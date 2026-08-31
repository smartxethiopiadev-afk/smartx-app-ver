// ignore_for_file: deprecated_member_use, overridden_fields, prefer_const_declarations, use_build_context_synchronously
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ad_helper.dart';
import 'subject_selection_screen.dart';
import 'splash_screen.dart';
import 'unit_selection_screen.dart';
import '../services/offline_manager.dart';
import 'quiz_screen.dart';
import 'notes_screen.dart';
import '../widgets/image_slider_carousel.dart';
import '../widgets/subject_vector_widgets.dart';
import '../widgets/interactive_subject_card.dart';
import '../main.dart';
import '../services/analytics_service.dart';

class HomeScreen extends StatefulWidget {
  final bool isDarkMode;
  final String languageCode;
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleLanguage;

  const HomeScreen({
    super.key,
    required this.isDarkMode,
    required this.languageCode,
    required this.onToggleTheme,
    required this.onToggleLanguage,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class HomeScreenWrapper extends HomeScreen {
  final HomeScreen actualWidget;
  
  @override
  final bool isDarkMode;
  @override
  final String languageCode;

  HomeScreenWrapper({
    required this.actualWidget,
    required this.isDarkMode,
    required this.languageCode,
  }) : super(
          isDarkMode: isDarkMode,
          languageCode: languageCode,
          onToggleTheme: actualWidget.onToggleTheme,
          onToggleLanguage: actualWidget.onToggleLanguage,
          key: actualWidget.key,
        );
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  @override
  HomeScreen get widget {
    try {
      final appState = AppStateProvider.of(context);
      return HomeScreenWrapper(
        actualWidget: super.widget,
        isDarkMode: appState.isDarkMode,
        languageCode: appState.languageCode,
      );
    } catch (_) {
      return super.widget;
    }
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;
  late AnimationController _fadeController;

  // Dynamic User Profile Fields loaded from SharedPreferences
  String _userName = "Abebe Bekele";
  String _userPhoneNumber = "+251 911 234 567";
  bool _isLoggedIn = false;

  // Profile Form Controllers matching screenshot fields
  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;

  int _selectedGradeForQuizTab = 9;
  int _selectedGradeForNotesTab = 9;

  // --- AdMob Ads State ---
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  // Dictionary for dynamic translation matching 'EN/አማርኛ'
  final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'title': 'Smart X Ethiopian',
      'tutorial_desc': 'Watch tutorial: Getting started with the Smart X Ethiopian',
      'explore_title': 'Explore Your Learning Path',
      'explore_sub': 'Select your grade to access courses and resources.',
      'g9_title': 'Grade 9',
      'g9_sub': 'Start Your\nJourney!',
      'g10_title': 'Grade 10',
      'g10_sub': 'Expand your\nknowledge!',
      'g11_title': 'Grade 11',
      'g11_sub': 'Prepare for\nexcellence!',
      'g12_title': 'Grade 12',
      'g12_sub': 'Achieve your\ngoals!',
      'nav_home': 'Home',
      'nav_courses': 'Offline',
      'nav_quiz': 'Quizzes',
      'nav_notes': 'Short Note',
      'nav_leaderboard': 'Leaderboard',
      'nav_account': 'Account',
      'nav_profile': 'Profile',
      'nav_settings': 'Settings',
      'nav_new': 'New',
      'start_course_btn': 'Start Course',
      'featured_title': 'Today\'s Featured Lessons',
      'featured_sub': 'Select a lesson below to watch instantly in the player.',
      'pdf_preview_title': 'PDF Study Material Preview',
      'pdf_preview_sub': 'Interactive quick summary cheat cards. Switch pages below.',
      'pdf_prev_btn': 'Prev',
      'pdf_next_btn': 'Next',
      'pdf_download_btn': 'Download PDF',
      'pdf_page_label': 'Page',
    },
    'am': {
      'title': 'ስማርት ኤክስ ኢትዮጵያ',
      'tutorial_desc': 'የማጠናከሪያ ቪዲዮ: በስማርት ኤክስ ኢትዮጵያ መተግበሪያ እንዴት እንደሚጀመር።',
      'explore_title': 'የመማር መንገድዎን ያስሱ',
      'explore_sub': 'ኮርሶችን እና ሀብቶችን ለማግኘት ክፍልዎን ይምረጡ።',
      'g9_title': 'ክፍል 9',
      'g9_sub': 'ጉዞዎን ይጀምሩ!',
      'g10_title': 'ክፍል 10',
      'g10_sub': 'እውቀትዎን ያሳድጉ!',
      'g11_title': 'ክፍል 11',
      'g11_sub': 'ለላቀ ውጤት ይዘጋጁ!',
      'g12_title': 'ክፍል 12',
      'g12_sub': 'ግብዎን ያሳኩ!',
      'nav_home': 'መነሻ',
      'nav_courses': 'ከመስመር ውጭ',
      'nav_quiz': 'ጥያቄዎች',
      'nav_notes': 'አጫጭር ማስታወሻዎች',
      'nav_leaderboard': 'መሪዎች ሰሌዳ',
      'nav_account': 'መለያ',
      'nav_profile': 'መገለጫ',
      'nav_settings': 'ማስተካከያዎች',
      'nav_new': 'አዲስ',
      'start_course_btn': 'ኮርስ ጀምር',
      'featured_title': 'የዛሬው ልዩ ትምህርቶች',
      'featured_sub': 'በቀጥታ ለመመልከት ከታች ካሉት ቪዲዮዎች አንዱን ይምረጡ።',
      'pdf_preview_title': 'የፒዲኤፍ ማጠቃለያ ማሳያ',
      'pdf_preview_sub': 'በይነተገናኝ አጫጭር የጥናት ካርዶች። ገጾችን ከታች ይቀይሩ።',
      'pdf_prev_btn': 'ቀዳሚ',
      'pdf_next_btn': 'ቀጣይ',
      'pdf_download_btn': 'ማውረድ (PDF)',
      'pdf_page_label': 'ገጽ',
    }
  };

  String _local(String key) {
    return _localizedValues[widget.languageCode]?[key] ?? key;
  }

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _phoneController = TextEditingController();

    // Log Screen View for Firebase Analytics
    logScreen('HomeScreen');

    _loadProfileData();
    _fadeController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200),
    );

    // Replicating tutorial video with standard Youtube embedded controller
    _loadBannerAd();
    _fadeController.forward();
    _checkAndShowTelegramDialog();
  }

  Future<void> _checkAndShowTelegramDialog() async {
    // Delay slightly so that the app loads and finishes rendering home page first
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        final isLight = !AppStateProvider.of(context).isDarkMode;
        final isAmharic = widget.languageCode == 'am';
        final primaryBlue = const Color(0xFF00BFFF);
        
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            decoration: BoxDecoration(
              color: isLight ? Colors.white : const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header/Top decorative banner with glowing telegram icon
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  decoration: BoxDecoration(
                    color: primaryBlue.withValues(alpha: 0.12),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: primaryBlue,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryBlue.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.telegram_rounded,
                        color: Colors.white,
                        size: 54,
                      ),
                    ),
                  ),
                ),
                
                // Text Content
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Column(
                    children: [
                      Text(
                        isAmharic ? 'የቴሌግራም ማህበረሰባችንን ይቀላቀሉ' : 'Join Our Telegram Community',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isLight ? const Color(0xFF0F172A) : Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isAmharic 
                            ? 'ለአዳዲስ ማሳወቂያዎች፣ ጠቃሚ ፒዲኤፍ (PDF) ሰነዶች እና ለማትሪክ ዝግጅት ፈጣን መረጃዎችን ለማግኘት የቴሌግራም ማህበረሰባችንን ይቀላቀሉ!'
                            : 'Connect with thousands of students! Get immediate matric updates, premium PDFs, daily short notes, and offline revision guides directly inside our channel.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Action Buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: isLight ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            isAmharic ? 'በኋላ' : 'Later',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            AnalyticsService.logTelegramBannerClicked(source: 'home_popup');
                            Navigator.of(dialogContext).pop();
                            final uri = Uri.parse('https://t.me/SmartX_Discussion');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shadowColor: primaryBlue.withValues(alpha: 0.3),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            isAmharic ? 'አሁን ይቀላቀሉ' : 'Join Now',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isLoggedIn = prefs.getBool('is_authenticated') ?? false;
      String? savedUid = prefs.getString('user_id');
      if (savedUid == null && _isLoggedIn) {
        savedUid = 'user_${DateTime.now().millisecondsSinceEpoch}_${(1000 + (DateTime.now().microsecondsSinceEpoch % 9000))}';
        prefs.setString('user_id', savedUid);
      }
      _userName = prefs.getString('user_fullName') ?? "Abebe Bekele";
      _userPhoneNumber = prefs.getString('user_phoneNumber') ?? "+251 911 234 567";

      // Populate text controllers
      _fullNameController.text = _userName;
      _phoneController.text = _userPhoneNumber.replaceAll(RegExp(r'^\+251\s*'), ''); // parse local digits
      
      debugPrint('Current user: $savedUid');
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _fadeController.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  /// Initialize AdMob and trigger async load for HomeScreen banner
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
          debugPrint('HomeScreen BannerAd failed to load: $err. Code: ${err.code}');
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

  @override
  Widget build(BuildContext context) {
    bool isLight = !widget.isDarkMode;
    final bool isCoursesActive = _currentIndex == 1;
    final bool isQuizActive = _currentIndex == 2;
    final bool isNotesActive = _currentIndex == 3;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isLight ? const Color(0xFFF5F7FA) : const Color(0xFF111827),
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: isLight ? Colors.white : const Color(0xFF1F2937),
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.menu,
            color: isLight ? const Color(0xFF0D2353) : Colors.white,
            size: 26,
          ),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        title: Text(
          isCoursesActive
              ? (widget.languageCode == 'en' ? 'Browse Courses' : 'ኮርሶችን ያስሱ')
              : (isQuizActive
                  ? (widget.languageCode == 'en' ? 'Quizzes' : 'ጥያቄዎች')
                  : (isNotesActive
                      ? (widget.languageCode == 'en' ? 'Short Notes' : 'አጫጭር ማስታወሻዎች')
                      : _local('title'))),
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w900,
            color: isLight ? const Color(0xFF0D2353) : Colors.white,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
                // Light/Dark Theme Switcher (Represents custom dark mode icon)
                IconButton(
                  icon: Icon(
                    widget.isDarkMode ? Icons.wb_sunny_rounded : Icons.nights_stay_outlined,
                    color: isLight ? const Color(0xFF0D2353) : Colors.amberAccent,
                    size: 24,
                  ),
                  onPressed: widget.onToggleTheme,
                ),
                
                // Compact, elegant language globe button matching design with EN/አማ
                GestureDetector(
                  onTap: widget.onToggleLanguage,
                  child: Container(
                    margin: const EdgeInsets.only(right: 16, left: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF374151),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.public_outlined,
                          size: 18,
                          color: isLight ? const Color(0xFF0D2353) : const Color(0xFF38BDF8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "EN/አማ",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: isLight ? const Color(0xFF0D2353) : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
      ),
      drawer: Drawer(
        backgroundColor: isLight ? Colors.white : const Color(0xFF1E293B),
        width: 250, // Decreased width for a very beautiful, compact design
        child: Column(
          children: [
            // Custom premium, highly compact header with academic repeat pattern and brand specifications
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 50, bottom: 20, left: 18, right: 18),
              decoration: const BoxDecoration(
                color: Color(0xFF0D2353), // Deep indigo
                image: DecorationImage(
                  image: AssetImage('assets/images/education_bg_pattern.png'),
                  repeat: ImageRepeat.repeat,
                  opacity: 0.12,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.school_rounded, // Graduation cap icon
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _isLoggedIn
                        ? (_userName.trim().isEmpty ? "Unknown Student" : _userName)
                        : "Smart X Ethiopia",
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isLoggedIn
                        ? (_userPhoneNumber.trim().isEmpty ? "+251992480372" : _userPhoneNumber)
                        : "Your Premium Learning Partner",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildDrawerTile(
                    icon: widget.isDarkMode ? Icons.wb_sunny_rounded : Icons.nights_stay_outlined,
                    title: widget.languageCode == 'en' ? 'Dark Mode' : 'ጨለምተኛ ሁነታ',
                    isSelected: false,
                    isLight: isLight,
                    trailing: Switch(
                      value: widget.isDarkMode,
                      activeThumbColor: const Color(0xFF00BFFF),
                      onChanged: (_) {
                        AppStateProvider.of(context).onToggleTheme();
                      },
                    ),
                    onTap: () {
                      AppStateProvider.of(context).onToggleTheme();
                    },
                  ),
                  _buildDrawerTile(
                    icon: Icons.help_outline_rounded,
                    title: widget.languageCode == 'en' ? 'Help & Support' : 'እርዳታ እና ድጋፍ',
                    isSelected: false,
                    isLight: isLight,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HelpSupportScreen(
                            isDarkMode: widget.isDarkMode,
                            languageCode: widget.languageCode,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildDrawerTile(
                    icon: Icons.info_outline_rounded,
                    title: widget.languageCode == 'en' ? 'About App' : 'ስለ መተግበሪያው',
                    isSelected: false,
                    isLight: isLight,
                    onTap: () {
                      Navigator.pop(context);
                      _showAboutAppModal(isLight);
                    },
                  ),
                  _buildDrawerTile(
                    icon: Icons.shield_outlined,
                    title: widget.languageCode == 'en' ? 'Privacy Policy' : 'የግል መመሪያ',
                    isSelected: false,
                    isLight: isLight,
                    onTap: () async {
                      Navigator.pop(context);
                      final Uri uri = Uri.parse('https://admi8829.github.io/privacy-policy.html/');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                  _buildDrawerTile(
                    icon: Icons.assignment_turned_in_outlined,
                    title: widget.languageCode == 'en' ? 'Terms of Service' : 'የአገልግሎት ውሎች',
                    isSelected: false,
                    isLight: isLight,
                    onTap: () async {
                      Navigator.pop(context);
                      final Uri uri = Uri.parse('https://admi8829.github.io/privacy-policy.html/');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Divider(
                color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                height: 1.0,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: _buildDrawerTile(
                icon: Icons.logout_rounded,
                title: widget.languageCode == 'en' ? 'Log Out' : 'ውጣ',
                isSelected: false,
                isLight: isLight,
                onTap: () {
                  Navigator.pop(context);
                  _showLogOutConfirmationDialog();
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: isLight ? const Color(0xFFF5F7FA) : const Color(0xFF111827),
                image: DecorationImage(
                        image: const AssetImage('assets/images/education_bg_pattern.png'),
                        repeat: ImageRepeat.repeat,
                        opacity: isLight ? 0.09 : 0.03,
                        colorFilter: isLight ? null : const ColorFilter.mode(Colors.white54, BlendMode.modulate),
                      ),
              ),
              child: _buildCurrentTab(isLight),
            ),
          ),
          if (_isBannerAdLoaded && _bannerAd != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14.0),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isLight ? Colors.white : const Color(0xFF1E293B),
                border: Border(
                  top: BorderSide(
                    color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                    width: 0.8,
                  ),
                ),
              ),
              child: SizedBox(
                height: 50.0,
                child: SizedBox(
                  width: _bannerAd!.size.width.toDouble(),
                  height: _bannerAd!.size.height.toDouble(),
                  child: AdWidget(ad: _bannerAd!),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isLight ? Colors.white.withValues(alpha: 0.8) : const Color(0xFF0F172A).withValues(alpha: 0.8),
          border: Border(
            top: BorderSide(
              color: isLight ? const Color(0xFFE2E8F0).withValues(alpha: 0.5) : const Color(0xFF334155).withValues(alpha: 0.5),
              width: 1.0,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: isLight 
                  ? const Color(0xFF0F1B2B).withValues(alpha: 0.04) 
                  : Colors.black.withValues(alpha: 0.25),
              blurRadius: 16.0,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
            child: SafeArea(
              child: SizedBox(
                height: 64.0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildBottomNavItem(
                      index: 0,
                      iconActive: Icons.home_rounded,
                      iconInactive: Icons.home_outlined,
                      label: _local('nav_home'),
                      isLight: isLight,
                    ),
                    _buildBottomNavItem(
                      index: 1,
                      iconActive: Icons.offline_pin_rounded,
                      iconInactive: Icons.offline_pin_outlined,
                      label: _local('nav_courses'),
                      isLight: isLight,
                    ),
                    _buildBottomNavItem(
                      index: 2,
                      iconActive: Icons.fact_check_rounded,
                      iconInactive: Icons.fact_check_outlined,
                      label: _local('nav_quiz'),
                      isLight: isLight,
                    ),
                    _buildBottomNavItem(
                      index: 3,
                      iconActive: Icons.article_rounded,
                      iconInactive: Icons.article_outlined,
                      label: _local('nav_notes'),
                      isLight: isLight,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentTab(bool isLight) {
    switch (_currentIndex) {
      case 0:
        return _buildHomeScreenContent(isLight);
      case 1:
        return _buildOfflineScreen(isLight);
      case 2:
        return _buildQuizScreenTab(isLight); // Quiz
      case 3:
        return _buildNotesScreenTab(isLight); // Notes
      default:
        return _buildHomeScreenContent(isLight);
    }
  }

  Widget _buildUnifiedSegmentedGradeSelector(bool isLight) {
    final List<int> grades = [9, 10, 11, 12];
    
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isLight ? const Color(0xFFEFF3F8) : const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(
          color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
          width: 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Row(
          children: grades.map((gradeNum) {
            final bool isSelected = _selectedGradeForNotesTab == gradeNum;
            final String title = widget.languageCode == 'en' ? 'G-$gradeNum' : 'ክ-$gradeNum';
            
            Color activeColor;
            switch (gradeNum) {
              case 9:
                activeColor = const Color(0xFF3B82F6);
                break;
              case 10:
                activeColor = const Color(0xFF10B981);
                break;
              case 11:
                activeColor = const Color(0xFFEA580C);
                break;
              case 12:
                activeColor = const Color(0xFF8B5CF6);
                break;
              default:
                activeColor = const Color(0xFF3B82F6);
            }

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedGradeForNotesTab = gradeNum;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? activeColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(20.0),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: activeColor.withValues(alpha: 0.2), // Softer, more elegant shadow color
                              blurRadius: 16.0, // Soft glowing effect
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.0,
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                      color: isSelected 
                          ? Colors.white 
                          : (isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8)),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildUnifiedSegmentedGradeSelectorForQuiz(bool isLight) {
    final List<int> grades = [9, 10, 11, 12];
    
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isLight ? const Color(0xFFEFF3F8) : const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(
          color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
          width: 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Row(
          children: grades.map((gradeNum) {
            final bool isSelected = _selectedGradeForQuizTab == gradeNum;
            final String title = widget.languageCode == 'en' ? 'G-$gradeNum' : 'ክ-$gradeNum';
            
            Color activeColor;
            switch (gradeNum) {
              case 9:
                activeColor = const Color(0xFF3B82F6);
                break;
              case 10:
                activeColor = const Color(0xFF10B981);
                break;
              case 11:
                activeColor = const Color(0xFFEA580C);
                break;
              case 12:
                activeColor = const Color(0xFF8B5CF6);
                break;
              default:
                activeColor = const Color(0xFF3B82F6);
            }

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedGradeForQuizTab = gradeNum;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? activeColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(20.0),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: activeColor.withValues(alpha: 0.2), // Softer, more elegant shadow color
                              blurRadius: 16.0, // Soft glowing effect
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.0,
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                      color: isSelected 
                          ? Colors.white 
                          : (isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8)),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildNotesScreenTab(bool isLight) {
    final List<Map<String, dynamic>> allSubjects = [
      {
        'id': 'Mathematics',
        'amTitle': 'ሂሳብ',
        'enTitle': 'Mathematics',
        'color': const Color(0xFF3B82F6), // Vibrant blue
        'lightBg': const Color(0xFFEFF6FF),
        'illustration': const DraftingGeometryWidget(),
      },
      {
        'id': 'Biology',
        'amTitle': 'ስነ-ህይወት',
        'enTitle': 'Biology',
        'color': const Color(0xFF10B981), // Emerald green
        'lightBg': const Color(0xFFECFDF5),
        'illustration': const CellBiologyWidget(),
      },
      {
        'id': 'Physics',
        'amTitle': 'ፊዚክስ',
        'enTitle': 'Physics',
        'color': const Color(0xFFDC2626), // Crimson red
        'lightBg': const Color(0xFFFEF2F2),
        'illustration': const AtomPhysicsWidget(),
      },
      {
        'id': 'Chemistry',
        'amTitle': 'ኬሚስትሪ',
        'enTitle': 'Chemistry',
        'color': const Color(0xFFEA580C), // Orange
        'lightBg': const Color(0xFFFFF7ED),
        'illustration': const ChemistryFlaskWidget(),
      },
      {
        'id': 'Geography',
        'amTitle': 'ጂኦግራፊ',
        'enTitle': 'Geography',
        'color': const Color(0xFF8E24AA), // Purple
        'lightBg': const Color(0xFFFDF4FF),
        'illustration': const WorldMapGeographyWidget(),
      },
      {
        'id': 'History',
        'amTitle': 'ታሪክ',
        'enTitle': 'History',
        'color': const Color(0xFFD97706), // Brown gold
        'lightBg': const Color(0xFFFEF3C7),
        'illustration': const AksumObeliskWidget(),
      },
      {
        'id': 'English',
        'amTitle': 'እንግሊዝኛ',
        'enTitle': 'English',
        'color': const Color(0xFF6D28D9),
        'lightBg': const Color(0xFFF5F3FF),
        'illustration': const EnglishBookWidget(),
      },
      {
        'id': 'Civics',
        'amTitle': 'ዜግነት',
        'enTitle': 'Civics',
        'color': const Color(0xFF1E88E5), // Blue civics
        'lightBg': const Color(0xFFEFF6FF),
        'illustration': const CivicsGavelWidget(),
      },
      {
        'id': 'Economics',
        'amTitle': 'ኢኮኖሚክስ',
        'enTitle': 'Economics',
        'color': const Color(0xFF0F766E),
        'lightBg': const Color(0xFFF0FDFA),
        'illustration': const EconomicsChartWidget(),
      },
      {
        'id': 'Agriculture',
        'amTitle': 'ግብርና',
        'enTitle': 'Agriculture',
        'color': const Color(0xFF8D6E63), // Brown
        'lightBg': const Color(0xFFEFEBE9),
        'illustration': const AgricultureSproutWidget(),
      },
    ];

    final List<Map<String, dynamic>> subjects;
    if (_selectedGradeForNotesTab == 11 || _selectedGradeForNotesTab == 12) {
      subjects = allSubjects.where((s) => s['id'] != 'Civics').toList();
    } else {
      subjects = allSubjects.where((s) => s['id'] != 'Agriculture').toList();
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
        image: DecorationImage(
          image: const AssetImage('assets/images/education_bg_pattern.png'),
          repeat: ImageRepeat.repeat,
          opacity: isLight ? 0.09 : 0.03,
          colorFilter: isLight ? null : const ColorFilter.mode(Colors.white54, BlendMode.modulate),
        ),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [


            // Upgraded pill-shaped unified segmented grade selector matching image
            _buildUnifiedSegmentedGradeSelector(isLight),
            const SizedBox(height: 18.0),

            // Upgraded vertical list of beautiful cards
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: subjects.length,
              itemBuilder: (context, index) {
                final subject = subjects[index];
                final String subjectTitle = widget.languageCode == 'en' ? subject['enTitle'] : subject['amTitle'];
                final String subjectSubtitle = widget.languageCode == 'en' ? 'Grade $_selectedGradeForNotesTab' : 'ክፍል $_selectedGradeForNotesTab';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12.0),
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: isLight ? Colors.white : const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(
                      color: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF334155),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isLight ? 0.03 : 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Circular subject illustration container
                      Container(
                        width: 52,
                        height: 52,
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: isLight ? subject['lightBg'] : subject['color'].withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: SizedBox(
                            width: 32,
                            height: 32,
                            child: subject['illustration'],
                          ),
                        ),
                      ),
                      const SizedBox(width: 14.0),
                      // Text block (Title & Grade Subtitle)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subjectTitle,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w900,
                                color: isLight ? const Color(0xFF1E293B) : Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2.5),
                            Text(
                              subjectSubtitle,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Beautiful custom START button with gradient and themed shadow
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => UnitSelectionScreen(
                                grade: _selectedGradeForNotesTab,
                                subjectId: subject['id'],
                                enTitle: subject['enTitle'],
                                amTitle: subject['amTitle'],
                                color: subject['color'],
                                icon: subject['illustration'],
                                isDarkMode: widget.isDarkMode,
                                languageCode: widget.languageCode,
                                onToggleTheme: widget.onToggleTheme,
                                onToggleLanguage: widget.onToggleLanguage,
                                isShortNotesMode: true,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 9.0),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                subject['color'],
                                Color.lerp(subject['color'], Colors.black, 0.12) ?? subject['color'],
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(30.0),
                            boxShadow: [
                              BoxShadow(
                                color: subject['color'].withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 3.5),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.languageCode == 'en' ? 'SHORT NOTE' : 'አጫጭር ማስታወሻ',
                                style: const TextStyle(
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              const SizedBox(width: 4.0),
                              const Icon(
                                Icons.chevron_right_rounded,
                                size: 14.0,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerTile({
    required IconData icon,
    required String title,
    required bool isSelected,
    required bool isLight,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 1.0),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? (isLight ? const Color(0xFFFFF3E0) : const Color(0xFFFF6D00).withValues(alpha: 0.15))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: ListTile(
          dense: true,
          visualDensity: const VisualDensity(horizontal: -4, vertical: -3),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
          leading: Icon(
            icon,
            color: isSelected
                ? const Color(0xFFFF6D00)
                : (isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8)),
            size: 20,
          ),
          title: Text(
            title,
            style: TextStyle(
              color: isSelected
                  ? const Color(0xFFFF6D00)
                  : (isLight ? const Color(0xFF0F172A) : Colors.white),
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
              fontSize: 13.0,
            ),
          ),
          trailing: trailing,
          onTap: onTap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      ),
    );
  }

  Widget _animateItem({required Widget child, required int index}) {
    final curver = CurvedAnimation(
      parent: _fadeController,
      curve: Interval(
        (0.05 + (index * 0.12)).clamp(0.0, 1.0),
        (0.55 + (index * 0.12)).clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );
    return FadeTransition(
      opacity: _fadeController,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.0, 0.14),
          end: Offset.zero,
        ).animate(curver),
        child: child,
      ),
    );
  }

  Widget _buildHomeScreenContent(bool isLight) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. EXISTING: Image Carousel Slider
          _animateItem(
            index: 1,
            child: ImageSliderCarousel(
              isDarkMode: !isLight,
              languageCode: widget.languageCode,
            ),
          ),

          const SizedBox(height: 12.0),

          // Section Title: Grade selection
          _animateItem(
            index: 2,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Text(
                widget.languageCode == 'en' ? 'Select Your Grade' : 'ክፍልዎን ይምረጡ',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w900,
                  color: isLight ? const Color(0xFF0F172A) : Colors.white,
                ),
              ),
            ),
          ),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
            childAspectRatio: 1.1, // Adjusted childAspectRatio for a perfect fit without progress bars
            children: [
              // Grade 9
              _animateItem(
                index: 3,
                child: _InteractiveGradeCard(
                  title: _local('g9_title'),
                  subtitle: _local('g9_sub'),
                  illustration: _buildScrollIllustration(),
                  btnColor: const Color(0xFF0084FF),
                  isLight: isLight,
                  statusText: widget.languageCode == 'en' ? "GRADE 9" : "ክፍል 9",
                  buttonText: _local('start_course_btn'),
                  onTap: () => _navigateToGradeScreen(9),
                  progress: 0.65,
                ),
              ),
              // Grade 10
              _animateItem(
                index: 4,
                child: _InteractiveGradeCard(
                  title: _local('g10_title'),
                  subtitle: _local('g10_sub'),
                  illustration: _buildShieldIllustration(),
                  btnColor: const Color(0xFF10B981),
                  isLight: isLight,
                  statusText: widget.languageCode == 'en' ? "GRADE 10" : "ክፍል 10",
                  buttonText: _local('start_course_btn'),
                  onTap: () => _navigateToGradeScreen(10),
                  progress: 0.40,
                ),
              ),
              // Grade 11
              _animateItem(
                index: 5,
                child: _InteractiveGradeCard(
                  title: _local('g11_title'),
                  subtitle: _local('g11_sub'),
                  illustration: _buildOrbitIllustration(),
                  btnColor: const Color(0xFFF59E0B),
                  isLight: isLight,
                  statusText: widget.languageCode == 'en' ? "GRADE 11" : "ክፍል 11",
                  buttonText: _local('start_course_btn'),
                  onTap: () => _navigateToGradeScreen(11),
                  progress: 0.85,
                ),
              ),
              // Grade 12
              _animateItem(
                index: 6,
                child: _InteractiveGradeCard(
                  title: _local('g12_title'),
                  subtitle: _local('g12_sub'),
                  illustration: _buildGraduateIllustration(),
                  btnColor: const Color(0xFF8B5CF6),
                  isLight: isLight,
                  statusText: widget.languageCode == 'en' ? "GRADE 12" : "ክፍል 12",
                  buttonText: _local('start_course_btn'),
                  onTap: () => _navigateToGradeScreen(12),
                  progress: 0.20,
                ),
              ),
            ],
          ),

          // New Social boxes right below Grade selection
          const SizedBox(height: 24.0),
          _animateItem(
            index: 7,
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final uri = Uri.parse('https://t.me/SmartX_Discussion');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    borderRadius: BorderRadius.circular(16.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 16.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00BFFF).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(
                          color: const Color(0xFF00BFFF).withValues(alpha: 0.25),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00BFFF).withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.telegram_rounded,
                              color: Color(0xFF00BFFF),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.languageCode == 'en' ? 'Join Telegram' : 'ቴሌግራም ይቀላቀሉ',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: isLight ? const Color(0xFF0F172A) : Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2.0),
                                Text(
                                  '@SmartX_Discussion',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final uri = Uri.parse('https://www.youtube.com/@smartx.ethiopia');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    borderRadius: BorderRadius.circular(16.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 16.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.25),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_circle_fill_rounded,
                              color: Color(0xFFEF4444),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.languageCode == 'en' ? 'Subscribe YouTube' : 'ዩቲዩብ ሰብስክራይብ',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: isLight ? const Color(0xFF0F172A) : Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2.0),
                                Text(
                                  'Smart X Ethiopia',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }









  // --- Beautiful Custom stacked vector illustrations matching image ---
  Widget _buildScrollIllustration() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Transform.rotate(
          angle: -0.15,
          child: Container(
            height: 48,
            width: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFFFB74D), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(1, 2),
                )
              ]
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(3, (i) => Container(height: 1.8, width: 22, color: const Color(0xFFFFD54F))),
            ),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.all(3.5),
            decoration: const BoxDecoration(
              color: Color(0xFFE53935),
              shape: BoxShape.circle,
            ),
            child: const Text("A+", style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildShieldIllustration() {
    return Stack(
      alignment: Alignment.center,
      children: [
        const Icon(
          Icons.shield_outlined,
          color: Color(0xFF2E7D32),
          size: 46,
        ),
        Positioned(
          child: Icon(
            Icons.nature_people_outlined,
            color: const Color(0xFF2E7D32).withValues(alpha: 0.4),
            size: 20,
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.all(3.5),
            decoration: const BoxDecoration(
              color: Color(0xFF2E7D32),
              shape: BoxShape.circle,
            ),
            child: const Text("A+", style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold)),
          ),
        )
      ],
    );
  }

  Widget _buildOrbitIllustration() {
    return Stack(
      alignment: Alignment.center,
      children: [
        const Icon(
          Icons.analytics_outlined,
          color: Color(0xFFEF6C00),
          size: 46,
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.all(3.5),
            decoration: const BoxDecoration(
              color: Color(0xFFEF6C00),
              shape: BoxShape.circle,
            ),
            child: const Text("A+", style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildGraduateIllustration() {
    return Stack(
      alignment: Alignment.center,
      children: [
        const Icon(
          Icons.public_outlined,
          color: Color(0xFF6A1B9A),
          size: 46,
        ),
        Positioned(
          top: 0,
          child: Icon(
            Icons.school_outlined,
            color: const Color(0xFF6A1B9A).withValues(alpha: 0.8),
            size: 18,
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.all(3.5),
            decoration: const BoxDecoration(
              color: Color(0xFF6A1B9A),
              shape: BoxShape.circle,
            ),
            child: const Text("A+", style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  void _openSubjectsForGrade(int grade, {required bool isShortNotes}) async {
    final prefs = await SharedPreferences.getInstance();
    String sub = "Mathematics";
    String title = "Unit 1: Functions and Calculus Intro";
    int colorInt = 0xFF0084FF;
    if (grade == 9) {
      sub = "Mathematics";
      title = "Unit 1: Number Systems and Logic";
      colorInt = 0xFF0084FF;
    } else if (grade == 10) {
      sub = "Biology";
      title = "Unit 2: Cells and Microorganisms";
      colorInt = 0xFF10B981;
    } else if (grade == 11) {
      sub = "Physics";
      title = "Unit 3: Electromagnetism and Magnet";
      colorInt = 0xFFF59E0B;
    } else if (grade == 12) {
      sub = "Mathematics";
      title = "Unit 1: Sequence & Series Matric Prep";
      colorInt = 0xFF8B5CF6;
    }
    await prefs.setInt('last_lesson_grade', grade);
    await prefs.setString('last_lesson_subject', sub);
    await prefs.setString('last_lesson_title', title);
    await prefs.setInt('last_lesson_color', colorInt);
    _loadProfileData();

    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SubjectSelectionScreen(
            grade: grade,
            isDarkMode: widget.isDarkMode,
            languageCode: widget.languageCode,
            onToggleTheme: widget.onToggleTheme,
            onToggleLanguage: widget.onToggleLanguage,
            isFromHome: true,
            isShortNotesMode: isShortNotes,
          ),
        ),
      );
    }
  }

  void _navigateToGradeScreen(int grade) {
    final bool isLight = !widget.isDarkMode;
    final bool isAmharic = widget.languageCode == 'am';

    // Log Grade Selection Screen for Firebase Analytics
    logScreen('GradeSelectionScreen');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        final sheetBg = isLight ? Colors.white : const Color(0xFF0F172A);
        final headerColor = isLight ? const Color(0xFF0F172A) : Colors.white;
        final descColor = isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

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
                      width: 40,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isAmharic ? 'ክፍል $grade - ምን መማር ይፈልጋሉ?' : 'Grade $grade - What do you want to learn?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: headerColor,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isAmharic ? 'የሚፈልጉትን የትምህርት አቀራረብ ይምረጡ' : 'Select your preferred study mode below.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: descColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Option 1: Interactive Quizzes
                  InkWell(
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _openSubjectsForGrade(grade, isShortNotes: false);
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
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00BFFF).withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.fact_check_rounded, color: Color(0xFF00BFFF), size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isAmharic ? 'በይነተገናኝ ጥያቄዎች (Quizzes)' : 'Interactive Quizzes',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: headerColor),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isAmharic ? 'በየምዕራፉ ያሉ ፈተናዎችን እና የልምምድ ጥያቄዎችን ይስሩ' : 'Practice unit-by-unit exam questions and track scores.',
                                  style: TextStyle(fontSize: 12, color: descColor, fontWeight: FontWeight.w500),
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
                  
                  // Option 2: Short Notes
                  InkWell(
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _openSubjectsForGrade(grade, isShortNotes: true);
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
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.article_rounded, color: Color(0xFF10B981), size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isAmharic ? 'አጫጭር ማስታወሻዎች (Short Notes)' : 'Short Notes',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: headerColor),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isAmharic ? 'አጫጭር የማጠቃለያ ማስታወሻዎችን እና ቀመሮችን ያንብቡ' : 'Quick revision guides, formulas, and unit summaries.',
                                  style: TextStyle(fontSize: 12, color: descColor, fontWeight: FontWeight.w500),
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


  Widget _buildOfflineScreen(bool isLight) {
    return FutureBuilder<Set<String>>(
      future: OfflineManager.getDownloadedUnitIds(),
      builder: (context, snapshot) {
        final downloadedIds = snapshot.data ?? {};
        
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 26.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Title
              Text(
                widget.languageCode == 'en' ? 'Offline Study Hub' : 'ከመስመር ውጭ የጥናት ማህደር',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: isLight ? const Color(0xFF0F172A) : Colors.white,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.languageCode == 'en'
                    ? 'Your downloaded practice quizzes are available 100% offline.'
                    : 'ያወረዷቸው ፈተናዎች ያለ በይነመረብ (Offline) እዚህ ይሰራሉ።',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                  color: isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 24),
              
              if (downloadedIds.isEmpty) ...[
                // Beautiful guide card on how to download if empty
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  decoration: BoxDecoration(
                    color: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(24.0),
                    border: Border.all(
                      color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E88E5).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.cloud_download_outlined,
                          size: 32,
                          color: Color(0xFF1E88E5),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.languageCode == 'en' ? 'No downloads yet' : 'እስካሁን የወረደ ፋይል የለም',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: isLight ? const Color(0xFF0F172A) : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.languageCode == 'en'
                            ? 'To access lessons offline, select any Grade on the Home Screen, browse your courses/subjects, open any Unit Explorer, and tap the "Download" button to save files instantly.'
                            : 'የትምህርት ክፍሎችን ያለ በይነመረብ ለማግኘት መነሻ ገጽ ላይ ክፍልዎን ይምረጡ፣ የሚፈልጉትን ትምህርት ከገቡ በኋላ "ያውርዱ" የሚለውን ቁልፍ ይጫኑ።',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                          color: isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // List of downloaded units
                ...downloadedIds.map((id) {
                  final unitInfo = _lookupUnitInfo(id);
                  final String title = widget.languageCode == 'en' ? unitInfo['enUnit'] : unitInfo['amUnit'];
                  final String subject = unitInfo['subject'];
                  final IconData icon = unitInfo['icon'];
                  final Color color = unitInfo['color'];
                  return FutureBuilder<OfflineMetadata?>(
                    future: OfflineManager.getOfflineMetadata(id),
                    builder: (context, metaSnapshot) {
                      final meta = metaSnapshot.data;
                      final int grade = meta?.grade ?? 9;
                      final bool isNotes = meta?.type == 'note' || id.endsWith('_notes');
                      
                      final Map<String, String> amSubjects = {
                        'Mathematics': 'ሂሳብ',
                        'Biology': 'ስነ-ህይወት',
                        'Physics': 'ፊዚክስ',
                        'Chemistry': 'ኬሚስትሪ',
                        'Geography': 'ጂኦግራፊ',
                        'History': 'ታሪክ',
                        'Civics': 'ዜግነት',
                        'Agriculture': 'ግብርና',
                      };
                      final String localizedSubject = widget.languageCode == 'en' 
                          ? subject 
                          : (amSubjects[subject] ?? subject);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: isLight ? Colors.white : const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                            width: 1.1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    icon,
                                    color: color,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: color.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              widget.languageCode == 'en' ? 'Grade $grade' : 'ክፍል $grade',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w900,
                                                color: color,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            localizedSubject,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w900,
                                              color: isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                                            ),
                                          ),
                                          const Spacer(),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.check_circle_rounded, size: 10, color: Color(0xFF10B981)),
                                                const SizedBox(width: 4),
                                                Text(
                                                  widget.languageCode == 'en' ? 'Offline' : 'ከመስመር ውጭ',
                                                  style: const TextStyle(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w900,
                                                    color: Color(0xFF10B981),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        title,
                                        style: TextStyle(
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.w900,
                                          color: isLight ? const Color(0xFF0F172A) : Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: TextButton.icon(
                                    onPressed: () async {
                                      final int unitNum = meta?.unit ?? int.tryParse(RegExp(r'u(\d+)').firstMatch(id)?.group(1) ?? '1') ?? 1;
                                      
                                      if (isNotes) {
                                        if (context.mounted) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => NotesScreen(
                                                grade: grade,
                                                subjectId: subject,
                                                unitNumber: unitNum,
                                                unitTitle: title,
                                                themeColor: color,
                                                isDarkMode: widget.isDarkMode,
                                                languageCode: widget.languageCode,
                                              ),
                                            ),
                                          );
                                        }
                                      } else {
                                        if (context.mounted) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => QuizScreen(
                                                grade: grade,
                                                subject: subject,
                                                unit: unitNum,
                                                isOffline: true,
                                                offlineUnitId: id,
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    icon: Icon(isNotes ? Icons.menu_book_rounded : Icons.play_arrow_rounded, size: 16),
                                    label: Text(
                                      isNotes 
                                          ? (widget.languageCode == 'en' ? 'Read Notes' : 'ማስታወሻ አንብብ')
                                          : (widget.languageCode == 'en' ? 'Take Quiz' : 'ፈተና ጀምር'),
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                                    ),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      backgroundColor: color,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () => _confirmDeleteDownload(id, title),
                                  icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFEF4444)),
                                  style: IconButton.styleFrom(
                                    backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.08),
                                    padding: const EdgeInsets.all(10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }),
              ],
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteDownload(String id, String unitTitle) {
    showDialog(
      context: context,
      builder: (context) {
        final isLight = !widget.isDarkMode;
        return AlertDialog(
          backgroundColor: isLight ? Colors.white : const Color(0xFF1E293B),
          title: Text(
            widget.languageCode == 'en' ? 'Delete offline questions?' : 'ጥያቄዎችን ያጥፉ?',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          content: Text(
            widget.languageCode == 'en'
                ? 'Are you sure you want to remove "$unitTitle" offline questions from your device?'
                : '"$unitTitle" ከመስመር ውጭ የተቀመጡ ጥያቄዎችን ማጥፋት ይፈልጋሉ?',
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                widget.languageCode == 'en' ? 'Cancel' : 'አይ',
                style: TextStyle(color: isLight ? const Color(0xFF475569) : Colors.white60, fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
              onPressed: () async {
                await OfflineManager.removeDownload(id);
                if (context.mounted) {
                  Navigator.pop(context);
                  setState(() {}); // refresh list
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        widget.languageCode == 'en'
                            ? 'Offline package removed'
                            : 'ከመስመር ውጭ የነበረው ማህደር ተሰርዟል',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: const Color(0xFFEF4444),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: Text(
                widget.languageCode == 'en' ? 'Delete' : 'አጥፋ',
                style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w900),
              ),
            ),
          ],
        );
      },
    );
  }

  Map<String, dynamic> _lookupUnitInfo(String id) {
    final Map<String, Map<String, dynamic>> unitsDb = {
      'math_u1': {
        'enUnit': 'Unit 1: The Number System',
        'amUnit': 'ክፍል 1: የቁጥር ስርዓት',
        'subject': 'Mathematics',
        'icon': Icons.functions_rounded,
        'color': const Color(0xFF0084FF),
      },
      'bio_u1': {
        'enUnit': 'Unit 1: Introduction to Biology',
        'amUnit': 'ክፍል 1: ስለ ስነ-ህይወት መግቢያ',
        'subject': 'Biology',
        'icon': Icons.biotech_rounded,
        'color': const Color(0xFF2E7D32),
      },
    };

    if (unitsDb.containsKey(id)) {
      return unitsDb[id]!;
    }

    String subject = "General";
    IconData icon = Icons.offline_pin_rounded;
    Color color = const Color(0xFF8B5CF6);

    if (id.contains('math')) {
      subject = "Mathematics";
      icon = Icons.functions_rounded;
      color = const Color(0xFF0084FF);
    } else if (id.contains('bio')) {
      subject = "Biology";
      icon = Icons.biotech_rounded;
      color = const Color(0xFF2E7D32);
    } else if (id.contains('phys')) {
      subject = "Physics";
      icon = Icons.bolt_rounded;
      color = const Color(0xFFE53935);
    } else if (id.contains('chem')) {
      subject = "Chemistry";
      icon = Icons.science_rounded;
      color = const Color(0xFFD81B60);
    } else if (id.contains('geo')) {
      subject = "Geography";
      icon = Icons.public_rounded;
      color = const Color(0xFF0F766E);
    } else if (id.contains('hist')) {
      subject = "History";
      icon = Icons.account_balance_rounded;
      color = const Color(0xFFCA8A04);
    } else if (id.contains('civ')) {
      subject = "Civics";
      icon = Icons.gavel_rounded;
      color = const Color(0xFF475569);
    } else if (id.contains('agri')) {
      subject = "Agriculture";
      icon = Icons.agriculture_rounded;
      color = const Color(0xFF15803D);
    }

    String unitNum = "1";
    final match = RegExp(r'u(\d+)').firstMatch(id);
    if (match != null) {
      unitNum = match.group(1) ?? "1";
    }

    return {
      'enUnit': 'Unit $unitNum: Complete Package',
      'amUnit': 'ክፍል $unitNum: አጠቃላይ ፓኬጅ',
      'subject': subject,
      'icon': icon,
      'color': color,
    };
  }

  Widget _buildQuizScreenTab(bool isLight) {
    final List<Map<String, dynamic>> allSubjects = [
      {
        'id': 'Mathematics',
        'amTitle': 'ሂሳብ',
        'enTitle': 'Mathematics',
        'color': const Color(0xFF3B82F6), // Vibrant blue
        'lightBg': const Color(0xFFEFF6FF),
        'illustration': const DraftingGeometryWidget(),
      },
      {
        'id': 'Biology',
        'amTitle': 'ስነ-ህይወት',
        'enTitle': 'Biology',
        'color': const Color(0xFF10B981), // Emerald green
        'lightBg': const Color(0xFFECFDF5),
        'illustration': const CellBiologyWidget(),
      },
      {
        'id': 'Physics',
        'amTitle': 'ፊዚክስ',
        'enTitle': 'Physics',
        'color': const Color(0xFFDC2626), // Crimson red
        'lightBg': const Color(0xFFFEF2F2),
        'illustration': const AtomPhysicsWidget(),
      },
      {
        'id': 'Chemistry',
        'amTitle': 'ኬሚስትሪ',
        'enTitle': 'Chemistry',
        'color': const Color(0xFFEA580C), // Orange
        'lightBg': const Color(0xFFFFF7ED),
        'illustration': const ChemistryFlaskWidget(),
      },
      {
        'id': 'Geography',
        'amTitle': 'ጂኦግራፊ',
        'enTitle': 'Geography',
        'color': const Color(0xFF8E24AA), // Purple
        'lightBg': const Color(0xFFFDF4FF),
        'illustration': const WorldMapGeographyWidget(),
      },
      {
        'id': 'History',
        'amTitle': 'ታሪክ',
        'enTitle': 'History',
        'color': const Color(0xFFD97706), // Brown gold
        'lightBg': const Color(0xFFFEF3C7),
        'illustration': const AksumObeliskWidget(),
      },
      {
        'id': 'English',
        'amTitle': 'እንግሊዝኛ',
        'enTitle': 'English',
        'color': const Color(0xFF6D28D9),
        'lightBg': const Color(0xFFF5F3FF),
        'illustration': const EnglishBookWidget(),
      },
      {
        'id': 'Civics',
        'amTitle': 'ዜግነት',
        'enTitle': 'Civics',
        'color': const Color(0xFF1E88E5), // Blue civics
        'lightBg': const Color(0xFFEFF6FF),
        'illustration': const CivicsGavelWidget(),
      },
      {
        'id': 'Economics',
        'amTitle': 'ኢኮኖሚክስ',
        'enTitle': 'Economics',
        'color': const Color(0xFF0F766E),
        'lightBg': const Color(0xFFF0FDFA),
        'illustration': const EconomicsChartWidget(),
      },
      {
        'id': 'Agriculture',
        'amTitle': 'ግብርና',
        'enTitle': 'Agriculture',
        'color': const Color(0xFF8D6E63), // Brown
        'lightBg': const Color(0xFFEFEBE9),
        'illustration': const AgricultureSproutWidget(),
      },
    ];

    final List<Map<String, dynamic>> subjects;
    if (_selectedGradeForQuizTab == 11 || _selectedGradeForQuizTab == 12) {
      subjects = allSubjects.where((s) => s['id'] != 'Civics').toList();
    } else {
      subjects = allSubjects.where((s) => s['id'] != 'Agriculture').toList();
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
        image: DecorationImage(
          image: const AssetImage('assets/images/education_bg_pattern.png'),
          repeat: ImageRepeat.repeat,
          opacity: isLight ? 0.09 : 0.03,
          colorFilter: isLight ? null : const ColorFilter.mode(Colors.white54, BlendMode.modulate),
        ),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [


            // Redesigned compact pill-shaped unified segmented grade selector
            _buildUnifiedSegmentedGradeSelectorForQuiz(isLight),
            const SizedBox(height: 18.0),

            // Subject Cards Grid (GridView.builder) matching the requested high-fidelity bento grid 100%
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                childAspectRatio: 0.92, // Optimized ratio for taller, elegant cards with floating buttons
              ),
              itemCount: subjects.length,
              itemBuilder: (context, index) {
                final subject = subjects[index];
                
                // Helper to get grade-based color accents
                Color getGradeColor(int g) {
                  switch (g) {
                    case 9:
                      return const Color(0xFF0084FF); // Blue
                    case 10:
                      return const Color(0xFF10B981); // Emerald Green
                    case 11:
                      return const Color(0xFFEA580C); // Warm Orange
                    case 12:
                      return const Color(0xFF8B5CF6); // Purple
                    default:
                      return const Color(0xFF0084FF);
                  }
                }

                return InteractiveSubjectCard(
                  amTitle: subject['amTitle'],
                  enTitle: subject['enTitle'],
                  color: subject['color'],
                  illustration: subject['illustration'],
                  isLight: isLight,
                  gradeColor: getGradeColor(_selectedGradeForQuizTab),
                  languageCode: widget.languageCode,
                  grade: _selectedGradeForQuizTab,
                  btnText: widget.languageCode == 'en' ? 'START' : 'ጀምር',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => UnitSelectionScreen(
                          grade: _selectedGradeForQuizTab,
                          subjectId: subject['id'],
                          enTitle: subject['enTitle'],
                          amTitle: subject['amTitle'],
                          color: subject['color'],
                          icon: subject['illustration'],
                          isDarkMode: widget.isDarkMode,
                          languageCode: widget.languageCode,
                          onToggleTheme: widget.onToggleTheme,
                          onToggleLanguage: widget.onToggleLanguage,
                          isShortNotesMode: false, // Quizzes mode
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }














  Widget _buildBottomNavItem({
    required int index,
    required IconData iconActive,
    required IconData iconInactive,
    required String label,
    required bool isLight,
  }) {
    final bool isSelected = _currentIndex == index;
    final Color activeColor = isLight ? const Color(0xFF0E7896) : const Color(0xFF00BFFF);
    final Color inactiveColor = isLight ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF); // Gray color
    
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
          switch (index) {
            case 0:
              logScreen('HomeScreen');
              break;
            case 1:
              logScreen('OfflineScreen');
              break;
            case 2:
              logScreen('QuizScreen');
              break;
            case 3:
              logScreen('ShortNotesScreen');
              break;
          }
        },
        child: Container(
          color: Colors.transparent,
          height: 64.0,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 3.0,
                width: 44.0,
                decoration: BoxDecoration(
                  color: isSelected ? activeColor : Colors.transparent,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(3),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSelected ? iconActive : iconInactive,
                      color: isSelected ? activeColor : inactiveColor,
                      size: 26,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? activeColor : inactiveColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4), // small bottom padding
            ],
          ),
        ),
      ),
    );
  }


  void _showAboutAppModal(bool isLight) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isLight ? Colors.white : const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline_rounded, size: 48, color: isLight ? const Color(0xFF0D2353) : Colors.white),
              const SizedBox(height: 12),
              Text(
                'Smart X ET',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: isLight ? const Color(0xFF0D2353) : Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.languageCode == 'en'
                    ? 'Version: 1.0.0+1 (Stable Build)\n\nAn advanced e-learning platform specifically crafted for Grade 9 to 12 Ethiopian high school students to access summaries, matric practice exams, interactive digital cheat-cards, and video walkthrough lessons.'
                    : 'ስሪት: 1.0.0+1 (የተረጋጋ)\n\nለ9-12ኛ ክፍል ኢትዮጵያዊያን ተማሪዎች የተዘጋጀ የቪዲዮ ትምህርቶች፣ ማጠቃለያዎች፣ የአጭር ጊዜ የጥናት መረጃዎች ሙሉ በሙሉ ተከፍተዋል።',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  height: 1.4,
                  color: isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showLogOutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final bool isLight = Theme.of(context).brightness == Brightness.light;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          backgroundColor: isLight ? Colors.white : const Color(0xFF1E293B),
          title: Text(
            widget.languageCode == 'en' ? 'Log Out' : 'መለያ ውጣ',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          content: Text(
            widget.languageCode == 'en' 
                ? 'Are you sure you want to log out of your Smart X ET student profile? Your local study stats will remain saved.'
                : 'ከስማርት ኤክስ መለያዎ መውጣት እርግጠኛ ነዎት? የዚህ መሣሪያ የጥናት ሂደትዎ አይጠፋም።',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                widget.languageCode == 'en' ? 'Cancel' : 'ሰርዝ',
                style: TextStyle(fontWeight: FontWeight.bold, color: isLight ? Colors.black54 : Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await OfflineManager.clearAll();
                
                // Reload stats and profile defaults dynamically
                _loadProfileData(); 
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        widget.languageCode == 'en' ? "Successfully logged out!" : "በስኬት ወጥተዋል!",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );

                  // Navigate to SplashScreen and remove all other screens in history
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => SplashScreen(
                        isDarkMode: widget.isDarkMode,
                        languageCode: widget.languageCode,
                        onToggleTheme: widget.onToggleTheme,
                        onToggleLanguage: widget.onToggleLanguage,
                      ),
                    ),
                    (route) => false,
                  );
                }
              },
              child: Text(
                widget.languageCode == 'en' ? 'Confirm Log Out' : 'ውጣ',
                style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.blue),
              ),
            ),
          ],
        );
      },
    );
  }

}

class _InteractiveGradeCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final Widget illustration;
  final Color btnColor;
  final bool isLight;
  final VoidCallback onTap;
  final String statusText;
  final String buttonText;
  final double progress;

  const _InteractiveGradeCard({
    required this.title,
    required this.subtitle,
    required this.illustration,
    required this.btnColor,
    required this.isLight,
    required this.onTap,
    required this.statusText,
    required this.buttonText,
    required this.progress,
  });

  @override
  State<_InteractiveGradeCard> createState() => _InteractiveGradeCardState();
}

class _InteractiveGradeCardState extends State<_InteractiveGradeCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) {
        setState(() {
          _scale = 0.96;
        });
      },
      onPointerUp: (event) {
        setState(() {
          _scale = 1.0;
        });
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          transform: Matrix4.identity()..scale(_scale),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.isLight ? Colors.white : const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(18.0),
            border: Border.all(
              color: Colors.white,
              width: 2.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: widget.isLight ? 0.06 : 0.22),
                blurRadius: 14.0,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0), // Elegant tighter padding to fit the shortened box
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Upper row containing title/subtitle on left and custom graphics/illustration on right
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16.0, // Slightly more compact font to prevent overflow
                              fontWeight: FontWeight.w900,
                              color: widget.isLight ? const Color(0xFF0F172A) : Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 1.0),
                          Expanded(
                            child: Text(
                              widget.subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10.0, // Tighter font size
                                fontWeight: FontWeight.w600,
                                color: widget.isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                height: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4.0),
                    // Premium illustration with custom compact size
                    SizedBox(
                      height: 34, // Slightly more compact to give the button maximum space
                      width: 34,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: widget.illustration,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6.0),

              // Pill button styled EXACTLY like a beautiful modern gradient pill button, made LARGER
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10.0), // Increased button height from 9.0 to 10.0
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF52C29F), // Vibrant mint teal
                      widget.btnColor, // Accent theme color for each grade category
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(24.0), // Proper pill button rounding
                  boxShadow: [
                    BoxShadow(
                      color: widget.btnColor.withValues(alpha: 0.24),
                      blurRadius: 8.0,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.buttonText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.0, // Increased font size from 12.0 to 13.0
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(width: 4.0),
                    const Icon(
                      Icons.chevron_right, // Required chevron_right arrow icon
                      color: Colors.white,
                      size: 14.0,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HelpSupportScreen extends StatelessWidget {
  final bool isDarkMode;
  final String languageCode;

  const HelpSupportScreen({
    super.key,
    required this.isDarkMode,
    required this.languageCode,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLight = !isDarkMode;
    final Color bgColor = isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final Color cardColor = isLight ? Colors.white : const Color(0xFF1E293B);
    final Color textColor = isLight ? const Color(0xFF0F172A) : Colors.white;
    final Color subtextColor = isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8);
    final Color borderColor = isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          languageCode == 'en' ? 'Help & Support' : 'እርዳታ እና ድጋፍ',
          style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 18),
        ),
        backgroundColor: const Color(0xFFFF6D00),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 22.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: Application Developer Company
            Row(
              children: [
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6D00),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  languageCode == 'en' ? 'APPLICATION DEVELOPER' : 'የመተግበሪያው አልሚ ድርጅት',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFFF6D00),
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20.0),
                border: Border.all(color: borderColor, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isLight ? 0.04 : 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6D00).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.code_rounded,
                          color: Color(0xFFFF6D00),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hab-IT Solutions',
                              style: TextStyle(
                                fontSize: 17.5,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 3.0),
                            Text(
                              '${languageCode == 'en' ? "Lead Software Engineer: " : "ዋና አልሚ: "}Habtamu Yifiru',
                              style: TextStyle(
                                fontSize: 13.0,
                                color: subtextColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  Divider(color: borderColor, height: 1.0),
                  const SizedBox(height: 14.0),
                  Text(
                    languageCode == 'en'
                        ? 'For software inquiries, bug reports, custom educational modules, or technical assistance, reach out directly to the developer.'
                        : 'ለማንኛውም የቴክኒክ ድጋፍ፣ የስርዓት ስህተቶች ወይም ተጨማሪ አገልግሎቶች ሶፍትዌር ምህንድስና ክፍልን ማነጋገር ይችላሉ።',
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.5,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  // Telegram Developer Contact
                  InkWell(
                    onTap: () async {
                      final uri = Uri.parse('https://t.me/hab_dev');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    borderRadius: BorderRadius.circular(14.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0088CC).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14.0),
                        border: Border.all(
                          color: const Color(0xFF0088CC).withValues(alpha: 0.3),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.telegram_rounded,
                            color: Color(0xFF0088CC),
                            size: 22,
                          ),
                          const SizedBox(width: 12.0),
                          Text(
                            languageCode == 'en' ? 'Telegram Developer' : 'በቴሌግራም ያግኙ',
                            style: const TextStyle(
                              color: Color(0xFF0088CC),
                              fontWeight: FontWeight.w800,
                              fontSize: 14.0,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '@hab_dev',
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 13.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  // Direct Email Support Button
                  InkWell(
                    onTap: () async {
                      final uri = Uri.parse('mailto:habtamu.yifiru.official@gmail.com?subject=Smart%20X%20Ethiopian%20Support');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                    borderRadius: BorderRadius.circular(14.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEA4335).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14.0),
                        border: Border.all(
                          color: const Color(0xFFEA4335).withValues(alpha: 0.3),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.mail_outline_rounded,
                            color: Color(0xFFEA4335),
                            size: 22,
                          ),
                          const SizedBox(width: 12.0),
                          Text(
                            languageCode == 'en' ? 'Email Support' : 'በኢሜይል ያግኙ',
                            style: const TextStyle(
                              color: Color(0xFFEA4335),
                              fontWeight: FontWeight.w800,
                              fontSize: 14.0,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Gmail',
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 13.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28.0),

            // Section 2: Application Owner (Smart X Ethiopian)
            Row(
              children: [
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0EA5E9),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  languageCode == 'en' ? 'APPLICATION OWNER' : 'የመተግበሪያው ባለቤት',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0EA5E9),
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20.0),
                border: Border.all(color: borderColor, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isLight ? 0.04 : 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0EA5E9).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          color: Color(0xFF0EA5E9),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Smart X Ethiopian',
                              style: TextStyle(
                                fontSize: 17.0,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 3.0),
                            Text(
                              languageCode == 'en' ? 'Official Educational Platform' : 'ይፋዊ የትምህርት መድረክ',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: subtextColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  Divider(color: borderColor, height: 1.0),
                  const SizedBox(height: 14.0),
                  Text(
                    languageCode == 'en'
                        ? 'Follow our official channels for new Ethiopian matric question packs, short notes updates, and video lectures.'
                        : 'ስለ አዳዲስ የትምህርት ማጠቃለያዎች፣ የማትሪክ ጥያቄዎች እና የቪዲዮ ማስረዳቶች ለማግኘት ይፋዊ ቻናላችንን ይቀላቀሉ።',
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.5,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  // Phone Row
                  InkWell(
                    onTap: () async {
                      final uri = Uri.parse('tel:0992480372');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                    borderRadius: BorderRadius.circular(14.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0EA5E9).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14.0),
                        border: Border.all(
                          color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.phone_android_rounded,
                            color: Color(0xFF0EA5E9),
                            size: 22,
                          ),
                          const SizedBox(width: 12.0),
                          Text(
                            languageCode == 'en' ? 'Direct Hotline' : 'ስልክ ቁጥር',
                            style: const TextStyle(
                              color: Color(0xFF0EA5E9),
                              fontWeight: FontWeight.w800,
                              fontSize: 14.0,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '0992480372',
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 13.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  // Telegram Channel Row
                  InkWell(
                    onTap: () async {
                      final uri = Uri.parse('https://t.me/smartx_et');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    borderRadius: BorderRadius.circular(14.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0088CC).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14.0),
                        border: Border.all(
                          color: const Color(0xFF0088CC).withValues(alpha: 0.3),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.telegram_rounded,
                            color: Color(0xFF0088CC),
                            size: 22,
                          ),
                          const SizedBox(width: 12.0),
                          Text(
                            languageCode == 'en' ? 'Join Telegram Channel' : 'የቴሌግራም ቻናል ይቀላቀሉ',
                            style: const TextStyle(
                              color: Color(0xFF0088CC),
                              fontWeight: FontWeight.w800,
                              fontSize: 14.0,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.open_in_new_rounded,
                            color: Color(0xFF0088CC),
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
