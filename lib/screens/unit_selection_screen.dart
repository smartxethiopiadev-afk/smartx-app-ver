import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/ad_helper.dart';
import '../services/offline_manager.dart';
import '../services/pdf_cache_service.dart';
import '../services/quiz_service.dart';
import '../main.dart';
import 'quiz_screen.dart';
import 'registration_overlay.dart';
import 'notes_screen.dart';

class UnitSelectionScreen extends StatefulWidget {
  final int grade;
  final String subjectId;
  final String enTitle;
  final String amTitle;
  final Color color;
  final Widget icon;
  final bool isDarkMode;
  final String languageCode;
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleLanguage;
  final bool isShortNotesMode;

  const UnitSelectionScreen({
    super.key,
    required this.grade,
    required this.subjectId,
    required this.enTitle,
    required this.amTitle,
    required this.color,
    required this.icon,
    required this.isDarkMode,
    required this.languageCode,
    required this.onToggleTheme,
    required this.onToggleLanguage,
    this.isShortNotesMode = false,
  });

  @override
  State<UnitSelectionScreen> createState() => _UnitSelectionScreenState();
}

class _UnitSelectionScreenState extends State<UnitSelectionScreen> {
  // Simple in-memory tracker for downloaded units & download progress states
  final Set<String> _downloadedUnits = {};
  final Set<String> _expiredUnits = {};
  final Map<String, double> _downloadProgress = {}; // unitId -> 0.0 to 1.0

  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;
  
  RewardedAd? _rewardedAd;
  bool _isRewardedAdLoaded = false;

  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdLoaded = false;

  bool _isRegistered = false;
  final Map<int, int> _unitBestScores = {};

  bool _showOfflineTipBanner = true;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
    _loadRewardedAd();
    _loadInterstitialAd();
    _loadOfflineDownloads();
    _loadBestScores();
    _checkRegistrationStatus();
    _checkOfflineTipBanner();
  }

  void _checkOfflineTipBanner() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('seen_offline_info_tip') ?? false;
    if (mounted) {
      setState(() {
        _showOfflineTipBanner = !seen;
      });
    }
  }

  void _dismissOfflineTipBanner() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_offline_info_tip', true);
    if (mounted) {
      setState(() {
        _showOfflineTipBanner = false;
      });
    }
  }

  void _checkRegistrationStatus() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
       setState(() {
         _isRegistered = (prefs.getBool('has_registered') ?? false) ||
                         (prefs.getBool('is_authenticated') ?? false);
       });
    }
  }

  Future<void> _checkRegistrationAndProceed(int index, int activeUnitNum, {required VoidCallback onSuccess}) async {
    // Unit 1 is always unlocked and free to use without registration
    if (activeUnitNum <= 1) {
      onSuccess();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final bool hasRegistered = (prefs.getBool('has_registered') ?? false) ||
                               (prefs.getBool('is_authenticated') ?? false);

    if (!hasRegistered) {
      if (!mounted) return;
      await Navigator.of(context).push<String>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => RegistrationOverlay(
            isDarkMode: AppStateProvider.of(context).isDarkMode,
            languageCode: widget.languageCode,
            primaryColor: widget.color,
          ),
        ),
      );

      // Reload SharedPreferences state after overlay closes
      final updatedPrefs = await SharedPreferences.getInstance();
      final bool nowRegistered = (updatedPrefs.getBool('has_registered') ?? false) ||
                                 (updatedPrefs.getBool('is_authenticated') ?? false);
      if (mounted) {
        setState(() {
          _isRegistered = nowRegistered;
        });
      }

      if (nowRegistered) {
        onSuccess();
      } else {
        debugPrint("Registration is required to access Unit $activeUnitNum. Access locked.");
      }
    } else {
      onSuccess();
    }
  }

  void _showUnitOptionsSheet(BuildContext context, int unitNumber, String unitId, String unitTitle, bool isDownloaded) {
    final bool isDarkMode = AppStateProvider.of(context).isDarkMode;
    final bool isLight = !isDarkMode;
    final Color sheetBg = isLight ? Colors.white : const Color(0xFF0F172A);
    final Color headerColor = isLight ? const Color(0xFF0F172A) : Colors.white;
    final Color descColor = isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Material(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    widget.languageCode == 'en' ? "Unit Activities" : "የክፍሉ ተግባራት",
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: headerColor,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.languageCode == 'en' 
                        ? "Choose how you want to study for Unit $unitNumber" 
                        : "ለክፍል $unitNumber የሚፈልጉትን ተግባር ይምረጡ",
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: descColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  

                  // 2. Practice Mode Card
                  InkWell(
                    onTap: () {
                      Navigator.of(ctx).pop();
                      final startQuizAction = () {
                        _showQuizStartDialog(
                          mode: QuizMode.practice,
                          unitNumber: unitNumber,
                          onStart: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => QuizScreen(
                                  grade: widget.grade,
                                  subject: widget.subjectId,
                                  unit: unitNumber,
                                  mode: QuizMode.practice,
                                  isOffline: isDownloaded,
                                  offlineUnitId: isDownloaded ? 'g${widget.grade}_${unitId}_quiz' : null,
                                ),
                              ),
                            ).then((_) {
                              _loadBestScores();
                            });
                          },
                        );
                      };
                      if (isDownloaded) {
                        startQuizAction();
                      } else {
                        _executeWithInterstitialAd(startQuizAction);
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.school_rounded, color: Color(0xFF3B82F6), size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.languageCode == 'en' ? "Practice Mode" : "የልምምድ ዓይነት",
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: headerColor),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.languageCode == 'en' 
                                      ? "Immediate answers and explanations." 
                                      : "ፈጣን መልሶችን እና ማብራሪያዎችን ያግኙ",
                                  style: TextStyle(fontSize: 11.5, color: descColor, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, color: descColor, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // 3. Exam Mode Card
                  InkWell(
                    onTap: () {
                      Navigator.of(ctx).pop();
                      final startQuizAction = () {
                        _showQuizStartDialog(
                          mode: QuizMode.exam,
                          unitNumber: unitNumber,
                          onStart: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => QuizScreen(
                                  grade: widget.grade,
                                  subject: widget.subjectId,
                                  unit: unitNumber,
                                  mode: QuizMode.exam,
                                  isOffline: isDownloaded,
                                  offlineUnitId: isDownloaded ? 'g${widget.grade}_${unitId}_quiz' : null,
                                ),
                              ),
                            ).then((_) {
                              _loadBestScores();
                            });
                          },
                        );
                      };
                      if (isDownloaded) {
                        startQuizAction();
                      } else {
                        _executeWithRewardedAd(startQuizAction);
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.timer_rounded, color: Color(0xFFEF4444), size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.languageCode == 'en' ? "Exam Mode" : "የፈተና ዓይነት",
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: headerColor),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.languageCode == 'en' 
                                      ? "Timed, no instant answers, final score only." 
                                      : "በጊዜ የተገደበ ፈተና ፣ ፈጣን መልስ የሌለው ፣ የመጨረሻ ውጤት ብቻ",
                                  style: TextStyle(fontSize: 11.5, color: descColor, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, color: descColor, size: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showQuizStartDialog({
    required QuizMode mode,
    required int unitNumber,
    required VoidCallback onStart,
  }) {
    final bool isDark = AppStateProvider.of(context).isDarkMode;
    final bool isAmharic = widget.languageCode == 'am';

    final String title = isAmharic ? 'ምዕራፍ $unitNumber ለመጀመር ተዘጋጅተዋል?' : 'Ready to Start Unit $unitNumber?';
    
    final String description = mode == QuizMode.exam
        ? (isAmharic
            ? 'ይህ በጊዜ የተገደበ ፈተና ነው። በሚሰሩበት ጊዜ ፈጣን ምላሽ ወይም ማብራሪያ አያገኙም።'
            : 'This is a timed test. You will not get instant answers or explanations during the exam.')
        : (isAmharic
            ? 'በዚህ የልምምድ ዓይነት ፈጣን ምላሾችን፣ ማብራሪያዎችን እና ዝርዝር መረጃዎችን ያገኛሉ።'
            : 'In Practice Mode, you will get instant feedback, correct answers, and detailed explanations.');

    final String startText = isAmharic ? 'ጀምር' : 'Start Quiz';
    final String cancelText = isAmharic ? 'ተመለስ' : 'Cancel';

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (mode == QuizMode.exam ? const Color(0xFFEF4444) : const Color(0xFF3B82F6)).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      mode == QuizMode.exam ? Icons.timer_rounded : Icons.school_rounded,
                      color: mode == QuizMode.exam ? const Color(0xFFEF4444) : const Color(0xFF3B82F6),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Text(
                        cancelText,
                        style: TextStyle(
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        onStart();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        startText,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _hasInternet() async {
    if (kIsWeb) return true;
    try {
      final result = await InternetAddress.lookup('google.com').timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void _showAdLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent user from dismissing it manually
      builder: (BuildContext context) {
        final isDark = AppStateProvider.of(context).isDarkMode;
        return PopScope(
          canPop: false, // Prevent back button from dismissing
          child: AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    widget.languageCode == 'en' ? 'Loading ad...' : 'ማስታወቂያ በመጫን ላይ...',
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _executeWithInterstitialAd(VoidCallback action) async {
    try {
      final bool hasConn = await _hasInternet();
      if (!hasConn) {
        action();
        return;
      }

      // Show loading dialog immediately
      _showAdLoadingDialog(context);

      bool dialogClosed = false;
      Timer? timeoutTimer;

      // Helper to close dialog and perform action
      void closeDialogAndProceed() {
        if (!dialogClosed) {
          dialogClosed = true;
          timeoutTimer?.cancel();
          Navigator.of(context, rootNavigator: true).pop(); // Close spinner
          action();
        }
      }

      // If an interstitial ad is ALREADY loaded, show it immediately
      if (_isInterstitialAdLoaded && _interstitialAd != null) {
        _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
          onAdDismissedFullScreenContent: (ad) {
            ad.dispose();
            _loadInterstitialAd();
            closeDialogAndProceed();
          },
          onAdFailedToShowFullScreenContent: (ad, err) {
            ad.dispose();
            _loadInterstitialAd();
            closeDialogAndProceed();
          },
        );
        _interstitialAd!.show();
        _interstitialAd = null;
        _isInterstitialAdLoaded = false;
        return;
      }

      // Otherwise, actively load a new ad and wait up to 5 seconds
      timeoutTimer = Timer(const Duration(seconds: 5), () {
        debugPrint("Interstitial ad load timed out after 5 seconds");
        closeDialogAndProceed();
      });

      InterstitialAd.load(
        adUnitId: AdHelper.interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            if (dialogClosed) {
              ad.dispose();
              return;
            }
            timeoutTimer?.cancel();
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (dismissedAd) {
                dismissedAd.dispose();
                _loadInterstitialAd(); // Cache the next one
                closeDialogAndProceed();
              },
              onAdFailedToShowFullScreenContent: (failedAd, err) {
                failedAd.dispose();
                _loadInterstitialAd();
                closeDialogAndProceed();
              },
            );
            dialogClosed = true;
            Navigator.of(context, rootNavigator: true).pop();
            ad.show();
          },
          onAdFailedToLoad: (err) {
            debugPrint("Interstitial ad failed to load within timeout: $err");
            closeDialogAndProceed();
          },
        ),
      );
    } catch (e) {
      debugPrint("Error in interstitial ad: $e");
      action();
    }
  }

  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: AdHelper.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _loadRewardedAd();
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              ad.dispose();
              _loadRewardedAd();
            },
          );
          _rewardedAd = ad;
          _isRewardedAdLoaded = true;
        },
        onAdFailedToLoad: (err) {
          debugPrint('Failed to load a rewarded ad: ${err.message}');
          _isRewardedAdLoaded = false;
        },
      ),
    );
  }

  void _executeWithRewardedAd(VoidCallback action) async {
    final bool hasConn = await _hasInternet();
    if (!hasConn) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext dialogContext) {
            final isLight = !AppStateProvider.of(context).isDarkMode;
            return AlertDialog(
              backgroundColor: isLight ? Colors.white : const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                widget.languageCode == 'en' ? 'No Internet' : 'ምንም የኢንተርኔት ግንኙነት የለም',
                style: TextStyle(
                  color: isLight ? const Color(0xFF0F172A) : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Text(
                widget.languageCode == 'en'
                    ? 'Please check your internet connection and try again.'
                    : 'እባክዎን የኢንተርኔት ግንኙነትዎን አስተካክለው ድጋሚ ይሞክሩ።',
                style: TextStyle(
                  color: isLight ? const Color(0xFF334155) : const Color(0xFF94A3B8),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    widget.languageCode == 'en' ? 'OK' : 'እሺ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      }
      return; // STOP execution
    }

    // Show loading spinner immediately
    _showAdLoadingDialog(context);

    bool dialogClosed = false;
    Timer? timeoutTimer;

    void closeDialogAndProceed() {
      if (!dialogClosed) {
        dialogClosed = true;
        timeoutTimer?.cancel();
        Navigator.of(context, rootNavigator: true).pop(); // Close spinner
        action();
      }
    }

    // If a rewarded ad is ALREADY loaded, show it immediately
    if (_isRewardedAdLoaded && _rewardedAd != null) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _loadRewardedAd();
          closeDialogAndProceed();
        },
        onAdFailedToShowFullScreenContent: (ad, err) {
          ad.dispose();
          _loadRewardedAd();
          closeDialogAndProceed();
        },
      );
      _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          closeDialogAndProceed();
        },
      );
      _rewardedAd = null;
      _isRewardedAdLoaded = false;
      return;
    }

    // Otherwise, actively load a new rewarded ad and wait up to 5 seconds
    timeoutTimer = Timer(const Duration(seconds: 5), () {
      debugPrint("Rewarded ad load timed out after 5 seconds");
      closeDialogAndProceed();
    });

    RewardedAd.load(
      adUnitId: AdHelper.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          if (dialogClosed) {
            ad.dispose();
            return;
          }
          timeoutTimer?.cancel();
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (dismissedAd) {
              dismissedAd.dispose();
              _loadRewardedAd(); // Cache next rewarded ad
              closeDialogAndProceed();
            },
            onAdFailedToShowFullScreenContent: (failedAd, err) {
              failedAd.dispose();
              _loadRewardedAd();
              closeDialogAndProceed();
            },
          );
          
          ad.show(
            onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
              closeDialogAndProceed();
            },
          );
        },
        onAdFailedToLoad: (err) {
          debugPrint("Rewarded ad failed to load within timeout: $err");
          closeDialogAndProceed();
        },
      ),
    );
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: AdHelper.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdLoaded = true;
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              ad.dispose();
              _loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (err) {
          debugPrint('Failed to load an interstitial ad: ${err.message}');
          _isInterstitialAdLoaded = false;
        },
      ),
    );
  }

  void _loadOfflineDownloads() async {
    final downloaded = await OfflineManager.getDownloadedUnitIds();
    final Set<String> expired = {};
    for (final id in downloaded) {
      if (await OfflineManager.isExpired(id)) {
        expired.add(id);
      }
    }
    if (mounted) {
      setState(() {
        _downloadedUnits.clear();
        _downloadedUnits.addAll(downloaded);
        _expiredUnits.clear();
        _expiredUnits.addAll(expired);
      });
    }
  }

  void _loadBestScores() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allUnits = _getUnits();
      final Map<int, int> loadedScores = {};
      for (int i = 0; i < allUnits.length; i++) {
        final int unitNum = i + 1;
        final String scoreKey = 'best_score_${widget.grade}_${widget.subjectId}_u$unitNum';
        final int? score = prefs.getInt(scoreKey);
        if (score != null) {
          loadedScores[unitNum] = score;
        }
      }
      if (mounted) {
        setState(() {
          _unitBestScores.clear();
          _unitBestScores.addAll(loadedScores);
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _rewardedAd?.dispose();
    _interstitialAd?.dispose();
    super.dispose();
  }

  void _loadBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isBannerAdLoaded = false;

    _bannerAd = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isBannerAdLoaded = true;
            });
          } else {
            ad.dispose();
          }
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('UnitSelectionScreen BannerAd failed to load: $err. Code: ${err.code}');
          ad.dispose();
          if (mounted) {
            setState(() {
              _isBannerAdLoaded = false;
              _bannerAd = null;
            });
          }
        },
      ),
    );
    _bannerAd!.load();
  }

  // Bilingual translation helper
  String _local(String key) {
    // Dynamic retrieval from AppStateProvider context
    final String languageCode = AppStateProvider.of(context).languageCode;
    final Map<String, Map<String, String>> localized = {
      'en': {
        'back': 'Back',
        'units_title': 'Unit Explorer',
        'download': 'Download Questions',
        'downloading': 'Downloading Questions...',
        'downloaded': 'Questions Saved',
        'start_quiz': 'Start Practice',
        'completed': 'Completed',
        'units_count': 'Units Available',
        'progress_label': 'My Learning Progress',
        'bytes_info': 'Size: ~100 KB • Complete offline questions database',
        'info_sheet': 'Unit Questions Package',
        'info_desc': 'Downloading saves unit-specific exam questions directly to your device for complete offline practice.',
      },
      'am': {
        'back': 'ተመለስ',
        'units_title': 'የትምህርት ክፍሎች',
        'download': 'ጥያቄዎችን አውርድ',
        'downloading': 'ጥያቄዎችን በማውረድ ላይ...',
        'downloaded': 'ጥያቄዎች ወርደዋል',
        'start_quiz': 'መጠይቅ ጀምር',
        'completed': 'የተጠናቀቀ',
      }
    };
    return localized[languageCode]?[key] ?? key;
  }

  List<Map<String, dynamic>> _getUnits() {
    switch (widget.subjectId) {
      case 'Mathematics':
        if (widget.grade == 9) {
          return [
            {
              'id': 'math_u1',
              'grade': 9,
              'enUnit': 'Unit 1: Further on sets',
              'amUnit': 'Unit 1: Further on sets',
              'enDesc': 'Comprehensive study of set theory, relations, operations, and applications.',
              'amDesc': 'Comprehensive study of set theory, relations, operations, and applications.',
            },
            {
              'id': 'math_u2',
              'grade': 9,
              'enUnit': 'Unit 2: The number system',
              'amUnit': 'Unit 2: The number system',
              'enDesc': 'Understanding real numbers, rational and irrational number properties.',
              'amDesc': 'Understanding real numbers, rational and irrational number properties.',
            },
            {
              'id': 'math_u3',
              'grade': 9,
              'enUnit': 'Unit 3: Solving equations',
              'amUnit': 'Unit 3: Solving equations',
              'enDesc': 'Solving linear and quadratic equations with single or multiple variables.',
              'amDesc': 'Solving linear and quadratic equations with single or multiple variables.',
            },
            {
              'id': 'math_u4',
              'grade': 9,
              'enUnit': 'Unit 4: Solving inequalities',
              'amUnit': 'Unit 4: Solving inequalities',
              'enDesc': 'Solving linear and quadratic inequalities in practical contexts.',
              'amDesc': 'Solving linear and quadratic inequalities in practical contexts.',
            },
            {
              'id': 'math_u5',
              'grade': 9,
              'enUnit': 'Unit 5: Introduction to trigonometry',
              'amUnit': 'Unit 5: Introduction to trigonometry',
              'enDesc': 'Exploring basic trigonometric ratios, angles, and triangles.',
              'amDesc': 'Exploring basic trigonometric ratios, angles, and triangles.',
            },
            {
              'id': 'math_u6',
              'grade': 9,
              'enUnit': 'Unit 6: Regular polygons',
              'amUnit': 'Unit 6: Regular polygons',
              'enDesc': 'Exploring interior and exterior angles, properties of regular polygons.',
              'amDesc': 'Exploring interior and exterior angles, properties of regular polygons.',
            },
            {
              'id': 'math_u7',
              'grade': 9,
              'enUnit': 'Unit 7: Congruency and similarity',
              'amUnit': 'Unit 7: Congruency and similarity',
              'enDesc': 'Proving congruency and similarity in triangles and polygons.',
              'amDesc': 'Proving congruency and similarity in triangles and polygons.',
            },
            {
              'id': 'math_u8',
              'grade': 9,
              'enUnit': 'Unit 8: Vectors in two dimensions',
              'amUnit': 'Unit 8: Vectors in two dimensions',
              'enDesc': 'Understanding 2D vectors, addition, subtraction, and scalar multiplication.',
              'amDesc': 'Understanding 2D vectors, addition, subtraction, and scalar multiplication.',
            },
            {
              'id': 'math_u9',
              'grade': 9,
              'enUnit': 'Unit 9: Statistics and probability',
              'amUnit': 'Unit 9: Statistics and probability',
              'enDesc': 'Introduction to data collection, analysis, probability, and standard deviation.',
              'amDesc': 'Introduction to data collection, analysis, probability, and standard deviation.',
            },
          ];
        }
        if (widget.grade == 10) {
          return [
            {
              'id': 'math_u1',
              'grade': 10,
              'enUnit': 'Unit 1: Polynomial Functions',
              'amUnit': 'ክፍል 1: ፖሊኖሚያል ተግባራት',
              'enDesc': 'Exploring polynomial functions, theorems, operations, and graphs.',
              'amDesc': 'የፖሊኖሚያል ተግባራት፣ ቀመሮች፣ ተግባራት እና ግራፎች።',
            },
            {
              'id': 'math_u2',
              'grade': 10,
              'enUnit': 'Unit 2: Exponential and Logarithmic Functions',
              'amUnit': 'ክፍል 2: ኤክስፖኔንሻል እና ሎጋሪዝም ተግባራት',
              'enDesc': 'Understanding exponents, exponential growth, and logarithmic equations.',
              'amDesc': 'ኤክስፖኔንሻል፣ ኤክስፖኔንሻል እድገት እና የሎጋሪዝም እኩልታዎችን መረዳት።',
            },
            {
              'id': 'math_u3',
              'grade': 10,
              'enUnit': 'Unit 3: Trigonometric Functions',
              'amUnit': 'ክፍል 3: ትሪጎኖሜትሪክ ተግባራት',
              'enDesc': 'Exploring trigonometric functions, graphs, and basic identities.',
              'amDesc': 'ትሪጎኖሜትሪክ ተግባራት፣ ግራፎች እና መሰረታዊ ማንነቶች ማሰስ።',
            },
            {
              'id': 'math_u4',
              'grade': 10,
              'enUnit': 'Unit 4: Circles',
              'amUnit': 'ክፍል 4: ክበቦች',
              'enDesc': 'Theorems on circles, angles, tangents, and coordinate geometry of circles.',
              'amDesc': 'በክበቦች ፣ በማእዘኖች ፣ በታንጀንት እና በክበቦች መጋጠሚያ ጂኦሜትሪ ላይ ያሉ ቲዎረሞች።',
            },
            {
              'id': 'math_u5',
              'grade': 10,
              'enUnit': 'Unit 5: Solid Geometry',
              'amUnit': 'ክፍል 5: ሶሊድ ጂኦሜትሪ',
              'enDesc': 'Prisms, pyramids, cylinders, cones, spheres, surface area and volume.',
              'amDesc': 'ፕሪዝም, ፒራሚድ, ሲሊንደር, ኮን, ሉል, የላይኛው ስፋት እና ይዘት (ቮልዩም).',
            },
            {
              'id': 'math_u6',
              'grade': 10,
              'enUnit': 'Unit 6: Coordinate Geometry',
              'amUnit': 'ክፍል 6: መጋጠሚያ ጂኦሜትሪ',
              'enDesc': 'Distance, midpoint, division of segment, equation of line, and parallel/perpendicular lines.',
              'amDesc': 'ርቀት, መካከለኛ ነጥብ, የክፍል ክፍፍል, የመስመር እኩልታ እና ትይዩ / ቀጥተኛ መስመሮች.',
            },
          ];
        }
        if (widget.grade == 11) {
          return [
            {
              'id': 'math_u1',
              'grade': 11,
              'enUnit': 'Unit 1: Relations and Functions',
              'amUnit': 'ክፍል 1: ግንኙነቶች እና ተግባራት',
              'enDesc': 'Advanced relations, types of functions, algebra of functions, and graphs.',
              'amDesc': 'የላቁ ግንኙነቶች፣ የተግባር አይነቶች፣ የተግባር አልጀብራ እና ግራፎች።',
            },
            {
              'id': 'math_u2',
              'grade': 11,
              'enUnit': 'Unit 2: Rational Expressions and Equations',
              'amUnit': 'ክፍል 2: ረሽናል መግለጫዎች እና እኩልታዎች',
              'enDesc': 'Simplifying rational expressions, solving rational equations, and inequalities.',
              'amDesc': 'ረሽናል መግለጫዎችን ማቅለል፣ ረሽናል እኩልታዎችን እና አለመመጣጠንን መፍታት።',
            },
            {
              'id': 'math_u3',
              'grade': 11,
              'enUnit': 'Unit 3: Coordinate Geometry',
              'amUnit': 'ክፍል 3: መጋጠሚያ ጂኦሜትሪ',
              'enDesc': 'Straight lines, conic sections including circles, parabolas, ellipses, and hyperbolas.',
              'amDesc': 'ቀጥተኛ መስመሮች, የኮኒክ ክፍሎች ክበቦችን, ፓራቦላዎችን, ኤሊፕስ እና ሃይፐርቦላዎችን ጨምሮ.',
            },
            {
              'id': 'math_u4',
              'grade': 11,
              'enUnit': 'Unit 4: Mathematical Reasoning',
              'amUnit': 'ክፍል 4: ሂሳባዊ አመክንዮ',
              'enDesc': 'Mathematical logic, propositions, arguments, open statements, and quantifiers.',
              'amDesc': 'ሂሳባዊ ሎጂክ፣ ሃሳቦች፣ ክርክሮች፣ ክፍት መግለጫዎች እና ኳንቲፋየሮች።',
            },
            {
              'id': 'math_u5',
              'grade': 11,
              'enUnit': 'Unit 5: Statistics and Probability',
              'amUnit': 'ክፍል 5: ስታቲስቲክስ እና ፕሮባብሊቲ',
              'enDesc': 'Measures of dispersion, permutations, combinations, and probability distributions.',
              'amDesc': 'የመበታተን መለኪያዎች, ፐርሙቴሽን, ጥምረት እና ፕሮባብሊቲ ስርጭቶች.',
            },
            {
              'id': 'math_u6',
              'grade': 11,
              'enUnit': 'Unit 6: Matrices and Determinants',
              'amUnit': 'ክፍል 6: ማትሪክስ እና ዲተርሚናንትስ',
              'enDesc': 'Matrix operations, determinants, and solving systems of linear equations.',
              'amDesc': 'የማትሪክስ ስሌቶች, ዲተርሚናንቶች እና የመስመራዊ እኩልታዎች ስርዓቶችን መፍታት.',
            },
          ];
        }
        if (widget.grade == 12) {
          return [
            {
              'id': 'math_u1',
              'grade': 12,
              'enUnit': 'Unit 1: Sequences and Series',
              'amUnit': 'ክፍል 1: ቅደም ተከተሎች እና ተከታታዮች',
              'enDesc': 'Arithmetic and geometric sequences, series, and convergence tests.',
              'amDesc': 'አርቲሜቲክ እና ጂኦሜትሪክ ቅደም ተከተሎች, ተከታታዮች እና የውህደት ሙከራዎች.',
            },
            {
              'id': 'math_u2',
              'grade': 12,
              'enUnit': 'Unit 2: Introduction to Limits and Continuity',
              'amUnit': 'ክፍል 2: ሊሚት እና ተከታታይነት መግቢያ',
              'enDesc': 'Limits of sequences and functions, continuity properties, and theorems.',
              'amDesc': 'የቅደም ተከተሎች እና ተግባራት ወሰኖች, ቀጣይነት ባህሪያት እና ንድፈ ሐሳቦች.',
            },
            {
              'id': 'math_u3',
              'grade': 12,
              'enUnit': 'Unit 3: Introduction to Differential Calculus',
              'amUnit': 'ክፍል 3: ዲፈረንሻል ካልኩለስ መግቢያ',
              'enDesc': 'Derivatives of functions, rules of differentiation, and rate of change.',
              'amDesc': 'የተግባር ተዋጽኦዎች, የልዩነት ደንቦች እና የለውጥ ፍጥነት.',
            },
            {
              'id': 'math_u4',
              'grade': 12,
              'enUnit': 'Unit 4: Applications of Differential Calculus',
              'amUnit': 'ክፍል 4: የዲፈረንሻል ካልኩለስ አተገባበር',
              'enDesc': 'Extrema of functions, curve sketching, optimization, and L’Hopital’s rule.',
              'amDesc': 'የተግባር ጽንፍ, የኩርባ ንድፍ, ማመቻቸት እና የኤል ሆፒታል ህግ.',
            },
            {
              'id': 'math_u5',
              'grade': 12,
              'enUnit': 'Unit 5: Introduction to Integral Calculus',
              'amUnit': 'ክፍል 5: ኢንተግራል ካልኩለስ መግቢያ',
              'enDesc': 'Antiderivatives, definite and indefinite integrals, and areas of regions.',
              'amDesc': 'ፀረ-ተዋጽኦዎች, የተወሰኑ እና ያልተወሰኑ ኢንተግራሎች, እና የክልሎች ስፋት.',
            },
            {
              'id': 'math_u6',
              'grade': 12,
              'enUnit': 'Unit 6: Three-Dimensional Geometry and Vectors',
              'amUnit': 'ክፍል 6: ባለ ሶስት አቅጣጫዊ ጂኦሜትሪ እና ቬክተሮች',
              'enDesc': 'Vectors in space, dot product, cross product, lines, and planes in 3D.',
              'amDesc': 'ቬክተሮች በጠፈር, ባለ ሁለት እና ሶስት አቅጣጫዊ የቬክተር ውጤቶች, መስመሮች እና አውሮፕላኖች.',
            },
          ];
        }
        return [
          {
            'id': 'math_u1',
            'grade': widget.grade,
            'enUnit': 'Unit 1: The Number System',
            'amUnit': 'ክፍል 1: የቁጥር ስርዓት',
            'enDesc': 'Exploring rational & irrational numbers, operations, proofs, and sequence properties.',
            'amDesc': 'አሳማኝ እና አሳማኝ ያልሆኑ ቁጥሮች፣ ስሌቶች፣ ቀመሮች እና ቅደም ተከተሎችን ማሰስ።',
          },
          {
            'id': 'math_u2',
            'grade': widget.grade,
            'enUnit': 'Unit 2: Equations & Inequalities',
            'amUnit': 'ክፍል 2: እኩልታዎች እና አለመሳባዎች',
            'enDesc': 'Solving quadratic systems, absolute values, and application models in real contexts.',
            'amDesc': 'የሁለተኛ ዲግሪ እኩልታዎችን፣ ፍጹም እሴቶችን እና ተግባራዊ አተገባበር መፍታት።',
          },
          {
            'id': 'math_u3',
            'grade': widget.grade,
            'enUnit': 'Unit 3: Coordinates & Vector Spaces',
            'amUnit': 'ክፍል 3: መጋጠሚያዎች እና የቬክተር ክፍተቶች',
            'enDesc': 'Distance formulas, midpoint vectors, linear equations slope, and spatial points.',
            'amDesc': 'የነጥቦች ርቀቶች ቀመር፣ የመካከለኛ ነጥብ፣ የቁልቁለት እና የቬክተር አቀማመጦች።',
          },
          {
            'id': 'math_u4',
            'grade': widget.grade,
            'enUnit': 'Unit 4: Geometry & Trigonometry',
            'amUnit': 'ክፍል 4: ጂኦሜትሪ እና ትሪጎኖሜትሪ',
            'enDesc': 'Congruent shapes, sine & cosine rules, area theorems, and complex angle measures.',
            'amDesc': 'ተመሳሳይ ቅርጾች፣ ሳይን እና ኮሳይን ህግጋት፣ የቦታ ይዘት እና አንግሎች።',
          },
          {
            'id': 'math_u5',
            'grade': widget.grade,
            'enUnit': 'Unit 5: Statistics & Probability',
            'amUnit': 'ክፍል 5: ስታቲስቲክስ እና ፕሮባብሊቲ',
            'enDesc': 'Data variance indices, standard deviations, permutation and independent compound events.',
            'amDesc': 'የዳታ ልዩነቶች እና ስታንዳርድ ዴቪዬሽን፣ ፐርሙቴሽን እና የተለያዩ የዕድል ሁኔታዎች።',
          },
        ];

      case 'Biology':
        if (widget.grade == 9) {
          return [
            {
              'id': 'bio_u1',
              'grade': 9,
              'enUnit': 'Unit 1: Introduction to Biology',
              'amUnit': 'Unit 1: Introduction to Biology',
              'enDesc': 'The study of life, scientific methods, and biological tools.',
              'amDesc': 'The study of life, scientific methods, and biological tools.',
            },
            {
              'id': 'bio_u2',
              'grade': 9,
              'enUnit': 'Unit 2: Characteristics and Classification of Organisms',
              'amUnit': 'Unit 2: Characteristics and Classification of Organisms',
              'enDesc': 'Principles of classification, taxonomy, and domains of life.',
              'amDesc': 'Principles of classification, taxonomy, and domains of life.',
            },
            {
              'id': 'bio_u3',
              'grade': 9,
              'enUnit': 'Unit 3: Cells',
              'amUnit': 'Unit 3: Cells',
              'enDesc': 'Structure, types, and functions of plant and animal cells.',
              'amDesc': 'Structure, types, and functions of plant and animal cells.',
            },
            {
              'id': 'bio_u4',
              'grade': 9,
              'enUnit': 'Unit 4: Reproduction',
              'amUnit': 'Unit 4: Reproduction',
              'enDesc': 'Asexual and sexual reproduction mechanisms in living organisms.',
              'amDesc': 'Asexual and sexual reproduction mechanisms in living organisms.',
            },
            {
              'id': 'bio_u5',
              'grade': 9,
              'enUnit': 'Unit 5: Human Health, Nutrition, and Disease',
              'amUnit': 'Unit 5: Human Health, Nutrition, and Disease',
              'enDesc': 'Understanding balanced diets, human diseases, and prevention strategies.',
              'amDesc': 'Understanding balanced diets, human diseases, and prevention strategies.',
            },
            {
              'id': 'bio_u6',
              'grade': 9,
              'enUnit': 'Unit 6: Ecology',
              'amUnit': 'Unit 6: Ecology',
              'enDesc': 'Organisms and their environment, food webs, and ecosystem dynamics.',
              'amDesc': 'Organisms and their environment, food webs, and ecosystem dynamics.',
            },
          ];
        }
        if (widget.grade == 10) {
          return [
            {
              'id': 'bio_u1',
              'grade': 10,
              'enUnit': 'Unit 1: Biotechnology',
              'amUnit': 'ክፍል 1: ባዮቴክኖሎጂ',
              'enDesc': 'Introduction to biotechnology, traditional and modern applications.',
              'amDesc': 'ስለ ባዮቴክኖሎጂ መግቢያ፣ ባህላዊ እና ዘመናዊ አተገባበር።',
            },
            {
              'id': 'bio_u2',
              'grade': 10,
              'enUnit': 'Unit 2: Heredity and Genetics',
              'amUnit': 'ክፍል 2: ውርስ እና ጄኔቲክስ',
              'enDesc': 'Mendelian genetics, chromosomes, DNA structure, and inheritance.',
              'amDesc': 'የሜንደሊያን ጄኔቲክስ፣ ክሮሞሶምች፣ የዲኤንኤ መዋቅር እና ውርስ።',
            },
            {
              'id': 'bio_u3',
              'grade': 10,
              'enUnit': 'Unit 3: Human Nervous System and Sensory Organs',
              'amUnit': 'ክፍል 3: የሰው የነርቭ ሥርዓት እና የስሜት ሕዋሳት',
              'enDesc': 'Structure and function of neurons, central nervous system, and senses.',
              'amDesc': 'የነርቭ ሴሎች አወቃቀር እና ተግባር፣ ማዕከላዊ የነርቭ ሥርዓት እና የስሜት ሕዋሳት።',
            },
            {
              'id': 'bio_u4',
              'grade': 10,
              'enUnit': 'Unit 4: Chronic and Infectious Diseases',
              'amUnit': 'ክፍል 4: ሥር የሰደዱ እና ተላላፊ በሽታዎች',
              'enDesc': 'Socio-economic impact of diseases, prevention, treatment, and immunology.',
              'amDesc': 'የበሽታዎች ማህበራዊና ኢኮኖሚያዊ ተፅእኖ፣ መከላከል፣ ህክምና እና ስነ-በሽታ መከላከል ጥናት።',
            },
            {
              'id': 'bio_u5',
              'grade': 10,
              'enUnit': 'Unit 5: Ecology',
              'amUnit': 'ክፍል 5: ሥነ-ምህዳር',
              'enDesc': 'Ecosystems, biodiversity conservation, biogeochemical cycles, and environmental issues.',
              'amDesc': 'ሥነ-ምህዳሮች፣ የብዝሃ ህይወት ጥበቃ፣ የባዮ-ጂኦ-ኬሚካላዊ ዑደቶች እና የአካባቢ ጉዳዮች።',
            },
          ];
        }
        if (widget.grade == 11) {
          return [
            {
              'id': 'bio_u1',
              'grade': 11,
              'enUnit': 'Unit 1: Biology and Technology',
              'amUnit': 'ክፍል 1: ባዮሎጂ እና ቴክኖሎጂ',
              'enDesc': 'Relationship between science, biology, technology and society.',
              'amDesc': 'በሳይንስ፣ ባዮሎጂ፣ ቴክኖሎጂ እና ማህበረሰብ መካከል ያለው ግንኙነት።',
            },
            {
              'id': 'bio_u2',
              'grade': 11,
              'enUnit': 'Unit 2: Biological Molecules',
              'amUnit': 'ክፍል 2: ባዮሎጂያዊ ሞለኪውሎች',
              'enDesc': 'Structure and function of carbohydrates, lipids, proteins, and nucleic acids.',
              'amDesc': 'የካርቦሃይድሬትስ፣ ሊፒድስ፣ ፕሮቲኖች እና ኑክሊክ አሲዶች አወቃቀር እና ተግባር።',
            },
            {
              'id': 'bio_u3',
              'grade': 11,
              'enUnit': 'Unit 3: Enzymes and Metabolic Activities',
              'amUnit': 'ክፍል 3: ኢንዛይሞች እና ሜታቦሊክ ተግባራት',
              'enDesc': 'Properties of enzymes, mechanism of enzyme action, and metabolic pathways.',
              'amDesc': 'የኢንዛይሞች ባህሪያት፣ የኢንዛይም ተግባር ዘዴ እና ሜታቦሊክ መንገዶች።',
            },
            {
              'id': 'bio_u4',
              'grade': 11,
              'enUnit': 'Unit 4: Cell Biology',
              'amUnit': 'ክፍል 4: የህዋስ ባዮሎጂ',
              'enDesc': 'Cell theory, cell membrane structure, transport across membranes, and cell division.',
              'amDesc': 'የሴል ቲዎሪ፣ የሴል ሽፋን መዋቅር፣ በሽፋኖች ላይ መጓጓዣ እና የሴል ክፍፍል።',
            },
            {
              'id': 'bio_u5',
              'grade': 11,
              'enUnit': 'Unit 5: Microorganisms',
              'amUnit': 'ክፍል 5: ረቂቅ ተሕዋስያን',
              'enDesc': 'Structure, characteristics, and economic importance of bacteria, viruses, and fungi.',
              'amDesc': 'የባክቴሪያ፣ ቫይረሶች እና ፈንገሶች አወቃቀር፣ ባህሪያት እና ኢኮኖሚያዊ ጠቀሜታ።',
            },
            {
              'id': 'bio_u6',
              'grade': 11,
              'enUnit': 'Unit 6: Ecology',
              'amUnit': 'ክፍል 6: ሥነ-ምህዳር',
              'enDesc': 'Biomes, ecosystem productivity, nutrient cycling, and succession.',
              'amDesc': 'ባዮሞች, የስነ-ምህዳር ምርታማነት, አልሚ ንጥረ ነገሮች ዑደት እና ተከታታይነት.',
            },
          ];
        }
        if (widget.grade == 12) {
          return [
            {
              'id': 'bio_u1',
              'grade': 12,
              'enUnit': 'Unit 1: Cellular Respiration and Photosynthesis',
              'amUnit': 'ክፍል 1: የህዋስ መተንፈስ እና ፎቶሲንተሲስ',
              'enDesc': 'Aerobic and anaerobic respiration, light and dark reactions of photosynthesis.',
              'amDesc': 'ኤሮቢክ እና አናኢሮቢክ መተንፈስ ፣ የፎቶሲንተሲስ ብርሃን እና ጨለማ ግብረመልሶች።',
            },
            {
              'id': 'bio_u2',
              'grade': 12,
              'enUnit': 'Unit 2: Molecular Biology',
              'amUnit': 'ክፍል 2: ሞለኪውላዊ ባዮሎጂ',
              'enDesc': 'DNA replication, transcription, translation, and genetic engineering.',
              'amDesc': 'የዲኤንኤ መባዛት፣ ትራንስክሪፕሽን፣ ትርጉም እና የጄኔቲክ ምህንድስና።',
            },
            {
              'id': 'bio_u3',
              'grade': 12,
              'enUnit': 'Unit 3: Human Evolution and Diversity',
              'amUnit': 'ክፍል 3: የሰው ልጅ ዝግመተ ለውጥ እና ስብጥር',
              'enDesc': 'Evidences of human evolution, hominid evolution, and modern human diversity.',
              'amDesc': 'የሰው ልጅ ዝግመተ ለውጥ፣ የሆሚኒድ ዝግመተ ለውጥ እና የዘመናዊ ሰው ስብጥር ማስረጃዎች።',
            },
            {
              'id': 'bio_u4',
              'grade': 12,
              'enUnit': 'Unit 4: Plant Anatomy and Physiology',
              'amUnit': 'ክፍል 4: የእፅዋት አወቃቀር እና ስነ-ተግባር',
              'enDesc': 'Plant tissues, root and stem anatomy, transpiration, and plant hormones.',
              'amDesc': 'የእፅዋት ቲሹዎች ፣ የሥር እና የግንድ አካል ፣ ትራንስፓይሬሽን እና የእፅዋት ሆርሞኖች።',
            },
            {
              'id': 'bio_u5',
              'grade': 12,
              'enUnit': 'Unit 5: Animal Anatomy and Physiology',
              'amUnit': 'ክፍል 5: የእንስሳት አወቃቀር እና ስነ-ተግባር',
              'enDesc': 'Digestive, respiratory, circulatory, excretory systems and homeostasis.',
              'amDesc': 'የምግብ መፈጨት፣ የመተንፈሻ አካላት፣ የደም ዝውውር፣ የኤክስክሬተሪ ሥርዓት እና ሆሞስታሲስ።',
            },
          ];
        }
        return [
          {
            'id': 'bio_u1',
            'grade': widget.grade,
            'enUnit': 'Unit 1: Introduction to Biology',
            'amUnit': 'ክፍል 1: ስለ ስነ-ህይወት መግቢያ',
            'enDesc': 'General scope of biological sciences, history, instruments, and microscopic observations.',
            'amDesc': 'የስነ-ህይወት ሳይንስ አጠቃላይ ድንጋጌዎች፣ ታሪክ፣ መሳሪያዎች እና የማይክሮስኮፕ አጠቃቀም።',
          },
          {
            'id': 'bio_u2',
            'grade': widget.grade,
            'enUnit': 'Unit 2: Cellular Chemistry & Functions',
            'amUnit': 'ክፍል 2: የህዋስ ኬሚስትሪ እና ተግባራት',
            'enDesc': 'Primary organelles structure, cellular respiration pathway, and DNA replication mechanisms.',
            'amDesc': 'የኦርጋኔሎች መዋቅር፣ የህዋስ መተንፈስ ተግባር እና የዲኤንኤ ገለጻ መርሆዎች።',
          },
          {
            'id': 'bio_u3',
            'grade': widget.grade,
            'enUnit': 'Unit 3: Plant Structure and Physiology',
            'amUnit': 'ክፍል 3: የዕፅዋት መዋቅር እና ስነ-ተግባር',
            'enDesc': 'Photosynthesis processes, stomatal movements, transpiration forces and nutrient transport.',
            'amDesc': 'ፎቶሲንተሲስ፣ የስቶማታ እንቅስቃሴ፣ ትራንስፓይሬሽን እና የዕፅዋት ምግብ ዝውውር።',
          },
          {
            'id': 'bio_u4',
            'grade': widget.grade,
            'enUnit': 'Unit 4: Human Anatomy & Health Systems',
            'amUnit': 'ክፍል 4: የሰው አካል የአካል ክፍሎች እና ጤና',
            'enDesc': 'Nervous transmission pathways, endocrinal regulatory glands, and immune system response.',
            'amDesc': 'የነርቭ ዝውውር መቆጣጠሪያ፣ የሆርሞኖች እጢዎች እና የበሽታ መከላከያ ስርዓቶች።',
          },
          {
            'id': 'bio_u5',
            'grade': widget.grade,
            'enUnit': 'Unit 5: Ecology & Environmental Physics',
            'amUnit': 'ክፍል 5: ስነ-ምህዳር እና አካባቢ',
            'enDesc': 'Biosphere interactions, biogeochemical nutrient loops, and habitat preservation dynamics.',
            'amDesc': 'በባዮስፌር ውስጥ ያሉ ግንኙነቶች፣ አልሚ ንጥረ ነገሮች ኡደት እና አካባቢ ጥበቃ።',
          },
        ];

      case 'Physics':
        if (widget.grade == 9) {
          return [
            {
              'id': 'phys_u1',
              'grade': 9,
              'enUnit': 'Unit 1: Physics and Human Society',
              'amUnit': 'Unit 1: Physics and Human Society',
              'enDesc': 'Understanding the role of physics in daily life and technology.',
              'amDesc': 'Understanding the role of physics in daily life and technology.',
            },
            {
              'id': 'phys_u2',
              'grade': 9,
              'enUnit': 'Unit 2: Physical Quantities',
              'amUnit': 'Unit 2: Physical Quantities',
              'enDesc': 'Measurement, standard units, vector and scalar quantities.',
              'amDesc': 'Measurement, standard units, vector and scalar quantities.',
            },
            {
              'id': 'phys_u3',
              'grade': 9,
              'enUnit': 'Unit 3: Motion in a Straight Line',
              'amUnit': 'Unit 3: Motion in a Straight Line',
              'enDesc': 'Analyzing displacement, velocity, and acceleration.',
              'amDesc': 'Analyzing displacement, velocity, and acceleration.',
            },
            {
              'id': 'phys_u4',
              'grade': 9,
              'enUnit': 'Unit 4: Force, Work, Energy, and Power',
              'amUnit': 'Unit 4: Force, Work, Energy, and Power',
              'enDesc': 'Understanding the laws of motion, conservation of energy, and power.',
              'amDesc': 'Understanding the laws of motion, conservation of energy, and power.',
            },
            {
              'id': 'phys_u5',
              'grade': 9,
              'enUnit': 'Unit 5: Simple Machines',
              'amUnit': 'Unit 5: Simple Machines',
              'enDesc': 'Principles and mechanical advantages of simple machines.',
              'amDesc': 'Principles and mechanical advantages of simple machines.',
            },
            {
              'id': 'phys_u6',
              'grade': 9,
              'enUnit': 'Unit 6: Mechanical Oscillation and Sound Wave',
              'amUnit': 'Unit 6: Mechanical Oscillation and Sound Wave',
              'enDesc': 'Properties of sound waves, frequency, amplitude, and wave motion.',
              'amDesc': 'Properties of sound waves, frequency, amplitude, and wave motion.',
            },
            {
              'id': 'phys_u7',
              'grade': 9,
              'enUnit': 'Unit 7: Temperature and Thermometer',
              'amUnit': 'Unit 7: Temperature and Thermometer',
              'enDesc': 'Understanding heat, thermal expansion, and temperature scales.',
              'amDesc': 'Understanding heat, thermal expansion, and temperature scales.',
            },
          ];
        }
        if (widget.grade == 10) {
          return [
            {
              'id': 'phys_u1',
              'grade': 10,
              'enUnit': 'Unit 1: Vector Quantities',
              'amUnit': 'ክፍል 1: ቬክተር መጠኖች',
              'enDesc': 'Scalar and vector quantities, vector addition, resolution, and representation.',
              'amDesc': 'ስካላር እና ቬክተር መጠኖች፣ የቬክተር ድምር፣ ጥንቅር እና መግለጫ።',
            },
            {
              'id': 'phys_u2',
              'grade': 10,
              'enUnit': 'Unit 2: Uniformly Accelerated Motion',
              'amUnit': 'ክፍል 2: ወጥ የተፋጠነ እንቅስቃሴ',
              'enDesc': 'Equations of accelerated motion, free fall, projectile motion, and graphical analysis.',
              'amDesc': 'የተፋጠነ እንቅስቃሴ እኩልታዎች፣ ነጻ መውደቅ፣ የፕሮጀክታይል እንቅስቃሴ እና ግራፊክ ትንተና።',
            },
            {
              'id': 'phys_u3',
              'grade': 10,
              'enUnit': 'Unit 3: Elasticity and Simple Harmonic Motion',
              'amUnit': 'ክፍል 3: የመለጠጥ ባህሪ እና ቀላል ሃርሞኒክ እንቅስቃሴ',
              'enDesc': 'Hooke\'s law, stress, strain, elasticity, simple pendulum, and mass-spring systems.',
              'amDesc': 'የሁክ ህግ, ውጥረት, ስትሬን, የመለጠጥ ችሎታ, ቀላል ፔንዱለም እና የባለ-ስፕሪንግ ስርዓቶች.',
            },
            {
              'id': 'phys_u4',
              'grade': 10,
              'enUnit': 'Unit 4: Electromagnetic Induction',
              'amUnit': 'ክፍል 4: ኤሌክትሮማግኔቲክ ኢንዳክሽን',
              'enDesc': 'Magnetic flux, Faraday\'s law, Lenz\'s law, generators, transformers, and induction.',
              'amDesc': 'ማግኔቲክ ፍለክስ፣ የፋራዳይ ህግ፣ የሌንዝ ህግ፣ ጄነሬተሮች፣ ትራንስፎርመሮች እና ኢንዳክሽን።',
            },
            {
              'id': 'phys_u5',
              'grade': 10,
              'enUnit': 'Unit 5: Introduction to Nuclear Physics',
              'amUnit': 'ክፍል 5: አቶሚክ እና ኒውክሌር ፊዚክስ',
              'enDesc': 'Radioactivity, nuclear decay, fission, fusion, half-life, and peaceful applications.',
              'amDesc': 'ራዲዮአክቲቪቲ፣ የኒውክሌር መበስበስ፣ ፊሽን፣ ፊውዥን፣ ግማሽ ህይወት እና ሰላማዊ አተገባበር።',
            },
          ];
        }
        if (widget.grade == 11) {
          return [
            {
              'id': 'phys_u1',
              'grade': 11,
              'enUnit': 'Unit 1: Vectors and Physical Quantities',
              'amUnit': 'ክፍል 1: ቬክተሮች እና ፊዚካዊ መጠኖች',
              'enDesc': 'Vector addition, dot and cross products, dimensional analysis, and error analysis.',
              'amDesc': 'የቬክተር ድምር, ዶት እና ክሮስ ውጤቶች, የዲሜንሽን ትንተና እና የስህተት ትንተና.',
            },
            {
              'id': 'phys_u2',
              'grade': 11,
              'enUnit': 'Unit 2: Kinematics',
              'amUnit': 'ክፍል 2: ኪነማቲክስ',
              'enDesc': 'Equations of motion in 1D and 2D, relative velocity, and projectile motion.',
              'amDesc': 'በ1D እና 2D ውስጥ የእንቅስቃሴ እኩልታዎች፣ አንጻራዊ ፍጥነት እና የፕሮጀክታይል እንቅስቃሴ።',
            },
            {
              'id': 'phys_u3',
              'grade': 11,
              'enUnit': 'Unit 3: Dynamics',
              'amUnit': 'ክፍል 3: ዳይናሚክስ',
              'enDesc': 'Newton’s laws of motion, friction, circular motion, linear momentum and impulse.',
              'amDesc': 'የኒውተን የእንቅስቃሴ ህጎች፣ ፍጥጫ፣ ክብ እንቅስቃሴ፣ መስመራዊ ሞመንተም እና ኢምፐልስ።',
            },
            {
              'id': 'phys_u4',
              'grade': 11,
              'enUnit': 'Unit 4: Work, Energy and Power',
              'amUnit': 'ክፍል 4: ስራ, ጉልበት, እና ሃይል',
              'enDesc': 'Work-energy theorem, conservative and non-conservative forces, conservation of energy.',
              'amDesc': 'የስራ-ጉልበት ቲዎረም, ጠባቂ እና ጠባቂ ያልሆኑ ኃይሎች, የጉልበት ጥበቃ.',
            },
            {
              'id': 'phys_u5',
              'grade': 11,
              'enUnit': 'Unit 5: Rotational Motion',
              'amUnit': 'ክፍል 5: ሽክርክሪት እንቅስቃሴ',
              'enDesc': 'Angular kinematics, torque, moment of inertia, angular momentum and rotational kinetic energy.',
              'amDesc': 'የማዕዘን ኪነማቲክስ፣ ቶርክ፣ የሽክርክሪት ግትርነት፣ የማዕዘን ሞመንተም እና ሽክርክሪት ጉልበት።',
            },
            {
              'id': 'phys_u6',
              'grade': 11,
              'enUnit': 'Unit 6: Gravitation',
              'amUnit': 'ክፍል 6: የስበት ኃይል',
              'enDesc': 'Newton\'s law of universal gravitation, Kepler\'s laws of planetary motion, satellite motion.',
              'amDesc': 'የኒውተን አጠቃላይ የስበት ህግ፣ የኬፕለር የፕላኔቶች እንቅስቃሴ ህግጋት፣ የሳተላይት እንቅስቃሴ።',
            },
            {
              'id': 'phys_u7',
              'grade': 11,
              'enUnit': 'Unit 7: Properties of Matter',
              'amUnit': 'ክፍል 7: የማተር ባህሪያት',
              'enDesc': 'Elastic properties of solids, fluid statics, fluid dynamics, viscosity and surface tension.',
              'amDesc': 'የጠንካራ አካላት የመለጠጥ ባህሪያት፣ ፈሳሽ ስታቲክስ፣ ፈሳሽ ዳይናሚክስ፣ ፍሰት መቋቋም እና ገጽታ ውጥረት።',
            },
            {
              'id': 'phys_u8',
              'grade': 11,
              'enUnit': 'Unit 8: Thermodynamics',
              'amUnit': 'ክፍል 8: ቴርሞዳይናሚክስ',
              'enDesc': 'Temperature scales, thermal expansion, gas laws, heat transfer, and laws of thermodynamics.',
              'amDesc': 'የሙቀት መለኪያዎች፣ የሙቀት መስፋፋት፣ የጋዝ ህጎች፣ የሙቀት ዝውውር እና የቴርሞዳይናሚክስ ህጎች።',
            },
          ];
        }
        if (widget.grade == 12) {
          return [
            {
              'id': 'phys_u1',
              'grade': 12,
              'enUnit': 'Unit 1: Oscillations and Waves',
              'amUnit': 'ክፍል 1: ማወዛወዝ እና ሞገዶች',
              'enDesc': 'Simple harmonic motion, wave motion, sound waves, Doppler effect, and resonance.',
              'amDesc': 'ቀላል ሃርሞኒክ እንቅስቃሴ, የሞገድ እንቅስቃሴ, የድምፅ ሞገዶች, ዶፕለር ተፅእኖ እና ሬዞናንስ.',
            },
            {
              'id': 'phys_u2',
              'grade': 12,
              'enUnit': 'Unit 2: Wave Optics',
              'amUnit': 'ክፍል 2: የሞገድ ኦፕቲክስ',
              'enDesc': 'Interference of light, diffraction, polarization, and optical instruments.',
              'amDesc': 'የብርሃን ጣልቃገብነት, ድፍረክሽን, ፖላራይዜሽን እና ኦፕቲካል መሳሪያዎች.',
            },
            {
              'id': 'phys_u3',
              'grade': 12,
              'enUnit': 'Unit 3: Electrostatics',
              'amUnit': 'ክፍል 3: ኤሌክትሮስታቲክስ',
              'enDesc': 'Coulomb\'s law, electric field, electric potential, capacitance, and dielectrics.',
              'amDesc': 'የኩሎምብ ህግ, የኤሌክትሪክ መስክ, የኤሌክትሪክ አቅም, አቅም (ካፓሲታንስ) እና ዳይኤሌክትሪክስ.',
            },
            {
              'id': 'phys_u4',
              'grade': 12,
              'enUnit': 'Unit 4: Electric Current and DC Circuits',
              'amUnit': 'ክፍል 4: የኤሌክትሪክ ፍሰት እና ዲሲ ሰርኪዩቶች',
              'enDesc': 'Ohm\'s law, electrical energy, power, Kirchhoff\'s rules, and measuring instruments.',
              'amDesc': 'የኦሆም ህግ, የኤሌክትሪክ ኃይል, የኤሌክትሪክ ፍሰት ህጎች (ኪርቾፍ) እና መለኪያ መሳሪያዎች.',
            },
            {
              'id': 'phys_u5',
              'grade': 12,
              'enUnit': 'Unit 5: Magnetism and Magnetic Fields',
              'amUnit': 'ክፍል 5: ማግኔቲዝም',
              'enDesc': 'Magnetic forces, torque on current loops, Ampere\'s law, and electromagnetic induction.',
              'amDesc': 'የማግኔት ኃይሎች, የሽቦ ቶርክ, የአምፔር ህግ እና የኤሌክትሮማግኔቲክ ኢንዳክሽን.',
            },
            {
              'id': 'phys_u6',
              'grade': 12,
              'enUnit': 'Unit 6: Alternating Currents',
              'amUnit': 'ክፍል 6: ተለዋዋጭ የኤሌክትሪክ ፍሰት',
              'enDesc': 'AC circuits, impedance, resonance in AC circuits, and power in AC circuits.',
              'amDesc': 'ተለዋዋጭ ፍሰት ሰርኪዩቶች, እክል (ኢምፔዳንስ), ተለዋዋጭ ፍሰት ሬዞናንስ እና ኃይል.',
            },
            {
              'id': 'phys_u7',
              'grade': 12,
              'enUnit': 'Unit 7: Modern Physics',
              'amUnit': 'ክፍል 7: ዘመናዊ ፊዚክስ',
              'enDesc': 'Photoelectric effect, Bohr\'s model, quantum theory, atomic spectra, and relativity.',
              'amDesc': 'ፎቶኤሌክትሪክ ተፅእኖ, የቦህር አቶም ሞዴል, ኳንተም ቲዎሪ, አቶሚክ ስፔክትራ እና ረሌቲቪቲ.',
            },
          ];
        }
        return [
          {
            'id': 'phys_u1',
            'grade': widget.grade,
            'enUnit': 'Unit 1: Physical Quantities & Vectors',
            'amUnit': 'ክፍል 1: ፊዚካዊ መጠኖች እና ቬክተሮች',
            'enDesc': 'Vector resolutions, scalar products, dimension analysis, and precision measurements.',
            'amDesc': 'የቬክተር ክፍፍሎች፣ መስቀለኛ እና ስካላር ብዜቶች፣ እና የልኬት ትክክለኛነት ሞዴሎች።',
          },
          {
            'id': 'phys_u2',
            'grade': widget.grade,
            'enUnit': 'Unit 2: Kinematics & Mechanics',
            'amUnit': 'ክፍል 2: ኪነማቲክስ እና መካኒክስ',
            'enDesc': 'Two-dimensional motions, projectile trajectories, and Newton’s core acceleration laws.',
            'amDesc': 'የአቅርቦት መስመር ኪነማቲክስ፣ የፕሮጀክታይል እንቅስቃሴ እና የኒውተን የጉልበት ህግጋት።',
          },
          {
            'id': 'phys_u3',
            'grade': widget.grade,
            'enUnit': 'Unit 3: Work, Energy & Power',
            'amUnit': 'ክፍል 3: ስራ፣ ጉልበት እና ሃይል',
            'enDesc': 'Conservation thresholds, potential fields, collision mechanics, and efficiency calculations.',
            'amDesc': 'የእምቅ ሃይል ክምችት፣ የመጋጨት መካኒክስ እና የውጤታማነት ስሌቶች።',
          },
          {
            'id': 'phys_u4',
            'grade': widget.grade,
            'enUnit': 'Unit 4: Rotational Motion & Gravity',
            'amUnit': 'ክፍል 4: ሽክርክሪት እንቅስቃሴ እና የስበት ኃይል',
            'enDesc': 'Angular pathways, torque balances, center of gravity, and moment of inertia formulas.',
            'amDesc': 'የማዕዘን ጉዞ፣ ቶርክ (ሽክርክሪት ኃይል) እና የመዞሪያ ግትርነት ስሌት።',
          },
          {
            'id': 'phys_u5',
            'grade': widget.grade,
            'enUnit': 'Unit 5: Thermodynamics & Heat Systems',
            'amUnit': 'ክፍል 5: ቴርሞዳይናሚክስ እና ሙቀት',
            'enDesc': 'Heat exchange equations, internal systems state energy, and thermodynamic efficiency.',
            'amDesc': 'የሙቀት ዝውውር መለኪያዎች፣ የውስጣዊ ሃይል መጠን እና የቴርሞዳይናሚክስ ህጎች።',
          },
        ];

      case 'Chemistry':
        if (widget.grade == 9) {
          return [
            {
              'id': 'chem_u1',
              'grade': 9,
              'enUnit': 'Unit 1: Chemistry And Its Importance',
              'amUnit': 'Unit 1: Chemistry And Its Importance',
              'enDesc': 'The definition, branches, and importance of chemistry in society.',
              'amDesc': 'The definition, branches, and importance of chemistry in society.',
            },
            {
              'id': 'chem_u2',
              'grade': 9,
              'enUnit': 'Unit 2: Measurements And Scientific Methods',
              'amUnit': 'Unit 2: Measurements And Scientific Methods',
              'enDesc': 'Laboratory safety, scientific measurements, and unit conversions.',
              'amDesc': 'Laboratory safety, scientific measurements, and unit conversions.',
            },
            {
              'id': 'chem_u3',
              'grade': 9,
              'enUnit': 'Unit 3: Structure Of The Atom',
              'amUnit': 'Unit 3: Structure Of The Atom',
              'enDesc': 'History of atomic theory, subatomic particles, and electronic configuration.',
              'amDesc': 'History of atomic theory, subatomic particles, and electronic configuration.',
            },
            {
              'id': 'chem_u4',
              'grade': 9,
              'enUnit': 'Unit 4: Periodic Classification Of Elements',
              'amUnit': 'Unit 4: Periodic Classification Of Elements',
              'enDesc': 'Trends in periodic tables, groups, periods, and periodic properties.',
              'amDesc': 'Trends in periodic tables, groups, periods, and periodic properties.',
            },
            {
              'id': 'chem_u5',
              'grade': 9,
              'enUnit': 'Unit 5: Chemical Bonding',
              'amUnit': 'Unit 5: Chemical Bonding',
              'enDesc': 'Understanding ionic, covalent, and metallic bonds.',
              'amDesc': 'Understanding ionic, covalent, and metallic bonds.',
            },
          ];
        }
        if (widget.grade == 10) {
          return [
            {
              'id': 'chem_u1',
              'grade': 10,
              'enUnit': 'Unit 1: Introduction to Organic Chemistry',
              'amUnit': 'ክፍል 1: የኦርጋኒክ ኬሚስትሪ መግቢያ',
              'enDesc': 'Classification, nomenclature, properties, and reactions of hydrocarbons.',
              'amDesc': 'የሃይድሮካርቦን ምደባ ፣ ስያሜ ፣ ባህሪዎች እና ግብረመልሶች።',
            },
            {
              'id': 'chem_u2',
              'grade': 10,
              'enUnit': 'Unit 2: Important Inorganic Compounds',
              'amUnit': 'ክፍል 2: አስፈላጊ ኢ-ኦርጋኒክ ውህዶች',
              'enDesc': 'Oxides, acids, bases, salts, and their properties and applications.',
              'amDesc': 'ኦክሳይዶች፣ አሲዶች፣ ቤዝ፣ ጨዎችን፣ እና ባህሪያቸው እና አተገባበሩ።',
            },
            {
              'id': 'chem_u3',
              'grade': 10,
              'enUnit': 'Unit 3: Electrochemistry',
              'amUnit': 'ክፍል 3: ኤሌክትሮኬሚስትሪ',
              'enDesc': 'Electrochemical cells, electrolysis, Faraday\'s laws, and battery technology.',
              'amDesc': 'ኤሌክትሮኬሚካዊ ህዋሶች፣ ኤሌክትሮሊሲስ፣ የፋራዳይ ህጎች እና የባትሪ ቴክኖሎጂ።',
            },
            {
              'id': 'chem_u4',
              'grade': 10,
              'enUnit': 'Unit 4: Chemistry in Industry and Environmental Pollution',
              'amUnit': 'ክፍል 4: ኬሚስትሪ በኢንዱስትሪ እና አካባቢ ብክለት',
              'enDesc': 'Industrial chemical processes, natural resource utilization, and pollution mitigation.',
              'amDesc': 'የኢንዱስትሪ ኬሚካዊ ሂደቶች ፣ የተፈጥሮ ሀብቶች አጠቃቀም እና ብክለትን መከላከል።',
            },
          ];
        }
        if (widget.grade == 11) {
          return [
            {
              'id': 'chem_u1',
              'grade': 11,
              'enUnit': 'Unit 1: Atomic Structure and Periodic Table',
              'amUnit': 'ክፍል 1: የአቶም መዋቅር እና ወቅታዊ ሰንጠረዥ',
              'enDesc': 'Quantum mechanical model, electronic configurations, and periodic properties.',
              'amDesc': 'የኳንተም ሜካኒካል ሞዴል፣ የኤሌክትሮን ውቅሮች እና ወቅታዊ ባህሪያት።',
            },
            {
              'id': 'chem_u2',
              'grade': 11,
              'enUnit': 'Unit 2: Chemical Bonding and Structure',
              'amUnit': 'ክፍል 2: ኬሚካዊ ትስስር እና መዋቅር',
              'enDesc': 'Ionic, covalent, metallic bonding, molecular geometry, and intermolecular forces.',
              'amDesc': 'አዮኒክ፣ ኮቫለንት፣ ሜታሊክ ቦንድንግ፣ ሞለኪውላር ጂኦሜትሪ እና የኢንተር-ሞለኪውላር ሃይሎች።',
            },
            {
              'id': 'chem_u3',
              'grade': 11,
              'enUnit': 'Unit 3: Physical States of Matter',
              'amUnit': 'ክፍል 3: የማተር አካላዊ ሁኔታዎች',
              'enDesc': 'Gases, liquids, solids, kinetic molecular theory, and phase changes.',
              'amDesc': 'ጋዞች, ፈሳሾች, ጠጣሮች, የኪነቲክ ሞለኪውላር ቲዎሪ እና ደረጃ ለውጦች.',
            },
            {
              'id': 'chem_u4',
              'grade': 11,
              'enUnit': 'Unit 4: Chemical Kinetics',
              'amUnit': 'ክፍል 4: ኬሚካዊ ኪነቲክስ',
              'enDesc': 'Rate of reaction, factors affecting rate, collision theory, and reaction mechanism.',
              'amDesc': 'የምላሽ መጠን, ፍጥነት ላይ ተጽዕኖ የሚያሳድሩ ምክንያቶች, የግጭት ቲዎሪ እና የምላሽ ዘዴ.',
            },
            {
              'id': 'chem_u5',
              'grade': 11,
              'enUnit': 'Unit 5: Chemical Equilibrium',
              'amUnit': 'ክፍል 5: ኬሚካዊ ሚዛን',
              'enDesc': 'Reversible reactions, equilibrium constant, Le Chatelier\'s principle, and ionic equilibrium.',
              'amDesc': 'ሊመለሱ የሚችሉ ግብረመልሶች፣ ሚዛናዊ ቋሚ፣ የሌ ሻተሌየር መርህ እና አዮኒክ ሚዛን።',
            },
            {
              'id': 'chem_u6',
              'grade': 11,
              'enUnit': 'Unit 6: Solutions',
              'amUnit': 'ክፍል 6: መፍትሄዎች (ሶሉሽኖች)',
              'enDesc': 'Types of solutions, solubility, concentration units, and colligative properties.',
              'amDesc': 'የመፍትሄ ዓይነቶች, መሟሟት, የትኩረት ክፍሎች እና የመፍትሄዎች ባህሪያት.',
            },
          ];
        }
        if (widget.grade == 12) {
          return [
            {
              'id': 'chem_u1',
              'grade': 12,
              'enUnit': 'Unit 1: Acid-Base Equilibria',
              'amUnit': 'ክፍል 1: አሲድ-ቤዝ ሚዛኖች',
              'enDesc': 'Acid-base concepts, strength, pH calculations, buffer solutions, and hydrolysis of salts.',
              'amDesc': 'የአሲድ-ቤዝ ጽንሰ-ሐሳቦች, ጥንካሬ, የፒኤች ስሌቶች, የመከላከያ (ባፈር) መፍትሄዎች.',
            },
            {
              'id': 'chem_u2',
              'grade': 12,
              'enUnit': 'Unit 2: Electrochemistry',
              'amUnit': 'ክፍል 2: ኤሌክትሮኬሚስትሪ',
              'enDesc': 'Galvanic cells, standard electrode potentials, Nernst equation, electrolysis, and corrosion.',
              'amDesc': 'የጋልቫኒክ ህዋሶች, ኤሌክትሮድ እምቅ, ኔርነስት እኩልታ, ኤሌክትሮሊሲስ እና ዝገት.',
            },
            {
              'id': 'chem_u3',
              'grade': 12,
              'enUnit': 'Unit 3: Industrial Chemistry',
              'amUnit': 'ክፍል 3: የኢንዱስትሪ ኬሚስትሪ',
              'enDesc': 'Manufacture of ammonia, sulfuric acid, nitric acid, sodium hydroxide, and environmental aspects.',
              'amDesc': 'የአሞኒያ, ሰልፈሪክ አሲድ, ናይትሪክ አሲድ, ሶዲየም ሃይድሮክሳይድ ማምረት.',
            },
            {
              'id': 'chem_u4',
              'grade': 12,
              'enUnit': 'Unit 4: Organic Chemistry',
              'amUnit': 'ክፍል 4: ኦርጋኒክ ኬሚስትሪ',
              'enDesc': 'Structure, nomenclature, reactions of alcohols, ethers, aldehydes, ketones, and carboxylic acids.',
              'amDesc': 'የአልኮል መጠጦች, ኤተር, አልዲኢይድ, ኬቶን, ካርቦክሲሊክ አሲዶች አወቃቀር እና ምላሽ.',
            },
            {
              'id': 'chem_u5',
              'grade': 12,
              'enUnit': 'Unit 5: Polymers and Biomolecules',
              'amUnit': 'ክፍል 5: ፖሊመሮች እና ባዮሞለኪውሎች',
              'enDesc': 'Natural and synthetic polymers, carbohydrates, proteins, lipids, and nucleic acids.',
              'amDesc': 'ተፈጥሯዊ እና ሰው ሰራሽ ፖሊመሮች, ካርቦሃይድሬትስ, ፕሮቲኖች, ቅባቶች እና ኑክሊክ አሲዶች.',
            },
          ];
        }
        return [
          {
            'id': 'chem_u1',
            'grade': widget.grade,
            'enUnit': 'Unit 1: Atomic Structure',
            'amUnit': 'ክፍል 1: የአቶም መዋቅር',
            'enDesc': 'Quantum numbers, orbital levels configuration, trends on periodic tables.',
            'amDesc': 'የኳንተም ቁጥሮች፣ የኤሌክትሮን ምደባ መዋቅር እና የጊዜያዊ ሰንጠረዥ ባህሪያት።',
          },
          {
            'id': 'chem_u2',
            'grade': widget.grade,
            'enUnit': 'Unit 2: Chemical Bonding',
            'amUnit': 'ክፍል 2: ኬሚካዊ ትስስር',
            'enDesc': 'Ionic lattices, covalent molecular geometries, and electronegativity.',
            'amDesc': 'አዮኒክ እና ኮቫለንት ትስስሮች፣ የሞለኪውሎች ውቅር እና የኤሌክትሮኔጋቲቪቲ ልዩነቶች።',
          },
          {
            'id': 'chem_u3',
            'grade': widget.grade,
            'enUnit': 'Unit 3: Stoichiometry & Formula Mass',
            'amUnit': 'ክፍል 3: ስቶይኪዮሜትሪ',
            'enDesc': 'The mole concept, limiting reactant calculations, and yields.',
            'amDesc': 'የሞል ጽንሰ-ሀሳብ፣ ወሳኝ አፀፋዊ ንጥረ ነገሮች እና የተመጣጠነ ኬሚካዊ ስሌቶች።',
          },
          {
            'id': 'chem_u4',
            'grade': widget.grade,
            'enUnit': 'Unit 4: Chemical Equilibria & Acids',
            'amUnit': 'ክፍል 4: ኬሚካዊ ሚዛን እና አሲዶች',
            'enDesc': 'Le Chatelier shifts, solubility product index, pH calculations, and neutralisations.',
            'amDesc': 'የለ ሻተሌየር መርህ፣ የፒኤች (pH) ስሌት እና የአሲድ-ቤዝ ገለልተኛ መሆን ሂደቶች።',
          },
          {
            'id': 'chem_u5',
            'grade': widget.grade,
            'enUnit': 'Unit 5: Introduction to Organic Chemistry',
            'amUnit': 'ክፍል 5: የኦርጋኒክ ኬሚስትሪ መግቢያ',
            'enDesc': 'IUPAC naming conventions of hydrocarbons, structural isomers, and properties.',
            'amDesc': 'የሃይድሮካርቦኖች የአሰያየም ሥርዓት (IUPAC)፣ አይሶመርስ እና አልኬን ባህሪዎች።',
          },
        ];

      case 'Geography':
        if (widget.grade == 9) {
          return [
            {
              'id': 'geo_u1',
              'grade': 9,
              'enUnit': 'Unit 1: Geological History And Topography Of Ethiopia',
              'amUnit': 'Unit 1: Geological History And Topography Of Ethiopia',
              'enDesc': 'Exploring the geological formation and landforms of Ethiopia.',
              'amDesc': 'Exploring the geological formation and landforms of Ethiopia.',
            },
            {
              'id': 'geo_u2',
              'grade': 9,
              'enUnit': 'Unit 2: Climate Of Ethiopia',
              'amUnit': 'Unit 2: Climate Of Ethiopia',
              'enDesc': 'Understanding key climate zones, rainfall patterns, and seasons.',
              'amDesc': 'Understanding key climate zones, rainfall patterns, and seasons.',
            },
            {
              'id': 'geo_u3',
              'grade': 9,
              'enUnit': 'Unit 3: Natural Resource Base Of Ethiopia',
              'amUnit': 'Unit 3: Natural Resource Base Of Ethiopia',
              'enDesc': 'Overview of soil, water, forest, and mineral resources.',
              'amDesc': 'Overview of soil, water, forest, and mineral resources.',
            },
            {
              'id': 'geo_u4',
              'grade': 9,
              'enUnit': 'Unit 4: Population And Demographic Characteristics Of Ethiopia',
              'amUnit': 'Unit 4: Population And Demographic Characteristics Of Ethiopia',
              'enDesc': 'Demographic dynamics, growth rates, and population distribution.',
              'amDesc': 'Demographic dynamics, growth rates, and population distribution.',
            },
            {
              'id': 'geo_u5',
              'grade': 9,
              'enUnit': 'Unit 5: Major Economic And Cultural Activities In Ethiopia',
              'amUnit': 'Unit 5: Major Economic And Cultural Activities In Ethiopia',
              'enDesc': 'Understanding agricultural, industrial, and heritage sectors.',
              'amDesc': 'Understanding agricultural, industrial, and heritage sectors.',
            },
            {
              'id': 'geo_u6',
              'grade': 9,
              'enUnit': 'Unit 6: Human – Natural Environment Interactions In Ethiopia',
              'amUnit': 'Unit 6: Human – Natural Environment Interactions In Ethiopia',
              'enDesc': 'How humans adapt to and modify the natural environment.',
              'amDesc': 'How humans adapt to and modify the natural environment.',
            },
            {
              'id': 'geo_u7',
              'grade': 9,
              'enUnit': 'Unit 7: Contemporary Geographic Issues And Public Concerns In Ethiopia',
              'amUnit': 'Unit 7: Contemporary Geographic Issues And Public Concerns In Ethiopia',
              'enDesc': 'Environmental challenges, urbanization, and sustainable policies.',
              'amDesc': 'Environmental challenges, urbanization, and sustainable policies.',
            },
            {
              'id': 'geo_u8',
              'grade': 9,
              'enUnit': 'Unit 8: Geographic Inquiry Skills And Techniques',
              'amUnit': 'Unit 8: Geographic Inquiry Skills And Techniques',
              'enDesc': 'Developing map reading, navigation, and fieldwork techniques.',
              'amDesc': 'Developing map reading, navigation, and fieldwork techniques.',
            },
          ];
        }
        if (widget.grade == 10) {
          return [
            {
              'id': 'geo_u1',
              'grade': 10,
              'enUnit': 'Unit 1: Map Reading and Interpretation',
              'amUnit': 'ክፍል 1: የካርታ ንባብ እና ትርጓሜ',
              'enDesc': 'Grid systems, map marginal information, scales, and measuring distances.',
              'amDesc': 'የግሪድ ሥርዓቶች፣ የካርታ ህዳግ መረጃዎች፣ ልኬቶች እና ርቀቶችን መለካት።',
            },
            {
              'id': 'geo_u2',
              'grade': 10,
              'enUnit': 'Unit 2: Physical Geography of Ethiopia and the Horn',
              'amUnit': 'ክፍል 2: የኢትዮጵያ እና የቀንድ አካላዊ ጂኦግራፊ',
              'enDesc': 'Geological structure, relief, drainage systems, climate, and soils.',
              'amDesc': 'ጂኦሎጂካዊ መዋቅር፣ የመሬት አቀማመጥ፣ የውሃ ፍሰት ስርዓቶች፣ አየር ንብረት እና አፈር።',
            },
            {
              'id': 'geo_u3',
              'grade': 10,
              'enUnit': 'Unit 3: Population and Economic Activities of Ethiopia',
              'amUnit': 'ክፍል 3: የኢትዮጵያ የህዝብ ቁጥር እና ኢኮኖሚያዊ እንቅስቃሴዎች',
              'enDesc': 'Demographic characteristics, economic sectors including agriculture, industry, and services.',
              'amDesc': 'የህዝብ ስብጥር ባህሪያት, ግብርና, ኢንዱስትሪ እና አገልግሎቶችን ጨምሮ የኢኮኖሚ ዘርፎች.',
            },
            {
              'id': 'geo_u4',
              'grade': 10,
              'enUnit': 'Unit 4: Environmental Issues and Management in Ethiopia',
              'amUnit': 'ክፍል 4: አካባቢያዊ ጉዳዮች እና አስተዳደር በኢትዮጵያ',
              'enDesc': 'Natural hazards, deforestation, soil erosion, climate change, and conservation efforts.',
              'amDesc': 'ተፈጥሮአዊ አደጋዎች፣ የደን መጨፍጨፍ፣ የአፈር መሸርሸር፣ የአየር ንብረት ለውጥ እና ጥበቃ።',
            },
          ];
        }
        if (widget.grade == 11) {
          return [
            {
              'id': 'geo_u1',
              'grade': 11,
              'enUnit': 'Unit 1: Map Reading and Interpretation',
              'amUnit': 'ክፍል 1: የካርታ ንባብ እና ትርጓሜ',
              'enDesc': 'Contour structures, scales comparison, grid symbols identification, and elevation slopes.',
              'amDesc': 'የኮንቱር መስመሮች፣ የካርታ ልኬቶች እና የከፍታዎች የቁልቁለት መጠን መመልከት።',
            },
            {
              'id': 'geo_u2',
              'grade': 11,
              'enUnit': 'Unit 2: Lithosphere and Landforms',
              'amUnit': 'ክፍል 2: ሊቶስፌር እና የመሬት ገጽታዎች',
              'enDesc': 'Plate tectonic dynamics, continental movements, weathering cycles and soil profiles.',
              'amDesc': 'የቴክቶኒክ ሳህኖች እንቅስቃሴ፣ የመሬት መንቀጥቀጥ እና የአፈር መሸርሸር ዑደቶች።',
            },
            {
              'id': 'geo_u3',
              'grade': 11,
              'enUnit': 'Unit 3: Weather & Climate of Africa',
              'amUnit': 'ክፍል 3: የአፍሪካ የአየር ሁኔታ እና የአየር ንብረት',
              'enDesc': 'ITCZ air movements, climatic classifications, vegetation distribution, and drought factors.',
              'amDesc': 'የአየር ግፊት እና የአየር ንብረት ክልሎች፣ የአፍሪካ ደኖች ተደራሽነት እና ድርቅ።',
            },
            {
              'id': 'geo_u4',
              'grade': 11,
              'enUnit': 'Unit 4: Human Demographics & Economic Growth',
              'amUnit': 'ክፍል 4: የህዝብ ስብጥር እና ኢኮኖሚያዊ ዕድገት',
              'enDesc': 'Fertility models, urban migrative patterns, and primary resource exploitation in Ethiopia.',
              'amDesc': 'የህዝብ ብዛት ተለዋዋጭነት፣ የከተማ ፍልሰት እና የኢትዮጵያ ኢኮኖሚ ሴክተሮች።',
            },
            {
              'id': 'geo_u5',
              'grade': 11,
              'enUnit': 'Unit 5: GIS & Remote Sensing Principles',
              'amUnit': 'ክፍል 5: ጂአይኤስ (GIS) እና የርቀት ምርመራ',
              'enDesc': 'Vector vs Raster attributes, satellite photography data overlaying, mapping softwares info.',
              'amDesc': 'የቬክተር እና ራስተር ዳታ ሞዴሎች፣ የሳተላይት ምስሎች እና የካርታ አሰራር።',
            },
          ];
        }
        if (widget.grade == 12) {
          return [
            {
              'id': 'geo_u1',
              'grade': 12,
              'enUnit': 'Unit 1: Climate and Soil Systems',
              'amUnit': 'ክፍል 1: የአየር ንብረት እና የአፈር ስርዓቶች',
              'enDesc': 'Global climate systems, factors influencing climate, and global soil classifications.',
              'amDesc': 'ዓለም አቀፍ የአየር ንብረት ሥርዓቶች፣ የአየር ንብረት ተጽዕኖ ፈጣሪዎች እና የአፈር ምደባ።',
            },
            {
              'id': 'geo_u2',
              'grade': 12,
              'enUnit': 'Unit 2: Natural Vegetation and Wild Animals',
              'amUnit': 'ክፍል 2: ተፈጥሮአዊ እፅዋት እና የዱር እንስሳት',
              'enDesc': 'Distribution of natural vegetation, wild animal diversity, and conservation strategies.',
              'amDesc': 'የተፈጥሮ እፅዋት ስርጭት ፣ የዱር እንስሳት ብዝሃነት እና ጥበቃ ስልቶች።',
            },
            {
              'id': 'geo_u3',
              'grade': 12,
              'enUnit': 'Unit 3: Economic and Social Systems',
              'amUnit': 'ክፍል 3: ኢኮኖሚያዊ እና ማህበራዊ ስርዓቶች',
              'enDesc': 'Sectors of global economy, globalization, development indices, and international trade.',
              'amDesc': 'የአለም አቀፍ ኢኮኖሚ ዘርፎች፣ ግሎባላይዜሽን፣ የልማት አመልካቾች እና የንግድ ግንኙነት።',
            },
            {
              'id': 'geo_u4',
              'grade': 12,
              'enUnit': 'Unit 4: GIS and Field Work Applications',
              'amUnit': 'ክፍል 4: ጂአይኤስ እና የመስክ ስራ ትግበራዎች',
              'enDesc': 'Hands-on GIS mapping, spatial query, database design, and fieldwork practices.',
              'amDesc': 'የጂአይኤስ ካርታ ስራ፣ የቦታ ጥያቄ፣ የመረጃ ቋት ንድፍ እና የመስክ ስራ ልምምዶች።',
            },
          ];
        }
        return [
          {
            'id': 'geo_u1',
            'grade': widget.grade,
            'enUnit': 'Unit 1: Map Reading and Interpretation',
            'amUnit': 'ክፍል 1: የካርታ ንባብ እና ትርጓሜ',
            'enDesc': 'Contour structures, scales comparison, grid symbols identification, and elevation slopes.',
            'amDesc': 'የኮንቱር መስመሮች፣ የካርታ ልኬቶች እና የከፍታዎች የቁልቁለት መጠን መመልከት።',
          },
          {
            'id': 'geo_u2',
            'grade': widget.grade,
            'enUnit': 'Unit 2: Lithosphere and Landforms',
            'amUnit': 'ክፍል 2: ሊቶስፌር እና የመሬት ገጽታዎች',
            'enDesc': 'Plate tectonic dynamics, continental movements, weathering cycles and soil profiles.',
            'amDesc': 'የቴክቶኒክ ሳህኖች እንቅስቃሴ፣ የመሬት መንቀጥቀጥ እና የአፈር መሸርሸር ዑደቶች።',
          },
          {
            'id': 'geo_u3',
            'grade': widget.grade,
            'enUnit': 'Unit 3: Weather & Climate of Africa',
            'amUnit': 'ክፍል 3: የአፍሪካ የአየር ሁኔታ እና የአየር ንብረት',
            'enDesc': 'ITCZ air movements, climatic classifications, vegetation distribution, and drought factors.',
            'amDesc': 'የአየር ግፊት እና የአየር ንብረት ክልሎች፣ የአፍሪካ ደኖች ተደራሽነት እና ድርቅ።',
          },
          {
            'id': 'geo_u4',
            'grade': widget.grade,
            'enUnit': 'Unit 4: Human Demographics & Economic Growth',
            'amUnit': 'ክፍል 4: የህዝብ ስብጥር እና ኢኮኖሚያዊ ዕድገት',
            'enDesc': 'Fertility models, urban migrative patterns, and primary resource exploitation in Ethiopia.',
            'amDesc': 'የህዝብ ብዛት ተለዋዋጭነት፣ የከተማ ፍልሰት እና የኢትዮጵያ ኢኮኖሚ ሴክተሮች።',
          },
          {
            'id': 'geo_u5',
            'grade': widget.grade,
            'enUnit': 'Unit 5: GIS & Remote Sensing Principles',
            'amUnit': 'ክፍል 5: ጂአይኤስ (GIS) እና የርቀት ምርመራ',
            'enDesc': 'Vector vs Raster attributes, satellite photography data overlaying, mapping softwares info.',
            'amDesc': 'የቬክተር እና ራስተር ዳታ ሞዴሎች፣ የሳተላይት ምስሎች እና የካርታ አሰራር።',
          },
        ];

      case 'History':
        if (widget.grade == 9) {
          return [
            {
              'id': 'hist_u1',
              'grade': 9,
              'enUnit': 'Unit 1: The Discipline of History and Human Evolution',
              'amUnit': 'Unit 1: The Discipline of History and Human Evolution',
              'enDesc': 'The nature of historical study and stages of human origin.',
              'amDesc': 'The nature of historical study and stages of human origin.',
            },
            {
              'id': 'hist_u2',
              'grade': 9,
              'enUnit': 'Unit 2: Ancient World Civilizations up to c. 500 AD',
              'amUnit': 'Unit 2: Ancient World Civilizations up to c. 500 AD',
              'enDesc': 'Exploring Egypt, Mesopotamia, Greece, and Rome civilizational systems.',
              'amDesc': 'Exploring Egypt, Mesopotamia, Greece, and Rome civilizational systems.',
            },
            {
              'id': 'hist_u3',
              'grade': 9,
              'enUnit': 'Unit 3: Peoples and States in Ethiopia and the Horn to the end of 13th Century',
              'amUnit': 'Unit 3: Peoples and States in Ethiopia and the Horn to the end of 13th Century',
              'enDesc': 'Trade routes, religions, and states in the Horn of Africa.',
              'amDesc': 'Trade routes, religions, and states in the Horn of Africa.',
            },
            {
              'id': 'hist_u4',
              'grade': 9,
              'enUnit': 'Unit 4: The Middle Ages and Early Modern World, C. 500 to 1750s',
              'amUnit': 'Unit 4: The Middle Ages and Early Modern World, C. 500 to 1750s',
              'enDesc': 'Feudalism, Islamic states, and European exploration voyages.',
              'amDesc': 'Feudalism, Islamic states, and European exploration voyages.',
            },
            {
              'id': 'hist_u5',
              'grade': 9,
              'enUnit': 'Unit 5: Peoples and States of Africa to 1500',
              'amUnit': 'Unit 5: Peoples and States of Africa to 1500',
              'enDesc': 'Socio-political structures of early African kingdoms.',
              'amDesc': 'Socio-political structures of early African kingdoms.',
            },
            {
              'id': 'hist_u6',
              'grade': 9,
              'enUnit': 'Unit 6: Africa and the Outside World 1500- 1880s',
              'amUnit': 'Unit 6: Africa and the Outside World 1500- 1880s',
              'enDesc': 'Atlantic slave trade, early contacts, and European colonialism attempts.',
              'amDesc': 'Atlantic slave trade, early contacts, and European colonialism attempts.',
            },
            {
              'id': 'hist_u7',
              'grade': 9,
              'enUnit': 'Unit 7: States, Principalities, Population Movements & Interactions in Ethiopia 13th to Mid-16th C.',
              'amUnit': 'Unit 7: States, Principalities, Population Movements & Interactions in Ethiopia 13th to Mid-16th C.',
              'enDesc': 'The Christian kingdom, Solomonic dynasty, and internal interactions.',
              'amDesc': 'The Christian kingdom, Solomonic dynasty, and internal interactions.',
            },
            {
              'id': 'hist_u8',
              'grade': 9,
              'enUnit': 'Unit 8: Political, Social, and Economic Processes in Ethiopia Mid-16th to Mid-19th C.',
              'amUnit': 'Unit 8: Political, Social, and Economic Processes in Ethiopia Mid-16th to Mid-19th C.',
              'enDesc': 'Gondar era, Zemene Mesafint, and regional states dynamics.',
              'amDesc': 'Gondar era, Zemene Mesafint, and regional states dynamics.',
            },
            {
              'id': 'hist_u9',
              'grade': 9,
              'enUnit': 'Unit 9: The Age of Revolutions 1750s to 1815',
              'amUnit': 'Unit 9: The Age of Revolutions 1750s to 1815',
              'enDesc': 'The French and American revolutions and Napoleonic era.',
              'amDesc': 'The French and American revolutions and Napoleonic era.',
            },
          ];
        }
        if (widget.grade == 10) {
          return [
            {
              'id': 'hist_u1',
              'grade': 10,
              'enUnit': 'Unit 1: Peoples and States in Ethiopia and the Horn, 1855 to 1991',
              'amUnit': 'ክፍል 1: ህዝቦች এবং መንግስታት በኢትዮጵያ እና በቀንድ፣ 1855 እስከ 1991',
              'enDesc': 'Unification of Ethiopia, battle of Adwa, Italian occupation, post-war reconstruction, and the Derg regime.',
              'amDesc': 'የኢትዮጵያ አንድነት መፈጠር፣ የአድዋ ጦርነት፣ የኢጣሊያ ወረራ፣ የድህረ-ጦርነት ግንባታ እና የደርግ አገዛዝ።',
            },
            {
              'id': 'hist_u2',
              'grade': 10,
              'enUnit': 'Unit 2: History of Africa since 1880s',
              'amUnit': 'ክፍል 2: የአፍሪካ ታሪክ ከ1880ዎቹ ጀምሮ',
              'enDesc': 'Scramble for Africa, colonial administration, anti-colonial resistance, and the decolonization process.',
              'amDesc': 'የአፍሪካ ቅርጫ፣ የቅኝ ግዛት አስተዳደር፣ ፀረ-ቅኝ ግዛት ትግል እና የቅኝ ግዛት ማክተም ሂደት።',
            },
            {
              'id': 'hist_u3',
              'grade': 10,
              'enUnit': 'Unit 3: World Wars and Post-War World Developments',
              'amUnit': 'ክፍል 3: የአለም ጦርነቶች እና ከጦርነቱ በኋላ የታዩ እድገቶች',
              'enDesc': 'Causes and consequences of WWI and WWII, League of Nations, UN, Cold War, and regional integration.',
              'amDesc': 'የአንደኛውና ሁለተኛው የዓለም ጦርነት መንስኤዎችና መዘዞች፣ ሊግ ኦፍ ኔሽንስ፣ የተባበሩት መንግሥታት ድርጅት፣ የቀዝቃዛው ጦርነት።',
            },
          ];
        }
        if (widget.grade == 11) {
          return [
            {
              'id': 'hist_u1',
              'grade': 11,
              'enUnit': 'Unit 1: Ancient and Medieval Civilizations',
              'amUnit': 'ክፍል 1: ጥንታዊ እና የመካከለኛው ዘመን ስልጣኔዎች',
              'enDesc': 'Major civilizations of Aksum, Zagwe, Damot, Solomonic dynasty, and Islamic sultanates.',
              'amDesc': 'የአክሱም፣ የዛግዌ፣ የዳሞት፣ የሰለሞን ስርወ መንግስት እና የእስልምና ሱልጣኔቶች ስልጣኔዎች።',
            },
            {
              'id': 'hist_u2',
              'grade': 11,
              'enUnit': 'Unit 2: Early Modern History and Revolutions',
              'amUnit': 'ክፍል 2: ቀደምት ዘመናዊ ታሪክ እና አብዮቶች',
              'enDesc': 'Industrial revolution, American and French revolutions, rise of capitalism and nationalism.',
              'amDesc': 'የኢንዱስትሪ አብዮት፣ የአሜሪካ እና የፈረንሳይ አብዮቶች፣ የካፒታሊዝም እና የብሔርተኝነት መነሳት።',
            },
            {
              'id': 'hist_u3',
              'grade': 11,
              'enUnit': 'Unit 3: Modern Ethiopian History, 1855-1974',
              'amUnit': 'ክፍል 3: የዘመናዊት ኢትዮጵያ ታሪክ፣ 1855-1974',
              'enDesc': 'State centralization under Tewodros II, Yohannes IV, Menelik II, Haile Selassie I, and socio-economic changes.',
              'amDesc': 'የሀገር ማዕከላዊነት በቴዎድሮስ 2ኛ፣ ዮሐንስ 4ኛ፣ ምኒልክ 2ኛ፣ ኃይለ ሥላሴ 1ኛ፣ እና ማህበራዊና ኢኮኖሚያዊ ለውጦች።',
            },
          ];
        }
        if (widget.grade == 12) {
          return [
            {
              'id': 'hist_u1',
              'grade': 12,
              'enUnit': 'Unit 1: World War I and Interwar Period',
              'amUnit': 'ክፍል 1: አንደኛው የዓለም ጦርነት እና በጦርነቶች መካከል ያለው ጊዜ',
              'enDesc': 'World War I, Russian Revolution, Great Depression, rise of fascism, and League of Nations collapse.',
              'amDesc': 'የአንደኛው የዓለም ጦርነት, የሩሲያ አብዮት, ታላቁ የኢኮኖሚ ቀውስ, የፋሺዝም መነሳት.',
            },
            {
              'id': 'hist_u2',
              'grade': 12,
              'enUnit': 'Unit 2: World War II and the Cold War',
              'amUnit': 'ክፍል 2: ሁለተኛው የዓለም ጦርነት እና የቀዝቃዛው ጦርነት',
              'enDesc': 'World War II alliances, battles, atomic bomb, UN creation, and Cold War block rivalry.',
              'amDesc': 'የሁለተኛው የዓለም ጦርነት ጥምረት፣ ጦርነቶች፣ የአቶሚክ ቦምብ፣ የተባበሩት መንግሥታት ድርጅት መፈጠር እና የቀዝቃዛው ጦርነት።',
            },
            {
              'id': 'hist_u3',
              'grade': 12,
              'enUnit': 'Unit 3: Post-Cold War Global Developments',
              'amUnit': 'ክፍል 3: ከቀዝቃዛው ጦርነት በኋላ ዓለም አቀፍ እድገቶች',
              'enDesc': 'Soviet Union collapse, globalization, terrorism, rise of China, and regional integrations.',
              'amDesc': 'የሶቪየት ህብረት መፈራረስ, ግሎባላይዜሽን, ሽብርተኝነት, የቻይና መነሳት እና ክልላዊ ውህደቶች.',
            },
            {
              'id': 'hist_u4',
              'grade': 12,
              'enUnit': 'Unit 4: Ethiopian History from 1974 to Present',
              'amUnit': 'ክፍል 4: የኢትዮጵያ ታሪክ ከ1974 እስከ አሁን',
              'enDesc': 'The 1974 revolution, the Derg military administration, the transitional government, and the FDRE constitution.',
              'amDesc': 'የ1974ቱ አብዮት፣ የደርግ ወታደራዊ አስተዳደር፣ የሽግግር መንግስት እና የኢፌዴሪ ህገ መንግስት።',
            },
          ];
        }
        return [
          {
            'id': 'hist_u1',
            'grade': widget.grade,
            'enUnit': 'Unit 1: Human Beginnings inside East Africa',
            'amUnit': 'ክፍል 1: የሰዎች መገኛ በምስራቅ አፍሪካ',
            'enDesc': 'Palaeoanthropology discoveries, Australopithecus Afarensis (Lucy), stone-age tool developments.',
            'amDesc': 'የአርኪዮሎጂ ግኝቶች፣ ሉሲ (ድንቅነሽ) በአዋሽ ሸለቆ፣ የድንጋይ ዘመን መሳሪያዎች እድገት።',
          },
          {
            'id': 'hist_u2',
            'grade': widget.grade,
            'enUnit': 'Unit 2: The Aksumite Kingdom & Maritime Trade',
            'amUnit': 'ክፍል 2: የአክሱም ስርወ-መንግስት እና የባህር ንግድ',
            'enDesc': 'Rise of Aksum state, stone obelisks engineering, coinage systems, and early Christian introduction.',
            'amDesc': 'የአክሱም ስልጣኔ መነሳት፣ የሀውልቶች ጥበብ፣ የሳንቲም ዝውውር እና ክርስትና መስፋፋት።',
          },
          {
            'id': 'hist_u3',
            'grade': widget.grade,
            'enUnit': 'Unit 3: Medieval Kingdoms and Camel Caravan Routes',
            'amUnit': 'ክፍል 3: የመካከለኛው ዘመን መንግስታት እና የንግድ መስመሮች',
            'enDesc': 'Lasta, Zagwe dynasty, Solomonic restoration, Gondar period, caravan trade routes.',
            'amDesc': 'ላስታ እና የዛግዌ ስርወ መንግስት፣ የሰለሞናዊያን ስርወ መንግስት መመለስ፣ የጎንደር ዘመን እና የነጋዴዎች መስመሮች።',
          },
        ];

      case 'Civics':
        if (widget.grade == 9) {
          return [
            {
              'id': 'civ_u1',
              'grade': 9,
              'enUnit': 'Unit 1: Ethical Values',
              'amUnit': 'Unit 1: Ethical Values',
              'enDesc': 'Core moral principles, responsibilities, and civic ethics.',
              'amDesc': 'Core moral principles, responsibilities, and civic ethics.',
            },
            {
              'id': 'civ_u2',
              'grade': 9,
              'enUnit': 'Unit 2: The Culture Of Using Digital Technology',
              'amUnit': 'Unit 2: The Culture Of Using Digital Technology',
              'enDesc': 'Responsible use of digital resources, safety, and online citizenship.',
              'amDesc': 'Responsible use of digital resources, safety, and online citizenship.',
            },
            {
              'id': 'civ_u3',
              'grade': 9,
              'enUnit': 'Unit 3: Constitution And Constitutionalism',
              'amUnit': 'Unit 3: Constitution And Constitutionalism',
              'enDesc': 'Structure, features, and importance of constitutional law.',
              'amDesc': 'Structure, features, and importance of constitutional law.',
            },
            {
              'id': 'civ_u4',
              'grade': 9,
              'enUnit': 'Unit 4: Understanding Indigenous Knowledge',
              'amUnit': 'Unit 4: Understanding Indigenous Knowledge',
              'enDesc': 'Appreciating local traditional knowledge and community wisdom.',
              'amDesc': 'Appreciating local traditional knowledge and community wisdom.',
            },
            {
              'id': 'civ_u5',
              'grade': 9,
              'enUnit': 'Unit 5: Multiculturalism In Ethiopia',
              'amUnit': 'Unit 5: Multiculturalism In Ethiopia',
              'enDesc': 'Understanding cultural diversity and inclusive national identity.',
              'amDesc': 'Understanding cultural diversity and inclusive national identity.',
            },
            {
              'id': 'civ_u6',
              'grade': 9,
              'enUnit': 'Unit 6: National Unity Through Diversity',
              'amUnit': 'Unit 6: National Unity Through Diversity',
              'enDesc': 'Promoting peaceful co-existence and unity across ethnic groups.',
              'amDesc': 'Promoting peaceful co-existence and unity across ethnic groups.',
            },
            {
              'id': 'civ_u7',
              'grade': 9,
              'enUnit': 'Unit 7: Problem-Solving Skills',
              'amUnit': 'Unit 7: Problem-Solving Skills',
              'enDesc': 'Conflict resolution, critical thinking, and decision making.',
              'amDesc': 'Conflict resolution, critical thinking, and decision making.',
            },
            {
              'id': 'civ_u8',
              'grade': 9,
              'enUnit': 'Unit 8: Ethiopia’s Foreign Relations In East Africa',
              'amUnit': 'Unit 8: Ethiopia’s Foreign Relations In East Africa',
              'enDesc': 'Ethiopia\'s regional diplomatic policies and cooperative treaties.',
              'amDesc': 'Ethiopia\'s regional diplomatic policies and cooperative treaties.',
            },
          ];
        }
        if (widget.grade == 10) {
          return [
            {
              'id': 'civ_u1',
              'grade': 10,
              'enUnit': 'Unit 1: Democracy and Constitutionalism',
              'amUnit': 'ክፍል 1: ዲሞክራሲ እና ህገ-መንግስታዊነት',
              'enDesc': 'Principles of democracy, constitutional developments in Ethiopia, and human rights standards.',
              'amDesc': 'የዲሞክራሲ መርሆዎች, በኢትዮጵያ ውስጥ ህገ-መንግስታዊ እድገቶች እና የሰብአዊ መብቶች ደረጃዎች.',
            },
            {
              'id': 'civ_u2',
              'grade': 10,
              'enUnit': 'Unit 2: Active Citizenship',
              'amUnit': 'ክፍል 2: ንቁ ዜግነት',
              'enDesc': 'Civic participation, community engagement, ethical responsibility, and digital citizenship.',
              'amDesc': 'የዜግነት ተሳትፎ, የማህበረሰብ ተሳትፎ, የስነ-ምግባር ሃላፊነት እና ዲጂታል ዜግነት.',
            },
            {
              'id': 'civ_u3',
              'grade': 10,
              'enUnit': 'Unit 3: Rule of Law and Justice',
              'amUnit': 'ክፍል 3: የህግ የበላይነት እና ፍትህ',
              'enDesc': 'Core attributes of rule of law, anti-corruption policies, and conflict resolution systems.',
              'amDesc': 'የህግ የበላይነት ዋና ዋና ባህሪያት, የፀረ-ሙስና ፖሊሲዎች እና የግጭት አፈታት ስርዓቶች.',
            },
          ];
        }
        if (widget.grade == 11) {
          return [
            {
              'id': 'civ_u1',
              'grade': 11,
              'enUnit': 'Unit 1: Democratic & Constitutional Values',
              'amUnit': 'ክፍል 1: ዲሞክራሲያዊ እና ህገ-መንግስታዊ እሴቶች',
              'enDesc': 'Human rights concepts, citizens participation, rule of law, and democratic institutions.',
              'amDesc': 'የሰብአዊ መብቶች ጽንሰ-ሀሳብ፣ የተማሪዎች/ዜጎች ተሳትፎ፣ የህግ የበላይነት እና ዲሞክራሲያዊ ተቋማት።',
            },
            {
              'id': 'civ_u2',
              'grade': 11,
              'enUnit': 'Unit 2: Active Citizenship & Ethics',
              'amUnit': 'ክፍል 2: ንቁ ዜግነት እና ስነ-ምግባር',
              'enDesc': 'Social engagement, patriotic duties, volunteer activities, and civic responsibilities.',
              'amDesc': 'ማህበራዊ ተሳትፎ፣ የአገር ፍቅር ግዴታዎች፣ የበጎ ፈቃድ ስራዎች እና የዜግነት ኃላፊነቶች።',
            },
            {
              'id': 'civ_u3',
              'grade': 11,
              'enUnit': 'Unit 3: Government and Legal Structures',
              'amUnit': 'ክፍል 3: የመንግስት እና የስነ-ህግ መዋቅሮች',
              'enDesc': 'Three branches of government, regional state formations, and national constitution pillars.',
              'amDesc': 'ሶስቱ የመንግስት አካላት፣ የክልል መንግስታት አመሰራረት እና የህገ-መንግስት መሰረቶች።',
            },
          ];
        }
        if (widget.grade == 12) {
          return [
            {
              'id': 'civ_u1',
              'grade': 12,
              'enUnit': 'Unit 1: Federalism and Governance in Ethiopia',
              'amUnit': 'ክፍል 1: ፌደራሊዝም እና አስተዳደር በኢትዮጵያ',
              'enDesc': 'Features of Ethiopian federalism, power sharing between federal and regional states.',
              'amDesc': 'የኢትዮጵያ ፌደራሊዝም መገለጫዎች፣ በፌደራል እና በክልል መንግስታት መካከል ያለው የስልጣን ክፍፍል።',
            },
            {
              'id': 'civ_u2',
              'grade': 12,
              'enUnit': 'Unit 2: Human Rights and International Relations',
              'amUnit': 'ክፍል 2: ሰብአዊ መብቶች እና ዓለም አቀፍ ግንኙነቶች',
              'enDesc': 'International human rights treaties, Ethiopia\'s foreign relations policy and regional role.',
              'amDesc': 'ዓለም አቀፍ የሰብአዊ መብቶች ስምምነቶች፣ የኢትዮጵያ የውጭ ግንኙነት ፖሊሲ እና ቀጣናዊ ሚና።',
            },
            {
              'id': 'civ_u3',
              'grade': 12,
              'enUnit': 'Unit 3: Sustainable Development and Global Issues',
              'amUnit': 'ክፍል 3: ቀጣይነት ያለው ልማት እና ዓለም አቀፍ ጉዳዮች',
              'enDesc': 'Development strategies in Ethiopia, environmental challenges, globalization, and civic duties.',
              'amDesc': 'በኢትዮጵያ ውስጥ የልማት ስልቶች፣ የአካባቢ ፈተናዎች፣ ግሎባላይዜሽን እና የዜግነት ግዴታዎች።',
            },
          ];
        }
        return [
          {
            'id': 'civ_u1',
            'grade': widget.grade,
            'enUnit': 'Unit 1: Democratic & Constitutional Values',
            'amUnit': 'ክፍል 1: ዲሞክራሲያዊ እና ህገ-መንግስታዊ እሴቶች',
            'enDesc': 'Human rights concepts, citizens participation, rule of law, and democratic institutions.',
            'amDesc': 'የሰብአዊ መብቶች ጽንሰ-ሀሳብ፣ የተማሪዎች/ዜጎች ተሳትፎ፣ የህግ የበላይነት እና ዲሞክራሲያዊ ተቋማት።',
          },
          {
            'id': 'civ_u2',
            'grade': widget.grade,
            'enUnit': 'Unit 2: Active Citizenship & Ethics',
            'amUnit': 'ክፍል 2: ንቁ ዜግነት እና ስነ-ምግባር',
            'enDesc': 'Social engagement, patriotic duties, volunteer activities, and civic responsibilities.',
            'amDesc': 'ማህበራዊ ተሳትፎ፣ የአገር ፍቅር ግዴታዎች፣ የበጎ ፈቃድ ስራዎች እና የዜግነት ኃላፊነቶች።',
          },
          {
            'id': 'civ_u3',
            'grade': widget.grade,
            'enUnit': 'Unit 3: Government and Legal Structures',
            'amUnit': 'ክፍል 3: የመንግስት እና የስነ-ህግ መዋቅሮች',
            'enDesc': 'Three branches of government, regional state formations, and national constitution pillars.',
            'amDesc': 'ሶስቱ የመንግስት አካላት፣ የክልል መንግስታት አመሰራረት እና የህገ-መንግስት መሰረቶች።',
          },
        ];

      case 'English':
        if (widget.grade == 9) {
          return [
            {
              'id': 'eng_u1',
              'grade': 9,
              'enUnit': 'Unit 1: Living in Urban Areas',
              'amUnit': 'Unit 1: Living in Urban Areas',
              'enDesc': 'Vocabulary and grammar practice related to urban life.',
              'amDesc': 'Vocabulary and grammar practice related to urban life.',
            },
            {
              'id': 'eng_u2',
              'grade': 9,
              'enUnit': 'Unit 2: Study Skills',
              'amUnit': 'Unit 2: Study Skills',
              'enDesc': 'Developing reading, note-taking, and research techniques.',
              'amDesc': 'Developing reading, note-taking, and research techniques.',
            },
            {
              'id': 'eng_u3',
              'grade': 9,
              'enUnit': 'Unit 3: Traffic Accident',
              'amUnit': 'Unit 3: Traffic Accident',
              'enDesc': 'Understanding traffic rules, safety warnings, and conditional tenses.',
              'amDesc': 'Understanding traffic rules, safety warnings, and conditional tenses.',
            },
            {
              'id': 'eng_u4',
              'grade': 9,
              'enUnit': 'Unit 4: National Parks',
              'amUnit': 'Unit 4: National Parks',
              'enDesc': 'Exploring Ethiopian wildlife, conservation, and descriptive writing.',
              'amDesc': 'Exploring Ethiopian wildlife, conservation, and descriptive writing.',
            },
            {
              'id': 'eng_u5',
              'grade': 9,
              'enUnit': 'Unit 5: Horticulture',
              'amUnit': 'Unit 5: Horticulture',
              'enDesc': 'Gardening vocabulary, sequencing steps, and passive voice.',
              'amDesc': 'Gardening vocabulary, sequencing steps, and passive voice.',
            },
            {
              'id': 'eng_u6',
              'grade': 9,
              'enUnit': 'Unit 6: Poverty in Ethiopia',
              'amUnit': 'Unit 6: Poverty in Ethiopia',
              'enDesc': 'Discussing socio-economic themes, cause and effect structures.',
              'amDesc': 'Discussing socio-economic themes, cause and effect structures.',
            },
            {
              'id': 'eng_u7',
              'grade': 9,
              'enUnit': 'Unit 7: Community Services',
              'amUnit': 'Unit 7: Community Services',
              'enDesc': 'Writing essays on voluntary activities and civic engagement.',
              'amDesc': 'Writing essays on voluntary activities and civic engagement.',
            },
            {
              'id': 'eng_u8',
              'grade': 9,
              'enUnit': 'Unit 8: Communicable Diseases',
              'amUnit': 'Unit 8: Communicable Diseases',
              'enDesc': 'Vocabulary on health, diseases, and modal verbs for advice.',
              'amDesc': 'Vocabulary on health, diseases, and modal verbs for advice.',
            },
            {
              'id': 'eng_u9',
              'grade': 9,
              'enUnit': 'Unit 9: Fairness and Equity',
              'amUnit': 'Unit 9: Fairness and Equity',
              'enDesc': 'Debating equality, justice, and expressing opinion phrases.',
              'amDesc': 'Debating equality, justice, and expressing opinion phrases.',
            },
            {
              'id': 'eng_u10',
              'grade': 9,
              'enUnit': 'Unit 10: The Internet',
              'amUnit': 'Unit 10: The Internet',
              'enDesc': 'Digital literacy vocabulary, advantages, and disadvantages.',
              'amDesc': 'Digital literacy vocabulary, advantages, and disadvantages.',
            },
          ];
        }
        if (widget.grade == 10) {
          return [
            {
              'id': 'eng_u1',
              'grade': 10,
              'enUnit': 'Unit 1: Sport and Fitness',
              'amUnit': 'ክፍል 1: ስፖርት እና የአካል ብቃት',
              'enDesc': 'Listening comprehension, reading about healthy lifestyles, vocabulary of sports, present simple and present continuous.',
              'amDesc': 'ማዳመጥ፣ ጤናማ የአኗኗር ዘይቤ ማንበብ፣ የስፖርት ቃላት፣ ቀላል የአሁን ጊዜ እና አሁን እየተደረገ ያለ ጊዜ።',
            },
            {
              'id': 'eng_u2',
              'grade': 10,
              'enUnit': 'Unit 2: Keep Safe',
              'amUnit': 'ክፍል 2: ደህንነትዎን ይጠብቁ',
              'enDesc': 'Safety at home and work, road safety, modal verbs of obligation and advice, hazard vocabulary.',
              'amDesc': 'በቤት እና በስራ ቦታ ደህንነት፣ የመንገድ ደህንነት፣ የግዴታ እና የምክር ሞዳል ግሶች፣ የአደጋ ቃላት።',
            },
            {
              'id': 'eng_u3',
              'grade': 10,
              'enUnit': 'Unit 3: Finance and Economic Growth',
              'amUnit': 'ክፍል 3: ፋይናንስ እና ኢኮኖሚያዊ እድገት',
              'enDesc': 'Socio-economic developments, banking systems, passive voice, financial terms and active listening.',
              'amDesc': 'ማህበራዊና ኢኮኖሚያዊ እድገቶች፣ የባንክ ስርዓቶች፣ ተገብሮ ግስ፣ የፋይናንስ ቃላት እና ንቁ ማዳመጥ።',
            },
          ];
        }
        if (widget.grade == 11) {
          return [
            {
              'id': 'eng_u1',
              'grade': 11,
              'enUnit': 'Unit 1: Tourism and Travels',
              'amUnit': 'ክፍል 1: ቱሪዝም እና ጉዞዎች',
              'enDesc': 'Describing locations, hotel reservations, present perfect and past simple, passive voice in tourism contexts.',
              'amDesc': 'ቦታዎችን መግለፅ, የሆቴል ቦታ ማስያዝ, የአሁን ፍጹም ጊዜ እና ቀላል ያለፈ ጊዜ.',
            },
            {
              'id': 'eng_u2',
              'grade': 11,
              'enUnit': 'Unit 2: Higher Education and Careers',
              'amUnit': 'ክፍል 2: ከፍተኛ ትምህርት እና የሙያ መስኮች',
              'enDesc': 'University entry, job applications, conditional sentences type 1 & 2, formal writing guidelines.',
              'amDesc': 'የዩኒቨርሲቲ መግቢያ፣ የሥራ ማመልከቻዎች፣ የሁኔታ ዓረፍተ ነገሮች ዓይነት 1 እና 2፣ መደበኛ የጽሕፈት መመሪያዎች።',
            },
            {
              'id': 'eng_u3',
              'grade': 11,
              'enUnit': 'Unit 3: Climate Change and Protection',
              'amUnit': 'ክፍል 3: የአየር ንብረት ለውጥ እና ጥበቃ',
              'enDesc': 'Environmental vocabulary, discussing causes and effects of global warming, expressing agreements and opinions.',
              'amDesc': 'የአካባቢ ቃላት፣ ስለ ሙቀት መጨመር መንስኤዎችና መዘዞች መወያየት፣ ስምምነትንና አስተያየትን መግለጽ።',
            },
          ];
        }
        if (widget.grade == 12) {
          return [
            {
              'id': 'eng_u1',
              'grade': 12,
              'enUnit': 'Unit 1: Post-Secondary Education Pathways',
              'amUnit': 'ክፍል 1: ከሁለተኛ ደረጃ ትምህርት በኋላ ያሉ መንገዶች',
              'enDesc': 'University scholarship essays, advanced study skills, conditional sentences type 3, career pathways.',
              'amDesc': 'የዩኒቨርሲቲ ስኮላርሺፕ ድርሰቶች፣ የላቀ የጥናት ክህሎት፣ የሁኔታ ዓረፍተ ነገሮች ዓይነት 3፣ የሙያ መንገዶች።',
            },
            {
              'id': 'eng_u2',
              'grade': 12,
              'enUnit': 'Unit 2: Global Citizenship and Treaties',
              'amUnit': 'ክፍል 2: ዓለም አቀፍ ዜግነት እና ስምምነቶች',
              'enDesc': 'Discussing international organizations, human rights, formal debates, complex passive constructions.',
              'amDesc': 'ስለ ዓለም አቀፍ ድርጅቶች, የሰብአዊ መብቶች, መደበኛ ክርክሮች, ውስብስብ ተገብሮ መዋቅሮች መወያየት.',
            },
            {
              'id': 'eng_u3',
              'grade': 12,
              'enUnit': 'Unit 3: Literature and Creative Writing',
              'amUnit': 'ክፍል 3: ስነ-ጽሁፍ እና ፈጠራ ጽሁፍ',
              'enDesc': 'Analyzing short stories, poetry, figures of speech, reporting speech, and writing narrative essays.',
              'amDesc': 'አጫጭር ታሪኮችን, ግጥሞችን, የስነ-ጽሁፍ ምስሎችን, ቀጥተኛ ያልሆነ ንግግርን መተንተን እና ድርሰቶችን መጻፍ.',
            },
          ];
        }
        return [
          {
            'id': 'eng_u1',
            'grade': widget.grade,
            'enUnit': 'Unit 1: Advanced Communication',
            'amUnit': 'ክፍል 1: የላቀ ግንኙነት',
            'enDesc': 'Enhancing comprehension, speaking, and academic writing skills.',
            'amDesc': 'የመረዳት፣ የመናገር እና የአካዳሚክ ፅሁፍ ክህሎቶችን ማሳደግ።',
          },
        ];

      case 'Economics':
        if (widget.grade == 9) {
          return [
            {
              'id': 'econ_u1',
              'grade': 9,
              'enUnit': 'Unit 1: Introducing Economics',
              'amUnit': 'Unit 1: Introducing Economics',
              'enDesc': 'Definition, scope, and basic methodology of economics.',
              'amDesc': 'Definition, scope, and basic methodology of economics.',
            },
            {
              'id': 'econ_u2',
              'grade': 9,
              'enUnit': 'Unit 2: The Basic Economic Problems and Economic Systems',
              'amUnit': 'Unit 2: The Basic Economic Problems and Economic Systems',
              'enDesc': 'Scarcity, choice, opportunity cost, and economic systems.',
              'amDesc': 'Scarcity, choice, opportunity cost, and economic systems.',
            },
            {
              'id': 'econ_u3',
              'grade': 9,
              'enUnit': 'Unit 3: Economic Resources and Markets',
              'amUnit': 'Unit 3: Economic Resources and Markets',
              'enDesc': 'Factors of production, circular flow of income, and market structures.',
              'amDesc': 'Factors of production, circular flow of income, and market structures.',
            },
            {
              'id': 'econ_u4',
              'grade': 9,
              'enUnit': 'Unit 4: Introduction to Demand and Supply',
              'amUnit': 'Unit 4: Introduction to Demand and Supply',
              'enDesc': 'Understanding the law of demand, law of supply, and equilibrium.',
              'amDesc': 'Understanding the law of demand, law of supply, and equilibrium.',
            },
            {
              'id': 'econ_u5',
              'grade': 9,
              'enUnit': 'Unit 5: Introduction to Production and Cost',
              'amUnit': 'Unit 5: Introduction to Production and Cost',
              'enDesc': 'Concept of production functions, short-run and long-run costs.',
              'amDesc': 'Concept of production functions, short-run and long-run costs.',
            },
            {
              'id': 'econ_u6',
              'grade': 9,
              'enUnit': 'Unit 6: Introduction to Money',
              'amUnit': 'Unit 6: Introduction to Money',
              'enDesc': 'Functions of money, evolution, and banking services.',
              'amDesc': 'Functions of money, evolution, and banking services.',
            },
            {
              'id': 'econ_u7',
              'grade': 9,
              'enUnit': 'Unit 7: Introduction to Macroeconomics',
              'amUnit': 'Unit 7: Introduction to Macroeconomics',
              'enDesc': 'National income, inflation, unemployment, and fiscal policy basics.',
              'amDesc': 'National income, inflation, unemployment, and fiscal policy basics.',
            },
            {
              'id': 'econ_u8',
              'grade': 9,
              'enUnit': 'Unit 8: Basic Entrepreneurship',
              'amUnit': 'Unit 8: Basic Entrepreneurship',
              'enDesc': 'Key characteristics of an entrepreneur, starting a business.',
              'amDesc': 'Key characteristics of an entrepreneur, starting a business.',
            },
          ];
        }
        if (widget.grade == 10) {
          return [
            {
              'id': 'econ_u1',
              'grade': 10,
              'enUnit': 'Unit 1: Theory of Demand and Supply',
              'amUnit': 'ክፍል 1: የፍላጎት እና የአቅርቦት ንድፈ ሃሳብ',
              'enDesc': 'Elasticity of demand and supply, market equilibrium, and price controls.',
              'amDesc': 'የፍላጎት እና አቅርቦት የመለጠጥ ባህሪ፣ የገበያ ሚዛን እና የዋጋ ቁጥጥሮች።',
            },
            {
              'id': 'econ_u2',
              'grade': 10,
              'enUnit': 'Unit 2: Theory of Consumer Behavior',
              'amUnit': 'ክፍል 2: የሸማቾች ባህሪ ንድፈ ሃሳብ',
              'enDesc': 'Utility approaches, cardinal and ordinal utility, consumer preference, and budget constraints.',
              'amDesc': 'የረቂቅ እርካታ (Utility) አቀራረቦች፣ የካርዲናል እና ኦርዲናል ረቂቅ እርካታ፣ የሸማቾች ምርጫ።',
            },
            {
              'id': 'econ_u3',
              'grade': 10,
              'enUnit': 'Unit 3: Theory of Production and Cost',
              'amUnit': 'ክፍል 3: የአመራረት እና የወጪ ንድፈ ሃሳብ',
              'enDesc': 'Production function, returns to scale, short-run and long-run cost analysis.',
              'amDesc': 'የምርት ተግባር (Production function)፣ የአጭር ጊዜ እና የረጅም ጊዜ ወጪዎች ትንተና።',
            },
          ];
        }
        if (widget.grade == 11) {
          return [
            {
              'id': 'econ_u1',
              'grade': 11,
              'enUnit': 'Unit 1: Microeconomic Principles',
              'amUnit': 'ክፍል 1: የማይክሮ-ኢኮኖሚክስ መርሆዎች',
              'enDesc': 'Analyzing consumer behavior, market systems and efficiency.',
              'amDesc': 'የሸማቾች ባህሪ፣ የገበያ ስርዓቶች እና ውጤታማነት መመርመር።',
            },
            {
              'id': 'econ_u2',
              'grade': 11,
              'enUnit': 'Unit 2: Market Structures',
              'amUnit': 'ክፍል 2: የገበያ መዋቅሮች',
              'enDesc': 'Perfect competition, monopoly, monopolistic competition, and oligopoly dynamics.',
              'amDesc': 'ፍጹም ውድድር፣ ሞኖፖሊ፣ ሞኖፖሊያዊ ውድድር እና ኦሊጎፖሊ ገበያ ባህሪያት።',
            },
            {
              'id': 'econ_u3',
              'grade': 11,
              'enUnit': 'Unit 3: National Income Accounting',
              'amUnit': 'ክፍል 3: ብሄራዊ የገቢ ሂሳብ አያያዝ',
              'enDesc': 'GDP, GNP, measurement methods (expenditure, income, product), and limitations.',
              'amDesc': 'ጂዲፒ (GDP)፣ ጂኤንፒ (GNP)፣ ብሄራዊ ገቢን የመለኪያ ዘዴዎች እና ተግዳሮቶቹ።',
            },
          ];
        }
        if (widget.grade == 12) {
          return [
            {
              'id': 'econ_u1',
              'grade': 12,
              'enUnit': 'Unit 1: Fundamental Macroeconomics',
              'amUnit': 'ክፍል 1: መሰረታዊ የማክሮ-ኢኮኖሚክስ መርሆዎች',
              'enDesc': 'Aggregate demand and supply, macroeconomic policy instruments, and business cycles.',
              'amDesc': 'አጠቃላይ ፍላጎትና አቅርቦት፣ የማክሮ ኢኮኖሚ ፖሊሲ መሳሪያዎች እና የንግድ ዑደቶች።',
            },
            {
              'id': 'econ_u2',
              'grade': 12,
              'enUnit': 'Unit 2: Inflation and Unemployment',
              'amUnit': 'ክፍል 2: የዋጋ ንረት እና ስራ አጥነት',
              'enDesc': 'Causes and types of inflation, unemployment classifications, Phillips curve, and policy remedies.',
              'amDesc': 'የዋጋ ንረት መንስኤዎች እና አይነቶች፣ የስራ አጥነት ምደባዎች እና የፖሊሲ መፍትሄዎች።',
            },
            {
              'id': 'econ_u3',
              'grade': 12,
              'enUnit': 'Unit 3: Economic Growth and Development',
              'amUnit': 'ክፍል 3: የኢኮኖሚ እድገት እና ልማት',
              'enDesc': 'Determinants of economic growth, development indices, and characteristics of developing nations.',
              'amDesc': 'የኢኮኖሚ እድገት ወሳኝ ሁኔታዎች፣ የልማት መለኪያዎች እና የታዳጊ አገሮች ባህሪያት።',
            },
            {
              'id': 'econ_u4',
              'grade': 12,
              'enUnit': 'Unit 4: International Trade and Finance',
              'amUnit': 'ክፍል 4: ዓለም አቀፍ ንግድ እና ፋይናንስ',
              'enDesc': 'Comparative advantage, balance of payments, exchange rate systems, and trade barriers.',
              'amDesc': 'አንጻራዊ ብልጫ፣ የክፍያ ሚዛን (BOP)፣ የምንዛሬ ተመን ሥርዓቶች እና የንግድ መሰናክሎች።',
            },
          ];
        }
        return [
          {
            'id': 'econ_u1',
            'grade': widget.grade,
            'enUnit': 'Unit 1: Microeconomic Principles',
            'amUnit': 'ክፍል 1: የማይክሮ-ኢኮኖሚክስ መርሆዎች',
            'enDesc': 'Analyzing consumer behavior, market systems and efficiency.',
            'amDesc': 'የሸማቾች ባህሪ፣ የገበያ ስርዓቶች እና ውጤታማነት መመርመር።',
          },
        ];

      case 'Agriculture':
        return [
          {
            'id': 'agri_u1',
            'grade': widget.grade,
            'enUnit': 'Unit 1: Principles of Crop and Livestock Management',
            'amUnit': 'ክፍል 1: የሰብል እና የእንስሳት እርባታ መሰረታዊ መርሆዎች',
            'enDesc': 'Sustainable animal breeding, agricultural tools safety, sowing timelines, crop rotation keys.',
            'amDesc': 'ዘላቂ የእንስሳት እርባታ፣ የግብርና ሰብል እንክብካቤ እና ዘላቂ የሰብል ዝውውር።',
          },
          {
            'id': 'agri_u2',
            'grade': widget.grade,
            'enUnit': 'Unit 2: Soil Properties & Water Systems',
            'amUnit': 'ክፍል 2: የአፈር ባህሪያት እና የውሃ አጠቃቀም',
            'enDesc': 'Clay vs sand water holding indexes, organic manure, and primary drainage pathways.',
            'amDesc': 'የአሸዋማ እና ጭቃማ አፈር ባህሪዎች፣ የተፈጥሮ ማዳበሪያ እና መስኖ አጠቃቀም።',
          },
          {
            'id': 'agri_u3',
            'grade': widget.grade,
            'enUnit': 'Unit 3: Crop Parasites & Biological Control',
            'amUnit': 'ክፍል 3: የሰብል ተባዮች እና ባዮሎጂያዊ ቁጥጥር',
            'enDesc': 'Predator-prey insects implementations, rust fungus treatments, and non-chemical methods.',
            'amDesc': 'የተፈጥሮ ተባዮችን መከላከያ ነፍሳት፣ የቡና በሽታ መከላከያዎች እና የአካባቢ ጥበቃ።',
          },
          {
            'id': 'agri_u4',
            'grade': widget.grade,
            'enUnit': 'Unit 4: Agroforestry and Resource Conservation',
            'amUnit': 'ክፍል 4: አግሮ-ፎረስቴሪ እና የተፈጥሮ ሀብት ጥበቃ',
            'enDesc': 'Combining high-productive trees with cereal crops, windbreak buffers, and terracings.',
            'amDesc': 'ዛፎችን ከእርሻ ሰብሎች ጋር ማሳደግ፣ የእርከን ስራዎች እና የንፋስ መከላከያዎች።',
          },
          {
            'id': 'agri_u5',
            'grade': widget.grade,
            'enUnit': 'Unit 5: Advanced Smart Agriculture Systems',
            'amUnit': 'ክፍል 5: ዘመናዊ እና የተራቀቁ የግብርና ዘዴዎች',
            'enDesc': 'Hydroponics structures, drip-irrigation efficiency setups, and greenhouse automation theories.',
            'amDesc': 'ሀይድሮፖኒክስ (ያለ አፈር ማልማት)፣ የተንጠባጠብ መስኖ እና የሙቀት መቆጣጠሪያ ግሪንሃውስ።',
          },
        ];

      default:
        return [];
    }
  }

  int _selectedUnitIndex = 0;



  Future<void> _downloadUnitWithAd(String unitId) async {
    final String typeSuffix = widget.isShortNotesMode ? '_notes' : '_quiz';
    final String downloadKey = 'g${widget.grade}_${unitId}$typeSuffix';
    final String cleanKey = downloadKey.replaceAll('_notes', '');
    final bool isExpired = _expiredUnits.contains(downloadKey);
    if ((_downloadedUnits.contains(cleanKey) || _downloadedUnits.contains(downloadKey)) && !isExpired) return;

    final String languageCode = AppStateProvider.of(context).languageCode;
    final allUnits = _getUnits();
    final unitIndex = allUnits.indexWhere((u) => u['id'] == unitId) + 1;
    final int activeUnitNum = unitIndex > 0 ? unitIndex : 1;

    void performDownload() async {
      // Start download status with 0% progress
      setState(() {
        _downloadProgress[downloadKey] = 0.0;
      });

      double currentProgress = 0.0;
      // Use a standard Stream.periodic timer to smoothly count progress from 0% to 100%
      final progressTimer = Stream.periodic(const Duration(milliseconds: 100)).listen((_) {
        if (currentProgress < 0.90) {
          // Slow down near 90% for realism
          currentProgress += 0.04 + (0.04 * (1.0 - currentProgress));
          if (currentProgress > 0.90) currentProgress = 0.90;
          if (mounted) {
            setState(() {
              _downloadProgress[downloadKey] = currentProgress;
            });
          }
        }
      });

      try {
        int fetchedQuestionsCount = 0;
        if (widget.isShortNotesMode) {
          String getNormalizedSubjectName(String rawId) {
            final sub = rawId.toLowerCase();
            if (sub.contains('math')) return 'mathematics';
            if (sub.contains('biol') || sub.contains('bio')) return 'biology';
            if (sub.contains('phys')) return 'physics';
            if (sub.contains('chem')) return 'chemistry';
            if (sub.contains('geog') || sub.contains('geo')) return 'geography';
            if (sub.contains('hist')) return 'history';
            if (sub.contains('civ')) return 'civics';
            if (sub.contains('agri') || sub.contains('agr')) return 'agriculture';
            if (sub.contains('econ') || sub.contains('eco')) return 'economics';
            if (sub.contains('eng')) return 'english';
            return sub;
          }

          final String normalizedSubject = getNormalizedSubjectName(widget.subjectId);
          final String expectedSubjectId = '${widget.grade}_$normalizedSubject';

          final fetchedNotesResponse = await Supabase.instance.client
              .from('units')
              .select('''
                id,
                subject_id,
                unit_number,
                subjects!inner(
                  id,
                  name,
                  grade
                ),
                unit_notes (
                  id,
                  unit_id,
                  title,
                  pdf_url,
                  created_at
                )
              ''')
              .eq('unit_number', activeUnitNum)
              .eq('subjects.grade', widget.grade)
              .or('subject_id.eq.$expectedSubjectId,subject_id.ilike.%$normalizedSubject%,subject_id.ilike.%${widget.subjectId}%')
              .maybeSingle();

          List<dynamic> fetchedNotesData = [];
          if (fetchedNotesResponse != null && fetchedNotesResponse['unit_notes'] != null) {
            fetchedNotesData = fetchedNotesResponse['unit_notes'];
          }

          if (fetchedNotesData.isEmpty) {
            throw Exception("No notes available on developer server.");
          }
          final List<Map<String, dynamic>> fetchedNotes = List<Map<String, dynamic>>.from(fetchedNotesData);
          await OfflineManager.saveOfflineNotes(
            downloadKey,
            fetchedNotes,
            grade: widget.grade,
            unit: activeUnitNum,
          );

          // Pre-download PDF files for offline reading
          final String unitIdStr = 'g${widget.grade}_$unitId';
          for (final note in fetchedNotes) {
            final String? pdfUrl = note['pdf_url']?.toString().trim();
            if (pdfUrl != null && pdfUrl.isNotEmpty) {
              try {
                await PdfCacheService.downloadAndSavePdf(unitId: unitIdStr, pdfUrl: pdfUrl);
              } catch (e) {
                debugPrint('[PDF Cache Error] Pre-downloading PDF note failed during unit download: $e');
              }
            }
          }
        } else {
          final fetchedQuestions = await QuizService.fetchQuestions(
            grade: widget.grade,
            subject: widget.subjectId,
            unit: activeUnitNum,
          );

          if (fetchedQuestions.isEmpty) {
            throw Exception("No questions available on developer server.");
          }
          fetchedQuestionsCount = fetchedQuestions.length;

          await OfflineManager.saveOfflineQuestions(
            downloadKey,
            fetchedQuestions,
            grade: widget.grade,
            unit: activeUnitNum,
          );
        }
        await OfflineManager.addDownload(downloadKey);

        progressTimer.cancel();

        // Finish progress smoothly to 100%
        if (mounted) {
          setState(() {
            _downloadProgress[downloadKey] = 1.0;
          });
        }

        // Brief delay so 100% is clearly visible to user
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          setState(() {
            _downloadProgress.remove(downloadKey);
            _downloadedUnits.add(downloadKey);
            _expiredUnits.remove(downloadKey);
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.isShortNotesMode
                          ? (languageCode == 'en'
                              ? 'Saved! Short notes are available offline.'
                              : 'ተቀምጧል! አጫጭር ማስታወሻዎች ከመስመር ውጭ ዝግጁ ናቸው።')
                          : (languageCode == 'en'
                              ? 'Saved! ${fetchedQuestionsCount} questions are available offline.'
                              : 'ተቀምጧል! ${fetchedQuestionsCount} ጥያቄዎች ከመስመር ውጭ ዝግጁ ናቸው።'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } catch (e) {
        progressTimer.cancel();
        if (mounted) {
          setState(() {
            _downloadProgress.remove(downloadKey);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      languageCode == 'en'
                          ? 'Download failed. Check network connection.'
                          : (widget.isShortNotesMode
                              ? 'ማስታወሻዎችን ማውረድ አልተቻለም፡ በይነመረብዎን ያረጋግጡ።'
                              : 'ጥያቄዎችን ማውረድ አልተቻለም፡ በይነመረብዎን ያረጋግጡ።'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }

    try {
      final bool hasConn = await _hasInternet();
      if (!hasConn) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      languageCode == 'en'
                          ? 'No internet connection. Please connect to download.'
                          : 'ምንም የኢንተርኔት ግንኙነት የለም። እባክዎ ለማውረድ ከኢንተርኔት ጋር ይገናኙ።',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      // Use AdMob rewarded video loading system on download question action
      _executeWithRewardedAd(performDownload);
    } catch (e) {
      debugPrint("Error in download logic: $e");
      performDownload();
    }
  }

  void _showInfoSheet() {
    final appConfig = AppStateProvider.of(context);
    final isLight = !appConfig.isDarkMode;
    showModalBottomSheet(
      context: context,
      backgroundColor: isLight ? Colors.white : const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.download_for_offline_rounded, color: widget.color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _local('info_sheet'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: isLight ? const Color(0xFF0F172A) : Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                _local('info_desc'),
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _local('bytes_info'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: widget.color,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Live query from AppStateProvider for absolute zero delay updates
    final appConfig = AppStateProvider.of(context);
    final bool isDarkMode = appConfig.isDarkMode;
    final String languageCode = appConfig.languageCode;
    final bool isLight = !isDarkMode;

    final Color bgColor = isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final Color cardBgColor = isLight ? Colors.white : const Color(0xFF1E293B);
    final Color headerTextColor = isLight ? const Color(0xFF0F172A) : Colors.white;
    final Color descColor = isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8);

    final allUnits = _getUnits();
    final filteredUnits = allUnits;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0.0,
        backgroundColor: isLight ? Colors.white : const Color(0xFF1E293B),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: headerTextColor, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          languageCode == 'en' ? widget.enTitle : widget.amTitle,
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w900,
            color: headerTextColor,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline_rounded, color: headerTextColor, size: 20),
            onPressed: _showInfoSheet,
          ),
          IconButton(
            icon: Icon(
              isDarkMode ? Icons.wb_sunny_rounded : Icons.nightlight_round_outlined,
              color: headerTextColor,
              size: 20,
            ),
            onPressed: appConfig.onToggleTheme,
          ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: (_isBannerAdLoaded && _bannerAd != null)
          ? Container(
              decoration: BoxDecoration(
                color: isLight ? Colors.white : const Color(0xFF1E293B),
                border: Border(
                  top: BorderSide(
                    color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                    width: 0.8,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: 50.0,
                  child: Center(
                    child: SizedBox(
                      width: _bannerAd!.size.width.toDouble(),
                      height: 50.0,
                      child: AdWidget(ad: _bannerAd!),
                    ),
                  ),
                ),
              ),
            )
          : null,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: bgColor,
          image: DecorationImage(
            image: const AssetImage('assets/images/education_bg_pattern.png'),
            repeat: ImageRepeat.repeat,
            opacity: isLight ? 0.09 : 0.03,
            colorFilter: isLight ? null : const ColorFilter.mode(Colors.white54, BlendMode.modulate),
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Beautiful Hero section with Subject Card presentation
              Container(
                decoration: BoxDecoration(
                  color: isLight ? Colors.white : const Color(0xFF1E293B),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isLight
                          ? Colors.black.withValues(alpha: 0.03)
                          : Colors.black.withValues(alpha: 0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Dynamic scaled illustration in unique background box
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: widget.color.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: SizedBox(
                              width: 36,
                              height: 36,
                              child: widget.icon,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Titles and Grade
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: widget.color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  languageCode == 'en'
                                      ? 'GRADE ${widget.grade}'
                                      : 'ክፍል ${widget.grade}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: widget.color,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                languageCode == 'en' ? widget.enTitle : widget.amTitle,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: headerTextColor,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                languageCode == 'en'
                                    ? 'High-quality comprehensive unit reviews'
                                    : 'ምርጥ ከመስመር ውጭ የትምህርት ክፍሎች',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: descColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1, thickness: 1),
                    const SizedBox(height: 8),
                    // Progress metric section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _local('progress_label'),
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: headerTextColor),
                        ),
                        Text(
                          languageCode == 'en'
                              ? '${_downloadedUnits.length} / ${allUnits.length} Offline'
                              : '${_downloadedUnits.length} / ${allUnits.length} ወርዷል',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: widget.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Custom layout ProgressBar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: allUnits.isEmpty ? 0.0 : (_downloadedUnits.length / allUnits.length),
                        minHeight: 6.0,
                        backgroundColor: widget.color.withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation<Color>(widget.color),
                      ),
                    ),
                  ],
                ),
              ),

              if (_showOfflineTipBanner)
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00BFFF).withValues(alpha: isLight ? 0.08 : 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF00BFFF).withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFF00BFFF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.download_for_offline_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              languageCode == 'am' ? '💡 ከመስመር ውጭ (Offline) ያንብቡ' : '💡 Study 100% Offline',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isLight ? const Color(0xFF0F172A) : Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              languageCode == 'am'
                                  ? 'የእያንዳንዱን ምዕራፍ ጥያቄዎችና ማስታወሻዎች አውርደው ያለ ኢንተርኔት ይጠቀሙ!'
                                  : 'Download units once to access quizzes & short notes without any internet connection!',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: _dismissOfflineTipBanner,
                        color: isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      ),
                    ],
                  ),
                ),

              if (filteredUnits.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                  child: Column(
                    children: [
                      Icon(Icons.layers_clear_rounded, color: descColor.withValues(alpha: 0.4), size: 48),
                      const SizedBox(height: 12),
                      Text(
                        languageCode == 'en' ? 'No units available yet.' : 'ምንም የትምህርት ክፍሎች አልተገኙም።',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: descColor, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  itemCount: filteredUnits.length,
                  itemBuilder: (context, index) {
                    final unit = filteredUnits[index];
                    final String unitId = unit['id'];
                    final String typeSuffix = widget.isShortNotesMode ? '_notes' : '_quiz';
                    final String downloadKey = 'g${widget.grade}_${unitId}$typeSuffix';
                    final String cleanKey = downloadKey.replaceAll('_notes', '');
                    final bool isDownloaded = _downloadedUnits.contains(cleanKey) || _downloadedUnits.contains(downloadKey);
                    final bool isExpired = _expiredUnits.contains(downloadKey);
                    final double? progress = _downloadProgress[downloadKey];

                    final String title = unit['enUnit'] ?? '';
                    final String desc = languageCode == 'en' ? unit['enDesc'] : unit['amDesc'];
                    final bool isSelected = _selectedUnitIndex == index;

                    final selectedUnit = filteredUnits[index];
                    final originalIndex = allUnits.indexOf(selectedUnit);
                    final int activeUnitNum = originalIndex >= 0 ? originalIndex + 1 : index + 1;

                    final indexFactor = index * 100;
                    final bool isLocked = activeUnitNum > 1 && !_isRegistered;
                    return TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: Duration(milliseconds: 300 + indexFactor),
                      curve: Curves.easeOutCubic,
                      builder: (context, animValue, animChild) {
                        return Transform.translate(
                          offset: Offset(0.0, 30.0 * (1.1 - animValue)),
                          child: Opacity(
                            opacity: animValue,
                            child: animChild,
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 11.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: cardBgColor,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: isLight ? 0.02 : 0.12),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: isSelected
                                        ? widget.color
                                        : (isLight ? const Color(0xFFEDF2F7) : const Color(0xFF334155)),
                                    width: isSelected ? 1.5 : 1.0,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        _checkRegistrationAndProceed(index, activeUnitNum, onSuccess: () {
                                          setState(() {
                                            _selectedUnitIndex = index;
                                          });
                                          if (widget.isShortNotesMode) {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) => NotesScreen(
                                                  grade: widget.grade,
                                                  subjectId: widget.subjectId,
                                                  unitNumber: activeUnitNum,
                                                  unitTitle: title,
                                                  themeColor: widget.color,
                                                  isDarkMode: AppStateProvider.of(context).isDarkMode,
                                                  languageCode: widget.languageCode,
                                                ),
                                              ),
                                            );
                                          } else {
                                            _showUnitOptionsSheet(context, activeUnitNum, unitId, title, isDownloaded);
                                          }
                                        });
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                                        child: Row(
                                          children: [
                                            // Left: circular container with a coral calendar icon
                                            Container(
                                              width: 44,
                                              height: 44,
                                              decoration: BoxDecoration(
                                                color: isLocked
                                                    ? (isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155))
                                                    : widget.color.withValues(alpha: 0.08),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(
                                                child: isLocked
                                                    ? Icon(
                                                        Icons.lock_rounded,
                                                        color: isLight ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                                        size: 20,
                                                      )
                                                    : SizedBox(
                                                        width: 24,
                                                        height: 24,
                                                        child: widget.icon,
                                                      ),
                                              ),
                                            ),
                                            const SizedBox(width: 14),
                                            // Middle: Unit Title and subtitle
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    title,
                                                    style: TextStyle(
                                                      fontSize: 14.0,
                                                      fontWeight: FontWeight.w900,
                                                      color: headerTextColor,
                                                      height: 1.25,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    desc,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 11.5,
                                                      fontWeight: FontWeight.w500,
                                                      color: descColor,
                                                    ),
                                                  ),
                                                  if (progress != null) ...[
                                                    const SizedBox(height: 8),
                                                    Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Row(
                                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                          children: [
                                                            Text(
                                                              languageCode == 'en' ? 'Downloading questions...' : 'ጥያቄዎችን በማውረድ ላይ...',
                                                              style: TextStyle(
                                                                fontSize: 10.5,
                                                                fontWeight: FontWeight.bold,
                                                                color: widget.color,
                                                              ),
                                                            ),
                                                            Text(
                                                              '${(progress * 100).toInt()}%',
                                                              style: TextStyle(
                                                                fontSize: 10.5,
                                                                fontWeight: FontWeight.w900,
                                                                color: widget.color,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(height: 4),
                                                        ClipRRect(
                                                          borderRadius: BorderRadius.circular(4),
                                                          child: LinearProgressIndicator(
                                                            value: progress,
                                                            minHeight: 6,
                                                            backgroundColor: widget.color.withValues(alpha: 0.12),
                                                            valueColor: AlwaysStoppedAnimation<Color>(widget.color),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                  if (_unitBestScores.containsKey(activeUnitNum)) ...[
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      children: [
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                                            borderRadius: BorderRadius.circular(6),
                                                            border: Border.all(
                                                              color: const Color(0xFF10B981).withValues(alpha: 0.25),
                                                              width: 1.0,
                                                            ),
                                                          ),
                                                          child: Row(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              const Icon(
                                                                Icons.emoji_events_rounded,
                                                                color: Colors.amber,
                                                                size: 12,
                                                              ),
                                                              const SizedBox(width: 4),
                                                              Text(
                                                                languageCode == 'en'
                                                                    ? "Score: ${_unitBestScores[activeUnitNum]}%"
                                                                    : "ውጤት: ${_unitBestScores[activeUnitNum]}%",
                                                                style: const TextStyle(
                                                                  fontSize: 10.5,
                                                                  fontWeight: FontWeight.w800,
                                                                  color: Color(0xFF10B981),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            // Tiny grey chevron arrow on the right
                                            Icon(
                                              Icons.chevron_right_rounded,
                                              color: isLight ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                                              size: 16,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                             // Separate Download Button next to each card
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isLocked
                                    ? (isLight ? const Color(0xFF8C95A0) : const Color(0xFF475569)) // Grey for locked
                                    : (isDownloaded
                                        ? (isExpired ? const Color(0xFFD97706) : const Color(0xFF10B981)) // Amber if expired, Green if fresh
                                        : const Color(0xFFCC4A52)), // Red if unlocked / not downloaded
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isLocked
                                            ? Colors.black
                                            : (isDownloaded
                                                ? (isExpired ? const Color(0xFFD97706) : const Color(0xFF10B981))
                                                : const Color(0xFFCC4A52)))
                                        .withValues(alpha: 0.25),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: Tooltip(
                                message: isLocked 
                                     ? 'Locked' 
                                     : (languageCode == 'en'
                                         ? (isDownloaded
                                             ? (isExpired ? 'Re-download' : 'Downloaded')
                                             : 'Download')
                                         : (isDownloaded
                                             ? (isExpired ? 'እንደገና አውርድ' : 'ወርዷል')
                                             : 'አውርድ')),
                                child: progress != null
                                    ? Center(
                                        child: Text(
                                          '${(progress * 100).toInt()}%',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      )
                                    : IconButton(
                                        padding: EdgeInsets.zero,
                                        icon: Icon(
                                          isLocked 
                                              ? Icons.lock_rounded
                                              : (isDownloaded
                                                  ? (isExpired ? Icons.update_rounded : Icons.cloud_done_rounded)
                                                  : Icons.download_rounded),
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                        onPressed: () {
                                          if (isLocked) return;
                                          if (isDownloaded && !isExpired) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  languageCode == 'en'
                                                      ? (widget.isShortNotesMode
                                                          ? 'Unit notes are fully up-to-date and available offline.'
                                                          : 'Unit questions are fully up-to-date and available offline.')
                                                      : (widget.isShortNotesMode
                                                          ? 'የክፍሉ ማስታወሻዎች ወቅታዊ ናቸው እና ከመስመር ውጭ ማግኘት ይችላሉ።'
                                                          : 'የክፍሉ ጥያቄዎች ወቅታዊ ናቸው እና ከመስመር ውጭ ማግኘት ይችላሉ።'),
                                                ),
                                                backgroundColor: const Color(0xFF10B981),
                                                behavior: SnackBarBehavior.floating,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              ),
                                            );
                                            return;
                                          }
                                          _checkRegistrationAndProceed(index, activeUnitNum, onSuccess: () {
                                            _downloadUnitWithAd(unitId);
                                          });
                                        },
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    ),
  );
  }
}

class TestInterstitialAdDialog extends StatefulWidget {
  final VoidCallback onDismiss;

  const TestInterstitialAdDialog({
    super.key,
    required this.onDismiss,
  });

  @override
  State<TestInterstitialAdDialog> createState() => _TestInterstitialAdDialogState();
}

class _TestInterstitialAdDialogState extends State<TestInterstitialAdDialog> {
  int _secondsRemaining = 3;
  StreamSubscription? _timerSubscription;

  @override
  void initState() {
    super.initState();
    _timerSubscription = Stream.periodic(const Duration(seconds: 1)).listen((_) {
      if (mounted) {
        setState(() {
          if (_secondsRemaining > 0) {
            _secondsRemaining--;
          } else {
            _timerSubscription?.cancel();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timerSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return PopScope(
      canPop: false, // Prevent physical back button pop
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.88,
          constraints: const BoxConstraints(maxHeight: 520),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 25,
                offset: const Offset(0, 10),
              )
            ],
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              width: 1.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Stack(
                children: [
                  // Core Ad Content
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // AdMob Watermark Label
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Test Interstitial Ad',
                            style: TextStyle(
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Smart X Logo Badge
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFFCC4A52).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.school_rounded,
                              color: Color(0xFFCC4A52),
                              size: 44,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Premium Title
                        const Text(
                          'SMART X PREMIUM',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: Color(0xFFCC4A52),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Unlock the complete offline classroom & interactive test bank',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Premium Highlight bullet points
                        _buildHighlightRow(Icons.offline_bolt_rounded, '100% Offline Practice', 'No active internet connection required'),
                        _buildHighlightRow(Icons.no_accounts_rounded, 'Zero Commercial Ads', 'Completely uninterrupted learning flow'),
                        _buildHighlightRow(Icons.psychology_rounded, 'Smart Explanation AI Assistant', 'Instant deep breakdown for wrong answers'),
                        const Spacer(),
                        // Primary CTA Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFCC4A52),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 2,
                            ),
                            onPressed: _secondsRemaining == 0
                                ? () {
                                    Navigator.of(context).pop();
                                    widget.onDismiss();
                                  }
                                : null,
                            child: Text(
                              _secondsRemaining > 0
                                  ? 'Closing in ${_secondsRemaining}s...'
                                  : 'Continue to Download',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Top Close Button
                  Positioned(
                    top: 14,
                    right: 14,
                    child: AnimatedCrossFade(
                      firstChild: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            value: (3 - _secondsRemaining) / 3.0,
                            strokeWidth: 2,
                            color: const Color(0xFFCC4A52),
                            backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                      ),
                      secondChild: IconButton(
                        icon: const Icon(Icons.close_rounded),
                        visualDensity: VisualDensity.compact,
                        style: IconButton.styleFrom(
                          backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.onDismiss();
                        },
                      ),
                      crossFadeState: _secondsRemaining > 0
                          ? CrossFadeState.showFirst
                          : CrossFadeState.showSecond,
                      duration: const Duration(milliseconds: 200),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHighlightRow(IconData icon, String title, String subtitle) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFCC4A52), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


