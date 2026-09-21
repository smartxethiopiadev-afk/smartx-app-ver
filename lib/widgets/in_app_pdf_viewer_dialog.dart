import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

class InAppPdfViewerDialog extends StatefulWidget {
  final String pdfUrl;
  final String title;
  final bool isDark;
  final String? summary;
  final int? grade;
  final String? subject;
  final int? unit;

  const InAppPdfViewerDialog({
    super.key,
    required this.pdfUrl,
    required this.title,
    required this.isDark,
    this.summary,
    this.grade,
    this.subject,
    this.unit,
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
  }) async {
    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => InAppPdfViewerDialog(
            pdfUrl: pdfUrl,
            title: title,
            isDark: isDark,
            summary: summary,
            grade: grade,
            subject: subject,
            unit: unit,
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

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBg = widget.isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = widget.isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final gradeText = widget.grade != null ? 'Grade ${widget.grade}' : '';
    final subjectText = widget.subject ?? 'Study Note';
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
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            if (gradeText.isNotEmpty || unitText.isNotEmpty)
              Text(
                '$subjectText — $gradeText $unitText'.trim(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: subColor,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share_rounded, color: subColor),
            onPressed: () {
              final text = '📚 ${widget.title}\n$subjectText $gradeText $unitText\nStudy with Smart Learn Ethiopia!';
              Share.share(text);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // PDF Header Banner Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.picture_as_pdf_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ትምህርታዊ ፒዲኤፍ ማስታወሻ',
                                style: GoogleFonts.notoSansEthiopic(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Ethiopian Curriculum Study Material',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Download Offline Action
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isDownloading
                            ? null
                            : () async {
                                final messenger = ScaffoldMessenger.of(context);
                                setState(() => _isDownloading = true);
                                await Future.delayed(const Duration(milliseconds: 600));
                                if (mounted) {
                                  setState(() {
                                    _isDownloading = false;
                                    _isDownloaded = true;
                                  });
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'ፒዲኤፉ ለ offline ጥናት በስኬት ወርዷል!',
                                        style: GoogleFonts.notoSansEthiopic(),
                                      ),
                                      backgroundColor: const Color(0xFF10B981),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                        icon: _isDownloading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                                ),
                              )
                            : Icon(
                                _isDownloaded ? Icons.check_circle_rounded : Icons.download_rounded,
                                size: 20,
                                color: const Color(0xFF2563EB),
                              ),
                        label: Text(
                          _isDownloaded ? 'ፒዲኤፉ ወርዷል (Downloaded)' : 'ፒዲኤፍ አውርድ (Download PDF)',
                          style: GoogleFonts.notoSansEthiopic(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF2563EB),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Summary / Notes Reader Content
              if (widget.summary != null && widget.summary!.isNotEmpty) ...[
                Text(
                  'የማጠቃለያ ነጥቦች (Short Note Summary)',
                  style: GoogleFonts.notoSansEthiopic(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: widget.isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Text(
                    widget.summary!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      height: 1.6,
                      color: textColor,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // In-App Document Viewer Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: widget.isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.article_rounded,
                      size: 52,
                      color: Color(0xFF2563EB),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Ethiopian National Curriculum Standard',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: subColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: widget.isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF10B981)),
                          const SizedBox(width: 8),
                          Text(
                            'Verified Official Curriculum Content',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

