// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

/// Modern, pure vector icon video carousel banner tailored for Smart Learn Ethiopian
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
      'darkBaseColor': Color(0xFF0C243C),
      'tagEn': 'SMART LEARN ETHIOPIAN',
      'tagAm': 'ስማርት ለርን ኢትዮጵያን',
      'icon': Icons.ondemand_video_rounded,
      'badgeIcon': Icons.play_arrow_rounded,
    },
    {
      'titleEn': 'Step-by-Step Problem Solving',
      'titleAm': 'የፈተና ጥያቄዎች ደረጃ በደረጃ አሰራር',
      'descEn': 'Master tricky physics derivations, math proofs, and chemistry reactions.',
      'descAm': 'አስቸጋሪ የሂሳብ፣ ፊዚክስ እና ኬሚስትሪ ጥያቄዎችን በቀላሉ የማስላት ዘዴዎች።',
      'accentColor': Color(0xFF6366F1),
      'secondaryColor': Color(0xFF4338CA),
      'darkBaseColor': Color(0xFF1E1B4B),
      'tagEn': 'EXAM STRATEGIES',
      'tagAm': 'የጥያቄ አሰራር',
      'icon': Icons.psychology_rounded,
      'badgeIcon': Icons.calculate_rounded,
    },
    {
      'titleEn': 'Concept Walkthroughs & Formulas',
      'titleAm': 'የቁልፍ ፎርሙላዎች እና ፅንሰ ሀሳቦች ዳሰሳ',
      'descEn': 'Grasp foundational science rules and derivations in fast 15-30 min sessions.',
      'descAm': 'ቁልፍ የሳይንስ ፎርሙላዎችን እና ህጎችን በአጭር ጊዜ ውስጥ በግልጽ ይረዱ።',
      'accentColor': Color(0xFF10B981),
      'secondaryColor': Color(0xFF047857),
      'darkBaseColor': Color(0xFF062D20),
      'tagEn': 'CURRICULUM RECAP',
      'tagAm': 'ፈጣን ግንዛቤ',
      'icon': Icons.auto_stories_rounded,
      'badgeIcon': Icons.science_rounded,
    },
    {
      'titleEn': 'National Matric Model Video Analysis',
      'titleAm': 'የማትሪክ ፈተና ሞዴል ጥያቄዎች ትንታኔ',
      'descEn': 'In-depth analysis of past national exams with expert tips for maximum score.',
      'descAm': 'የብሔራዊ ፈተና ጥያቄዎች ትንታኔ እና ለከፍተኛ ውጤት የሚረዱ ጠቃሚ ምክሮች።',
      'accentColor': Color(0xFFF59E0B),
      'secondaryColor': Color(0xFFD97706),
      'darkBaseColor': Color(0xFF332007),
      'tagEn': 'MATRIC MASTERY',
      'tagAm': 'የማትሪክ ዝግጅት',
      'icon': Icons.military_tech_rounded,
      'badgeIcon': Icons.workspace_premium_rounded,
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
            final Color darkBaseColor = slide['darkBaseColor']!;
            final IconData icon = slide['icon']!;
            final IconData badgeIcon = slide['badgeIcon']!;

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
                    // Dynamic Rich Vector Gradient Background
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isLight
                                ? [
                                    accentColor,
                                    secondaryColor,
                                    const Color(0xFF0F172A),
                                  ]
                                : [
                                    accentColor.withValues(alpha: 0.90),
                                    secondaryColor.withValues(alpha: 0.95),
                                    darkBaseColor,
                                    const Color(0xFF070B14),
                                  ],
                            stops: isLight ? const [0.0, 0.50, 1.0] : const [0.0, 0.40, 0.75, 1.0],
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
                    Positioned(
                      right: 35,
                      bottom: -35,
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accentColor.withValues(alpha: 0.25),
                        ),
                      ),
                    ),

                    // Giant Elegant Icon Watermark on the right
                    Positioned(
                      right: 10,
                      bottom: -15,
                      child: Opacity(
                        opacity: 0.16,
                        child: Icon(
                          icon,
                          size: 130,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    // Right Play Badge
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
                            color: Colors.white.withValues(alpha: 0.14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withValues(alpha: 0.45),
                                blurRadius: 14,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            badgeIcon,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ),

                    // Text & Details
                    Positioned(
                      left: 18.0,
                      top: 14.0,
                      bottom: 14.0,
                      right: 86.0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Tag
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.35),
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
                                    color: accentColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: accentColor,
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 5.5),
                                Text(
                                  widget.languageCode == 'en' ? slide['tagEn']! : slide['tagAm']!,
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
          children: _videoBanners.asMap().entries.map((entry) {
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
