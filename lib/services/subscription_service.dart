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
            .select()
            .eq('phone_number', cleanPhone)
            .eq('is_active', true);

        if (response.isNotEmpty) {
          await init();
          final currentDevId = await DeviceService.getDeviceId();
          for (final item in response) {
            final devId = item['device_id'] as String?;
            if (devId != null && devId.isNotEmpty && devId != currentDevId) {
              continue; // Bound to another device
            }
            final pkgId = item['package_id'] as String?;
            final pkgType = item['package_type'] as String?;
            final subName = item['subject_name'] as String? ?? item['subject'] as String?;
            final gradeNum = (item['grade'] as num?)?.toInt();

            if (pkgId != null && pkgId.isNotEmpty) {
              _unlockedPackages.add(pkgId);
            }
            if (pkgType != null && pkgType.isNotEmpty) {
              _unlockedPackages.add(pkgType);
            }
            if (gradeNum != null) {
              _unlockedPackages.add('pkg_grade_$gradeNum');
              _unlockedPackages.add('grade_$gradeNum');
            }
            if (subName != null && subName.isNotEmpty) {
              final slug = subName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
              if (gradeNum != null) {
                _unlockedPackages.add('pkg_g${gradeNum}_$slug');
              }
              _unlockedPackages.add(slug);
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

  /// Granular verification for Unit 2+ access.
  /// Rule 1: Unit 1 is 100% FREE.
  /// Rule 2: Unit 2+ queries `user_subscriptions` in Supabase:
  ///   - phone_number == user_phoneNumber
  ///   - device_id == currentDeviceId
  ///   - is_active == true
  ///   - subject_name == currentSubject OR package_type == 'all_inclusive' OR grade == currentGrade
  static Future<bool> checkSubscriptionAccess({
    required int grade,
    required String subject,
    required int unitNumber,
  }) async {
    if (unitNumber <= 1) {
      return true; // Unit 1 is always 100% free!
    }

    await init();

    if (isUnitAccessibleSync(grade, unitNumber, subject: subject)) {
      return true;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final phone = prefs.getString('user_phoneNumber') ?? prefs.getString('phone_number') ?? '';
      if (phone.isEmpty) return false;

      final cleanPhone = phone.replaceAll(RegExp(r'\s+'), '').trim();
      final currentDeviceId = await DeviceService.getDeviceId();
      final supabase = Supabase.instance.client;

      final List<dynamic> records = await supabase
          .from('user_subscriptions')
          .select()
          .eq('phone_number', cleanPhone)
          .eq('is_active', true);

      final cleanSubject = subject.trim().toLowerCase();

      for (final rec in records) {
        final recDevId = rec['device_id'] as String?;
        if (recDevId == null || recDevId.trim().isEmpty) {
          // Auto bind device
          try {
            await supabase
                .from('user_subscriptions')
                .update({'device_id': currentDeviceId})
                .eq('id', rec['id']);
          } catch (_) {}
        } else if (recDevId.trim() != currentDeviceId.trim()) {
          // Bound to a different device
          continue;
        }

        final pkgType = (rec['package_type'] as String? ?? rec['package_id'] as String? ?? '').toLowerCase();
        final recSub = (rec['subject_name'] as String? ?? rec['subject'] as String? ?? '').toLowerCase();
        final recGrade = (rec['grade'] as num?)?.toInt();

        final bool isAllInclusive = pkgType.contains('all_inclusive') || pkgType.contains('all_grades');
        final bool isGradeMatch = recGrade == grade || pkgType.contains('grade_$grade');
        final bool isSubjectMatch = recSub.isNotEmpty &&
            (recSub == cleanSubject || cleanSubject.contains(recSub) || recSub.contains(cleanSubject));

        if (isAllInclusive || isGradeMatch || isSubjectMatch) {
          await unlockGrade(grade);
          final slug = cleanSubject.replaceAll(RegExp(r'[^a-z0-9]'), '_');
          await unlockPackage('pkg_g${grade}_$slug');
          return true;
        }
      }
    } catch (e) {
      debugPrint('[SubscriptionService] checkSubscriptionAccess notice: $e');
    }

    return false;
  }

  /// Legacy sync method for backwards compatibility
  static Future<void> syncWithSupabase(String phoneNumber) async {
    await syncWithSupabaseAndVerifyDevice(phoneNumber);
  }
}
