import 'package:flutter/material.dart';

import 'package:customer_app/core/theme/app_theme.dart';

/// Menu Screen - Category list like ZARA
class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'MENU',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        children: const [
          _MenuCategory(title: 'NEW'),
          _MenuCategory(title: 'WOMAN'),
          _MenuCategory(title: 'DRESSES'),
          _MenuCategory(title: 'TOPS'),
          _MenuCategory(title: 'PANTS'),
          _MenuCategory(title: 'SHOES'),
          _MenuCategory(title: 'ACCESSORIES'),
          _MenuCategory(title: 'BAGS'),
          Divider(height: 40),
          _MenuCategory(title: 'SALE', isHighlight: true),
        ],
      ),
    );
  }
}

class _MenuCategory extends StatelessWidget {
  final String title;
  final bool isHighlight;

  const _MenuCategory({
    required this.title,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
          color: isHighlight ? Colors.red : Colors.black,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: () {
        // Navigate to category
      },
    );
  }
}
