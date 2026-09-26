import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum ErrorCategory {
  network,
  invalidCode,
  deviceMismatch,
  accountNotFound,
  expired,
  general,
}

/// A user-friendly, actionable error card designed to replace harsh red alert boxes.
class FriendlyErrorCard extends StatelessWidget {
  final String errorMessage;
  final bool isDarkMode;
  final String languageCode;
  final VoidCallback? onRetry;
  final VoidCallback? onAction;
  final String? actionLabel;
  final VoidCallback? onDismiss;

  const FriendlyErrorCard({
    super.key,
    required this.errorMessage,
    required this.isDarkMode,
    required this.languageCode,
    this.onRetry,
    this.onAction,
    this.actionLabel,
    this.onDismiss,
  });

  static ErrorCategory categorizeError(String error) {
    final lower = error.toLowerCase();
    if (lower.contains('network') ||
        lower.contains('internet') ||
        lower.contains('connection') ||
        lower.contains('offline') ||
        lower.contains('timeout') ||
        lower.contains('socket') ||
        lower.contains('በይነመረብ')) {
      return ErrorCategory.network;
    }
    if (lower.contains('code') ||
        lower.contains('invalid code') ||
        lower.contains('ኮድ') ||
        lower.contains('ያልተገኘ')) {
      return ErrorCategory.invalidCode;
    }
    if (lower.contains('device') ||
        lower.contains('መለያ') ||
        lower.contains('ስልክ') && lower.contains('ሌላ')) {
      return ErrorCategory.deviceMismatch;
    }
    if (lower.contains('not found') ||
        lower.contains('አልተገኘም') ||
        lower.contains('unregistered')) {
      return ErrorCategory.accountNotFound;
    }
    if (lower.contains('expired') ||
        lower.contains('አብቅቷል') ||
        lower.contains('ጊዜው')) {
      return ErrorCategory.expired;
    }
    return ErrorCategory.general;
  }

  /// Displays a friendly snackbar with actionable feedback
  static void showErrorSnackBar(
    BuildContext context, {
    required String message,
    required String languageCode,
    VoidCallback? onRetry,
  }) {
    final isAm = languageCode == 'am';
    final category = categorizeError(message);

    IconData icon;
    Color iconColor;
    String friendlyTitle;

    switch (category) {
      case ErrorCategory.network:
        icon = Icons.wifi_off_rounded;
        iconColor = const Color(0xFFF59E0B);
        friendlyTitle = isAm ? 'የኔትወርክ ግንኙነት' : 'Connection Issue';
        break;
      case ErrorCategory.invalidCode:
        icon = Icons.vpn_key_off_rounded;
        iconColor = const Color(0xFFF43F5E);
        friendlyTitle = isAm ? 'የማግበሪያ ኮድ ስህተት' : 'Verification Issue';
        break;
      case ErrorCategory.deviceMismatch:
        icon = Icons.phonelink_lock_rounded;
        iconColor = const Color(0xFF8B5CF6);
        friendlyTitle = isAm ? 'የመሳሪያ ማረጋገጫ' : 'Device Security';
        break;
      case ErrorCategory.accountNotFound:
        icon = Icons.person_search_rounded;
        iconColor = const Color(0xFF0284C7);
        friendlyTitle = isAm ? 'መረጃ ማረጋገጫ' : 'Account Check';
        break;
      case ErrorCategory.expired:
        icon = Icons.history_toggle_off_rounded;
        iconColor = const Color(0xFFF59E0B);
        friendlyTitle = isAm ? 'የአገልግሎት ጊዜ' : 'Subscription Notice';
        break;
      case ErrorCategory.general:
        icon = Icons.info_outline_rounded;
        iconColor = const Color(0xFF0284C7);
        friendlyTitle = isAm ? 'ማስታወሻ' : 'Notice';
        break;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friendlyTitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: GoogleFonts.notoSansEthiopic(
                      fontSize: 12,
                      color: const Color(0xFFCBD5E1),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        action: onRetry != null
            ? SnackBarAction(
                label: isAm ? 'እንደገና' : 'Retry',
                textColor: const Color(0xFF38BDF8),
                onPressed: onRetry,
              )
            : null,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isAm = languageCode == 'am';
    final category = categorizeError(errorMessage);

    IconData icon;
    Color accentColor;
    String friendlyTitle;
    String actionableTip;

    switch (category) {
      case ErrorCategory.network:
        icon = Icons.wifi_off_rounded;
        accentColor = const Color(0xFFF59E0B);
        friendlyTitle = isAm ? 'የበይነመረብ ግንኙነት ችግር' : 'Network Connection Issue';
        actionableTip = isAm
            ? 'እባክዎ የሞባይል ዳታ ወይም ዋይፋይ መብራቱን ያረጋግጡና እንደገና ይሞክሩ።'
            : 'Please check your Wi-Fi or mobile data connection and try again.';
        break;
      case ErrorCategory.invalidCode:
        icon = Icons.lock_clock_rounded;
        accentColor = const Color(0xFFF43F5E);
        friendlyTitle = isAm ? 'ፈቃድ አልተገኘም' : 'License / Account Not Found';
        actionableTip = isAm
            ? 'የስልክ ቁጥርዎን ወይም ሙሉ ስምዎን ያረጋግጡና በድጋሚ ይሞክሩ ወይም አድሚኑን ያነጋግሩ።'
            : 'Please check your name and phone number or contact admin.';
        break;
      case ErrorCategory.deviceMismatch:
        icon = Icons.phonelink_lock_rounded;
        accentColor = const Color(0xFF8B5CF6);
        friendlyTitle = isAm ? 'የመሳሪያ ጥበቃ ማረጋገጫ' : 'Device Security Check';
        actionableTip = isAm
            ? 'ይህ መለያ አስቀድሞ ከተመዘገበበት ዋና ስልክ ጋር ብቻ ይሰራል ወይም አድሚኑን ያነጋግሩ።'
            : 'This account is linked to your registered device for security.';
        break;
      case ErrorCategory.accountNotFound:
        icon = Icons.person_search_rounded;
        accentColor = const Color(0xFF0284C7);
        friendlyTitle = isAm ? 'የተማሪ መረጃ አልተገኘም' : 'Account Not Found';
        actionableTip = isAm
            ? 'የተማሪውን ሙሉ ስም እና ስልክ ቁጥር በትክክል ማስገባትዎን ያረጋግጡ።'
            : 'Please confirm your phone number and student full name are correct.';
        break;
      case ErrorCategory.expired:
        icon = Icons.history_toggle_off_rounded;
        accentColor = const Color(0xFFF59E0B);
        friendlyTitle = isAm ? 'የአገልግሎት ጊዜ ተጠናቋል' : 'Subscription Notice';
        actionableTip = isAm
            ? 'የትምህርት ፓኬጁን በድጋሚ ለማስቀጠል ፈቃድዎን ያድሱ።'
            : 'Please renew your subscription to access all updated lessons.';
        break;
      case ErrorCategory.general:
        icon = Icons.info_outline_rounded;
        accentColor = const Color(0xFF0284C7);
        friendlyTitle = isAm ? 'ማሳሰቢያ' : 'Notice';
        actionableTip = isAm
            ? 'እባክዎ መረጃውን አረጋግጠው እንደገና ይሞክሩ።'
            : 'Please verify the details and try again.';
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: isDarkMode ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withValues(alpha: isDarkMode ? 0.35 : 0.25),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      friendlyTitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      errorMessage,
                      style: GoogleFonts.notoSansEthiopic(
                        fontSize: 12,
                        color: isDarkMode ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 14,
                          color: accentColor,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            actionableTip,
                            style: GoogleFonts.notoSansEthiopic(
                              fontSize: 11,
                              color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onDismiss != null)
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  onPressed: onDismiss,
                ),
            ],
          ),
          if (onRetry != null || onAction != null) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onRetry != null)
                  TextButton.icon(
                    onPressed: onRetry,
                    icon: Icon(Icons.refresh_rounded, size: 15, color: accentColor),
                    label: Text(
                      isAm ? 'እንደገና ሞክር' : 'Retry',
                      style: GoogleFonts.notoSansEthiopic(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: accentColor,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                if (onAction != null && actionLabel != null) ...[
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: onAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      actionLabel!,
                      style: GoogleFonts.notoSansEthiopic(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
