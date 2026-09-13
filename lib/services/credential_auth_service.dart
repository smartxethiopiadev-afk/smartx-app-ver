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

      // 1. Query student_credentials table
      final response = await supabase
          .from('student_credentials')
          .select('id, full_name, phone_number, password, package_id, device_id, is_active')
          .eq('phone_number', cleanPhone)
          .maybeSingle();

      if (response == null) {
        return const CredentialAuthResult(
          status: CredentialAuthStatus.invalidCredentials,
          message: 'No student account found with this phone number. Please check credentials or contact admin.',
        );
      }

      final String dbPassword = response['password'] as String? ?? '';
      if (dbPassword != cleanPass) {
        return const CredentialAuthResult(
          status: CredentialAuthStatus.invalidCredentials,
          message: 'Incorrect password. Please verify the password provided by admin.',
        );
      }

      final bool isActive = response['is_active'] as bool? ?? false;
      if (!isActive) {
        return const CredentialAuthResult(
          status: CredentialAuthStatus.inactiveAccount,
          message: 'This account is currently deactivated. Please contact admin.',
        );
      }

      final String? registeredDeviceId = response['device_id'] as String?;
      final String packageId = response['package_id'] as String? ?? 'pkg_grade_$grade';
      final String studentName = response['full_name'] as String? ?? cleanName;

      // 2. Single-Device Binding Enforcement
      if (registeredDeviceId == null || registeredDeviceId.trim().isEmpty) {
        // First login: Lock account to current hardware device ID
        await supabase
            .from('student_credentials')
            .update({'device_id': currentDeviceId})
            .eq('phone_number', cleanPhone);

        debugPrint('[CredentialAuthService] Bound device $currentDeviceId to account $cleanPhone');
      } else if (registeredDeviceId != currentDeviceId) {
        // Anti-Account Sharing: Device Mismatch
        return CredentialAuthResult(
          status: CredentialAuthStatus.deviceMismatchLocked,
          message: 'This account is already registered on another phone ($registeredDeviceId). Account sharing is strictly restricted.',
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

      // 4. Unlock the package locally via SubscriptionService
      await SubscriptionService.unlockPackage(packageId);
      await SubscriptionService.unlockPackage('pkg_grade_$grade');
      if (subject != null && subject.isNotEmpty) {
        final slug = subject.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
        await SubscriptionService.unlockPackage('pkg_g${grade}_$slug');
      }

      return CredentialAuthResult(
        status: CredentialAuthStatus.success,
        message: 'Login successful! Lifetime access unlocked on this device.',
        packageId: packageId,
        studentName: studentName,
        phoneNumber: cleanPhone,
      );
    } catch (e) {
      debugPrint('[CredentialAuthService] Online verification failed: $e');

      // Offline fallback: Check if this user previously logged in on this exact device
      final prefs = await SharedPreferences.getInstance();
      final bool wasAuth = prefs.getBool(_keyIsAuth) ?? false;
      final String? savedPhone = prefs.getString(_keyPhone);
      final String? savedBoundDevice = prefs.getString(_keyBoundDeviceId);

      if (wasAuth && savedPhone == cleanPhone && savedBoundDevice == currentDeviceId) {
        return CredentialAuthResult(
          status: CredentialAuthStatus.success,
          message: 'Offline session validated on your registered device.',
          packageId: prefs.getString(_keyActivePackage) ?? 'pkg_grade_$grade',
          studentName: prefs.getString(_keyFullName) ?? cleanName,
          phoneNumber: cleanPhone,
        );
      }

      return CredentialAuthResult(
        status: CredentialAuthStatus.networkError,
        message: 'Could not connect to verification server. Please check your internet connection and try again: $e',
      );
    }
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
}
