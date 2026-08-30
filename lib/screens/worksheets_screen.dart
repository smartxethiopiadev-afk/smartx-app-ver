import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../models/worksheet_model.dart';
import '../services/offline_service.dart';

class WorksheetsScreen extends StatefulWidget {
  const WorksheetsScreen({super.key});

  @override
  State<WorksheetsScreen> createState() => _WorksheetsScreenState();
}

class _WorksheetsScreenState extends State<WorksheetsScreen> {
  String _selectedSubjectId = 'mathematics';

  @override
  Widget build(BuildContext context) {
    final offline = context.watch<OfflineService>();
    final isAm = offline.language == LanguageCode.am;
    final currentGrade = offline.currentGrade;
    final worksheets = offline.getWorksheetsForSubject(_selectedSubjectId, currentGrade);

    final currentSubject = allSubjects.firstWhere(
      (s) => s.id == _selectedSubjectId,
      orElse: () => allSubjects.first,
    );

    return Scaffold(
      backgroundColor: AppConfig.darkBackground,
      appBar: AppBar(
        backgroundColor: AppConfig.darkCard,
        elevation: 0,
        title: Text(
          isAm ? 'የፈተና ዎርክሺቶችና ልምምዶች' : 'Exam Worksheets & Drills',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          // Grade & Subject Selector Bar
          Container(
            color: AppConfig.darkCard,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                // Grade Toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [9, 10, 11, 12].map((g) {
                    final isSelected = currentGrade == g;
                    return GestureDetector(
                      onTap: () => offline.setGrade(g),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? AppConfig.primaryGreen : Colors.white10,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Grade $g',
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),

                // Subjects Horizontal Scroll
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: allSubjects.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final subject = allSubjects[index];
                      final isSelected = subject.id == _selectedSubjectId;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedSubjectId = subject.id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? subject.primaryColor : Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? Colors.transparent : Colors.white12,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(subject.icon, size: 16, color: isSelected ? Colors.white : subject.primaryColor),
                              const SizedBox(width: 6),
                              Text(
                                isAm ? subject.amTitle : subject.enTitle,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.white70,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Worksheets List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: worksheets.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final ws = worksheets[index];
                final isDownloaded = offline.isWorksheetDownloaded(ws.id);

                return Container(
                  decoration: BoxDecoration(
                    color: AppConfig.darkCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: currentSubject.primaryColor.withValues(alpha: 0.3)),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: currentSubject.primaryColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.assignment_outlined, color: currentSubject.primaryColor, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: currentSubject.primaryColor,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Grade $currentGrade • Unit ${ws.unitNumber}',
                                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppConfig.accentAmber.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        ws.difficulty,
                                        style: const TextStyle(color: AppConfig.accentAmber, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  isAm && ws.amTitle.isNotEmpty ? ws.amTitle : ws.title,
                                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        ws.description,
                        style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                      ),
                      const SizedBox(height: 12),

                      // Key topics chips
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: ws.keyTopics.map((topic) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Text(
                              '#$topic',
                              style: const TextStyle(color: Colors.white60, fontSize: 10),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),

                      // Action row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.quiz_outlined, size: 14, color: Colors.white38),
                              const SizedBox(width: 4),
                              Text(
                                '${ws.totalQuestions} Questions',
                                style: const TextStyle(color: Colors.white54, fontSize: 11),
                              ),
                              const SizedBox(width: 12),
                              const Icon(Icons.file_download_outlined, size: 14, color: Colors.white38),
                              const SizedBox(width: 4),
                              Text(
                                '${ws.downloadCount} ${isAm ? "ተጠቃሚዎች" : "downloads"}',
                                style: const TextStyle(color: Colors.white54, fontSize: 11),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDownloaded ? AppConfig.primaryGreen : currentSubject.primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onPressed: () {
                              offline.toggleWorksheetDownload(ws);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isDownloaded
                                        ? (isAm ? 'ዎርክሺቱ ተወግዷል' : 'Worksheet removed from offline storage')
                                        : (isAm ? 'ዎርክሺቱ በተሳካ ሁኔታ ወርዷል!' : 'Worksheet downloaded for offline practice!'),
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            icon: Icon(isDownloaded ? Icons.check_circle : Icons.download_rounded, size: 16),
                            label: Text(
                              isDownloaded ? (isAm ? 'ወርዷል' : 'Downloaded') : (isAm ? 'አውርድ' : 'Download'),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
  }
}
