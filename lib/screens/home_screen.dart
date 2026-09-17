// ignore_for_file: deprecated_member_use, overridden_fields, prefer_const_declarations, use_build_context_synchronously
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'subject_selection_screen.dart';
import 'splash_screen.dart';
import 'unit_selection_screen.dart';
import 'video_subject_selection_screen.dart';
import '../services/offline_manager.dart';
import 'quiz_screen.dart';
import 'notes_screen.dart';
import '../models/video_model.dart';
import '../services/video_service.dart';
import '../widgets/youtube_video_player_dialog.dart';
import '../widgets/image_slider_carousel.dart';
import '../widgets/video_slider_carousel.dart';
import '../widgets/how_to_start_banner.dart';
import '../widgets/subject_vector_widgets.dart';
import '../widgets/interactive_subject_card.dart';
import '../widgets/locked_unit_dialog.dart';
import '../services/subscription_service.dart';
import '../services/device_service.dart';
import '../services/credential_auth_service.dart';
import '../widgets/academic_progress_charts.dart';
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

  int _selectedGradeForLibraryTab = 9;
  String _libraryMode = 'qa'; // 'qa' or 'notes'
  String _deviceId = '';
  int? _selectedGradeForVideosTab;
  int _selectedUnitForVideosTab = 0; // 0 for All Units, 1, 2, 3...
  String _selectedSubjectForVideosTab = 'All';

  // Dictionary for dynamic translation matching 'EN/አማርኛ'
  final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'title': 'Smart Learn Ethiopia',
      'tutorial_desc': 'Watch tutorial: Getting started with Smart Learn Ethiopia',
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
      'nav_videos': 'Videos',
      'nav_quiz': 'Quizzes',
      'nav_notes': 'Notes',
      'nav_offline': 'Offline',
      'nav_courses': 'Offline',
      'nav_leaderboard': 'Leaderboard',
      'nav_library': 'Library',
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
      'title': 'ስማርት ለርን ኢትዮጵያ',
      'tutorial_desc': 'የማጠናከሪያ ቪዲዮ: በስማርት ለርን ኢትዮጵያ መተግበሪያ እንዴት እንደሚጀመር።',
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
      'nav_videos': 'ቪዲዮዎች',
      'nav_quiz': 'ጥያቄዎች',
      'nav_notes': 'ማስታወሻዎች',
      'nav_offline': 'ከመስመር ውጭ',
      'nav_courses': 'ከመስመር ውጭ',
      'nav_leaderboard': 'መሪዎች ሰሌዳ',
      'nav_library': 'ቤተ-መጽሐፍት',
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

    // Log Screen View
    logScreen('HomeScreen');

    _loadProfileData();
    _fadeController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200),
    );

    // Replicating tutorial video with standard Youtube embedded controller
    _fadeController.forward();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    final devId = await DeviceService.getDeviceId();
    final cached = await CredentialAuthService.getCachedCredentials();
    final cachedName = cached['fullName'] ?? '';
    final cachedPhone = cached['phoneNumber'] ?? '';
    setState(() {
      _deviceId = devId;
      if (cachedName.isNotEmpty) {
        _isLoggedIn = true;
        _userName = cachedName;
        _userPhoneNumber = cachedPhone;
      } else {
        _isLoggedIn = prefs.getBool('is_authenticated') ?? false;
        _userName = prefs.getString('user_fullName') ?? "Smart Student";
        _userPhoneNumber = prefs.getString('user_phoneNumber') ?? "+251 911 ...";
      }
      String? savedUid = prefs.getString('user_id');
      if (savedUid == null && _isLoggedIn) {
        savedUid = 'user_${DateTime.now().millisecondsSinceEpoch}_${(1000 + (DateTime.now().microsecondsSinceEpoch % 9000))}';
        prefs.setString('user_id', savedUid);
      }

      // Populate text controllers
      _fullNameController.text = _userName;
      _phoneController.text = _userPhoneNumber.replaceAll(RegExp(r'^\+251\s*'), '');
      
      debugPrint('Current user: $savedUid, deviceId: $_deviceId');
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isLight = !widget.isDarkMode;
    final bool isVideosActive = _currentIndex == 1;
    final bool isOfflineActive = _currentIndex == 2;
    final bool isLibraryActive = _currentIndex == 3;
    final bool isAccountActive = _currentIndex == 4;

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
          isVideosActive
              ? (widget.languageCode == 'en' ? 'Video Lessons' : 'የቪዲዮ ትምህርቶች')
              : (isOfflineActive
                  ? (widget.languageCode == 'en' ? 'Offline Lessons' : 'ከመስመር ውጭ')
                  : (isLibraryActive
                      ? (widget.languageCode == 'en' ? 'Library (Notes & Quizzes)' : 'ቤተ-መጽሐፍት')
                      : (isAccountActive
                          ? (widget.languageCode == 'en' ? 'Student Account' : 'የተማሪ መለያ')
                          : _local('title')))),
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
                        : "Ethio Concept Center",
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
                        : "Excellence in Ethiopian Education",
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
                    title: widget.languageCode == 'en' ? 'How to Start' : 'እንዴት ልጀምር?',
                    isSelected: false,
                    isLight: isLight,
                    onTap: () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (ctx) => HowToStartBanner(
                          isDarkMode: widget.isDarkMode,
                          languageCode: widget.languageCode,
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
                  _buildDrawerTile(
                    icon: Icons.send_rounded,
                    title: widget.languageCode == 'en' ? 'Contact Telegram' : 'ቴሌግራም አግኙን',
                    isSelected: false,
                    isLight: isLight,
                    onTap: () async {
                      Navigator.pop(context);
                      final Uri uri = Uri.parse('https://t.me/EthioconceptcenterAcademy');
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
                      iconActive: Icons.play_circle_filled_rounded,
                      iconInactive: Icons.play_circle_outline_rounded,
                      label: _local('nav_videos'),
                      isLight: isLight,
                    ),
                    _buildBottomNavItem(
                      index: 2,
                      iconActive: Icons.offline_pin_rounded,
                      iconInactive: Icons.offline_pin_outlined,
                      label: _local('nav_offline'),
                      isLight: isLight,
                    ),
                    _buildBottomNavItem(
                      index: 3,
                      iconActive: Icons.local_library_rounded,
                      iconInactive: Icons.local_library_outlined,
                      label: _local('nav_library'),
                      isLight: isLight,
                    ),
                    _buildBottomNavItem(
                      index: 4,
                      iconActive: Icons.person_rounded,
                      iconInactive: Icons.person_outline_rounded,
                      label: _local('nav_account'),
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
        return _buildVideosScreenTab(isLight); // Videos
      case 2:
        return _buildOfflineScreen(isLight); // Offline
      case 3:
        return _buildLibraryScreenTab(isLight); // Library (Short notes & Quizzes in Quiz style)
      case 4:
        return _buildAccountScreenTab(isLight); // Account
      default:
        return _buildHomeScreenContent(isLight);
    }
  }

  Widget _buildUnifiedSegmentedGradeSelectorForVideos(bool isLight) {
    final List<int> grades = [9, 10, 11, 12];
    final bool isAmharic = widget.languageCode == 'am';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: grades.map((gradeNum) {
          final bool isSelected = _selectedGradeForVideosTab == gradeNum;

          Color primaryColor;
          Color secondaryColor;
          IconData icon;
          switch (gradeNum) {
            case 9:
              primaryColor = const Color(0xFF3B82F6);
              secondaryColor = const Color(0xFF1D4ED8);
              icon = Icons.school_rounded;
              break;
            case 10:
              primaryColor = const Color(0xFF10B981);
              secondaryColor = const Color(0xFF047857);
              icon = Icons.auto_stories_rounded;
              break;
            case 11:
              primaryColor = const Color(0xFFEA580C);
              secondaryColor = const Color(0xFFC2410C);
              icon = Icons.science_rounded;
              break;
            case 12:
              primaryColor = const Color(0xFF8B5CF6);
              secondaryColor = const Color(0xFF6D28D9);
              icon = Icons.military_tech_rounded;
              break;
            default:
              primaryColor = const Color(0xFF3B82F6);
              secondaryColor = const Color(0xFF1D4ED8);
              icon = Icons.school_rounded;
          }

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3.5),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedGradeForVideosTab = gradeNum;
                    _selectedUnitForVideosTab = 0; // reset to all units
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [primaryColor, secondaryColor],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isSelected
                        ? null
                        : (isLight ? Colors.white : const Color(0xFF1E293B)),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? primaryColor
                          : (isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
                      width: isSelected ? 2.0 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? primaryColor.withValues(alpha: 0.35)
                            : Colors.black.withValues(alpha: isLight ? 0.03 : 0.15),
                        blurRadius: isSelected ? 8 : 3,
                        offset: Offset(0, isSelected ? 3 : 1),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.22)
                              : primaryColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          size: 14,
                          color: isSelected ? Colors.white : primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isAmharic ? '$gradeNumኛ ክፍል' : 'Grade $gradeNum',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                          color: isSelected
                              ? Colors.white
                              : (isLight ? const Color(0xFF0F172A) : Colors.white),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Full-width wide Grade Card for video tab landing
  Widget _buildGradeVideoLandingCard({
    required int gradeNum,
    required bool isLight,
    required bool isAmharic,
  }) {
    Color primaryColor;
    Color secondaryColor;
    IconData icon;
    String title;
    String subtitle;
    List<String> subjectTags;

    switch (gradeNum) {
      case 9:
        primaryColor = const Color(0xFF2563EB);
        secondaryColor = const Color(0xFF1D4ED8);
        icon = Icons.school_rounded;
        title = isAmharic ? '9ኛ ክፍል (Grade 9)' : 'Grade 9 Curriculum';
        subtitle = isAmharic
            ? 'የ9ኛ ክፍል የቪዲዮ ትምህርቶች፣ ዩኒት ማብራሪያዎች እና የፈተና ጥያቄዎች'
            : 'Grade 9 unit walkthroughs, formula derivations, and practice solutions.';
        subjectTags = ['Mathematics', 'Physics', 'Chemistry', 'Biology', 'Civics', 'English'];
        break;
      case 10:
        primaryColor = const Color(0xFF059669);
        secondaryColor = const Color(0xFF047857);
        icon = Icons.auto_stories_rounded;
        title = isAmharic ? '10ኛ ክፍል (Grade 10)' : 'Grade 10 Curriculum';
        subtitle = isAmharic
            ? 'ለማትሪክ መሠረት የሚሆኑ ሙሉ የትምህርት ክፍሎች በቪዲዮ ማብራሪያ'
            : 'Foundational lessons and matric preparation with verified problem walkthroughs.';
        subjectTags = ['Mathematics', 'Physics', 'Chemistry', 'Biology', 'Civics', 'English'];
        break;
      case 11:
        primaryColor = const Color(0xFFD97706);
        secondaryColor = const Color(0xFFB45309);
        icon = Icons.science_rounded;
        title = isAmharic ? '11ኛ ክፍል (Grade 11)' : 'Grade 11 Curriculum';
        subtitle = isAmharic
            ? 'የተፈጥሮ እና ማህበራዊ ሳይንስ የዩኒት ማብራሪያዎች እና ማጠቃለያዎች'
            : 'Natural & Social Science advanced unit breakdowns and key concepts.';
        subjectTags = ['Mathematics', 'Physics', 'Chemistry', 'Biology', 'Agriculture', 'Civics'];
        break;
      case 12:
        primaryColor = const Color(0xFF7C3AED);
        secondaryColor = const Color(0xFF6D28D9);
        icon = Icons.military_tech_rounded;
        title = isAmharic ? '12ኛ ክፍል (Grade 12)' : 'Grade 12 Curriculum';
        subtitle = isAmharic
            ? 'የማትሪክ ፈተና ዝግጅት፣ የሞዴል ፈተናዎች ትንታኔ እና ሙሉ አሰራር'
            : 'National Matric Exam mastery, model tests analysis, and solved questions.';
        subjectTags = ['Mathematics', 'Physics', 'Chemistry', 'Biology', 'Agriculture', 'Economics'];
        break;
      default:
        primaryColor = const Color(0xFF2563EB);
        secondaryColor = const Color(0xFF1D4ED8);
        icon = Icons.school_rounded;
        title = 'Grade $gradeNum';
        subtitle = 'Curriculum video lessons';
        subjectTags = ['Mathematics', 'Physics', 'Chemistry'];
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isLight ? Colors.white : const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: primaryColor.withValues(alpha: isLight ? 0.3 : 0.5),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: isLight ? 0.09 : 0.22),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => VideoSubjectSelectionScreen(
                  grade: gradeNum,
                  isDarkMode: !isLight,
                  languageCode: widget.languageCode,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Icon + Grade Title + Lesson Count
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryColor, secondaryColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: isLight ? const Color(0xFF0F172A) : Colors.white,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: isLight ? 0.12 : 0.25),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isAmharic ? '48+ ቪዲዮዎች' : '48+ Lessons',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Subject Badges Preview
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: subjectTags.map((subj) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                        ),
                      ),
                      child: Text(
                        subj,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isLight ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 14),

                // Bottom Call To Action
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, secondaryColor],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        isAmharic
                            ? '$gradeNumኛ ክፍል ቪዲዮዎችን ይመልከቱ'
                            : 'Explore Grade $gradeNum Video Lessons',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideosScreenTab(bool isLight) {
    final bool isAmharic = widget.languageCode == 'am';
    final Color textColor =
        isLight ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final Color subColor =
        isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

    final List<Map<String, String>> subjects = [
      {'id': 'All', 'title': isAmharic ? 'ሁሉም' : 'All'},
      {'id': 'Mathematics', 'title': isAmharic ? 'ሂሳብ' : 'Mathematics'},
      {'id': 'Physics', 'title': isAmharic ? 'ፊዚክስ' : 'Physics'},
      {'id': 'Chemistry', 'title': isAmharic ? 'ኬሚስትሪ' : 'Chemistry'},
      {'id': 'Biology', 'title': isAmharic ? 'ስነ-ህይወት' : 'Biology'},
    ];

    final int currentGrade = _selectedGradeForVideosTab ?? 9;

    if (currentGrade == 9 || currentGrade == 10) {
      subjects.add({'id': 'Civics', 'title': isAmharic ? 'የዜግነት ትምህርት' : 'Civics'});
    }
    if (currentGrade == 11 || currentGrade == 12) {
      subjects.add({'id': 'Agriculture', 'title': isAmharic ? 'ግብርና' : 'Agriculture'});
    }

    subjects.addAll([
      {'id': 'Geography', 'title': isAmharic ? 'ጂኦግራፊ' : 'Geography'},
      {'id': 'History', 'title': isAmharic ? 'ታሪክ' : 'History'},
      {'id': 'Economics', 'title': isAmharic ? 'ኢኮኖሚክስ' : 'Economics'},
      {'id': 'ICT', 'title': isAmharic ? 'ኢንፎርሜሽን ቴክኖሎጂ (ICT)' : 'ICT'},
    ]);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- TOP VIDEO BANNER CAROUSEL (3-5 Rotating Slides) ---
                  VideoSliderCarousel(
                    isDarkMode: !isLight,
                    languageCode: widget.languageCode,
                  ),

                  const SizedBox(height: 14),

                  // CONDITIONAL CONTENT:
                  // IF NO GRADE SELECTED -> Show 4 Stacked Full-Width Grade Cards
                  if (_selectedGradeForVideosTab == null) ...[
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0x1FEF4444),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.video_library_rounded, size: 16, color: Color(0xFFEF4444)),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isAmharic ? 'ክፍልዎን ይምረጡ (የቪዲዮ ትምህርቶች)' : 'Select Your Grade (Video Lessons)',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isAmharic
                          ? 'የትምህርት ዓይነት እና የዩኒት ማብራሪያዎችን ለመመልከት ክፍልዎን ይምረጡ'
                          : 'Choose your grade to explore subjects, units, and video walkthroughs.',
                      style: TextStyle(
                        fontSize: 12,
                        color: subColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Freemium Tip Banner
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: isLight ? 0.08 : 0.16),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF10B981).withValues(alpha: isLight ? 0.25 : 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lock_open_rounded, color: Color(0xFF10B981), size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isAmharic
                                  ? 'Unit 1 ለሁሉም ክፍሎች እና የትምህርት አይነቶች 100% ነጻ ነው!'
                                  : 'Unit 1 is 100% Free for all subjects and grades!',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildGradeVideoLandingCard(gradeNum: 9, isLight: isLight, isAmharic: isAmharic),
                    _buildGradeVideoLandingCard(gradeNum: 10, isLight: isLight, isAmharic: isAmharic),
                    _buildGradeVideoLandingCard(gradeNum: 11, isLight: isLight, isAmharic: isAmharic),
                    _buildGradeVideoLandingCard(gradeNum: 12, isLight: isLight, isAmharic: isAmharic),
                  ] else ...[
                    // IF GRADE IS SELECTED -> Show Grade Header + Quick switcher + Subject + Unit Selectors
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isLight ? Colors.white : const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                        ),
                      ),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () {
                              setState(() {
                                _selectedGradeForVideosTab = null;
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0x1F0284C7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.arrow_back_rounded, size: 15, color: Color(0xFF0284C7)),
                                  const SizedBox(width: 4),
                                  Text(
                                    isAmharic ? 'ወደ ክፍሎች' : 'All Grades',
                                    style: const TextStyle(
                                      color: Color(0xFF0284C7),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0x1FEF4444),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.school_rounded, size: 14, color: Color(0xFFEF4444)),
                                const SizedBox(width: 5),
                                Text(
                                  isAmharic ? '$_selectedGradeForVideosTabኛ ክፍል' : 'Grade $_selectedGradeForVideosTab',
                                  style: const TextStyle(
                                    color: Color(0xFFEF4444),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Quick switcher for grades
                    _buildUnifiedSegmentedGradeSelectorForVideos(isLight),

                    const SizedBox(height: 10),

                    // Subject Horizontal Filter Chips
                    SizedBox(
                      height: 34,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: subjects.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 6),
                        itemBuilder: (context, index) {
                          final item = subjects[index];
                          final bool isSelected =
                              _selectedSubjectForVideosTab == item['id'];
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedSubjectForVideosTab = item['id']!;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFEF4444)
                                    : (isLight ? Colors.white : const Color(0xFF1E293B)),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFFEF4444)
                                      : (isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
                                ),
                                boxShadow: isSelected
                                    ? const [
                                        BoxShadow(
                                          color: Color(0x40EF4444),
                                          blurRadius: 6,
                                          offset: Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  item['title']!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : (isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8)),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Unit Filter Horizontal Pills
                    SizedBox(
                      height: 34,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _buildUnitFilterChip(
                            unitNum: 0,
                            label: isAmharic ? 'ሁሉም ክፍሎች (All)' : 'All Units',
                            isSelected: _selectedUnitForVideosTab == 0,
                            isLight: isLight,
                          ),
                          ...List.generate(6, (index) {
                            final unitNum = index + 1;
                            return _buildUnitFilterChip(
                              unitNum: unitNum,
                              label: isAmharic ? 'ክፍል $unitNum (Unit $unitNum)' : 'Unit $unitNum',
                              isSelected: _selectedUnitForVideosTab == unitNum,
                              isLight: isLight,
                            );
                          }),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          ),

          // Videos Stream / Future Builder with Unit Filtering (Only if grade selected)
          if (_selectedGradeForVideosTab != null)
            FutureBuilder<List<VideoModel>>(
              future: VideoService.fetchVideos(
                grade: _selectedGradeForVideosTab!,
                subject: _selectedSubjectForVideosTab == 'All'
                    ? null
                    : _selectedSubjectForVideosTab,
                unit: _selectedUnitForVideosTab == 0 ? null : _selectedUnitForVideosTab,
              ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFEF4444),
                    ),
                  ),
                );
              }

              final videos = snapshot.data ?? [];

              if (videos.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_lesson_rounded,
                              size: 40,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isAmharic
                                ? 'ለዚህ ክፍል እና Unit ቪዲዮ በቅርቡ ይጫናል'
                                : 'Video lessons for this unit coming soon!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isAmharic
                                ? 'በቴሌግራም አድሚኑን በማነጋገር የፈለጉትን ትምህርት መጠየቅ ይችላሉ።'
                                : 'You can request this specific lesson directly from our academic team on Telegram.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: subColor,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 18),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final unitStr = _selectedUnitForVideosTab > 0 ? 'Unit $_selectedUnitForVideosTab' : '';
                              final msg = Uri.encodeComponent(
                                  'ሰላም ኢትዮ ኮንሴፕት ሴንተር፣ Grade $_selectedGradeForVideosTab $_selectedSubjectForVideosTab $unitStr ቪዲዮ እንዲጫንልኝ እፈልጋለሁ።');
                              final uri = Uri.parse('https://t.me/EthioconceptcenterAcademy?text=$msg');
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              }
                            },
                            icon: const Icon(Icons.telegram_rounded, size: 18),
                            label: Text(
                              isAmharic ? 'በቴሌግራም አድሚኑን ጠይቅ' : 'Request Lesson on Telegram',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0284C7),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final video = videos[index];
                      return _buildCompactVideoCard(
                        video: video,
                        isLight: isLight,
                        isAmharic: isAmharic,
                        textColor: textColor,
                        subColor: subColor,
                      );
                    },
                    childCount: videos.length,
                  ),
                ),
              );
            },
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 36),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitFilterChip({
    required int unitNum,
    required String label,
    required bool isSelected,
    required bool isLight,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedUnitForVideosTab = unitNum;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF0284C7)
                : (isLight ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF0284C7)
                  : (isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isLight ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Compact, refined in-app video card (Strictly stays inside Mobile Application)
  Widget _buildCompactVideoCard({
    required VideoModel video,
    required bool isLight,
    required bool isAmharic,
    required Color textColor,
    required Color subColor,
  }) {
    final bool isUnitFree = video.unitNumber <= 1;
    final bool isUnlocked = isUnitFree ||
        SubscriptionService.isUnitAccessibleSync(video.grade, video.unitNumber,
            subject: video.subject);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isLight ? Colors.white : const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: !isUnlocked
              ? const Color(0xFFF59E0B).withValues(alpha: 0.35)
              : (isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isLight ? 0.03 : 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            if (!isUnlocked) {
              LockedUnitDialog.show(
                context,
                grade: video.grade,
                subject: video.subject,
                unitNumber: video.unitNumber,
                unitTitle: video.title,
                languageCode: widget.languageCode,
                isDarkMode: widget.isDarkMode,
                onUnlocked: () {
                  setState(() {});
                },
              );
            } else {
              YouTubeVideoPlayerDialog.show(
                context,
                video: video,
                isDarkMode: widget.isDarkMode,
                languageCode: widget.languageCode,
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Compact 16:9 Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 110,
                    height: 72,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          video.thumbnailUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFF0F172A),
                            child: Center(
                              child: Icon(
                                !isUnlocked ? Icons.lock_rounded : Icons.play_circle_fill_rounded,
                                size: 28,
                                color: !isUnlocked ? const Color(0xFFF59E0B) : const Color(0xFFEF4444),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          color: Colors.black.withValues(alpha: 0.25),
                        ),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: !isUnlocked
                                  ? const Color(0xFFD97706)
                                  : const Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              !isUnlocked ? Icons.lock_rounded : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                        if (video.durationText != null)
                          Positioned(
                            bottom: 3,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                video.durationText!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Video Meta details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0284C7).withValues(alpha: isLight ? 0.12 : 0.25),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'G-${video.grade} • ${video.subject}',
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0284C7),
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6).withValues(alpha: isLight ? 0.12 : 0.25),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Unit ${video.unitNumber}',
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF8B5CF6),
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: isLight ? 0.12 : 0.25),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isAmharic ? 'ክፍልፋይ ${video.partNumber}' : 'Part ${video.partNumber}',
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (!isUnlocked)
                            const Icon(Icons.lock_rounded, size: 13, color: Color(0xFFD97706))
                          else
                            const Icon(Icons.play_circle_filled_rounded, size: 14, color: Color(0xFF10B981)),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        video.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            !isUnlocked
                                ? (isAmharic ? 'የተቆለፈ • ለመክፈት ይጫኑ' : 'Locked • Tap to unlock')
                                : (isAmharic ? 'በመተግበሪያው ያጫውቱ' : 'Watch In-App'),
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: !isUnlocked ? const Color(0xFFD97706) : const Color(0xFF10B981),
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () async {
                              final msg = Uri.encodeComponent(
                                  'ሰላም ኢትዮ ኮንሴፕት ሴንተር፣ ስለ Grade ${video.grade} ${video.subject} Unit ${video.unitNumber} (${video.title}) ጥያቄ አለኝ።');
                              final uri = Uri.parse('https://t.me/EthioconceptcenterAcademy?text=$msg');
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.telegram_rounded, size: 12, color: Color(0xFF0284C7)),
                                  const SizedBox(width: 3),
                                  Text(
                                    isAmharic ? 'ጥያቄ' : 'Ask',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0284C7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUnifiedSegmentedGradeSelectorForLibrary(bool isLight) {
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
            final bool isSelected = _selectedGradeForLibraryTab == gradeNum;
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
                    _selectedGradeForLibraryTab = gradeNum;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected ? activeColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(20.0),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: activeColor.withValues(alpha: 0.2),
                              blurRadius: 16.0,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
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
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLibraryScreenTab(bool isLight) {
    final bool isAmharic = widget.languageCode == 'am';
    final Color subColor = isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

    final List<Map<String, dynamic>> allSubjects = [
      {
        'id': 'Mathematics',
        'amTitle': 'ሂሳብ',
        'enTitle': 'Mathematics',
        'color': const Color(0xFF3B82F6),
        'lightBg': const Color(0xFFEFF6FF),
        'illustration': const DraftingGeometryWidget(),
      },
      {
        'id': 'Biology',
        'amTitle': 'ስነ-ህይወት',
        'enTitle': 'Biology',
        'color': const Color(0xFF10B981),
        'lightBg': const Color(0xFFECFDF5),
        'illustration': const CellBiologyWidget(),
      },
      {
        'id': 'Physics',
        'amTitle': 'ፊዚክስ',
        'enTitle': 'Physics',
        'color': const Color(0xFFDC2626),
        'lightBg': const Color(0xFFFEF2F2),
        'illustration': const AtomPhysicsWidget(),
      },
      {
        'id': 'Chemistry',
        'amTitle': 'ኬሚስትሪ',
        'enTitle': 'Chemistry',
        'color': const Color(0xFFEA580C),
        'lightBg': const Color(0xFFFFF7ED),
        'illustration': const ChemistryFlaskWidget(),
      },
    ];

    if (_selectedGradeForLibraryTab == 9 || _selectedGradeForLibraryTab == 10) {
      allSubjects.add({
        'id': 'Civics',
        'amTitle': 'የዜግነት ትምህርት',
        'enTitle': 'Civics',
        'color': const Color(0xFF1E88E5),
        'lightBg': const Color(0xFFEFF6FF),
        'illustration': const CivicsGavelWidget(),
      });
    }

    if (_selectedGradeForLibraryTab == 11 || _selectedGradeForLibraryTab == 12) {
      allSubjects.add({
        'id': 'Agriculture',
        'amTitle': 'ግብርና',
        'enTitle': 'Agriculture',
        'color': const Color(0xFF16A34A),
        'lightBg': const Color(0xFFF0FDF4),
        'illustration': const AgricultureSproutWidget(),
      });
    }

    allSubjects.addAll([
      {
        'id': 'Geography',
        'amTitle': 'ጂኦግራፊ',
        'enTitle': 'Geography',
        'color': const Color(0xFF8E24AA),
        'lightBg': const Color(0xFFFDF4FF),
        'illustration': const WorldMapGeographyWidget(),
      },
      {
        'id': 'History',
        'amTitle': 'ታሪክ',
        'enTitle': 'History',
        'color': const Color(0xFFD97706),
        'lightBg': const Color(0xFFFEF3C7),
        'illustration': const AksumObeliskWidget(),
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
        'id': 'ICT',
        'amTitle': 'ኢንፎርሜሽን ቴክኖሎጂ (ICT)',
        'enTitle': 'ICT',
        'color': const Color(0xFF0284C7),
        'lightBg': const Color(0xFFF0F9FF),
        'illustration': const IctComputerWidget(),
      },
    ]);

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
        image: DecorationImage(
          image: const AssetImage('assets/images/education_bg_pattern.png'),
          repeat: ImageRepeat.repeat,
          opacity: isLight ? 0.08 : 0.03,
          colorFilter: isLight ? null : const ColorFilter.mode(Colors.white54, BlendMode.modulate),
        ),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Grade Selector
            _buildUnifiedSegmentedGradeSelectorForLibrary(isLight),
            const SizedBox(height: 16.0),

            // Mode Selector: Q&A Quizzes vs Short Note Question Cards
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isLight ? const Color(0xFFE2E8F0).withValues(alpha: 0.6) : const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _libraryMode = 'qa';
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _libraryMode == 'qa'
                              ? (isLight ? Colors.white : const Color(0xFF0284C7))
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _libraryMode == 'qa'
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.quiz_rounded,
                              size: 16,
                              color: _libraryMode == 'qa'
                                  ? (isLight ? const Color(0xFF0284C7) : Colors.white)
                                  : subColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isAmharic ? 'ጥያቄ እና መልስ' : 'Q&A Quizzes',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: _libraryMode == 'qa'
                                    ? (isLight ? const Color(0xFF0F172A) : Colors.white)
                                    : subColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _libraryMode = 'notes';
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _libraryMode == 'notes'
                              ? (isLight ? Colors.white : const Color(0xFF10B981))
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _libraryMode == 'notes'
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.menu_book_rounded,
                              size: 16,
                              color: _libraryMode == 'notes'
                                  ? (isLight ? const Color(0xFF10B981) : Colors.white)
                                  : subColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isAmharic ? 'አጭር ማስታወሻ' : 'Short Notes',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: _libraryMode == 'notes'
                                    ? (isLight ? const Color(0xFF0F172A) : Colors.white)
                                    : subColor,
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

            const SizedBox(height: 14.0),

            // Free Unit 1 Notice Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: isLight ? 0.09 : 0.18),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isAmharic
                          ? 'የክፍል 1 (Unit 1) ጥያቄዎች እና ማስታወሻዎች ሙሉ በሙሉ ነጻ ናቸው!'
                          : 'Unit 1 questions and notes are 100% Free for all subjects!',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18.0),

            // Subject Cards Grid (in Quiz Style)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                childAspectRatio: 0.92,
              ),
              itemCount: allSubjects.length,
              itemBuilder: (context, index) {
                final subject = allSubjects[index];

                Color getGradeColor(int g) {
                  switch (g) {
                    case 9:
                      return const Color(0xFF0084FF);
                    case 10:
                      return const Color(0xFF10B981);
                    case 11:
                      return const Color(0xFFEA580C);
                    case 12:
                      return const Color(0xFF8B5CF6);
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
                  gradeColor: getGradeColor(_selectedGradeForLibraryTab),
                  languageCode: widget.languageCode,
                  grade: _selectedGradeForLibraryTab,
                  btnText: isAmharic
                      ? (_libraryMode == 'notes' ? 'ማስታወሻ ጀምር' : 'ፈተና ጀምር')
                      : (_libraryMode == 'notes' ? 'READ NOTES' : 'START QUIZ'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => UnitSelectionScreen(
                          grade: _selectedGradeForLibraryTab,
                          subjectId: subject['id'],
                          enTitle: subject['enTitle'],
                          amTitle: subject['amTitle'],
                          color: subject['color'],
                          icon: subject['illustration'],
                          isDarkMode: widget.isDarkMode,
                          languageCode: widget.languageCode,
                          onToggleTheme: widget.onToggleTheme,
                          onToggleLanguage: widget.onToggleLanguage,
                          isShortNotesMode: _libraryMode == 'notes',
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 32),
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
      padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 16.0),
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

          const SizedBox(height: 8.0),

          // Interactive "How to Start" (እንዴት ልጀምር?) Guide Banner
          _animateItem(
            index: 2,
            child: HowToStartBanner(
              isDarkMode: !isLight,
              languageCode: widget.languageCode,
              onGradeSelected: (grade) => _navigateToGradeScreen(grade),
            ),
          ),

          const SizedBox(height: 12.0),

          // Section Title: Grade selection
          _animateItem(
            index: 3,
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

    // Log Grade Selection Screen View
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

  Widget _buildAccountScreenTab(bool isLight) {
    final bool isAmharic = widget.languageCode == 'am';
    final Color textColor = isLight ? const Color(0xFF0F172A) : Colors.white;
    final Color subColor = isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    final Color cardBg = isLight ? Colors.white : const Color(0xFF1E293B);
    final Color borderColor = isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155);

    final Set<String> unlockedPkgs = SubscriptionService.getUnlockedPackagesSync();

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
        image: DecorationImage(
          image: const AssetImage('assets/images/education_bg_pattern.png'),
          repeat: ImageRepeat.repeat,
          opacity: isLight ? 0.08 : 0.03,
          colorFilter: isLight ? null : const ColorFilter.mode(Colors.white54, BlendMode.modulate),
        ),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student Profile Header Card
            Container(
              padding: const EdgeInsets.all(18.0),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20.0),
                border: Border.all(color: borderColor, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isLight ? 0.04 : 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0084FF), Color(0xFF0056B3)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0084FF).withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _userName.isNotEmpty ? _userName : (isAmharic ? 'ተማሪ' : 'Student'),
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _userPhoneNumber.isNotEmpty ? _userPhoneNumber : (isAmharic ? 'ስልክ አልተመዘገበም' : 'No phone linked'),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: subColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF10B981)),
                            const SizedBox(width: 4),
                            Text(
                              isAmharic ? 'ነቃ' : 'Active',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 14),

                  // Single-Device Automated Security Badge
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.shield_rounded, size: 20, color: Color(0xFF10B981)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isAmharic ? 'የመለያ ደህንነት እና ጥበቃ' : 'Device Security Status',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: isLight ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isAmharic
                                    ? 'ይህ መለያ በዚህ ስልክ ላይ በደህንነት የተጠበቀ ነው (Single-Device Protection)'
                                    : 'Account securely bound to this device (Single-Device Protection Active)',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: subColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isAmharic ? 'ንቁ' : 'Active',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF10B981)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Advanced Academic Analytics & Chart Analysis Engine (Separated Study Velocity, Subject Master, and Quiz Trade)
            AcademicProgressCharts(
              isDarkMode: widget.isDarkMode,
              languageCode: widget.languageCode,
              currentGrade: _selectedGradeForLibraryTab,
            ),

            const SizedBox(height: 24),

            // Active Subscriptions / Database Permissions Section
            Text(
              isAmharic ? 'የተፈቀዱ የትምህርት ክፍሎች' : 'Active Content Access',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: textColor,
              ),
            ),
            const SizedBox(height: 10),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderColor, width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAmharic ? 'ክፍል 1 (Unit 1) - ሙሉ በሙሉ ነጻ' : 'Unit 1 (All Subjects) - 100% Free',
                              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: textColor),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isAmharic ? 'ለሁሉም ተማሪዎች ክፍት የተደረገ' : 'Always open for trial practice',
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: subColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (unlockedPkgs.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1),
                    ),
                    Text(
                      isAmharic ? 'በዚህ ስልክ የተፈቀዱ ሙሉ ክፍሎች:' : 'Unlocked on this single device:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textColor),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: unlockedPkgs.map((pkg) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0084FF).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF0084FF).withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.lock_open_rounded, size: 13, color: Color(0xFF0084FF)),
                              const SizedBox(width: 5),
                              Text(
                                pkg.replaceAll('pkg_', '').replaceAll('_', ' ').toUpperCase(),
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0084FF)),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 36),
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
              logScreen('VideosScreen');
              break;
            case 2:
              logScreen('OfflineScreen');
              break;
            case 3:
              logScreen('LibraryScreen');
              break;
            case 4:
              logScreen('AccountScreen');
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
                ? 'Are you sure you want to log out of your Ethio Concept Center student profile? Your local study stats will remain saved.'
                : 'ከኢትዮ ኮንሴፕት ሴንተር መለያዎ መውጣት እርግጠኛ ነዎት? የዚህ መሣሪያ የጥናት ሂደትዎ አይጠፋም።',
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
    final Color subtextColor = isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    final Color borderColor = isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          languageCode == 'en' ? 'Help & Developer Info' : 'እርዳታ እና አልሚ መረጃ',
          style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF0284C7),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header: Developer Information
            Row(
              children: [
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  languageCode == 'en' ? 'DEVELOPER CONTACT' : 'የአልሚው አድራሻ',
                  style: const TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0284C7),
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10.0),
            
            // Developer Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18.0),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(18.0),
                border: Border.all(color: borderColor, width: 1.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isLight ? 0.03 : 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.code_rounded,
                          color: Color(0xFF0284C7),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Habtamu Yifiru',
                              style: TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w900,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 2.0),
                            Text(
                              languageCode == 'en' ? 'Lead Software Developer' : 'ዋና ሶፍትዌር አልሚ (Hab-IT)',
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
                  
                  // Telegram Direct Developer Button (@HabIT_Dev)
                  InkWell(
                    onTap: () async {
                      final uri = Uri.parse('https://t.me/HabIT_Dev');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    borderRadius: BorderRadius.circular(12.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0088CC).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(
                          color: const Color(0xFF0088CC).withValues(alpha: 0.25),
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
                          const SizedBox(width: 10.0),
                          Text(
                            languageCode == 'en' ? 'Telegram Developer' : 'አልሚውን በቴሌግራም',
                            style: const TextStyle(
                              color: Color(0xFF0088CC),
                              fontWeight: FontWeight.w800,
                              fontSize: 13.5,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '@HabIT_Dev',
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 13.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  
                  // Phone Call / SMS (+251900297614)
                  InkWell(
                    onTap: () async {
                      final uri = Uri.parse('tel:+251900297614');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                    borderRadius: BorderRadius.circular(12.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(
                          color: const Color(0xFF10B981).withValues(alpha: 0.25),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.phone_rounded,
                            color: Color(0xFF10B981),
                            size: 20,
                          ),
                          const SizedBox(width: 10.0),
                          Text(
                            languageCode == 'en' ? 'Phone / Call' : 'ስልክ ቁጥር',
                            style: const TextStyle(
                              color: Color(0xFF10B981),
                              fontWeight: FontWeight.w800,
                              fontSize: 13.5,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '+251900297614',
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 13.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  
                  // Email Support Button
                  InkWell(
                    onTap: () async {
                      final uri = Uri.parse('mailto:habtamu.yifiru.official@gmail.com?subject=Smart%20X%20Ethiopian%20Inquiry');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                    borderRadius: BorderRadius.circular(12.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEA4335).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(
                          color: const Color(0xFFEA4335).withValues(alpha: 0.25),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.mail_outline_rounded,
                            color: Color(0xFFEA4335),
                            size: 20,
                          ),
                          const SizedBox(width: 10.0),
                          Text(
                            languageCode == 'en' ? 'Email Support' : 'በኢሜይል ያግኙ',
                            style: const TextStyle(
                              color: Color(0xFFEA4335),
                              fontWeight: FontWeight.w800,
                              fontSize: 13.5,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Gmail',
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 13.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22.0),

            // Section Header: Official Discussion Community
            Row(
              children: [
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0088CC),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  languageCode == 'en' ? 'OFFICIAL COMMUNITY' : 'ይፋዊ የቴሌግራም ቻናል',
                  style: const TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0088CC),
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10.0),
            
            // Community Card (@EthioconceptcenterAcademy)
            InkWell(
              onTap: () async {
                final uri = Uri.parse('https://t.me/EthioconceptcenterAcademy');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              borderRadius: BorderRadius.circular(18.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18.0),
                decoration: BoxDecoration(
                  color: isLight ? const Color(0xFFF0F9FF) : const Color(0xFF0F2942),
                  borderRadius: BorderRadius.circular(18.0),
                  border: Border.all(
                    color: const Color(0xFF0088CC).withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0088CC),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.telegram_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ethio Concept Center Academy',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 2.0),
                          const Text(
                            '@EthioconceptcenterAcademy',
                            style: TextStyle(
                              fontSize: 12.0,
                              color: Color(0xFF0088CC),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Color(0xFF0088CC),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
