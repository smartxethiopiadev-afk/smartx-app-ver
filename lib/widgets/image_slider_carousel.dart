import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

/// Modern, high-contrast banner carousel for the Home Screen of Smart Learn Ethiopian
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
      'assetPath': 'assets/images/home_banner1.png',
      'titleEn': 'Smart Learn Ethiopian Hub',
      'titleAm': 'ስማርት ለርን ኢትዮጵያን የመማሪያ ማዕከል',
      'descEn': 'Master Grade 9-12 curriculum with concise unit notes, formulas & quizzes.',
      'descAm': 'የ9-12ኛ ክፍል አዲሱ ካሪኩለም ማጠቃለያ ማስታወሻዎች፣ ፎርሙላዎችና ጥያቄዎች።',
      'primaryColor': const Color(0xFF0284C7),
      'secondaryColor': const Color(0xFF0369A1),
      'tagEn': 'SMART LEARN ETHIOPIAN',
      'tagAm': 'ስማርት ለርን ኢትዮጵያን',
      'icon': Icons.auto_stories_rounded,
    },
    {
      'assetPath': 'assets/images/home_banner3.png',
      'titleEn': 'National Exam Question Bank',
      'titleAm': 'የብሔራዊ ፈተና ጥያቄዎችና ሞዴሎች',
      'descEn': 'Timed matric practice tests with detailed step-by-step explanations.',
      'descAm': 'ለማትሪክ ፈተና ከፍተኛ ውጤት የሚያዘጋጁ የፈተና ጥያቄዎችና የተብራሩ መልሶች።',
      'primaryColor': const Color(0xFFF59E0B),
      'secondaryColor': const Color(0xFFD97706),
      'tagEn': 'MATRIC READY',
      'tagAm': 'ለፈተና ዝግጁ',
      'icon': Icons.quiz_rounded,
    },
    {
      'assetPath': 'assets/images/home_banner5.png',
      'titleEn': '100% Offline Study Mode',
      'titleAm': 'ያለ ኢንተርኔት 100% ከመስመር ውጭ',
      'descEn': 'Download your chapters once and study anywhere without internet connection.',
      'descAm': 'የትምህርት ክፍሎችን አንዴ በማውረድ ያለ ኢንተርኔት በየትኛውም ቦታ ያጥኑ።',
      'primaryColor': const Color(0xFF10B981),
      'secondaryColor': const Color(0xFF059669),
      'tagEn': 'OFFLINE READY',
      'tagAm': 'ያለ ኢንተርኔት',
      'icon': Icons.offline_bolt_rounded,
    },
    {
      'assetPath': 'assets/images/home_banner1.png',
      'titleEn': 'Performance & Quiz Analytics',
      'titleAm': 'የትምህርት እድገት እና የውጤት ትንታኔ',
      'descEn': 'Track study speed, test ratings, and chapter mastery progression in real time.',
      'descAm': 'የጥናት ፍጥነትዎን፣ የፈተና ውጤቶችን እና ያለቁ ምዕራፎችን በቀላሉ ይከታተሉ።',
      'primaryColor': const Color(0xFF8B5CF6),
      'secondaryColor': const Color(0xFF6D28D9),
      'tagEn': 'SMART ANALYTICS',
      'tagAm': 'የውጤት ትንታኔ',
      'icon': Icons.insights_rounded,
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
            final IconData icon = slide['icon']!;

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 1.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18.0),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: isLight ? 0.18 : 0.32),
                    blurRadius: 14.0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18.0),
                child: Stack(
                  children: [
                    // Base background image
                    Positioned.fill(
                      child: Image.asset(
                        slide['assetPath']!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [primaryColor, secondaryColor, const Color(0xFF0F172A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Multi-layer deep gradient overlay for crystal readability
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              const Color(0xFF0A0F1D).withValues(alpha: 0.94),
                              const Color(0xFF0A0F1D).withValues(alpha: 0.82),
                              primaryColor.withValues(alpha: 0.45),
                            ],
                            stops: const [0.0, 0.65, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // Subtle background icon watermark
                    Positioned(
                      right: 14,
                      bottom: -15,
                      child: Opacity(
                        opacity: 0.15,
                        child: Icon(
                          icon,
                          size: 130,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    // Content text & badges
                    Positioned(
                      left: 18.0,
                      top: 16.0,
                      bottom: 16.0,
                      right: 28.0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // App Branding Tag Chip
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 0.9,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
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
                                const SizedBox(width: 6),
                                Text(
                                  tag,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 7.0),
                          // Title
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          // Description
                          Text(
                            desc,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.88),
                              fontSize: 11.5,
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
