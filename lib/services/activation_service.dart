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
  expired,
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
  /// Verify and upgrade student account directly using the `students` table
  static Future<ActivationResult> activateCode({
    required String code,
    required String name,
    required String phone,
    String? languageCode = 'en',
  }) async {
    final bool isAmharic = languageCode == 'am';
    final cleanCode = code.trim().toUpperCase().replaceAll(' ', '');
    final cleanName = name.trim();
    final cleanPhone = SubscriptionService.sanitizeEthiopianPhone(phone);

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

      // Primary verification: Check `students` record directly
      final res = await supabase
          .from('students')
          .select('full_name, phone_number, grade, device_id, unlocked_packages, subscription_status, subscription_expires_at, is_active')
          .eq('phone_number', cleanPhone)
          .maybeSingle();

      if (res == null) {
        return ActivationResult(
          status: ActivationStatus.invalidCode,
          isSuccess: false,
          message: isAmharic
              ? 'በዚህ ስልክ ቁጥር የተመዘገበ ተማሪ አልተገኘም። እባክዎ በአስተዳዳሪው በኩል መመዝገብዎን ያረጋግጡ።'
              : 'No registered student found for this phone number. Please contact admin (@smart_x_help).',
        );
      }

      final bool isActive = res['is_active'] as bool? ?? true;
      if (!isActive) {
        return ActivationResult(
          status: ActivationStatus.invalidCode,
          isSuccess: false,
          message: isAmharic
              ? 'ይህ መለያ በአስተዳዳሪው ታግዷል።'
              : 'This account is currently suspended.',
        );
      }

      // Check Expiration
      if (res['subscription_expires_at'] != null) {
        final expiresAt = DateTime.tryParse(res['subscription_expires_at'].toString());
        if (expiresAt != null && DateTime.now().toUtc().isAfter(expiresAt.toUtc())) {
          return ActivationResult(
            status: ActivationStatus.expired,
            isSuccess: false,
            message: isAmharic
                ? 'የደንበኝነት ምዝገባዎ ጊዜ አልቋል። እባክዎ ፈቃድዎን ያድሱ።'
                : 'Subscription has expired. Please renew with admin.',
          );
        }
      }

      final String? boundDev = (res['device_id'] as String?)?.trim();
      if (boundDev != null && boundDev.isNotEmpty && boundDev != currentDeviceId) {
        return ActivationResult(
          status: ActivationStatus.alreadyUsedDifferentDevice,
          isSuccess: false,
          message: isAmharic
              ? 'ይህ ስልክ ቁጥር ቀደም ሲል በሌላ ሞባይል ስልክ ላይ ተመዝግቧል! የደህንነት ስርዓቱ 1 አካውንት ለአንድ ስልክ ብቻ ይፈቅዳል (Single-Device Protection)።'
              : 'This account is already registered on another device. Single-device protection enforced.',
        );
      }

      // Auto-bind device
      final nowIso = DateTime.now().toUtc().toIso8601String();
      await supabase.from('students').update({
        'device_id': currentDeviceId,
        'full_name': cleanName,
        'updated_at': nowIso,
      }).eq('phone_number', cleanPhone);

      final int grade = (res['grade'] as num?)?.toInt() ?? 12;
      final List<dynamic>? rawPkgs = res['unlocked_packages'] as List<dynamic>?;
      final List<String> pkgs = rawPkgs != null
          ? rawPkgs.map((e) => e.toString()).toList()
          : <String>['pkg_grade_$grade'];

      await _applyActivationLocally(
        name: cleanName,
        phone: cleanPhone,
        packageId: pkgs.isNotEmpty ? pkgs.first : 'pkg_grade_$grade',
        grade: grade,
        packages: pkgs,
        deviceId: currentDeviceId,
      );

      final readablePkg = _getHumanReadablePackageName(grade, null, pkgs.isNotEmpty ? pkgs.first : '', isAmharic);

      return ActivationResult(
        status: ActivationStatus.success,
        isSuccess: true,
        packageId: pkgs.isNotEmpty ? pkgs.first : 'pkg_grade_$grade',
        grade: grade,
        packageName: readablePkg,
        message: isAmharic
            ? 'እንኳን ደስ አለዎት! $readablePkg በዚህ ስልክ ላይ በተሳካ ሁኔታ ተከፍቷል!'
            : 'Congratulations! $readablePkg has been unlocked on this device.',
      );
    } catch (e) {
      debugPrint('[ActivationService] Activation error: $e');
      return ActivationResult(
        status: ActivationStatus.networkError,
        isSuccess: false,
        message: isAmharic
            ? 'የኢንተርኔት ግንኙነት ችግር አጋጥሟል። እባክዎ ግንኙነትዎን ፈትሸው እንደገና ይሞክሩ።'
            : 'Network error. Please check your internet connection and try again.',
      );
    }
  }

  /// Internal helper to store unlock state locally
  static Future<void> _applyActivationLocally({
    required String name,
    required String phone,
    required String packageId,
    required int grade,
    required List<String> packages,
    required String deviceId,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Store user identity
    await prefs.setString('user_fullName', name);
    await prefs.setString('user_name', name);
    await prefs.setString('user_phoneNumber', phone);
    await prefs.setString('phone_number', phone);
    await prefs.setInt('user_grade', grade);
    await prefs.setBool('is_registered', true);
    await prefs.setBool('is_authenticated', true);

    // Apply strict hardware binding fingerprint
    await DeviceService.bindDeviceToSubscription(phone, packageId);

    // Unlock in SubscriptionService
    await SubscriptionService.setUnlockedPackages(packages);
  }

  /// Helper to get user-friendly package title
  static String _getHumanReadablePackageName(
    int grade,
    String? subject,
    String packageId,
    bool isAmharic,
  ) {
    if (packageId.contains('all_inclusive') || packageId.contains('all_grades')) {
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
