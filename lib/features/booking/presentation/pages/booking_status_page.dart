import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../shared/models/booking.dart';
import '../../../../shared/models/mission.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/circle_icon_avatar.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../data/booking_repository.dart';

/// Tracks a booking after payment via `GET /bookings/:id/mission` — the
/// backend has no push/webhook to the client, matching happens async, so
/// this is the client's only way to observe PENDING -> MATCHED ->
/// IN_PROGRESS -> COMPLETED and pick up partner info (booking-flow.md §1, §5).
class BookingStatusPage extends ConsumerStatefulWidget {
  const BookingStatusPage({super.key, required this.bookingId, this.seed});

  final String bookingId;

  /// The just-created booking's rich, client-known display data (service
  /// title/icon, member name, ...) — the raw rows this page polls don't
  /// carry those (no service/partner name preload on the backend).
  final Booking? seed;

  @override
  ConsumerState<BookingStatusPage> createState() => _BookingStatusPageState();
}

class _BookingStatusPageState extends ConsumerState<BookingStatusPage> {
  Timer? _pollTimer;
  DateTime? _pendingSince;

  bool _isLoading = true;
  Booking? _booking;
  Mission? _mission;
  Partner? _partner;

  @override
  void initState() {
    super.initState();
    _booking = widget.seed;
    _poll();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _poll() async {
    final detail = await ref.read(bookingRepositoryProvider).getMission(widget.bookingId);
    if (!mounted) return;

    final merged = _booking?.copyWith(status: detail.booking.status) ?? detail.booking;

    if (merged.status == BookingStatus.pending) {
      _pendingSince ??= DateTime.now();
    } else {
      _pendingSince = null;
    }

    setState(() {
      _booking = merged;
      _mission = detail.mission;
      _partner = detail.partner;
      _isLoading = false;
    });

    _scheduleNextPoll(merged.status);
  }

  void _scheduleNextPoll(BookingStatus status) {
    _pollTimer?.cancel();

    final interval = switch (status) {
      BookingStatus.pending => const Duration(seconds: 5),
      BookingStatus.matched => const Duration(seconds: 20),
      BookingStatus.inProgress => const Duration(seconds: 20),
      _ => null, // COMPLETED / CANCELLED / PAYMENT_EXPIRED / AWAITING_PAYMENT: stop polling
    };

    if (interval == null) return;
    _pollTimer = Timer(interval, _poll);
  }

  bool get _isTakingLong {
    final since = _pendingSince;
    return since != null && DateTime.now().difference(since) > const Duration(minutes: 10);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('สถานะการจอง')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final booking = _booking!;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('สถานะการจอง'),
        leading: BackButton(onPressed: () => context.go(AppRoutes.home)),
      ),
      body: RefreshIndicator(
        onRefresh: _poll,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            AppCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleIconAvatar(icon: booking.serviceIcon, color: booking.serviceColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(booking.serviceTitle, style: textTheme.titleMedium),
                            const SizedBox(height: 2),
                            Text('อ้างอิง ${booking.reference}', style: textTheme.bodySmall),
                          ],
                        ),
                      ),
                      StatusBadge(text: booking.status.label, color: booking.status.color),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildStatusBody(booking, textTheme),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.go(AppRoutes.home),
                child: const Text('กลับหน้าหลัก'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBody(Booking booking, TextTheme textTheme) {
    switch (booking.status) {
      case BookingStatus.pending:
        return Column(
          children: [
            const AppCard(
              child: Column(
                children: [
                  SizedBox(height: 8),
                  SizedBox(width: 32, height: 32, child: CircularProgressIndicator(strokeWidth: 3)),
                  SizedBox(height: 14),
                  Text('กำลังค้นหาผู้ดูแลใกล้คุณ', style: TextStyle(fontWeight: FontWeight.w700)),
                  SizedBox(height: 4),
                  Text(
                    'ระบบกำลังจับคู่กับพาร์ทเนอร์ที่เหมาะสม โปรดรอสักครู่',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  SizedBox(height: 8),
                ],
              ),
            ),
            if (_isTakingLong) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.warning),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'การค้นหาผู้ดูแลใช้เวลานานกว่าปกติ หากรอนานผิดปกติ กรุณาติดต่อฝ่ายบริการลูกค้า',
                        style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );

      case BookingStatus.matched:
      case BookingStatus.inProgress:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_partner != null) ...[
              const SectionHeader(title: 'พาร์ทเนอร์ผู้ดูแล', icon: Icons.badge_rounded),
              const SizedBox(height: 12),
              AppCard(
                child: Row(
                  children: [
                    const CircleIconAvatar(icon: Icons.person_rounded, color: AppColors.primary, filled: true),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_partner!.name, style: textTheme.titleSmall),
                          const SizedBox(height: 3),
                          Text(_partner!.phone, style: textTheme.bodySmall),
                        ],
                      ),
                    ),
                    if (_partner!.ratingAvg != null) ...[
                      const Icon(Icons.star_rounded, color: AppColors.badgeDefault, size: 18),
                      const SizedBox(width: 2),
                      Text(_partner!.ratingAvg!.toStringAsFixed(1), style: textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            if (_mission != null && _mission!.checkpoints.isNotEmpty) ...[
              const SectionHeader(title: 'ความคืบหน้างาน', icon: Icons.checklist_rounded),
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  children: [
                    for (final checkpoint in _mission!.checkpoints)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Icon(
                              checkpoint.isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                              color: checkpoint.isDone ? AppColors.success : AppColors.border,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                checkpoint.labelTh.isNotEmpty ? checkpoint.labelTh : checkpoint.labelEn,
                                style: textTheme.bodyMedium?.copyWith(
                                  fontWeight: checkpoint.isDone ? FontWeight.w700 : FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ] else
              const AppCard(child: Text('พาร์ทเนอร์รับงานแล้ว กำลังเตรียมเดินทาง')),
          ],
        );

      case BookingStatus.completed:
        return const AppCard(
          child: Column(
            children: [
              Icon(Icons.check_circle_rounded, color: AppColors.success, size: 40),
              SizedBox(height: 10),
              Text('งานเสร็จสิ้นแล้ว', style: TextStyle(fontWeight: FontWeight.w700)),
              SizedBox(height: 4),
              Text('ขอบคุณที่ใช้บริการ CareMate', style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        );

      case BookingStatus.paymentExpired:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppCard(
              child: Column(
                children: [
                  Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 40),
                  SizedBox(height: 10),
                  Text('การชำระเงินหมดอายุ', style: TextStyle(fontWeight: FontWeight.w700)),
                  SizedBox(height: 4),
                  Text(
                    'รายการนี้ไม่สามารถดำเนินการต่อได้ กรุณาทำรายการจองใหม่',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            PrimaryButton(
              label: 'จองใหม่',
              icon: Icons.add,
              onPressed: () => context.go(AppRoutes.booking),
            ),
          ],
        );

      case BookingStatus.cancelled:
      case BookingStatus.awaitingPayment:
        return AppCard(child: Text(booking.status.label));
    }
  }
}
