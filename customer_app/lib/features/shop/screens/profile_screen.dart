import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:customer_app/core/theme/app_theme.dart';
import 'package:customer_app/core/l10n/locale_provider.dart';
import 'orders_history_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocaleProvider>();

    return Scaffold(
      backgroundColor: CustomerTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  loc.t('profile.title').toUpperCase(),
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  // Language switch
                  Text(
                    loc.t('profile.language').toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _LangChip(
                          label: "O'zbekcha",
                          selected: loc.isUz,
                          onTap: () => loc.setLang('uz'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _LangChip(
                          label: 'Русский',
                          selected: !loc.isUz,
                          onTap: () => loc.setLang('ru'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // My orders
                  _ProfileMenuItem(
                    title: loc.t('profile.myOrders').toUpperCase(),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const OrdersHistoryScreen(),
                        ),
                      );
                    },
                  ),
                  _ProfileMenuItem(
                    title: loc.t('profile.contact').toUpperCase(),
                    onTap: () {},
                  ),
                  _ProfileMenuItem(
                    title: loc.t('profile.about').toUpperCase(),
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LangChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.black : Colors.white,
          border: Border.all(color: Colors.black),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: Colors.black,
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
