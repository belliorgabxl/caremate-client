import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/router/nav_direction.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/error_messages.dart';
import '../../../../shared/models/booking.dart';
import '../../../../shared/models/booking_cancellation.dart';
import '../../../../shared/models/mission.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/aurora_background.dart';
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
  bool _isCancelling = false;
  Booking? _booking;
  Mission? _mission;
  Partner? _partner;

  /// Set only when this screen is the one that cancelled the booking — a
  /// booking opened from history that was already cancelled has no such
  /// detail to show (the list endpoints don't carry it).
  BookingCancellation? _cancellation;

  bool _isSendingEmergency = false;
  bool _isSharingLocation = false;

  final TextEditingController _reviewCommentController =
      TextEditingController();
  int _reviewRating = 0;
  bool _isSubmittingReview = false;

  /// Optimistic client-side "already reviewed this session" flag — set on a
  /// successful submit or a 409 (already reviewed elsewhere), so the form
  /// can't be resubmitted without re-fetching anything.
  bool _reviewSubmitted = false;

  @override
  void initState() {
    super.initState();
    _booking = widget.seed;
    _poll();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _reviewCommentController.dispose();
    super.dispose();
  }

  Future<void> _poll() async {
    final detail = await ref
        .read(bookingRepositoryProvider)
        .getMission(widget.bookingId);
    if (!mounted) return;

    final merged =
        _booking?.copyWith(status: detail.booking.status) ?? detail.booking;

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
      _ =>
        null,
    };

    if (interval == null) return;
    _pollTimer = Timer(interval, _poll);
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Returns the reason the user typed (possibly empty) on confirm, or null
  /// if they backed out.
  Future<String?> _askCancelReason(Booking booking) {
    final reasonController = TextEditingController();

    final consequence = switch (booking.status) {
      BookingStatus.awaitingPayment =>
        'รายการนี้ยังไม่ได้ชำระเงิน ยกเลิกได้ทันที',
      BookingStatus.matched =>
        'ผู้ดูแลรับงานนี้ไปแล้ว ระบบจะแจ้งการยกเลิกให้ทราบ '
            'และคืนเงินตามขั้นตอนของเจ้าหน้าที่',
      _ =>
        'ระบบกำลังค้นหาผู้ดูแลอยู่ การยกเลิกจะหยุดการค้นหา '
            'และคืนเงินตามขั้นตอนของเจ้าหน้าที่',
    };

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยกเลิกการจอง'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(consequence),
            const SizedBox(height: 16),
            AppTextField(
              controller: reasonController,
              label: 'เหตุผล (ไม่บังคับ)',
              hint: 'เช่น ผู้ป่วยอาการดีขึ้นแล้ว',
              maxLines: 3,
              maxLength: 500,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ไม่ยกเลิก'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, reasonController.text.trim()),
            child: const Text(
              'ยืนยันยกเลิก',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelBooking(Booking booking) async {
    final reason = await _askCancelReason(booking);
    if (reason == null || !mounted) return;

    setState(() => _isCancelling = true);

    try {
      final cancellation = await ref
          .read(bookingRepositoryProvider)
          .cancelBooking(bookingId: widget.bookingId, reason: reason);

      if (!mounted) return;
      _pollTimer?.cancel();
      setState(() {
        _cancellation = cancellation;
        _booking = _booking?.copyWith(status: BookingStatus.cancelled);
        _isCancelling = false;
      });
      _showSnack('ยกเลิกการจองเรียบร้อยแล้ว');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isCancelling = false);

      switch (e.code) {
        // Already cancelled is the outcome the user wanted — treat it as a
        // success and just re-sync, don't show it as a failure.
        case BookingCancelErrorCode.alreadyCancelled:
          _showSnack('รายการนี้ถูกยกเลิกไปแล้ว');
          await _poll();
        case BookingCancelErrorCode.notCancellable:
          _showSnack('ไม่สามารถยกเลิกรายการนี้ได้ กรุณาติดต่อเจ้าหน้าที่');
          await _poll();
        case BookingCancelErrorCode.notFound:
          _showSnack('ไม่พบรายการจองนี้');
        default:
          _showSnack(friendlyErrorMessage(e));
      }
    }
  }

  bool get _isTakingLong {
    final since = _pendingSince;
    return since != null &&
        DateTime.now().difference(since) > const Duration(minutes: 10);
  }

  /// SOS is offered for any state where the booking is still "live" —
  /// everything except the two terminal happy/unhappy paths and the expired
  /// state, where there's no active service left to raise an alert about.
  bool get _isEmergencyEligible {
    final booking = _booking;
    if (booking == null) return false;
    return booking.status != BookingStatus.completed &&
        booking.status != BookingStatus.cancelled &&
        booking.status != BookingStatus.paymentExpired;
  }

  /// Zero-backend-dependency direct dial — deliberately not gated behind the
  /// SOS confirm dialog, one tap only.
  Future<void> _call1669() async {
    final uri = Uri(scheme: 'tel', path: '1669');
    final launched = await launchUrl(uri);
    if (!launched && mounted) {
      _showSnack('ไม่สามารถโทรออกได้ในขณะนี้');
    }
  }

  Future<void> _showEmergencyDialog() async {
    final notesController = TextEditingController();
    var selectedType = 'medical';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('แจ้งเหตุฉุกเฉิน'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ทีมงานจะได้รับแจ้งและติดต่อกลับโดยเร็วที่สุด '
                  'กรุณาเลือกประเภทเหตุฉุกเฉิน',
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('ฉุกเฉินทางการแพทย์'),
                      selected: selectedType == 'medical',
                      onSelected: (_) =>
                          setDialogState(() => selectedType = 'medical'),
                    ),
                    ChoiceChip(
                      label: const Text('ความปลอดภัย'),
                      selected: selectedType == 'safety',
                      onSelected: (_) =>
                          setDialogState(() => selectedType = 'safety'),
                    ),
                    ChoiceChip(
                      label: const Text('อื่นๆ'),
                      selected: selectedType == 'other',
                      onSelected: (_) =>
                          setDialogState(() => selectedType = 'other'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: notesController,
                  label: 'รายละเอียดเพิ่มเติม (ไม่บังคับ)',
                  maxLines: 3,
                  maxLength: 300,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'ยืนยันแจ้งเหตุ',
                style: TextStyle(color: AppColors.danger),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isSendingEmergency = true);
    try {
      final notes = notesController.text.trim();
      await ref
          .read(bookingRepositoryProvider)
          .triggerEmergency(
            bookingId: widget.bookingId,
            type: selectedType,
            notes: notes.isEmpty ? null : notes,
          );
      if (!mounted) return;
      setState(() => _isSendingEmergency = false);
      _showSnack('แจ้งเหตุฉุกเฉินแล้ว ทีมงานจะติดต่อกลับโดยเร็วที่สุด');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSendingEmergency = false);
      _showSnack(
        friendlyErrorMessage(
          e,
          'ไม่สามารถแจ้งเหตุฉุกเฉินได้ กรุณาลองใหม่ หรือโทร 1669',
        ),
      );
    }
  }

  Future<void> _shareLocation() async {
    setState(() => _isSharingLocation = true);
    try {
      final link = await ref
          .read(bookingRepositoryProvider)
          .createShareLink(widget.bookingId);
      if (!mounted) return;
      setState(() => _isSharingLocation = false);

      // caremate.app has no real web deployment yet — this exact URL won't
      // resolve for a recipient without the app installed and configured to
      // handle the domain as an app link. The in-app route (`/track/:token`,
      // PublicTrackingPage) is what actually renders something today.
      final url = 'https://caremate.app/track/${link.token}';
      final partnerName = _partner?.name ?? 'ผู้ดูแล';

      await SharePlus.instance.share(
        ShareParams(
          text:
              'ติดตามตำแหน่งการเดินทางของ $partnerName ได้ที่ $url',
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSharingLocation = false);
      _showSnack(
        friendlyErrorMessage(e, 'ไม่สามารถสร้างลิงก์แชร์ตำแหน่งได้ กรุณาลองใหม่'),
      );
    }
  }

  Future<void> _submitReview() async {
    setState(() => _isSubmittingReview = true);
    try {
      final comment = _reviewCommentController.text.trim();
      await ref
          .read(bookingRepositoryProvider)
          .submitReview(
            bookingId: widget.bookingId,
            rating: _reviewRating,
            comment: comment.isEmpty ? null : comment,
          );
      if (!mounted) return;
      setState(() {
        _isSubmittingReview = false;
        _reviewSubmitted = true;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSubmittingReview = false);

      if (e.statusCode == 409) {
        setState(() => _reviewSubmitted = true);
        _showSnack('คุณให้คะแนนบริการนี้ไปแล้ว');
      } else {
        _showSnack(friendlyErrorMessage(e));
      }
    }
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
        leading: BackButton(onPressed: () => context.goBack(AppRoutes.home)),
      ),
      floatingActionButton: _isEmergencyEligible
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: 'call1669',
                  backgroundColor: AppColors.warning,
                  foregroundColor: Colors.white,
                  onPressed: _call1669,
                  tooltip: 'โทร 1669',
                  child: const Icon(Icons.call_rounded),
                ),
                const SizedBox(height: 12),
                FloatingActionButton.extended(
                  heroTag: 'sos',
                  backgroundColor: AppColors.danger,
                  foregroundColor: Colors.white,
                  onPressed: _isSendingEmergency ? null : _showEmergencyDialog,
                  icon: const Icon(Icons.emergency_rounded),
                  label: const Text('ฉุกเฉิน'),
                ),
              ],
            )
          : null,
      body: Stack(
        children: [
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AuroraBackground(height: 260),
          ),
          RefreshIndicator(
            onRefresh: _poll,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                AppCard(
                  glass: true,
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleIconAvatar(
                            icon: booking.serviceIcon,
                            color: booking.serviceColor,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  booking.serviceTitle,
                                  style: textTheme.titleMedium,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'อ้างอิง ${booking.reference}',
                                  style: textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          StatusBadge(
                            text: booking.status.label,
                            color: booking.status.color,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const SectionHeader(
                  title: 'รายละเอียดการจอง',
                  icon: Icons.receipt_long_rounded,
                ),
                const SizedBox(height: 12),
                _BookingDetailCard(booking: booking),
                const SizedBox(height: 20),
                _buildStatusBody(booking, textTheme),
                if (booking.status.isCancellableByUser) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isCancelling
                          ? null
                          : () => _cancelBooking(booking),
                      icon: _isCancelling
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.close_rounded),
                      label: Text(
                        _isCancelling ? 'กำลังยกเลิก...' : 'ยกเลิกการจอง',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: BorderSide(
                          color: AppColors.danger.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => context.goBack(AppRoutes.home),
                    child: const Text('กลับหน้าหลัก'),
                  ),
                ),
              ],
            ),
          ),
        ],
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
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                  SizedBox(height: 14),
                  Text(
                    'กำลังค้นหาผู้ดูแลใกล้คุณ',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
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
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'การค้นหาผู้ดูแลใช้เวลานานกว่าปกติ หากรอนานผิดปกติ กรุณาติดต่อฝ่ายบริการลูกค้า',
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
        );

      case BookingStatus.matched:
      case BookingStatus.inProgress:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_partner != null) ...[
              const SectionHeader(
                title: 'พาร์ทเนอร์ผู้ดูแล',
                icon: Icons.badge_rounded,
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Row(
                  children: [
                    const CircleIconAvatar(
                      icon: Icons.person_rounded,
                      color: AppColors.primary,
                      filled: true,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  _partner!.name,
                                  style: textTheme.titleSmall,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (_partner!.verified) ...[
                                const SizedBox(width: 5),
                                const Icon(
                                  Icons.verified_rounded,
                                  size: 16,
                                  color: AppColors.info,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(_partner!.phone, style: textTheme.bodySmall),
                          if (_partner!.verified) ...[
                            const SizedBox(height: 2),
                            Text(
                              'ผ่านการตรวจสอบแล้ว',
                              style: textTheme.labelSmall?.copyWith(
                                color: AppColors.info,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (_partner!.ratingAvg != null) ...[
                      const Icon(
                        Icons.star_rounded,
                        color: AppColors.badgeDefault,
                        size: 18,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        _partner!.ratingAvg!.toStringAsFixed(1),
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isSharingLocation ? null : _shareLocation,
                  icon: _isSharingLocation
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.share_location_rounded),
                  label: Text(
                    _isSharingLocation
                        ? 'กำลังสร้างลิงก์...'
                        : 'แชร์ตำแหน่งให้ครอบครัว',
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
            if (_mission != null && _mission!.checkpoints.isNotEmpty) ...[
              const SectionHeader(
                title: 'ความคืบหน้างาน',
                icon: Icons.checklist_rounded,
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  children: [
                    for (final checkpoint in _mission!.checkpoints)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  checkpoint.isDone
                                      ? Icons.check_circle_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                  color: checkpoint.isDone
                                      ? AppColors.success
                                      : AppColors.border,
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    checkpoint.labelTh.isNotEmpty
                                        ? checkpoint.labelTh
                                        : checkpoint.labelEn,
                                    style: textTheme.bodyMedium?.copyWith(
                                      fontWeight: checkpoint.isDone
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (checkpoint.photoUrl != null) ...[
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.only(left: 34),
                                child: _CheckpointPhotoThumbnail(
                                  url: checkpoint.photoUrl!,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ] else
              const AppCard(
                child: Text('พาร์ทเนอร์รับงานแล้ว กำลังเตรียมเดินทาง'),
              ),
          ],
        );

      case BookingStatus.completed:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppCard(
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: 40,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'งานเสร็จสิ้นแล้ว',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'ขอบคุณที่ใช้บริการ CareMate',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _reviewSubmitted
                ? const AppCard(
                    child: Column(
                      children: [
                        Icon(
                          Icons.favorite_rounded,
                          color: AppColors.danger,
                          size: 32,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'ขอบคุณสำหรับคะแนนของคุณ',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  )
                : _buildReviewForm(textTheme),
          ],
        );

      case BookingStatus.paymentExpired:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppCard(
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.danger,
                    size: 40,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'การชำระเงินหมดอายุ',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
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
              onPressed: () => context.goForward(AppRoutes.booking),
            ),
          ],
        );

      case BookingStatus.awaitingPayment:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(child: Text(booking.status.label)),
            const SizedBox(height: 14),
            PrimaryButton(
              label: 'ชำระเงิน',
              icon: Icons.payment_rounded,
              onPressed: () => context.goForward(AppRoutes.payment),
            ),
          ],
        );

      case BookingStatus.cancelled:
        final cancellation = _cancellation;
        final detail = switch (cancellation?.previousStatus) {
          BookingStatus.matched =>
            'ระบบได้แจ้งการยกเลิกให้ผู้ดูแลที่รับงานแล้ว',
          BookingStatus.pending => 'ระบบหยุดค้นหาผู้ดูแลให้แล้ว',
          BookingStatus.awaitingPayment =>
            'รายการนี้ถูกยกเลิกก่อนการชำระเงิน',
          _ => 'รายการนี้ถูกยกเลิกแล้ว',
        };

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              child: Column(
                children: [
                  const Icon(
                    Icons.cancel_rounded,
                    color: AppColors.danger,
                    size: 40,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'ยกเลิกรายการแล้ว',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    detail,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  if (cancellation?.reason != null) ...[
                    const Divider(height: 24),
                    _DetailRow(
                      icon: Icons.notes_rounded,
                      label: 'เหตุผลที่ยกเลิก',
                      value: cancellation!.reason!,
                    ),
                  ],
                ],
              ),
            ),
            if (cancellation?.refundRequired == true) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.currency_exchange_rounded,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'ยกเลิกหลังชำระเงินแล้ว อยู่ระหว่างดำเนินการคืนเงิน '
                        'เจ้าหน้าที่จะติดต่อกลับ',
                        style: textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            PrimaryButton(
              label: 'จองใหม่',
              icon: Icons.add,
              onPressed: () => context.goForward(AppRoutes.booking),
            ),
          ],
        );
    }
  }

  Widget _buildReviewForm(TextTheme textTheme) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'ให้คะแนนบริการครั้งนี้',
            style: textTheme.titleSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var star = 1; star <= 5; star++)
                IconButton(
                  onPressed: () => setState(() => _reviewRating = star),
                  icon: Icon(
                    star <= _reviewRating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: AppColors.badgeDefault,
                    size: 32,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          AppTextField(
            controller: _reviewCommentController,
            label: 'ความคิดเห็น (ไม่บังคับ)',
            maxLines: 3,
            maxLength: 500,
          ),
          const SizedBox(height: 14),
          PrimaryButton(
            label: 'ส่งคะแนน',
            icon: Icons.send_rounded,
            isLoading: _isSubmittingReview,
            onPressed: _reviewRating == 0 ? null : _submitReview,
          ),
        ],
      ),
    );
  }
}

class _BookingDetailCard extends StatelessWidget {
  const _BookingDetailCard({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          _DetailRow(
            icon: Icons.person_outline_rounded,
            label: 'ผู้รับบริการ',
            value: booking.memberName,
          ),
          const Divider(height: 24),
          _DetailRow(
            icon: Icons.event_outlined,
            label: 'วันและเวลา',
            value: _formatDateTime(booking.scheduledAt),
          ),
          const Divider(height: 24),
          _DetailRow(
            icon: Icons.location_on_outlined,
            label: booking.destinationAddress == null
                ? 'สถานที่รับบริการ'
                : 'จุดรับ → จุดหมาย',
            value: booking.destinationAddress == null
                ? booking.pickupAddress
                : '${booking.pickupAddress} → ${booking.destinationAddress}',
          ),
          if (booking.notes != null && booking.notes!.isNotEmpty) ...[
            const Divider(height: 24),
            _DetailRow(
              icon: Icons.notes_rounded,
              label: 'หมายเหตุ',
              value: booking.notes!,
            ),
          ],
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
                '฿${booking.totalAmount.toStringAsFixed(0)}',
                style: textTheme.titleMedium?.copyWith(
                  color: booking.serviceColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
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
    return '${dateTime.day} ${months[dateTime.month - 1]} เวลา $hour:$minute น.';
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
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

/// Small tappable thumbnail for a checkpoint photo — opens a full-screen
/// pinch-to-zoom viewer. Plain `Image.network`, no caching package in this
/// project yet, so loading/error states are handled explicitly.
class _CheckpointPhotoThumbnail extends StatelessWidget {
  const _CheckpointPhotoThumbnail({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        barrierColor: Colors.black,
        builder: (context) => _CheckpointPhotoViewer(url: url),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Image.network(
          url,
          width: 96,
          height: 96,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              width: 96,
              height: 96,
              color: AppColors.surfaceAlt,
              alignment: Alignment.center,
              child: const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) => Container(
            width: 96,
            height: 96,
            color: AppColors.surfaceAlt,
            alignment: Alignment.center,
            child: const Icon(
              Icons.broken_image_outlined,
              color: AppColors.textTertiary,
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckpointPhotoViewer extends StatelessWidget {
  const _CheckpointPhotoViewer({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Image.network(
                url,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white54,
                  size: 48,
                ),
              ),
            ),
          ),
          SafeArea(
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
