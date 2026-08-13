import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'offline_manager.dart';

class PdfCacheService {
  /// Directory for local PDF file storage
  static Future<Directory> _getPdfDirectory() async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final pdfDir = Directory('${docsDir.path}/pdfs');
      if (!await pdfDir.exists()) {
        await pdfDir.create(recursive: true);
        debugPrint('[PDF Cache] Created PDF storage directory at: ${pdfDir.path}');
      }
      return pdfDir;
    } catch (e) {
      debugPrint('[PDF Cache Error] Failed to get/create PDF storage directory: $e');
      rethrow;
    }
  }

  /// Sanitizes unit ID & URL to construct a deterministic local file name
  static String getLocalFileName(String unitId, String pdfUrl) {
    final sanitizedUnit = unitId.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    final uri = Uri.tryParse(pdfUrl);
    String lastSegment = (uri != null && uri.pathSegments.isNotEmpty)
        ? uri.pathSegments.last
        : 'document.pdf';
    
    // Remove query parameters if any
    if (lastSegment.contains('?')) {
      lastSegment = lastSegment.split('?').first;
    }
    
    if (!lastSegment.endsWith('.pdf')) {
      lastSegment = '$lastSegment.pdf';
    }
    return '${sanitizedUnit}_$lastSegment';
  }

  /// Returns the local cached File if it exists and is valid (>0 bytes).
  /// If a 0-byte corrupted file is found, it is automatically purged and removed from OfflineManager.
  static Future<File?> getLocalPdfFile(String unitId, String pdfUrl) async {
    try {
      final pdfDir = await _getPdfDirectory();
      final fileName = getLocalFileName(unitId, pdfUrl);
      final file = File('${pdfDir.path}/$fileName');

      if (await file.exists()) {
        final length = await file.length();
        if (length > 0) {
          debugPrint('[PDF Cache] Found valid local cached PDF at: ${file.path} ($length bytes)');
          return file;
        } else {
          debugPrint('[PDF Cache Error] Found 0-byte corrupted file at ${file.path}. Purging...');
          await file.delete();
          final String cleanUnitId = unitId.replaceAll('_notes', '');
          await OfflineManager.removeDownload(cleanUnitId);
        }
      }
    } catch (e) {
      debugPrint('[PDF Cache Error] Failed to inspect local cached PDF file: $e');
    }
    return null;
  }

  /// Downloads a remote PDF, verifies its contents, saves it locally,
  /// optionally updates OfflineManager, and returns the cached local File.
  static Future<File> downloadAndSavePdf({
    required String unitId,
    required String pdfUrl,
    bool registerOffline = true,
  }) async {
    debugPrint('[PDF Cache] Starting PDF download for unitId: $unitId from URL: $pdfUrl (registerOffline: $registerOffline)');
    
    if (pdfUrl.isEmpty || !pdfUrl.startsWith('http')) {
      final err = 'Invalid or missing PDF URL: "$pdfUrl"';
      debugPrint('[PDF Cache Error] $err');
      throw Exception(err);
    }

    final String cleanUnitId = unitId.replaceAll('_notes', '');
    File? targetFile;

    try {
      final pdfDir = await _getPdfDirectory();
      final fileName = getLocalFileName(unitId, pdfUrl);
      targetFile = File('${pdfDir.path}/$fileName');

      final Uri uri = Uri.parse(pdfUrl);
      final response = await http.get(uri).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          final timeoutErr = 'Network request timed out after 30 seconds while downloading PDF.';
          debugPrint('[PDF Cache Error] $timeoutErr');
          throw Exception(timeoutErr);
        },
      );

      if (response.statusCode != 200) {
        final statusErr = 'Server returned HTTP error code ${response.statusCode}';
        debugPrint('[PDF Cache Error] $statusErr for URL: $pdfUrl');
        throw Exception(statusErr);
      }

      final bytes = response.bodyBytes;
      if (bytes.isEmpty) {
        final emptyErr = 'Received empty response (0 bytes) from server.';
        debugPrint('[PDF Cache Error] $emptyErr');
        throw Exception(emptyErr);
      }

      // Write bytes to local file
      await targetFile.writeAsBytes(bytes, flush: true);

      // Verify file integrity - MUST be > 0 bytes
      final fileLength = await targetFile.length();
      if (fileLength == 0) {
        if (await targetFile.exists()) {
          await targetFile.delete();
        }
        await OfflineManager.removeDownload(cleanUnitId);
        final zeroByteErr = 'File saved locally but verified to be 0 bytes. Removed corrupt file.';
        debugPrint('[PDF Cache Error] $zeroByteErr');
        throw Exception(zeroByteErr);
      }

      // ONLY update OfflineManager tracker after verifying > 0 bytes AND registerOffline is true
      if (registerOffline) {
        await OfflineManager.addDownload(cleanUnitId);
      }
      
      debugPrint('[PDF Cache] Successfully cached PDF ($fileLength bytes) at: ${targetFile.path}');
      return targetFile;
    } catch (e) {
      debugPrint('[PDF Cache Error] Download failed for unit $unitId: $e');
      if (targetFile != null && await targetFile.exists()) {
        try {
          await targetFile.delete();
        } catch (_) {}
      }
      if (registerOffline) {
        try {
          await OfflineManager.removeDownload(cleanUnitId);
        } catch (_) {}
      }
      rethrow;
    }
  }

  /// Checks if a PDF is cached locally
  static Future<bool> isPdfCached(String unitId, String pdfUrl) async {
    final file = await getLocalPdfFile(unitId, pdfUrl);
    return file != null;
  }

  /// Deletes a cached PDF file if present and cleans up OfflineManager
  static Future<void> deleteCachedPdf(String unitId, String pdfUrl) async {
    try {
      final pdfDir = await _getPdfDirectory();
      final fileName = getLocalFileName(unitId, pdfUrl);
      final file = File('${pdfDir.path}/$fileName');
      if (await file.exists()) {
        await file.delete();
        debugPrint('[PDF Cache] Deleted cached PDF: ${file.path}');
      }
      final String cleanUnitId = unitId.replaceAll('_notes', '');
      await OfflineManager.removeDownload(cleanUnitId);
    } catch (e) {
      debugPrint('[PDF Cache Error] Error deleting cached PDF: $e');
    }
  }
}
