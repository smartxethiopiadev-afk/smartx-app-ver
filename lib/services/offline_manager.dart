// ignore_for_file: prefer_conditional_assignment
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/question_model.dart';
import '../models/worksheet_model.dart';
import '../models/video_model.dart';
import 'device_service.dart';

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
  static String _cleanKey(String id) {
    return id.replaceAll('_notes', '');
  }

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

  static Future<void> saveOfflineQuestions(
    String unitId,
    List<QuestionModel> questions, {
    int? grade,
    int? unit,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> jsonList = questions.map((q) => jsonEncode(q.toJson())).toList();
      await prefs.setStringList('offline_questions_$unitId', jsonList);
      final parsed = _parseMetadata(unitId, explicitGrade: grade, explicitUnit: unit);
      final metadata = OfflineMetadata(
        unitId: unitId,
        grade: parsed['grade']!,
        unit: parsed['unit']!,
        downloadedAt: DateTime.now().millisecondsSinceEpoch,
        type: 'quiz',
      );
      await prefs.setString('offline_metadata_$unitId', jsonEncode(metadata.toJson()));
    } catch (_) {}
  }

  /// Generate an isolated storage key for mode and question type
  static String buildQuestionKey({
    required String unitId,
    required String mode,
    String? questionType,
  }) {
    final clean = _cleanKey(unitId);
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

      final clean = _cleanKey(unitId);
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
      // 1. Check exact key
      List<String>? jsonList = prefs.getStringList('offline_q_$key');

      // 2. If looking for specific practice type, check if practice_all has it
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

      // 3. Fallback to generic questions for this unit
      if (jsonList == null || jsonList.isEmpty) {
        final clean = _cleanKey(unitId);
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

  /// Dedicated PDF Offline Storage and Management
  static Future<void> saveOfflinePdf({
    required String unitId,
    required String pdfUrl,
    String? title,
    String? summary,
    int? grade,
    int? unit,
  }) async {
    try {
      final clean = _cleanKey(unitId);
      final prefs = await SharedPreferences.getInstance();
      final pdfData = {
        'unitId': clean,
        'pdfUrl': pdfUrl,
        'title': title ?? 'Curriculum Short Note PDF',
        'summary': summary ?? '',
        'grade': grade ?? 9,
        'unit': unit ?? 1,
        'downloadedAt': DateTime.now().millisecondsSinceEpoch,
        'isOfflineAvailable': true,
      };
      await prefs.setString('offline_pdf_$clean', jsonEncode(pdfData));
      await addDownload('${clean}_pdf');
      await addDownload(clean);
    } catch (e) {
      debugPrint('[OfflineManager] Error saving offline PDF: $e');
    }
  }

  static Future<Map<String, dynamic>?> getOfflinePdf(String unitId) async {
    await init();
    final clean = _cleanKey(unitId);
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString('offline_pdf_$clean');
      if (str != null && str.isNotEmpty) {
        return Map<String, dynamic>.from(jsonDecode(str) as Map);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> hasOfflinePdf(String unitId) async {
    await init();
    final clean = _cleanKey(unitId);
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
    await checkExpirationAndPrune(unitId);
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? jsonList = prefs.getStringList('offline_questions_$unitId');
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
      final cleanId = _cleanKey(unitId);
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
    } catch (_) {}
  }

  static Future<List<Map<String, dynamic>>> getOfflineNotes(String unitId) async {
    await init();
    final bool tamperOk = await DeviceService.verifyOfflineTamperIntegrity();
    if (!tamperOk) return [];
    final cleanId = _cleanKey(unitId);
    await checkExpirationAndPrune(cleanId);
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String>? jsonList = prefs.getStringList('offline_notes_$cleanId');
      if (jsonList == null || jsonList.isEmpty) {
        // Fallback for legacy key format
        jsonList = prefs.getStringList('offline_notes_${cleanId}_notes');
      }

      if (jsonList == null || jsonList.isEmpty) {
        if (_downloadedUnitIds.contains(cleanId) || _downloadedUnitIds.contains('${cleanId}_notes')) {
          await removeDownload(cleanId);
        }
        return [];
      }
      return jsonList.map((str) => Map<String, dynamic>.from(jsonDecode(str) as Map)).toList();
    } catch (e) {
      debugPrint('[OfflineManager] Error reading offline notes for $unitId: $e');
      if (_downloadedUnitIds.contains(cleanId) || _downloadedUnitIds.contains('${cleanId}_notes')) {
        await removeDownload(cleanId);
      }
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
      final cleanId = _cleanKey(unitId);
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
    final cleanId = _cleanKey(unitId);
    await checkExpirationAndPrune(cleanId);
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
    final cleanId = _cleanKey(unitId);
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
    final cleanId = _cleanKey(unitId);
    await checkExpirationAndPrune(cleanId);
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
    final cleanId = _cleanKey(unitId);
    await checkExpirationAndPrune(cleanId);
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
          _downloadedUnitIds.add(_cleanKey(item));
        }
      }
      _isLoaded = true;
      
      // Auto-prune expired downloads upon init
      await checkAndPruneExpiredDownloads();
      
      // Auto-sync pending registration if network is available
      await syncPendingRegistration();
    } catch (e) {
      // In case of any error, we keep operating in-memory
      _isLoaded = true;
    }
  }

  static Future<void> checkAndPruneExpiredDownloads() async {
    final ids = _downloadedUnitIds.toList();
    for (final unitId in ids) {
      await checkExpirationAndPrune(unitId);
    }
  }

  static Future<bool> isExpired(String unitId) async {
    // Offline downloads do not expire so they can be explored/used anytime
    return false;
  }

  static Future<void> checkExpirationAndPrune(String unitId) async {
    if (await isExpired(unitId)) {
      final prefs = await SharedPreferences.getInstance();
      await _deleteOfflineDataForUnit(prefs, unitId);
      if (_downloadedUnitIds.contains(unitId)) {
        _downloadedUnitIds.remove(unitId);
        await prefs.setStringList('downloaded_unit_ids', _downloadedUnitIds.toList());
        _notifyListeners();
      }
    }
  }

  static Future<void> _deleteOfflineDataForUnit(SharedPreferences prefs, String unitId) async {
    await prefs.remove('offline_questions_$unitId');
    await prefs.remove('offline_notes_$unitId');
    await prefs.remove('offline_pdf_$unitId');
    await prefs.remove('offline_worksheets_$unitId');
    await prefs.remove('offline_metadata_$unitId');
    // Also remove mode-specific keys
    for (final key in [
      'offline_q_${unitId}_exam',
      'offline_q_${unitId}_practice_all',
      'offline_q_${unitId}_practice_multiple_choice',
      'offline_q_${unitId}_practice_true_false',
      'offline_q_${unitId}_practice_blank_space',
      'offline_q_${unitId}_practice_matching',
    ]) {
      await prefs.remove(key);
    }
    // Also remove legacy keys if present
    await prefs.remove('offline_questions_${unitId}_notes');
    await prefs.remove('offline_notes_${unitId}_notes');
    await prefs.remove('offline_worksheets_${unitId}_notes');
    await prefs.remove('offline_metadata_${unitId}_notes');
  }

  static Future<Set<String>> getDownloadedUnitIds() async {
    await init();
    return _downloadedUnitIds.map((id) => _cleanKey(id)).toSet();
  }

  static bool isDownloadedSync(String id) {
    final cleanId = _cleanKey(id);
    return _downloadedUnitIds.contains(cleanId) || _downloadedUnitIds.contains('${cleanId}_notes');
  }

  static Future<bool> isDownloaded(String id) async {
    await init();
    final cleanId = _cleanKey(id);
    await checkExpirationAndPrune(cleanId);
    return _downloadedUnitIds.contains(cleanId) || _downloadedUnitIds.contains('${cleanId}_notes');
  }

  static Future<void> addDownload(String id) async {
    await init();
    final cleanId = _cleanKey(id);
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
    final cleanId = _cleanKey(id);
    _downloadedUnitIds.remove(cleanId);
    _downloadedUnitIds.remove('${cleanId}_notes');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('downloaded_unit_ids', _downloadedUnitIds.toList());
      await _deleteOfflineDataForUnit(prefs, cleanId);
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
