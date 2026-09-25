import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';
import '../services/offline_manager.dart';
import '../services/short_note_service.dart';

/// Ultra High-Resolution Full-Screen In-App PDF Viewer Screen
/// Features:
/// - Full-screen edge-to-edge page cover with high DPI crisp rendering
/// - Tap-to-toggle animated floating controls (Next, Prev, Jump, Invert, Save)
/// - Night mode & Invert colors for eye comfort
/// - Horizontal & Vertical swipe options
/// - Offline download & caching
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

class _PdfViewerScreenState extends State<PdfViewerScreen> with SingleTickerProviderStateMixin {
  String? _localPath;
  String _effectivePdfUrl = '';
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  int _totalPages = 0;
  int _currentPage = 0;
  bool _isReady = false;
  bool _swipeHorizontal = false;
  bool _fitBoth = false; // false = Fit width (Ultra crisp high resolution fill), true = fit both
  bool _isNightMode = false;
  bool _nightModeExplicitlySet = false;
  bool _isSavingOffline = false;
  bool _isDownloaded = false;

  // Controls visibility toggle
  bool _showControls = true;

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
            _errorMessage = 'ለዚህ ምዕራፍ የተዘጋጀው የትምህርት ማጠቃለያ አጭር ማስታወሻ (Short Note) በዳታቤዝ ውስጥ ገና አልተጫነም። አዘጋጆቻችን እያዘጋጁት ሲሆን በቅርቡ የሚጫን ይሆናል!';
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

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  void _jumpToPageDialog() {
    if (_totalPages <= 1) return;
    final controller = TextEditingController(text: '${_currentPage + 1}');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.menu_book_rounded, color: Color(0xFF0284C7), size: 22),
            const SizedBox(width: 8),
            Text(
              'ወደ ገጽ ሂድ (Jump to Page)',
              style: GoogleFonts.notoSansEthiopic(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ],
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Page (1 - $_totalPages)',
            hintText: 'e.g. 5',
            prefixIcon: const Icon(Icons.numbers_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
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
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

    final Color bgColor = _isNightMode
        ? const Color(0xFF0F172A)
        : (isDark ? const Color(0xFF121212) : const Color(0xFFF1F5F9));
    final Color textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final Color subTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      extendBodyBehindAppBar: true,
      body: SafeArea(
        top: false,
        bottom: false,
        child: _buildBody(bgColor, textColor, subTextColor),
      ),
    );
  }

  Widget _buildBody(Color bgColor, Color textColor, Color subTextColor) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0284C7)),
            ),
            const SizedBox(height: 20),
            Text(
              'Rendering Ultra-Crisp PDF...',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'High resolution vector rendering in progress',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: subTextColor,
              ),
            ),
          ],
        ),
      );
    }

    if (_hasError) {
      return _buildErrorView(textColor, subTextColor);
    }

    if (kIsWeb) {
      return _buildWebView(textColor, subTextColor);
    }

    if (_localPath == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _toggleControls,
      child: Stack(
        children: [
          // 1. Full Screen PDF View (High DPI, Edge-to-Edge Fill)
          Positioned.fill(
            child: PDFView(
              filePath: _localPath,
              enableSwipe: true,
              swipeHorizontal: _swipeHorizontal,
              autoSpacing: true,
              pageFling: true,
              pageSnap: true,
              defaultPage: _currentPage,
              fitPolicy: _fitBoth ? FitPolicy.BOTH : FitPolicy.WIDTH,
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
          ),

          // 2. Loading Indicator while PDF finishes rendering
          if (!_isReady)
            Container(
              color: bgColor,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0284C7)),
                ),
              ),
            ),

          // 3. Mini Floating Page Indicator (Visible when controls are hidden)
          if (!_showControls && _isReady && _totalPages > 0)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: 16,
              child: GestureDetector(
                onTap: _toggleControls,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.touch_app_rounded, color: Colors.white, size: 13),
                      const SizedBox(width: 4),
                      Text(
                        '${_currentPage + 1} / $_totalPages',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 4. Floating Side Navigation Arrows (Appear on tap)
          if (_showControls && _isReady && _totalPages > 1) ...[
            // Left Quick Arrow
            Positioned(
              left: 12,
              top: 0,
              bottom: 0,
              child: Center(
                child: AnimatedOpacity(
                  opacity: _currentPage > 0 ? 1.0 : 0.3,
                  duration: const Duration(milliseconds: 200),
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.65),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _currentPage > 0
                          ? () => _pdfViewController?.setPage(_currentPage - 1)
                          : null,
                      child: const Padding(
                        padding: EdgeInsets.all(10.0),
                        child: Icon(Icons.chevron_left_rounded, color: Colors.white, size: 28),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Right Quick Arrow
            Positioned(
              right: 12,
              top: 0,
              bottom: 0,
              child: Center(
                child: AnimatedOpacity(
                  opacity: _currentPage < _totalPages - 1 ? 1.0 : 0.3,
                  duration: const Duration(milliseconds: 200),
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.65),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _currentPage < _totalPages - 1
                          ? () => _pdfViewController?.setPage(_currentPage + 1)
                          : null,
                      child: const Padding(
                        padding: EdgeInsets.all(10.0),
                        child: Icon(Icons.chevron_right_rounded, color: Colors.white, size: 28),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],

          // 5. Floating Glassmorphic Top Header Bar (Animated fade in/out)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            top: _showControls ? 0 : -130,
            left: 0,
            right: 0,
            child: _buildFloatingTopBar(),
          ),

          // 6. Floating Glassmorphic Bottom Navigation Bar (Animated slide up/down)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            bottom: _showControls ? 0 : -130,
            left: 0,
            right: 0,
            child: _buildFloatingBottomToolbar(),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingTopBar() {
    final topPadding = MediaQuery.of(context).padding.top;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.fromLTRB(12, topPadding + 6, 12, 12),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF0F172A) : Colors.white).withValues(alpha: 0.94),
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back Button
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Go Back',
          ),
          const SizedBox(width: 4),

          // Title & Unit Tag
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (widget.subject != null && widget.subject!.isNotEmpty)
                  Text(
                    '${widget.subject!} • Grade ${widget.grade ?? ""} • Unit ${widget.unitNumber ?? ""}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0284C7),
                    ),
                  ),
              ],
            ),
          ),

          // Fit Width vs Fit Page toggle for ultimate quality
          IconButton(
            tooltip: _fitBoth ? 'Fill Screen Width (High DPI)' : 'Fit Entire Page',
            icon: Icon(
              _fitBoth ? Icons.fit_screen_rounded : Icons.aspect_ratio_rounded,
              color: const Color(0xFF0284C7),
              size: 21,
            ),
            onPressed: () {
              setState(() {
                _fitBoth = !_fitBoth;
              });
            },
          ),

          // Dark Mode / Invert Colors Toggle
          IconButton(
            tooltip: _isNightMode ? 'Light Mode (White Page)' : 'Dark Mode (Eye Comfort)',
            icon: Icon(
              _isNightMode ? Icons.nightlight_round : Icons.wb_sunny_rounded,
              color: _isNightMode ? const Color(0xFFFBBF24) : const Color(0xFF64748B),
              size: 21,
            ),
            onPressed: () {
              setState(() {
                _nightModeExplicitlySet = true;
                _isNightMode = !_isNightMode;
              });
            },
          ),

          // Download / Offline Save Button
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
                      color: _isDownloaded ? const Color(0xFF10B981) : const Color(0xFF64748B),
                      size: 21,
                    ),
              onPressed: _isDownloaded ? null : _saveToDownloads,
            ),
        ],
      ),
    );
  }

  Widget _buildFloatingBottomToolbar() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!_isReady || _totalPages <= 0) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, bottomPadding + 10),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF0F172A) : Colors.white).withValues(alpha: 0.94),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous Page Button
          ElevatedButton.icon(
            onPressed: _currentPage > 0
                ? () => _pdfViewController?.setPage(_currentPage - 1)
                : null,
            icon: const Icon(Icons.chevron_left_rounded, size: 20),
            label: Text(
              'Prev',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 12.5),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),

          // Page Indicator & Jump Dialog Trigger
          GestureDetector(
            onTap: _jumpToPageDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.menu_book_rounded, size: 16, color: Color(0xFF0284C7)),
                  const SizedBox(width: 6),
                  Text(
                    'Page ${_currentPage + 1} of $_totalPages',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0284C7),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.edit_rounded, size: 14, color: Color(0xFF0284C7)),
                ],
              ),
            ),
          ),

          // Next Page Button
          ElevatedButton(
            onPressed: _currentPage < _totalPages - 1
                ? () => _pdfViewController?.setPage(_currentPage + 1)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Next',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 12.5),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebView(Color textColor, Color subTextColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.picture_as_pdf_rounded,
              size: 64,
              color: Color(0xFF0284C7),
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
              'Open this high-resolution PDF note directly in your browser.',
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
                backgroundColor: const Color(0xFF0284C7),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(Color textColor, Color subTextColor) {
    final isAm = AppStateProvider.of(context).languageCode == 'am';
    final isLight = !AppStateProvider.of(context).isDarkMode;
    final unitLabel = 'Grade ${widget.grade ?? ""} • ${widget.subject ?? ""} • Unit ${widget.unitNumber ?? ""}';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.all(28.0),
          decoration: BoxDecoration(
            color: isLight ? Colors.white : const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isLight ? 0.04 : 0.2),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.hourglass_top_rounded, size: 48, color: Color(0xFF0284C7)),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  unitLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0284C7),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                isAm ? "ማስታወሻ በቅርቡ ይጫናል (Coming Soon)" : "Short Note Coming Soon",
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansEthiopic(
                  fontWeight: FontWeight.w900,
                  fontSize: 19,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansEthiopic(
                  fontSize: 13.5,
                  height: 1.5,
                  color: subTextColor,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: Text(
                      isAm ? "ተመለስ" : "Go Back",
                      style: GoogleFonts.notoSansEthiopic(fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _loadPdf,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(
                      isAm ? "እንደገና ሞክር" : "Retry",
                      style: GoogleFonts.notoSansEthiopic(fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextButton.icon(
                onPressed: () async {
                  final msg = Uri.encodeComponent(
                      'ሰላም ስማርት ለርን አድሚን (@smart_x_help)፣ የ $unitLabel አጭር ማስታወሻ ፒዲኤፍ እንዲጫንልኝ እፈልጋለሁ።');
                  final uri = Uri.parse('https://t.me/smart_x_help?text=$msg');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.telegram_rounded, size: 18, color: Color(0xFF0284C7)),
                label: Text(
                  isAm ? "በቴሌግራም አድሚን እንዲጫን ጠይቅ" : "Request upload on Telegram",
                  style: GoogleFonts.notoSansEthiopic(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0284C7),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
