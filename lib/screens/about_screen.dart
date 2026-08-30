import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../services/offline_service.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final offline = context.watch<OfflineService>();
    final isAm = offline.language == LanguageCode.am;

    return Scaffold(
      backgroundColor: AppConfig.darkBackground,
      appBar: AppBar(
        backgroundColor: AppConfig.darkCard,
        elevation: 0,
        title: Text(
          isAm ? 'ስለ እኛ (About Smart X)' : 'About Smart X Academy',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // App Banner Logo Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppConfig.darkCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppConfig.primaryGreen.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppConfig.primaryGreen.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppConfig.primaryGreen, width: 2),
                    ),
                    child: const Icon(Icons.school, color: AppConfig.primaryGreen, size: 40),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Smart X Academy Ethiopia',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'v${AppConfig.appVersion} • Ethiopian High School Platform',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppConfig.primaryGreen.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isAm ? 'በኢትዮጵያ ሥርዓተ-ትምህርት የተዘጋጀ' : '100% Aligned with New Ethiopian Curriculum',
                      style: const TextStyle(color: AppConfig.primaryGreen, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Mission Statement
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppConfig.darkCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lightbulb_outline, color: AppConfig.accentAmber, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        isAm ? 'ዓላማችን' : 'Our Mission',
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isAm
                        ? 'ስማርት ኤክስ አካዳሚ ለኢትዮጵያ ሁለተኛ ደረጃ ተማሪዎች (ከ 9ኛ እስከ 12ኛ ክፍል) ጥራት ያለው ትምህርት፣ የማጠቃለያ ኖቶች፣ የፈተና ዎርክሺቶችና የሞዴል ፈተናዎችን ያለ ኢንተርኔት (Offline) በቀላሉ ተደራሽ ለማድረግ የተዘጋጀ የትምህርት መተግበሪያ ነው።'
                        : 'Smart X Academy is an educational platform dedicated to Ethiopian high school students (Grades 9 - 12), providing structured short notes, high-yield worksheets, and exam simulations that function entirely offline without internet.',
                    style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Key Highlights
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppConfig.darkCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAm ? 'ዋና ዋና አገልግሎቶች' : 'Key Features & Capabilities',
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureTile(
                    Icons.offline_pin,
                    isAm ? 'ሙሉ በሙሉ ያለ ኔትወርክ ይሰራል' : '100% Offline Capability',
                    isAm ? 'የወረዱ ኖቶችና ጥያቄዎች ያለ ኢንተርኔት ክፍት ናቸው' : 'Read notes and take quizzes anywhere without data bundles.',
                  ),
                  _buildFeatureTile(
                    Icons.assignment_turned_in_outlined,
                    isAm ? 'የፈተና ዎርክሺቶችና ሞዴል ጥያቄዎች' : 'Unit Worksheets & Drills',
                    isAm ? 'በእያንዳንዱ ምዕራፍ የተዘጋጁ የብሔራዊ ፈተና ደረጃ ጥያቄዎች' : 'Unit-by-unit practice sheets tailored to matric examinations.',
                  ),
                  _buildFeatureTile(
                    Icons.telegram,
                    isAm ? 'የስህተት መጠቆሚያ እና የቴሌግራም ድጋፍ' : 'Direct Question Feedback',
                    isAm ? 'በጥያቄዎች ላይ ያለን ስህተት በቀጥታ በቴሌግራም መጠቆም' : 'Instantly report errors and receive support via Telegram.',
                  ),
                  _buildFeatureTile(
                    Icons.analytics_outlined,
                    isAm ? 'የተጠቃሚዎች ዳታና ማስታወቂያ ትንታኔ' : 'Real-time Analytics & AdMob Sync',
                    isAm ? 'ቀጥታ አክቲቭ ተጠቃሚዎችና የ AdMob ገቢ ትንታኔ' : 'Live telemetry tracking active learners and ad ecosystem.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Contact & Telegram Community
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppConfig.darkCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.send_rounded, color: Colors.blueAccent, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Telegram Community & Support',
                        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isAm
                        ? 'ጥያቄ፣ አስተያየት ወይም የትምህርት ድጋፍ ለማግኘት በቴሌግራም ይገናኙን።'
                        : 'Join thousands of Ethiopian students in our Telegram community for daily exam tips, discussion, and direct support.',
                    style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('@smartx_ethiopia', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('Official Channel', style: TextStyle(color: Colors.white54, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureTile(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppConfig.primaryGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppConfig.primaryGreen, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 11, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
