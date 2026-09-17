import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

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
      'titleEn': 'Smart Learn Ethiopia Hub',
      'titleAm': 'ስማርት ለርን ኢትዮጵያ - አጠቃላይ የመማሪያ ማዕከል',
      'descEn': 'Learn | Practice | Succeed. Grades 9-12 full curriculum mastery.',
      'descAm': 'ተማር | ተለማመድ | ተሳካ። ከ9-12ኛ ክፍል አጠቃላይ የትምህርት ማጠቃለያዎች።',
      'accentColor': const Color(0xFF0084FF),
      'tagEn': 'SMART LEARN ETHIOPIA',
      'tagAm': 'ስማርት ለርን ኢትዮጵያ',
    },
    {
      'assetPath': 'assets/images/home_banner2.png',
      'titleEn': 'Curriculum Video Masterclasses',
      'titleAm': 'የቪዲዮ ትምህርቶች እና ማብራሪያዎች',
      'descEn': 'Crystal clear chapter walkthroughs, formulas, and verified solutions.',
      'descAm': 'ከ9-12ኛ ክፍል ያሉትን ሁሉንም የትምህርት ምዕራፎች በቪዲዮ ማብራሪያ በቀላሉ ይረዱ።',
      'accentColor': const Color(0xFF10B981),
      'tagEn': 'VIDEO LESSONS',
      'tagAm': 'የቪዲዮ ማብራሪያዎች',
    },
    {
      'assetPath': 'assets/images/home_banner3.png',
      'titleEn': 'National Matric Exam Excellence',
      'titleAm': 'ለማትሪክ ፈተና ከፍተኛ ውጤት',
      'descEn': 'Model exams, unit tests, and interactive cheat-cards for top scores.',
      'descAm': 'ከፍተኛ ጥራት ያላቸው የልምምድ ፈተናዎች፣ አጫጭር ካርዶች እና የተረጋገጡ ማብራሪያዎች።',
      'accentColor': const Color(0xFFF59E0B),
      'tagEn': 'MATRIC READY',
      'tagAm': 'ለፈተና ዝግጁ',
    },
    {
      'assetPath': 'assets/images/home_banner4.png',
      'titleEn': '100% Offline Study Hub',
      'titleAm': 'ያለ ኢንተርኔት በየትኛውም ቦታ ያጥኑ',
      'descEn': 'Download short notes and practice quizzes to learn anywhere offline.',
      'descAm': 'አጫጭር ማስታወሻዎችን እና የልምምድ ፈተናዎችን አውርደው ያለ ኢንተርኔት ይጠቀሙ።',
      'accentColor': const Color(0xFF8B5CF6),
      'tagEn': 'OFFLINE ACCESS',
      'tagAm': 'ከመስመር ውጭ ዝግጁ',
    },
    {
      'assetPath': 'assets/images/home_banner5.png',
      'titleEn': 'Velocity & Academic Score Tracking',
      'titleAm': 'የትምህርት እድገት እና የውጤት ትንታኔ',
      'descEn': 'Track study velocity, master quiz ratings, and chapter completion progress.',
      'descAm': 'የጥናት ፍጥነትን፣ የፈተና ውጤቶችን እና ያለቁ ምዕራፎችን በቀላሉ ይከታተሉ።',
      'accentColor': const Color(0xFF06B6D4),
      'tagEn': 'STUDY ANALYTICS',
      'tagAm': 'የውጤት ትንታኔ',
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
            height: 140.0,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 4),
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
            final Color accentColor = slide['accentColor']!;

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 1.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isLight ? 0.08 : 0.3),
                    blurRadius: 10.0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.0),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        slide['assetPath']!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: isLight ? const Color(0xFFEDF2F7) : const Color(0xFF1E293B),
                          child: Icon(Icons.school_rounded, size: 40, color: accentColor.withValues(alpha: 0.5)),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.15),
                              Colors.black.withValues(alpha: 0.45),
                              Colors.black.withValues(alpha: 0.85),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16.0,
                      bottom: 14.0,
                      right: 16.0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: accentColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              tag,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 5.0),
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15.0,
                              fontWeight: FontWeight.w900,
                              shadows: [
                                Shadow(color: Colors.black87, blurRadius: 4),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            desc,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11.0,
                              fontWeight: FontWeight.w600,
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _slidesData.asMap().entries.map((entry) {
            final bool isSelected = _currentSlideIndex == entry.key;
            return GestureDetector(
              onTap: () => _carouselController.animateToPage(entry.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: isSelected ? 20.0 : 6.0,
                height: 6.0,
                margin: const EdgeInsets.symmetric(horizontal: 3.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4.0),
                  color: isSelected
                      ? const Color(0xFF0084FF)
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
