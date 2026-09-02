import 'dart:io';
import 'package:flutter/foundation.dart';

class AdHelper {
  /// Returns the AdMob Banner Unit ID for Android and iOS.
  static String get bannerAdUnitId {
    if (kIsWeb) return '';
    if (Platform.isAndroid) {
      return 'ca-app-pub-3033531181358996/6349966054';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716';
    } else {
      return '';
    }
  }

  /// Returns the AdMob Interstitial Unit ID for Android and iOS.
  static String get interstitialAdUnitId {
    if (kIsWeb) return '';
    if (Platform.isAndroid) {
      return 'ca-app-pub-3033531181358996/7735094719';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/4411468910';
    } else {
      return '';
    }
  }

  /// Returns the AdMob Rewarded Video Unit ID for Android and iOS.
  static String get rewardedAdUnitId {
    if (kIsWeb) return '';
    if (Platform.isAndroid) {
      return 'ca-app-pub-3033531181358996/6801286996';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/1712485313';
    } else {
      return '';
    }
  }
}
