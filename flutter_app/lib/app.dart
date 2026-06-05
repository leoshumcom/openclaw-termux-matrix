import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/setup_provider.dart';
import 'providers/gateway_provider.dart';
import 'providers/node_provider.dart';
import 'screens/splash_screen.dart';

/// Matrix/Hacker-style color palette.
///
/// Based on openclaw-termux (https://github.com/mithun50/openclaw-termux)
/// — MIT License. Modifications © 2026 66哥.
class AppColors {
  AppColors._();

  // Matrix green — the star of the show
  static const Color matrixGreen = Color(0xFF00FF41);
  static const Color matrixGreenDim = Color(0xFF00CC33);
  static const Color matrixGreenDark = Color(0xFF003B00);

  // Dark backgrounds
  static const Color bg = Color(0xFF0D0D0D);
  static const Color surface = Color(0xFF111111);
  static const Color surfaceAlt = Color(0xFF1A1A1A);
  static const Color border = Color(0xFF1F3B1F);

  // Status
  static const Color statusGreen = Color(0xFF00FF41);
  static const Color statusAmber = Color(0xFFFFD700);
  static const Color statusRed = Color(0xFFFF3333);
  static const Color statusGrey = Color(0xFF3B5E3B);

  // Text
  static const Color mutedText = Color(0xFF3B7A3B);
  static const Color textPrimary = Color(0xFF00FF41);
  static const Color textSecondary = Color(0xFF8BC34A);

  // Legacy aliases for screens not yet ported to Matrix theme
  static const Color accent = matrixGreen;
  static const Color darkBg = bg;
  static const Color darkSurface = surface;
  static const Color darkSurfaceAlt = surfaceAlt;
  static const Color darkBorder = border;
}

class OpenClawApp extends StatelessWidget {
  const OpenClawApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SetupProvider()),
        ChangeNotifierProvider(create: (_) => GatewayProvider()),
        ChangeNotifierProxyProvider<GatewayProvider, NodeProvider>(
          create: (_) => NodeProvider(),
          update: (_, gatewayProvider, nodeProvider) {
            nodeProvider!.onGatewayStateChanged(gatewayProvider.state);
            return nodeProvider;
          },
        ),
      ],
      child: MaterialApp(
        title: 'OpenClaw - Matrix Edition',
        debugShowCheckedModeBanner: false,
        theme: _buildMatrixTheme(),
        darkTheme: _buildMatrixTheme(), // Matrix is always dark 💚
        themeMode: ThemeMode.dark,
        home: const SplashScreen(),
      ),
    );
  }

  ThemeData _buildMatrixTheme() {
    // Use a monospace-like font for that terminal feel
    final textTheme = GoogleFonts.jetBrainsMonoTextTheme(
      ThemeData.dark(useMaterial3: true).textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.matrixGreen,
        onPrimary: AppColors.bg,
        secondary: AppColors.matrixGreenDim,
        onSecondary: AppColors.bg,
        surface: AppColors.surface,
        onSurface: AppColors.matrixGreen,
        onSurfaceVariant: AppColors.mutedText,
        error: AppColors.statusRed,
        onError: AppColors.bg,
        outline: AppColors.border,
      ),
      textTheme: textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.matrixGreen,
        titleTextStyle: GoogleFonts.jetBrainsMono(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.matrixGreen,
          letterSpacing: 2,
        ),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: AppColors.border),
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.matrixGreen,
          foregroundColor: AppColors.bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: GoogleFonts.jetBrainsMono(
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.matrixGreen,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: GoogleFonts.jetBrainsMono(
            letterSpacing: 1,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.matrixGreen,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.matrixGreen, width: 1),
        ),
        labelStyle: TextStyle(color: AppColors.mutedText),
        hintStyle: TextStyle(color: AppColors.mutedText.withAlpha(100)),
        filled: true,
        fillColor: AppColors.surfaceAlt,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.matrixGreen;
          return AppColors.statusGrey;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.matrixGreen.withAlpha(60);
          }
          return AppColors.border;
        }),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.matrixGreen,
        linearTrackColor: AppColors.border,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        space: 1,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceAlt,
        contentTextStyle: GoogleFonts.jetBrainsMono(
          color: AppColors.matrixGreen,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: AppColors.border),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.mutedText,
        textColor: AppColors.textPrimary,
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.matrixGreen;
          return AppColors.statusGrey;
        }),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.bg,
        selectedItemColor: AppColors.matrixGreen,
        unselectedItemColor: AppColors.mutedText,
      ),
    );
  }
}
