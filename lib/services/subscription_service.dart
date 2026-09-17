import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'device_service.dart';

class DeviceBindingResult {
  final bool isAllowed;
  final String? message;
  const DeviceBindingResult({required this.isAllowed, this.message});
}

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

  /// Initialize local subscription state from SharedPreferences
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

  static Future<void> setUnlockedPackages(List<String> packages) async {
    await init();
    _unlockedPackages = packages.toSet();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_unlockedKey, _unlockedPackages.toList());
    _notifyListeners();
  }

  /// Check if a specific package is unlocked
  static Future<bool> isPackageUnlocked(String packageId) async {
    await init();
    return _unlockedPackages.contains(packageId) ||
        _unlockedPackages.contains('all_inclusive') ||
        _unlockedPackages.contains('all_grades');
  }

  /// Check if a specific Grade package or subject is unlocked
  static Future<bool> isGradeUnlocked(int grade, {String? subject}) async {
    await init();

    final String targetPkg = 'pkg_grade_$grade';

    if (_unlockedPackages.contains(targetPkg) ||
        _unlockedPackages.contains('all_inclusive') ||
        _unlockedPackages.contains('all_grades') ||
        _unlockedPackages.contains('grade_$grade')) {
      return true;
    }

    if (subject != null && subject.trim().isNotEmpty) {
      final String subjectSlug = subject.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
      final String specificSubjectPkg = 'pkg_g${grade}_$subjectSlug';
      if (_unlockedPackages.contains(specificSubjectPkg) || _unlockedPackages.contains(subjectSlug)) {
        return true;
      }
    }

    return false;
  }

  /// Core Business Rule:
  /// Unit 1 is ALWAYS 100% FREE for all subjects and grades.
  /// Unit 2+ requires an active package unlock or student subscription.
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

    if (_unlockedPackages.contains(targetPkg) ||
        _unlockedPackages.contains('all_inclusive') ||
        _unlockedPackages.contains('all_grades') ||
        _unlockedPackages.contains('grade_$grade')) {
      return true;
    }

    if (subject != null && subject.trim().isNotEmpty) {
      final String subjectSlug = subject.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
      final String specificSubjectPkg = 'pkg_g${grade}_$subjectSlug';
      if (_unlockedPackages.contains(specificSubjectPkg) || _unlockedPackages.contains(subjectSlug)) {
        return true;
      }
    }

    return false;
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

  /// Syncs subscriptions against `students.unlocked_packages` and enforces `students.device_id == currentDeviceId`.
  static Future<bool> syncWithSupabase(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\s+'), '').trim();
    if (cleanPhone.isEmpty) return false;

    try {
      final supabase = Supabase.instance.client;
      final currentDeviceId = await DeviceService.getDeviceId();

      final response = await supabase
          .from('students')
          .select('device_id, unlocked_packages, is_active, grade')
          .eq('phone_number', cleanPhone)
          .maybeSingle();

      if (response == null) return false;

      final bool isActive = response['is_active'] as bool? ?? true;
      if (!isActive) return false;

      final String? boundDev = response['device_id'] as String?;
      if (boundDev == null || boundDev.isEmpty) {
        // Auto-bind device
        try {
          await supabase.from('students').update({
            'device_id': currentDeviceId,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          }).eq('phone_number', cleanPhone);
        } catch (_) {}
      } else if (boundDev != currentDeviceId) {
        // Device mismatch locked!
        return false;
      }

      final List<dynamic>? rawPkgs = response['unlocked_packages'] as List<dynamic>?;
      final List<String> pkgs = rawPkgs != null ? rawPkgs.map((e) => e.toString()).toList() : [];
      final int? grade = (response['grade'] as num?)?.toInt();
      if (grade != null) {
        pkgs.add('pkg_grade_$grade');
        pkgs.add('grade_$grade');
      }

      await setUnlockedPackages(pkgs);
      return true;
    } catch (e) {
      debugPrint("[SubscriptionService] Supabase sync packages error: $e");
      return false;
    }
  }

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

      return await syncWithSupabase(phone);
    } catch (e) {
      debugPrint('[SubscriptionService] checkSubscriptionAccess notice: $e');
    }

    return false;
  }

  static Future<DeviceBindingResult> syncWithSupabaseAndVerifyDevice(
    String phoneNumber, {
    String? packageId,
  }) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\s+'), '').trim();
    if (cleanPhone.isEmpty) {
      return const DeviceBindingResult(
        isAllowed: false,
        message: 'ስልክ ቁጥር ባዶ መሆን አይችልም። / Phone number cannot be empty.',
      );
    }

    try {
      final supabase = Supabase.instance.client;
      final currentDeviceId = await DeviceService.getDeviceId();

      final res = await supabase
          .from('students')
          .select()
          .eq('phone_number', cleanPhone)
          .maybeSingle();

      if (res != null) {
        final String? registeredDeviceId = res['device_id'] as String?;
        if (registeredDeviceId != null &&
            registeredDeviceId.isNotEmpty &&
            registeredDeviceId != currentDeviceId) {
          return const DeviceBindingResult(
            isAllowed: false,
            message: 'ይህ ስልክ ቁጥር በሌላ መሳሪያ ላይ የተመዘገበ ነው። / Device mismatch.',
          );
        }

        final List<dynamic>? rawPkgs = res['unlocked_packages'] as List<dynamic>?;
        final List<String> pkgs = rawPkgs != null
            ? rawPkgs.map((e) => e.toString()).toList()
            : [];

        if (packageId != null && !pkgs.contains(packageId)) {
          pkgs.add(packageId);
          await supabase.from('students').update({
            'unlocked_packages': pkgs,
            'device_id': currentDeviceId,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          }).eq('phone_number', cleanPhone);
        }

        await setUnlockedPackages(pkgs);
        return const DeviceBindingResult(isAllowed: true);
      } else {
        final List<String> pkgs = packageId != null ? [packageId] : ['all_grades'];
        await supabase.from('students').insert({
          'full_name': 'Student',
          'phone_number': cleanPhone,
          'grade': 12,
          'device_id': currentDeviceId,
          'is_active': true,
          'unlocked_packages': pkgs,
        });
        await setUnlockedPackages(pkgs);
        return const DeviceBindingResult(isAllowed: true);
      }
    } catch (e) {
      debugPrint('[SubscriptionService] syncWithSupabaseAndVerifyDevice error: $e');
      if (packageId != null) {
        await unlockPackage(packageId);
      }
      return const DeviceBindingResult(isAllowed: true);
    }
  }
}
