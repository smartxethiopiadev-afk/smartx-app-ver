import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Helper utility for Google Mobile Ads (AdMob) configuration and safe lifecycle handling.
class AdHelper {
  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized;

  /// Initializes the Google Mobile Ads SDK safely with standard test configuration.
  static Future<void> initialize() async {
    if (kIsWeb) return;
    try {
      final status = await MobileAds.instance.initialize().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('[AdHelper] AdMob initialization timed out; continuing in safe mode.');
          return InitializationStatus({});
        },
      );
      _isInitialized = true;
      debugPrint('[AdHelper] AdMob initialized successfully: ${status.adapterStatuses}');
    } catch (e, stack) {
      debugPrint('[AdHelper] AdMob initialization warning: $e\n$stack');
    }
  }

  /// AdMob Banner Ad Unit ID (Defaults to Google official test IDs for safe verification)
  static String get bannerAdUnitId {
    if (kIsWeb) return '';
    if (Platform.isAndroid) {
      // Android Sample Banner Ad Unit ID
      return 'ca-app-pub-3940256099942544/6300978111';
    } else if (Platform.isIOS) {
      // iOS Sample Banner Ad Unit ID
      return 'ca-app-pub-3940256099942544/2934735716';
    } else {
      return '';
    }
  }

  /// AdMob Interstitial Ad Unit ID
  static String get interstitialAdUnitId {
    if (kIsWeb) return '';
    if (Platform.isAndroid) {
      // Android Sample Interstitial Ad Unit ID
      return 'ca-app-pub-3940256099942544/1033173712';
    } else if (Platform.isIOS) {
      // iOS Sample Interstitial Ad Unit ID
      return 'ca-app-pub-3940256099942544/4411468910';
    } else {
      return '';
    }
  }

  /// AdMob Rewarded Video Ad Unit ID
  static String get rewardedAdUnitId {
    if (kIsWeb) return '';
    if (Platform.isAndroid) {
      // Android Sample Rewarded Ad Unit ID
      return 'ca-app-pub-3940256099942544/5224354917';
    } else if (Platform.isIOS) {
      // iOS Sample Rewarded Ad Unit ID
      return 'ca-app-pub-3940256099942544/1712485313';
    } else {
      return '';
    }
  }

  /// Translates AdMob error codes into clear developer messages.
  static String getErrorMessage(int errorCode) {
    switch (errorCode) {
      case 0:
        return 'Internal Error (Code 0): Something happened internally; perhaps invalid App ID or unverified account.';
      case 1:
        return 'Invalid Request (Code 1): The ad unit ID may be incorrect or missing.';
      case 2:
        return 'Network Error (Code 2): The device is offline or has slow internet connectivity.';
      case 3:
        return 'No Fill (Code 3): Google AdMob currently has no inventory available for this ad unit.';
      default:
        return 'Ad load error (Code $errorCode).';
    }
  }
}
