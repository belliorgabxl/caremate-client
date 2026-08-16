import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/models/booking.dart';
import '../../../../shared/models/public_tracking.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../data/booking_repository.dart';

/// Public, no-auth page behind `GET /public/tracking/:token` — meant to be
/// opened by a family member who shared a `POST /bookings/:id/share-location`
/// link and may not be logged into this app at all, or even have an account.
/// Standalone `Scaffold` deliberately outside `MainScaffold`'s bottom-nav
/// shell: nothing here should assume authenticated user state.
///
/// This route (`/track/:token`) needs wiring into `app_router.dart` and, per
/// its `redirect:` callback, must be exempted from the login-required
/// redirect — see the session notes for the exact ask.
class PublicTrackingPage extends ConsumerStatefulWidget {
  const PublicTrackingPage({super.key, required this.token});

  final String token;

  @override
  ConsumerState<PublicTrackingPage> createState() =>
      _PublicTrackingPageState();
}

class _PublicTrackingPageState extends ConsumerState<PublicTrackingPage> {
  Timer? _pollTimer;
  bool _isLoading = true;

  /// Distinguishes "token invalid/expired" (404 — show [EmptyState]) from
  /// any other transient failure (network blip — keep the loader/retry via
  /// the still-scheduled poll rather than declaring the link dead).
  bool _notFound = false;
  PublicTracking? _tracking;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final tracking = await ref
          .read(bookingRepositoryProvider)
          .getPublicTracking(widget.token);
      if (!mounted) return;

      setState(() {
        _tracking = tracking;
        _isLoading = false;
        _notFound = false;
      });
      _scheduleNextPoll(tracking.bookingStatus);
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        if (e.statusCode == 404) _notFound = true;
      });
    }
  }

  void _scheduleNextPoll(BookingStatus status) {
    _pollTimer?.cancel();

    // Mirrors BookingStatusPage's own polling cadence — only worth refreshing
    // while a partner might actually be moving.
    final interval = switch (status) {
      BookingStatus.matched || BookingStatus.inProgress => const Duration(
        seconds: 20,
      ),
      _ => null,
    };

    if (interval == null) return;
    _pollTimer = Timer(interval, _load);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ติดตามการเดินทาง'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _notFound
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: EmptyState(
                    icon: Icons.link_off_rounded,
                    title: 'ลิงก์ไม่ถูกต้อง',
                    message: 'ลิงก์นี้หมดอายุหรือไม่ถูกต้อง',
                  ),
                ),
              )
            : _buildContent(_tracking!),
      ),
    );
  }

  Widget _buildContent(PublicTracking tracking) {
    final textTheme = Theme.of(context).textTheme;
    final hasLocation = tracking.partnerLat != null && tracking.partnerLng != null;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          AppCard(
            elevated: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'สถานะการเดินทาง',
                        style: textTheme.titleMedium,
                      ),
                    ),
                    StatusBadge(
                      text: tracking.bookingStatus.label,
                      color: tracking.bookingStatus.color,
                    ),
                  ],
                ),
                if (tracking.partnerName != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline_rounded,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(tracking.partnerName!, style: textTheme.bodyMedium),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (hasLocation) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: SizedBox(
                height: 240,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(tracking.partnerLat!, tracking.partnerLng!),
                    zoom: 15,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId('partner'),
                      position: LatLng(
                        tracking.partnerLat!,
                        tracking.partnerLng!,
                      ),
                    ),
                  },
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (tracking.pickupAddress != null || tracking.destinationAddress != null)
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (tracking.pickupAddress != null)
                    _AddressRow(
                      icon: Icons.trip_origin_rounded,
                      label: 'จุดรับ',
                      value: tracking.pickupAddress!,
                    ),
                  if (tracking.pickupAddress != null &&
                      tracking.destinationAddress != null)
                    const Divider(height: 24),
                  if (tracking.destinationAddress != null)
                    _AddressRow(
                      icon: Icons.location_on_rounded,
                      label: 'จุดหมาย',
                      value: tracking.destinationAddress!,
                    ),
                ],
              ),
            ),
          if (tracking.expiresAt != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: AppColors.info.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    color: AppColors.info,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'ลิงก์นี้จะหมดอายุเวลา ${_formatExpiry(tracking.expiresAt!)}',
                      style: textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatExpiry(DateTime dateTime) {
    final local = dateTime.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.day}/${local.month}/${local.year} $hour:$minute น.';
  }
}

class _AddressRow extends StatelessWidget {
  const _AddressRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
