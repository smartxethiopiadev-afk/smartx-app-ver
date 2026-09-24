import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'device_service.dart';
import 'subscription_service.dart';

enum ActivationStatus {
  success,
  invalidCode,
  alreadyUsedDifferentDevice,
  alreadyUsedSameDevice,
  missingInfo,
  networkError,
}

class ActivationResult {
  final ActivationStatus status;
  final bool isSuccess;
  final String message;
  final String? packageId;
  final int? grade;
  final String? subject;
  final String? packageName;

  const ActivationResult({
    required this.status,
    required this.isSuccess,
    required this.message,
    this.packageId,
    this.grade,
    this.subject,
    this.packageName,
  });
}

class ActivationService {
  /// Verify and activate a package-specific activation code
  static Future<ActivationResult> activateCode({
    required String code,
    required String name,
    required String phone,
    String? languageCode = 'en',
  }) async {
    final bool isAmharic = languageCode == 'am';
    final cleanCode = code.trim().toUpperCase().replaceAll(' ', '');
    final cleanName = name.trim();
    final cleanPhone = phone.replaceAll(RegExp(r'\s+'), '').trim();

    if (cleanCode.isEmpty) {
      return ActivationResult(
        status: ActivationStatus.missingInfo,
        isSuccess: false,
        message: isAmharic
            ? 'እባክዎ የማግበሪያ ኮዱን ያስገቡ።'
            : 'Please enter a valid activation code.',
      );
    }

    if (cleanName.isEmpty) {
      return ActivationResult(
        status: ActivationStatus.missingInfo,
        isSuccess: false,
        message: isAmharic
            ? 'እባክዎ የተማሪውን ሙሉ ስም ያስገቡ።'
            : 'Please enter student full name.',
      );
    }

    if (cleanPhone.isEmpty || cleanPhone.length < 9) {
      return ActivationResult(
        status: ActivationStatus.missingInfo,
        isSuccess: false,
        message: isAmharic
            ? 'እባክዎ ትክክለኛ ስልክ ቁጥር ያስገቡ።'
            : 'Please enter a valid phone number.',
      );
    }

    final currentDeviceId = await DeviceService.getDeviceId();

    try {
      final supabase = Supabase.instance.client;

      // Primary Flow: Call atomic PostgreSQL RPC function redeem_activation_code
      try {
        final rpcResult = await supabase.rpc('redeem_activation_code', params: {
          'p_code': cleanCode,
          'p_phone': cleanPhone,
          'p_name': cleanName,
          'p_device_id': currentDeviceId,
        });

        if (rpcResult is Map) {
          final bool success = rpcResult['success'] == true;
          final String? rpcMsg = rpcResult['message'] as String?;
          final String? rpcError = rpcResult['error'] as String?;
          final String? packageId = rpcResult['package_id'] as String?;
          final int grade = (rpcResult['grade'] as num?)?.toInt() ?? 12;
          final String? subject = rpcResult['subject'] as String?;

          if (success && packageId != null) {
            await _applyActivationLocally(
              name: cleanName,
              phone: cleanPhone,
              packageId: packageId,
              grade: grade,
              subject: subject,
              deviceId: currentDeviceId,
            );

            final readablePkg = _getHumanReadablePackageName(grade, subject, packageId, isAmharic);
            return ActivationResult(
              status: ActivationStatus.success,
              isSuccess: true,
              packageId: packageId,
              grade: grade,
              subject: subject,
              packageName: readablePkg,
              message: rpcMsg ?? (isAmharic
                  ? 'እንኳን ደስ አለዎት! $readablePkg በተሳካ ሁኔታ ተከፍቷል!'
                  : 'Congratulations! $readablePkg has been unlocked and bound to this device.'),
            );
          } else if (rpcError != null) {
            if (rpcError.contains('different device') || rpcError.contains('already used')) {
              return ActivationResult(
                status: ActivationStatus.alreadyUsedDifferentDevice,
                isSuccess: false,
                message: isAmharic
                    ? 'ይህ የማግበሪያ ኮድ በሌላ ስልክ ላይ አገልግሎት ላይ ውሏል። የደህንነት ስርዓቱ አንድን ኮድ ለአንድ ስልክ ብቻ ይፈቅዳል!'
                    : 'This activation code has already been redeemed on another device. Codes are strictly single-device bound.',
              );
            } else if (rpcError.contains('Invalid activation code')) {
              return ActivationResult(
                status: ActivationStatus.invalidCode,
                isSuccess: false,
                message: isAmharic
                    ? 'የተሳሳተ የማግበሪያ ኮድ። እባክዎ በትክክል መጻፍዎን ያረጋግጡና እንደገና ይሞክሩ።'
                    : 'Invalid activation code. Please double-check your code and try again.',
              );
            }
          }
        }
      } catch (rpcErr) {
        debugPrint('[ActivationService] RPC fallback notice: $rpcErr');
      }

      // Fallback Direct Supabase Flow
      // 1. Query the activation_codes table
      final response = await supabase
          .from('activation_codes')
          .select()
          .eq('code', cleanCode)
          .maybeSingle();

      if (response == null) {
        return ActivationResult(
          status: ActivationStatus.invalidCode,
          isSuccess: false,
          message: isAmharic
              ? 'የተሳሳተ የማግበሪያ ኮድ። እባክዎ በትክክል መጻፍዎን ያረጋግጡና እንደገና ይሞክሩ።'
              : 'Invalid activation code. Please double-check your code and try again.',
        );
      }

      final String packageId = response['package_id'] as String? ?? 'pkg_grade_12';
      final int grade = response['grade'] as int? ?? 12;
      final String? subject = response['subject'] as String?;
      final bool isUsed = response['is_used'] as bool? ?? false;
      final String? usedByPhone = response['used_by_phone'] as String?;
      final String? usedByDevice = response['used_by_device'] as String?;

      // 2. Strict Anti-Piracy / Single-Device Binding check
      if (isUsed) {
        final bool sameDevice = usedByDevice != null &&
            usedByDevice.isNotEmpty &&
            usedByDevice == currentDeviceId;
        final bool samePhone = usedByPhone != null &&
            usedByPhone.isNotEmpty &&
            usedByPhone.replaceAll(RegExp(r'\s+'), '') == cleanPhone;

        if (sameDevice || samePhone) {
          // Re-activation on the same verified device
          await _applyActivationLocally(
            name: cleanName,
            phone: cleanPhone,
            packageId: packageId,
            grade: grade,
            subject: subject,
            deviceId: currentDeviceId,
          );

          final readablePkg = _getHumanReadablePackageName(grade, subject, packageId, isAmharic);

          return ActivationResult(
            status: ActivationStatus.alreadyUsedSameDevice,
            isSuccess: true,
            packageId: packageId,
            grade: grade,
            subject: subject,
            packageName: readablePkg,
            message: isAmharic
                ? 'ይህ ኮድ ቀደም ሲል ለዚህ ስልክ የተከፈተ ነው። ፓኬጁ በተሳካ ሁኔታ ታድሷል!'
                : 'This activation code is already bound to this device. Access restored successfully!',
          );
        } else {
          // Used on a different device / phone - Anti-Account Sharing rule
          return ActivationResult(
            status: ActivationStatus.alreadyUsedDifferentDevice,
            isSuccess: false,
            message: isAmharic
                ? 'ይህ የማግበሪያ ኮድ በሌላ ስልክ ላይ አገልግሎት ላይ ውሏል። የደህንነት ስርዓቱ አንድን ኮድ ለአንድ ስልክ ብቻ ይፈቅዳል!'
                : 'This activation code has already been redeemed on another device. In accordance with Smart Learn Ethiopian anti-piracy policy, codes are strictly single-device bound.',
          );
        }
      }

      final nowIso = DateTime.now().toUtc().toIso8601String();

      // 3. Mark code as used in Supabase
      await supabase.from('activation_codes').update({
        'is_used': true,
        'used_by_phone': cleanPhone,
        'used_by_device': currentDeviceId,
        'used_at': nowIso,
      }).eq('code', cleanCode);

      // 4. Update students table with unlocked_packages and device binding
      try {
        final existingStudent = await supabase
            .from('students')
            .select('unlocked_packages')
            .eq('phone_number', cleanPhone)
            .maybeSingle();

        List<String> pkgs = [];
        if (existingStudent != null && existingStudent['unlocked_packages'] != null) {
          pkgs = (existingStudent['unlocked_packages'] as List<dynamic>).map((e) => e.toString()).toList();
        }
        if (!pkgs.contains(packageId)) {
          pkgs.add(packageId);
        }
        if (subject != null && subject.trim().isNotEmpty) {
          final slug = SubscriptionService.normalizeSubjectSlug(subject);
          final subjectPkg = 'pkg_g${grade}_$slug';
          if (!pkgs.contains(subjectPkg)) pkgs.add(subjectPkg);
        } else {
          final gradePkg = 'pkg_grade_$grade';
          if (!pkgs.contains(gradePkg)) pkgs.add(gradePkg);
        }

        await supabase.from('students').upsert({
          'phone_number': cleanPhone,
          'full_name': cleanName,
          'grade': grade,
          'device_id': currentDeviceId,
          'is_active': true,
          'subscription_status': 'active',
          'unlocked_packages': pkgs,
          'updated_at': nowIso,
        }, onConflict: 'phone_number');
      } catch (e) {
        debugPrint('[ActivationService] Student table update notice: $e');
      }

      // 5. Record active subscription in user_subscriptions table
      try {
        await supabase.from('user_subscriptions').upsert({
          'phone_number': cleanPhone,
          'package_id': packageId,
          'device_id': currentDeviceId,
          'is_active': true,
          'activated_at': nowIso,
        });
      } catch (e) {
        debugPrint('[ActivationService] Upsert subscription notice: $e');
      }

      // 6. Apply local unlock and device binding
      await _applyActivationLocally(
        name: cleanName,
        phone: cleanPhone,
        packageId: packageId,
        grade: grade,
        subject: subject,
        deviceId: currentDeviceId,
      );

      final readablePkg = _getHumanReadablePackageName(grade, subject, packageId, isAmharic);

      return ActivationResult(
        status: ActivationStatus.success,
        isSuccess: true,
        packageId: packageId,
        grade: grade,
        subject: subject,
        packageName: readablePkg,
        message: isAmharic
            ? 'እንኳን ደስ አለዎት! $readablePkg በተሳካ ሁኔታ ተከፍቷል!'
            : 'Congratulations! $readablePkg has been unlocked and bound to this device.',
      );
    } catch (e) {
      debugPrint('[ActivationService] Activation error: $e');
      return ActivationResult(
        status: ActivationStatus.networkError,
        isSuccess: false,
        message: isAmharic
            ? 'የኢንተርኔት ግንኙነት ችግር አጋጥሟል። እባክዎ ግንኙነትዎን ፈትሸው እንደገና ይሞክሩ።'
            : 'Network error connecting to activation server. Please check your internet connection and try again.',
      );
    }
  }

  /// Internal helper to store unlock state locally
  static Future<void> _applyActivationLocally({
    required String name,
    required String phone,
    required String packageId,
    required int grade,
    String? subject,
    required String deviceId,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Store user identity
    await prefs.setString('user_fullName', name);
    await prefs.setString('user_name', name);
    await prefs.setString('user_phoneNumber', phone);
    await prefs.setString('phone_number', phone);
    await prefs.setBool('is_registered', true);

    // Apply strict hardware binding fingerprint
    await DeviceService.bindDeviceToSubscription(phone, packageId);

    // Unlock in SubscriptionService
    await SubscriptionService.unlockPackage(packageId);

    if (subject != null && subject.trim().isNotEmpty) {
      final String slug = subject.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
      await SubscriptionService.unlockPackage('pkg_g${grade}_$slug');
    } else {
      // Full grade package unlocked
      await SubscriptionService.unlockPackage('pkg_grade_$grade');
      await SubscriptionService.unlockGrade(grade);
    }
  }

  /// Helper to get user-friendly package title
  static String _getHumanReadablePackageName(
    int grade,
    String? subject,
    String packageId,
    bool isAmharic,
  ) {
    if (packageId.contains('all_inclusive')) {
      return isAmharic
          ? 'ክፍል $grade የዩኒቨርሲቲ መግቢያ (Matric) የተሟላ ፓኬጅ'
          : 'Grade $grade All-Inclusive Matric Prep Kit';
    }
    if (subject != null && subject.isNotEmpty) {
      return isAmharic
          ? 'ክፍል $grade $subject ብቻ ፓኬጅ'
          : 'Grade $grade $subject Single Subject Pack';
    }
    return isAmharic
        ? 'ክፍል $grade የሁሉም ትምህርቶች ፓኬጅ'
        : 'Grade $grade All-Subjects Package';
  }
}
