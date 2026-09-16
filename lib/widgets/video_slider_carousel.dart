// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class VideoSliderCarousel extends StatefulWidget {
  final bool isDarkMode;
  final String languageCode;
  final VoidCallback? onWatchTutorial;

  const VideoSliderCarousel({
    super.key,
    required this.isDarkMode,
    required this.languageCode,
    this.onWatchTutorial,
  });

  @override
  State<VideoSliderCarousel> createState() => _VideoSliderCarouselState();
}

class _VideoSliderCarouselState extends State<VideoSliderCarousel> {
  int _currentSlideIndex = 0;
  final CarouselSliderController _carouselController = CarouselSliderController();

  final List<Map<String, dynamic>> _videoBanners = [
    {
      'assetPath': 'assets/images/student_laptop.png',
      'titleEn': 'Curriculum Video Lessons',
      'titleAm': 'የክፍል ቪዲዮ ትምህርቶች (Grade 9-12)',
      'descEn': 'Crystal clear explanations organized by Grade, Subject, and Unit breakdown.',
      'descAm': 'በአዲሱ ሥርዓተ ትምህርት መሠረት በክፍል፣ በትምህርት ዓይነት እና በዩኒት የተደራጁ።',
      'accentColor': Color(0xFFEF4444),
      'tagEn': 'CURRICULUM MASTERY',
      'tagAm': 'የቪዲዮ ማብራሪያ',
      'icon': Icons.play_circle_fill_rounded,
    },
    {
      'assetPath': 'assets/images/student_tablet.png',
      'titleEn': 'Step-by-Step Problem Solving',
      'titleAm': 'የፈተና ጥያቄዎች ደረጃ በደረጃ አሰራር',
      'descEn': 'Learn smart exam problem solving techniques with experienced top tutors.',
      'descAm': 'አስቸጋሪ የሂሳብ፣ ፊዚክስ እና ኬሚስትሪ ጥያቄዎችን በቀላሉ የማስላት ዘዴዎች።',
      'accentColor': Color(0xFF0284C7),
      'tagEn': 'EXAM TACTICS',
      'tagAm': 'የጥያቄ አሰራር',
      'icon': Icons.lightbulb_rounded,
    },
    {
      'assetPath': 'assets/images/student_phone.png',
      'titleEn': 'Concept Walkthroughs & Formulas',
      'titleAm': 'የቁልፍ ፎርሙላዎች እና ፅንሰ ሀሳቦች ዳሰሳ',
      'descEn': 'Grasp foundational science rules and derivations in fast 15-30 min sessions.',
      'descAm': 'ቁልፍ የሳይንስ ፎርሙላዎችን እና ህጎችን በአጭር ጊዜ ውስጥ በግልጽ ይረዱ።',
      'accentColor': Color(0xFF10B981),
      'tagEn': 'CONCEPT CLARITY',
      'tagAm': 'ፈጣን ግንዛቤ',
      'icon': Icons.auto_stories_rounded,
    },
    {
      'assetPath': 'assets/images/student_laptop.png',
      'titleEn': 'National & Matric Exam Revisions',
      'titleAm': 'የማትሪክ እና ሞዴል ፈተናዎች ትንታኔ',
      'descEn': 'In-depth past matric exam revisions and model test walkthroughs.',
      'descAm': 'ያለፉት ዓመታት የማትሪክ ፈተናዎች ትንታኔ እና ሙሉ አሰራር ማብራሪያ።',
      'accentColor': Color(0xFF8B5CF6),
      'tagEn': 'MATRIC REVISION',
      'tagAm': 'የማትሪክ ክለሳ',
      'icon': Icons.military_tech_rounded,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final bool isLight = !widget.isDarkMode;

    return Column(
      children: [
        CarouselSlider.builder(
          carouselController: _carouselController,
          itemCount: _videoBanners.length,
          options: CarouselOptions(
            height: 132.0,
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
            final slide = _videoBanners[index];
            final String title = widget.languageCode == 'en' ? slide['titleEn']! : slide['titleAm']!;
            final String desc = widget.languageCode == 'en' ? slide['descEn']! : slide['descAm']!;
            final Color accentColor = slide['accentColor']!;
            final IconData icon = slide['icon']!;

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 1.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isLight ? 0.07 : 0.28),
                    blurRadius: 10.0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.0),
                child: Stack(
                  children: [
                    // Background Image
                    Positioned.fill(
                      child: Image.asset(
                        slide['assetPath']!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: isLight ? const Color(0xFFEDF2F7) : const Color(0xFF1E293B),
                          child: Icon(icon, size: 40, color: accentColor.withValues(alpha: 0.5)),
                        ),
                      ),
                    ),
                    // High-contrast gradient overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.15),
                              Colors.black.withValues(alpha: 0.45),
                              Colors.black.withValues(alpha: 0.88),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Play icon watermark in top-right
                    Positioned(
                      top: 10,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.85),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                    // Content details
                    Positioned(
                      left: 14,
                      bottom: 12,
                      right: 14,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: accentColor, width: 1),
                            ),
                            child: Text(
                              widget.languageCode == 'en' 
                                  ? (slide['tagEn'] ?? 'VIDEO HUB') 
                                  : (slide['tagAm'] ?? 'የቪዲዮ ማዕከል'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            desc,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.88),
                              fontSize: 10.5,
                              height: 1.2,
                              fontWeight: FontWeight.w500,
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
        const SizedBox(height: 8),
        // Dots Indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _videoBanners.asMap().entries.map((entry) {
            final int index = entry.key;
            final bool isActive = _currentSlideIndex == index;

            return GestureDetector(
              onTap: () => _carouselController.animateToPage(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: isActive ? 16.0 : 6.0,
                height: 5.0,
                margin: const EdgeInsets.symmetric(horizontal: 3.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3.0),
                  color: isActive
                      ? const Color(0xFFEF4444)
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
