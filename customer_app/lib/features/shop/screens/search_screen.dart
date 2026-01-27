import 'package:flutter/material.dart';

import 'package:customer_app/core/theme/app_theme.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomerTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Minimal Search Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
              ),
              child: Row(
                children: [
                   Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: false, // ZARA doesn't auto-focus always
                      style: const TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.normal,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'SEARCH FOR AN ITEM...',
                        hintStyle: TextStyle(
                          fontSize: 14, 
                          color: Colors.grey,
                          letterSpacing: 1.0,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.mic_none_outlined, color: Colors.black),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            
            // Trending / Recent
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                children: [
                  const Text(
                    'TRENDING NOW',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _TrendingItem(term: 'LINEN DRESS'),
                  _TrendingItem(term: 'BLAZER'),
                  _TrendingItem(term: 'SHOES'),
                  _TrendingItem(term: 'JEANS'),
                  _TrendingItem(term: 'SUMMER'),
                  
                  const SizedBox(height: 48),
                  
                  const Text(
                    'RECENTLY VIEWED',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Simple text list or small thumbnails
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendingItem extends StatelessWidget {
  final String term;

  const _TrendingItem({required this.term});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: GestureDetector(
        onTap: () {
          // Fill search
        },
        child: Text(
          term,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: Color(0xFF333333),
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
