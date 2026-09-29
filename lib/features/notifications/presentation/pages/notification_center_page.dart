import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/router/nav_direction.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/app_badge_service.dart';
import '../../../../core/utils/error_messages.dart';
import '../../../../shared/models/notification_item.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/back_circle_button.dart';
import '../../../../shared/widgets/circle_icon_avatar.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../data/notification_repository.dart';

class NotificationCenterPage extends ConsumerStatefulWidget {
  const NotificationCenterPage({super.key});

  @override
  ConsumerState<NotificationCenterPage> createState() =>
      _NotificationCenterPageState();
}

class _NotificationCenterPageState
    extends ConsumerState<NotificationCenterPage> {
  bool _isLoading = true;
  String? _error;
  List<NotificationItem> _items = const [];

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
      final (items, unread) = await ref
          .read(notificationRepositoryProvider)
          .list();
      if (!mounted) return;
      setState(() {
        _items = items;
        _isLoading = false;
      });
      await AppBadgeService.setCount(unread);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = friendlyErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  void _openNotification(NotificationItem item) {
    _markRead(item);
    final bookingId = item.bookingId;
    if (bookingId != null && bookingId.isNotEmpty) {
      context.pushForward(AppRoutes.bookingStatusPath(bookingId));
    }
  }

  Future<void> _markRead(NotificationItem item) async {
    if (item.isRead) return;
    final index = _items.indexWhere((n) => n.id == item.id);
    if (index == -1) return;

    try {
      await ref.read(notificationRepositoryProvider).markRead(item.id);
      if (!mounted) return;
      setState(() {
        _items = [
          for (final n in _items)
            if (n.id == item.id)
              NotificationItem(
                id: n.id,
                title: n.title,
                body: n.body,
                type: n.type,
                createdAt: n.createdAt,
                bookingId: n.bookingId,
                readAt: DateTime.now(),
              )
            else
              n,
        ];
      });
      await AppBadgeService.setCount(_items.where((n) => !n.isRead).length);
    } on ApiException catch (_) {
      // Best-effort — a failed mark-read isn't worth surfacing an error for.
    }
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
    final h = dateTime.hour.toString().padLeft(2, '0');
    final m = dateTime.minute.toString().padLeft(2, '0');
    return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year + 543} $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final topInset = MediaQuery.paddingOf(context).top + 60;

    return Scaffold(
      body: Stack(
        children: [
          _isLoading
              ? const SizedBox.shrink()
              : _error != null
              ? ListView(
                  padding: EdgeInsets.fromLTRB(20, topInset, 20, 32),
                  children: [
                    EmptyState(
                      icon: Icons.error_outline_rounded,
                      title: 'โหลดข้อมูลไม่สำเร็จ',
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
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _items.isEmpty
                      ? ListView(
                          padding: EdgeInsets.fromLTRB(20, topInset, 20, 32),
                          children: const [
                            EmptyState(
                              icon: Icons.notifications_none_rounded,
                              title: 'ยังไม่มีการแจ้งเตือน',
                              message:
                                  'เมื่อมีความเคลื่อนไหวเกี่ยวกับการจองของคุณ จะแสดงที่นี่',
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: EdgeInsets.fromLTRB(16, topInset, 16, 32),
                          itemCount: _items.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = _items[index];
                            return AppCard(
                              onTap: () => _openNotification(item),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleIconAvatar(
                                    icon: Icons.notifications_rounded,
                                    color: item.isRead
                                        ? AppColors.textTertiary
                                        : AppColors.primary,
                                    radius: 20,
                                    filled: !item.isRead,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title,
                                          style: textTheme.titleSmall?.copyWith(
                                            fontWeight: item.isRead
                                                ? FontWeight.w500
                                                : FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.body,
                                          style: textTheme.bodySmall,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          _formatDateTime(item.createdAt),
                                          style: textTheme.bodySmall?.copyWith(
                                            color: AppColors.textTertiary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!item.isRead) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            left: 20,
            child: BackCircleButton(
              onTap: () => context.popBack(AppRoutes.home),
            ),
          ),
        ],
      ),
    );
  }
}
