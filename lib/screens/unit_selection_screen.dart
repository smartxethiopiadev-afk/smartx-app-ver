// ignore_for_file: prefer_function_declarations_over_variables, use_build_context_synchronously, unnecessary_brace_in_string_interps
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/ad_helper.dart';
import '../services/offline_manager.dart';
import '../services/quiz_service.dart';
import '../main.dart';
import 'quiz_screen.dart';
import 'registration_overlay.dart';
import 'notes_screen.dart';
import '../widgets/ad_loading_dialog.dart';
import '../services/analytics_service.dart';
import '../data/curriculum_units.dart';

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
    logScreen(widget.isShortNotesMode ? 'ShortNotesUnitScreen' : 'UnitSelectionScreen');
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
    final isDark = AppStateProvider.of(context).isDarkMode;
    AdLoadingDialog.show(
      context,
      languageCode: widget.languageCode,
      isDark: isDark,
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
    return CurriculumUnits.getUnits(
      subjectId: widget.subjectId,
      grade: widget.grade,
    );
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

          List<Map<String, dynamic>> fetchedNotes = [];
          
          try {
            // First try fetching from modern short_notes table (HTML/CSS notes)
            final shortNotesResponse = await Supabase.instance.client
                .from('short_notes')
                .select('id, grade, subject, unit_number, title, html_content, created_at')
                .eq('grade', widget.grade)
                .eq('unit_number', activeUnitNum)
                .ilike('subject', '%$normalizedSubject%');

            if (shortNotesResponse.isNotEmpty) {
              fetchedNotes = List<Map<String, dynamic>>.from(shortNotesResponse);
            }
          } catch (e) {
            debugPrint('[Offline Download] Short notes query notice: $e');
          }

          // Fallback to unit_notes if short_notes is empty
          if (fetchedNotes.isEmpty) {
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
                    html_content,
                    created_at
                  )
                ''')
                .eq('unit_number', activeUnitNum)
                .eq('subjects.grade', widget.grade)
                .or('subject_id.eq.$expectedSubjectId,subject_id.ilike.%$normalizedSubject%,subject_id.ilike.%${widget.subjectId}%')
                .maybeSingle();

            if (fetchedNotesResponse != null && fetchedNotesResponse['unit_notes'] != null) {
              fetchedNotes = List<Map<String, dynamic>>.from(fetchedNotesResponse['unit_notes']);
            }
          }

          if (fetchedNotes.isEmpty) {
            throw Exception("No notes available on developer server.");
          }

          await OfflineManager.saveOfflineNotes(
            downloadKey,
            fetchedNotes,
            grade: widget.grade,
            unit: activeUnitNum,
          );
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

        // Log Firebase Analytics Event for offline unit download
        AnalyticsService.logOfflineDownload(
          unitTitle: 'Unit $activeUnitNum',
          subject: widget.subjectId,
          grade: widget.grade,
        );

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


