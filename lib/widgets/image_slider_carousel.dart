import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

/// Modern, pure vector icon banner carousel for the Home Screen of Smart Learn Ethiopian.
/// Designed with rich gradients, ambient glow, and crisp academic iconography.
class ImageSliderCarousel extends StatefulWidget {
  final bool isDarkMode;
  final String languageCode;

  const ImageSliderCarousel({
    super.key,
    required this.isDarkMode,
    required this.languageCode,
  });

  @override
  State<ImageSliderCarousel> createState() => _ImageSliderCarouselState();
}

class _ImageSliderCarouselState extends State<ImageSliderCarousel> {
  int _currentSlideIndex = 0;
  final CarouselSliderController _carouselController = CarouselSliderController();

  final List<Map<String, dynamic>> _slidesData = [
    {
      'titleEn': 'Smart Learn Ethiopian Hub',
      'titleAm': 'ስማርት ለርን ኢትዮጵያን የመማሪያ ማዕከል',
      'descEn': 'Master Grade 9-12 curriculum with concise unit notes, formulas & quizzes.',
      'descAm': 'የ9-12ኛ ክፍል አዲሱ ካሪኩለም ማጠቃለያ ማስታወሻዎች፣ ፎርሙላዎችና ጥያቄዎች።',
      'primaryColor': const Color(0xFF0284C7),
      'secondaryColor': const Color(0xFF0369A1),
      'darkBaseColor': const Color(0xFF0C243C),
      'tagEn': 'SMART LEARN ETHIOPIAN',
      'tagAm': 'ስማርት ለርን ኢትዮጵያን',
      'icon': Icons.auto_stories_rounded,
      'badgeIcon': Icons.school_rounded,
    },
    {
      'titleEn': 'National Exam Question Bank',
      'titleAm': 'የብሔራዊ ፈተና ጥያቄዎችና ሞዴሎች',
      'descEn': 'Timed matric practice tests with detailed step-by-step explanations.',
      'descAm': 'ለማትሪክ ፈተና ከፍተኛ ውጤት የሚያዘጋጁ የፈተና ጥያቄዎችና የተብራሩ መልሶች።',
      'primaryColor': const Color(0xFFF59E0B),
      'secondaryColor': const Color(0xFFD97706),
      'darkBaseColor': const Color(0xFF332007),
      'tagEn': 'MATRIC READY',
      'tagAm': 'ለፈተና ዝግጁ',
      'icon': Icons.quiz_rounded,
      'badgeIcon': Icons.workspace_premium_rounded,
    },
    {
      'titleEn': '100% Offline Study Mode',
      'titleAm': 'ያለ ኢንተርኔት 100% ከመስመር ውጭ',
      'descEn': 'Download your chapters once and study anywhere without internet connection.',
      'descAm': 'የትምህርት ክፍሎችን አንዴ በማውረድ ያለ ኢንተርኔት በየትኛውም ቦታ ያጥኑ።',
      'primaryColor': const Color(0xFF10B981),
      'secondaryColor': const Color(0xFF059669),
      'darkBaseColor': const Color(0xFF0A291C),
      'tagEn': 'OFFLINE READY',
      'tagAm': 'ያለ ኢንተርኔት',
      'icon': Icons.offline_bolt_rounded,
      'badgeIcon': Icons.download_done_rounded,
    },
    {
      'titleEn': 'Performance & Quiz Analytics',
      'titleAm': 'የትምህርት እድገት እና የውጤት ትንታኔ',
      'descEn': 'Track study speed, test ratings, and chapter mastery progression in real time.',
      'descAm': 'የጥናት ፍጥነትዎን፣ የፈተና ውጤቶችን እና ያለቁ ምዕራፎችን በቀላሉ ይከታተሉ።',
      'primaryColor': const Color(0xFF8B5CF6),
      'secondaryColor': const Color(0xFF6D28D9),
      'darkBaseColor': const Color(0xFF231145),
      'tagEn': 'SMART ANALYTICS',
      'tagAm': 'የውጤት ትንታኔ',
      'icon': Icons.insights_rounded,
      'badgeIcon': Icons.analytics_rounded,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final bool isLight = !widget.isDarkMode;

    return Column(
      children: [
        CarouselSlider.builder(
          carouselController: _carouselController,
          itemCount: _slidesData.length,
          options: CarouselOptions(
            height: 148.0,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 5),
            autoPlayAnimationDuration: const Duration(milliseconds: 700),
            autoPlayCurve: Curves.easeInOutCubic,
            enlargeCenterPage: false,
            viewportFraction: 1.0,
            onPageChanged: (index, reason) {
              setState(() {
                _currentSlideIndex = index;
              });
            },
          ),
          itemBuilder: (context, index, realIndex) {
            final slide = _slidesData[index];
            final String title = widget.languageCode == 'en' ? slide['titleEn']! : slide['titleAm']!;
            final String desc = widget.languageCode == 'en' ? slide['descEn']! : slide['descAm']!;
            final String tag = widget.languageCode == 'en' ? slide['tagEn']! : slide['tagAm']!;
            final Color primaryColor = slide['primaryColor']!;
            final Color secondaryColor = slide['secondaryColor']!;
            final Color darkBaseColor = slide['darkBaseColor']!;
            final IconData icon = slide['icon']!;
            final IconData badgeIcon = slide['badgeIcon']!;

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 1.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18.0),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: isLight ? 0.20 : 0.35),
                    blurRadius: 16.0,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18.0),
                child: Stack(
                  children: [
                    // Dynamic Rich Vector Gradient Background
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isLight
                                ? [
                                    primaryColor,
                                    secondaryColor,
                                    const Color(0xFF0F172A),
                                  ]
                                : [
                                    primaryColor.withValues(alpha: 0.85),
                                    secondaryColor.withValues(alpha: 0.95),
                                    darkBaseColor,
                                    const Color(0xFF070B14),
                                  ],
                            stops: isLight ? const [0.0, 0.55, 1.0] : const [0.0, 0.40, 0.75, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // Ambient Decorative Glow Shapes
                    Positioned(
                      right: -30,
                      top: -30,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 40,
                      bottom: -40,
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primaryColor.withValues(alpha: 0.25),
                        ),
                      ),
                    ),

                    // Multi-layer deep overlay for crystal readability
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              const Color(0xFF070C16).withValues(alpha: 0.88),
                              const Color(0xFF070C16).withValues(alpha: 0.70),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.60, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // Large Vector Icon Silhouette Watermark on the Right
                    Positioned(
                      right: 12,
                      bottom: -10,
                      child: Opacity(
                        opacity: 0.16,
                        child: Icon(
                          icon,
                          size: 120,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    // Right Vector Icon Badge
                    Positioned(
                      right: 18,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.4),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            badgeIcon,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                    ),

                    // Content text & badges
                    Positioned(
                      left: 18.0,
                      top: 16.0,
                      bottom: 16.0,
                      right: 86.0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // App Branding Tag Chip
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 0.9,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 5.5,
                                  height: 5.5,
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: primaryColor,
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 5.5),
                                Text(
                                  tag,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9.0,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6.0),
                          // Title
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15.0,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 3.5),
                          // Description
                          Text(
                            desc,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.88),
                              fontSize: 11.0,
                              fontWeight: FontWeight.w500,
                              height: 1.3,
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
        ),
        const SizedBox(height: 8.0),
        // Dots Indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _slidesData.asMap().entries.map((entry) {
            final bool isSelected = _currentSlideIndex == entry.key;
            return GestureDetector(
              onTap: () => _carouselController.animateToPage(entry.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: isSelected ? 22.0 : 6.0,
                height: 5.5,
                margin: const EdgeInsets.symmetric(horizontal: 3.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4.0),
                  color: isSelected
                      ? const Color(0xFF0284C7)
                      : (isLight ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
