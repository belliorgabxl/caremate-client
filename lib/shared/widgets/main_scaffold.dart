import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_routes.dart';
import '../../app/router/booking_wizard_dirty.dart';
import '../../app/router/nav_direction.dart';
import '../utils/confirm_dialogs.dart';
import 'app_bottom_nav.dart';

const _navItems = [
  AppBottomNavItem(icon: Icons.home_rounded, label: 'หน้าแรก'),
  AppBottomNavItem(icon: Icons.calendar_month_rounded, label: 'จองบริการ'),
  AppBottomNavItem(icon: Icons.people_rounded, label: 'สมาชิก'),
  AppBottomNavItem(icon: Icons.person_rounded, label: 'โปรไฟล์'),
];

class MainScaffold extends StatelessWidget {
  const MainScaffold({super.key, required this.child});

  final Widget child;

  int _getCurrentIndex(String path) {
    if (path.startsWith(AppRoutes.booking)) return 1;
    if (path.startsWith(AppRoutes.members)) return 2;
    if (path.startsWith(AppRoutes.profile)) return 3;
    return 0;
  }

  Future<void> _onTap(BuildContext context, int index) async {
    final currentIndex = _getCurrentIndex(
      GoRouterState.of(context).uri.toString(),
    );

    // Leaving the booking tab mid-wizard (past the first step) would
    // silently discard everything the user has filled in — confirm first.
    if (currentIndex == 1 && index != 1 && bookingWizardDirty.value) {
      final confirmed = await confirmDiscardChanges(
        context,
        message: 'ข้อมูลการจองที่กรอกไว้จะหายไป ต้องการออกจากหน้านี้หรือไม่?',
      );
      if (!context.mounted || !confirmed) return;
      bookingWizardDirty.value = false;
    }

    navDirection.value = index >= currentIndex
        ? NavDirection.forward
        : NavDirection.back;
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
        break;
      case 1:
        context.go(AppRoutes.booking);
        break;
      case 2:
        context.go(AppRoutes.members);
        break;
      case 3:
        context.go(AppRoutes.profile);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _getCurrentIndex(location);

    return Scaffold(
      // No `extendBody`: a tab's own FloatingActionButton (Members' "เพิ่ม
      // สมาชิก") positions itself relative to this Scaffold's *body* bounds,
      // not the nav bar's — with `extendBody: true` that body fills the
      // whole screen and the FAB lands underneath/overlapping the floating
      // pill instead of clear above it. Leaving it off makes Scaffold
      // shrink body to stop above `bottomNavigationBar` the normal way, so
      // the FAB (and everything else) naturally clears it. Each tab's own
      // ListView already carries its own bottom padding for the pill's
      // height, so scroll content still reads correctly either way.
      // `child` here is the ShellRoute's own Navigator (same GlobalKey on
      // every rebuild — see DESIGN.md / router notes), so the actual slide
      // transition between tabs lives in that Navigator's page transitions
      // (each tab route's `pageBuilder` in app_router.dart), not here. An
      // AnimatedSwitcher wrapped around `child` was tried first and never
      // animated anything, because `child`'s identity never changes for
      // Flutter to detect a swap.
      body: child,
      bottomNavigationBar: AppBottomNav(
        items: _navItems,
        currentIndex: currentIndex,
        onTap: (index) => _onTap(context, index),
      ),
    );
  }
}
