import 'package:flutter/material.dart';

/// Warna brand BengkelKu — sama di mode terang & gelap.
/// Dipakai sebagai `static const` agar tetap kompatibel dengan layar lama
/// yang menulis `AppColors.primary` secara langsung.
class AppColors {
  AppColors._();

  // Brand colors (tidak berubah antar mode)
  static const Color primary = Color(0xFF1B2440); // Navy
  static const Color primaryLight = Color(0xFF2C4356);
  static const Color primaryDark = Color(0xFF101630);
  static const Color accent = Color(0xFF1B3A5E); // Aksen navy lebih terang
  static const Color success = Color(0xFF00C853);
  static const Color error = Color(0xFFD32F2F);
  static const Color link = Color(0xFF1976D2);
  static const Color warning = Color(0xFFFF9800);

  // Legacy defaults (mode terang) — tetap dipertahankan untuk kompatibilitas
  // layar yang belum dimigrasi. Layar baru wajib pakai context.colors.
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF5F6F8);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF8C8C8C);
  static const Color border = Color(0xFFE5E5E5);
}

/// Skema warna adaptif yang nilainya bergantung pada [Brightness].
/// Akses lewat `context.colors` (extension di bawah) supaya otomatis ikut
/// tema aktif (terang/gelap/ikut sistem).
class AppColorScheme {
  final Brightness brightness;

  const AppColorScheme({required this.brightness});

  bool get isDark => brightness == Brightness.dark;

  /// Latar utama layar.
  Color get background => isDark ? const Color(0xFF0F1115) : const Color(0xFFFFFFFF);

  /// Latar kartu / input field.
  Color get surface => isDark ? const Color(0xFF1A1D24) : const Color(0xFFF5F6F8);

  /// Latar kartu yang sedikit lebih terang dari surface (untuk nesting).
  Color get surfaceVariant =>
      isDark ? const Color(0xFF242832) : const Color(0xFFFFFFFF);

  /// Teks utama.
  Color get textPrimary =>
      isDark ? const Color(0xFFF3F4F6) : const Color(0xFF1A1A1A);

  /// Teks sekunder / hint.
  Color get textSecondary =>
      isDark ? const Color(0xFF9CA3AF) : const Color(0xFF8C8C8C);

  /// Garis pembatas.
  Color get border =>
      isDark ? const Color(0xFF2D3139) : const Color(0xFFE5E5E5);

  /// Warna divider halus.
  Color get divider =>
      isDark ? const Color(0xFF262A32) : const Color(0xFFEEEEEE);

  /// Warna untuk shader/glow overlay di header gelap.
  Color get overlay => isDark
      ? Colors.white.withValues(alpha: 0.06)
      : Colors.black.withValues(alpha: 0.04);

  /// Header gradient navy dipakai di layar auth (mirip di kedua mode,
  /// hanya sedikit disesuaikan untuk dark).
  List<Color> get authHeaderGradient => isDark
      ? [const Color(0xFF16203A), const Color(0xFF0B0F1C)]
      : [AppColors.primary, AppColors.primaryDark];
}

/// Extension agar `context.colors` langsung resolve skema warna aktif.
extension AppColorSchemeContext on BuildContext {
  AppColorScheme get colors =>
      AppColorScheme(brightness: Theme.of(this).brightness);
}
