import 'package:dio/dio.dart';

import 'demo_config.dart';
import 'demo_fixtures.dart';
import 'demo_mode.dart';

/// A booking created during a demo session. Status/payment state are pure
/// functions of elapsed wall-clock time from [chargeCreatedAt] — no polling
/// or timers needed, `bookingStatus`/`paymentStatus` just read differently
/// as the reviewer's own polling (`BookingStatusPage`) calls back in.
class _DemoBooking {
  _DemoBooking({
    required this.id,
    required this.reference,
    required this.paymentId,
    required this.serviceName,
    required this.serviceSlug,
    required this.memberName,
    required this.pickupAddress,
    required this.scheduledAt,
    required this.totalAmount,
    required this.paymentMethodId,
    this.destinationAddress,
    this.notes,
  }) : createdAt = DateTime.now();

  final String id;
  final String reference;
  final String paymentId;
  final String serviceName;
  final String serviceSlug;
  final String memberName;
  final String pickupAddress;
  final String? destinationAddress;
  final String? notes;
  final DateTime scheduledAt;
  final double totalAmount;
  final String paymentMethodId;
  final DateTime createdAt;

  DateTime? chargeCreatedAt;
  DateTime? cancelledAt;

  static const _payDelay = Duration(seconds: 6);
  static const _inProgressDelay = Duration(seconds: 15);
  static const _completedDelay = Duration(seconds: 40);

  bool get isCancelled => cancelledAt != null;

  String get paymentStatus {
    final chargedAt = chargeCreatedAt;
    if (chargedAt == null) return 'PENDING';
    return DateTime.now().difference(chargedAt) >= _payDelay
        ? 'PAID'
        : 'PENDING';
  }

  DateTime? get paidAt {
    final chargedAt = chargeCreatedAt;
    if (chargedAt == null || paymentStatus != 'PAID') return null;
    return chargedAt.add(_payDelay);
  }

  String get bookingStatus {
    if (isCancelled) return 'CANCELLED';
    final paid = paidAt;
    if (paid == null) return 'AWAITING_PAYMENT';
    final sincePaid = DateTime.now().difference(paid);
    if (sincePaid >= _completedDelay) return 'COMPLETED';
    if (sincePaid >= _inProgressDelay) return 'IN_PROGRESS';
    return 'MATCHED';
  }

  Map<String, dynamic> toBookingJson() => {
    'id': id,
    'reference': reference,
    'status': bookingStatus,
    'scheduled_at': scheduledAt.toIso8601String(),
    'pickup_address': pickupAddress,
    'destination_address': destinationAddress,
    'total_amount': totalAmount,
    'fee': totalAmount,
    'patient_name': memberName,
    'contact_name': memberName,
    'service_type_name': serviceName,
  };

  Map<String, dynamic> toPaymentJson() => {
    'id': paymentId,
    'booking_id': id,
    'payment_method_id': paymentMethodId,
    'total_amount': totalAmount,
    'status': paymentStatus,
    'reference': reference,
    'expired_at': createdAt.add(const Duration(minutes: 15)).toIso8601String(),
    'paid_at': paidAt?.toIso8601String(),
  };

  List<Map<String, dynamic>> _checkpoints() {
    final paid = paidAt;
    final inProgress =
        bookingStatus == 'IN_PROGRESS' || bookingStatus == 'COMPLETED';
    final completed = bookingStatus == 'COMPLETED';

    String? at(bool done, Duration afterPaid) =>
        done && paid != null ? paid.add(afterPaid).toIso8601String() : null;

    return [
      {
        'id': '$id-cp1',
        'step': 1,
        'label_th': 'รับคำขอแล้ว',
        'label_en': 'Request received',
        'notes': '',
        'completed_at': at(paid != null, Duration.zero),
      },
      {
        'id': '$id-cp2',
        'step': 2,
        'label_th': 'พบผู้ให้บริการแล้ว',
        'label_en': 'Partner matched',
        'notes': '',
        'completed_at': at(paid != null, Duration.zero),
      },
      {
        'id': '$id-cp3',
        'step': 3,
        'label_th': 'กำลังให้บริการ',
        'label_en': 'In progress',
        'notes': '',
        'completed_at': at(inProgress, _inProgressDelay),
        // Demo-only stand-in for a partner-uploaded checkpoint photo — a
        // public placeholder, not a real upload, so a reviewer walking the
        // demo account actually sees the photo-thumbnail UI at least once
        // instead of every checkpoint being photo-less.
        'photo_url': inProgress
            ? 'https://picsum.photos/seed/caremate-$id/400'
            : null,
      },
      {
        'id': '$id-cp4',
        'step': 4,
        'label_th': 'เสร็จสิ้น',
        'label_en': 'Completed',
        'notes': '',
        'completed_at': at(completed, _completedDelay),
      },
    ];
  }

  Map<String, dynamic>? toPartnerJson() {
    if (paidAt == null) return null;
    return {
      'id': 'demo-partner-1',
      'name': 'สมศักดิ์ ใจงาม',
      'phone': '0898765432',
      'rating_avg': 4.8,
      'current_lat': 13.7600,
      'current_lng': 100.5100,
      'status': 'active',
    };
  }

  Map<String, dynamic>? toMissionJson() {
    final paid = paidAt;
    if (paid == null) return null;
    return {
      'id': 'demo-mission-$id',
      'booking_id': id,
      'partner_id': 'demo-partner-1',
      'status': bookingStatus,
      'checkpoints': _checkpoints(),
      'started_at': paid.toIso8601String(),
      'completed_at': bookingStatus == 'COMPLETED'
          ? paid.add(_completedDelay).toIso8601String()
          : null,
    };
  }
}

/// Answers every Dio call while [DemoMode.enabled] is on, from in-memory
/// state seeded by `demo_fixtures.dart`. Mutations (creating a booking,
/// adding a relative, saving a bank account) persist for the life of the
/// demo session and reset on logout — see [reset].
class DemoBackend {
  DemoBackend._();

  static final List<Map<String, dynamic>> _relatives = [
    for (final r in demoRelatives()) Map<String, dynamic>.from(r),
  ];
  static final List<_DemoBooking> _bookings = [];
  static final List<Map<String, dynamic>> _notifications = [
    for (final n in demoNotifications()) Map<String, dynamic>.from(n),
  ];
  static Map<String, dynamic> _healthInfo = demoHealthInformation();
  static Map<String, dynamic> _address = demoAddress();
  static Map<String, dynamic>? _bankAccount;
  static int _seq = 0;

  /// Called on logout — a fresh demo login should start from a clean slate,
  /// not carry over whatever a previous reviewer session mutated.
  static void reset() {
    _relatives
      ..clear()
      ..addAll([for (final r in demoRelatives()) Map<String, dynamic>.from(r)]);
    _bookings.clear();
    _notifications
      ..clear()
      ..addAll([
        for (final n in demoNotifications()) Map<String, dynamic>.from(n),
      ]);
    _healthInfo = demoHealthInformation();
    _address = demoAddress();
    _bankAccount = null;
    _seq = 0;
  }

  static Response<dynamic> _ok(
    RequestOptions o,
    dynamic data, {
    int status = 200,
  }) => Response(requestOptions: o, statusCode: status, data: data);

  static DioException _error(
    RequestOptions o,
    int status,
    String message, {
    String? code,
  }) => DioException(
    requestOptions: o,
    response: Response(
      requestOptions: o,
      statusCode: status,
      data: {'message': message, 'code': ?code},
    ),
    type: DioExceptionType.badResponse,
  );

  /// Segment-based path matcher — `:id` in [pattern] matches any single
  /// segment. Avoids a regex per route for ~20 routes.
  static bool _matches(RequestOptions o, String method, String pattern) {
    if (o.method.toUpperCase() != method) return false;
    final segs = o.path.split('/').where((s) => s.isNotEmpty).toList();
    final patSegs = pattern.split('/').where((s) => s.isNotEmpty).toList();
    if (segs.length != patSegs.length) return false;
    for (var i = 0; i < segs.length; i++) {
      if (patSegs[i].startsWith(':')) continue;
      if (patSegs[i] != segs[i]) return false;
    }
    return true;
  }

  static String _param(RequestOptions o, String pattern, String name) {
    final segs = o.path.split('/').where((s) => s.isNotEmpty).toList();
    final patSegs = pattern.split('/').where((s) => s.isNotEmpty).toList();
    for (var i = 0; i < patSegs.length; i++) {
      if (patSegs[i] == ':$name') return segs[i];
    }
    return '';
  }

  static Map<String, dynamic> _body(RequestOptions o) =>
      (o.data is Map ? o.data as Map : const {}).cast<String, dynamic>();

  /// Entry point called by `DemoInterceptor`. Returns a resolved [Response]
  /// on success; throws [DioException] for the few paths that model a real
  /// failure (wrong demo OTP, double-cancel). Any unmapped path/method falls
  /// through to a harmless empty 200 rather than surfacing a dead end to
  /// the reviewer.
  static Response<dynamic> handle(RequestOptions o) {
    // --- auth ---
    if (_matches(o, 'POST', '/authentication/otp/request')) {
      return _ok(o, {'sent': true});
    }
    if (_matches(o, 'POST', '/authentication/login')) {
      final body = _body(o);
      if (DemoConfig.otp == null || body['code'] != DemoConfig.otp) {
        throw _error(o, 401, 'รหัส OTP ไม่ถูกต้อง กรุณาลองใหม่อีกครั้ง');
      }
      final response = _ok(o, {'ok': true});
      response.headers = Headers.fromMap({
        'set-cookie': ['caremate_session=demo-mode-session; Path=/; HttpOnly'],
      });
      return response;
    }
    if (_matches(o, 'GET', '/authentication/me')) {
      return _ok(o, demoAuthMe());
    }

    // --- profile ---
    if (_matches(o, 'GET', '/users/health-information')) {
      return _ok(o, _healthInfo);
    }
    if (_matches(o, 'PATCH', '/users/health-information')) {
      _healthInfo = {
        ..._healthInfo,
        ..._body(o),
        'has_health_information': true,
      };
      return _ok(o, _healthInfo);
    }
    if (_matches(o, 'GET', '/users/address')) {
      return _ok(o, _address);
    }
    if (_matches(o, 'PATCH', '/users/address')) {
      _address = {..._address, ..._body(o), 'has_address': true};
      return _ok(o, _address);
    }
    if (_matches(o, 'PATCH', '/users/personal-information')) {
      return _ok(o, demoAuthMe());
    }
    if (_matches(o, 'GET', '/users/bank-account')) {
      final acct = _bankAccount;
      return _ok(o, {
        'user_id': demoUserId,
        'bank_name': acct?['bank_name'],
        'bank_account': acct?['bank_account'],
        'bank_account_name': acct?['bank_account_name'],
        'has_bank_account': acct != null,
      });
    }
    if (_matches(o, 'PATCH', '/users/bank-account')) {
      _bankAccount = _body(o);
      return _ok(o, {'ok': true});
    }
    // Deleting the demo account only ends the demo session (the client logs
    // out right after, which resets DemoBackend) — the reviewer can log in
    // again with the same demo credentials.
    if (_matches(o, 'DELETE', '/users/account')) {
      return _ok(o, {'deleted': true});
    }
    if (_matches(o, 'GET', '/users/payment-check')) {
      return _ok(o, {'hasPayment': false, 'items': const []});
    }

    // --- relatives (members) ---
    if (_matches(o, 'GET', '/user-relatives')) {
      return _ok(o, {'relatives': _relatives});
    }
    if (_matches(o, 'POST', '/user-relatives')) {
      final body = _body(o);
      final id = 'demo-relative-${++_seq}';
      final entry = {
        'id': id,
        'firstName': body['firstName'],
        'lastName': body['lastName'],
        'nickname': body['firstName'],
        'relationship': body['relationship'],
        'registerAs': body['registerAs'],
        'phone': body['phone'],
        'gender': body['gender'],
        'dateOfBirth': body['dateOfBirth'],
        'bloodType': '',
        'isDefault': false,
        'isActive': true,
        'addressLine': '',
        'latitude': null,
        'longitude': null,
        'allergies': '',
        'congenitalDiseases': '',
        'careNote': body['careNote'] ?? '',
        'emergencyContactName': '',
        'emergencyContactPhone': '',
        'emergencyContactRelationship': '',
      };
      _relatives.add(entry);
      return _ok(o, entry, status: 201);
    }
    if (_matches(o, 'GET', '/user-relatives/:id')) {
      final id = _param(o, '/user-relatives/:id', 'id');
      final entry = _relatives.firstWhere(
        (m) => m['id'] == id,
        orElse: () => const {},
      );
      return _ok(o, {'relative': entry});
    }
    if (_matches(o, 'PATCH', '/user-relatives/:id')) {
      final id = _param(o, '/user-relatives/:id', 'id');
      final index = _relatives.indexWhere((m) => m['id'] == id);
      if (index != -1) {
        final body = _body(o);
        if (body['isDefault'] == true) {
          for (final m in _relatives) {
            m['isDefault'] = false;
          }
        }
        _relatives[index] = {..._relatives[index], ...body};
      }
      return _ok(o, index == -1 ? const {} : _relatives[index]);
    }
    if (_matches(o, 'DELETE', '/user-relatives/:id')) {
      final id = _param(o, '/user-relatives/:id', 'id');
      final index = _relatives.indexWhere((m) => m['id'] == id);
      if (index != -1) _relatives[index]['isActive'] = false;
      return _ok(o, const {});
    }

    // --- care services / booking ---
    if (_matches(o, 'GET', '/care/services')) {
      return _ok(o, {'services': demoServices});
    }
    if (_matches(o, 'GET', '/bookings/history')) {
      return _ok(o, {
        'bookings': [for (final b in _bookings) b.toBookingJson()],
      });
    }
    if (_matches(o, 'GET', '/bookings')) {
      return _ok(o, {
        'bookings': [
          for (final b in _bookings)
            if (!b.isCancelled &&
                b.bookingStatus != 'COMPLETED' &&
                b.bookingStatus != 'CANCELLED')
              b.toBookingJson(),
        ],
      });
    }
    if (_matches(o, 'POST', '/bookings/create')) {
      return _createBooking(o);
    }
    if (_matches(o, 'GET', '/bookings/:id/mission')) {
      final id = _param(o, '/bookings/:id/mission', 'id');
      final booking = _bookings.firstWhere(
        (b) => b.id == id,
        orElse: () => _bookings.first,
      );
      return _ok(o, {
        'booking': booking.toBookingJson(),
        'mission': booking.toMissionJson(),
        'partner': booking.toPartnerJson(),
      });
    }
    if (_matches(o, 'POST', '/bookings/:id/cancel')) {
      final id = _param(o, '/bookings/:id/cancel', 'id');
      final booking = _bookings.firstWhere(
        (b) => b.id == id,
        orElse: () => _bookings.first,
      );
      if (booking.isCancelled) {
        throw _error(
          o,
          409,
          'จองนี้ถูกยกเลิกไปแล้ว',
          code: 'BOOKING_ALREADY_CANCELLED',
        );
      }
      final previousStatus = booking.bookingStatus;
      booking.cancelledAt = DateTime.now();
      return _ok(o, {
        'bookingId': booking.id,
        'reference': booking.reference,
        'previousStatus': previousStatus,
        'cancelledAt': booking.cancelledAt!.toIso8601String(),
        'cancelledBy': 'user',
        'refundRequired': booking.paymentStatus == 'PAID',
        'reason': _body(o)['reason'],
        'paymentId': booking.paymentId,
        'paymentStatus': booking.paymentStatus,
      });
    }
    if (_matches(o, 'POST', '/bookings/:id/emergency')) {
      return _ok(o, const {}, status: 201);
    }
    if (_matches(o, 'POST', '/bookings/:id/share-location')) {
      final id = _param(o, '/bookings/:id/share-location', 'id');
      return _ok(o, {
        'token': 'demo-track-$id',
        'expiresAt': DateTime.now()
            .add(const Duration(hours: 6))
            .toIso8601String(),
      });
    }
    if (_matches(o, 'POST', '/bookings/:id/review')) {
      return _ok(o, const {}, status: 201);
    }

    // --- payments ---
    if (_matches(o, 'GET', '/payments/methods')) {
      return _ok(o, demoPaymentMethods);
    }
    if (_matches(o, 'GET', '/payments/:id')) {
      final id = _param(o, '/payments/:id', 'id');
      final booking = _bookings.firstWhere(
        (b) => b.paymentId == id,
        orElse: () => _bookings.first,
      );
      return _ok(o, booking.toPaymentJson());
    }
    if (_matches(o, 'POST', '/payments/:id/charge')) {
      final id = _param(o, '/payments/:id/charge', 'id');
      final booking = _bookings.firstWhere(
        (b) => b.paymentId == id,
        orElse: () => _bookings.first,
      );
      booking.chargeCreatedAt ??= DateTime.now();
      return _ok(o, {
        'paymentId': booking.paymentId,
        'chargeId': 'demo-charge-${booking.id}',
        'qrImageBase64': demoQrImageBase64,
        'qrExpiresAt': DateTime.now()
            .add(const Duration(minutes: 15))
            .toIso8601String(),
      });
    }

    // --- misc ---
    if (_matches(o, 'GET', '/banners')) {
      return _ok(o, demoBanners());
    }
    if (_matches(o, 'GET', '/notifications')) {
      return _ok(o, {
        'notifications': _notifications,
        'unread_count': _notifications
            .where((n) => n['read_at'] == null)
            .length,
      });
    }
    if (_matches(o, 'PATCH', '/notifications/:id/read')) {
      final id = _param(o, '/notifications/:id/read', 'id');
      final index = _notifications.indexWhere((n) => n['id'] == id);
      if (index != -1) {
        _notifications[index]['read_at'] = DateTime.now().toIso8601String();
      }
      return _ok(o, const {});
    }

    // Unmapped path — fail soft rather than surface a dead end mid-demo.
    return _ok(o, const {});
  }

  static Response<dynamic> _createBooking(RequestOptions o) {
    final body = _body(o);
    final serviceId = body['serviceTypeId'] as String?;
    final service = demoServices.firstWhere(
      (s) => s['id'] == serviceId,
      orElse: () => demoServices.first,
    );
    final relativeId = body['relativeId'] as String?;
    final member = _relatives.firstWhere(
      (m) => m['id'] == relativeId,
      orElse: () => _relatives.first,
    );

    final scheduledRaw = body['scheduledStartAt'] as String?;
    final scheduledAt = scheduledRaw == null
        ? DateTime.now()
        : DateTime.tryParse(scheduledRaw) ?? DateTime.now();

    final seq = ++_seq;
    final id = 'demo-booking-$seq';
    final paymentId = 'demo-payment-$seq';
    final reference = 'CM-DEMO-${seq.toString().padLeft(4, '0')}';
    final baseFee = (service['base_fee'] as num).toDouble();

    final booking = _DemoBooking(
      id: id,
      reference: reference,
      paymentId: paymentId,
      serviceName: service['name_th'] as String,
      serviceSlug: service['slug'] as String,
      memberName: '${member['firstName']} ${member['lastName']}'.trim(),
      pickupAddress: body['pickupAddress'] as String? ?? '-',
      destinationAddress: body['destinationAddress'] as String?,
      notes: body['specialNotes'] as String?,
      scheduledAt: scheduledAt,
      totalAmount: baseFee + 20,
      paymentMethodId:
          body['paymentMethodId'] as String? ??
          demoPaymentMethods.first['id'] as String,
    );
    _bookings.insert(0, booking);

    return _ok(o, {
      'bookingId': id,
      'reference': reference,
      'distanceKm': booking.serviceSlug == 'transport' ? 8.5 : null,
      'totalAmount': booking.totalAmount,
      'status': 'AWAITING_PAYMENT',
      'paymentId': paymentId,
      'paymentStatus': 'PENDING',
    });
  }
}

/// Installed on [ApiClient.dio]. When [DemoMode.enabled] is off this is a
/// no-op passthrough; the login/OTP-request routes are checked unconditionally
/// (by request body, not the flag) since they're what turns the flag on in
/// the first place.
class DemoInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final isDemoAuthCall =
        (options.method.toUpperCase() == 'POST' &&
            (options.path == '/authentication/otp/request' ||
                options.path == '/authentication/login')) &&
        (options.data is Map) &&
        DemoConfig.phone != null &&
        (options.data as Map)['phone'] == DemoConfig.phone;

    if (!DemoMode.enabled.value && !isDemoAuthCall) {
      handler.next(options);
      return;
    }

    try {
      final response = DemoBackend.handle(options);
      if (isDemoAuthCall && options.path == '/authentication/login') {
        DemoMode.enabled.value = true;
      }
      handler.resolve(response);
    } on DioException catch (e) {
      handler.reject(e);
    }
  }
}
