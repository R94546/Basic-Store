import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// ZARA-style Editorial Theme with Google Fonts
class CustomerTheme {
  // Colors - Strictly Monochrome
  static const Color background = Colors.white;
  static const Color surface = Colors.white;
  static const Color textPrimary = Colors.black;
  static const Color textSecondary = Color(0xFF666666);
  static const Color accent = Colors.black;
  static const Color divider = Color(0xFFEEEEEE);
  
  static ThemeData get lightTheme {
    // ZARA uses a Didone-style serif font (like Bodoni or Didot)
    // Playfair Display is the closest Google Fonts alternative
    final headingFont = GoogleFonts.playfairDisplay();
    final bodyFont = GoogleFonts.inter(); // Clean sans-serif for body
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: Colors.black,
      scaffoldBackgroundColor: Colors.white,
      
      colorScheme: const ColorScheme.light(
        primary: Colors.black,
        secondary: Colors.black,
        surface: Colors.white,
        error: Color(0xFFD32F2F),
      ),
      
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black, size: 24),
        actionsIconTheme: const IconThemeData(color: Colors.black, size: 24),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: GoogleFonts.playfairDisplay(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 2.0,
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
          textStyle: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.0,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black,
          side: const BorderSide(color: Colors.black, width: 1),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
          textStyle: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.0,
          ),
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide.none,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide.none,
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Colors.black, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: GoogleFonts.inter(
          color: Colors.grey, 
          fontSize: 14,
          letterSpacing: 0.5,
        ),
      ),

      textTheme: TextTheme(
        // Display - Large headlines (ZARA style)
        displayLarge: GoogleFonts.playfairDisplay(
          fontSize: 56, 
          fontWeight: FontWeight.bold, 
          color: Colors.black,
          letterSpacing: -1.0,
          height: 0.9,
        ),
        displayMedium: GoogleFonts.playfairDisplay(
          fontSize: 40, 
          fontWeight: FontWeight.bold, 
          color: Colors.black,
          letterSpacing: 0,
        ),
        displaySmall: GoogleFonts.playfairDisplay(
          fontSize: 32, 
          fontWeight: FontWeight.bold, 
          color: Colors.black,
        ),
        // Headlines
        headlineLarge: GoogleFonts.playfairDisplay(
          fontSize: 28, 
          fontWeight: FontWeight.bold, 
          color: Colors.black,
          letterSpacing: 1.0,
        ),
        headlineMedium: GoogleFonts.playfairDisplay(
          fontSize: 24, 
          fontWeight: FontWeight.bold, 
          color: Colors.black,
        ),
        // Titles - Product names
        titleLarge: GoogleFonts.inter(
          fontSize: 14, 
          fontWeight: FontWeight.w600, 
          color: Colors.black,
          letterSpacing: 1.0,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 12, 
          fontWeight: FontWeight.w500, 
          color: Colors.black,
          letterSpacing: 0.5,
        ),
        // Body text
        bodyLarge: GoogleFonts.inter(
          fontSize: 14, 
          color: Colors.black,
          letterSpacing: 0.3,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 12, 
          color: Color(0xFF333333),
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 10, 
          color: Color(0xFF666666),
          letterSpacing: 0.5,
        ),
        // Labels
        labelLarge: GoogleFonts.inter(
          fontSize: 12, 
          fontWeight: FontWeight.w600,
          letterSpacing: 2.0,
          color: Colors.black,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 10, 
          fontWeight: FontWeight.w500,
          letterSpacing: 1.5,
          color: Colors.grey,
        ),
      ),
      
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showSelectedLabels: false,
        showUnselectedLabels: false,
      ),
      
      dividerTheme: const DividerThemeData(
        color: Color(0xFFEEEEEE),
        thickness: 1,
        space: 1,
      ),
    );
  }
}
