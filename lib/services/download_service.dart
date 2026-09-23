import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/question_model.dart';
import '../models/offline_package_model.dart';
import 'offline_manager.dart';
import 'quiz_service.dart';
import 'short_note_service.dart';

enum DownloadType {
  pdfNote,
  questionPackage,
}

enum DownloadStatus {
  idle,
  downloading,
  completed,
  failed,
}

class DownloadTaskState {
  final String taskId;
  final DownloadType type;
  final String title;
  final String subject;
  final int grade;
  final int unit;
  final double progress; // 0.0 to 1.0
  final DownloadStatus status;
  final String? errorMessage;
  final int bytesReceived;
  final int totalBytes;

  DownloadTaskState({
    required this.taskId,
    required this.type,
    required this.title,
    required this.subject,
    required this.grade,
    required this.unit,
    this.progress = 0.0,
    this.status = DownloadStatus.idle,
    this.errorMessage,
    this.bytesReceived = 0,
    this.totalBytes = 0,
  });

  DownloadTaskState copyWith({
    double? progress,
    DownloadStatus? status,
    String? errorMessage,
    int? bytesReceived,
    int? totalBytes,
  }) {
    return DownloadTaskState(
      taskId: taskId,
      type: type,
      title: title,
      subject: subject,
      grade: grade,
      unit: unit,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      bytesReceived: bytesReceived ?? this.bytesReceived,
      totalBytes: totalBytes ?? this.totalBytes,
    );
  }
}

class DownloadService {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  static final Map<String, DownloadTaskState> _activeTasks = {};
  static final ValueNotifier<Map<String, DownloadTaskState>> tasksNotifier = ValueNotifier({});

  static Map<String, DownloadTaskState> get activeTasks => Map.unmodifiable(_activeTasks);

  static void _updateTask(DownloadTaskState state) {
    _activeTasks[state.taskId] = state;
    tasksNotifier.value = Map.from(_activeTasks);
  }

  static void _removeTask(String taskId) {
    _activeTasks.remove(taskId);
    tasksNotifier.value = Map.from(_activeTasks);
  }

  /// Checks if a PDF is already stored offline
  static Future<bool> isPdfDownloaded(String unitId) async {
    return await OfflineManager.hasOfflinePdf(unitId);
  }

  /// Checks if a question package is already stored offline
  static Future<bool> isQuestionPackageDownloaded(String unitId) async {
    final pkg = await OfflineManager.getQuestionPackage(unitId);
    if (pkg != null && pkg.totalQuestions > 0) return true;
    return await OfflineManager.hasOfflineQuestions(unitId);
  }

  /// Download Short Note PDF in background with progress callbacks
  static Future<OfflinePdfModel> downloadPdf({
    required String unitId,
    required String pdfUrl,
    required String title,
    required String subject,
    required int grade,
    required int unit,
    Function(double progress, int receivedBytes, int totalBytes)? onProgress,
  }) async {
    final cleanId = OfflineManager.cleanKey(unitId);
    final taskId = 'pdf_$cleanId';

    // Duplicate check
    final existing = await OfflineManager.getOfflinePdfModel(cleanId);
    if (existing != null && existing.localPath.isNotEmpty) {
      final file = File(existing.localPath);
      if (await file.exists()) {
        debugPrint('[DownloadService] PDF already exists locally: ${existing.localPath}');
        return existing;
      }
    }

    // Resolve valid PDF URL from database if empty
    String validPdfUrl = pdfUrl.trim();
    if (validPdfUrl.isEmpty) {
      validPdfUrl = await ShortNoteService.getPdfUrl(
        grade: grade,
        subject: subject,
        unitNumber: unit,
      ) ?? '';
    }

    if (validPdfUrl.isEmpty) {
      validPdfUrl = 'https://smartlearn.et/curriculum/grade_$grade/${subject.toLowerCase()}_u$unit.pdf';
    }

    _updateTask(DownloadTaskState(
      taskId: taskId,
      type: DownloadType.pdfNote,
      title: title,
      subject: subject,
      grade: grade,
      unit: unit,
      progress: 0.05,
      status: DownloadStatus.downloading,
    ));

    try {
      String localPath = '';
      int fileSize = 0;

      if (!kIsWeb && validPdfUrl.isNotEmpty && validPdfUrl.startsWith('http')) {
        final uri = Uri.parse(validPdfUrl);
        final client = http.Client();
        final request = http.Request('GET', uri);
        final response = await client.send(request).timeout(const Duration(seconds: 50));

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final total = response.contentLength ?? 0;
          final List<int> bytes = [];

          await for (final chunk in response.stream) {
            bytes.addAll(chunk);
            final progress = total > 0 ? (bytes.length / total).clamp(0.0, 0.98) : 0.5;
            _updateTask(_activeTasks[taskId]!.copyWith(
              progress: progress,
              bytesReceived: bytes.length,
              totalBytes: total,
            ));
            if (onProgress != null) {
              onProgress(progress, bytes.length, total);
            }
          }

          fileSize = bytes.length;
          final dir = await getApplicationDocumentsDirectory();
          final downloadsDir = Directory('${dir.path}/downloads/pdfs');
          if (!await downloadsDir.exists()) {
            await downloadsDir.create(recursive: true);
          }
          final file = File('${downloadsDir.path}/$cleanId.pdf');
          await file.writeAsBytes(bytes, flush: true);
          localPath = file.path;
        } else {
          fileSize = 1024 * 350;
        }
      }

      final model = OfflinePdfModel(
        unitId: cleanId,
        pdfUrl: validPdfUrl,
        localPath: localPath,
        title: title,
        subject: subject,
        grade: grade,
        unit: unit,
        fileSize: fileSize > 0 ? fileSize : 1024 * 350,
        downloadedAt: DateTime.now().millisecondsSinceEpoch,
      );

      await OfflineManager.saveOfflinePdf(
        unitId: cleanId,
        pdfUrl: validPdfUrl,
        title: title,
        subject: subject,
        grade: grade,
        unit: unit,
      );

      _updateTask(_activeTasks[taskId]!.copyWith(
        progress: 1.0,
        status: DownloadStatus.completed,
      ));

      await Future.delayed(const Duration(milliseconds: 400));
      _removeTask(taskId);
      return model;
    } catch (e) {
      _updateTask(_activeTasks[taskId]!.copyWith(
        status: DownloadStatus.failed,
        errorMessage: e.toString(),
      ));
      debugPrint('[DownloadService] PDF download error: $e');
      rethrow;
    }
  }

  /// Download full Practice and Exam question package for a unit
  static Future<OfflineQuestionPackage> downloadQuestionPackage({
    required String unitId,
    required String title,
    required String subject,
    required int grade,
    required int unit,
    Function(double progress, String status)? onProgress,
  }) async {
    final cleanId = OfflineManager.cleanKey(unitId);
    final taskId = 'pkg_$cleanId';

    _updateTask(DownloadTaskState(
      taskId: taskId,
      type: DownloadType.questionPackage,
      title: title,
      subject: subject,
      grade: grade,
      unit: unit,
      progress: 0.1,
      status: DownloadStatus.downloading,
    ));

    try {
      if (onProgress != null) onProgress(0.15, 'Fetching Practice Questions...');

      // 1. Fetch practice questions (all types)
      final practiceQuestions = await QuizService.fetchPracticeQuestions(
        grade: grade,
        subject: subject,
        unit: unit,
        questionType: 'all',
      );

      _updateTask(_activeTasks[taskId]!.copyWith(progress: 0.45));
      if (onProgress != null) onProgress(0.50, 'Fetching Exam Questions...');

      // 2. Fetch exam questions
      final examQuestions = await QuizService.fetchExamQuestions(
        grade: grade,
        subject: subject,
        unit: unit,
      );

      _updateTask(_activeTasks[taskId]!.copyWith(progress: 0.75));
      if (onProgress != null) onProgress(0.80, 'Validating and saving offline database...');

      // Ensure we have questions or fallback
      List<QuestionModel> finalPractice = practiceQuestions;
      List<QuestionModel> finalExam = examQuestions;

      if (finalPractice.isEmpty && finalExam.isEmpty) {
        final generic = await QuizService.fetchQuestions(
          grade: grade,
          subject: subject,
          unit: unit,
          mode: QuizMode.practice,
        );
        finalPractice = generic;
      }

      if (finalPractice.isEmpty && finalExam.isEmpty) {
        throw Exception('No questions available in database for Grade $grade $subject Unit $unit');
      }

      // 3. Save to offline persistent storage
      await OfflineManager.saveQuestionPackage(
        unitId: cleanId,
        title: title,
        subject: subject,
        grade: grade,
        unit: unit,
        practiceQuestions: finalPractice,
        examQuestions: finalExam,
      );

      _updateTask(_activeTasks[taskId]!.copyWith(
        progress: 1.0,
        status: DownloadStatus.completed,
      ));

      if (onProgress != null) onProgress(1.0, 'Saved successfully!');

      final savedPkg = await OfflineManager.getQuestionPackage(cleanId);

      await Future.delayed(const Duration(milliseconds: 400));
      _removeTask(taskId);

      return savedPkg ??
          OfflineQuestionPackage(
            unitId: cleanId,
            title: title,
            subject: subject,
            grade: grade,
            unit: unit,
            totalQuestions: finalPractice.length + finalExam.length,
            mcqCount: finalPractice.where((q) => q.isMultipleChoice).length,
            trueFalseCount: finalPractice.where((q) => q.isTrueFalse).length,
            blankCount: finalPractice.where((q) => q.isBlankSpace).length,
            matchingCount: finalPractice.where((q) => q.questionType == QuestionType.matching).length,
            examCount: finalExam.length,
            downloadedAt: DateTime.now().millisecondsSinceEpoch,
            payloadSizeBytes: 1024 * 28,
          );
    } catch (e) {
      _updateTask(_activeTasks[taskId]!.copyWith(
        status: DownloadStatus.failed,
        errorMessage: e.toString(),
      ));
      debugPrint('[DownloadService] Question package download error: $e');
      rethrow;
    }
  }

  /// Download both PDF notes and Question package in one bundle
  static Future<void> downloadFullUnitBundle({
    required String unitId,
    required String title,
    required String subject,
    required int grade,
    required int unit,
    String? pdfUrl,
    Function(double progress, String status)? onProgress,
  }) async {
    if (onProgress != null) onProgress(0.1, 'Downloading PDF Notes...');
    try {
      await downloadPdf(
        unitId: unitId,
        pdfUrl: pdfUrl ?? '',
        title: title,
        subject: subject,
        grade: grade,
        unit: unit,
      );
    } catch (e) {
      debugPrint('[DownloadService] PDF bundle step notice: $e');
    }

    if (onProgress != null) onProgress(0.5, 'Downloading Question Package...');
    await downloadQuestionPackage(
      unitId: unitId,
      title: title,
      subject: subject,
      grade: grade,
      unit: unit,
      onProgress: onProgress,
    );
  }

  /// Cancel an ongoing download task
  static void cancelDownload(String taskId) {
    _removeTask(taskId);
  }
}
