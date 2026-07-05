import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'screens/search_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/wishlist_screen.dart';
import 'screens/profile_screen.dart';
import 'providers/cart_provider.dart';
import 'providers/wishlist_provider.dart';
import 'providers/shell_tab_provider.dart';

class CustomerShell extends StatelessWidget {
  const CustomerShell({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final wishlist = context.watch<WishlistProvider>();
    final tabs = context.watch<ShellTabProvider>();
    final currentIndex = tabs.index;
    void go(int i) => tabs.setIndex(i);

    final screens = [
      HomeScreen(onProfileTap: () => go(5)),
      const SearchScreen(),
      const MenuScreen(),
      const CartScreen(),
      const WishlistScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade200, width: 0.5),
          ),
        ),
        child: Padding(
          // iPhone home-indikatori ustida joylashishi uchun pastdan masofa
          padding: EdgeInsets.only(
            left: 8,
            right: 8,
            top: 12,
            bottom: 12 +
                (MediaQuery.viewPaddingOf(context).bottom > 0
                    ? MediaQuery.viewPaddingOf(context).bottom
                    : 16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
                _NavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  isActive: currentIndex == 0,
                  onTap: () => go(0),
                ),
                _NavItem(
                  icon: Icons.search,
                  activeIcon: Icons.search,
                  isActive: currentIndex == 1,
                  onTap: () => go(1),
                ),
                // MENU - Text instead of icon (like ZARA)
                GestureDetector(
                  onTap: () => go(2),
                  child: Text(
                    'MENU',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: currentIndex == 2 ? FontWeight.bold : FontWeight.normal,
                      color: currentIndex == 2 ? Colors.black : Colors.grey,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                _NavItem(
                  icon: Icons.shopping_bag_outlined,
                  activeIcon: Icons.shopping_bag,
                  isActive: currentIndex == 3,
                  onTap: () => go(3),
                  badge: cart.itemCount,
                ),
                _NavItem(
                  icon: Icons.favorite_border,
                  activeIcon: Icons.favorite,
                  isActive: currentIndex == 4,
                  onTap: () => go(4),
                  badge: wishlist.count,
                ),
                _NavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  isActive: currentIndex == 5,
                  onTap: () => go(5),
                ),
              ],
            ),
          ),
        ),
      );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final bool isActive;
  final VoidCallback onTap;
  final int? badge;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.isActive,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        // Bosish maydonini kattalashtirish
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? Colors.black : Colors.grey,
              size: 26,
            ),
          if (badge != null && badge! > 0)
            Positioned(
              right: -8,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  '$badge',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
