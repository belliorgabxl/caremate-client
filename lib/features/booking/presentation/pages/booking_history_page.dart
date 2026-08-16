import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/router/nav_direction.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/error_messages.dart';
import '../../../../shared/models/address.dart';
import '../../../../shared/models/booking.dart';
import '../../../../shared/models/booking_prefill.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/circle_icon_avatar.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../data/booking_repository.dart';

class BookingHistoryPage extends ConsumerStatefulWidget {
  const BookingHistoryPage({super.key});

  @override
  ConsumerState<BookingHistoryPage> createState() => _BookingHistoryPageState();
}

class _BookingHistoryPageState extends ConsumerState<BookingHistoryPage> {
  bool _isLoading = true;
  String? _error;
  List<Booking> _bookings = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final bookings = await ref
          .read(bookingRepositoryProvider)
          .getAllBookings();
      if (!mounted) return;
      setState(() {
        _bookings = bookings;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = friendlyErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  /// `Booking` (from `/bookings/history`) doesn't carry a service slug or
  /// member id — the backend row is thin, per CLAUDE.md's documented quirk —
  /// so this is a best-effort partial prefill: only the address strings
  /// (wrapped as a plain `Address` with no coordinates, since history rows
  /// don't carry lat/lng either) make it across. `BookingPage` treats a
  /// non-matching/absent `serviceSlug`/`memberId` as a no-op, so this is
  /// still real value even though it can't reselect the same service or
  /// recipient.
  void _rebook(BuildContext context, Booking booking) {
    context.goForward(
      AppRoutes.booking,
      extra: BookingPrefill(
        pickupAddress: Address(
          addressLine: booking.pickupAddress,
          latitude: 0,
          longitude: 0,
        ),
        destinationAddress: booking.destinationAddress == null
            ? null
            : Address(
                addressLine: booking.destinationAddress!,
                latitude: 0,
                longitude: 0,
              ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    const months = [
      'ม.ค.',
      'ก.พ.',
      'มี.ค.',
      'เม.ย.',
      'พ.ค.',
      'มิ.ย.',
      'ก.ค.',
      'ส.ค.',
      'ก.ย.',
      'ต.ค.',
      'พ.ย.',
      'ธ.ค.',
    ];
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year + 543} • $hour:$minute น.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ประวัติการจอง'),
        leading: BackButton(onPressed: () => context.goBack(AppRoutes.profile)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _error != null
                  ? ListView(
                      padding: const EdgeInsets.fromLTRB(20, 40, 20, 32),
                      children: [
                        EmptyState(
                          icon: Icons.error_outline_rounded,
                          title: 'โหลดประวัติการจองไม่สำเร็จ',
                          message: _error!,
                          action: PrimaryButton(
                            label: 'ลองอีกครั้ง',
                            icon: Icons.refresh_rounded,
                            expanded: false,
                            onPressed: _load,
                          ),
                        ),
                      ],
                    )
                  : _bookings.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.fromLTRB(20, 40, 20, 32),
                      children: [
                        EmptyState(
                          icon: Icons.receipt_long_rounded,
                          title: 'ยังไม่มีประวัติการจอง',
                          message: 'เมื่อคุณจองบริการ รายการจะแสดงที่นี่',
                          action: PrimaryButton(
                            label: 'จองบริการ',
                            icon: Icons.add,
                            expanded: false,
                            onPressed: () =>
                                context.goForward(AppRoutes.booking),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                      itemCount: _bookings.length,
                      separatorBuilder: (context, _) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final booking = _bookings[index];
                        final textTheme = Theme.of(context).textTheme;

                        return AppCard(
                          onTap: () => context.goForward(
                            AppRoutes.bookingStatusPath(booking.id),
                            extra: booking,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleIconAvatar(
                                icon: booking.serviceIcon,
                                color: booking.serviceColor,
                                radius: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            booking.serviceTitle,
                                            style: textTheme.titleSmall,
                                          ),
                                        ),
                                        StatusBadge(
                                          text: booking.status.label,
                                          color: booking.status.color,
                                          dense: true,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'ให้${booking.memberName} • ${_formatDateTime(booking.scheduledAt)}',
                                      style: textTheme.bodySmall,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      booking.destinationAddress == null
                                          ? booking.pickupAddress
                                          : '${booking.pickupAddress} → ${booking.destinationAddress}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.surfaceAlt,
                                              borderRadius: BorderRadius.circular(
                                                AppRadius.sm,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.receipt_rounded,
                                                  size: 14,
                                                  color: AppColors.textSecondary,
                                                ),
                                                const SizedBox(width: 6),
                                                Flexible(
                                                  child: Text(
                                                    '${booking.reference} • ฿${booking.totalAmount.toStringAsFixed(0)}',
                                                    overflow: TextOverflow.ellipsis,
                                                    style: textTheme.labelMedium,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        TextButton.icon(
                                          onPressed: () => _rebook(context, booking),
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                            ),
                                          ),
                                          icon: const Icon(
                                            Icons.replay_rounded,
                                            size: 16,
                                          ),
                                          label: const Text('จองซ้ำ'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
