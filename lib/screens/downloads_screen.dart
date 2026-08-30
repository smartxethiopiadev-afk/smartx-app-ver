import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../models/download_analytics_model.dart';
import '../models/subject_model.dart';
import '../services/offline_service.dart';
import 'quiz_screen.dart';
import 'notes_screen.dart';

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final offline = context.watch<OfflineService>();
    final isAm = offline.language == LanguageCode.am;
    final downloads = offline.downloadedUnitsList;
    final totalSizeKb = downloads.fold<int>(0, (sum, item) => sum + item.sizeKb);

    return Scaffold(
      backgroundColor: AppConfig.darkBackground,
      appBar: AppBar(
        backgroundColor: AppConfig.darkCard,
        elevation: 0,
        title: Text(
          isAm ? 'የወረዱ ዩኒቶችና ማስታወሻዎች' : 'Offline Downloads Manager',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Storage & Summary Header Cards
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppConfig.darkCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppConfig.primaryGreen.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.offline_pin_rounded, color: AppConfig.primaryGreen, size: 24),
                        const SizedBox(height: 8),
                        Text(
                          '${downloads.length} ${isAm ? "ዩኒቶች" : "Units"}',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          isAm ? 'ሙሉ በሙሉ ያለ ኔትወርክ' : 'Available Offline',
                          style: const TextStyle(color: Colors.white60, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppConfig.darkCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppConfig.accentAmber.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.storage_rounded, color: AppConfig.accentAmber, size: 24),
                        const SizedBox(height: 8),
                        Text(
                          '${(totalSizeKb / 1024).toStringAsFixed(2)} MB',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          isAm ? 'የያዘው ቦታ' : 'Storage Footprint',
                          style: const TextStyle(color: Colors.white60, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Section Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isAm ? 'የወረዱ ዩኒቶች ዝርዝር' : 'Downloaded Units Breakdown',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppConfig.primaryGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${downloads.length} Active',
                    style: const TextStyle(color: AppConfig.primaryGreen, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (downloads.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppConfig.darkCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.cloud_download_outlined, color: Colors.white38, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      isAm ? 'እስካሁን የወረደ ዩኒት የለም' : 'No units downloaded yet',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isAm
                          ? 'ከዋናው ገጽ ላይ የሚፈልጉትን ዩኒት በመምረጥ ያለ ኔትወርክ ለማንበብ ያውርዱ።'
                          : 'Download any subject unit from the home screen to access study notes and practice exams offline without internet.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollException(),
                itemCount: downloads.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = downloads[index];
                  final subjectConfig = allSubjects.firstWhere(
                    (s) => s.id == item.subjectId || s.code.toLowerCase() == item.subjectId.toLowerCase(),
                    orElse: () => allSubjects.first,
                  );

                  return Container(
                    decoration: BoxDecoration(
                      color: AppConfig.darkCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: subjectConfig.primaryColor.withValues(alpha: 0.3)),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: subjectConfig.primaryColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(subjectConfig.icon, color: subjectConfig.primaryColor, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: subjectConfig.primaryColor,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Grade ${item.grade} • Unit ${item.unitNumber}',
                                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        subjectConfig.code,
                                        style: TextStyle(color: subjectConfig.primaryColor, fontWeight: FontWeight.bold, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isAm && item.amTitle.isNotEmpty ? item.amTitle : item.enTitle,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                              tooltip: 'Remove download',
                              onPressed: () {
                                offline.deleteDownloadedUnit(item.unitId);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(isAm ? 'ዩኒቱ ከመሳሪያዎ ተሰርዟል' : 'Unit removed from offline storage'),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${item.questionCount} Questions • ${item.sizeKb} KB',
                                style: const TextStyle(color: Colors.white60, fontSize: 11),
                              ),
                              Text(
                                '${item.downloadedAt.day}/${item.downloadedAt.month}/${item.downloadedAt.year}',
                                style: const TextStyle(color: Colors.white38, fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: subjectConfig.primaryColor,
                                  side: BorderSide(color: subjectConfig.primaryColor.withValues(alpha: 0.5)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                                onPressed: () {
                                  final unitModel = UnitModel(
                                    unitNumber: item.unitNumber,
                                    unitId: item.unitId,
                                    enTitle: item.enTitle,
                                    amTitle: item.amTitle,
                                    description: '',
                                    questionCount: item.questionCount,
                                    hasNotes: true,
                                    estimatedMinutes: 20,
                                  );
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => NotesScreen(
                                        unit: unitModel,
                                        subject: subjectConfig,
                                        grade: item.grade,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.menu_book, size: 16),
                                label: Text(isAm ? 'ማስታወሻ አንብብ' : 'Read Note', style: const TextStyle(fontSize: 12)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: subjectConfig.primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                                onPressed: () {
                                  final unitModel = UnitModel(
                                    unitNumber: item.unitNumber,
                                    unitId: item.unitId,
                                    enTitle: item.enTitle,
                                    amTitle: item.amTitle,
                                    description: '',
                                    questionCount: item.questionCount,
                                    hasNotes: true,
                                    estimatedMinutes: 20,
                                  );
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => QuizScreen(
                                        unit: unitModel,
                                        subject: subjectConfig,
                                        grade: item.grade,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.play_arrow_rounded, size: 16),
                                label: Text(isAm ? 'ፈተና ጀምር' : 'Start Quiz', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
