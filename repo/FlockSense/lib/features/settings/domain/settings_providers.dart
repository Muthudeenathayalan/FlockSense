import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/features/settings/data/models/user_preferences_model.dart';
import 'package:flock_sense/features/settings/data/services/settings_service.dart';

class SettingsNotifier extends Notifier<UserPreferencesModel> {
  @override
  UserPreferencesModel build() {
    Future.microtask(() async {
      final pref = await SettingsService.loadLocalPreferences();
      state = pref;
    });
    return SettingsService.getCachedPreferences();
  }

  Future<void> updateSettings(UserPreferencesModel newSettings) async {
    state = newSettings;
    await SettingsService.savePreferences(newSettings);
  }

  Future<void> updateThemeMode(String mode) async {
    final updated = state.copyWith(themeMode: mode);
    await updateSettings(updated);
  }

  Future<void> updateLanguage(String code) async {
    final updated = state.copyWith(languageCode: code);
    await updateSettings(updated);
  }

  Future<void> updateUnits({
    String? weightUnit,
    String? distanceUnit,
    String? temperatureUnit,
    String? currency,
  }) async {
    final updated = state.copyWith(
      weightUnit: weightUnit,
      distanceUnit: distanceUnit,
      temperatureUnit: temperatureUnit,
      currency: currency,
    );
    await updateSettings(updated);
  }

  Future<void> updateAiSettings({
    String? aiModel,
    String? responseStyle,
    bool? aiMemoryEnabled,
    bool? useFarmContext,
    bool? useBatchContext,
    bool? imageAnalysis,
    bool? fileAnalysis,
    bool? streamingResponses,
  }) async {
    final updated = state.copyWith(
      aiModel: aiModel,
      responseStyle: responseStyle,
      aiMemoryEnabled: aiMemoryEnabled,
      useFarmContext: useFarmContext,
      useBatchContext: useBatchContext,
      imageAnalysis: imageAnalysis,
      fileAnalysis: fileAnalysis,
      streamingResponses: streamingResponses,
    );
    await updateSettings(updated);
  }

  Future<void> updateNotificationToggles({
    bool? pushEnabled,
    bool? aiNotifsEnabled,
    bool? dailySummaryEnabled,
    bool? vaccineAlertsEnabled,
    bool? inventoryAlertsEnabled,
    bool? financeAlertsEnabled,
    bool? vibration,
    String? sound,
  }) async {
    final updated = state.copyWith(
      pushEnabled: pushEnabled,
      aiNotifsEnabled: aiNotifsEnabled,
      dailySummaryEnabled: dailySummaryEnabled,
      vaccineAlertsEnabled: vaccineAlertsEnabled,
      inventoryAlertsEnabled: inventoryAlertsEnabled,
      financeAlertsEnabled: financeAlertsEnabled,
      vibration: vibration,
      notificationSound: sound,
    );
    await updateSettings(updated);
  }

  Future<void> clearCache() async {
    await SettingsService.clearCache();
    state = state.copyWith(cacheSizeMb: 0.0);
  }

  Future<void> resetSettings() async {
    await SettingsService.resetSettings();
    state = UserPreferencesModel();
  }
}

final settingsNotifierProvider =
    NotifierProvider<SettingsNotifier, UserPreferencesModel>(
  SettingsNotifier.new,
);

final currentUserProvider = Provider<User?>((ref) {
  return FirebaseAuth.instance.currentUser;
});
