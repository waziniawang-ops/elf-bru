import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

final currencyFormat = NumberFormat.currency(symbol: '\$');

class AppTheme {
  // Palette derived from the Elfbru logo — dusty periwinkle blue + champagne
  static const Color primary     = Color(0xFF6B8FAD); // logo blue — dusty periwinkle
  static const Color primaryDark = Color(0xFF4B7090); // deeper slate blue
  static const Color gold        = Color(0xFFC4A96B); // warm champagne accent
  static const Color bgDark      = Color(0xFFF7F9FB); // icy crisp white bg
  static const Color surfaceDark = Color(0xFFFFFFFF); // pure white card
  static const Color surfaceMid  = Color(0xFFEDF3F8); // light blue-tinted surface
  static const Color borderColor = Color(0xFFCFE0EC); // soft blue-grey border
  static const Color textPrimary = Color(0xFF16243A); // deep navy text
  static const Color textMuted   = Color(0xFF6E88A0); // blue-grey muted text

  // Convenience — used where "silver" sheen is needed
  static const Color silver = Color(0xFFB0C6D8);

  static ThemeData get theme {
    final base = ThemeData(useMaterial3: true);
    final tt = GoogleFonts.cormorantGaramondTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.cormorantGaramond(
          color: textPrimary, fontWeight: FontWeight.w300),
      displayMedium: GoogleFonts.cormorantGaramond(
          color: textPrimary, fontWeight: FontWeight.w300),
      headlineLarge: GoogleFonts.cormorantGaramond(
          color: textPrimary, fontWeight: FontWeight.w400),
      headlineMedium: GoogleFonts.cormorantGaramond(
          color: textPrimary, fontWeight: FontWeight.w400),
      titleLarge: GoogleFonts.lato(
          color: textPrimary, fontWeight: FontWeight.w400, letterSpacing: 0.5),
      titleMedium: GoogleFonts.lato(
          color: textPrimary, fontWeight: FontWeight.w500),
      bodyLarge: GoogleFonts.lato(color: textPrimary),
      bodyMedium: GoogleFonts.lato(color: textPrimary),
      bodySmall: GoogleFonts.lato(color: textMuted, fontSize: 12),
      labelLarge: GoogleFonts.lato(
          color: textPrimary, fontWeight: FontWeight.w600, letterSpacing: 1.2),
      labelSmall: GoogleFonts.lato(
          color: textMuted, fontSize: 10, letterSpacing: 1.5),
    );

    return base.copyWith(
      textTheme: tt,
      scaffoldBackgroundColor: bgDark,
      colorScheme: const ColorScheme.light(
        primary: primary,
        onPrimary: Colors.white,
        secondary: primaryDark,
        onSecondary: Colors.white,
        surface: surfaceDark,
        onSurface: textPrimary,
        outline: borderColor,
        tertiary: gold,
        onTertiary: Colors.white,
        error: Color(0xFFD65757),
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceDark,
        foregroundColor: textPrimary,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: GoogleFonts.cormorantGaramond(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w300,
          letterSpacing: 3,
        ),
        iconTheme: const IconThemeData(color: textMuted),
        actionsIconTheme: const IconThemeData(color: textMuted),
        shape: const Border(
          bottom: BorderSide(color: borderColor, width: 0.8),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceDark,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        indicatorColor: primary.withAlpha(40),
        height: 64,
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              color:
                  states.contains(WidgetState.selected) ? primary : textMuted,
              size: 22,
            )),
        labelTextStyle:
            WidgetStateProperty.resolveWith((states) => GoogleFonts.lato(
                  color: states.contains(WidgetState.selected)
                      ? primary
                      : textMuted,
                  fontSize: 11,
                  fontWeight: states.contains(WidgetState.selected)
                      ? FontWeight.w600
                      : FontWeight.w400,
                  letterSpacing: 0.3,
                )),
      ),
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderColor, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: primary.withAlpha(70),
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 15),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          textStyle: GoogleFonts.lato(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.8,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          textStyle: GoogleFonts.lato(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.8,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.lato(letterSpacing: 0.3),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceMid,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD65757)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD65757), width: 1.5),
        ),
        labelStyle: GoogleFonts.lato(color: textMuted, fontSize: 14),
        hintStyle: GoogleFonts.lato(color: textMuted),
        prefixIconColor: textMuted,
        suffixIconColor: textMuted,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      dividerTheme: const DividerThemeData(color: borderColor, thickness: 1),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceMid,
        selectedColor: primary.withAlpha(40),
        labelStyle: GoogleFonts.lato(color: textPrimary, fontSize: 12),
        side: const BorderSide(color: borderColor),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        checkmarkColor: primary,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? primary : textMuted),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? primary.withAlpha(80)
                : borderColor),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? primary : textMuted),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? primary : Colors.transparent),
        side: const BorderSide(color: textMuted),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: surfaceMid,
        textStyle: TextStyle(color: textPrimary),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          side: BorderSide(color: borderColor),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceDark,
        elevation: 24,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderColor),
        ),
        titleTextStyle: GoogleFonts.cormorantGaramond(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
        contentTextStyle:
            GoogleFonts.lato(color: textPrimary, height: 1.6),
      ),
      listTileTheme: const ListTileThemeData(
        textColor: textPrimary,
        iconColor: textMuted,
        tileColor: Colors.transparent,
      ),
      expansionTileTheme: const ExpansionTileThemeData(
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        textColor: textPrimary,
        iconColor: textMuted,
        collapsedTextColor: textPrimary,
        collapsedIconColor: textMuted,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        thumbColor: primary,
        inactiveTrackColor: borderColor,
        overlayColor: primary.withAlpha(30),
        valueIndicatorColor: primary,
        valueIndicatorTextStyle: const TextStyle(color: Colors.white),
      ),
      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: primary),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceMid,
        contentTextStyle: GoogleFonts.lato(color: textPrimary),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),
      badgeTheme: const BadgeThemeData(
        backgroundColor: primary,
        textColor: Colors.white,
        smallSize: 8,
      ),
      dropdownMenuTheme: const DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(surfaceMid),
        ),
      ),
    );
  }
}

void showSnack(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor:
          isError ? const Color(0xFF8B3030) : AppTheme.surfaceMid,
    ),
  );
}
