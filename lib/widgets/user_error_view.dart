import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';

enum ErrorDisplayType {
  network,
  emptyContent,
  notFound,
  inputValidation,
  quizError,
  downloadError,
}

class UserErrorView extends StatelessWidget {
  final ErrorDisplayType type;
  final String? customTitle;
  final String? customMessage;
  final String? amharicMessage;
  final VoidCallback? onRetry;
  final String? retryLabel;
  final bool showTelegramReport;
  final String? contextTag;

  const UserErrorView({
    super.key,
    this.type = ErrorDisplayType.network,
    this.customTitle,
    this.customMessage,
    this.amharicMessage,
    this.onRetry,
    this.retryLabel,
    this.showTelegramReport = true,
    this.contextTag,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    String titleEn;
    String titleAm;
    String messageEn;
    String messageAm;

    switch (type) {
      case ErrorDisplayType.network:
        icon = Icons.wifi_off_rounded;
        color = Colors.amberAccent;
        titleEn = 'Connection Issue';
        titleAm = 'የኢንተርኔት ግንኙነት ችግር ተፈጥሯል';
        messageEn = 'Could not reach online servers. You can still study all downloaded units offline without network.';
        messageAm = 'ከሰርቨር ጋር መገናኘት አልተቻለም። የወረዱ ዩኒቶችዎን ያለ ኔትወርክ በነፃነት ማጥናት ይችላሉ።';
        break;
      case ErrorDisplayType.emptyContent:
        icon = Icons.folder_open_rounded;
        color = Colors.blueAccent;
        titleEn = 'No Content Available Yet';
        titleAm = 'ይዘቱ ለጊዜው አልተገኘም';
        messageEn = 'This unit is currently being updated by curriculum specialists for the latest national exam matrix.';
        messageAm = 'ይህ ክፍል በስርዓተ-ትምህርት አዘጋጆች በመከለስ ላይ ነው። በቅርቡ ይጫናል።';
        break;
      case ErrorDisplayType.notFound:
        icon = Icons.search_off_rounded;
        color = Colors.orangeAccent;
        titleEn = 'Resource Not Found';
        titleAm = 'የተፈለገው መረጃ አልተገኘም';
        messageEn = 'The requested note, quiz or worksheet could not be located in local storage or database.';
        messageAm = 'የተፈለገው ማጠቃለያ፣ ፈተና ወይም ዎርክሺት አልተገኘም። እባክዎ እንደገና ይሞክሩ።';
        break;
      case ErrorDisplayType.inputValidation:
        icon = Icons.error_outline_rounded;
        color = Colors.redAccent;
        titleEn = 'Invalid Information';
        titleAm = 'የተሳሳተ መረጃ ገብቷል';
        messageEn = 'Please review your entered data (e.g., Ethiopian phone number +251...) and try again.';
        messageAm = 'እባክዎን ያስገቡትን መረጃ (ለምሳሌ፡ ትክክለኛ የኢትዮጵያ ስልክ ቁጥር +251...) ያረጋግጡ።';
        break;
      case ErrorDisplayType.quizError:
        icon = Icons.quiz_outlined;
        color = Colors.redAccent;
        titleEn = 'Quiz Loading Issue';
        titleAm = 'የፈተና ጥያቄዎችን መጫን አልተቻለም';
        messageEn = 'Unable to parse quiz questions for this unit. Please report this to our Telegram educators.';
        messageAm = 'የዚህን ዩኒት የፈተና ጥያቄዎች ማግኘት አልተቻለም። እባክዎ በቴሌግራም ጥቆማ ይስጡ።';
        break;
      case ErrorDisplayType.downloadError:
        icon = Icons.cloud_off_rounded;
        color = AppConfig.accentRose;
        titleEn = 'Download Failed';
        titleAm = 'ማውረድ አልተሳካም';
        messageEn = 'Failed to cache this unit to device storage. Please check storage space or retry.';
        messageAm = 'ይዘቱን ወደ ስልክዎ ማውረድ አልተሳካም። የስልክዎ ማከማቻ ቦታ በቂ መሆኑን ያረጋግጡ።';
        break;
    }

    final finalTitle = customTitle ?? '$titleAm ($titleEn)';
    final finalMessage = amharicMessage ?? customMessage ?? messageAm;

    return Center(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppConfig.darkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 36),
            ),
            const SizedBox(height: 14),
            Text(
              finalTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              finalMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              messageEn,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 11,
              ),
            ),
            if (contextTag != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Code: $contextTag',
                  style: const TextStyle(color: Colors.white54, fontSize: 10, fontFamily: 'monospace'),
                ),
              ),
            ],
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (onRetry != null)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConfig.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: Text(
                      retryLabel ?? 'እንደገና ሞክር (Retry)',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                if (onRetry != null && showTelegramReport) const SizedBox(width: 10),
                if (showTelegramReport)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF29B6F6),
                      side: const BorderSide(color: Color(0xFF29B6F6)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      final text = '''
[Smart X Error Support]
Error: $finalTitle
Details: $finalMessage ($contextTag)
Telegram Channel: @smartx_ethiopia
''';
                      Clipboard.setData(ClipboardData(text: text));
                      final uri = Uri.parse(AppConfig.telegramChannelUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: const Icon(Icons.send_rounded, size: 14),
                    label: const Text('በቴሌግራም ጠይቅ', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
