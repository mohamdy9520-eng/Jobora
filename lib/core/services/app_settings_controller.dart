import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Central, app-wide user preferences: language, currency, theme,
/// and onboarding completion. Persisted locally; synced to Firestore
/// (users/{uid}) once the user is authenticated — see AuthRepository.
class AppSettingsController extends ChangeNotifier {
  static const _kLanguageKey = 'settings_language';
  static const _kCurrencyKey = 'settings_currency';
  static const _kThemeModeKey = 'settings_theme_mode';
  static const _kOnboardingDoneKey = 'settings_onboarding_done';

  Locale _locale = const Locale('en');
  String _currency = 'USD';
  ThemeMode _themeMode = ThemeMode.system;
  bool _onboardingCompleted = false;
  bool _isLoaded = false;

  Locale get locale => _locale;
  String get currency => _currency;
  ThemeMode get themeMode => _themeMode;
  bool get onboardingCompleted => _onboardingCompleted;
  bool get isLoaded => _isLoaded;

  static const supportedCurrencies = ['USD', 'EUR', 'GBP', 'EGP', 'SAR', 'AED'];

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString(_kLanguageKey);
    if (lang != null) _locale = Locale(lang);
    _currency = prefs.getString(_kCurrencyKey) ?? 'USD';
    final theme = prefs.getString(_kThemeModeKey);
    _themeMode = switch (theme) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    _onboardingCompleted = prefs.getBool(_kOnboardingDoneKey) ?? false;
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLanguageKey, locale.languageCode);
  }

  Future<void> setCurrency(String currency) async {
    _currency = currency;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCurrencyKey, currency);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeModeKey, mode.name);
  }

  Future<void> completeOnboarding() async {
    _onboardingCompleted = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboardingDoneKey, true);
  }
}
