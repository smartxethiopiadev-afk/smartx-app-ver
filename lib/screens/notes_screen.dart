import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../models/subject_model.dart';
import '../services/offline_service.dart';

class NotesScreen extends StatelessWidget {
  final UnitModel unit;
  final SubjectConfig subject;
  final int grade;

  const NotesScreen({
    super.key,
    required this.unit,
    required this.subject,
    required this.grade,
  });

  @override
  Widget build(BuildContext context) {
    final offline = context.watch<OfflineService>();
    final isAm = offline.language == LanguageCode.am;
    final note = offline.getShortNoteForUnit(unit.unitId, subject.enTitle, grade, unit.unitNumber);
    final isDownloaded = offline.isUnitDownloaded(unit.unitId);

    return Scaffold(
      backgroundColor: AppConfig.darkBackground,
      appBar: AppBar(
        backgroundColor: AppConfig.darkCard,
        elevation: 0,
        title: Text(
          '${subject.code} • Unit ${unit.unitNumber} Notes',
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
        actions: [
          // Download / Offline Toggle
          IconButton(
            icon: Icon(
              isDownloaded ? Icons.offline_pin : Icons.download_outlined,
              color: isDownloaded ? AppConfig.primaryGreen : Colors.white70,
            ),
            tooltip: isDownloaded ? 'Available Offline' : 'Download for Offline Study',
            onPressed: () {
              offline.toggleUnitDownload(unit, subject.id, grade);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isDownloaded
                        ? (isAm ? 'ዩኒቱ ከመሳሪያዎ ተሰርዟል' : 'Unit removed from offline storage')
                        : (isAm ? 'ማጠቃለያውና ጥያቄዎቹ በተሳካ ሁኔታ ወርደዋል!' : 'Notes & questions downloaded for offline access!'),
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          // Telegram Share / Report Issue
          IconButton(
            icon: const Icon(Icons.send_rounded, color: Color(0xFF29B6F6), size: 20),
            tooltip: 'Share / Ask on Telegram',
            onPressed: () {
              final text = '''
[Smart X Ethiopia Notes]
Subject: ${subject.code} (Grade $grade)
Unit ${unit.unitNumber}: ${unit.enTitle}
Official Channel: @smartx_ethiopia
''';
              Clipboard.setData(ClipboardData(text: text));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isAm
                        ? 'የማስታወሻው ሊንክ ተገልብጧል! በቴሌግራም ቻናል (@smartx_ethiopia) መጋራት ይችላሉ።'
                        : 'Notes copied! Join discussion at @smartx_ethiopia',
                  ),
                  backgroundColor: const Color(0xFF0288D1),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [subject.primaryColor.withValues(alpha: 0.3), AppConfig.darkCard],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: subject.primaryColor.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: subject.primaryColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Grade $grade • Unit ${unit.unitNumber}',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.verified, color: AppConfig.primaryGreen, size: 12),
                              SizedBox(width: 4),
                              Text('NEAEA Aligned', style: TextStyle(color: Colors.white70, fontSize: 11)),
                            ],
                          ),
                        ),
                        if (isDownloaded) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppConfig.primaryGreen.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.check_circle, color: AppConfig.primaryGreen, size: 12),
                                SizedBox(width: 4),
                                Text('Offline', style: TextStyle(color: AppConfig.primaryGreen, fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isAm ? unit.amTitle : unit.enTitle,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      note.title,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Note Content Body
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppConfig.darkCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Text(
                  note.content,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.6,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
