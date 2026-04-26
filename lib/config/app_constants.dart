// lib/config/app_constants.dart

/// Global constants used across the PulseNews application.
/// Centralising here prevents magic numbers scattered through the codebase.
class AppConstants {
  AppConstants._(); // Non-instantiable utility class

  // ── API ────────────────────────────────────────────────────────────────────
  static const int pageSize = 20;
  static const int paginationLoadSize = 20;

  // ── Bonus: Search Debounce ─────────────────────────────────────────────────
  /// API call is delayed by this duration after the user stops typing.
  static const Duration debounceDelay = Duration(milliseconds: 400);

  // ── Bonus: In-Memory Cache ─────────────────────────────────────────────────
  /// Cached data is considered fresh for this duration.
  static const Duration cacheTtl = Duration(minutes: 5);

  // ── Countries — Minimum 5 required by assignment ──────────────────────────
  static const List<CountryOption> countries = [
    CountryOption(code: 'us', name: 'United States', flag: '🇺🇸'),
    CountryOption(code: 'gb', name: 'United Kingdom', flag: '🇬🇧'),
    CountryOption(code: 'de', name: 'Germany',        flag: '🇩🇪'),
    CountryOption(code: 'fr', name: 'France',         flag: '🇫🇷'),
    CountryOption(code: 'au', name: 'Australia',      flag: '🇦🇺'),
    CountryOption(code: 'in', name: 'India',          flag: '🇮🇳'),
    CountryOption(code: 'ca', name: 'Canada',         flag: '🇨🇦'),
    CountryOption(code: 'et', name: 'Ethiopia',       flag: '🇪🇹'),
    CountryOption(code: 'za', name: 'South Africa',   flag: '🇿🇦'),
    CountryOption(code: 'jp', name: 'Japan',          flag: '🇯🇵'),
  ];

  // ── Strings ────────────────────────────────────────────────────────────────
  static const String appName = 'PulseNews';
  static const String errorNoInternet =
      'No internet connection.\nCheck your network and try again.';
  static const String errorTimeout =
      'Request timed out.\nThe server may be busy. Please try again.';
  static const String errorFormat =
      'Unexpected data format received from the server.';
  static const String errorGeneric = 'An unexpected error occurred.';
}

/// Immutable value object representing a country option in the dropdown.
class CountryOption {
  final String code;
  final String name;
  final String flag;

  const CountryOption({
    required this.code,
    required this.name,
    required this.flag,
  });

  String get displayLabel => '$flag  $name';
}
