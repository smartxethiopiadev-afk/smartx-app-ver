import 'package:flutter/material.dart';
import '../screens/payment_screen.dart';
import '../models/package_model.dart';

class HowToStartBanner extends StatefulWidget {
  final bool isDarkMode;
  final String languageCode;
  final Function(int grade)? onGradeSelected;

  const HowToStartBanner({
    super.key,
    required this.isDarkMode,
    required this.languageCode,
    this.onGradeSelected,
  });

  @override
  State<HowToStartBanner> createState() => _HowToStartBannerState();
}

class _HowToStartBannerState extends State<HowToStartBanner> {
  int _activeStep = 0;
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final bool isLight = !widget.isDarkMode;
    final bool isAm = widget.languageCode == 'am';

    final Color cardBg = isLight ? Colors.white : const Color(0xFF1E293B);
    final Color borderColor = isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155);
    final Color textPrimary = isLight ? const Color(0xFF0F172A) : Colors.white;
    final Color textSecondary = isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

    final steps = [
      {
        'number': '1',
        'icon': Icons.school_rounded,
        'color': const Color(0xFF0084FF),
        'title': isAm ? 'ክፍልዎን ይምረጡ' : 'Select Your Grade',
        'desc': isAm
            ? 'ከክፍል 9 እስከ 12 ድረስ የእርስዎን ክፍል ይምረጡ።'
            : 'Choose from Grade 9 to 12 tailored to the new curriculum.',
        'tag': isAm ? 'ደረጃ 1' : 'Step 1',
      },
      {
        'number': '2',
        'icon': Icons.card_giftcard_rounded,
        'color': const Color(0xFF10B981),
        'title': isAm ? 'ክፍል 1 100% ነፃ ነው' : 'Unit 1 is 100% FREE',
        'desc': isAm
            ? 'ለሁሉም የትምህርት አይነቶች ክፍል 1ን በነፃ ያጥኑ፣ ፈተና ይውሰዱ እና የልምምድ ወረቀቶችን ይስሩ።'
            : 'Every subject includes Unit 1 completely free: notes, quizzes, and worksheets.',
        'tag': isAm ? 'ደረጃ 2' : 'Step 2',
      },
      {
        'number': '3',
        'icon': Icons.offline_pin_rounded,
        'color': const Color(0xFFF59E0B),
        'title': isAm ? 'ከመስመር ውጭ (Offline) ያውርዱ' : 'Download for Offline Study',
        'desc': isAm
            ? 'ያለ ኢንተርኔት በየትኛውም ቦታ ለማጥናት የክፍል ይዘቶችን አንድ ጊዜ ብቻ ያውርዱ።'
            : 'Download units once to access full notes and quizzes without any data connection.',
        'tag': isAm ? 'ደረጃ 3' : 'Step 3',
      },
      {
        'number': '4',
        'icon': Icons.workspace_premium_rounded,
        'color': const Color(0xFF8B5CF6),
        'title': isAm ? 'ክፍያ ፈጽመው መለያዎን ያግብሩ' : 'Pay & Activate Full Access',
        'desc': isAm
            ? 'በቴሌብር ወይም በኢትዮጵያ ንግድ ባንክ ከፍለው በይለፍ ቃል ሙሉ ይዘቶችን ይክፈቱ።'
            : 'Pay via Telebirr or CBE to receive your admin-issued credentials for full lifetime access.',
        'tag': isAm ? 'ደረጃ 4' : 'Step 4',
      },
    ];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isLight ? 0.03 : 0.15),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Banner Top Header
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0084FF), Color(0xFF00BFFF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0084FF).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.rocket_launch_rounded,
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
                              isAm ? 'እንዴት ልጀምር?' : 'How to Start?',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: textPrimary,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0084FF).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isAm ? '4 ደረጃዎች' : '4 STEPS',
                                style: const TextStyle(
                                  color: Color(0xFF0084FF),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isAm
                              ? 'ቀላል ደረጃዎች የስማርት ኤክስን ትምህርት ለመጀመር'
                              : 'Quick roadmap to master your studies offline & online',
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: textSecondary,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),

          // Steps list (when expanded)
          if (_isExpanded) ...[
            const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: [
                  // Step Indicator Pills
                  Row(
                    children: List.generate(steps.length, (idx) {
                      final item = steps[idx];
                      final isSelected = _activeStep == idx;
                      final Color stepColor = item['color'] as Color;

                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _activeStep = idx),
                          child: Container(
                            margin: EdgeInsets.only(right: idx < 3 ? 6.0 : 0),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? stepColor.withValues(alpha: 0.15)
                                  : (isLight
                                      ? const Color(0xFFF1F5F9)
                                      : const Color(0xFF334155).withValues(alpha: 0.5)),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? stepColor : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  item['icon'] as IconData,
                                  size: 15,
                                  color: isSelected ? stepColor : textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  item['number'] as String,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: isSelected ? stepColor : textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 14),

                  // Active Step Detail Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: (steps[_activeStep]['color'] as Color).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: (steps[_activeStep]['color'] as Color).withValues(alpha: 0.25),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: steps[_activeStep]['color'] as Color,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                steps[_activeStep]['icon'] as IconData,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: (steps[_activeStep]['color'] as Color).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      steps[_activeStep]['tag'] as String,
                                      style: TextStyle(
                                        color: steps[_activeStep]['color'] as Color,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    steps[_activeStep]['title'] as String,
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w800,
                                      color: textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          steps[_activeStep]['desc'] as String,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: textSecondary,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Action button for active step
                        if (_activeStep == 0)
                          Row(
                            children: [9, 10, 11, 12].map((g) {
                              return Expanded(
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  child: ElevatedButton(
                                    onPressed: () => widget.onGradeSelected?.call(g),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0084FF),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      'G$g',
                                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          )
                        else if (_activeStep == 1)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    isAm
                                        ? 'ምንም ክፍያ ወይም ምዝገባ ሳያስፈልግ ክፍል 1ን ወዲያውኑ ይጀምሩ!'
                                        : 'No payment or sign-up needed to access Unit 1 immediately!',
                                    style: const TextStyle(
                                      color: Color(0xFF10B981),
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (_activeStep == 3)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                _showAllPackagesBottomSheet(context, isLight, isAm);
                              },
                              icon: const Icon(Icons.workspace_premium_rounded, size: 18),
                              label: Text(
                                isAm ? 'ሁሉንም ፓኬጆች ይመልከቱ' : 'View Premium Packages',
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8B5CF6),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
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
          ],
        ],
      ),
    );
  }

  void _showAllPackagesBottomSheet(BuildContext context, bool isLight, bool isAm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isLight ? Colors.white : const Color(0xFF0F172A),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: isLight ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isAm ? 'ስማርት ኤክስ የትምህርት ፓኬጆች' : 'Smart X Learning Packages',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: isLight ? const Color(0xFF0F172A) : Colors.white,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isAm ? 'ክፍል 1 ነፃ ነው' : 'UNIT 1 FREE',
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              ...PackageModel.defaultPackages.map((pkg) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0084FF).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'G${pkg.grade}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0084FF),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pkg.title,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: isLight ? const Color(0xFF0F172A) : Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${pkg.priceEtb.toInt()} ETB • ${isAm ? "የአንድ ጊዜ ክፍያ" : "Lifetime Access"}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF10B981),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          PaymentScreen.push(
                            context,
                            grade: pkg.grade,
                            languageCode: widget.languageCode,
                            isDarkMode: widget.isDarkMode,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0084FF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          isAm ? 'ክፈት' : 'Unlock',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
