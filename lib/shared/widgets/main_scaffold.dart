import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_routes.dart';
import '../../app/router/booking_wizard_dirty.dart';
import '../../app/router/nav_direction.dart';
import '../utils/confirm_dialogs.dart';

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
      // `child` here is the ShellRoute's own Navigator (same GlobalKey on
      // every rebuild — see DESIGN.md / router notes), so the actual slide
      // transition between tabs lives in that Navigator's page transitions
      // (each tab route's `pageBuilder` in app_router.dart), not here. An
      // AnimatedSwitcher wrapped around `child` was tried first and never
      // animated anything, because `child`'s identity never changes for
      // Flutter to detect a swap.
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => _onTap(context, index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'หน้าแรก',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'จองบริการ',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'สมาชิก',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'โปรไฟล์',
          ),
        ],
      ),
    );
  }
}
