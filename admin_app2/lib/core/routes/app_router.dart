import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/warehouse/warehouse_screen.dart';
import '../../screens/pos/pos_screen.dart';
import '../../screens/orders/orders_screen.dart';
import '../../screens/discount/discount_screen.dart';
import '../../screens/analytics/analytics_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../theme/app_theme.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      // Main Shell with Glass Sidebar
      ShellRoute(
        builder: (context, state, child) {
          return MainShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/warehouse',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: WarehouseScreen(),
            ),
          ),
          GoRoute(
            path: '/pos',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: POSScreen(),
            ),
          ),
          GoRoute(
            path: '/orders',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: OrdersScreen(),
            ),
          ),
          GoRoute(
            path: '/discount',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DiscountScreen(),
            ),
          ),
          GoRoute(
            path: '/analytics',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AnalyticsScreen(),
            ),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),
        ],
      ),
    ],
  );
}

class MainShell extends StatefulWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  final List<String> _routes = [
    '/',
    '/warehouse',
    '/pos',
    '/orders',
    '/discount',
    '/analytics',
    '/settings',
  ];

  void _onItemSelected(int index) {
    setState(() => _selectedIndex = index);
    context.go(_routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    // Joriy yo'lga qarab indexni aniqlash
    final location = GoRouterState.of(context).uri.path;
    final currentIndex = _routes.indexOf(location);
    if (currentIndex != -1 && currentIndex != _selectedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _selectedIndex = currentIndex);
      });
    }

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Row(
          children: [
            // Glass Sidebar
            GlassSidebar(
              selectedIndex: _selectedIndex,
              onItemSelected: _onItemSelected,
            ),
            
            // Main Content
            Expanded(
              child: widget.child,
            ),
          ],
        ),
      ),
    );
  }
}
