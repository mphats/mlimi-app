import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors - Agricultural green theme
  static const Color primary = Color(0xFF1B5E20); // Refined deep green
  static const Color primaryLight = Color(0xFF43A047); 
  static const Color primaryDark = Color(0xFF0D3311);

  // Secondary Colors - Harvest theme (Gold/Amber)
  static const Color secondary = Color(0xFFF9A825); // Premium Gold
  static const Color secondaryLight = Color(0xFFFFD54F);
  static const Color secondaryDark = Color(0xFFC42500);

  // Surface & Glassmorphism
  static const Color glassSurface = Color(0x33FFFFFF);
  static const Color glassBorder = Color(0x4DFFFFFF);
  static const Color cardShadowPremium = Color(0x1A000000);

  // Refined Backgrounds
  static const Color background = Color(0xFFFDFDFD);
  static const Color backgroundLight = Colors.white;
  static const Color backgroundDark = Color(0xFFF5F7F5); // Subtle green tint

  // ... (keeping other colors as is, but updating the primary for a richer look)
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF1F4F1);

  // Status Colors
  static const Color success = Color(0xFF2E7D32);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color error = Color(0xFFD32F2F);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color warning = Color(0xFFFFA000);
  static const Color info = Color(0xFF0288D1);

  // Text Colors
  static const Color textPrimary = Color(0xFF1A1C1A); // Almost black with green tint
  static const Color textSecondary = Color(0xFF5F635F);
  static const Color textDisabled = Color(0xFFA1A3A1);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textInverse = Colors.white;

  // Border
  static const Color border = Color(0xFFE0E4E0);
  static const Color divider = Color(0xFFF1F1F1);

  // Final Premium Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
  );

  static const LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x4DFFFFFF),
      Color(0x1AFFFFFF),
    ],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF9A825), Color(0xFFF57C00)],
  );

  // Missing colors required by app components
  static const Color inputBackground = Color(0xFFF5F7F5);
  static const Color inputBorder = Color(0xFFE0E4E0);
  static const Color inputBorderFocused = Color(0xFF1B5E20);
  static const Color inputBorderError = Color(0xFFD32F2F);
  static const Color buttonDisabled = Color(0xFFE0E4E0);
  static const Color cardBackground = Colors.white;
  static const Color cardShadow = Color(0x1A000000);
  static const Color borderLight = Color(0xFFF1F1F1);
  
  // Category colors for market prices
  static const Map<String, Color> categoryColors = {
    'GRAINS': Color(0xFF2E7D32),
    'VEGETABLES': Color(0xFF00838F),
    'FRUITS': Color(0xFFAD1457),
    'LIVESTOCK': Color(0xFF1565C0),
    'POULTRY': Color(0xFFE65100),
    'Crops': Color(0xFF2E7D32),
    'Livestock': Color(0xFF1565C0),
    'Poultry': Color(0xFFE65100),
    'Vegetables': Color(0xFF00838F),
    'Fruits': Color(0xFFAD1457),
    'OTHER': Color(0xFF757575),
  };
}
