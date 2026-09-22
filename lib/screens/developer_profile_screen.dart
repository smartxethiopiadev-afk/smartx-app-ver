import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class DeveloperProfileScreen extends StatelessWidget {
  final bool isDarkMode;
  final String languageCode;

  const DeveloperProfileScreen({
    super.key,
    required this.isDarkMode,
    required this.languageCode,
  });

  Future<void> _makePhoneCall(BuildContext context) async {
    final Uri uri = Uri.parse('tel:+251900297614');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw 'Could not launch phone call';
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              languageCode == 'am'
                  ? 'ስልክ መደወል አልተቻለም፡ +251 900 297 614'
                  : 'Could not place call to: +251 900 297 614',
            ),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _sendEmail(BuildContext context) async {
    final Uri uri = Uri.parse(
      'mailto:habtamu.yifiru.official@gmail.com?subject=Inquiry%20from%20Smart%20Learn%20App',
    );
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw 'Could not open mail client';
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              languageCode == 'am'
                  ? 'ኢሜይል መላክ አልተቻለም፡ habtamu.yifiru.official@gmail.com'
                  : 'Could not send email to: habtamu.yifiru.official@gmail.com',
            ),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isAm = languageCode == 'am';
    final bool isLight = !isDarkMode;

    final Color bgColor = isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final Color cardBg = isLight ? Colors.white : const Color(0xFF1E293B);
    final Color textColor = isLight ? const Color(0xFF0F172A) : Colors.white;
    final Color subColor = isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    final Color borderColor = isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155);
    const Color primaryBlue = Color(0xFF0284C7);
    const Color accentIndigo = Color(0xFF4F46E5);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          isAm ? 'ስለ አልሚው እና HAB IT Solutions' : 'Developer & HAB IT Solutions',
          style: GoogleFonts.plusJakartaSans(
            color: textColor,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: borderColor, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Lead Developer Hero Bento Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0284C7), Color(0xFF2563EB), Color(0xFF4F46E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.28),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Avatar with Verified Tech Badge
                  Stack(
                    children: [
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.2),
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.person_rounded,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.verified_rounded, size: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Habtamu Yifiru',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isAm ? 'ዋና የሶፍትዌር መሃንዲስ እና መስራች' : 'Founder & Lead Software Engineer',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isAm
                        ? 'በኢትዮጵያ ዲጂታል ትምህርትን እና የቴክኖሎጂ አሰራርን የሚያዘምኑ አስተማማኝ ሶፍትዌሮችን የማበልጸግ ራዕይ ያለው ባለሙያ።'
                        : 'Dedicated to empowering Ethiopian education and enterprise ecosystems through high-performance, offline-first mobile applications and cloud architectures.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.notoSansEthiopic(
                      fontSize: 13,
                      height: 1.5,
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. HAB IT Solutions Section Header
            Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: primaryBlue,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isAm ? 'ስለ HAB IT SOLUTIONS' : 'ABOUT HAB IT SOLUTIONS',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: primaryBlue,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Company Overview Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isLight ? 0.03 : 0.2),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: accentIndigo.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.business_center_rounded, color: accentIndigo, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'HAB IT Solutions',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: textColor,
                              ),
                            ),
                            Text(
                              isAm ? 'የቴክኖሎጂ እና የሶፍትዌር ማበልጸጊያ ድርጅት' : 'Innovative Software & Tech Solutions Firm',
                              style: GoogleFonts.notoSansEthiopic(
                                fontSize: 12,
                                color: subColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    isAm
                        ? 'HAB IT Solutions በሀገራችን ኢትዮጵያ ውስጥ በዲጂታል ትምህርት፣ በሞባይል አፕሊኬሽን ስራዎች፣ በዳታቤዝ እና ክላውድ ሲስተም ላይ ልዩ ትኩረት ሰጥቶ የሚሰራ የቴክኖሎጂ ተቋም ነው። ያለ ኢንተርኔት (Offline) የሚሰሩ መተግበሪያዎችን፣ ፈጣን እና ደህንነቱ የተጠበቀ የዳታቤዝ አሰራርን ለተማሪዎችና ለተቋማት ያቀርባል።'
                        : 'HAB IT Solutions is a premier technology and software engineering initiative focused on building scalable, localized mobile apps, offline-first digital learning architectures, and modern cloud database solutions. We bridge the digital divide by engineering software that performs flawlessly even with limited internet connectivity.',
                    style: GoogleFonts.notoSansEthiopic(
                      fontSize: 13,
                      height: 1.6,
                      color: isLight ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3. Core Capabilities & Services Grid
            Text(
              isAm ? 'ዋና ዋና አገልግሎቶች እና ቴክኖሎጂዎች' : 'Core Services & Tech Stack',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),

            _buildServiceItem(
              icon: Icons.phone_android_rounded,
              iconColor: const Color(0xFF0284C7),
              title: isAm ? 'የሞባይል አፕሊኬሽን ልማት' : 'Cross-Platform Mobile Apps',
              description: isAm
                  ? 'ለአንድሮይድ እና አይኦኤስ የተዘጋጁ ዘመናዊ፣ ፈጣን እና ማራኪ መተግበሪያዎች (Flutter, Dart)'
                  : 'High-performance Android & iOS applications built with clean architecture and Flutter.',
              isLight: isLight,
              cardBg: cardBg,
              borderColor: borderColor,
              textColor: textColor,
              subColor: subColor,
            ),
            const SizedBox(height: 10),

            _buildServiceItem(
              icon: Icons.storage_rounded,
              iconColor: const Color(0xFF10B981),
              title: isAm ? 'የዳታቤዝ እና ክላውድ ሲስተም' : 'PostgreSQL & Cloud Infrastructure',
              description: isAm
                  ? 'ከሱፓቤዝ (Supabase) እና ፖስትግሬስ ዳታቤዝ ጋር የተገናኙ ዘመናዊ የዳታ አያያዝ ስርዓቶች'
                  : 'Robust relational database schemas, real-time data sync, and cloud storage management.',
              isLight: isLight,
              cardBg: cardBg,
              borderColor: borderColor,
              textColor: textColor,
              subColor: subColor,
            ),
            const SizedBox(height: 10),

            _buildServiceItem(
              icon: Icons.offline_pin_rounded,
              iconColor: const Color(0xFFF59E0B),
              title: isAm ? 'ከመስመር ውጭ የሚሰሩ ስርዓቶች (Offline-First)' : 'Offline-First Architectures',
              description: isAm
                  ? 'ያለ ኢንተርኔት ጥያቄዎችን፣ የቪዲዮ ትምህርቶችን እና ፒዲኤፍ ማስታወሻዎችን የሚያስቀምጡ ቴክኖሎጂዎች'
                  : 'Smart client-side caching algorithms enabling 100% offline access to quizzes, PDFs, and notes.',
              isLight: isLight,
              cardBg: cardBg,
              borderColor: borderColor,
              textColor: textColor,
              subColor: subColor,
            ),
            const SizedBox(height: 10),

            _buildServiceItem(
              icon: Icons.security_rounded,
              iconColor: const Color(0xFF8B5CF6),
              title: isAm ? 'የመተግበሪያ ደህንነት እና ፍቃድ' : 'App Security & Device Licensing',
              description: isAm
                  ? 'በመሳሪያ መለያ (Hardware ID) የታሰሩ እና ያልተፈቀደ ስርጭትን የሚከላከሉ የደህንነት ስርዓቶች'
                  : 'Single-device hardware-locked subscription verification and tamper-resistant code.',
              isLight: isLight,
              cardBg: cardBg,
              borderColor: borderColor,
              textColor: textColor,
              subColor: subColor,
            ),
            const SizedBox(height: 24),

            // 4. Contact & Inquiries Section
            Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isAm ? 'ቀጥታ ግንኙነት እና ማነጋገሪያ' : 'DIRECT DEVELOPER CONTACT',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF10B981),
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  // Phone Call Button
                  InkWell(
                    onTap: () => _makePhoneCall(context),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF10B981).withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.phone_rounded, color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isAm ? 'ቀጥታ ስልክ ቁጥር' : 'Direct Phone Line',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: subColor,
                                  ),
                                ),
                                Text(
                                  '+251 900 297 614',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF10B981)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Email Button
                  InkWell(
                    onTap: () => _sendEmail(context),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFF0284C7),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.email_rounded, color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isAm ? 'ኦፊሴላዊ የኢሜይል አድራሻ' : 'Official Email',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: subColor,
                                  ),
                                ),
                                Text(
                                  'habtamu.yifiru.official@gmail.com',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF0284C7)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Location Info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on_rounded, size: 16, color: subColor),
                      const SizedBox(width: 6),
                      Text(
                        isAm ? 'አዲስ አበባ፣ ኢትዮጵያ (Addis Ababa, Ethiopia)' : 'Addis Ababa, Ethiopia',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: subColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required bool isLight,
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
    required Color subColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.notoSansEthiopic(
                    fontSize: 12,
                    height: 1.45,
                    color: subColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
