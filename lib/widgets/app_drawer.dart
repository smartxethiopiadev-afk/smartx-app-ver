import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../services/offline_service.dart';
import '../screens/downloads_screen.dart';
import '../screens/worksheets_screen.dart';
import '../screens/analytics_monitor_screen.dart';
import '../screens/about_screen.dart';
import '../screens/feedback_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final offline = context.watch<OfflineService>();
    final isAm = offline.language == LanguageCode.am;
    final profile = offline.profile;
    final downloadCount = offline.downloadedUnitIds.length;

    return Drawer(
      backgroundColor: AppConfig.darkBackground,
      child: Column(
        children: [
          // Drawer Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 50, bottom: 20, left: 20, right: 20),
            decoration: const BoxDecoration(
              color: AppConfig.darkCard,
              border: Border(bottom: BorderSide(color: Colors.white10)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppConfig.primaryGreen.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppConfig.primaryGreen, width: 1.5),
                      ),
                      child: const Icon(Icons.school, color: AppConfig.primaryGreen, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.fullName,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            profile.phoneNumber,
                            style: const TextStyle(color: Colors.white60, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppConfig.primaryGreen,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Grade ${offline.currentGrade}',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.offline_pin_rounded, color: AppConfig.accentAmber, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            '$downloadCount ${isAm ? "የወረዱ" : "Offline"}',
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Drawer Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildDrawerItem(
                  icon: Icons.home_rounded,
                  title: isAm ? 'መነሻ / ትምህርት' : 'Home & Curriculum',
                  onTap: () => Navigator.pop(context),
                  color: AppConfig.primaryGreen,
                ),
                _buildDrawerItem(
                  icon: Icons.cloud_download_rounded,
                  title: isAm ? 'የወረዱ ዩኒቶች (Downloads)' : 'Downloaded Units',
                  badge: '$downloadCount',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const DownloadsScreen()));
                  },
                  color: Colors.blueAccent,
                ),
                _buildDrawerItem(
                  icon: Icons.assignment_outlined,
                  title: isAm ? 'የፈተና ዎርክሺቶች' : 'Worksheets & Drills',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const WorksheetsScreen()));
                  },
                  color: AppConfig.accentAmber,
                ),
                _buildDrawerItem(
                  icon: Icons.analytics_outlined,
                  title: isAm ? 'አክቲቭ ተጠቃሚዎችና ማስታወቂያ' : 'Active Users & AdMob',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalyticsMonitorScreen()));
                  },
                  color: Colors.purpleAccent,
                ),
                const Divider(color: Colors.white10, indent: 16, endIndent: 16, height: 16),
                _buildDrawerItem(
                  icon: Icons.rate_review_outlined,
                  title: isAm ? 'አስተያየት ይስጡ' : 'Send Feedback',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const FeedbackScreen()));
                  },
                  color: Colors.tealAccent,
                ),
                _buildDrawerItem(
                  icon: Icons.info_outline_rounded,
                  title: isAm ? 'ስለ እኛ (About Us)' : 'About Smart X Academy',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen()));
                  },
                  color: Colors.cyanAccent,
                ),
                _buildDrawerItem(
                  icon: Icons.send_rounded,
                  title: isAm ? 'የቴሌግራም ግሩፕ' : 'Telegram Community',
                  onTap: () {
                    Navigator.pop(context);
                    _showTelegramDialog(context, isAm);
                  },
                  color: const Color(0xFF29B6F6),
                ),
              ],
            ),
          ),

          // Drawer Footer (Language toggle & Version)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppConfig.darkCard,
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    offline.setLanguage(isAm ? LanguageCode.en : LanguageCode.am);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.language, color: Colors.white70, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          isAm ? 'English' : 'አማርኛ',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const Text(
                  'v${AppConfig.appVersion}',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required Color color,
    String? badge,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
      ),
      trailing: badge != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badge,
                style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            )
          : const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
      onTap: onTap,
    );
  }

  void _showTelegramDialog(BuildContext context, bool isAm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConfig.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF29B6F6).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.send_rounded, color: Color(0xFF29B6F6), size: 22),
            ),
            const SizedBox(width: 10),
            Text(
              isAm ? 'የስማርት ኤክስ ቴሌግራም' : 'Telegram Channel',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAm
                  ? 'የየዕለቱ የፈተና ጥያቄዎች፣ ፒዲኤፍ ማስታወሻዎች እና የስህተት ጥቆማዎችን በቴሌግራም ቻናላችን ያግኙ።'
                  : 'Join our official Telegram channel for daily model exams, PDF notes, and direct question feedback.',
              style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const SelectableText(
                'https://t.me/smartx_ethiopia\nBot: @smartx_support_bot',
                style: TextStyle(color: Color(0xFF29B6F6), fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF29B6F6),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: Text(isAm ? 'እሺ' : 'Close'),
          ),
        ],
      ),
    );
  }
}
