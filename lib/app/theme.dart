import 'package:flutter/material.dart';

/// Professional industrial engineering theme.
/// Primary: Dark Navy Blue | Accent: Safety Orange | Background: Industrial Dark Grey
class AppColors {
  static const Color navy = Color(0xFF0D1B2A);
  static const Color navyLight = Color(0xFF1B3A5C);
  static const Color safetyOrange = Color(0xFFFF6F00);
  static const Color industrialGrey = Color(0xFF1E1E1E);
  static const Color cardGrey = Color(0xFF2A2E33);
  static const Color textLight = Color(0xFFECEFF1);
  static const Color success = Color(0xFF2E7D32);
  static const Color danger = Color(0xFFC62828);
  static const Color warning = Color(0xFFF9A825);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.industrialGrey,
      primaryColor: AppColors.navy,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.navy,
        secondary: AppColors.safetyOrange,
        surface: AppColors.cardGrey,
        error: AppColors.danger,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.navy,
        foregroundColor: AppColors.textLight,
        elevation: 2,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.textLight,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardGrey,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.safetyOrange,
          foregroundColor: Colors.black,
          minimumSize: const Size.fromHeight(56),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.safetyOrange,
          side: const BorderSide(color: AppColors.safetyOrange, width: 1.5),
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardGrey,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.safetyOrange, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.textLight),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.textLight, fontSize: 16),
        bodyMedium: TextStyle(color: AppColors.textLight, fontSize: 14),
        titleLarge: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold),
      ),
      dividerColor: Colors.white24,
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}

/// Reusable "SAFE / NOT SAFE" style status chip used across all calculators.
class SafetyStatusBanner extends StatelessWidget {
  final bool isSafe;
  final String safeText;
  final String unsafeText;

  const SafetyStatusBanner({
    super.key,
    required this.isSafe,
    this.safeText = 'SAFE',
    this.unsafeText = 'NOT SAFE',
  });

  @override
  Widget build(BuildContext context) {
    final color = isSafe ? AppColors.success : AppColors.danger;
    final icon = isSafe ? Icons.check_circle : Icons.dangerous;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 12),
          Text(
            isSafe ? safeText : unsafeText,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class ResultRow extends StatelessWidget {
  final String label;
  final String value;
  const ResultRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 15)),
          Text(value,
              style: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
