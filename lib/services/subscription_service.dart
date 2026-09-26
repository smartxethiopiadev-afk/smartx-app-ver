import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'device_service.dart';

class SubscriptionService {
  static const String _unlockedKey = 'smartx_unlocked_packages';
  static const String _expiresAtKey = 'smartx_subscription_expires_at';
  static const String _statusKey = 'smartx_subscription_status';
  static Set<String> _unlockedPackages = {};
  static bool _isLoaded = false;
  static DateTime? _cachedExpiresAt;
  static final List<VoidCallback> _listeners = [];

  // Security & Brute-force rate limiting
  static int _failedAttemptsCount = 0;
  static DateTime? _lastFailedAttemptTime;

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

      // Check if current cached subscription has expired
      final String? expStr = prefs.getString(_expiresAtKey);
      if (expStr != null && expStr.isNotEmpty) {
        final expiresAt = DateTime.tryParse(expStr);
        _cachedExpiresAt = expiresAt;
        if (expiresAt != null && DateTime.now().toUtc().isAfter(expiresAt.toUtc())) {
          _unlockedPackages.clear();
          await prefs.setStringList(_unlockedKey, []);
          await prefs.setString(_statusKey, 'expired');
        }
      }

      _isLoaded = true;
    } catch (e) {
      debugPrint("[SubscriptionService] Init error: $e");
    }
  }

  /// Synchronously checks if cached subscription has expired
  static bool isSubscriptionExpiredSync() {
    if (_cachedExpiresAt != null) {
      if (DateTime.now().toUtc().isAfter(_cachedExpiresAt!.toUtc())) {
        return true;
      }
    }
    return false;
  }

  /// Checks if the current subscription or package access has expired
  static Future<bool> isSubscriptionExpired() async {
    await init();
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? expStr = prefs.getString(_expiresAtKey);
      if (expStr != null && expStr.isNotEmpty) {
        final expiresAt = DateTime.tryParse(expStr);
        _cachedExpiresAt = expiresAt;
        if (expiresAt != null && DateTime.now().toUtc().isAfter(expiresAt.toUtc())) {
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  /// Returns the expiration date or null if lifetime
  static Future<DateTime?> getSubscriptionExpiresAt() async {
    await init();
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? expStr = prefs.getString(_expiresAtKey);
      if (expStr != null && expStr.isNotEmpty) {
        return DateTime.tryParse(expStr);
      }
    } catch (_) {}
    return null;
  }

  /// Returns remaining minutes until subscription expires, or -1 if expired, null if unlimited
  static Future<int?> getRemainingMinutes() async {
    final exp = await getSubscriptionExpiresAt();
    if (exp == null) return null;
    final diff = exp.difference(DateTime.now().toUtc()).inMinutes;
    return diff > 0 ? diff : 0;
  }

  static Future<void> setUnlockedPackages(List<String> packages) async {
    await init();
    _unlockedPackages = packages.toSet();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_unlockedKey, _unlockedPackages.toList());
    _notifyListeners();
  }

  /// Unlocks a specific package
  static Future<void> unlockPackage(String packageId) async {
    await init();
    if (!_unlockedPackages.contains(packageId)) {
      _unlockedPackages.add(packageId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_unlockedKey, _unlockedPackages.toList());
      _notifyListeners();
    }
  }

  /// Silently validate device binding and sync active subscriptions in background directly with `students` table
  static Future<void> validateAndSyncWithDatabase() async {
    try {
      await init();
      final devId = await DeviceService.getDeviceId();
      if (devId.isEmpty) return;

      final prefs = await SharedPreferences.getInstance();
      final phone = prefs.getString('user_phoneNumber') ?? prefs.getString('phone_number');

      if (phone != null && phone.isNotEmpty) {
        final cleanPhone = sanitizeEthiopianPhone(phone);
        final client = Supabase.instance.client;
        final resp = await client
            .from('students')
            .select('unlocked_packages, subscription_status, subscription_expires_at, is_active, device_id')
            .eq('phone_number', cleanPhone)
            .maybeSingle();

        if (resp != null) {
          final bool isActive = resp['is_active'] as bool? ?? true;
          final String? regDev = (resp['device_id'] as String?)?.trim();

          // Expiration check
          if (resp['subscription_expires_at'] != null) {
            final expStr = resp['subscription_expires_at'].toString();
            await prefs.setString(_expiresAtKey, expStr);
            final expiresAt = DateTime.tryParse(expStr);
            if (expiresAt != null && DateTime.now().toUtc().isAfter(expiresAt.toUtc())) {
              // Expired!
              _unlockedPackages.clear();
              await prefs.setStringList(_unlockedKey, []);
              await prefs.setString(_statusKey, 'expired');
              _notifyListeners();
              return;
            }
          }

          if (isActive && (regDev == null || regDev.isEmpty || regDev == devId)) {
            final List<dynamic>? rawPkgs = resp['unlocked_packages'] as List<dynamic>?;
            if (rawPkgs != null) {
              final pkgs = rawPkgs.map((e) => e.toString()).toList();
              await setUnlockedPackages(pkgs);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[SubscriptionService] Silent background sync notice: $e');
    }
  }

  /// Check if a specific package is unlocked
  static Future<bool> isPackageUnlocked(String packageId) async {
    await init();
    if (await isSubscriptionExpired()) return false;
    return _unlockedPackages.contains(packageId) ||
        _unlockedPackages.contains('all_inclusive') ||
        _unlockedPackages.contains('all_grades') ||
        _unlockedPackages.contains('pkg_all_grades') ||
        _unlockedPackages.contains('pkg_all_inclusive');
  }

  /// Check if a specific Grade package or subject is unlocked
  static Future<bool> isGradeUnlocked(int grade, {String? subject}) async {
    await init();
    if (await isSubscriptionExpired()) return false;

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
  /// Unit 2+ requires an active package unlock or student subscription that is not expired.
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

  /// Synchronous check if a grade is unlocked
  static bool isGradeUnlockedSync(int grade, {String? subject}) {
    if (isSubscriptionExpiredSync()) {
      return false;
    }

    if (_unlockedPackages.contains('pkg_all_grades') ||
        _unlockedPackages.contains('all_grades') ||
        _unlockedPackages.contains('all_inclusive') ||
        _unlockedPackages.contains('pkg_all_inclusive') ||
        _unlockedPackages.contains('pkg_all_inclusive_g$grade')) {
      return true;
    }

    final String targetPkg = 'pkg_grade_$grade';
    if (_unlockedPackages.contains(targetPkg) || _unlockedPackages.contains('grade_$grade')) {
      return true;
    }

    if (subject != null && subject.trim().isNotEmpty) {
      final String slug = normalizeSubjectSlug(subject);
      final String specificSubjectPkg = 'pkg_g${grade}_$slug';
      if (_unlockedPackages.contains(specificSubjectPkg) || _unlockedPackages.contains(slug)) {
        return true;
      }
    }

    return false;
  }

  /// Synchronous check if a specific unit is accessible
  static bool isUnitAccessibleSync(int grade, int unitNumber, {String? subject}) {
    if (unitNumber <= 1) {
      return true;
    }
    return isGradeUnlockedSync(grade, subject: subject);
  }

  /// Syncs subscriptions against `students` table and enforces `students.device_id == currentDeviceId` and expiry.
  static Future<bool> syncWithSupabase(String phoneNumber) async {
    final cleanPhone = sanitizeEthiopianPhone(phoneNumber);
    if (cleanPhone.isEmpty) return false;
    final altPhone = cleanPhone.startsWith('0') ? '+251${cleanPhone.substring(1)}' : cleanPhone;

    try {
      final supabase = Supabase.instance.client;
      final currentDeviceId = await DeviceService.getDeviceId();
      final prefs = await SharedPreferences.getInstance();

      final response = await supabase
          .from('students')
          .select('device_id, unlocked_packages, subscription_status, subscription_expires_at, is_active')
          .or('phone_number.eq.$cleanPhone,phone_number.eq.$altPhone')
          .maybeSingle();

      if (response == null) return false;

      // 1. Account status check
      final bool isActive = response['is_active'] as bool? ?? true;
      if (!isActive) return false;

      // 2. Expiration check (minutes / timestamp from DB)
      if (response['subscription_expires_at'] != null) {
        final expStr = response['subscription_expires_at'].toString();
        await prefs.setString(_expiresAtKey, expStr);
        final expiresAt = DateTime.tryParse(expStr);
        _cachedExpiresAt = expiresAt;
        if (expiresAt != null && DateTime.now().toUtc().isAfter(expiresAt.toUtc())) {
          debugPrint('[SubscriptionService] Subscription expired for $cleanPhone at $expStr');
          _unlockedPackages.clear();
          await prefs.setStringList(_unlockedKey, []);
          await prefs.setString(_statusKey, 'expired');
          _notifyListeners();
          return false;
        }
      } else {
        await prefs.remove(_expiresAtKey);
        _cachedExpiresAt = null;
      }

      // 3. Single device hardware binding enforcement
      final String? boundDev = (response['device_id'] as String?)?.trim();
      if (boundDev == null || boundDev.isEmpty) {
        // Strict Check: Check for device conflicts
        final deviceConflict = await supabase
            .from('students')
            .select('phone_number')
            .eq('device_id', currentDeviceId)
            .neq('phone_number', cleanPhone)
            .neq('phone_number', altPhone)
            .maybeSingle();

        if (deviceConflict != null) {
          debugPrint('[SubscriptionService] Sync failed: Current device is already bound to a different student');
          return false;
        }

        // Auto-bind on first sync
        try {
          await supabase.from('students').update({
            'device_id': currentDeviceId,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          }).or('phone_number.eq.$cleanPhone,phone_number.eq.$altPhone');
        } catch (e) {
          debugPrint('[SubscriptionService] Auto-bind error: $e');
        }
      } else if (boundDev != currentDeviceId) {
        debugPrint('[SubscriptionService] Device mismatch: registered $boundDev vs current $currentDeviceId');
        return false;
      }

      // 4. Extract genuine unlocked packages
      final List<dynamic>? rawPkgs = response['unlocked_packages'] as List<dynamic>?;
      final List<String> pkgs = rawPkgs != null ? rawPkgs.map((e) => e.toString()).toList() : [];

      await setUnlockedPackages(pkgs);
      await prefs.setString(_statusKey, response['subscription_status']?.toString() ?? 'active');
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

    if (await isSubscriptionExpired()) {
      return false;
    }

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

  /// Unlocks a specific grade package
  static Future<void> unlockGrade(int grade) async {
    await unlockPackage('pkg_grade_$grade');
  }

  /// Verifies if phone has legitimate access to packageId and enforces hardware device binding.
  static Future<DeviceBindingResult> syncWithSupabaseAndVerifyDevice(
    String phoneNumber, {
    String? packageId,
  }) async {
    final cleanPhone = sanitizeEthiopianPhone(phoneNumber);
    if (cleanPhone.isEmpty) {
      final currentDev = await DeviceService.getDeviceId();
      return DeviceBindingResult(
        status: DeviceBindingStatus.noSubscription,
        currentDeviceId: currentDev,
        message: 'ስልክ ቁጥር ባዶ መሆን አይችልም። / Phone number cannot be empty.',
      );
    }

    return await DeviceService.verifyAndBindSubscription(
      phoneNumber: cleanPhone,
      packageId: packageId ?? 'all_grades',
    );
  }

  /// Verifies student subscription directly in `students` table
  static Future<StudentUpgradeResult> verifyAndUpgradeStudent({
    String? fullName,
    String? phoneNumber,
    String? name,
    String? phone,
  }) async {
    final cleanName = (fullName ?? name ?? '').trim();
    final cleanPhone = sanitizeEthiopianPhone(phoneNumber ?? phone ?? '');

    if (cleanName.isEmpty) {
      return const StudentUpgradeResult(
        isSuccess: false,
        message: 'እባክዎ ሙሉ ስምዎን ያስገቡ። / Please enter your full name.',
      );
    }

    if (cleanPhone.isEmpty || cleanPhone.length < 9) {
      return const StudentUpgradeResult(
        isSuccess: false,
        message: 'እባክዎ ትክክለኛ ስልክ ቁጥር ያስገቡ። / Please enter a valid Ethiopian phone number.',
      );
    }

    // Rate Limiting Protection
    if (_lastFailedAttemptTime != null) {
      final diff = DateTime.now().difference(_lastFailedAttemptTime!);
      if (_failedAttemptsCount >= 5 && diff.inMinutes < 2) {
        final remainingSec = 120 - diff.inSeconds;
        return StudentUpgradeResult(
          isSuccess: false,
          message: 'የተደጋጋሚ ሙከራ ገደብ አልፏል። እባክዎ ከ $remainingSec ሰከንድ በኋላ በድጋሚ ይሞክሩ።',
        );
      } else if (diff.inMinutes >= 2) {
        _failedAttemptsCount = 0;
      }
    }

    try {
      final currentDeviceId = await DeviceService.getDeviceId();
      final supabase = Supabase.instance.client;
      final nowIso = DateTime.now().toUtc().toIso8601String();

      final altPhone = cleanPhone.startsWith('0') ? '+251${cleanPhone.substring(1)}' : cleanPhone;

      // Query `students` table directly with both formats
      final res = await supabase
          .from('students')
          .select('full_name, phone_number, grade, device_id, unlocked_packages, subscription_status, subscription_expires_at, is_active')
          .or('phone_number.eq.$cleanPhone,phone_number.eq.$altPhone')
          .maybeSingle();

      if (res == null) {
        _failedAttemptsCount++;
        _lastFailedAttemptTime = DateTime.now();
        return const StudentUpgradeResult(
          isSuccess: false,
          message: 'በዚህ ስልክ ቁጥር የተመዘገበ ተማሪ አልተገኘም። እባክዎ ሙሉ ስምዎንና ስልክ ቁጥርዎን በትክክል ያስገቡ።',
        );
      }

      // Check Active Status
      final bool isActive = res['is_active'] as bool? ?? true;
      if (!isActive) {
        return const StudentUpgradeResult(
          isSuccess: false,
          message: 'ይህ መለያ በአስተዳዳሪው ታግዷል። እባክዎ የድጋፍ አገልግሎትን ያነጋግሩ (@smart_x_help)።',
        );
      }

      // Check Expiration
      if (res['subscription_expires_at'] != null) {
        final expiresAt = DateTime.tryParse(res['subscription_expires_at'].toString());
        if (expiresAt != null && DateTime.now().toUtc().isAfter(expiresAt.toUtc())) {
          return const StudentUpgradeResult(
            isSuccess: false,
            message: 'የደንበኝነት ምዝገባዎ ጊዜ አልቋል። እባክዎ ፈቃድዎን ያድሱ። / Subscription has expired.',
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
          message: 'ይህ ስልክ ቁጥር ቀደም ሲል በሌላ ሞባይል ስልክ ላይ ተመዝግቧል! የደህንነት ስርዓቱ አንድን አካውንት ለአንድ ስልክ ብቻ ይፈቅዳል (Single-Device Protection)።',
        );
      }

      // First time binding or update device_id
      bool deviceBindingConfirmed = false;
      if (boundDev == null || boundDev.isEmpty) {
        // Strict Check: Check if currentDeviceId is already bound to another phone number
        final deviceConflict = await supabase
            .from('students')
            .select('phone_number')
            .eq('device_id', currentDeviceId)
            .neq('phone_number', cleanPhone)
            .neq('phone_number', altPhone)
            .maybeSingle();

        if (deviceConflict != null) {
          return const StudentUpgradeResult(
            isSuccess: false,
            message: 'ይህ መሣሪያ ቀደም ሲል ከሌላ መለያ ጋር ተገናኝቷል። ከአንድ መሣሪያ በላይ መያዝ አይቻልም! / This device is already linked to another phone number.',
          );
        }

        try {
          final updateRes = await supabase.from('students').update({
            'device_id': currentDeviceId,
            'full_name': cleanName,
            'updated_at': nowIso,
          }).or('phone_number.eq.$cleanPhone,phone_number.eq.$altPhone').select('device_id');
          
          if (updateRes.isNotEmpty && updateRes.first['device_id'] == currentDeviceId) {
            deviceBindingConfirmed = true;
          }
        } catch (bindErr) {
          debugPrint('[SubscriptionService] Auto-bind error: $bindErr');
        }
      } else {
        deviceBindingConfirmed = (boundDev == currentDeviceId);
        try {
          await supabase.from('students').update({
            'full_name': cleanName,
            'updated_at': nowIso,
          }).or('phone_number.eq.$cleanPhone,phone_number.eq.$altPhone');
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
          message: 'ስልክ ቁጥርዎ ተገኝቷል፤ ነገር ግን እስካሁን የተፈቀደ ንቁ የትምህርት ፓኬጅ የለም። እባክዎ መለያዎን ያረጋግጡ።',
        );
      }

      _failedAttemptsCount = 0;
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

      if (res['subscription_expires_at'] != null) {
        final expStr = res['subscription_expires_at'].toString();
        await prefs.setString(_expiresAtKey, expStr);
        _cachedExpiresAt = DateTime.tryParse(expStr);
      } else {
        await prefs.remove(_expiresAtKey);
        _cachedExpiresAt = null;
      }

      return StudentUpgradeResult(
        isSuccess: true,
        message: 'እንኳን ደስ አለዎት! $cleanName፣ የትምህርት ፈቃድዎ በዚህ ስልክ ላይ በተሳካ ሁኔታ ተረጋግጦ ተከፍቷል!',
        studentName: cleanName,
        phoneNumber: cleanPhone,
        grade: studentGrade,
        unlockedPackages: pkgs,
        deviceBindingConfirmed: deviceBindingConfirmed,
        boundDeviceId: currentDeviceId,
      );
    } catch (e) {
      debugPrint('[SubscriptionService] verifyAndUpgradeStudent error: $e');
      return StudentUpgradeResult(
        isSuccess: false,
        message: 'የማረጋገጫ ስህተት አጋጥሟል: $e',
        rawError: e.toString(),
      );
    }
  }

  /// Sanitizes phone numbers to standard format (09..., 07..., 251...)
  static String sanitizeEthiopianPhone(String raw) {
    String p = raw.replaceAll(RegExp(r'[^0-9+]'), '').trim();
    if (p.startsWith('+251')) {
      p = '0${p.substring(4)}';
    } else if (p.startsWith('251')) {
      p = '0${p.substring(3)}';
    }
    return p;
  }

  /// Opens Telegram with a formatted custom message including student info, Grade, Unit, Package, and Device ID
  static Future<void> contactAdminOnTelegram({
    BuildContext? context,
    String? studentName,
    String? phoneNumber,
    int? grade,
    String? subject,
    int? unitNumber,
    String? unitTitle,
    String? packageName,
    String? customPurpose,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = (studentName != null && studentName.isNotEmpty)
          ? studentName
          : (prefs.getString('user_fullName') ?? prefs.getString('user_name') ?? '');
      final phone = (phoneNumber != null && phoneNumber.isNotEmpty)
          ? phoneNumber
          : (prefs.getString('user_phoneNumber') ?? prefs.getString('phone_number') ?? '');
      final currentDeviceId = await DeviceService.getDeviceId();
      final int userGrade = grade ?? prefs.getInt('user_grade') ?? prefs.getInt('selected_grade') ?? 12;

      final StringBuffer buffer = StringBuffer();
      buffer.writeln('ሰላም አስተዳዳሪ (Smart Learn Admin)፣');
      buffer.writeln('የ Smart Learn Ethiopian አካውንቴን ለማሳደግ (Upgrade) ፈልጌ ነበር።');
      buffer.writeln('');
      if (customPurpose != null && customPurpose.isNotEmpty) {
        buffer.writeln('📌 ዓላማ: $customPurpose');
      } else if (packageName != null && packageName.isNotEmpty) {
        buffer.writeln('📦 የተመረጠው ፓኬጅ: $packageName');
      } else if (subject != null && unitNumber != null) {
        final titlePart = (unitTitle != null && unitTitle.isNotEmpty) ? ' ($unitTitle)' : '';
        buffer.writeln('📚 የትምህርት ምዕራፍ: Grade $userGrade - $subject Unit $unitNumber$titlePart (በ 50 ብር)');
      } else {
        buffer.writeln('📚 የትምህርት ክፍል: Grade $userGrade ሙሉ ትምህርት');
      }
      buffer.writeln('');
      if (name.isNotEmpty) buffer.writeln('👤 የተማሪ ሙሉ ስም: $name');
      if (phone.isNotEmpty) buffer.writeln('📱 ስልክ ቁጥር: $phone');
      buffer.writeln('🎓 ክፍል (Grade): Grade $userGrade');
      if (currentDeviceId.isNotEmpty) buffer.writeln('🔑 Device ID: $currentDeviceId');
      buffer.writeln('');
      buffer.writeln('እባክዎ አካውንቴን አረጋግጠው ፈቃዴን ይክፈቱልኝ። እናመሰግናለን!');

      final String fullMessage = buffer.toString();
      final String encodedMsg = Uri.encodeComponent(fullMessage);
      final Uri telegramUri = Uri.parse('https://t.me/smart_x_help?text=$encodedMsg');

      bool launched = false;
      if (await canLaunchUrl(telegramUri)) {
        launched = await launchUrl(telegramUri, mode: LaunchMode.externalApplication);
      }
      if (!launched) {
        await launchUrl(telegramUri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      debugPrint('[SubscriptionService] contactAdminOnTelegram error: $e');
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('መልእክቱን ወደ አስተዳዳሪው ለመላክ ቴሌግራም ይክፈቱ'),
            backgroundColor: Color(0xFF0088CC),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

class StudentUpgradeResult {
  final bool isSuccess;
  final bool isDeviceMismatch;
  final String message;
  final String? studentName;
  final String? phoneNumber;
  final int? grade;
  final List<String>? unlockedPackages;
  final bool deviceBindingConfirmed;
  final String? boundDeviceId;
  final String? rawError;

  const StudentUpgradeResult({
    required this.isSuccess,
    this.isDeviceMismatch = false,
    required this.message,
    this.studentName,
    this.phoneNumber,
    this.grade,
    this.unlockedPackages,
    this.deviceBindingConfirmed = false,
    this.boundDeviceId,
    this.rawError,
  });
}
