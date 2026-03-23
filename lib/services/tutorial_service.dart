// lib/services/tutorial_service.dart
//
// Tracks whether the first-launch home-screen tutorial has already been shown.
// Backed by SharedPreferences (same instance used by StorageService).

import 'package:shared_preferences/shared_preferences.dart';

class TutorialService {
  static final TutorialService _instance = TutorialService._internal();
  factory TutorialService() => _instance;
  TutorialService._internal();

  static const String _kHomeTutorialSeen = 'home_tutorial_seen';

  /// Returns true if the user has NOT yet seen the home tutorial.
  Future<bool> shouldShowHomeTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_kHomeTutorialSeen) ?? false);
  }

  /// Call once the tutorial finishes (or is skipped) to never show it again.
  Future<void> markHomeTutorialSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHomeTutorialSeen, true);
  }

  /// Dev-only helper: resets the flag so the tutorial shows again on next launch.
  Future<void> resetForDebug() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kHomeTutorialSeen);
  }
}