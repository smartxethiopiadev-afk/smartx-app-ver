import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';
import '../services/offline_service.dart';
import '../widgets/app_drawer.dart';
import 'quiz_screen.dart';
import 'notes_screen.dart';
import 'downloads_screen.dart';
import 'worksheets_screen.dart';
import 'analytics_monitor_screen.dart';
import 'registration_overlay.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final offline = context.watch<OfflineService>();
    final isAm = offline.language == LanguageCode.am;
    final currentGrade = offline.currentGrade;
    final downloadedCount = offline.downloadedUnitIds.length;

    return Scaffold(
      backgroundColor: AppConfig.darkBackground,
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: AppConfig.darkCard,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.white),
            tooltip: 'Menu',
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppConfig.primaryGreen.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.school, color: AppConfig.primaryGreen, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              isAm ? 'ስማርት ኤክስ' : 'Smart X Learning',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
            ),
          ],
        ),
        actions: [
          // Downloads quick action
          IconButton(
            icon: Badge(
              label: Text('$downloadedCount'),
              backgroundColor: AppConfig.primaryGreen,
              isLabelVisible: downloadedCount > 0,
              child: const Icon(Icons.cloud_download_outlined, color: Colors.white70),
            ),
            tooltip: isAm ? 'የወረዱ ዩኒቶች' : 'Downloaded Units',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const DownloadsScreen()));
            },
          ),
          IconButton(
            icon: Icon(
              offline.language == LanguageCode.am ? Icons.language : Icons.translate,
              color: AppConfig.accentAmber,
            ),
            onPressed: () {
              offline.setLanguage(offline.language == LanguageCode.am ? LanguageCode.en : LanguageCode.am);
            },
            tooltip: 'Switch Language',
          ),
          if (!offline.profile.isRegistered)
            TextButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => RegistrationOverlay(onRegistered: () => Navigator.pop(ctx)),
                );
              },
              icon: const Icon(Icons.person_add, color: AppConfig.primaryGreen, size: 16),
              label: Text(
                isAm ? 'ይመዝገቡ' : 'Register',
                style: const TextStyle(color: AppConfig.primaryGreen, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Grade Selector Bar
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppConfig.darkCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [9, 10, 11, 12].map((g) {
                        final isSelected = currentGrade == g;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => offline.setGrade(g),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? AppConfig.primaryGreen : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  'Grade $g',
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.white70,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Quick Action Cards Row (Downloads, Worksheets, Analytics/AdMob)
                  Row(
                    children: [
                      // Downloads Manager Card
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DownloadsScreen())),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppConfig.darkCard,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppConfig.primaryGreen.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Icon(Icons.offline_pin_rounded, color: AppConfig.primaryGreen, size: 20),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: AppConfig.primaryGreen.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '$downloadedCount ${isAm ? "የወረዱ" : "Offline"}',
                                        style: const TextStyle(color: AppConfig.primaryGreen, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  isAm ? 'የወረዱ ዩኒቶች' : 'Downloads',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                Text(
                                  isAm ? 'ሙሉ በሙሉ ያለ ኔትወርክ' : 'Access offline',
                                  style: const TextStyle(color: Colors.white60, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Worksheets Card
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WorksheetsScreen())),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppConfig.darkCard,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppConfig.accentAmber.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Icon(Icons.assignment_outlined, color: AppConfig.accentAmber, size: 20),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: AppConfig.accentAmber.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'New',
                                        style: TextStyle(color: AppConfig.accentAmber, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  isAm ? 'የፈተና ዎርክሺቶች' : 'Worksheets',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                Text(
                                  isAm ? 'የሞዴል ፈተናዎች' : 'Model Exam Drills',
                                  style: const TextStyle(color: Colors.white60, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Real-time Analytics & AdMob Card
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalyticsMonitorScreen())),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppConfig.darkCard,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Icon(Icons.analytics_outlined, color: Colors.blueAccent, size: 20),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Colors.blueAccent.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '${offline.activeUsersToday} live',
                                        style: const TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  isAm ? 'አክቲቭ ተጠቃሚዎች' : 'Analytics & Ad',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  isAm ? 'የ AdMob ዳታ' : 'Live telemetry',
                                  style: const TextStyle(color: Colors.white60, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Telegram Community Banner
                  GestureDetector(
                    onTap: () async {
                      final uri = Uri.parse(AppConfig.telegramChannelUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.send_rounded, color: Colors.white, size: 26),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isAm ? 'የቴሌግራም የጥናት ቻናላችንን ይቀላቀሉ' : 'Join Our Telegram Community',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Text(
                                  isAm ? 'ዕለታዊ ፈተናዎች፣ የፈተና ጥያቄዎች እና ኖቶች' : 'Daily model exams, pdf notes & live discussions',
                                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.white70),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Section Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isAm ? 'የትምህርት ዓይነቶች (Grade $currentGrade)' : 'Subjects (Grade $currentGrade)',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${allSubjects.length} ${isAm ? "ትምህርቶች" : "Curriculums"}',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Subjects Grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final subject = allSubjects[index];
                  return GestureDetector(
                    onTap: () {
                      _showUnitModal(context, subject, currentGrade, offline);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppConfig.darkCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: subject.primaryColor.withValues(alpha: 0.3)),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: subject.primaryColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(subject.icon, color: subject.primaryColor, size: 22),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white10,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${offline.getUnitsForSubject(subject.id, currentGrade).length} Units',
                                  style: const TextStyle(color: Colors.white60, fontSize: 10),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isAm ? subject.amTitle : subject.enTitle,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                subject.code,
                                style: TextStyle(
                                  color: subject.primaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: allSubjects.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }

  void _showUnitModal(BuildContext context, SubjectConfig subject, int grade, OfflineService offline) {
    final units = offline.getUnitsForSubject(subject.id, grade);
    final isAm = offline.language == LanguageCode.am;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppConfig.darkBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          maxChildSize: 0.92,
          minChildSize: 0.4,
          expand: false,
          builder: (_, controller) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(subject.icon, color: subject.primaryColor, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        '${isAm ? subject.amTitle : subject.enTitle} (Grade $grade)',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      controller: controller,
                      itemCount: units.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, index) {
                        final unit = units[index];
                        final isDownloaded = offline.isUnitDownloaded(unit.unitId);

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppConfig.darkCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isDownloaded ? AppConfig.primaryGreen.withValues(alpha: 0.4) : Colors.white10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      isAm ? unit.amTitle : unit.enTitle,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      isDownloaded ? Icons.offline_pin : Icons.download_outlined,
                                      color: isDownloaded ? AppConfig.primaryGreen : Colors.white54,
                                      size: 22,
                                    ),
                                    tooltip: isDownloaded ? 'Downloaded (Offline)' : 'Download Unit',
                                    onPressed: () {
                                      offline.toggleUnitDownload(unit, subject.id, grade);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            isDownloaded
                                                ? (isAm ? 'ዩኒቱ ከመሳሪያዎ ተሰርዟል' : 'Unit removed from offline storage')
                                                : (isAm ? 'ዩኒቱ በተሳካ ሁኔታ ወርዷል!' : 'Unit downloaded for offline study!'),
                                          ),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              Text(
                                unit.description,
                                style: const TextStyle(color: Colors.white60, fontSize: 12),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => QuizScreen(
                                              unit: unit,
                                              subject: subject,
                                              grade: grade,
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.quiz_outlined, size: 16),
                                      label: Text(isAm ? 'ጥያቄዎች' : 'Quiz (${unit.questionCount})'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: subject.primaryColor,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => NotesScreen(
                                              unit: unit,
                                              subject: subject,
                                              grade: grade,
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.menu_book, size: 16),
                                      label: Text(isAm ? 'ማጠቃለያ' : 'Summary'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        side: const BorderSide(color: Colors.white24),
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
