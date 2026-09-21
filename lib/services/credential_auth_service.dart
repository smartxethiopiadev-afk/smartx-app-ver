import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'device_service.dart';
import 'subscription_service.dart';

enum CredentialAuthStatus {
  success,
  invalidCredentials,
  inactiveAccount,
  deviceMismatchLocked,
  networkError,
}

class CredentialAuthResult {
  final CredentialAuthStatus status;
  final String? message;
  final String? packageId;
  final String? studentName;
  final String? phoneNumber;

  const CredentialAuthResult({
    required this.status,
    this.message,
    this.packageId,
    this.studentName,
    this.phoneNumber,
  });

  bool get isSuccess => status == CredentialAuthStatus.success;
}

class CredentialAuthService {
  static const String _keyIsAuth = 'is_authenticated';
  static const String _keyFullName = 'user_fullName';
  static const String _keyPhone = 'user_phoneNumber';
  static const String _keyBoundDeviceId = 'smartx_verified_device_binding';

  /// Authenticates a student using Phone & Name without passwords against the `students` table.
  static Future<CredentialAuthResult> loginWithPhoneAndName({
    required String fullName,
    required String phoneNumber,
    int? grade,
    String? subject,
  }) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\s+'), '').trim();
    final cleanName = fullName.trim();

    if (cleanPhone.isEmpty) {
      return const CredentialAuthResult(
        status: CredentialAuthStatus.invalidCredentials,
        message: 'እባክዎ ስልክ ቁጥርዎን ያስገቡ። / Please enter your phone number.',
      );
    }

    final currentDeviceId = await DeviceService.getDeviceId();
    final prefs = await SharedPreferences.getInstance();

    try {
      final supabase = Supabase.instance.client;
      Map<String, dynamic>? studentRecord;

      // Query ONLY public.students table
      try {
        final res = await supabase
            .from('students')
            .select()
            .eq('phone_number', cleanPhone)
            .maybeSingle();
        if (res != null) {
          studentRecord = res;
        }
      } catch (e) {
        debugPrint('[Auth] students query error: $e');
      }

      // If not found in database, check cached SharedPreferences
      if (studentRecord == null) {
        final cachedPhone = prefs.getString(_keyPhone) ?? prefs.getString('user_phoneNumber') ?? '';
        final cachedAuth = prefs.getBool(_keyIsAuth) ?? false;
        final cachedDevId = prefs.getString(_keyBoundDeviceId) ?? '';

        if (cachedAuth && cachedPhone.isNotEmpty && (cachedPhone == cleanPhone || cleanPhone.endsWith(cachedPhone) || cleanPhone.endsWith(cachedPhone))) {
          if (cachedDevId.isNotEmpty && cachedDevId != currentDeviceId) {
            return const CredentialAuthResult(
              status: CredentialAuthStatus.deviceMismatchLocked,
              message: 'ይህ ስልክ ቁጥር አስቀድሞ በሌላ ስልክ ላይ ተመዝግቧል። መለያ ማጋራት በጥብቅ የተከለከለ ነው።',
            );
          }
          final savedName = prefs.getString(_keyFullName) ?? cleanName;
          return CredentialAuthResult(
            status: CredentialAuthStatus.success,
            message: 'እንኳን በደህና ተመለሱ! / Welcome back!',
            studentName: savedName,
            phoneNumber: cleanPhone,
          );
        }

        return const CredentialAuthResult(
          status: CredentialAuthStatus.invalidCredentials,
          message: 'ይህ ስልክ ቁጥር በመረጃ ቋት ውስጥ አልተገኘም። እባክዎ መጀመሪያ ይመዝገቡ። / No account found. Please register first.',
        );
      }

      // Check isActive
      final bool isActive = studentRecord['is_active'] as bool? ?? true;
      if (!isActive) {
        return const CredentialAuthResult(
          status: CredentialAuthStatus.inactiveAccount,
          message: 'ይህ መለያ በአሁኑ ጊዜ አገልግሎቱ ተቋርጧል።',
        );
      }

      // Device binding check against students.device_id
      final String? boundDeviceId = (studentRecord['device_id'] as String?)?.trim();
      if (boundDeviceId == null || boundDeviceId.isEmpty) {
        try {
          await supabase.from('students').update({
            'device_id': currentDeviceId,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          }).eq('phone_number', cleanPhone);
        } catch (_) {}
      } else if (boundDeviceId != currentDeviceId) {
        return const CredentialAuthResult(
          status: CredentialAuthStatus.deviceMismatchLocked,
          message: 'ይህ ስልክ ቁጥር አስቀድሞ በሌላ ስልክ ላይ ተመዝግቧል። መለያ ማጋራት በጥብቅ የተከለከለ ነው።',
        );
      }

      final dbName = (studentRecord['full_name'] as String?) ?? cleanName;
      final int dbGrade = (studentRecord['grade'] as num?)?.toInt() ?? grade ?? 9;

      // Save locally
      await prefs.setBool(_keyIsAuth, true);
      await prefs.setString(_keyFullName, dbName.isNotEmpty ? dbName : 'Smart Student');
      await prefs.setString(_keyPhone, cleanPhone);
      await prefs.setInt('selected_grade', dbGrade);
      await prefs.setString(_keyBoundDeviceId, currentDeviceId);

      // Sync unlocked packages from students.unlocked_packages
      try {
        final List<dynamic>? unlockedList = studentRecord['unlocked_packages'] as List<dynamic>?;
        if (unlockedList != null) {
          final pkgs = unlockedList.map((e) => e.toString()).toList();
          await SubscriptionService.setUnlockedPackages(pkgs);
        }
      } catch (_) {}

      return CredentialAuthResult(
        status: CredentialAuthStatus.success,
        message: 'በተሳካ ሁኔታ ገብተዋል! / Login successful!',
        studentName: dbName,
        phoneNumber: cleanPhone,
      );
    } catch (e) {
      final cachedPhone = prefs.getString(_keyPhone) ?? '';
      final cachedDevId = prefs.getString(_keyBoundDeviceId) ?? '';
      if (cachedPhone.isNotEmpty && cachedPhone == cleanPhone) {
        if (cachedDevId.isNotEmpty && cachedDevId != currentDeviceId) {
          return const CredentialAuthResult(
            status: CredentialAuthStatus.deviceMismatchLocked,
            message: 'ይህ ስልክ ቁጥር አስቀድሞ በሌላ ስልክ ላይ ተመዝግቧል።',
          );
        }
        await prefs.setBool(_keyIsAuth, true);
        return CredentialAuthResult(
          status: CredentialAuthStatus.success,
          message: 'ከመስመር ውጭ ገብተዋል / Logged in offline',
          studentName: prefs.getString(_keyFullName) ?? cleanName,
          phoneNumber: cleanPhone,
        );
      }

      return const CredentialAuthResult(
        status: CredentialAuthStatus.networkError,
        message: 'የኔትወርክ ችግር አጋጥሟል። / Network error.',
      );
    }
  }

  /// Registers or upserts a student in the `students` table.
  static Future<CredentialAuthResult> registerStudent({
    required String fullName,
    required String phoneNumber,
    required int grade,
  }) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\s+'), '').trim();
    final cleanName = fullName.trim();

    if (cleanPhone.isEmpty || cleanName.isEmpty) {
      return const CredentialAuthResult(
        status: CredentialAuthStatus.invalidCredentials,
        message: 'እባክዎ ሙሉ ስም እና ስልክ ቁጥር ያስገቡ።',
      );
    }

    final currentDeviceId = await DeviceService.getDeviceId();
    final prefs = await SharedPreferences.getInstance();
    List<String> unlockedPackages = [];

    try {
      final supabase = Supabase.instance.client;

      // Check existing device binding in `students`
      try {
        final existing = await supabase
            .from('students')
            .select('device_id, unlocked_packages')
            .eq('phone_number', cleanPhone)
            .maybeSingle();

        if (existing != null) {
          final String? existingDev = existing['device_id'] as String?;
          if (existingDev != null && existingDev.isNotEmpty && existingDev != currentDeviceId) {
            return const CredentialAuthResult(
              status: CredentialAuthStatus.deviceMismatchLocked,
              message: 'ይህ ስልክ ቁጥር አስቀድሞ በሌላ ስልክ ላይ ተመዝግቧል።',
            );
          }
          final List<dynamic>? rawExistingPkgs = existing['unlocked_packages'] as List<dynamic>?;
          if (rawExistingPkgs != null) {
            unlockedPackages = rawExistingPkgs.map((e) => e.toString()).toList();
          }
        }
      } catch (e) {
        debugPrint('[Auth] check existing student error: $e');
      }

      // Upsert into `students` table strictly with genuine unlocked packages
      try {
        await supabase.from('students').upsert({
          'full_name': cleanName,
          'phone_number': cleanPhone,
          'grade': grade,
          'device_id': currentDeviceId,
          'is_active': true,
          'unlocked_packages': unlockedPackages,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }, onConflict: 'phone_number');
      } catch (upsertErr) {
        debugPrint('[Auth] students upsert error: $upsertErr');
        await supabase.from('students').insert({
          'full_name': cleanName,
          'phone_number': cleanPhone,
          'grade': grade,
          'device_id': currentDeviceId,
          'is_active': true,
          'unlocked_packages': unlockedPackages,
        });
      }

      // Save local session
      await prefs.setBool(_keyIsAuth, true);
      await prefs.setString(_keyFullName, cleanName);
      await prefs.setString(_keyPhone, cleanPhone);
      await prefs.setInt('selected_grade', grade);
      await prefs.setString(_keyBoundDeviceId, currentDeviceId);

      await SubscriptionService.setUnlockedPackages(unlockedPackages);

      return CredentialAuthResult(
        status: CredentialAuthStatus.success,
        message: 'ምዝገባው በተሳካ ሁኔታ ተጠናቋል! / Registration successful!',
        studentName: cleanName,
        phoneNumber: cleanPhone,
      );
    } catch (e) {
      debugPrint('[Auth] registerStudent error: $e');
      // Offline fallback
      await prefs.setBool(_keyIsAuth, true);
      await prefs.setString(_keyFullName, cleanName);
      await prefs.setString(_keyPhone, cleanPhone);
      await prefs.setInt('selected_grade', grade);
      await prefs.setString(_keyBoundDeviceId, currentDeviceId);

      return CredentialAuthResult(
        status: CredentialAuthStatus.success,
        message: 'በተሳካ ሁኔታ ተመዝግበዋል (ከመስመር ውጭ)!',
        studentName: cleanName,
        phoneNumber: cleanPhone,
      );
    }
  }

  static Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    final isAuth = prefs.getBool(_keyIsAuth) ?? false;
    if (!isAuth) return false;

    final boundDevice = prefs.getString(_keyBoundDeviceId);
    final currentDevice = await DeviceService.getDeviceId();
    if (boundDevice != null && boundDevice.isNotEmpty && boundDevice != currentDevice) {
      return false;
    }
    return true;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsAuth, false);
  }

  static Future<Map<String, String>> getCachedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'fullName': prefs.getString(_keyFullName) ?? '',
      'phoneNumber': prefs.getString(_keyPhone) ?? '',
      'boundDeviceId': prefs.getString(_keyBoundDeviceId) ?? '',
    };
  }
}
