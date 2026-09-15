import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'device_service.dart';

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
    final bool tamperOk = await DeviceService.verifyOfflineTamperIntegrity();
    if (!tamperOk) {
      return false; // Lock content if data was cloned to another unauthorized phone
    }
    return _unlockedPackages.contains(packageId) ||
        _unlockedPackages.contains('all_inclusive') ||
        _unlockedPackages.contains('all_grades');
  }

  /// Check if a specific Grade package or subject is unlocked
  static Future<bool> isGradeUnlocked(int grade, {String? subject}) async {
    await init();
    final bool tamperOk = await DeviceService.verifyOfflineTamperIntegrity();
    if (!tamperOk) {
      return false;
    }

    final String targetPkg = 'pkg_grade_$grade';
    final String targetAllInclusive = 'pkg_all_inclusive_g$grade';

    if (_unlockedPackages.contains(targetPkg) ||
        _unlockedPackages.contains(targetAllInclusive) ||
        _unlockedPackages.contains('grade_$grade') ||
        _unlockedPackages.contains('all_inclusive') ||
        _unlockedPackages.contains('all_grades')) {
      return true;
    }

    if (subject != null && subject.trim().isNotEmpty) {
      final String subjectSlug = subject.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
      final String specificSubjectPkg = 'pkg_g${grade}_$subjectSlug';
      if (_unlockedPackages.contains(specificSubjectPkg)) {
        return true;
      }
    }

    return false;
  }

  /// Core Business Rule:
  /// Unit 1 is ALWAYS 100% FREE for all subjects and grades.
  /// Unit 2+ requires an active single-device bound subscription.
  static Future<bool> isUnitAccessible(int grade, int unitNumber, {String? subject}) async {
    if (unitNumber <= 1) {
      return true; // Unit 1 is 100% FREE!
    }
    return isGradeUnlocked(grade, subject: subject);
  }

  /// Synchronous quick check for UI builds (uses cached in-memory set)
  static Set<String> getUnlockedPackagesSync() {
    return Set.unmodifiable(_unlockedPackages);
  }

  static bool isUnitAccessibleSync(int grade, int unitNumber, {String? subject}) {
    if (unitNumber <= 1) {
      return true;
    }
    final String targetPkg = 'pkg_grade_$grade';
    final String targetAllInclusive = 'pkg_all_inclusive_g$grade';

    if (_unlockedPackages.contains(targetPkg) ||
        _unlockedPackages.contains(targetAllInclusive) ||
        _unlockedPackages.contains('grade_$grade') ||
        _unlockedPackages.contains('all_inclusive') ||
        _unlockedPackages.contains('all_grades')) {
      return true;
    }

    if (subject != null && subject.trim().isNotEmpty) {
      final String subjectSlug = subject.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
      final String specificSubjectPkg = 'pkg_g${grade}_$subjectSlug';
      if (_unlockedPackages.contains(specificSubjectPkg)) {
        return true;
      }
    }

    return false;
  }

  /// Unlocks a package locally and persists in SharedPreferences with device binding fingerprint
  static Future<void> unlockPackage(String packageId) async {
    await init();
    _unlockedPackages.add(packageId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_unlockedKey, _unlockedPackages.toList());

    // Save device binding
    final currentDevId = await DeviceService.getDeviceId();
    await prefs.setString('smartx_verified_device_binding', currentDevId);

    _notifyListeners();
  }

  /// Unlocks all content for a specific grade
  static Future<void> unlockGrade(int grade) async {
    await unlockPackage('pkg_grade_$grade');
  }

  /// Syncs user subscriptions from Supabase with strict Single-Device Binding check
  static Future<DeviceBindingResult> syncWithSupabaseAndVerifyDevice(String phoneNumber, {String? packageId}) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\s+'), '').trim();
    if (cleanPhone.isEmpty) {
      final devId = await DeviceService.getDeviceId();
      return DeviceBindingResult(
        status: DeviceBindingStatus.noSubscription,
        currentDeviceId: devId,
        message: 'No phone number provided.',
      );
    }

    final String targetPkgId = packageId ?? 'all_inclusive';
    final DeviceBindingResult result = await DeviceService.verifyAndBindSubscription(
      phoneNumber: cleanPhone,
      packageId: targetPkgId,
    );

    if (result.isAllowed) {
      try {
        final supabase = Supabase.instance.client;
        final response = await supabase
            .from('user_subscriptions')
            .select('package_id, is_active, device_id')
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
        debugPrint("[SubscriptionService] Supabase sync packages error: $e");
      }
    }

    return result;
  }

  /// Legacy sync method for backwards compatibility
  static Future<void> syncWithSupabase(String phoneNumber) async {
    await syncWithSupabaseAndVerifyDevice(phoneNumber);
  }
}
