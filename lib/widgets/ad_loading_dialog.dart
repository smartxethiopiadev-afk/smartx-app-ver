import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdLoadingDialog extends StatefulWidget {
  final String languageCode;
  final bool isDark;

  const AdLoadingDialog({
    super.key,
    this.languageCode = 'en',
    this.isDark = false,
  });

  /// Displays the sleek modern Ad Loading Dialog with a smooth fade & scale transition
  static Future<void> show(
    BuildContext context, {
    String languageCode = 'en',
    bool isDark = false,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'AdLoading',
      barrierColor: Colors.black.withValues(alpha: 0.65),
      transitionDuration: const Duration(milliseconds: 280),
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
        final curved = CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  /// Safely dismisses the Ad Loading Dialog if currently shown
  static void hide(BuildContext context) {
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  @override
  State<AdLoadingDialog> createState() => _AdLoadingDialogState();
}

class _AdLoadingDialogState extends State<AdLoadingDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEn = widget.languageCode == 'en';
    final bool isDark = widget.isDark;

    final cardBg = isDark
        ? const Color(0xFF0F172A).withValues(alpha: 0.92)
        : Colors.white.withValues(alpha: 0.96);

    final borderColor = isDark
        ? const Color(0xFF38BDF8).withValues(alpha: 0.35)
        : const Color(0xFF0284C7).withValues(alpha: 0.25);

    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 310,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.25 : 0.12),
                blurRadius: 32,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: borderColor, width: 1.5),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Glowing pulse animation with brand circular progress ring
                    AnimatedBuilder(
                      animation: _animController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnim.value,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer ambient glow ring
                              Container(
                                width: 78,
                                height: 78,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00D2FF).withValues(
                                        alpha: isDark ? 0.45 : 0.3,
                                      ),
                                      blurRadius: 20,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                              // Rotating gradient circular progress indicator
                              SizedBox(
                                width: 68,
                                height: 68,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3.5,
                                  valueColor: const AlwaysStoppedAnimation<Color>(
                                    Color(0xFF00D2FF),
                                  ),
                                  backgroundColor: isDark
                                      ? const Color(0xFF1E293B)
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              // Center sponsor/ad modern play badge
                              Container(
                                width: 50,
                                height: 50,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [Color(0xFF0072FF), Color(0xFF00D2FF)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.auto_awesome_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Primary Title
                    Text(
                      isEn ? "Loading sponsor ad..." : "ማስታወቂያ በመጫን ላይ...",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtitle / Helper
                    Text(
                      isEn
                          ? "Free study resources made possible with sponsor support. Please wait a moment."
                          : "የትምህርት መርጃዎችን በነጻ ለማቅረብ የተዘጋጀ። እባክዎ ጥቂት ሰከንዶች ይጠብቁ...",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                        color: subtitleColor,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Subtle Progress shimmer pill
                    Container(
                      height: 4,
                      width: 140,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          backgroundColor: Colors.transparent,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF00D2FF),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
