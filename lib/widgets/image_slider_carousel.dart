// ignore_for_file: prefer_const_constructors
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

  // 3 Education Oriented high quality slides with translated titles and descriptions
  final List<Map<String, dynamic>> _slidesData = [
    {
      'assetPath': 'assets/images/student_phone.png',
      'titleEn': 'Collaborative Learning',
      'titleAm': 'የጋራ ጥናት ቡድን',
      'descEn': 'Connect and share summaries and matric preparation strategies with students nationwide.',
      'descAm': 'አጠቃላይ ማጠቃለያዎችን እና የማትሪክ ዝግጅቶችን በሀገር አቀፍ ደረጃ ካሉ ተማሪዎች ጋር ይጋሩ።',
      'accentColor': Color(0xFF0084FF),
    },
    {
      'assetPath': 'assets/images/student_tablet.png',
      'titleEn': 'Excellence in Exams',
      'titleAm': 'ለማትሪክ አሸናፊነት',
      'descEn': 'Unlock high-quality practice tests, interactive flashcards, and verified solutions.',
      'descAm': 'ከፍተኛ ጥራት ያላቸው የልምምድ ፈተናዎች፣ አጫጭር ካርዶች እና የተረጋገጡ ማብራሪያዎችን ያግኙ።',
      'accentColor': Color(0xFF10B981),
    },
    {
      'assetPath': 'assets/images/student_laptop.png',
      'titleEn': 'Track Your Progression',
      'titleAm': 'የእርስዎን ጉዞ ይከታተሉ',
      'descEn': 'Monitor study hours, completed chapters, and detailed mock success statistics.',
      'descAm': 'የጥናት ሰዓታትን፣ ያለቁ ምዕራፎችን እና ዝርዝር የፈተና ውጤቶችን ይቆጣጠሩ።',
      'accentColor': Color(0xFFF59E0B),
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
            height: 165.0,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 4),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
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
            final Color accentColor = slide['accentColor']!;

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isLight ? 0.08 : 0.35),
                    blurRadius: 12.0,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24.0),
                child: Stack(
                  children: [
                    // Slide Image background
                    Positioned.fill(
                      child: Image.asset(
                        slide['assetPath']!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: isLight ? const Color(0xFFEDF2F7) : const Color(0xFF1E293B),
                          child: Icon(Icons.school_rounded, size: 48, color: accentColor.withValues(alpha: 0.5)),
                        ),
                      ),
                    ),
                    // High-quality dark multi-gradient mask overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.1),
                              Colors.black.withValues(alpha: 0.35),
                              Colors.black.withValues(alpha: 0.8),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Text details and badge info overlay
                    Positioned(
                      left: 16,
                      bottom: 12,
                      right: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: accentColor, width: 1),
                            ),
                            child: Text(
                              widget.languageCode == 'en' ? 'SMART X LEARNING' : 'ስማርት ኤክስ ትምህርት',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8.0,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            desc,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 10.0,
                              height: 1.25,
                              fontWeight: FontWeight.w600,
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
        const SizedBox(height: 12),
        // Dots Indicator for slide selection
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _slidesData.asMap().entries.map((entry) {
            final int index = entry.key;
            final bool isActive = _currentSlideIndex == index;

            return GestureDetector(
              onTap: () => _carouselController.animateToPage(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: isActive ? 18.0 : 7.0,
                height: 7.0,
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4.0),
                  color: isActive
                      ? const Color(0xFFFF6D00)
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
