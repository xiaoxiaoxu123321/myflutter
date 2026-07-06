import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class AuthSession {
  static const _isLoggedInKey = 'auth.isLoggedIn';
  static const _isGuestKey = 'auth.isGuest';
  static const _tokenKey = 'auth.token';
  static const _userKey = 'auth.user';

  static bool isLoggedIn = false;
  static bool isGuest = false;
  static String? token;
  static Map<String, dynamic>? user;
  static final StreamController<void> _expiredController = StreamController<void>.broadcast();

  static Stream<void> get expiredStream => _expiredController.stream;

  static Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
    isGuest = prefs.getBool(_isGuestKey) ?? false;
    token = prefs.getString(_tokenKey);

    final userJson = prefs.getString(_userKey);
    if (userJson == null || userJson.isEmpty) {
      user = null;
      return;
    }
    try {
      final decoded = jsonDecode(userJson);
      user = decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      user = null;
    }
  }

  static Future<void> enterGuestMode() async {
    isLoggedIn = false;
    isGuest = true;
    token = null;
    user = null;
    await _save();
  }

  static Future<void> enterUserMode({
    required String? authToken,
    required Map<String, dynamic>? currentUser,
  }) async {
    isLoggedIn = authToken != null && authToken.isNotEmpty;
    isGuest = false;
    token = authToken;
    user = currentUser;
    await _save();
  }

  static Future<void> updateUser(Map<String, dynamic>? currentUser) async {
    user = currentUser;
    await _save();
  }

  static Future<void> clear() async {
    isLoggedIn = false;
    isGuest = false;
    token = null;
    user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isLoggedInKey);
    await prefs.remove(_isGuestKey);
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  static Future<void> expire() async {
    if (!isLoggedIn && token == null && user == null) return;
    await clear();
    _expiredController.add(null);
  }

  static Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, isLoggedIn);
    await prefs.setBool(_isGuestKey, isGuest);
    if (token == null || token!.isEmpty) {
      await prefs.remove(_tokenKey);
    } else {
      await prefs.setString(_tokenKey, token!);
    }
    if (user == null) {
      await prefs.remove(_userKey);
    } else {
      await prefs.setString(_userKey, jsonEncode(user));
    }
  }
}
