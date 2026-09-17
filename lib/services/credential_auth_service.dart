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
  static const String _keyActivePackage = 'smartx_active_package_id';
  static const String _keyBoundDeviceId = 'smartx_verified_device_binding';

  /// Authenticates a student using Phone & Name without requiring a password.
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

      // 1. Check 'profiles' table
      try {
        final profileRes = await supabase
            .from('profiles')
            .select()
            .eq('phone_number', cleanPhone)
            .maybeSingle();
        if (profileRes != null) {
          studentRecord = profileRes;
        }
      } catch (e) {
        debugPrint('[Auth] profiles check: $e');
      }

      // 2. Check 'student_profiles' table
      if (studentRecord == null) {
        try {
          final sProfileRes = await supabase
              .from('student_profiles')
              .select()
              .eq('phone_number', cleanPhone)
              .maybeSingle();
          if (sProfileRes != null) {
            studentRecord = sProfileRes;
          }
        } catch (e) {
          debugPrint('[Auth] student_profiles check: $e');
        }
      }

      // 3. Check 'student_credentials' table
      if (studentRecord == null) {
        try {
          final credRes = await supabase
              .from('student_credentials')
              .select()
              .eq('phone_number', cleanPhone)
              .maybeSingle();
          if (credRes != null) {
            studentRecord = credRes;
          }
        } catch (e) {
          debugPrint('[Auth] student_credentials check: $e');
        }
      }

      // 4. Check 'student_registrations' table
      if (studentRecord == null) {
        try {
          final regRes = await supabase
              .from('student_registrations')
              .select()
              .eq('phone_number', cleanPhone)
              .maybeSingle();
          if (regRes != null) {
            studentRecord = regRes;
          }
        } catch (e) {
          debugPrint('[Auth] student_registrations check: $e');
        }
      }

      // If not found in database, check cached SharedPreferences
      if (studentRecord == null) {
        final cachedPhone = prefs.getString(_keyPhone) ?? prefs.getString('phone_number') ?? prefs.getString('user_phoneNumber') ?? '';
        final cachedAuth = prefs.getBool(_keyIsAuth) ?? prefs.getBool('is_authenticated') ?? false;
        final cachedReg = prefs.getBool('has_registered') ?? false;
        final cachedDevId = prefs.getString(_keyBoundDeviceId) ?? prefs.getString('user_device_id') ?? '';

        if ((cachedAuth || cachedReg) && cachedPhone.isNotEmpty && (cachedPhone == cleanPhone || cleanPhone.endsWith(cachedPhone) || cachedPhone.endsWith(cleanPhone))) {
          if (cachedDevId.isNotEmpty && cachedDevId != currentDeviceId) {
            return const CredentialAuthResult(
              status: CredentialAuthStatus.deviceMismatchLocked,
              message: 'ይህ ስልክ ቁጥር አስቀድሞ በሌላ ስልክ ላይ ተመዝግቧል። መለያ ማጋራት በጥብቅ የተከለከለ ነው።',
            );
          }
          final savedName = prefs.getString(_keyFullName) ?? prefs.getString('user_fullName') ?? cleanName;
          await prefs.setBool(_keyIsAuth, true);
          await prefs.setString(_keyBoundDeviceId, currentDeviceId);
          return CredentialAuthResult(
            status: CredentialAuthStatus.success,
            message: 'እንኳን በደህና ተመለሱ! / Welcome back!',
            studentName: savedName,
            phoneNumber: cleanPhone,
          );
        }

        return const CredentialAuthResult(
          status: CredentialAuthStatus.invalidCredentials,
          message: 'ይህ ስልክ ቁጥር በመረጃ ቋት ውስጥ አልተገኘም። እባክዎ መጀመሪያ ይመዝገቡ። / No account found with this phone. Please register first.',
        );
      }

      // Found student! Check device binding logic
      final String? boundDeviceId = (studentRecord['device_id'] as String?)?.trim();
      if (boundDeviceId == null || boundDeviceId.isEmpty) {
        // Automatically bind current hardware device in Supabase
        try {
          await supabase.from('student_profiles').update({'device_id': currentDeviceId}).eq('phone_number', cleanPhone);
        } catch (_) {}
        try {
          await supabase.from('profiles').update({'device_id': currentDeviceId}).eq('phone_number', cleanPhone);
        } catch (_) {}
        debugPrint('[CredentialAuthService] Bound device $currentDeviceId to student $cleanPhone');
      } else if (boundDeviceId != currentDeviceId) {
        // Device mismatch: Block login
        return const CredentialAuthResult(
          status: CredentialAuthStatus.deviceMismatchLocked,
          message: 'ይህ ስልክ ቁጥር አስቀድሞ በሌላ ስልክ ላይ ተመዝግቧል። መለያ ማጋራት በጥብቅ የተከለከለ ነው።',
        );
      }

      final dbName = (studentRecord['full_name'] as String?) ??
          (studentRecord['name'] as String?) ??
          cleanName;
      final int dbGrade = (studentRecord['grade'] as num?)?.toInt() ?? grade ?? 9;
      final packageId = (studentRecord['package_id'] as String?) ?? 'pkg_grade_$dbGrade';

      // Save locally
      await prefs.setBool(_keyIsAuth, true);
      await prefs.setBool('has_registered', true);
      await prefs.setBool('is_authenticated', true);
      await prefs.setString(_keyFullName, dbName.isNotEmpty ? dbName : (cleanName.isNotEmpty ? cleanName : 'Smart Student'));
      await prefs.setString('user_fullName', dbName.isNotEmpty ? dbName : (cleanName.isNotEmpty ? cleanName : 'Smart Student'));
      await prefs.setString(_keyPhone, cleanPhone);
      await prefs.setString('user_phoneNumber', cleanPhone);
      await prefs.setString('user_grade', 'Grade $dbGrade');
      await prefs.setInt('selected_grade', dbGrade);
      await prefs.setString(_keyActivePackage, packageId);
      await prefs.setString(_keyBoundDeviceId, currentDeviceId);
      await prefs.setString('user_device_id', currentDeviceId);
      await prefs.setString('smartx_verified_device_binding', currentDeviceId);

      // Sync active subscriptions
      try {
        await SubscriptionService.syncWithSupabase(cleanPhone);
      } catch (_) {}

      return CredentialAuthResult(
        status: CredentialAuthStatus.success,
        message: 'በተሳካ ሁኔታ ገብተዋል! / Login successful!',
        studentName: dbName,
        phoneNumber: cleanPhone,
        packageId: packageId,
      );
    } catch (e) {
      final cachedPhone = prefs.getString(_keyPhone) ?? prefs.getString('phone_number') ?? prefs.getString('user_phoneNumber') ?? '';
      final cachedDevId = prefs.getString(_keyBoundDeviceId) ?? prefs.getString('user_device_id') ?? '';
      if (cachedPhone.isNotEmpty && (cachedPhone == cleanPhone || cleanPhone.endsWith(cachedPhone) || cachedPhone.endsWith(cleanPhone))) {
        if (cachedDevId.isNotEmpty && cachedDevId != currentDeviceId) {
          return const CredentialAuthResult(
            status: CredentialAuthStatus.deviceMismatchLocked,
            message: 'ይህ ስልክ ቁጥር አስቀድሞ በሌላ ስልክ ላይ ተመዝግቧል። መለያ ማጋራት በጥብቅ የተከለከለ ነው።',
          );
        }
        await prefs.setBool(_keyIsAuth, true);
        final savedName = prefs.getString(_keyFullName) ?? prefs.getString('user_fullName') ?? cleanName;
        return CredentialAuthResult(
          status: CredentialAuthStatus.success,
          message: 'ከመስመር ውጭ ገብተዋል / Logged in offline',
          studentName: savedName,
          phoneNumber: cleanPhone,
        );
      }

      return const CredentialAuthResult(
        status: CredentialAuthStatus.networkError,
        message: 'የኔትወርክ ችግር አጋጥሟል። እባክዎ ግንኙነትዎን ያረጋግጡ። / Network error. Please check your connection.',
      );
    }
  }

  /// Registers a student with Full Name, Phone Number, and Grade (9, 10, 11, 12).
  /// Silently binds the hardware device ID and saves { full_name, phone_number, grade, device_id } into Supabase student_profiles.
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
        message: 'እባክዎ ሙሉ ስም እና ስልክ ቁጥር ያስገቡ። / Please enter your name and phone number.',
      );
    }

    final currentDeviceId = await DeviceService.getDeviceId();
    final prefs = await SharedPreferences.getInstance();

    try {
      final supabase = Supabase.instance.client;

      // 1. Check if phone is already registered on another device
      try {
        final existing = await supabase
            .from('student_profiles')
            .select('device_id')
            .eq('phone_number', cleanPhone)
            .maybeSingle();

        if (existing != null) {
          final String? existingDev = existing['device_id'] as String?;
          if (existingDev != null && existingDev.isNotEmpty && existingDev != currentDeviceId) {
            return const CredentialAuthResult(
              status: CredentialAuthStatus.deviceMismatchLocked,
              message: 'ይህ ስልክ ቁጥር አስቀድሞ በሌላ ስልክ ላይ ተመዝግቧል። መለያ ማጋራት በጥብቅ የተከለከለ ነው።',
            );
          }
        }
      } catch (e) {
        debugPrint('[CredentialAuthService] Check existing note: $e');
      }

      // 2. Save student_profiles record with device_id
      try {
        await supabase.from('student_profiles').upsert({
          'full_name': cleanName,
          'phone_number': cleanPhone,
          'grade': grade,
          'device_id': currentDeviceId,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }, onConflict: 'phone_number');
      } catch (upsertErr) {
        debugPrint('[CredentialAuthService] student_profiles upsert note: $upsertErr');
        try {
          await supabase.from('student_profiles').insert({
            'full_name': cleanName,
            'phone_number': cleanPhone,
            'grade': grade,
            'device_id': currentDeviceId,
          });
        } catch (_) {}
      }

      // Also ensure profiles table sync if present
      try {
        await supabase.from('profiles').upsert({
          'full_name': cleanName,
          'phone_number': cleanPhone,
          'grade': grade,
          'device_id': currentDeviceId,
        }, onConflict: 'phone_number');
      } catch (_) {}

      // 3. Save local session
      await prefs.setBool(_keyIsAuth, true);
      await prefs.setBool('has_registered', true);
      await prefs.setBool('is_authenticated', true);
      await prefs.setString(_keyFullName, cleanName);
      await prefs.setString('user_fullName', cleanName);
      await prefs.setString(_keyPhone, cleanPhone);
      await prefs.setString('user_phoneNumber', cleanPhone);
      await prefs.setString('user_grade', 'Grade $grade');
      await prefs.setInt('selected_grade', grade);
      await prefs.setString(_keyBoundDeviceId, currentDeviceId);
      await prefs.setString('user_device_id', currentDeviceId);
      await prefs.setString('smartx_verified_device_binding', currentDeviceId);

      return CredentialAuthResult(
        status: CredentialAuthStatus.success,
        message: 'ምዝገባው በተሳካ ሁኔታ ተጠናቋል! / Registration successful!',
        studentName: cleanName,
        phoneNumber: cleanPhone,
      );
    } catch (e) {
      debugPrint('[CredentialAuthService] registerStudent error: $e');

      // Offline fallback: Save locally so user can immediately study Unit 1 offline
      await prefs.setBool(_keyIsAuth, true);
      await prefs.setBool('has_registered', true);
      await prefs.setBool('is_authenticated', true);
      await prefs.setString(_keyFullName, cleanName);
      await prefs.setString('user_fullName', cleanName);
      await prefs.setString(_keyPhone, cleanPhone);
      await prefs.setString('user_phoneNumber', cleanPhone);
      await prefs.setString('user_grade', 'Grade $grade');
      await prefs.setInt('selected_grade', grade);
      await prefs.setString(_keyBoundDeviceId, currentDeviceId);
      await prefs.setString('user_device_id', currentDeviceId);

      return CredentialAuthResult(
        status: CredentialAuthStatus.success,
        message: 'በተሳካ ሁኔታ ተመዝግበዋል (ከመስመር ውጭ)!',
        studentName: cleanName,
        phoneNumber: cleanPhone,
      );
    }
  }

  /// Authenticates a student using Admin-issued Phone & Password with single-device binding.
  static Future<CredentialAuthResult> loginWithCredentials({
    required String fullName,
    required String phoneNumber,
    required String password,
    required int grade,
    String? subject,
  }) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\s+'), '').trim();
    final cleanPass = password.trim();
    final cleanName = fullName.trim();

    if (cleanPhone.isEmpty || cleanPass.isEmpty) {
      return const CredentialAuthResult(
        status: CredentialAuthStatus.invalidCredentials,
        message: 'Please enter both phone number and password.',
      );
    }

    final currentDeviceId = await DeviceService.getDeviceId();

    try {
      final supabase = Supabase.instance.client;

      // 1. Query student_credentials table (supports allowed_subjects, package_id, grade)
      final response = await supabase
          .from('student_credentials')
          .select('id, full_name, phone_number, password, package_id, allowed_subjects, grade, device_id, is_active')
          .eq('phone_number', cleanPhone)
          .maybeSingle();

      if (response == null) {
        return const CredentialAuthResult(
          status: CredentialAuthStatus.invalidCredentials,
          message: 'ምንም ተማሪ በዚህ ስልክ ቁጥር አልተገኘም። እባክዎ ስልክ ቁጥርዎን ያረጋግጡ ወይም አስተዳዳሪውን ያነጋግሩ።',
        );
      }

      final String dbPassword = response['password'] as String? ?? '';
      if (dbPassword != cleanPass) {
        return const CredentialAuthResult(
          status: CredentialAuthStatus.invalidCredentials,
          message: 'የገቡት የይለፍ ቃል የተሳሳተ ነው። እባክዎ በአስተዳዳሪ የተሰጦትን የይለፍ ቃል በትክክል ያስገቡ።',
        );
      }

      final bool isActive = response['is_active'] as bool? ?? false;
      if (!isActive) {
        return const CredentialAuthResult(
          status: CredentialAuthStatus.inactiveAccount,
          message: 'ይህ መለያ በአሁኑ ጊዜ አገልግሎቱ ተቋርጧል። እባክዎ አስተዳዳሪውን ያነጋግሩ።',
        );
      }

      final String? registeredDeviceId = response['device_id'] as String?;
      final String packageId = response['package_id'] as String? ?? 'pkg_grade_$grade';
      final dynamic rawSubjects = response['allowed_subjects'];
      final String studentName = response['full_name'] as String? ?? cleanName;

      // 2. Single-Device Automated Binding & Anti-Sharing Enforcement
      if (registeredDeviceId == null || registeredDeviceId.trim().isEmpty) {
        // First login on this device: Bind hardware device in background
        await supabase
            .from('student_credentials')
            .update({'device_id': currentDeviceId})
            .eq('phone_number', cleanPhone);

        debugPrint('[CredentialAuthService] Automatically bound device to account $cleanPhone');
      } else if (registeredDeviceId != currentDeviceId) {
        // Device Mismatch (Account active on another device) - Keep Device ID completely secret
        return CredentialAuthResult(
          status: CredentialAuthStatus.deviceMismatchLocked,
          message: 'ይህ መለያ አስቀድሞ በሌላ ስልክ ላይ ገብቷል። መለያ ማጋራት በጥብቅ የተከለከለ ነው። ስልክ ከቀየሩ አስተዳዳሪውን ያነጋግሩ።',
          studentName: studentName,
          phoneNumber: cleanPhone,
        );
      }

      // 3. Save Session Locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsAuth, true);
      await prefs.setString(_keyFullName, studentName.isNotEmpty ? studentName : cleanName);
      await prefs.setString(_keyPhone, cleanPhone);
      await prefs.setString(_keyActivePackage, packageId);
      await prefs.setString(_keyBoundDeviceId, currentDeviceId);

      // 4. Dynamic Multi-Course/Subject Unlock (Password never changes when admin adds subjects)
      // Unlock all packages from packageId
      for (final pkg in packageId.split(',')) {
        final trimmed = pkg.trim();
        if (trimmed.isNotEmpty) {
          await SubscriptionService.unlockPackage(trimmed);
        }
      }

      // Unlock all subjects from allowed_subjects array or string if provided
      if (rawSubjects is List) {
        for (final sub in rawSubjects) {
          final sName = sub.toString().toLowerCase().trim();
          if (sName.isNotEmpty) {
            await SubscriptionService.unlockPackage('pkg_g${grade}_$sName');
            await SubscriptionService.unlockPackage(sName);
          }
        }
      } else if (rawSubjects is String && rawSubjects.isNotEmpty) {
        for (final sub in rawSubjects.split(',')) {
          final sName = sub.toLowerCase().trim();
          if (sName.isNotEmpty) {
            await SubscriptionService.unlockPackage('pkg_g${grade}_$sName');
            await SubscriptionService.unlockPackage(sName);
          }
        }
      }

      return CredentialAuthResult(
        status: CredentialAuthStatus.success,
        message: 'በተሳካ ሁኔታ ገብተዋል! የተፈቀዱ የትምህርት ክፍሎች በሙሉ ተከፍተዋል።',
        packageId: packageId,
        studentName: studentName,
        phoneNumber: cleanPhone,
      );
    } catch (e) {
      debugPrint('[CredentialAuthService] Verification server error: $e');

      // Offline fallback: Check if this user previously logged in on this exact device
      final prefs = await SharedPreferences.getInstance();
      final bool wasAuth = prefs.getBool(_keyIsAuth) ?? false;
      final String? savedPhone = prefs.getString(_keyPhone);
      final String? savedBoundDevice = prefs.getString(_keyBoundDeviceId);

      if (wasAuth && savedPhone == cleanPhone && savedBoundDevice == currentDeviceId) {
        return CredentialAuthResult(
          status: CredentialAuthStatus.success,
          message: 'የቀድሞው ክፍለ-ጊዜዎ በዚህ ስልክ ላይ በተሳካ ሁኔታ ተረጋግጧል።',
          packageId: prefs.getString(_keyActivePackage) ?? 'pkg_grade_$grade',
          studentName: prefs.getString(_keyFullName) ?? cleanName,
          phoneNumber: cleanPhone,
        );
      }

      return const CredentialAuthResult(
        status: CredentialAuthStatus.networkError,
        message: 'ከአገልጋዩ ጋር መገናኘት አልተቻለም። እባክዎ የኢንተርኔት ግንኙነትዎን ያረጋግጡና እንደገና ይሞክሩ።',
      );
    }
  }

  /// Offline "Welcome Back" Authentication
  /// Validates phone number and checks device ID matching
  static Future<CredentialAuthResult> loginOfflineWelcomeBack({
    required String fullName,
    required String phoneNumber,
  }) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\s+'), '').trim();
    final cleanName = fullName.trim();
    final currentDeviceId = await DeviceService.getDeviceId();

    final prefs = await SharedPreferences.getInstance();
    final String? savedPhone = prefs.getString(_keyPhone) ?? prefs.getString('user_phoneNumber');
    final String? savedDeviceId = prefs.getString(_keyBoundDeviceId) ?? prefs.getString('user_device_id');
    final bool hasRegistered = prefs.getBool('has_registered') ?? false;

    // Check if phone matches and device ID matches (or first offline bind if registered)
    bool matchesPhone = false;
    if (savedPhone != null && savedPhone.isNotEmpty) {
      final sNorm = savedPhone.replaceAll(RegExp(r'\D'), '');
      final cNorm = cleanPhone.replaceAll(RegExp(r'\D'), '');
      matchesPhone = (sNorm == cNorm) || sNorm.endsWith(cNorm) || cNorm.endsWith(sNorm);
    }

    if (matchesPhone || hasRegistered) {
      // Device ID check
      if (savedDeviceId != null && savedDeviceId.isNotEmpty && savedDeviceId != currentDeviceId) {
        return CredentialAuthResult(
          status: CredentialAuthStatus.deviceMismatchLocked,
          message: 'ይህ ስልክ ቁጥር ከተለየ መሳሪያ ጋር ተቆራኝቷል። እባክዎ በትክክለኛው ስልክዎ ይጠቀሙ።',
          studentName: cleanName,
          phoneNumber: cleanPhone,
        );
      }

      // Success! Auto-bind this device
      await prefs.setBool(_keyIsAuth, true);
      await prefs.setString(_keyFullName, cleanName.isNotEmpty ? cleanName : (prefs.getString(_keyFullName) ?? 'Student'));
      await prefs.setString(_keyPhone, cleanPhone.isNotEmpty ? cleanPhone : (savedPhone ?? ''));
      await prefs.setString(_keyBoundDeviceId, currentDeviceId);

      return CredentialAuthResult(
        status: CredentialAuthStatus.success,
        message: 'እንኳን ደህና መጡ! ከመስመር ውጭ በተሳካ ሁኔታ ገብተዋል።',
        studentName: cleanName,
        phoneNumber: cleanPhone,
      );
    }

    // Allow offline first-time entry if valid phone number
    if (cleanPhone.length >= 9) {
      await prefs.setBool(_keyIsAuth, true);
      await prefs.setString(_keyFullName, cleanName.isNotEmpty ? cleanName : 'Student');
      await prefs.setString(_keyPhone, cleanPhone);
      await prefs.setString(_keyBoundDeviceId, currentDeviceId);
      await prefs.setBool('has_registered', true);

      return CredentialAuthResult(
        status: CredentialAuthStatus.success,
        message: 'እንኳን ደህና መጡ! መሳሪያዎ በተሳካ ሁኔታ ተመዝግቧል።',
        studentName: cleanName,
        phoneNumber: cleanPhone,
      );
    }

    return const CredentialAuthResult(
      status: CredentialAuthStatus.invalidCredentials,
      message: 'እባክዎ ትክክለኛ ስም እና ስልክ ቁጥር ያስገቡ።',
    );
  }

  /// Checks if the current user has an active authenticated session
  static Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    final isAuth = prefs.getBool(_keyIsAuth) ?? false;
    if (!isAuth) return false;

    // Verify offline device integrity
    final boundDevice = prefs.getString(_keyBoundDeviceId);
    final currentDevice = await DeviceService.getDeviceId();
    if (boundDevice != null && boundDevice.isNotEmpty && boundDevice != currentDevice) {
      return false;
    }
    return true;
  }

  /// Clears session on logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsAuth, false);
  }

  /// Returns saved student credentials if available
  static Future<Map<String, String>> getCachedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'fullName': prefs.getString(_keyFullName) ?? '',
      'phoneNumber': prefs.getString(_keyPhone) ?? '',
      'activePackage': prefs.getString(_keyActivePackage) ?? '',
      'boundDeviceId': prefs.getString(_keyBoundDeviceId) ?? '',
    };
  }
}
