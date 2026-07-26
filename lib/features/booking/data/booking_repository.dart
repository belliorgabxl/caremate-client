import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/models/booking.dart';
import '../../../shared/models/care_member.dart';
import '../../../shared/models/care_service.dart';
import '../../payment/data/payment_repository.dart';
import '../domain/booking_calculations.dart';

class BookingRepository {
  BookingRepository(this._paymentRepository) {
    _bookings.add(
      Booking(
        id: 'b-seed-1',
        reference: 'CM-SEED1',
        serviceId: services[0].id,
        serviceTitle: services[0].title,
        serviceIcon: services[0].icon,
        serviceColor: services[0].color,
        memberId: 'm2',
        memberName: 'สมชาย นภากาญจน์',
        memberRelationship: 'บิดา',
        scheduledAt: DateTime.now().add(const Duration(days: 1, hours: 2)),
        pickupAddress: 'คอนโด CareMate Residence, ถนนสุขุมวิท',
        destinationAddress: 'โรงพยาบาลสมิติเวช สุขุมวิท',
        distanceKm: services[0].typicalDistanceKm,
        notes: 'ผู้รับบริการเดินช้า กรุณาช่วยพยุงตอนขึ้นลงรถ',
        serviceFee: calculateServiceFee(
          baseFeePerHour: services[0].baseFeePerHour,
          durationMinutes: services[0].durationMinutes,
        ),
        platformFee: AppConfig.platformFee,
        status: BookingStatus.matched,
        paymentId: 'pay-seed-1',
      ),
    );
  }

  final PaymentRepository _paymentRepository;

  final List<CareService> services = const [
    CareService(
      id: 's1',
      slug: 'transport',
      title: 'รับ-ส่งพบแพทย์',
      subtitle: 'มีผู้ช่วยดูแลระหว่างเดินทาง',
      icon: Icons.local_taxi_rounded,
      color: AppColors.serviceTransport,
      baseFeePerHour: 300,
      requiresDestination: true,
      durationMinutes: 90,
      typicalDistanceKm: 8.4,
    ),
    CareService(
      id: 's2',
      slug: 'home_care',
      title: 'ดูแลรายชั่วโมง',
      subtitle: 'ดูแลที่บ้านหรือคอนโด',
      icon: Icons.volunteer_activism_rounded,
      color: AppColors.serviceHomeCare,
      baseFeePerHour: 175,
      requiresDestination: false,
      durationMinutes: 120,
      typicalDistanceKm: 0,
    ),
    CareService(
      id: 's3',
      slug: 'medication',
      title: 'ซื้อยา / เวชภัณฑ์',
      subtitle: 'ให้พาร์ทเนอร์ช่วยซื้อและจัดส่ง',
      icon: Icons.medication_rounded,
      color: AppColors.serviceMedication,
      baseFeePerHour: 180,
      requiresDestination: true,
      durationMinutes: 60,
      typicalDistanceKm: 5.2,
    ),
    CareService(
      id: 's4',
      slug: 'errand',
      title: 'พาไปทำธุระ',
      subtitle: 'ช่วยดูแลการเดินทางทั่วไป',
      icon: Icons.accessible_forward_rounded,
      color: AppColors.serviceErrand,
      baseFeePerHour: 290,
      requiresDestination: true,
      durationMinutes: 80,
      typicalDistanceKm: 7.1,
    ),
  ];

  final List<Booking> _bookings = [];

  Future<List<CareService>> getServices() async {
    await Future.delayed(AppConfig.mockNetworkDelay);
    return services;
  }

  Future<List<Booking>> getActiveBookings() async {
    await Future.delayed(AppConfig.mockNetworkDelay);
    return _bookings
        .where((b) => b.status != BookingStatus.completed && b.status != BookingStatus.cancelled)
        .toList(growable: false);
  }

  Booking? getById(String id) {
    for (final booking in _bookings) {
      if (booking.id == id) return booking;
    }
    return null;
  }

  Future<Booking> createBooking({
    required CareService service,
    required CareMember member,
    required DateTime scheduledAt,
    required String pickupAddress,
    String? destinationAddress,
    String? notes,
    required String paymentMethodId,
  }) async {
    await Future.delayed(AppConfig.mockNetworkDelay);

    final serviceFee = calculateServiceFee(
      baseFeePerHour: service.baseFeePerHour,
      durationMinutes: service.durationMinutes,
    );

    final bookingId = 'b-${DateTime.now().millisecondsSinceEpoch}';
    final payment = _paymentRepository.createForBooking(
      bookingId: bookingId,
      totalAmount: serviceFee + AppConfig.platformFee,
      paymentMethodId: paymentMethodId,
    );

    final booking = Booking(
      id: bookingId,
      reference: 'CM${DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase()}',
      serviceId: service.id,
      serviceTitle: service.title,
      serviceIcon: service.icon,
      serviceColor: service.color,
      memberId: member.id,
      memberName: member.fullName,
      memberRelationship: member.relationship,
      scheduledAt: scheduledAt,
      pickupAddress: pickupAddress,
      destinationAddress: service.requiresDestination ? destinationAddress : null,
      distanceKm: service.requiresDestination ? service.typicalDistanceKm : null,
      notes: notes,
      serviceFee: serviceFee,
      platformFee: AppConfig.platformFee,
      status: BookingStatus.awaitingPayment,
      paymentId: payment.id,
    );

    _bookings.add(booking);
    return booking;
  }

  Future<void> markPaid(String bookingId) async {
    await Future.delayed(AppConfig.mockNetworkDelay);

    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index == -1) return;
    _bookings[index] = _bookings[index].copyWith(status: BookingStatus.matched);
  }
}

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository(ref.read(paymentRepositoryProvider));
});
