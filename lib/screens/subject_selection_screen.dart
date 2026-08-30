import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_helper.dart';
import '../main.dart';
import 'unit_selection_screen.dart';
import '../widgets/subject_vector_widgets.dart';
import '../widgets/interactive_subject_card.dart';
import '../services/analytics_service.dart';

class SubjectSelectionScreen extends StatefulWidget {
  final int grade;
  final bool isDarkMode;
  final String languageCode;
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleLanguage;
  final bool isFromHome;
  final bool isShortNotesMode;

  const SubjectSelectionScreen({
    super.key,
    required this.grade,
    required this.isDarkMode,
    required this.languageCode,
    required this.onToggleTheme,
    required this.onToggleLanguage,
    this.isFromHome = false,
    this.isShortNotesMode = false,
  });

  @override
  State<SubjectSelectionScreen> createState() => _SubjectSelectionScreenState();
}

class _SubjectSelectionScreenState extends State<SubjectSelectionScreen> {
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;
  late int _selectedGrade;

  @override
  void initState() {
    super.initState();
    _selectedGrade = widget.grade;
    logScreen('SubjectListScreen');
    _loadBannerAd();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
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
          debugPrint('SubjectSelectionScreen BannerAd failed to load: $err. Code: ${err.code}');
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

  // Translate title helper dynamically retrieving the language code
  String _local(String key, String languageCode) {
    final Map<String, Map<String, String>> localized = {
      'en': {
        'title': 'GRADE $_selectedGrade: SUBJECTS',
        'subtitle': 'Select your subject to access courses and resources.',
        'btn_start': 'START',
      },
      'am': {
        'title': 'ክፍል $_selectedGrade: የትምህርት ምድቦች',
        'subtitle': 'የትምህርት ዓይነቶችዎን ለመምረጥ ከዚህ በታች ይጫኑ።',
        'btn_start': 'ጀምር',
      }
    };
    return localized[languageCode]?[key] ?? key;
  }

  // Define subjects with Amharic & English representation plus custom coloring/drawing style
  List<Map<String, dynamic>> _getSubjects() {
    final allSubjects = [
      {
        'id': 'Mathematics',
        'amTitle': 'ሂሳብ',
        'enTitle': 'Mathematics',
        'color': const Color(0xFF0084FF),
        'illustration': const DraftingGeometryWidget(),
      },
      {
        'id': 'Biology',
        'amTitle': 'ስነ-ህይወት',
        'enTitle': 'Biology',
        'color': const Color(0xFF2E7D32),
        'illustration': const CellBiologyWidget(),
      },
      {
        'id': 'Physics',
        'amTitle': 'ፊዚክስ',
        'enTitle': 'Physics',
        'color': const Color(0xFFE53935),
        'illustration': const AtomPhysicsWidget(),
      },
      {
        'id': 'Chemistry',
        'amTitle': 'ኬሚስትሪ',
        'enTitle': 'Chemistry',
        'color': const Color(0xFFEF6C00),
        'illustration': const ChemistryFlaskWidget(),
      },
      {
        'id': 'Geography',
        'amTitle': 'ጂኦግራፊ',
        'enTitle': 'Geography',
        'color': const Color(0xFF8E24AA),
        'illustration': const WorldMapGeographyWidget(),
      },
      {
        'id': 'History',
        'amTitle': 'ታሪክ',
        'enTitle': 'History',
        'color': const Color(0xFFF5B041),
        'illustration': const AksumObeliskWidget(),
      },
      {
        'id': 'English',
        'amTitle': 'እንግሊዝኛ',
        'enTitle': 'English',
        'color': const Color(0xFF6D28D9),
        'illustration': const EnglishBookWidget(),
      },
      {
        'id': 'Civics',
        'amTitle': 'ዜግነት',
        'enTitle': 'Civics',
        'color': const Color(0xFF1E88E5),
        'illustration': const CivicsGavelWidget(),
      },
      {
        'id': 'Economics',
        'amTitle': 'ኢኮኖሚክስ',
        'enTitle': 'Economics',
        'color': const Color(0xFF0F766E),
        'illustration': const EconomicsChartWidget(),
      },
      {
        'id': 'Agriculture',
        'amTitle': 'ግብርና',
        'enTitle': 'Agriculture',
        'color': const Color(0xFF8D6E63),
        'illustration': const AgricultureSproutWidget(),
      },
    ];

    if (_selectedGrade == 11 || _selectedGrade == 12) {
      return allSubjects.where((s) => s['id'] != 'Civics').toList();
    } else {
      return allSubjects.where((s) => s['id'] != 'Agriculture').toList();
    }
  }

  void _navigateToUnitSelectionScreen(Map<String, dynamic> subject, AppStateProvider appState) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UnitSelectionScreen(
          grade: _selectedGrade,
          subjectId: subject['id'],
          enTitle: subject['enTitle'],
          amTitle: subject['amTitle'],
          color: subject['color'],
          icon: subject['illustration'],
          isDarkMode: appState.isDarkMode,
          languageCode: appState.languageCode,
          onToggleTheme: appState.onToggleTheme,
          onToggleLanguage: appState.onToggleLanguage,
          isShortNotesMode: widget.isShortNotesMode,
        ),
      ),
    );
  }

  Color _getGradeColor() {
    switch (_selectedGrade) {
      case 9:
        return const Color(0xFF0084FF); // Blue
      case 10:
        return const Color(0xFF10B981); // Emerald Green
      case 11:
        return const Color(0xFFF59E0B); // Amber
      case 12:
        return const Color(0xFF8B5CF6); // Purple
      default:
        return const Color(0xFF0084FF);
    }
  }

  Widget _buildSegmentedGradeSelector(bool isLight, String languageCode) {
    final List<int> grades = [9, 10, 11, 12];
    final Color activeColor = _getGradeColor();
    final Color containerBg = isLight ? const Color(0xFFEFF3F8) : const Color(0xFF1E293B);

    return Container(
      height: 48,
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: containerBg,
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(
          color: isLight ? const Color(0xFFEDF2F7) : const Color(0xFF334155),
          width: 1.0,
        ),
      ),
      child: Row(
        children: grades.map((gradeNum) {
          final bool isSelected = _selectedGrade == gradeNum;
          final String title = languageCode == 'en' ? 'G-$gradeNum' : 'ክ-$gradeNum';

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedGrade = gradeNum;
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
    );
  }

  @override
  Widget build(BuildContext context) {
    // Dynamically retrieve the latest real-time application values to bypass stale attributes
    final appState = AppStateProvider.of(context);
    final bool isDark = appState.isDarkMode;
    final bool isLight = !isDark;
    final String currentLang = appState.languageCode;
    final subjects = _getSubjects();
    final Color gradeColor = _getGradeColor();

    // Matching responsive top UI alignment and clean off-white platform canvas background
    final Color bgColor = isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final Color headerTextColor = isLight ? const Color(0xFF0F172A) : Colors.white;

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
          _local('title', currentLang),
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w900,
            color: headerTextColor,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          // Elegant theme mode toggles
          IconButton(
            icon: Icon(
              isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round_outlined,
              color: headerTextColor,
              size: 20,
            ),
            onPressed: appState.onToggleTheme,
          ),
          const SizedBox(width: 12),
        ],
      ),
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
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!widget.isFromHome) ...[
                  // Headings
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        currentLang == 'en' ? 'Select Grade' : 'ክፍል ይምረጡ',
                        style: TextStyle(
                          fontSize: 15.0,
                          fontWeight: FontWeight.w900,
                          color: headerTextColor,
                        ),
                      ),
                      Text(
                        currentLang == 'en' ? 'Practice Quizzes' : 'የልምምድ ጥያቄዎች',
                        style: const TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF3B82F6), // primary blue
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),

                  // Pill selector
                  _buildSegmentedGradeSelector(isLight, currentLang),
                  const SizedBox(height: 24.0),
                ],

                // Subjects label
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(
                    currentLang == 'en' ? 'Select Your Subject' : 'የትምህርት ምድብ ይምረጡ',
                    style: TextStyle(
                      fontSize: 15.0,
                      fontWeight: FontWeight.w900,
                      color: headerTextColor,
                    ),
                  ),
                ),

                // Redesigned 2-column GridView subject selector matching request of 100% high-fidelity bento design
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                    childAspectRatio: 0.97, // Optimized ratio for taller, elegant cards with floating buttons
                  ),
                  itemCount: subjects.length,
                  itemBuilder: (context, index) {
                    final subject = subjects[index];
                    return InteractiveSubjectCard(
                      amTitle: subject['amTitle'],
                      enTitle: subject['enTitle'],
                      color: subject['color'],
                      illustration: subject['illustration'],
                      isLight: isLight,
                      gradeColor: gradeColor,
                      languageCode: currentLang,
                      grade: _selectedGrade,
                      btnText: _local('btn_start', currentLang),
                      onTap: () => _navigateToUnitSelectionScreen(subject, appState),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: (_isBannerAdLoaded && _bannerAd != null)
          ? Container(
              color: bgColor,
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
    );
  }
}
