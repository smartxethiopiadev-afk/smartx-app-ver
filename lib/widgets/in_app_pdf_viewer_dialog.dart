import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class InAppPdfViewerDialog extends StatelessWidget {
  final String pdfUrl;
  final String title;
  final bool isDark;

  const InAppPdfViewerDialog({
    super.key,
    required this.pdfUrl,
    required this.title,
    required this.isDark,
  });

  static Future<void> show(
    BuildContext context, {
    required String pdfUrl,
    required String title,
    required bool isDark,
  }) async {
    if (pdfUrl.isEmpty) return;

    final Uri uri = Uri.parse(pdfUrl);

    // On mobile or web, attempt inAppBrowserView or external application
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: kIsWeb
              ? LaunchMode.externalApplication
              : LaunchMode.inAppBrowserView,
        );
        return;
      }
    } catch (_) {}

    // Fallback modal dialog
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => InAppPdfViewerDialog(
          pdfUrl: pdfUrl,
          title: title,
          isDark: isDark,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Dialog(
      backgroundColor: backgroundColor,
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.picture_as_pdf_rounded,
                    color: Color(0xFFEF4444),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'PDF Study Material',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: subColor,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded, color: subColor),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Banner Preview
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.menu_book_rounded,
                    size: 48,
                    color: isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'እባክዎ ፒዲኤፉን ለመክፈት ከታች ያለውን ይጫኑ',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.notoSansEthiopic(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Click below to open or download the PDF',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: subColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Action Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final Uri uri = Uri.parse(pdfUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
                icon: const Icon(Icons.open_in_new_rounded, size: 20, color: Colors.white),
                label: Text(
                  'ፒዲኤፍ ክፈት (Open PDF)',
                  style: GoogleFonts.notoSansEthiopic(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
