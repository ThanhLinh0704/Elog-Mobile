import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // Brand colors
  static const Color primary = Color(0xFF1E40AF); // Deep blue
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF1E3A8A);
  static const Color accent = Color(0xFF0EA5E9); // Sky blue

  // Status colors
  static const Color statusDispatched = Color(0xFF6B7280); // Gray
  static const Color statusInProgress = Color(0xFF2563EB); // Blue
  static const Color statusCompleted = Color(0xFF16A34A); // Green
  static const Color statusException = Color(0xFFDC2626); // Red
  static const Color statusPending = Color(0xFF9CA3AF); // Light gray

  // Surface colors
  static const Color background = Color(0xFFF1F5F9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFE2E8F0);

  // Warning
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);

  // Text
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 3,
        shadowColor: Colors.black26,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: primary.withOpacity(0.4),
          minimumSize: const Size(double.infinity, 52),
          elevation: 1,
          shadowColor: primary.withOpacity(0.35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(double.infinity, 52),
          side: const BorderSide(color: primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: surfaceVariant.withOpacity(0.8)),
        ),
        margin: EdgeInsets.zero,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE2E8F0),
        thickness: 1,
      ),
    );
  }

  // ── Status badge helpers ─────────────────────────────────────────────────

  static Color tripStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'DISPATCHED':
        return statusDispatched;
      case 'IN_PROGRESS':
        return statusInProgress;
      case 'COMPLETED':
        return statusCompleted;
      case 'VALIDATED':
        return const Color(0xFF8B5CF6);
      default:
        return statusPending;
    }
  }

  static String tripStatusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'DISPATCHED':
        return 'Chờ khởi hành';
      case 'IN_PROGRESS':
        return 'Đang thực hiện';
      case 'COMPLETED':
        return 'Đã hoàn thành';
      case 'VALIDATED':
        return 'Chưa điều phối';
      default:
        return status;
    }
  }

  static IconData tripStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'DISPATCHED':
        return Icons.schedule_rounded;
      case 'IN_PROGRESS':
        return Icons.local_shipping_rounded;
      case 'COMPLETED':
        return Icons.check_circle_rounded;
      case 'VALIDATED':
        return Icons.rule_folder_outlined;
      default:
        return Icons.hourglass_empty_rounded;
    }
  }

  static Color stopStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return statusPending;
      case 'IN_PROGRESS':
        return statusInProgress;
      case 'COMPLETED':
        return statusCompleted;
      case 'EXCEPTION':
        return statusException;
      default:
        return statusPending;
    }
  }

  static String stopStatusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Chờ đến';
      case 'IN_PROGRESS':
        return 'Đang giao';
      case 'COMPLETED':
        return 'Đã hoàn thành';
      case 'EXCEPTION':
        return 'Có ngoại lệ';
      default:
        return status;
    }
  }
}
