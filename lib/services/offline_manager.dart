// ignore_for_file: prefer_conditional_assignment
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/question_model.dart';
import '../models/worksheet_model.dart';
import '../models/video_model.dart';
import '../models/offline_package_model.dart';
import 'device_service.dart';
import 'subscription_service.dart';

class OfflinePdfModel {
  final String unitId;
  final String pdfUrl;
  final String localPath;
  final String title;
  final String subject;
  final int grade;
  final int unit;
  final int fileSize;
  final int downloadedAt;

  OfflinePdfModel({
    required this.unitId,
    required this.pdfUrl,
    required this.localPath,
    required this.title,
    required this.subject,
    required this.grade,
    required this.unit,
    required this.fileSize,
    required this.downloadedAt,
  });

  Map<String, dynamic> toJson() => {
    'unitId': unitId,
    'pdfUrl': pdfUrl,
    'localPath': localPath,
    'title': title,
    'subject': subject,
    'grade': grade,
    'unit': unit,
    'fileSize': fileSize,
    'downloadedAt': downloadedAt,
  };

  factory OfflinePdfModel.fromJson(Map<String, dynamic> json) => OfflinePdfModel(
    unitId: json['unitId'] as String? ?? '',
    pdfUrl: json['pdfUrl'] as String? ?? '',
    localPath: json['localPath'] as String? ?? '',
    title: json['title'] as String? ?? 'Curriculum Short Note PDF',
    subject: json['subject'] as String? ?? '',
    grade: json['grade'] as int? ?? 9,
    unit: json['unit'] as int? ?? 1,
    fileSize: json['fileSize'] as int? ?? 0,
    downloadedAt: json['downloadedAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
  );

  String get formattedSize {
    if (fileSize <= 0) return '0 KB';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class OfflineMetadata {
  final String unitId;
  final int grade;
  final int unit;
  final int downloadedAt;
  final String type; // 'quiz', 'note', or 'worksheet'

  OfflineMetadata({
    required this.unitId,
    this.grade = 9,
    this.unit = 1,
    required this.downloadedAt,
    this.type = 'quiz',
  });

  Map<String, dynamic> toJson() => {
    'unitId': unitId,
    'grade': grade,
    'unit': unit,
    'downloadedAt': downloadedAt,
    'type': type,
  };

  factory OfflineMetadata.fromJson(Map<String, dynamic> json) => OfflineMetadata(
    unitId: json['unitId'] as String? ?? '',
    grade: json['grade'] as int? ?? 9,
    unit: json['unit'] as int? ?? 1,
    downloadedAt: json['downloadedAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    type: json['type'] as String? ?? 'quiz',
  );
}

class OfflineManager {
  static final Set<String> _downloadedUnitIds = {};
  static bool _isLoaded = false;
  static final List<VoidCallback> _listeners = [];

  /// Helper to strip '_notes' suffix for normalized raw unit ID storage
  static String cleanKey(String id) {
    return id.replaceAll('_notes', '').replaceAll('_quiz', '');
  }

  static String _cleanKey(String id) => cleanKey(id);

  static Map<String, int> _parseMetadata(
    String unitId, {
    int? explicitGrade,
    int? explicitUnit,
  }) {
    int grade = explicitGrade ?? 9;
    int unit = explicitUnit ?? 1;

    if (explicitGrade == null) {
      final gradeMatch =
          RegExp(r'grade_?(\d+)', caseSensitive: false).firstMatch(unitId) ??
          RegExp(r'g(\d+)', caseSensitive: false).firstMatch(unitId) ??
          RegExp(r'(\d+)_\w+_u', caseSensitive: false).firstMatch(unitId);
      if (gradeMatch != null) {
        grade = int.tryParse(gradeMatch.group(1) ?? '') ?? grade;
      }
    }

    if (explicitUnit == null) {
      final unitMatch =
          RegExp(r'u(\d+)', caseSensitive: false).firstMatch(unitId) ??
          RegExp(r'unit_?(\d+)', caseSensitive: false).firstMatch(unitId);
      if (unitMatch != null) {
        unit = int.tryParse(unitMatch.group(1) ?? '') ?? unit;
      }
    }

    return {'grade': grade, 'unit': unit};
  }

  static Future<void> syncPendingRegistration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool hasPending = prefs.getBool('has_pending_registration_sync') ?? false;
      if (!hasPending) return;

      final bool hasConn = await isNetworkAvailable();
      if (!hasConn) return;

      final String? payloadStr = prefs.getString('pending_registration_payload');
      if (payloadStr == null || payloadStr.isEmpty) {
        await prefs.setBool('has_pending_registration_sync', false);
        return;
      }

      final Map<String, dynamic> payload = jsonDecode(payloadStr) as Map<String, dynamic>;
      final supabase = Supabase.instance.client;

      bool syncSuccess = false;
      try {
        await supabase.from('profiles').insert(payload);
        syncSuccess = true;
      } catch (e) {
        try {
          await supabase.from('student_profiles').insert({
            'id': payload['id'],
            'full_name': payload['full_name'],
            'phone_number': payload['phone_number'],
            'grade': payload['grade'],
          });
          syncSuccess = true;
        } catch (_) {}
      }

      if (syncSuccess) {
        await prefs.setBool('has_pending_registration_sync', false);
        await prefs.remove('pending_registration_payload');
        debugPrint("[OfflineManager] Pending registration synced successfully to Supabase.");
      }
    } catch (e) {
      debugPrint("[OfflineManager] Pending registration sync error: $e");
    }
  }

  // ==========================================
  // Question Package Storage & Retrieval
  // ==========================================

  /// Save a complete question package with metadata cataloging
  static Future<void> saveQuestionPackage({
    required String unitId,
    required String title,
    required String subject,
    required int grade,
    required int unit,
    required List<QuestionModel> practiceQuestions,
    required List<QuestionModel> examQuestions,
  }) async {
    try {
      final clean = cleanKey(unitId);
      final prefs = await SharedPreferences.getInstance();

      // Filter practice subsets
      final mcqs = practiceQuestions.where((q) => q.isMultipleChoice).toList();
      final tf = practiceQuestions.where((q) => q.isTrueFalse).toList();
      final blanks = practiceQuestions.where((q) => q.isBlankSpace).toList();
      final matching = practiceQuestions.where((q) => q.questionType == QuestionType.matching).toList();

      // Combined practice + exam questions
      final allUniqueQuestions = <String, QuestionModel>{};
      for (final q in practiceQuestions) {
        allUniqueQuestions[q.id] = q;
      }
      for (final q in examQuestions) {
        allUniqueQuestions[q.id] = q;
      }

      // Encode partitions
      final practiceJson = practiceQuestions.map((q) => jsonEncode(q.toJson())).toList();
      final examJson = examQuestions.map((q) => jsonEncode(q.toJson())).toList();
      final mcqJson = mcqs.map((q) => jsonEncode(q.toJson())).toList();
      final tfJson = tf.map((q) => jsonEncode(q.toJson())).toList();
      final blankJson = blanks.map((q) => jsonEncode(q.toJson())).toList();
      final matchingJson = matching.map((q) => jsonEncode(q.toJson())).toList();
      final allJson = allUniqueQuestions.values.map((q) => jsonEncode(q.toJson())).toList();

      await prefs.setStringList('offline_q_${clean}_practice_all', practiceJson);
      await prefs.setStringList('offline_q_${clean}_exam', examJson);
      if (mcqJson.isNotEmpty) await prefs.setStringList('offline_q_${clean}_practice_multiple_choice', mcqJson);
      if (tfJson.isNotEmpty) await prefs.setStringList('offline_q_${clean}_practice_true_false', tfJson);
      if (blankJson.isNotEmpty) await prefs.setStringList('offline_q_${clean}_practice_blank_space', blankJson);
      if (matchingJson.isNotEmpty) await prefs.setStringList('offline_q_${clean}_practice_matching', matchingJson);
      await prefs.setStringList('offline_questions_$clean', allJson);

      // Estimate byte size
      int totalBytes = 0;
      for (final s in allJson) {
        totalBytes += utf8.encode(s).length;
      }

      final packageModel = OfflineQuestionPackage(
        unitId: clean,
        title: title,
        subject: subject,
        grade: grade,
        unit: unit,
        totalQuestions: allUniqueQuestions.length,
        mcqCount: mcqs.length,
        trueFalseCount: tf.length,
        blankCount: blanks.length,
        matchingCount: matching.length,
        examCount: examQuestions.length,
        downloadedAt: DateTime.now().millisecondsSinceEpoch,
        payloadSizeBytes: totalBytes > 0 ? totalBytes : 1024 * 18,
      );

      await prefs.setString('offline_pkg_$clean', jsonEncode(packageModel.toJson()));

      // Add to package catalog
      final List<String> pkgIds = prefs.getStringList('offline_pkg_catalog_ids') ?? [];
      if (!pkgIds.contains(clean)) {
        pkgIds.add(clean);
        await prefs.setStringList('offline_pkg_catalog_ids', pkgIds);
      }

      await addDownload(clean);
      _notifyListeners();
    } catch (e) {
      debugPrint('[OfflineManager] Error saving question package: $e');
    }
  }

  /// Retrieve all offline question packages
  static Future<List<OfflineQuestionPackage>> getAllQuestionPackages() async {
    await init();
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> pkgIds = prefs.getStringList('offline_pkg_catalog_ids') ?? [];
      final List<OfflineQuestionPackage> list = [];

      for (final id in pkgIds) {
        final str = prefs.getString('offline_pkg_$id');
        if (str != null && str.isNotEmpty) {
          try {
            list.add(OfflineQuestionPackage.fromJson(jsonDecode(str) as Map<String, dynamic>));
          } catch (_) {}
        }
      }

      // Check legacy downloaded units
      for (final id in _downloadedUnitIds) {
        if (!pkgIds.contains(id) && !id.endsWith('_pdf')) {
          final genericList = prefs.getStringList('offline_questions_$id');
          if (genericList != null && genericList.isNotEmpty) {
            final parsed = _parseMetadata(id);
            final List<QuestionModel> questions = genericList
                .map((str) => QuestionModel.fromJson(jsonDecode(str) as Map<String, dynamic>))
                .toList();

            final pkg = OfflineQuestionPackage(
              unitId: id,
              title: 'Unit ${parsed['unit']} Question Set',
              subject: 'Curriculum',
              grade: parsed['grade']!,
              unit: parsed['unit']!,
              totalQuestions: questions.length,
              mcqCount: questions.where((q) => q.isMultipleChoice).length,
              trueFalseCount: questions.where((q) => q.isTrueFalse).length,
              blankCount: questions.where((q) => q.isBlankSpace).length,
              matchingCount: questions.where((q) => q.questionType == QuestionType.matching).length,
              examCount: questions.where((q) => q.isMultipleChoice).length,
              downloadedAt: DateTime.now().millisecondsSinceEpoch,
              payloadSizeBytes: genericList.fold(0, (sum, s) => sum + utf8.encode(s).length),
            );
            list.add(pkg);
          }
        }
      }

      list.sort((a, b) => b.downloadedAt.compareTo(a.downloadedAt));
      return list;
    } catch (e) {
      debugPrint('[OfflineManager] getAllQuestionPackages error: $e');
      return [];
    }
  }

  /// Get a single question package metadata
  static Future<OfflineQuestionPackage?> getQuestionPackage(String unitId) async {
    await init();
    final clean = cleanKey(unitId);
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString('offline_pkg_$clean');
      if (str != null && str.isNotEmpty) {
        return OfflineQuestionPackage.fromJson(jsonDecode(str) as Map<String, dynamic>);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Delete a question package
  static Future<void> deleteQuestionPackage(String unitId) async {
    try {
      final clean = cleanKey(unitId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('offline_pkg_$clean');

      final List<String> pkgIds = prefs.getStringList('offline_pkg_catalog_ids') ?? [];
      pkgIds.remove(clean);
      await prefs.setStringList('offline_pkg_catalog_ids', pkgIds);

      // Remove specific question arrays
      await prefs.remove('offline_questions_$clean');
      await prefs.remove('offline_q_${clean}_exam');
      await prefs.remove('offline_q_${clean}_practice_all');
      await prefs.remove('offline_q_${clean}_practice_multiple_choice');
      await prefs.remove('offline_q_${clean}_practice_true_false');
      await prefs.remove('offline_q_${clean}_practice_blank_space');
      await prefs.remove('offline_q_${clean}_practice_matching');

      await removeDownload(clean);
      _notifyListeners();
    } catch (e) {
      debugPrint('[OfflineManager] deleteQuestionPackage error: $e');
    }
  }

  static Future<void> saveOfflineQuestions(
    String unitId,
    List<QuestionModel> questions, {
    int? grade,
    int? unit,
  }) async {
    try {
      final clean = cleanKey(unitId);
      final prefs = await SharedPreferences.getInstance();
      final List<String> jsonList = questions.map((q) => jsonEncode(q.toJson())).toList();
      await prefs.setStringList('offline_questions_$clean', jsonList);
      final parsed = _parseMetadata(clean, explicitGrade: grade, explicitUnit: unit);
      final metadata = OfflineMetadata(
        unitId: clean,
        grade: parsed['grade']!,
        unit: parsed['unit']!,
        downloadedAt: DateTime.now().millisecondsSinceEpoch,
        type: 'quiz',
      );
      await prefs.setString('offline_metadata_$clean', jsonEncode(metadata.toJson()));
      await addDownload(clean);
    } catch (_) {}
  }

  /// Generate an isolated storage key for mode and question type
  static String buildQuestionKey({
    required String unitId,
    required String mode,
    String? questionType,
  }) {
    final clean = cleanKey(unitId);
    if (mode == 'exam') {
      return '${clean}_exam';
    }
    if (questionType != null && questionType.isNotEmpty && questionType != 'all') {
      return '${clean}_practice_$questionType';
    }
    return '${clean}_practice_all';
  }

  /// Save questions separated by mode (practice vs exam) and question type
  static Future<void> saveOfflineQuestionsByMode({
    required String unitId,
    required String mode,
    String? questionType,
    required List<QuestionModel> questions,
    int? grade,
    int? unit,
  }) async {
    try {
      final key = buildQuestionKey(unitId: unitId, mode: mode, questionType: questionType);
      final prefs = await SharedPreferences.getInstance();
      final List<String> jsonList = questions.map((q) => jsonEncode(q.toJson())).toList();
      await prefs.setStringList('offline_q_$key', jsonList);

      await addDownload(key);

      final clean = cleanKey(unitId);
      final hasGeneric = prefs.getStringList('offline_questions_$clean') != null;
      if (!hasGeneric || (mode == 'practice' && (questionType == null || questionType == 'all'))) {
        await saveOfflineQuestions(clean, questions, grade: grade, unit: unit);
      }
    } catch (e) {
      debugPrint('[OfflineManager] Error saving questions by mode: $e');
    }
  }

  /// Retrieve questions separated by mode and question type
  static Future<List<QuestionModel>> getOfflineQuestionsByMode({
    required String unitId,
    required String mode,
    String? questionType,
  }) async {
    await init();
    final key = buildQuestionKey(unitId: unitId, mode: mode, questionType: questionType);
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String>? jsonList = prefs.getStringList('offline_q_$key');

      if ((jsonList == null || jsonList.isEmpty) && mode == 'practice' && questionType != null && questionType != 'all') {
        final allPracticeKey = buildQuestionKey(unitId: unitId, mode: 'practice', questionType: 'all');
        final allList = prefs.getStringList('offline_q_$allPracticeKey');
        if (allList != null && allList.isNotEmpty) {
          final allQuestions = allList
              .map((str) => QuestionModel.fromJson(jsonDecode(str) as Map<String, dynamic>))
              .toList();
          final filtered = allQuestions.where((q) {
            if (questionType == 'multiple_choice') return q.isMultipleChoice;
            if (questionType == 'true_false') return q.isTrueFalse;
            if (questionType == 'blank_space') return q.isBlankSpace;
            if (questionType == 'matching') return q.questionType == QuestionType.matching;
            return true;
          }).toList();
          if (filtered.isNotEmpty) return filtered;
        }
      }

      if (jsonList == null || jsonList.isEmpty) {
        final clean = cleanKey(unitId);
        final generic = await getOfflineQuestions(clean);
        if (generic.isNotEmpty) {
          if (questionType != null && questionType.isNotEmpty && questionType != 'all') {
            final filtered = generic.where((q) {
              if (questionType == 'multiple_choice') return q.isMultipleChoice;
              if (questionType == 'true_false') return q.isTrueFalse;
              if (questionType == 'blank_space') return q.isBlankSpace;
              if (questionType == 'matching') return q.questionType == QuestionType.matching;
              return true;
            }).toList();
            if (filtered.isNotEmpty) return filtered;
          }
          return generic;
        }
      }

      if (jsonList != null && jsonList.isNotEmpty) {
        return jsonList
            .map((str) => QuestionModel.fromJson(jsonDecode(str) as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('[OfflineManager] Error getting questions by mode: $e');
      return [];
    }
  }

  /// Check if questions for specific mode and type are downloaded
  static Future<bool> hasOfflineQuestionsByMode({
    required String unitId,
    required String mode,
    String? questionType,
  }) async {
    await init();
    final key = buildQuestionKey(unitId: unitId, mode: mode, questionType: questionType);
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('offline_q_$key');
      if (list != null && list.isNotEmpty) return true;

      if (mode == 'practice' && questionType != null && questionType != 'all') {
        final allPracticeKey = buildQuestionKey(unitId: unitId, mode: 'practice', questionType: 'all');
        final allList = prefs.getStringList('offline_q_$allPracticeKey');
        if (allList != null && allList.isNotEmpty) {
          return allList.any((str) => str.contains('"type":"$questionType"'));
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // ==========================================
  // Dedicated PDF Offline Storage and Management
  // ==========================================

  static Future<OfflinePdfModel?> downloadAndSavePdfFile({
    required String unitId,
    required String pdfUrl,
    required String title,
    String? subject,
    int? grade,
    int? unit,
    Function(double progress, int received, int total)? onProgress,
  }) async {
    try {
      final clean = cleanKey(unitId);
      String localPath = '';
      int fileSize = 0;

      if (!kIsWeb && pdfUrl.isNotEmpty) {
        final uri = Uri.parse(pdfUrl);
        final client = http.Client();
        final request = http.Request('GET', uri);
        final response = await client.send(request).timeout(const Duration(seconds: 45));

        if (response.statusCode == 200) {
          final contentLength = response.contentLength ?? 0;
          final List<int> bytes = [];

          await for (final chunk in response.stream) {
            bytes.addAll(chunk);
            if (contentLength > 0 && onProgress != null) {
              onProgress(bytes.length / contentLength, bytes.length, contentLength);
            }
          }

          fileSize = bytes.length;
          final dir = await getApplicationDocumentsDirectory();
          final downloadsDir = Directory('${dir.path}/downloads');
          if (!await downloadsDir.exists()) {
            await downloadsDir.create(recursive: true);
          }
          final file = File('${downloadsDir.path}/$clean.pdf');
          await file.writeAsBytes(bytes, flush: true);
          localPath = file.path;
        } else {
          throw Exception('Download failed with HTTP status ${response.statusCode}');
        }
      }

      final model = OfflinePdfModel(
        unitId: clean,
        pdfUrl: pdfUrl,
        localPath: localPath,
        title: title,
        subject: subject ?? 'General',
        grade: grade ?? 9,
        unit: unit ?? 1,
        fileSize: fileSize > 0 ? fileSize : 1024 * 350,
        downloadedAt: DateTime.now().millisecondsSinceEpoch,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('offline_pdf_$clean', jsonEncode(model.toJson()));

      final List<String> ids = prefs.getStringList('offline_pdf_catalog_ids') ?? [];
      if (!ids.contains(clean)) {
        ids.add(clean);
        await prefs.setStringList('offline_pdf_catalog_ids', ids);
      }

      await addDownload('${clean}_pdf');
      await addDownload(clean);
      _notifyListeners();
      return model;
    } catch (e) {
      debugPrint('[OfflineManager] downloadAndSavePdfFile error: $e');
      rethrow;
    }
  }

  static Future<void> saveOfflinePdf({
    required String unitId,
    required String pdfUrl,
    String? title,
    String? summary,
    int? grade,
    int? unit,
    String? subject,
  }) async {
    await downloadAndSavePdfFile(
      unitId: unitId,
      pdfUrl: pdfUrl,
      title: title ?? 'Curriculum Short Note PDF',
      subject: subject,
      grade: grade,
      unit: unit,
    );
  }

  static Future<OfflinePdfModel?> getOfflinePdfModel(String unitId) async {
    await init();
    final clean = cleanKey(unitId);
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString('offline_pdf_$clean');
      if (str != null && str.isNotEmpty) {
        return OfflinePdfModel.fromJson(jsonDecode(str) as Map<String, dynamic>);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<List<OfflinePdfModel>> getAllOfflinePdfs() async {
    await init();
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> ids = prefs.getStringList('offline_pdf_catalog_ids') ?? [];
      final List<OfflinePdfModel> list = [];
      for (final id in ids) {
        final str = prefs.getString('offline_pdf_$id');
        if (str != null && str.isNotEmpty) {
          try {
            final model = OfflinePdfModel.fromJson(jsonDecode(str) as Map<String, dynamic>);
            list.add(model);
          } catch (_) {}
        }
      }
      list.sort((a, b) => b.downloadedAt.compareTo(a.downloadedAt));
      return list;
    } catch (e) {
      debugPrint('[OfflineManager] getAllOfflinePdfs error: $e');
      return [];
    }
  }

  static Future<void> deleteOfflinePdf(String unitId) async {
    try {
      final clean = cleanKey(unitId);
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString('offline_pdf_$clean');
      if (str != null) {
        try {
          final data = jsonDecode(str) as Map<String, dynamic>;
          final localPath = data['localPath']?.toString() ?? '';
          if (localPath.isNotEmpty && !kIsWeb) {
            final file = File(localPath);
            if (await file.exists()) {
              await file.delete();
            }
          }
        } catch (_) {}
      }
      await prefs.remove('offline_pdf_$clean');
      final List<String> ids = prefs.getStringList('offline_pdf_catalog_ids') ?? [];
      ids.remove(clean);
      await prefs.setStringList('offline_pdf_catalog_ids', ids);
      await removeDownload('${clean}_pdf');
      await removeDownload(clean);
      _notifyListeners();
    } catch (e) {
      debugPrint('[OfflineManager] deleteOfflinePdf error: $e');
    }
  }

  static Future<bool> hasOfflinePdf(String unitId) async {
    await init();
    final clean = cleanKey(unitId);
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey('offline_pdf_$clean');
    } catch (_) {
      return false;
    }
  }

  static Future<List<QuestionModel>> getOfflineQuestions(String unitId) async {
    await init();
    final bool tamperOk = await DeviceService.verifyOfflineTamperIntegrity();
    if (!tamperOk) return [];
    if (await isExpired(unitId)) {
      debugPrint('[OfflineManager] Offline questions for $unitId is expired. Access blocked.');
      return [];
    }
    final clean = cleanKey(unitId);
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? jsonList = prefs.getStringList('offline_questions_$clean');
      if (jsonList == null || jsonList.isEmpty) return [];
      return jsonList.map((str) => QuestionModel.fromJson(jsonDecode(str) as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveOfflineNotes(
    String unitId,
    List<Map<String, dynamic>> notes, {
    int? grade,
    int? unit,
  }) async {
    try {
      final cleanId = cleanKey(unitId);
      final prefs = await SharedPreferences.getInstance();
      final List<String> jsonList = notes.map((n) => jsonEncode(n)).toList();
      await prefs.setStringList('offline_notes_$cleanId', jsonList);

      final parsed = _parseMetadata(cleanId, explicitGrade: grade, explicitUnit: unit);
      final metadata = OfflineMetadata(
        unitId: cleanId,
        grade: parsed['grade']!,
        unit: parsed['unit']!,
        downloadedAt: DateTime.now().millisecondsSinceEpoch,
        type: 'note',
      );
      await prefs.setString('offline_metadata_$cleanId', jsonEncode(metadata.toJson()));
      await addDownload(cleanId);
    } catch (_) {}
  }

  static Future<List<Map<String, dynamic>>> getOfflineNotes(String unitId) async {
    await init();
    final bool tamperOk = await DeviceService.verifyOfflineTamperIntegrity();
    if (!tamperOk) return [];
    if (await isExpired(unitId)) {
      debugPrint('[OfflineManager] Offline notes for $unitId is expired. Access blocked.');
      return [];
    }
    final cleanId = cleanKey(unitId);
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String>? jsonList = prefs.getStringList('offline_notes_$cleanId');
      if (jsonList == null || jsonList.isEmpty) {
        jsonList = prefs.getStringList('offline_notes_${cleanId}_notes');
      }

      if (jsonList == null || jsonList.isEmpty) {
        return [];
      }
      return jsonList.map((str) => Map<String, dynamic>.from(jsonDecode(str) as Map)).toList();
    } catch (e) {
      debugPrint('[OfflineManager] Error reading offline notes for $unitId: $e');
      return [];
    }
  }

  static Future<void> saveOfflineWorksheets(
    String unitId,
    List<WorksheetModel> worksheets, {
    int? grade,
    int? unit,
  }) async {
    try {
      final cleanId = cleanKey(unitId);
      final prefs = await SharedPreferences.getInstance();
      final List<String> jsonList =
          worksheets.map((w) => jsonEncode(w.toJson())).toList();
      await prefs.setStringList('offline_worksheets_$cleanId', jsonList);

      final parsed = _parseMetadata(cleanId, explicitGrade: grade, explicitUnit: unit);
      final metadata = OfflineMetadata(
        unitId: cleanId,
        grade: parsed['grade']!,
        unit: parsed['unit']!,
        downloadedAt: DateTime.now().millisecondsSinceEpoch,
        type: 'worksheet',
      );
      await prefs.setString(
          'offline_metadata_$cleanId', jsonEncode(metadata.toJson()));
      await addDownload(cleanId);
    } catch (e) {
      debugPrint('[OfflineManager] Error saving offline worksheets: $e');
    }
  }

  static Future<List<WorksheetModel>> getOfflineWorksheets(String unitId) async {
    await init();
    final bool tamperOk = await DeviceService.verifyOfflineTamperIntegrity();
    if (!tamperOk) return [];
    if (await isExpired(unitId)) {
      debugPrint('[OfflineManager] Offline worksheets for $unitId is expired. Access blocked.');
      return [];
    }
    final cleanId = cleanKey(unitId);
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? jsonList =
          prefs.getStringList('offline_worksheets_$cleanId');
      if (jsonList == null || jsonList.isEmpty) return [];
      return jsonList
          .map((str) =>
              WorksheetModel.fromJson(jsonDecode(str) as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[OfflineManager] Error loading offline worksheets: $e');
      return [];
    }
  }

  static Future<bool> hasOfflineWorksheets(String unitId) async {
    await init();
    final cleanId = cleanKey(unitId);
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? jsonList =
          prefs.getStringList('offline_worksheets_$cleanId');
      return jsonList != null && jsonList.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> hasOfflineQuestions(String unitId) async {
    await init();
    final cleanId = cleanKey(unitId);
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? jsonList = prefs.getStringList('offline_questions_$cleanId');
      return jsonList != null && jsonList.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future<OfflineMetadata?> getOfflineMetadata(String unitId) async {
    await init();
    final cleanId = cleanKey(unitId);
    try {
      final prefs = await SharedPreferences.getInstance();
      String? metadataStr = prefs.getString('offline_metadata_$cleanId');
      if (metadataStr == null) {
        metadataStr = prefs.getString('offline_metadata_${cleanId}_notes');
      }
      if (metadataStr == null) {
        final hasNotes = prefs.getStringList('offline_notes_$cleanId') != null ||
            prefs.getStringList('offline_notes_${cleanId}_notes') != null;
        if (hasNotes) {
          final parsed = _parseMetadata(cleanId);
          return OfflineMetadata(
            unitId: cleanId,
            grade: parsed['grade']!,
            unit: parsed['unit']!,
            downloadedAt: DateTime.now().millisecondsSinceEpoch,
            type: 'note',
          );
        }
        return null;
      }
      final decoded = jsonDecode(metadataStr) as Map<String, dynamic>;
      if (!decoded.containsKey('type')) {
        final hasNotes = prefs.getStringList('offline_notes_$cleanId') != null ||
            prefs.getStringList('offline_notes_${cleanId}_notes') != null;
        decoded['type'] = hasNotes ? 'note' : 'quiz';
      }
      return OfflineMetadata.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  static Future<void> init() async {
    if (_isLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('downloaded_unit_ids');
      if (list != null) {
        _downloadedUnitIds.clear();
        for (final item in list) {
          _downloadedUnitIds.add(cleanKey(item));
        }
      }
      _isLoaded = true;
      await syncPendingRegistration();
    } catch (e) {
      _isLoaded = true;
    }
  }

  static Future<bool> isExpired(String unitId) async {
    final meta = _parseMetadata(unitId);
    final unitNum = meta['unit'] ?? 1;
    // Unit 1 is always 100% free trial (never expires)
    if (unitNum <= 1) return false;

    // Check if subscription or time limit set in database has expired
    final bool subExpired = await SubscriptionService.isSubscriptionExpired();
    if (subExpired) {
      return true;
    }

    return false;
  }

  static Future<Set<String>> getDownloadedUnitIds() async {
    await init();
    return _downloadedUnitIds.map((id) => cleanKey(id)).toSet();
  }

  static bool isDownloadedSync(String id) {
    final cleanId = cleanKey(id);
    return _downloadedUnitIds.contains(cleanId) || _downloadedUnitIds.contains('${cleanId}_notes');
  }

  static Future<bool> isDownloaded(String id) async {
    await init();
    final cleanId = cleanKey(id);
    return _downloadedUnitIds.contains(cleanId) || _downloadedUnitIds.contains('${cleanId}_notes');
  }

  static Future<void> addDownload(String id) async {
    await init();
    final cleanId = cleanKey(id);
    _downloadedUnitIds.remove('${cleanId}_notes');
    _downloadedUnitIds.add(cleanId);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('downloaded_unit_ids', _downloadedUnitIds.toList());
    } catch (_) {}
    _notifyListeners();
  }

  static Future<void> removeDownload(String id) async {
    await init();
    final cleanId = cleanKey(id);
    _downloadedUnitIds.remove(cleanId);
    _downloadedUnitIds.remove('${cleanId}_notes');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('downloaded_unit_ids', _downloadedUnitIds.toList());
    } catch (_) {}
    _notifyListeners();
  }

  static void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  static void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  static void _notifyListeners() {
    for (final listener in _listeners) {
      try {
        listener();
      } catch (_) {}
    }
  }

  static Future<bool> isNetworkAvailable() async {
    try {
      final List<ConnectivityResult> results = await Connectivity().checkConnectivity();
      return !results.contains(ConnectivityResult.none);
    } catch (e) {
      debugPrint('Connectivity check error: $e');
      return true;
    }
  }

  /// Total storage usage calculation
  static Future<Map<String, int>> getStorageUsageBytes() async {
    final pdfs = await getAllOfflinePdfs();
    final pkgs = await getAllQuestionPackages();

    final int pdfBytes = pdfs.fold(0, (sum, p) => sum + p.fileSize);
    final int pkgBytes = pkgs.fold(0, (sum, p) => sum + p.payloadSizeBytes);

    return {
      'pdfBytes': pdfBytes,
      'questionBytes': pkgBytes,
      'totalBytes': pdfBytes + pkgBytes,
    };
  }

  /// Delete all downloads
  static Future<void> deleteAllDownloads() async {
    try {
      final pdfs = await getAllOfflinePdfs();
      for (final pdf in pdfs) {
        await deleteOfflinePdf(pdf.unitId);
      }
      final pkgs = await getAllQuestionPackages();
      for (final pkg in pkgs) {
        await deleteQuestionPackage(pkg.unitId);
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('downloaded_unit_ids');
      await prefs.remove('offline_pdf_catalog_ids');
      await prefs.remove('offline_pkg_catalog_ids');
      _downloadedUnitIds.clear();
      _notifyListeners();
    } catch (e) {
      debugPrint('[OfflineManager] deleteAllDownloads error: $e');
    }
  }

  /// Offline Video Storage and Retrieval
  static Future<void> saveOfflineVideo(VideoModel video) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonStr = jsonEncode(video.toJson());
      await prefs.setString('offline_video_${video.id}', jsonStr);

      final List<String> list = prefs.getStringList('offline_video_ids') ?? [];
      if (!list.contains(video.id)) {
        list.add(video.id);
        await prefs.setStringList('offline_video_ids', list);
      }
      _notifyListeners();
    } catch (e) {
      debugPrint('Error saving offline video: $e');
    }
  }

  static Future<bool> isOfflineVideoDownloaded(String videoId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> list = prefs.getStringList('offline_video_ids') ?? [];
      return list.contains(videoId) && prefs.containsKey('offline_video_$videoId');
    } catch (_) {
      return false;
    }
  }

  static Future<void> removeOfflineVideo(String videoId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('offline_video_$videoId');
      final List<String> list = prefs.getStringList('offline_video_ids') ?? [];
      list.remove(videoId);
      await prefs.setStringList('offline_video_ids', list);
      _notifyListeners();
    } catch (_) {}
  }

  static Future<List<VideoModel>> getOfflineVideos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> ids = prefs.getStringList('offline_video_ids') ?? [];
      final List<VideoModel> videos = [];
      for (final id in ids) {
        final str = prefs.getString('offline_video_$id');
        if (str != null && str.isNotEmpty) {
          try {
            videos.add(VideoModel.fromJson(jsonDecode(str) as Map<String, dynamic>));
          } catch (_) {}
        }
      }
      return videos;
    } catch (_) {
      return [];
    }
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _downloadedUnitIds.clear();
    _isLoaded = false;
    _notifyListeners();
  }
}
