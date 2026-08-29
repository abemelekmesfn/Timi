import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final languageProvider = StateNotifierProvider<LanguageNotifier, Locale>((ref) {
  return LanguageNotifier();
});

class LanguageNotifier extends StateNotifier<Locale> {
  LanguageNotifier() : super(const Locale("am")) {
    load();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString("language") ?? "am";
    state = Locale(code);
  }

  Future<void> change(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("language", code);
    state = Locale(code);
  }
}
