import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/curriculum_units.dart';
import '../services/subscription_service.dart';
import '../widgets/locked_unit_dialog.dart';
import 'video_lesson_screen.dart';

class VideoUnitSelectionScreen extends StatefulWidget {
  final int grade;
  final String subject;
  final Color subjectColor;
  final bool isDarkMode;
  final String languageCode;

  const VideoUnitSelectionScreen({
    super.key,
    required this.grade,
    required this.subject,
    required this.subjectColor,
    required this.isDarkMode,
    required this.languageCode,
  });

  @override
  State<VideoUnitSelectionScreen> createState() => _VideoUnitSelectionScreenState();
}

class _VideoUnitSelectionScreenState extends State<VideoUnitSelectionScreen> {
  bool _isGradeUnlocked = false;

  @override
  void initState() {
    super.initState();
    SubscriptionService.addListener(_onSubscriptionChanged);
    _checkSubscription();
  }

  @override
  void dispose() {
    SubscriptionService.removeListener(_onSubscriptionChanged);
    super.dispose();
  }

  void _onSubscriptionChanged() {
    if (mounted) {
      _checkSubscription();
    }
  }

  Future<void> _checkSubscription() async {
    final unlocked = await SubscriptionService.isGradeUnlocked(
      widget.grade,
      subject: widget.subject,
    );
    if (mounted) {
      setState(() {
        _isGradeUnlocked = unlocked;
      });
    }
  }

  List<Map<String, dynamic>> _getUnits() {
    final list = CurriculumUnits.getUnits(
      subjectId: widget.subject,
      grade: widget.grade,
    );
    if (list.isNotEmpty) return list;

    // Fallback standard curriculum units if subject isn't explicitly in CurriculumUnits
    return List.generate(6, (index) {
      final uNum = index + 1;
      return {
        'id': '${widget.subject.toLowerCase()}_u$uNum',
        'grade': widget.grade,
        'enUnit': 'Unit $uNum: ${widget.subject} Fundamentals Part $uNum',
        'amUnit': 'ክፍል $uNum: የ${widget.subject} መሰረታዊ ትምህርቶች $uNum',
        'enDesc': 'Core syllabus concepts, lecture breakdown, formulas and exercises.',
        'amDesc': 'የትምህርቱ ዋና ዋና ነጥቦች፣ ማብራሪያዎች እና የፈተና ጥያቄዎች።',
      };
    });
  }

  void _onUnitTap({
    required int unitNumber,
    required String unitTitle,
  }) {
    final bool isUnitFree = unitNumber <= 1;
    final bool isUnlocked = isUnitFree ||
        _isGradeUnlocked ||
        SubscriptionService.isUnitAccessibleSync(
          widget.grade,
          unitNumber,
          subject: widget.subject,
        );

    if (!isUnlocked) {
      LockedUnitDialog.show(
        context,
        grade: widget.grade,
        subject: widget.subject,
        unitNumber: unitNumber,
        unitTitle: unitTitle,
        languageCode: widget.languageCode,
        isDarkMode: widget.isDarkMode,
        onUnlocked: () {
          _checkSubscription();
        },
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VideoLessonScreen(
            grade: widget.grade,
            subject: widget.subject,
            unitNumber: unitNumber,
            unitTitle: unitTitle,
            isDarkMode: widget.isDarkMode,
            languageCode: widget.languageCode,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEn = widget.languageCode == 'en';
    final bool isLight = !widget.isDarkMode;

    final Color bgColor = isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final Color cardBg = isLight ? Colors.white : const Color(0xFF1E293B);
    final Color textColor = isLight ? const Color(0xFF0F172A) : Colors.white;
    final Color subColor = isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    final Color borderColor = isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155);

    final units = _getUnits();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: isEn ? 'Back to Subjects' : 'ወደ ትምህርቶች ተመለስ',
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEn ? 'Grade ${widget.grade} • ${widget.subject}' : '${widget.grade}ኛ ክፍል • ${widget.subject}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            Text(
              isEn ? 'Select a unit to view lessons' : 'የቪዲዮ ትምህርቶችን ለመምረጥ ዩኒቱን ይጫኑ',
              style: TextStyle(
                fontSize: 11.5,
                color: subColor,
              ),
            ),
          ],
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: borderColor, height: 1.0),
        ),
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            // Educational Overview Header
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: widget.subjectColor.withValues(alpha: isLight ? 0.08 : 0.16),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: widget.subjectColor.withValues(alpha: isLight ? 0.25 : 0.4),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.subjectColor.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.play_lesson_rounded, color: widget.subjectColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEn ? 'Curriculum Video Lessons' : 'የስርዓተ-ትምህርት ቪዲዮ ትምህርቶች',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isEn
                              ? 'Stream video explanations and solved examples directly from database.'
                              : 'ከዳታቤዝ በቀጥታ የሚተላለፉ የመማሪያ ቪዲዮዎችን እና የተሰሩ ምሳሌዎችን ይመልከቱ።',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: subColor,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Units List
            ...units.asMap().entries.map((entry) {
              final int index = entry.key;
              final unit = entry.value;
              final int unitNumber = index + 1;

              final String unitTitle = isEn
                  ? (unit['enUnit'] as String? ?? 'Unit $unitNumber')
                  : (unit['amUnit'] as String? ?? 'ክፍል $unitNumber');
              final String unitDesc = isEn
                  ? (unit['enDesc'] as String? ?? '')
                  : (unit['amDesc'] as String? ?? '');

              final bool isUnitFree = unitNumber <= 1;
              final bool isUnlocked = isUnitFree ||
                  _isGradeUnlocked ||
                  SubscriptionService.isUnitAccessibleSync(
                    widget.grade,
                    unitNumber,
                    subject: widget.subject,
                  );

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: !isUnlocked
                        ? const Color(0xFFF59E0B).withValues(alpha: 0.35)
                        : borderColor,
                    width: !isUnlocked ? 1.2 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isLight ? 0.03 : 0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _onUnitTap(
                      unitNumber: unitNumber,
                      unitTitle: unitTitle,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Unit Number Avatar
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isUnlocked
                                  ? (isUnitFree
                                      ? const Color(0xFF10B981).withValues(alpha: isLight ? 0.15 : 0.25)
                                      : widget.subjectColor.withValues(alpha: isLight ? 0.15 : 0.25))
                                  : const Color(0xFFF59E0B).withValues(alpha: isLight ? 0.15 : 0.25),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: isUnlocked
                                  ? Text(
                                      '$unitNumber',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: isUnitFree ? const Color(0xFF10B981) : widget.subjectColor,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.lock_rounded,
                                      color: Color(0xFFF59E0B),
                                      size: 20,
                                    ),
                            ),
                          ),

                          const SizedBox(width: 14),

                          // Unit Text Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        unitTitle,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w800,
                                          color: textColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Free / Locked Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isUnitFree
                                            ? const Color(0xFF10B981).withValues(alpha: isLight ? 0.12 : 0.25)
                                            : (isUnlocked
                                                ? const Color(0xFF0084FF).withValues(alpha: isLight ? 0.12 : 0.25)
                                                : const Color(0xFFF59E0B).withValues(alpha: isLight ? 0.12 : 0.25)),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        isUnitFree
                                            ? (isEn ? 'FREE' : 'ነጻ')
                                            : (isUnlocked
                                                ? (isEn ? 'UNLOCKED' : 'ክፍት')
                                                : (isEn ? 'LOCKED' : 'ዝግ')),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          color: isUnitFree
                                              ? const Color(0xFF10B981)
                                              : (isUnlocked
                                                  ? const Color(0xFF0084FF)
                                                  : const Color(0xFFD97706)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (unitDesc.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    unitDesc,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: subColor,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(width: 6),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: subColor.withValues(alpha: 0.6),
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
