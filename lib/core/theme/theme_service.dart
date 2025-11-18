import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  bool _isDark = true;
  bool get isDarkMode => _isDark;

  ThemeService() {
    _loadTheme();
  }

  void toggleTheme(bool value) {
    _isDark = value;
    _saveTheme(value);
    notifyListeners();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool("darkMode") ?? true;
    notifyListeners();
  }

  Future<void> _saveTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool("darkMode", value);
  }
}
