import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui_web' as ui_web;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

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

  static void show(BuildContext context, {required String pdfUrl, required String title, required bool isDark}) {
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

  @override
  Widget build(BuildContext context) {
    final String viewType = 'pdf-iframe-${pdfUrl.hashCode}';
    
    try {
      ui_web.platformViewRegistry.registerViewFactory(
        viewType,
        (int viewId) {
          final html.IFrameElement iframe = html.IFrameElement()
            ..src = pdfUrl
            ..style.border = 'none'
            ..style.width = '100%'
            ..style.height = '100%';
          return iframe;
        },
      );
    } catch (_) {}

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  color: Colors.grey.shade100,
                  child: HtmlElementView(viewType: viewType),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
