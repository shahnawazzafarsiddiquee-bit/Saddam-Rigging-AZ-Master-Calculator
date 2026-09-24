import 'package:flutter/material.dart';

/// Professional industrial engineering theme.
/// Primary: Dark Navy Blue | Accent: Safety Orange | Background: Industrial Dark Grey
///
/// Contrast note: the navy here is kept a bit brighter than a near-black
/// navy so it still reads as "blue" (not just dark) even in strong sunlight
/// on a phone screen, and every AppBar gets a bright safety-orange strip
/// underneath it so the header is always visible at a glance on site.
class AppColors {
  static const Color navy = Color(0xFF15335C);
  static const Color navyLight = Color(0xFF2A4E85);
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
      // Primary is orange, not navy: FilledButton, TextButton, switches, checkboxes and
      // progress bars take it, and navy on the dark background was unreadable.
      colorScheme: const ColorScheme.dark(
        primary: AppColors.safetyOrange,
        onPrimary: Colors.black,
        secondary: AppColors.safetyOrange,
        onSecondary: Colors.black,
        surface: AppColors.cardGrey,
        error: AppColors.danger,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.safetyOrange,
          foregroundColor: Colors.black,
          disabledBackgroundColor: Colors.white24,
          disabledForegroundColor: Colors.white70,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.safetyOrange),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white, size: 26),
        elevation: 3,
        // Material 3 tries to tint the AppBar towards the surface color as
        // the page scrolls, which is exactly what was washing the navy out
        // — this keeps it a solid, high-contrast navy at all times.
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 3,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
        // A bright orange strip under every header — always visible even
        // when the navy above it is washed out by direct sunlight.
        shape: const Border(
          bottom: BorderSide(color: AppColors.safetyOrange, width: 3),
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
