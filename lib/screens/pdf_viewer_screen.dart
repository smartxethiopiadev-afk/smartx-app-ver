import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';
import '../services/offline_manager.dart';
import '../services/short_note_service.dart';

/// Ultra High-Resolution In-App PDF Viewer Screen with complete Dark Mode,
/// Invert Colors toggle, page navigation, and offline caching support.
class PdfViewerScreen extends StatefulWidget {
  final String pdfUrl;
  final String title;
  final String? subject;
  final int? grade;
  final int? unitNumber;
  final String? localFilePath;

  const PdfViewerScreen({
    super.key,
    required this.pdfUrl,
    required this.title,
    this.subject,
    this.grade,
    this.unitNumber,
    this.localFilePath,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  String? _localPath;
  String _effectivePdfUrl = '';
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  int _totalPages = 0;
  int _currentPage = 0;
  bool _isReady = false;
  bool _swipeHorizontal = false;
  bool _isNightMode = false;
  bool _nightModeExplicitlySet = false;
  bool _isSavingOffline = false;
  bool _isDownloaded = false;

  PDFViewController? _pdfViewController;

  @override
  void initState() {
    super.initState();
    _effectivePdfUrl = widget.pdfUrl;
    _checkOfflineStatus();
    _loadPdf();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_nightModeExplicitlySet) {
      final isDark = AppStateProvider.of(context).isDarkMode;
      _isNightMode = isDark;
    }
  }

  String get _cleanUnitId {
    final grade = widget.grade ?? 9;
    final sub = (widget.subject ?? 'general').toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
    final unit = widget.unitNumber ?? 1;
    return 'g${grade}_${sub}_u$unit';
  }

  Future<void> _checkOfflineStatus() async {
    final hasOffline = await OfflineManager.hasOfflinePdf(_cleanUnitId);
    if (mounted) {
      setState(() {
        _isDownloaded = hasOffline;
      });
    }
  }

  Future<void> _loadPdf() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      // 1. Check if localFilePath was provided and exists (e.g. from Downloads Hub)
      if (widget.localFilePath != null && widget.localFilePath!.isNotEmpty) {
        final file = File(widget.localFilePath!);
        if (await file.exists()) {
          if (mounted) {
            setState(() {
              _localPath = file.path;
              _isDownloaded = true;
              _isLoading = false;
            });
          }
          return;
        }
      }

      // 2. Check if already stored in OfflineManager
      final offlineModel = await OfflineManager.getOfflinePdfModel(_cleanUnitId);
      if (offlineModel != null && offlineModel.localPath.isNotEmpty) {
        final cachedFile = File(offlineModel.localPath);
        if (await cachedFile.exists()) {
          if (mounted) {
            setState(() {
              _localPath = cachedFile.path;
              _isDownloaded = true;
              _isLoading = false;
            });
          }
          return;
        }
      }

      // 3. Resolve PDF URL (if not passed, query ShortNoteService)
      String url = _effectivePdfUrl.trim();
      if (url.isEmpty && widget.grade != null && widget.subject != null && widget.unitNumber != null) {
        final fetched = await ShortNoteService.getPdfUrl(
          grade: widget.grade!,
          subject: widget.subject!,
          unitNumber: widget.unitNumber!,
        );
        if (fetched != null && fetched.isNotEmpty) {
          url = fetched.trim();
          _effectivePdfUrl = url;
        }
      }

      if (url.isEmpty) {
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = 'PDF link not available for this unit.';
            _isLoading = false;
          });
        }
        return;
      }

      // 4. Web platform handling
      if (kIsWeb) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      // 5. Download and cache PDF to secure local device storage
      final uri = Uri.parse(url);
      final response = await http.get(uri).timeout(const Duration(seconds: 40));

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final dir = await getApplicationDocumentsDirectory();
        final downloadsDir = Directory('${dir.path}/downloads');
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }

        final file = File('${downloadsDir.path}/$_cleanUnitId.pdf');
        await file.writeAsBytes(bytes, flush: true);

        // Record in offline manager catalog
        await OfflineManager.saveOfflinePdf(
          unitId: _cleanUnitId,
          pdfUrl: url,
          title: widget.title,
          subject: widget.subject,
          grade: widget.grade,
          unit: widget.unitNumber,
        );

        if (mounted) {
          setState(() {
            _localPath = file.path;
            _isDownloaded = true;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[PdfViewerScreen] Error loading PDF: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Unable to load PDF document. Please check your internet connection and try again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveToDownloads() async {
    if (_isSavingOffline || _effectivePdfUrl.isEmpty) return;
    setState(() => _isSavingOffline = true);

    try {
      await OfflineManager.downloadAndSavePdfFile(
        unitId: _cleanUnitId,
        pdfUrl: _effectivePdfUrl,
        title: widget.title,
        subject: widget.subject,
        grade: widget.grade,
        unit: widget.unitNumber,
      );

      if (mounted) {
        setState(() {
          _isSavingOffline = false;
          _isDownloaded = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Saved to Downloads Hub! (Available Offline)',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSavingOffline = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save download: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _jumpToPageDialog() {
    if (_totalPages <= 1) return;
    final controller = TextEditingController(text: '${_currentPage + 1}');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Jump to Page',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Page Number (1 - $_totalPages)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(controller.text.trim());
              if (val != null && val >= 1 && val <= _totalPages) {
                _pdfViewController?.setPage(val - 1);
                Navigator.of(ctx).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
            ),
            child: const Text('Go'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appConfig = AppStateProvider.of(context);
    final isDark = appConfig.isDarkMode;

    // Dark Mode background enforces #121212 for ultra-clean contrast
    final Color bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC);
    final Color cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final Color subTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: cardBg,
        iconTheme: IconThemeData(color: textColor),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            if (widget.subject != null && widget.subject!.isNotEmpty)
              Text(
                widget.subject!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2563EB),
                ),
              ),
          ],
        ),
        actions: [
          // Dark Mode / Invert PDF Colors Toggle
          IconButton(
            tooltip: _isNightMode ? 'Normal Colors' : 'Dark Mode / Invert Colors',
            icon: Icon(
              _isNightMode ? Icons.nightlight_round : Icons.wb_sunny_rounded,
              color: _isNightMode ? const Color(0xFFFBBF24) : textColor,
            ),
            onPressed: () {
              setState(() {
                _nightModeExplicitlySet = true;
                _isNightMode = !_isNightMode;
              });
            },
          ),

          // Horizontal / Vertical Layout Toggle
          if (_isReady && _totalPages > 0 && !kIsWeb)
            IconButton(
              tooltip: _swipeHorizontal ? 'Vertical View' : 'Horizontal View',
              icon: Icon(
                _swipeHorizontal ? Icons.swap_vert_rounded : Icons.swap_horiz_rounded,
                color: textColor,
              ),
              onPressed: () {
                setState(() {
                  _swipeHorizontal = !_swipeHorizontal;
                });
              },
            ),

          // Download / Offline Hub Save Button
          if (!kIsWeb)
            IconButton(
              tooltip: _isDownloaded ? 'Downloaded (Offline)' : 'Save Offline',
              icon: _isSavingOffline
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      _isDownloaded ? Icons.cloud_done_rounded : Icons.download_rounded,
                      color: _isDownloaded ? const Color(0xFF10B981) : textColor,
                    ),
              onPressed: _isDownloaded ? null : _saveToDownloads,
            ),

          // Share Link
          IconButton(
            tooltip: 'Share',
            icon: Icon(Icons.share_rounded, color: textColor),
            onPressed: () {
              if (_effectivePdfUrl.isNotEmpty) {
                Share.share('📚 ${widget.title} - ${widget.subject ?? ""}\n$_effectivePdfUrl');
              }
            },
          ),
        ],
      ),
      body: _buildBody(bgColor, cardBg, textColor, subTextColor),
      // Bottom Navigation Toolbar for Page Stepping
      bottomNavigationBar: (_isReady && _totalPages > 0 && !kIsWeb)
          ? _buildBottomToolbar(cardBg, textColor, subTextColor)
          : null,
    );
  }

  Widget _buildBottomToolbar(Color cardBg, Color textColor, Color subTextColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cardBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Previous Page Button
            ElevatedButton.icon(
              onPressed: _currentPage > 0
                  ? () => _pdfViewController?.setPage(_currentPage - 1)
                  : null,
              icon: const Icon(Icons.chevron_left_rounded, size: 20),
              label: const Text('Prev'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),

            // Page Indicator & Jump To Page trigger
            GestureDetector(
              onTap: _jumpToPageDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Page ${_currentPage + 1} of $_totalPages',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.edit_note_rounded, size: 16, color: Color(0xFF2563EB)),
                  ],
                ),
              ),
            ),

            // Next Page Button
            ElevatedButton.icon(
              onPressed: _currentPage < _totalPages - 1
                  ? () => _pdfViewController?.setPage(_currentPage + 1)
                  : null,
              icon: const Icon(Icons.chevron_right_rounded, size: 20),
              label: const Text('Next'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(Color bgColor, Color cardBg, Color textColor, Color subTextColor) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
            ),
            const SizedBox(height: 20),
            Text(
              'Rendering High-Quality PDF...',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Preparing pages & high DPI rendering',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: subTextColor,
              ),
            ),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF2F2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.picture_as_pdf_rounded,
                  size: 48,
                  color: Color(0xFFEF4444),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'PDF Note Unavailable',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: subTextColor,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadPdf,
                icon: const Icon(Icons.refresh_rounded, size: 18, color: Colors.white),
                label: Text(
                  'Try Again',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (kIsWeb) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.picture_as_pdf_rounded,
                size: 64,
                color: Color(0xFF2563EB),
              ),
              const SizedBox(height: 16),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Open this PDF note directly in your browser.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: subTextColor),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  final uri = Uri.parse(_effectivePdfUrl);
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
                icon: const Icon(Icons.open_in_new_rounded, color: Colors.white),
                label: Text(
                  'Open PDF in Browser',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_localPath == null) {
      return const SizedBox.shrink();
    }

    return Container(
      color: bgColor,
      child: Stack(
        children: [
          PDFView(
            filePath: _localPath,
            enableSwipe: true,
            swipeHorizontal: _swipeHorizontal,
            autoSpacing: true,
            pageFling: true,
            pageSnap: true,
            defaultPage: _currentPage,
            fitPolicy: FitPolicy.BOTH,
            nightMode: _isNightMode,
            preventLinkNavigation: false,
            onRender: (pages) {
              if (mounted) {
                setState(() {
                  _totalPages = pages ?? 0;
                  _isReady = true;
                });
              }
            },
            onError: (error) {
              if (mounted) {
                setState(() {
                  _hasError = true;
                  _errorMessage = error.toString();
                });
              }
            },
            onPageError: (page, error) {
              debugPrint('[PdfViewerScreen] Page $page error: $error');
            },
            onViewCreated: (PDFViewController pdfViewController) {
              _pdfViewController = pdfViewController;
            },
            onPageChanged: (int? page, int? total) {
              if (page != null && mounted) {
                setState(() {
                  _currentPage = page;
                });
              }
            },
          ),
          if (!_isReady)
            Container(
              color: bgColor,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
