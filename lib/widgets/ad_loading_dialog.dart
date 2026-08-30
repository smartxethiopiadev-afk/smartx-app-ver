import 'package:flutter/material.dart';

/// A sleek, minimal waiting system for ad/media loading without intrusive sponsor text or heavy card backgrounds.
class AdLoadingDialog extends StatelessWidget {
  final String languageCode;
  final bool isDark;

  const AdLoadingDialog({
    super.key,
    this.languageCode = 'en',
    this.isDark = false,
  });

  /// Displays the clean, minimal waiting dialog with a smooth fade transition
  static Future<void> show(
    BuildContext context, {
    String languageCode = 'en',
    bool isDark = false,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'AdWaiting',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, anim1, anim2) {
        return PopScope(
          canPop: false,
          child: AdLoadingDialog(
            languageCode: languageCode,
            isDark: isDark,
          ),
        );
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim1, curve: Curves.easeOut),
          child: child,
        );
      },
    );
  }

  /// Safely dismisses the loading waiting dialog if currently shown
  static void hide(BuildContext context) {
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1E293B).withValues(alpha: 0.85)
                : Colors.white.withValues(alpha: 0.92),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00BFFF).withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: SizedBox(
              width: 38,
              height: 38,
              child: CircularProgressIndicator(
                strokeWidth: 3.5,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00BFFF)),
                backgroundColor: Color(0x3300BFFF),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
