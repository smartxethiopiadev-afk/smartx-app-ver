// ignore_for_file: unused_element, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/offline_manager.dart';

class InAppPdfViewerDialog extends StatefulWidget {
  final String pdfUrl;
  final String title;
  final bool isDark;
  final String? summary;
  final int? grade;
  final String? subject;
  final int? unit;
  final String? unitId;

  const InAppPdfViewerDialog({
    super.key,
    required this.pdfUrl,
    required this.title,
    required this.isDark,
    this.summary,
    this.grade,
    this.subject,
    this.unit,
    this.unitId,
  });

  static Future<void> show(
    BuildContext context, {
    required String pdfUrl,
    required String title,
    required bool isDark,
    String? summary,
    int? grade,
    String? subject,
    int? unit,
    String? unitId,
  }) async {
    if (context.mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => InAppPdfViewerDialog(
            pdfUrl: pdfUrl,
            title: title,
            isDark: isDark,
            summary: summary,
            grade: grade,
            subject: subject,
            unit: unit,
            unitId: unitId,
          ),
        ),
      );
    }
  }

  @override
  State<InAppPdfViewerDialog> createState() => _InAppPdfViewerDialogState();
}

class _InAppPdfViewerDialogState extends State<InAppPdfViewerDialog> {
  bool _isDownloading = false;
  bool _isDownloaded = false;
  double _downloadProgress = 0.0;
  int _currentPage = 1;
  final int _totalPages = 6;
  double _zoomScale = 1.0;
  final TransformationController _transformationController = TransformationController();

  String get _cleanUnitId {
    if (widget.unitId != null && widget.unitId!.isNotEmpty) {
      return widget.unitId!;
    }
    final grade = widget.grade ?? 9;
    final sub = (widget.subject ?? 'general').toLowerCase().replaceAll(' ', '_');
    final unit = widget.unit ?? 1;
    return 'g${grade}_${sub}_u$unit';
  }

  @override
  void initState() {
    super.initState();
    _checkOfflineStatus();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _checkOfflineStatus() async {
    final downloaded = await OfflineManager.hasOfflinePdf(_cleanUnitId);
    if (mounted) {
      setState(() {
        _isDownloaded = downloaded;
      });
    }
  }

  Future<void> _downloadPdfOffline() async {
    if (_isDownloading) return;
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.05;
    });

    try {
      // Simulate real chunk download progress
      for (int i = 1; i <= 10; i++) {
        await Future.delayed(const Duration(milliseconds: 120));
        if (!mounted) return;
        setState(() {
          _downloadProgress = i / 10.0;
        });
      }

      await OfflineManager.saveOfflinePdf(
        unitId: _cleanUnitId,
        pdfUrl: widget.pdfUrl,
        title: widget.title,
        summary: widget.summary,
        grade: widget.grade,
        unit: widget.unit,
      );

      if (mounted) {
        setState(() {
          _isDownloading = false;
          _isDownloaded = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ፒዲኤፉ ለ offline ጥናት በስኬት ወርዷል! (Saved for Offline Study)',
              style: GoogleFonts.notoSansEthiopic(),
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ማውረድ አልተሳካም፡ እባክዎ እንደገና ይሞክሩ ($e)',
              style: GoogleFonts.notoSansEthiopic(),
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _openExternalPdf() async {
    if (widget.pdfUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ትክክለኛ የፒዲኤፍ አድራሻ አልተገኘም (No URL available)',
            style: GoogleFonts.notoSansEthiopic(),
          ),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }

    try {
      final uri = Uri.parse(widget.pdfUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ፒዲኤፉን በውጭ መተግበሪያ መክፈት አልተቻለም፡ $e',
              style: GoogleFonts.notoSansEthiopic(),
            ),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _zoomIn() {
    setState(() {
      _zoomScale = (_zoomScale + 0.25).clamp(0.75, 2.5);
      _transformationController.value = Matrix4.identity()..scale(_zoomScale);
    });
  }

  void _zoomOut() {
    setState(() {
      _zoomScale = (_zoomScale - 0.25).clamp(0.75, 2.5);
      _transformationController.value = Matrix4.identity()..scale(_zoomScale);
    });
  }

  void _resetZoom() {
    setState(() {
      _zoomScale = 1.0;
      _transformationController.value = Matrix4.identity();
    });
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.isDark ? const Color(0xFF0B132B) : const Color(0xFFF8FAFC);
    final cardBg = widget.isDark ? const Color(0xFF1C2541) : Colors.white;
    final textColor = widget.isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final gradeText = widget.grade != null ? 'Grade ${widget.grade}' : '';
    final subjectText = widget.subject ?? 'Curriculum Note';
    final unitText = widget.unit != null ? 'Unit ${widget.unit}' : '';

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            Row(
              children: [
                if (gradeText.isNotEmpty || unitText.isNotEmpty)
                  Text(
                    '$subjectText — $gradeText $unitText'.trim(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: subColor,
                    ),
                  ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _isDownloaded ? const Color(0xFF10B981).withValues(alpha: 0.15) : const Color(0xFF2563EB).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _isDownloaded ? 'OFFLINE' : 'ONLINE',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: _isDownloaded ? const Color(0xFF10B981) : const Color(0xFF2563EB),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'በውጭ PDF አንባቢ ክፈት (External Viewer)',
            icon: const Icon(Icons.open_in_new_rounded, size: 20),
            color: const Color(0xFF2563EB),
            onPressed: _openExternalPdf,
          ),
          IconButton(
            tooltip: 'አጋራ (Share)',
            icon: Icon(Icons.share_rounded, size: 20, color: subColor),
            onPressed: () {
              final text = '📚 ${widget.title}\n$subjectText $gradeText $unitText\nStudy with Smart Learn Ethiopia!\n${widget.pdfUrl}';
              Share.share(text);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Download Status Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: widget.isDark ? const Color(0xFF131D38) : const Color(0xFFEFF6FF),
                border: Border(
                  bottom: BorderSide(
                    color: widget.isDark ? const Color(0xFF1E293B) : const Color(0xFFDBEAFE),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isDownloaded ? Icons.check_circle_rounded : Icons.offline_pin_rounded,
                    color: _isDownloaded ? const Color(0xFF10B981) : const Color(0xFF2563EB),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _isDownloaded
                          ? 'ይህ ፒዲኤፍ ለኦፍላይን ጥናት በስልክዎ ተቀምጧል'
                          : 'ፒዲኤፉን ያውርዱ እና ያለ ኢንተርኔት በፈለጉበት ሰዓት ያንብቡ',
                      style: GoogleFonts.notoSansEthiopic(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isDownloading ? null : _downloadPdfOffline,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isDownloaded ? const Color(0xFF10B981) : const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    icon: _isDownloading
                        ? SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              value: _downloadProgress > 0 ? _downloadProgress : null,
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Icon(
                            _isDownloaded ? Icons.done_all_rounded : Icons.download_rounded,
                            size: 16,
                          ),
                    label: Text(
                      _isDownloading
                          ? '${(_downloadProgress * 100).toInt()}%'
                          : (_isDownloaded ? 'ወርዷል' : 'አውርድ (Download)'),
                      style: GoogleFonts.notoSansEthiopic(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Reading Controls Toolbar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: cardBg,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page Indicator & Stepper
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded),
                        visualDensity: VisualDensity.compact,
                        onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: widget.isDark ? const Color(0xFF0B132B) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'ገጽ $_currentPage / $_totalPages',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded),
                        visualDensity: VisualDensity.compact,
                        onPressed: _currentPage < _totalPages ? () => setState(() => _currentPage++) : null,
                      ),
                    ],
                  ),

                  // Zoom Controls
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'አሳንስ (Zoom Out)',
                        icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
                        visualDensity: VisualDensity.compact,
                        onPressed: _zoomOut,
                      ),
                      Text(
                        '${(_zoomScale * 100).toInt()}%',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: subColor,
                        ),
                      ),
                      IconButton(
                        tooltip: 'አሳድግ (Zoom In)',
                        icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                        visualDensity: VisualDensity.compact,
                        onPressed: _zoomIn,
                      ),
                      IconButton(
                        tooltip: 'ወደ ነበረበት መልስ (Reset)',
                        icon: const Icon(Icons.restart_alt_rounded, size: 20),
                        visualDensity: VisualDensity.compact,
                        onPressed: _resetZoom,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Interactive PDF Document Page Viewer
            Expanded(
              child: InteractiveViewer(
                transformationController: _transformationController,
                minScale: 0.8,
                maxScale: 3.0,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: widget.isDark ? const Color(0xFF131D38) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: widget.isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Official Ministry Header watermark
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.picture_as_pdf_rounded,
                                        color: Color(0xFF2563EB),
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'የኢትዮጵያ ትምህርት ሚኒስቴር ስርዓተ-ትምህርት',
                                          style: GoogleFonts.notoSansEthiopic(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF2563EB),
                                          ),
                                        ),
                                        Text(
                                          'Ethiopian National Curriculum Standard',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 10,
                                            color: subColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'ገጽ $_currentPage / $_totalPages',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF10B981),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 32),

                            // Document Title
                            Text(
                              widget.title,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$subjectText • $gradeText • $unitText',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF2563EB),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Page Content Renderer based on active page
                            _buildPageContent(textColor, subColor),

                            const Divider(height: 40),

                            // Footer details
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Smart Learn Ethiopia Mobile System',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: subColor),
                                ),
                                Text(
                                  '© 2026 Academic Notes',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: subColor),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageContent(Color textColor, Color subColor) {
    if (widget.summary != null && widget.summary!.trim().isNotEmpty) {
      return Text(
        widget.summary!.trim(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          height: 1.7,
          color: textColor,
        ),
      );
    }
    return Container();
  }

  Widget _buildConceptCard(String title, String desc, Color textColor, Color subColor) {
    return Container();
  }
}


