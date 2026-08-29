import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';
import '../services/offline_service.dart';
import 'registration_overlay.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final offline = context.watch<OfflineService>();
    final isAm = offline.language == LanguageCode.am;
    final profile = offline.profile;

    return Scaffold(
      backgroundColor: AppConfig.darkBackground,
      appBar: AppBar(
        backgroundColor: AppConfig.darkCard,
        elevation: 0,
        title: Text(
          isAm ? 'የተማሪ ፕሮፋይል' : 'Student Profile',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // User Avatar Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppConfig.darkCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppConfig.primaryGreen.withValues(alpha: 0.2),
                    child: const Icon(Icons.person, color: AppConfig.primaryGreen, size: 36),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.fullName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          profile.phoneNumber,
                          style: const TextStyle(color: Colors.white60, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppConfig.primaryGreen.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Grade ${offline.currentGrade}',
                            style: const TextStyle(
                              color: AppConfig.primaryGreen,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.white70),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => RegistrationOverlay(onRegistered: () => Navigator.pop(ctx)),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Daily Streak & Stat Cards
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppConfig.darkCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppConfig.accentAmber.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.local_fire_department, color: AppConfig.accentAmber, size: 28),
                        const SizedBox(height: 8),
                        Text(
                          '${profile.streakDays} Days',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        Text(
                          isAm ? 'የጥናት ቅደም ተከተል' : 'Study Streak',
                          style: const TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppConfig.darkCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppConfig.primaryGreen.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.offline_pin, color: AppConfig.primaryGreen, size: 28),
                        const SizedBox(height: 8),
                        Text(
                          '${offline.downloadedUnitIds.length} Units',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        Text(
                          isAm ? 'ያለ ኔትወርክ የወረዱ' : 'Downloaded',
                          style: const TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Settings Tile Options
            Container(
              decoration: BoxDecoration(
                color: AppConfig.darkCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.language, color: Colors.blueAccent),
                    title: Text(isAm ? 'ቋንቋ ቀይር' : 'Language / ቋንቋ', style: const TextStyle(color: Colors.white)),
                    subtitle: Text(offline.language == LanguageCode.am ? 'አማርኛ' : 'English', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                    onTap: () {
                      offline.setLanguage(offline.language == LanguageCode.am ? LanguageCode.en : LanguageCode.am);
                    },
                  ),
                  const Divider(color: Colors.white10, height: 1),
                  ListTile(
                    leading: const Icon(Icons.send_rounded, color: Color(0xFF0284C7)),
                    title: Text(isAm ? 'ስማርት ኤክስ ቴሌግራም' : 'Smart X Telegram', style: const TextStyle(color: Colors.white)),
                    subtitle: const Text('t.me/smartx_ethiopia', style: TextStyle(color: Colors.white60, fontSize: 12)),
                    trailing: const Icon(Icons.open_in_new, color: Colors.white54, size: 18),
                    onTap: () async {
                      final uri = Uri.parse(AppConfig.telegramChannelUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
