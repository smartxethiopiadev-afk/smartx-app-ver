import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum DeviceBindingStatus {
  granted,
  boundSuccessfully,
  mismatch,
  noSubscription,
  inactive,
  expired,
  offlineTampered,
  networkError,
}

class DeviceBindingResult {
  final DeviceBindingStatus status;
  final String? message;
  final String? registeredDeviceId;
  final String currentDeviceId;

  const DeviceBindingResult({
    required this.status,
    required this.currentDeviceId,
    this.message,
    this.registeredDeviceId,
  });

  bool get isAllowed =>
      status == DeviceBindingStatus.granted ||
      status == DeviceBindingStatus.boundSuccessfully;
}

class DeviceService {
  static const String _localDeviceIdKey = 'smartx_hardware_device_id';
  static const String _verifiedBindingKey = 'smartx_verified_device_binding';
  static String? _cachedDeviceId;

  /// Binds the current device to the student's profile in the `students` table
  static Future<void> bindDeviceToSubscription(String phoneNumber, String packageId) async {
    try {
      final String currentDeviceId = await getDeviceId();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_verifiedBindingKey, currentDeviceId);

      final supabase = Supabase.instance.client;
      final cleanPhone = phoneNumber.replaceAll(RegExp(r'\s+'), '').trim();

      await supabase
          .from('students')
          .update({
            'device_id': currentDeviceId,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('phone_number', cleanPhone);
    } catch (e) {
      debugPrint('[DeviceService] bindDeviceToSubscription notice: $e');
    }
  }

  /// Gets a persistent hardware fingerprint for the device.
  /// On Android, extracts unique Android ID / hardware ID.
  /// On Web/Fallback, stores a unique hardware GUID in local persistent storage.
  static Future<String> getDeviceId() async {
    if (_cachedDeviceId != null && _cachedDeviceId!.isNotEmpty) {
      return _cachedDeviceId!;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      String? savedId = prefs.getString(_localDeviceIdKey);

      final deviceInfo = DeviceInfoPlugin();

      if (!kIsWeb && Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        final String rawId = androidInfo.id.isNotEmpty
            ? androidInfo.id
            : (androidInfo.fingerprint.isNotEmpty
                ? androidInfo.fingerprint
                : '${androidInfo.manufacturer}_${androidInfo.model}_${androidInfo.hardware}');
        
        final cleanId = 'AND_${rawId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '').toUpperCase()}';
        final formattedId = cleanId.length > 32 ? cleanId.substring(0, 32) : cleanId;
        _cachedDeviceId = formattedId;
        await prefs.setString(_localDeviceIdKey, formattedId);
        return formattedId;
      } else if (!kIsWeb && Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        final String rawId = iosInfo.identifierForVendor ?? 'IOS_${iosInfo.name}_${iosInfo.model}';
        final cleanId = 'IOS_${rawId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '').toUpperCase()}';
        final formattedId = cleanId.length > 32 ? cleanId.substring(0, 32) : cleanId;
        _cachedDeviceId = formattedId;
        await prefs.setString(_localDeviceIdKey, formattedId);
        return formattedId;
      } else {
        // Fallback for Web/Desktop/Emulators
        if (savedId != null && savedId.isNotEmpty) {
          _cachedDeviceId = savedId;
          return savedId;
        }
        final String generatedId = 'DEV_${DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase()}_${(1000 + (DateTime.now().microsecond % 9000))}';
        _cachedDeviceId = generatedId;
        await prefs.setString(_localDeviceIdKey, generatedId);
        return generatedId;
      }
    } catch (e) {
      debugPrint('[DeviceService] Error generating device ID: $e');
      final prefs = await SharedPreferences.getInstance();
      final String fallback = prefs.getString(_localDeviceIdKey) ?? 'DEV_SMARTX_${DateTime.now().millisecondsSinceEpoch}';
      _cachedDeviceId = fallback;
      await prefs.setString(_localDeviceIdKey, fallback);
      return fallback;
    }
  }

  /// Verifies if the local device has permission to access offline encrypted/downloaded content.
  /// Protects against cloning / moving app data folder to another phone.
  static Future<bool> verifyOfflineTamperIntegrity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? boundDeviceId = prefs.getString(_verifiedBindingKey);
      
      // If no bound device yet (e.g. fresh install / Unit 1 free), pass integrity
      if (boundDeviceId == null || boundDeviceId.isEmpty) {
        return true;
      }

      final String currentDeviceId = await getDeviceId();
      if (boundDeviceId != currentDeviceId) {
        debugPrint('[DeviceService] Anti-Piracy Tamper Alert: Current device $currentDeviceId does not match bound device $boundDeviceId');
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('[DeviceService] Offline integrity check error: $e');
      return true;
    }
  }

  /// Strict Single-Device Binding check against Supabase `students` table
  static Future<DeviceBindingResult> verifyAndBindSubscription({
    required String phoneNumber,
    required String packageId,
  }) async {
    final String currentDeviceId = await getDeviceId();
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\s+'), '').trim();

    if (cleanPhone.isEmpty) {
      return DeviceBindingResult(
        status: DeviceBindingStatus.noSubscription,
        currentDeviceId: currentDeviceId,
        message: 'Please enter a valid phone number.',
      );
    }

    try {
      final supabase = Supabase.instance.client;

      // Query students table directly
      final targetRecord = await supabase
          .from('students')
          .select('id, full_name, phone_number, grade, device_id, unlocked_packages, subscription_status, subscription_expires_at, is_active')
          .eq('phone_number', cleanPhone)
          .maybeSingle();

      if (targetRecord == null) {
        return DeviceBindingResult(
          status: DeviceBindingStatus.noSubscription,
          currentDeviceId: currentDeviceId,
          message: 'No student record found for $cleanPhone. Please register first.',
        );
      }

      final bool isActive = targetRecord['is_active'] as bool? ?? true;
      if (!isActive) {
        return DeviceBindingResult(
          status: DeviceBindingStatus.inactive,
          currentDeviceId: currentDeviceId,
          message: 'This account is currently inactive. Please contact admin (@smart_x_help).',
        );
      }

      // Check Expiration timestamp
      if (targetRecord['subscription_expires_at'] != null) {
        final expiresAt = DateTime.tryParse(targetRecord['subscription_expires_at'].toString());
        if (expiresAt != null && DateTime.now().toUtc().isAfter(expiresAt.toUtc())) {
          return DeviceBindingResult(
            status: DeviceBindingStatus.expired,
            currentDeviceId: currentDeviceId,
            message: 'የደንበኝነት ምዝገባዎ ጊዜ አልቋል። እባክዎ ያድሱ። / Subscription has expired.',
          );
        }
      }

      final String? registeredDeviceId = (targetRecord['device_id'] as String?)?.trim();

      // Scenario A: First time activation OR Admin Reset (device_id is null or empty)
      if (registeredDeviceId == null || registeredDeviceId.isEmpty) {
        await supabase
            .from('students')
            .update({
              'device_id': currentDeviceId,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('phone_number', cleanPhone);

        // Save local verification
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_verifiedBindingKey, currentDeviceId);
        await prefs.setString('user_phoneNumber', cleanPhone);

        return DeviceBindingResult(
          status: DeviceBindingStatus.boundSuccessfully,
          currentDeviceId: currentDeviceId,
          registeredDeviceId: currentDeviceId,
          message: 'Device successfully registered and bound to this account.',
        );
      }

      // Scenario B: Device IDs match -> Access Granted
      if (registeredDeviceId == currentDeviceId) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_verifiedBindingKey, currentDeviceId);
        await prefs.setString('user_phoneNumber', cleanPhone);

        return DeviceBindingResult(
          status: DeviceBindingStatus.granted,
          currentDeviceId: currentDeviceId,
          registeredDeviceId: registeredDeviceId,
          message: 'Device verified successfully.',
        );
      }

      // Scenario C: Device IDs MISMATCH -> Access Blocked! (Account Sharing Detected)
      return DeviceBindingResult(
        status: DeviceBindingStatus.mismatch,
        currentDeviceId: currentDeviceId,
        registeredDeviceId: registeredDeviceId,
        message: 'ይህ አካውንት በሌላ ስልክ ($registeredDeviceId) ላይ ተመዝግቧል። የደህንነት ስርዓቱ 1 አካውንት ለአንድ ስልክ ብቻ ይፈቅዳል።',
      );
    } catch (e) {
      debugPrint('[DeviceService] Subscription verification error: $e');
      return DeviceBindingResult(
        status: DeviceBindingStatus.networkError,
        currentDeviceId: currentDeviceId,
        message: 'Network error while verifying device binding: $e',
      );
    }
  }

  /// Unbinds/clears the local device binding (e.g. on logout or app reset)
  static Future<void> clearLocalBinding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_verifiedBindingKey);
  }
}
