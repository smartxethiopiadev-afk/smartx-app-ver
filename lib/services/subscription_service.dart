import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SubscriptionService {
  static const String _unlockedKey = 'smartx_unlocked_packages';
  static Set<String> _unlockedPackages = {};
  static bool _isLoaded = false;
  static final List<VoidCallback> _listeners = [];

  static void addListener(VoidCallback listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }

  static void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  static void _notifyListeners() {
    for (final listener in _listeners) {
      try {
        listener();
      } catch (e) {
        debugPrint("[SubscriptionService] Listener error: $e");
      }
    }
  }

  /// Initialize local subscription state
  static Future<void> init() async {
    if (_isLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? savedList = prefs.getStringList(_unlockedKey);
      if (savedList != null) {
        _unlockedPackages = savedList.toSet();
      }
      _isLoaded = true;
    } catch (e) {
      debugPrint("[SubscriptionService] Init error: $e");
    }
  }

  /// Check if a specific package is unlocked
  static Future<bool> isPackageUnlocked(String packageId) async {
    await init();
    return _unlockedPackages.contains(packageId);
  }

  /// Check if a specific Grade package is unlocked
  static Future<bool> isGradeUnlocked(int grade) async {
    await init();
    final String targetPkg = 'pkg_grade_$grade';
    if (_unlockedPackages.contains(targetPkg) ||
        _unlockedPackages.contains('grade_$grade') ||
        _unlockedPackages.contains('all_grades')) {
      return true;
    }
    return false;
  }

  /// Core Business Rule:
  /// Unit 1 is ALWAYS 100% FREE for all subjects and grades.
  /// Unit 2+ requires an active subscription or unlocked package.
  static Future<bool> isUnitAccessible(int grade, int unitNumber) async {
    if (unitNumber <= 1) {
      return true; // Unit 1 is 100% FREE!
    }
    return isGradeUnlocked(grade);
  }

  /// Synchronous quick check for UI builds (uses cached in-memory set)
  static bool isUnitAccessibleSync(int grade, int unitNumber) {
    if (unitNumber <= 1) {
      return true;
    }
    final String targetPkg = 'pkg_grade_$grade';
    return _unlockedPackages.contains(targetPkg) ||
        _unlockedPackages.contains('grade_$grade') ||
        _unlockedPackages.contains('all_grades');
  }

  /// Unlocks a package locally and persists in SharedPreferences
  static Future<void> unlockPackage(String packageId) async {
    await init();
    _unlockedPackages.add(packageId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_unlockedKey, _unlockedPackages.toList());
    _notifyListeners();
  }

  /// Unlocks all content for a specific grade
  static Future<void> unlockGrade(int grade) async {
    await unlockPackage('pkg_grade_$grade');
  }

  /// Syncs user subscriptions from Supabase using user's phone number
  static Future<void> syncWithSupabase(String phoneNumber) async {
    if (phoneNumber.trim().isEmpty) return;
    try {
      final supabase = Supabase.instance.client;
      final cleanPhone = phoneNumber.replaceAll(RegExp(r'\s+'), '');

      final response = await supabase
          .from('user_subscriptions')
          .select('package_id, is_active')
          .eq('phone_number', cleanPhone)
          .eq('is_active', true);

      if (response.isNotEmpty) {
        await init();
        for (final item in response) {
          final pkgId = item['package_id'] as String?;
          if (pkgId != null && pkgId.isNotEmpty) {
            _unlockedPackages.add(pkgId);
          }
        }
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(_unlockedKey, _unlockedPackages.toList());
        _notifyListeners();
      }
    } catch (e) {
      debugPrint("[SubscriptionService] Supabase sync error: $e");
    }
  }
}
