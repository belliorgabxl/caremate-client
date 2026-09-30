import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/booking_tab_activated.dart';
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
  const MainScaffold({super.key, required this.navigationShell});

  /// One branch per bottom tab (see `StatefulShellRoute.indexedStack` in
  /// `app_router.dart`). `navigationShell` itself is the body — it's an
  /// `IndexedStack` under the hood, keeping every tab's widget tree (and
  /// scroll position, form state, in-flight data) alive across switches
  /// instead of rebuilding the destination tab from scratch like a plain
  /// `ShellRoute` does.
  final StatefulNavigationShell navigationShell;

  Future<void> _onTap(BuildContext context, int index) async {
    final currentIndex = navigationShell.currentIndex;

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
    navigationShell.goBranch(
      index,
      // Tapping the already-active tab resets it to its own initial route
      // (e.g. clears Booking's wizard back to step one) instead of no-op —
      // matches how a tab bar is expected to behave.
      initialLocation: index == currentIndex,
    );

    // Booking's bank-account gate and member list must be fresh every time
    // this tab is entered, not just the first time this app session (see
    // booking_tab_activated.dart).
    if (index == 1) bookingTabActivated.value++;
  }

  @override
  Widget build(BuildContext context) {
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
      body: navigationShell,
      bottomNavigationBar: AppBottomNav(
        items: _navItems,
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => _onTap(context, index),
      ),
    );
  }
}
