import 'dart:ui';
import 'package:flutter/material.dart';

/// Glassmorphism dizayn uchun asosiy tema
class AppTheme {
  AppTheme._();

  // ===== RANGLAR =====
  // Warm Beige/Peach gradient fon uchun
  static const Color gradientStart = Color(0xFFF5E6D3); // Yumshoq beige
  static const Color gradientMiddle = Color(0xFFE8D4C4); // Peach
  static const Color gradientEnd = Color(0xFFD4C4B0); // Quyuqroq beige
  
  // Accent ranglar
  static const Color accentOrange = Color(0xFFFF9800);
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color accentRed = Color(0xFFE53935);
  
  // Matn ranglari
  static const Color textPrimary = Color(0xFF2D2D2D);
  static const Color textSecondary = Color(0xFF757575);
  
  // Glass effekt ranglari
  static const Color glassWhite = Color(0xFFFFFFFF);
  static const Color glassBorder = Color(0x4DFFFFFF); // 30% opacity

  // ===== TEMA =====
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: accentOrange,
      brightness: Brightness.light,
    ),
    fontFamily: 'Poppins',
    scaffoldBackgroundColor: Colors.transparent,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: textPrimary),
    ),
    cardTheme: CardThemeData(
      color: glassWhite.withOpacity(0.2),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: glassWhite.withOpacity(0.3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: glassBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: accentOrange, width: 2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentOrange,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
      ),
    ),
  );
}

/// Gradient fon - rasm + gradient overlay
class GradientBackground extends StatelessWidget {
  final Widget child;

  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background image
        Positioned.fill(
          child: Image.asset(
            'assets/images/background.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.gradientStart,
                    AppTheme.gradientMiddle,
                    AppTheme.gradientEnd,
                  ],
                ),
              ),
            ),
          ),
        ),
        
        // Dark overlay for glassmorphism effect
        Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.3),
          ),
        ),
        
        // Content
        child,
      ],
    );
  }
}

/// Glass Card - Glassmorphism effekti
class GlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;

  const GlassCard({
    super.key,
    required this.child,
    this.blur = 10,
    this.opacity = 0.25,
    this.padding,
    this.margin,
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.glassWhite.withOpacity(opacity),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: AppTheme.glassBorder,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Glass Sidebar - Chap panel uchun
class GlassSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const GlassSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      margin: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SidebarItem(
            icon: Icons.dashboard_rounded,
            label: 'Dashboard',
            isSelected: selectedIndex == 0,
            onTap: () => onItemSelected(0),
          ),
          const SizedBox(height: 8),
          _SidebarItem(
            icon: Icons.inventory_2_rounded,
            label: 'Sklad',
            isSelected: selectedIndex == 1,
            onTap: () => onItemSelected(1),
          ),
          const SizedBox(height: 8),
          _SidebarItem(
            icon: Icons.point_of_sale_rounded,
            label: 'Kassa',
            isSelected: selectedIndex == 2,
            onTap: () => onItemSelected(2),
          ),
          const SizedBox(height: 8),
          _SidebarItem(
            icon: Icons.receipt_long_rounded,
            label: 'Buyurtmalar',
            isSelected: selectedIndex == 3,
            onTap: () => onItemSelected(3),
          ),
          const SizedBox(height: 8),
          _SidebarItem(
            icon: Icons.discount_rounded,
            label: 'Chegirma',
            isSelected: selectedIndex == 4,
            onTap: () => onItemSelected(4),
          ),
          const SizedBox(height: 8),
          _SidebarItem(
            icon: Icons.history_rounded,
            label: 'Savdo tarixi',
            isSelected: selectedIndex == 5,
            onTap: () => onItemSelected(5),
          ),
          const SizedBox(height: 8),
          _SidebarItem(
            icon: Icons.analytics_rounded,
            label: 'Hisobot',
            isSelected: selectedIndex == 6,
            onTap: () => onItemSelected(6),
          ),
          const SizedBox(height: 8),
          _SidebarItem(
            icon: Icons.category_rounded,
            label: 'Kategoriyalar',
            isSelected: selectedIndex == 7,
            onTap: () => onItemSelected(7),
          ),
          const Spacer(),
          _SidebarItem(
            icon: Icons.settings_rounded,
            label: 'Sozlama',
            isSelected: selectedIndex == 8,
            onTap: () => onItemSelected(8),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: isSelected 
                ? AppTheme.accentOrange.withOpacity(0.2) 
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            color: isSelected ? AppTheme.accentOrange : AppTheme.textSecondary,
            size: 28,
          ),
        ),
      ),
    );
  }
}

/// Stat Card - Dashboard vidjetlari uchun
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final Widget? chart;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor,
    this.chart,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (iconColor ?? AppTheme.accentOrange).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? AppTheme.accentOrange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
