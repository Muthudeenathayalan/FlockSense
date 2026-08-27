import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flock_sense/features/settings/data/models/user_preferences_model.dart';

class SettingsService {
  SettingsService._();

  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;
  static const _prefKey = 'flocksense_user_preferences';

  static UserPreferencesModel _memoryCache = UserPreferencesModel();

  static UserPreferencesModel getCachedPreferences() => _memoryCache;

  static Future<UserPreferencesModel> loadLocalPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKey);
      if (raw != null) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        _memoryCache = UserPreferencesModel.fromJson(map);
      }
    } catch (e) {
      debugPrint('[SettingsService] loadLocalPreferences failed: $e');
    }
    return _memoryCache;
  }

  static Future<void> savePreferences(UserPreferencesModel model) async {
    _memoryCache = model;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, jsonEncode(model.toJson()));
    } catch (e) {
      debugPrint('[SettingsService] saveLocalPreferences failed: $e');
    }

    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('settings')
            .doc('preferences')
            .set(model.toJson(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('[SettingsService] syncFirestorePreferences failed: $e');
      }
    }
  }

  static Stream<UserPreferencesModel> streamPreferences() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(_memoryCache);
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('settings')
        .doc('preferences')
        .snapshots()
        .map(
          (doc) => doc.exists
              ? UserPreferencesModel.fromJson(doc.data()!)
              : _memoryCache,
        )
        .handleError((err) {
          debugPrint('[SettingsService] streamPreferences error: $err');
          return _memoryCache;
        });
  }

  // Account Actions
  static Future<void> updateProfile({
    required String displayName,
    required String phone,
  }) async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.updateDisplayName(displayName);
    }
    final updated = _memoryCache.copyWith(
      displayName: displayName,
      phone: phone,
    );
    await savePreferences(updated);
  }

  static Future<void> changePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.updatePassword(newPassword);
    }
  }

  static Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('flocksense_cached_reports');
    await prefs.remove('flocksense_cached_analytics');
    final updated = _memoryCache.copyWith(cacheSizeMb: 0.0);
    await savePreferences(updated);
  }

  static Future<void> resetSettings() async {
    final defaultModel = UserPreferencesModel();
    await savePreferences(defaultModel);
  }
}
