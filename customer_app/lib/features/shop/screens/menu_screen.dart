import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'category_products_screen.dart';

/// Menu Screen - ZARA style categories
/// Minimalist design - no icons, clean typography
class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top tabs - ZARA style
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _TabItem(title: 'AYOLLAR', isSelected: true),
                  _TabItem(title: 'ERKAKLAR'),
                  _TabItem(title: 'BOLALAR'),
                ],
              ),
            ),
            
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            
            // Categories list
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('categories')
                    .orderBy('order')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 1,
                      ),
                    );
                  }

                  // Kategoriyalar ro'yxatini yaratish
                  List<_CategoryData> categories = [];
                  
                  if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                    categories = snapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return _CategoryData(
                        id: doc.id,
                        name: data['name'] as String? ?? '',
                      );
                    }).toList();
                  } else {
                    // Default kategoriyalar
                    categories = [
                      _CategoryData(id: '', name: "Ko'ylak"),
                      _CategoryData(id: '', name: 'Shim'),
                      _CategoryData(id: '', name: 'Yubka'),
                      _CategoryData(id: '', name: 'Bluzka'),
                      _CategoryData(id: '', name: "Ko'stum"),
                      _CategoryData(id: '', name: 'Palto'),
                      _CategoryData(id: '', name: 'Kurtka'),
                      _CategoryData(id: '', name: 'Sport'),
                    ];
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return _CategoryItem(
                        title: category.name.toUpperCase(),
                        onTap: () {
                          // Navigate to category products
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CategoryProductsScreen(
                                categoryName: category.name,
                                categoryId: category.id,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kategoriya ma'lumotlari
class _CategoryData {
  final String id;
  final String name;

  _CategoryData({required this.id, required this.name});
}

/// Top tab item - ZARA style
class _TabItem extends StatelessWidget {
  final String title;
  final bool isSelected;

  const _TabItem({
    required this.title,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 24),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          letterSpacing: 1.0,
          color: Colors.black,
        ),
      ),
    );
  }
}

/// Category list item - ZARA style (minimalist)
class _CategoryItem extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;

  const _CategoryItem({
    required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.5,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}
