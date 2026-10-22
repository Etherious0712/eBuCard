import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'business_card.dart';

/// Keeps the user's own card on the device.
class CardStore {
  static const _key = 'my_card';

  Future<BusinessCard?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    return BusinessCard.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> save(BusinessCard card) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(card.toJson()));
  }
}
