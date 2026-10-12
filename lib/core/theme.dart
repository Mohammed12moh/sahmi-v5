import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ألوان التصميم / Design tokens
class C {
  static const green = Color(0xFF00D09C);
  static const red = Color(0xFFFF4757);
  static const gold = Color(0xFFFFD700);
  static const navy = Color(0xFF0A0E27);
  static const surface = Color(0xFF151A35);
  static const card = Color(0xFF1A2040);
}

ThemeData buildTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  final text = GoogleFonts.cairoTextTheme(base.textTheme)
      .apply(bodyColor: Colors.white, displayColor: Colors.white);
  return base.copyWith(
    scaffoldBackgroundColor: C.navy,
    colorScheme: const ColorScheme.dark(
        primary: C.green, secondary: C.gold, surface: C.surface, error: C.red),
    textTheme: text,
    appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent, elevation: 0, centerTitle: true),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: C.card,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: C.green, width: 1.5)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: C.surface,
      indicatorColor: C.green.withValues(alpha: .2),
      labelTextStyle: WidgetStatePropertyAll(GoogleFonts.cairo(fontSize: 12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: C.green,
        foregroundColor: C.navy,
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 16),
      ),
    ),
  );
}

/// زر بتوهج / Glow button
class GlowButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  const GlowButton(this.label, {super.key, this.onPressed, this.loading = false});
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: C.green.withValues(alpha: .4), blurRadius: 22)],
        ),
        child: ElevatedButton(
          onPressed: loading ? null : onPressed,
          child: loading
              ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: C.navy))
              : Text(label),
        ),
      );
}
