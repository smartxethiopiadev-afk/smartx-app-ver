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

  /// Helper to convert any subject title to standard deterministic slug
  static String normalizeSubjectSlug(String subject) {
    final s = subject.trim().toLowerCase();
    if (s.contains('math')) return 'mathematics';
    if (s.contains('phys')) return 'physics';
    if (s.contains('chem')) return 'chemistry';
    if (s.contains('bio')) return 'biology';
    if (s.contains('eng')) return 'english';
    if (s.contains('civ')) return 'civics';
    if (s.contains('geo')) return 'geography';
    if (s.contains('hist')) return 'history';
    if (s.contains('econ')) return 'economics';
    if (s.contains('agri') || s.contains('agr')) return 'agriculture';
    if (s.contains('ict') || s.contains('tech')) return 'ict';
    return s.replaceAll(RegExp(r'[^a-z0-9]'), '_');
  }

  /// Get standard unique subject package ID
  static String getSubjectPackageId(int grade, String subject) {
    final slug = normalizeSubjectSlug(subject);
    return 'pkg_g${grade}_$slug';
  }

  /// Get standard grade package ID
  static String getGradePackageId(int grade) {
    return 'pkg_grade_$grade';
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
        _unlockedPackages.contains('all_grades') ||
        _unlockedPackages.contains('pkg_all_grades') ||
        _unlockedPackages.contains('pkg_all_inclusive');
  }

  /// Check if a specific Grade package or subject is unlocked
  static Future<bool> isGradeUnlocked(int grade, {String? subject}) async {
    await init();

    // 1. Check all-inclusive / all-grades master subscriptions
    if (_unlockedPackages.contains('pkg_all_grades') ||
        _unlockedPackages.contains('all_grades') ||
        _unlockedPackages.contains('all_inclusive') ||
        _unlockedPackages.contains('pkg_all_inclusive') ||
        _unlockedPackages.contains('pkg_all_inclusive_g$grade')) {
      return true;
    }

    // 2. Check full grade package
    final String targetPkg = 'pkg_grade_$grade';
    if (_unlockedPackages.contains(targetPkg) || _unlockedPackages.contains('grade_$grade')) {
      return true;
    }

    // 3. Check individual subject package
    if (subject != null && subject.trim().isNotEmpty) {
      final String slug = normalizeSubjectSlug(subject);
      final String specificSubjectPkg = 'pkg_g${grade}_$slug';
      if (_unlockedPackages.contains(specificSubjectPkg) || _unlockedPackages.contains(slug)) {
        return true;
      }
    }

    return false;
  }

  /// Core Business Rule:
  /// Unit 1 is ALWAYS 100% FREE for all subjects and grades (Trial mode).
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
      return true; // Unit 1 is 100% FREE
    }

    // Check all-inclusive master subscriptions
    if (_unlockedPackages.contains('pkg_all_grades') ||
        _unlockedPackages.contains('all_grades') ||
        _unlockedPackages.contains('all_inclusive') ||
        _unlockedPackages.contains('pkg_all_inclusive') ||
        _unlockedPackages.contains('pkg_all_inclusive_g$grade')) {
      return true;
    }

    // Check full grade package
    final String targetPkg = 'pkg_grade_$grade';
    if (_unlockedPackages.contains(targetPkg) || _unlockedPackages.contains('grade_$grade')) {
      return true;
    }

    // Check individual subject package
    if (subject != null && subject.trim().isNotEmpty) {
      final String slug = normalizeSubjectSlug(subject);
      final String specificSubjectPkg = 'pkg_g${grade}_$slug';
      if (_unlockedPackages.contains(specificSubjectPkg) || _unlockedPackages.contains(slug)) {
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
  /// Strictly checks database state without granting unauthorized unlocks.
  static Future<bool> syncWithSupabase(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\s+'), '').trim();
    if (cleanPhone.isEmpty) return false;

    try {
      final supabase = Supabase.instance.client;
      final currentDeviceId = await DeviceService.getDeviceId();

      final response = await supabase
          .from('students')
          .select('device_id, unlocked_packages, subscription_status, subscription_expires_at, is_active')
          .eq('phone_number', cleanPhone)
          .maybeSingle();

      if (response == null) return false;

      // 1. Account status check
      final bool isActive = response['is_active'] as bool? ?? true;
      if (!isActive) return false;

      // 2. Expiration check
      if (response['subscription_expires_at'] != null) {
        final expiresAt = DateTime.tryParse(response['subscription_expires_at'].toString());
        if (expiresAt != null && DateTime.now().toUtc().isAfter(expiresAt.toUtc())) {
          debugPrint('[SubscriptionService] Subscription expired for $cleanPhone');
          return false;
        }
      }

      // 3. Single device hardware binding enforcement
      final String? boundDev = (response['device_id'] as String?)?.trim();
      if (boundDev == null || boundDev.isEmpty) {
        // Auto-bind on first sync
        try {
          await supabase.from('students').update({
            'device_id': currentDeviceId,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          }).eq('phone_number', cleanPhone);
        } catch (e) {
          debugPrint('[SubscriptionService] Auto-bind error: $e');
        }
      } else if (boundDev != currentDeviceId) {
        // Device mismatch locked! Strict anti-account sharing
        debugPrint('[SubscriptionService] Device mismatch: registered $boundDev vs current $currentDeviceId');
        return false;
      }

      // 4. Extract strictly genuine unlocked packages
      final List<dynamic>? rawPkgs = response['unlocked_packages'] as List<dynamic>?;
      final List<String> pkgs = rawPkgs != null ? rawPkgs.map((e) => e.toString()).toList() : [];

      await setUnlockedPackages(pkgs);
      return true;
    } catch (e) {
      debugPrint("[SubscriptionService] Supabase sync packages error: $e");
      return false;
    }
  }

  /// Checks subscription access with live sync verification
  static Future<bool> checkSubscriptionAccess({
    required int grade,
    required String subject,
    required int unitNumber,
  }) async {
    if (unitNumber <= 1) {
      return true; // Unit 1 is always 100% free trial!
    }

    await init();

    if (isUnitAccessibleSync(grade, unitNumber, subject: subject)) {
      return true;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final phone = prefs.getString('user_phoneNumber') ?? prefs.getString('phone_number') ?? '';
      if (phone.isEmpty) return false;

      final synced = await syncWithSupabase(phone);
      if (synced) {
        return isUnitAccessibleSync(grade, unitNumber, subject: subject);
      }
    } catch (e) {
      debugPrint('[SubscriptionService] checkSubscriptionAccess error: $e');
    }

    return false;
  }

  /// Verifies if phone has legitimate access to packageId and enforces hardware device binding.
  /// Strictly rejects non-paying or mismatched devices.
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
          .select('device_id, unlocked_packages, subscription_status, subscription_expires_at, is_active')
          .eq('phone_number', cleanPhone)
          .maybeSingle();

      if (res == null) {
        return const DeviceBindingResult(
          isAllowed: false,
          message: 'ምንም ንቁ መለያ አልተገኘም። እባክዎ አስቀድመው ይመዝገቡ ወይም በቴሌግራም አስተዳዳሪውን ያነጋግሩ (@smart_x_help)',
        );
      }

      // Check isActive
      final bool isActive = res['is_active'] as bool? ?? true;
      if (!isActive) {
        return const DeviceBindingResult(
          isAllowed: false,
          message: 'ይህ መለያ በአሁኑ ጊዜ አገልግሎቱ ተቋርጧል። / Account is inactive.',
        );
      }

      // Check Expiration
      if (res['subscription_expires_at'] != null) {
        final expiresAt = DateTime.tryParse(res['subscription_expires_at'].toString());
        if (expiresAt != null && DateTime.now().toUtc().isAfter(expiresAt.toUtc())) {
          return const DeviceBindingResult(
            isAllowed: false,
            message: 'የምዝገባ ጊዜዎ አልቋል። እባክዎ ያድሱ። / Subscription has expired.',
          );
        }
      }

      // Device Binding Check
      final String? registeredDeviceId = (res['device_id'] as String?)?.trim();
      if (registeredDeviceId != null &&
          registeredDeviceId.isNotEmpty &&
          registeredDeviceId != currentDeviceId) {
        return const DeviceBindingResult(
          isAllowed: false,
          message: 'ይህ ስልክ ቁጥር በሌላ መሳሪያ ላይ የተመዘገበ ነው። የደህንነት ስርዓቱ 1 መለያ ለአንድ ስልክ ብቻ ይፈቅዳል።',
        );
      }

      // First time binding
      if (registeredDeviceId == null || registeredDeviceId.isEmpty) {
        try {
          await supabase.from('students').update({
            'device_id': currentDeviceId,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          }).eq('phone_number', cleanPhone);
        } catch (e) {
          debugPrint('[SubscriptionService] Auto-bind error: $e');
        }
      }

      final List<dynamic>? rawPkgs = res['unlocked_packages'] as List<dynamic>?;
      final List<String> pkgs = rawPkgs != null
          ? rawPkgs.map((e) => e.toString()).toList()
          : [];

      // Check if requested packageId is legitimately unlocked
      if (packageId != null) {
        final bool hasAccess = pkgs.contains(packageId) ||
            pkgs.contains('all_grades') ||
            pkgs.contains('pkg_all_grades') ||
            pkgs.contains('all_inclusive') ||
            pkgs.contains('pkg_all_inclusive');

        if (!hasAccess) {
          return const DeviceBindingResult(
            isAllowed: false,
            message: 'ይህ ፓኬጅ አልተከፈለም። እባክዎ በቴሌግራም አድሚኑን ያነጋግሩ (@smart_x_help)።',
          );
        }
      }

      await setUnlockedPackages(pkgs);
      return const DeviceBindingResult(
        isAllowed: true,
        message: 'ፓኬጁ በተሳካ ሁኔታ ተረጋግጧል!',
      );
    } catch (e) {
      debugPrint('[SubscriptionService] syncWithSupabaseAndVerifyDevice error: $e');
      return DeviceBindingResult(
        isAllowed: false,
        message: 'የኔትወርክ ችግር አጋጥሟል። እባክዎ እንደገና ይሞክሩ: $e',
      );
    }
  }

  // --- Rate limiting shield against brute force ---
  static int _failedAttemptsCount = 0;
  static DateTime? _lastFailedAttemptTime;

  /// Sanitizes Ethiopian phone number to uniform 10-digit format (09... or 07...)
  static String sanitizeEthiopianPhone(String raw) {
    String clean = raw.replaceAll(RegExp(r'[^0-9+]'), '').trim();
    if (clean.startsWith('+251')) {
      clean = '0${clean.substring(4)}';
    } else if (clean.startsWith('251')) {
      clean = '0${clean.substring(3)}';
    }
    return clean;
  }

  /// Verifies student upgrade request by Phone Number and Name after Telegram payment.
  /// Enforces Single-Device hardware binding, rate limiting, and tamper protection.
  static Future<StudentUpgradeResult> verifyAndUpgradeStudent({
    required String phone,
    required String name,
  }) async {
    // 1. Rate Limiting Protection (Anti-Brute Force)
    final now = DateTime.now();
    if (_lastFailedAttemptTime != null &&
        now.difference(_lastFailedAttemptTime!).inMinutes < 3 &&
        _failedAttemptsCount >= 5) {
      final remainingSecs = 60 - now.difference(_lastFailedAttemptTime!).inSeconds;
      return StudentUpgradeResult(
        isSuccess: false,
        message: 'ተደጋጋሚ ሙከራ ተስተውሏል። ለደህንነት ሲባል እባክዎ ከ $remainingSecs ሰከንዶች በኋላ እንደገና ይሞክሩ።',
      );
    }

    // 2. Input Sanitization & Validation
    final cleanPhone = sanitizeEthiopianPhone(phone);
    final cleanName = name.trim();

    if (cleanName.length < 2) {
      return const StudentUpgradeResult(
        isSuccess: false,
        message: 'እባክዎ ትክክለኛ ሙሉ ስምዎን ያስገቡ (ቢያንስ 2 ፊደላት)።',
      );
    }

    final phoneRegex = RegExp(r'^0[79]\d{8}$');
    if (!phoneRegex.hasMatch(cleanPhone)) {
      return const StudentUpgradeResult(
        isSuccess: false,
        message: 'እባክዎ ትክክለኛ የኢትዮጵያ ስልክ ቁጥር ያስገቡ (ለምሳሌ 0911234567 ወይም 0711234567)።',
      );
    }

    try {
      final supabase = Supabase.instance.client;
      final currentDeviceId = await DeviceService.getDeviceId();
      final String nowIso = DateTime.now().toUtc().toIso8601String();

      // 3. Primary: Try Atomic RPC Function `verify_and_upgrade_student`
      try {
        final rpcResult = await supabase.rpc('verify_and_upgrade_student', params: {
          'p_phone': cleanPhone,
          'p_name': cleanName,
          'p_device_id': currentDeviceId,
        });

        if (rpcResult is Map) {
          final bool success = rpcResult['success'] == true;
          final String? status = rpcResult['status'] as String?;
          final String msg = rpcResult['message']?.toString() ?? '';

          if (success) {
            _failedAttemptsCount = 0; // Reset rate limit counter on success
            final rawPkgs = rpcResult['unlocked_packages'] as List<dynamic>?;
            final pkgs = rawPkgs != null ? rawPkgs.map((e) => e.toString()).toList() : <String>[];
            final int studentGrade = (rpcResult['grade'] as num?)?.toInt() ?? 12;

            // Apply unlocks locally
            await setUnlockedPackages(pkgs);

            // Persist verified student profile
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('user_fullName', cleanName);
            await prefs.setString('user_name', cleanName);
            await prefs.setString('user_phoneNumber', cleanPhone);
            await prefs.setString('phone_number', cleanPhone);
            await prefs.setInt('user_grade', studentGrade);
            await prefs.setBool('is_authenticated', true);
            await prefs.setString('device_id', currentDeviceId);

            return StudentUpgradeResult(
              isSuccess: true,
              message: msg.isNotEmpty ? msg : 'እንኳን ደስ አለዎት! ፓኬጅዎ በዚህ ስልክ ላይ በተሳካ ሁኔታ ተረጋግጦ ተከፍቷል!',
              studentName: cleanName,
              phoneNumber: cleanPhone,
              grade: studentGrade,
              unlockedPackages: pkgs,
            );
          } else if (status == 'device_mismatch') {
            _failedAttemptsCount++;
            _lastFailedAttemptTime = DateTime.now();
            return StudentUpgradeResult(
              isSuccess: false,
              isDeviceMismatch: true,
              message: msg.isNotEmpty
                  ? msg
                  : 'ይህ ስልክ ቁጥር ቀደም ሲል በሌላ ሞባይል ስልክ ላይ ተመዝግቧል! የደህንነት ስርዓቱ አንድን አካውንት ለአንድ ስልክ ብቻ ይፈቅዳል (Single-Device Protection)።',
            );
          } else {
            _failedAttemptsCount++;
            _lastFailedAttemptTime = DateTime.now();
            return StudentUpgradeResult(
              isSuccess: false,
              message: msg.isNotEmpty ? msg : 'ማረጋገጥ አልተቻለም። እባክዎ መረጃዎን ይፈትሹ።',
            );
          }
        }
      } catch (rpcErr) {
        debugPrint('[SubscriptionService] verify_and_upgrade_student RPC notice: $rpcErr');
      }

      // 4. Fallback Direct Supabase Query Flow
      final res = await supabase
          .from('students')
          .select('full_name, phone_number, grade, device_id, unlocked_packages, subscription_status, subscription_expires_at, is_active')
          .eq('phone_number', cleanPhone)
          .maybeSingle();

      if (res == null) {
        _failedAttemptsCount++;
        _lastFailedAttemptTime = DateTime.now();
        return const StudentUpgradeResult(
          isSuccess: false,
          message: 'በዚህ ስልክ ቁጥር የተመዘገበ ተማሪ አልተገኘም። እባክዎ አስቀድመው በቴሌግራም (@smart_x_help) ክፍያ ፈጽመው ደረሰኝዎን ይላኩ።',
        );
      }

      // Check Active Status
      final bool isActive = res['is_active'] as bool? ?? true;
      if (!isActive) {
        return const StudentUpgradeResult(
          isSuccess: false,
          message: 'ይህ መለያ በአስተዳዳሪው ታግዷል። እባክዎ ድጋፍ ያነጋግሩ (@smart_x_help)።',
        );
      }

      // Check Expiration
      if (res['subscription_expires_at'] != null) {
        final expiresAt = DateTime.tryParse(res['subscription_expires_at'].toString());
        if (expiresAt != null && DateTime.now().toUtc().isAfter(expiresAt.toUtc())) {
          return const StudentUpgradeResult(
            isSuccess: false,
            message: 'የደንበኝነት ምዝገባዎ ጊዜ አልቋል። እባክዎ በቴሌግራም ያድሱ (@smart_x_help)።',
          );
        }
      }

      // Strict Anti-Sharing Hardware Device Binding Check
      final String? boundDev = (res['device_id'] as String?)?.trim();
      if (boundDev != null && boundDev.isNotEmpty && boundDev != currentDeviceId) {
        _failedAttemptsCount++;
        _lastFailedAttemptTime = DateTime.now();
        return const StudentUpgradeResult(
          isSuccess: false,
          isDeviceMismatch: true,
          message: 'ይህ ስልክ ቁጥር ቀደም ሲል በሌላ ሞባይል ስልክ ላይ ተመዝግቧል! የደህንነት ስርዓቱ አንድን አካውንት ለአንድ ስልክ ብቻ ይፈቅዳል (Single-Device Protection)። መለያ ማጋራት በጥብቅ የተከለከለ ነው።',
        );
      }

      // First time binding or name update
      if (boundDev == null || boundDev.isEmpty) {
        try {
          await supabase.from('students').update({
            'device_id': currentDeviceId,
            'full_name': cleanName,
            'updated_at': nowIso,
          }).eq('phone_number', cleanPhone);
        } catch (bindErr) {
          debugPrint('[SubscriptionService] Auto-bind error: $bindErr');
        }
      } else {
        try {
          await supabase.from('students').update({
            'full_name': cleanName,
            'updated_at': nowIso,
          }).eq('phone_number', cleanPhone);
        } catch (_) {}
      }

      // Extract Legitimate Unlocked Packages
      final List<dynamic>? rawPkgs = res['unlocked_packages'] as List<dynamic>?;
      final List<String> pkgs = rawPkgs != null
          ? rawPkgs.map((e) => e.toString()).toList()
          : <String>[];

      if (pkgs.isEmpty) {
        return const StudentUpgradeResult(
          isSuccess: false,
          message: 'ስልክ ቁጥርዎ ተገኝቷል፤ ነገር ግን እስካሁን የተፈቀደ ንቁ የትምህርት ፓኬጅ የለም። ክፍያ ፈጽመው ከሆነ እባክዎ ደረሰኝዎን በቴሌግራም (@smart_x_help) ለአድሚኑ ይላኩ።',
        );
      }

      _failedAttemptsCount = 0; // Success, reset rate limiter
      final int studentGrade = (res['grade'] as num?)?.toInt() ?? 12;

      // Apply unlocks locally
      await setUnlockedPackages(pkgs);

      // Persist student profile locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_fullName', cleanName);
      await prefs.setString('user_name', cleanName);
      await prefs.setString('user_phoneNumber', cleanPhone);
      await prefs.setString('phone_number', cleanPhone);
      await prefs.setInt('user_grade', studentGrade);
      await prefs.setBool('is_authenticated', true);
      await prefs.setString('device_id', currentDeviceId);

      return StudentUpgradeResult(
        isSuccess: true,
        message: 'እንኳን ደስ አለዎት! $cleanName፣ የትምህርት ፈቃድዎ በዚህ ስልክ ላይ በተሳካ ሁኔታ ተረጋግጦ ተከፍቷል!',
        studentName: cleanName,
        phoneNumber: cleanPhone,
        grade: studentGrade,
        unlockedPackages: pkgs,
      );
    } catch (e) {
      debugPrint('[SubscriptionService] verifyAndUpgradeStudent error: $e');
      return StudentUpgradeResult(
        isSuccess: false,
        message: 'የኔትወርክ ችግር አጋጥሟል። እባክዎ የበይነመረብ ግንኙነትዎን ያረጋግጡ: $e',
      );
    }
  }
}

class StudentUpgradeResult {
  final bool isSuccess;
  final String message;
  final String? studentName;
  final String? phoneNumber;
  final int? grade;
  final List<String> unlockedPackages;
  final bool isDeviceMismatch;

  const StudentUpgradeResult({
    required this.isSuccess,
    required this.message,
    this.studentName,
    this.phoneNumber,
    this.grade,
    this.unlockedPackages = const [],
    this.isDeviceMismatch = false,
  });
}
