// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

/// Modern, high-impact video carousel banner tailored for Smart Learn Ethiopian
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
      'titleEn': 'Smart Learn Ethiopian Video Hub',
      'titleAm': 'ስማርት ለርን የቪዲዮ ትምህርቶች (Grade 9-12)',
      'descEn': 'High-definition chapter walkthroughs tailored for Ethiopian national curricula.',
      'descAm': 'በአዲሱ ሥርዓተ ትምህርት መሠረት በክፍል፣ በትምህርት ዓይነት እና በዩኒት የተደራጁ።',
      'accentColor': Color(0xFF0284C7),
      'secondaryColor': Color(0xFF0369A1),
      'tagEn': 'SMART LEARN ETHIOPIAN',
      'tagAm': 'ስማርት ለርን ኢትዮጵያን',
      'icon': Icons.ondemand_video_rounded,
    },
    {
      'titleEn': 'Step-by-Step Problem Solving',
      'titleAm': 'የፈተና ጥያቄዎች ደረጃ በደረጃ አሰራር',
      'descEn': 'Master tricky physics derivations, math proofs, and chemistry reactions.',
      'descAm': 'አስቸጋሪ የሂሳብ፣ ፊዚክስ እና ኬሚስትሪ ጥያቄዎችን በቀላሉ የማስላት ዘዴዎች።',
      'accentColor': Color(0xFF6366F1),
      'secondaryColor': Color(0xFF4338CA),
      'tagEn': 'EXAM STRATEGIES',
      'tagAm': 'የጥያቄ አሰራር',
      'icon': Icons.psychology_rounded,
    },
    {
      'titleEn': 'Concept Walkthroughs & Formulas',
      'titleAm': 'የቁልፍ ፎርሙላዎች እና ፅንሰ ሀሳቦች ዳሰሳ',
      'descEn': 'Grasp foundational science rules and derivations in fast 15-30 min sessions.',
      'descAm': 'ቁልፍ የሳይንስ ፎርሙላዎችን እና ህጎችን በአጭር ጊዜ ውስጥ በግልጽ ይረዱ።',
      'accentColor': Color(0xFF10B981),
      'secondaryColor': Color(0xFF047857),
      'tagEn': 'CURRICULUM RECAP',
      'tagAm': 'ፈጣን ግንዛቤ',
      'icon': Icons.auto_stories_rounded,
    },
    {
      'titleEn': 'National Matric Model Video Analysis',
      'titleAm': 'የማትሪክ ፈተና ሞዴል ጥያቄዎች ትንታኔ',
      'descEn': 'In-depth analysis of past national exams with expert tips for maximum score.',
      'descAm': 'የብሔራዊ ፈተና ጥያቄዎች ትንታኔ እና ለከፍተኛ ውጤት የሚረዱ ጠቃሚ ምክሮች።',
      'accentColor': Color(0xFFF59E0B),
      'secondaryColor': Color(0xFFD97706),
      'tagEn': 'MATRIC MASTERY',
      'tagAm': 'የማትሪክ ዝግጅት',
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
            height: 152.0,
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
            final Color secondaryColor = slide['secondaryColor']!;
            final IconData icon = slide['icon']!;

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 1.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18.0),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: isLight ? 0.22 : 0.38),
                    blurRadius: 16.0,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18.0),
                child: Stack(
                  children: [
                    // Deep Rich Gradient Base
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              accentColor,
                              secondaryColor,
                              const Color(0xFF070C18),
                            ],
                            stops: const [0.0, 0.45, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // Soft Ambient Glow Circles
                    Positioned(
                      right: -25,
                      top: -25,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.10),
                        ),
                      ),
                    ),

                    // Giant Elegant Icon Watermark on the right
                    Positioned(
                      right: 12,
                      bottom: -10,
                      child: Opacity(
                        opacity: 0.18,
                        child: Icon(
                          icon,
                          size: 130,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    // Modern Play Button Pill on Top Right
                    Positioned(
                      top: 14,
                      right: 14,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.20),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
                            width: 1.2,
                          ),
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),

                    // Content details
                    Positioned(
                      left: 18,
                      bottom: 16,
                      right: 64,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Badge Chip
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.32),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF38BDF8),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  widget.languageCode == 'en' 
                                      ? (slide['tagEn'] ?? 'SMART LEARN ETHIOPIAN') 
                                      : (slide['tagAm'] ?? 'ስማርት ለርን ኢትዮጵያን'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9.0,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            desc,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 11.0,
                              height: 1.25,
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
        const SizedBox(height: 10),
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
                width: isActive ? 20.0 : 6.0,
                height: 5.0,
                margin: const EdgeInsets.symmetric(horizontal: 3.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3.0),
                  color: isActive
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
