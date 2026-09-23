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

/// Dedicated In-App PDF Viewer Screen for displaying Short Note PDFs.
class PdfViewerScreen extends StatefulWidget {
  final String pdfUrl;
  final String title;
  final String? subject;
  final String? localFilePath;

  const PdfViewerScreen({
    super.key,
    required this.pdfUrl,
    required this.title,
    this.subject,
    this.localFilePath,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  String? _localPath;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  int _totalPages = 0;
  int _currentPage = 0;
  bool _isReady = false;
  bool _swipeHorizontal = false;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      // 1. Check if localFilePath is provided and exists
      if (widget.localFilePath != null && widget.localFilePath!.isNotEmpty) {
        final file = File(widget.localFilePath!);
        if (await file.exists()) {
          setState(() {
            _localPath = file.path;
            _isLoading = false;
          });
          return;
        }
      }

      // 2. Validate URL
      final url = widget.pdfUrl.trim();
      if (url.isEmpty) {
        setState(() {
          _hasError = true;
          _errorMessage = 'PDF link not available for this unit';
          _isLoading = false;
        });
        return;
      }

      // 3. Web platform fallback
      if (kIsWeb) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // 4. Download PDF to temporary cache for Android/iOS native viewing
      final uri = Uri.parse(url);
      final response = await http.get(uri).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final dir = await getTemporaryDirectory();
        final filename = 'pdf_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final file = File('${dir.path}/$filename');
        await file.writeAsBytes(bytes, flush: true);

        if (mounted) {
          setState(() {
            _localPath = file.path;
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
          _errorMessage = 'Unable to load PDF document. Please check your internet connection.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appConfig = AppStateProvider.of(context);
    final isDarkMode = appConfig.isDarkMode;
    final bgColor = isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBg = isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final subTextColor = isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 1,
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
                fontSize: 16,
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
          if (_isReady && _totalPages > 0 && !kIsWeb) ...[
            IconButton(
              tooltip: _swipeHorizontal ? 'Vertical Scroll' : 'Horizontal Scroll',
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
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '${_currentPage + 1} / $_totalPages',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF2563EB),
                  ),
                ),
              ),
            ),
          ],
          IconButton(
            tooltip: 'Share PDF',
            icon: Icon(Icons.share_rounded, color: textColor),
            onPressed: () {
              if (widget.pdfUrl.isNotEmpty) {
                Share.share('Check out this Short Note PDF: ${widget.pdfUrl}');
              }
            },
          ),
        ],
      ),
      body: _buildBody(bgColor, textColor, subTextColor),
    );
  }

  Widget _buildBody(Color bgColor, Color textColor, Color subTextColor) {
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
              'Downloading PDF...',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Please wait a moment',
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
                'PDF Not Available',
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
                  final uri = Uri.parse(widget.pdfUrl);
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

    return Stack(
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
          preventLinkNavigation: false,
          onRender: (pages) {
            setState(() {
              _totalPages = pages ?? 0;
              _isReady = true;
            });
          },
          onError: (error) {
            setState(() {
              _hasError = true;
              _errorMessage = error.toString();
            });
          },
          onPageError: (page, error) {
            debugPrint('[PdfViewerScreen] Page $page error: $error');
          },
          onPageChanged: (int? page, int? total) {
            if (page != null) {
              setState(() {
                _currentPage = page;
              });
            }
          },
        ),
        if (!_isReady)
          const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
            ),
          ),
      ],
    );
  }
}
