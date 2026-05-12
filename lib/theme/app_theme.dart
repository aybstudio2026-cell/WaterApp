import 'package:flutter/material.dart';

class AppTheme {
  // Colores base
  static const primary     = Color(0xFF2D5BE3);
  static const primaryLight = Color(0xFF4A90D9);
  static const secondary   = Color(0xFF2D7A4F);
  static const bgLight     = Color(0xFFF4F6FA);
  static const bgDark      = Color(0xFF0F1117);
  static const cardLight   = Color(0xFFFFFFFF);
  static const cardDark    = Color(0xFF1A1D27);
  static const cardDark2   = Color(0xFF222536);

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: primaryLight,
      brightness: Brightness.light,
      scaffoldBackgroundColor: bgLight,
      cardColor: cardLight,
      fontFamily: 'Arial',
      appBarTheme: const AppBarTheme(
        backgroundColor: bgLight,
        foregroundColor: Color(0xFF1A2E6E),
        elevation: 0,
      ),
      extensions: const [AppColors.light()],
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: primaryLight,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      cardColor: cardDark,
      fontFamily: 'Arial',
      appBarTheme: const AppBarTheme(
        backgroundColor: bgDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      extensions: const [AppColors.dark()],
    );
  }
}

// Extensión con todos los colores personalizados
@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color bg;
  final Color card;
  final Color card2;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color border;
  final Color inputBg;
  final Color statBlue;
  final Color statGreen;
  final Color statOrange;

  const AppColors({
    required this.bg,
    required this.card,
    required this.card2,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.inputBg,
    required this.statBlue,
    required this.statGreen,
    required this.statOrange,
  });

  const AppColors.light()
      : bg            = const Color(0xFFF4F6FA),
        card          = const Color(0xFFFFFFFF),
        card2         = const Color(0xFFF9FAFB),
        textPrimary   = const Color(0xFF1A2E6E),
        textSecondary = const Color(0xFF374151),
        textMuted     = const Color(0xFF6B7280),
        border        = const Color(0xFFE5E7EB),
        inputBg       = const Color(0xFFFFFFFF),
        statBlue      = const Color(0xFFD6E4FF),
        statGreen     = const Color(0xFFD6F5E3),
        statOrange    = const Color(0xFFFFEDD5);

  const AppColors.dark()
      : bg            = const Color(0xFF0F1117),
        card          = const Color(0xFF1A1D27),
        card2         = const Color(0xFF222536),
        textPrimary   = const Color(0xFFE8EAFF),
        textSecondary = const Color(0xFFB0B7C3),
        textMuted     = const Color(0xFF6B7280),
        border        = const Color(0xFF2A2D3E),
        inputBg       = const Color(0xFF1A1D27),
        statBlue      = const Color(0xFF1A2340),
        statGreen     = const Color(0xFF0D2318),
        statOrange    = const Color(0xFF2A1A0A);

  @override
  AppColors copyWith({
    Color? bg, Color? card, Color? card2,
    Color? textPrimary, Color? textSecondary, Color? textMuted,
    Color? border, Color? inputBg,
    Color? statBlue, Color? statGreen, Color? statOrange,
  }) {
    return AppColors(
      bg:            bg            ?? this.bg,
      card:          card          ?? this.card,
      card2:         card2         ?? this.card2,
      textPrimary:   textPrimary   ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted:     textMuted     ?? this.textMuted,
      border:        border        ?? this.border,
      inputBg:       inputBg       ?? this.inputBg,
      statBlue:      statBlue      ?? this.statBlue,
      statGreen:     statGreen     ?? this.statGreen,
      statOrange:    statOrange    ?? this.statOrange,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      bg:            Color.lerp(bg, other.bg, t)!,
      card:          Color.lerp(card, other.card, t)!,
      card2:         Color.lerp(card2, other.card2, t)!,
      textPrimary:   Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted:     Color.lerp(textMuted, other.textMuted, t)!,
      border:        Color.lerp(border, other.border, t)!,
      inputBg:       Color.lerp(inputBg, other.inputBg, t)!,
      statBlue:      Color.lerp(statBlue, other.statBlue, t)!,
      statGreen:     Color.lerp(statGreen, other.statGreen, t)!,
      statOrange:    Color.lerp(statOrange, other.statOrange, t)!,
    );
  }

  // Helper para acceder desde cualquier widget
  static AppColors of(BuildContext context) {
    return Theme.of(context).extension<AppColors>()!;
  }
}