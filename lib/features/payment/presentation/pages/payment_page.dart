import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/router/nav_direction.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/local_notifications.dart';
import '../../../../core/utils/error_messages.dart';
import '../../../../shared/models/booking.dart';
import '../../../../shared/models/booking_cancellation.dart';
import '../../../../shared/models/payment.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/aurora_background.dart';
import '../../../../shared/widgets/circle_icon_avatar.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../booking/data/booking_repository.dart';
import '../../data/payment_repository.dart';

class PaymentPage extends ConsumerStatefulWidget {
  const PaymentPage({super.key});

  @override
  ConsumerState<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<PaymentPage> {
  bool _isLoading = true;
  bool _isCancelling = false;
  bool _paymentConfirmed = false;

  Booking? _booking;
  Payment? _payment;
  List<PaymentMethod> _methods = const [];
  Uint8List? _qrImageBytes;

  Timer? _pollTimer;
  Timer? _countdownTimer;
  Duration _remaining = Duration.zero;
  bool _qrExpired = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);

    final bookingRepo = ref.read(bookingRepositoryProvider);
    final paymentRepo = ref.read(paymentRepositoryProvider);

    final pending = await bookingRepo.getPendingPayment();
    final methods = await paymentRepo.getMethods();

    Payment? payment;
    if (pending != null && pending.$2.id.isNotEmpty) {
      payment = await paymentRepo.getById(pending.$2.id);
    }

    if (!mounted) return;
    setState(() {
      _booking = pending?.$1;
      _payment = payment;
      _methods = methods;
      _isLoading = false;
    });

    if (payment == null) return;

    if (payment.status == PaymentStatus.paid) {
      _onPaymentConfirmed();
      return;
    }

    _startExpiryCountdown(payment);
    await _createChargeIfNeeded(payment);
    _startPolling(payment);
  }

  Future<void> _createChargeIfNeeded(Payment payment) async {
    final method = _selectedMethod;
    if (method?.slug != 'qr_promptpay') return;

    try {
      final charge = await ref
          .read(paymentRepositoryProvider)
          .createCharge(paymentId: payment.id);

      if (!mounted) return;
      setState(() => _qrImageBytes = base64Decode(charge.qrImageBase64));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
    }
  }

  /// Polls for the backend to confirm payment (via Beam's webhook) — the
  /// client can no longer assert payment succeeded itself.
  void _startPolling(Payment payment) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!mounted || _paymentConfirmed) return;

      final latest = await ref
          .read(paymentRepositoryProvider)
          .getById(payment.id);

      if (!mounted) return;

      if (latest.status == PaymentStatus.paid) {
        _pollTimer?.cancel();
        setState(() => _payment = latest);
        _onPaymentConfirmed();
      }
    });
  }

  void _startExpiryCountdown(Payment payment) {
    _qrExpired = false;
    _countdownTimer?.cancel();
    _updateRemaining(payment);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _updateRemaining(payment);
    });
  }

  void _updateRemaining(Payment payment) {
    final expiredAt = payment.expiredAt;
    if (expiredAt == null) {
      setState(() => _remaining = Duration.zero);
      return;
    }
    final remaining = expiredAt.difference(DateTime.now());
    final isExpired = remaining.isNegative;
    setState(() {
      _remaining = isExpired ? Duration.zero : remaining;
      if (isExpired) _qrExpired = true;
    });
    // The payment can no longer succeed server-side past its own expiry —
    // stop polling instead of hammering the endpoint indefinitely.
    if (isExpired) _pollTimer?.cancel();
  }

  String get _countdownLabel {
    final minutes = _remaining.inMinutes
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    final seconds = _remaining.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    return '$minutes:$seconds';
  }

  PaymentMethod? get _selectedMethod {
    final payment = _payment;
    if (payment == null || _methods.isEmpty) return null;
    for (final method in _methods) {
      if (method.id == payment.paymentMethodId) return method;
    }
    return _methods.first;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('ชำระเงิน')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final booking = _booking;
    final payment = _payment;

    if (booking == null || payment == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('ชำระเงิน')),
        body: const Center(child: Text('ไม่มีรายการที่รอชำระเงิน')),
      );
    }

    final textTheme = Theme.of(context).textTheme;
    final method = _selectedMethod;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('ชำระเงิน'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      bottomNavigationBar: _buildBottomBar(payment),
      body: Stack(
        children: [
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AuroraBackground(height: 360),
          ),
          ListView(
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.paddingOf(context).top + 68,
              20,
              24,
            ),
            children: [
              AppCard(
                glass: true,
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.receipt_long_rounded,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'สรุปรายการจอง',
                            style: textTheme.titleMedium,
                          ),
                        ),
                        StatusBadge(
                          text: payment.status.label,
                          color: AppColors.warning,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SummaryRow(label: 'บริการ', value: booking.serviceTitle),
                    _SummaryRow(
                      label: 'ผู้รับบริการ',
                      value: booking.memberName,
                    ),
                    _SummaryRow(label: 'อ้างอิง', value: booking.reference),
                    const Divider(height: 24),
                    Row(
                      children: [
                        Text(
                          'ยอดชำระ',
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '฿${payment.totalAmount.toStringAsFixed(0)}',
                          style: textTheme.headlineMedium?.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (method?.slug == 'qr_promptpay') ...[
                const SectionHeader(
                  title: 'สแกน QR เพื่อชำระเงิน',
                  subtitle: 'เปิดแอปธนาคารแล้วสแกน QR นี้',
                  icon: Icons.qr_code_rounded,
                ),
                const SizedBox(height: 12),
                _PromptPayQrCard(
                  imageBytes: _qrImageBytes,
                  reference: payment.reference,
                  countdownLabel: _countdownLabel,
                  isExpired: _qrExpired,
                ),
              ] else if (method != null) ...[
                const SectionHeader(
                  title: 'วิธีชำระเงิน',
                  icon: Icons.wallet_rounded,
                ),
                const SizedBox(height: 12),
                AppCard(
                  child: Row(
                    children: [
                      CircleIconAvatar(
                        icon: method.icon,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(method.title, style: textTheme.titleSmall),
                            const SizedBox(height: 2),
                            Text(method.subtitle, style: textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              // A user who decides not to pay would otherwise have to leave
              // this screen and find the booking again to cancel it — and the
              // 15-minute expiry timer would keep running in the meantime.
              Center(
                child: TextButton.icon(
                  onPressed: _isCancelling ? null : _cancelBooking,
                  icon: _isCancelling
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.close_rounded, size: 18),
                  label: Text(
                    _isCancelling ? 'กำลังยกเลิก...' : 'ยกเลิกรายการจองนี้',
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// There is nothing left for the user to tap — payment is confirmed only
  /// by Beam's webhook, picked up by `_startPolling`, which auto-advances to
  /// the success screen on its own. This bar just reflects that state.
  Widget _buildBottomBar(Payment payment) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ยอดชำระ', style: textTheme.labelMedium),
                  const SizedBox(height: 2),
                  Text(
                    '฿${payment.totalAmount.toStringAsFixed(0)}',
                    style: textTheme.headlineSmall,
                  ),
                ],
              ),
            ),
            if (_qrExpired)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 18,
                    color: AppColors.danger,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'QR หมดอายุ',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  /// Cancelling here is always the `AWAITING_PAYMENT` case — nothing has been
  /// paid, so there's no refund to explain and no partner to notify.
  Future<void> _cancelBooking() async {
    final booking = _booking;
    if (booking == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยกเลิกรายการจอง'),
        content: const Text(
          'รายการนี้ยังไม่ได้ชำระเงิน ยกเลิกได้ทันทีโดยไม่มีค่าใช้จ่าย '
          'หากต้องการใช้บริการภายหลังต้องทำรายการจองใหม่',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ไม่ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'ยืนยันยกเลิก',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isCancelling = true);

    try {
      await ref
          .read(bookingRepositoryProvider)
          .cancelBooking(bookingId: booking.id);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isCancelling = false);

      // Already cancelled is the outcome the user asked for — fall through to
      // the same "leave this screen" handling rather than reporting an error.
      if (e.code != BookingCancelErrorCode.alreadyCancelled) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
        return;
      }
    }

    if (!mounted) return;
    _pollTimer?.cancel();
    _countdownTimer?.cancel();
    setState(() => _isCancelling = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ยกเลิกรายการจองเรียบร้อยแล้ว')),
    );
    context.goBack(AppRoutes.home);
  }

  /// Called once polling observes the payment flip to `paid` — the backend
  /// already confirmed it via Beam's webhook by this point. No user action
  /// triggers this; it fires on its own.
  void _onPaymentConfirmed() {
    if (_paymentConfirmed) return;
    _paymentConfirmed = true;

    _pollTimer?.cancel();
    _countdownTimer?.cancel();

    ref.read(bookingRepositoryProvider).clearPendingPayment();
    _scheduleBookingReminder(_booking);

    if (!mounted) return;
    final booking = _booking;
    if (booking != null) {
      context.goForward(AppRoutes.paymentSuccess, extra: booking);
    }
  }

  /// Best-effort nicety layered on top of a successful payment confirmation
  /// — a failure here (permission denied, plugin not ready, etc.) must never
  /// surface as an error on what is otherwise a completed, paid booking.
  /// Fire-and-forget (not awaited from [_onPaymentConfirmed]); `.catchError`
  /// (rather than a synchronous try/catch, which can't see errors thrown
  /// after an `await` inside the scheduling call) makes sure a failure here
  /// only ever reaches `debugPrint`.
  void _scheduleBookingReminder(Booking? booking) {
    if (booking == null) return;

    LocalNotificationsService.scheduleBookingReminder(
      id: booking.id.hashCode,
      title: 'ใกล้ถึงเวลานัดหมายแล้ว',
      body: '${booking.serviceTitle} สำหรับ ${booking.memberName} '
          'อีก 30 นาทีจะถึงเวลานัดหมาย',
      scheduledFor: booking.scheduledAt,
    ).catchError((Object e) {
      debugPrint('scheduleBookingReminder failed: $e');
    });
  }

}

class _PromptPayQrCard extends StatelessWidget {
  const _PromptPayQrCard({
    required this.imageBytes,
    required this.reference,
    required this.countdownLabel,
    required this.isExpired,
  });

  /// The real QR image PNG bytes from Beam — not a payload string, nothing
  /// renders/generates this client-side anymore.
  final Uint8List? imageBytes;
  final String reference;
  final String countdownLabel;
  final bool isExpired;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasImage = imageBytes != null && imageBytes!.isNotEmpty;

    return AppCard(
      elevated: true,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: 200,
            height: 200,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: isExpired
                ? const Center(
                    child: Icon(
                      Icons.qr_code_2_rounded,
                      size: 56,
                      color: AppColors.textSecondary,
                    ),
                  )
                : (hasImage
                      ? Image.memory(imageBytes!, fit: BoxFit.contain)
                      : const Center(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(strokeWidth: 3),
                          ),
                        )),
          ),
          const SizedBox(height: 14),
          Text('อ้างอิง: $reference', style: textTheme.bodySmall),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isExpired ? Icons.error_outline_rounded : Icons.timer_outlined,
                size: 16,
                color: AppColors.danger,
              ),
              const SizedBox(width: 6),
              Text(
                isExpired ? 'QR หมดอายุแล้ว กรุณาทำรายการใหม่' : 'QR หมดอายุใน $countdownLabel นาที',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
