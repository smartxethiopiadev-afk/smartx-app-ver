// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/video_model.dart';
import '../services/analytics_service.dart';
import '../services/offline_manager.dart';

class YouTubeVideoPlayerDialog extends StatefulWidget {
  final VideoModel video;
  final bool isDarkMode;
  final String languageCode;

  const YouTubeVideoPlayerDialog({
    super.key,
    required this.video,
    required this.isDarkMode,
    required this.languageCode,
  });

  static void show(
    BuildContext context, {
    required VideoModel video,
    required bool isDarkMode,
    required String languageCode,
  }) {
    AnalyticsService.logTelegramBannerClicked(source: 'video_play_${video.id}');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => YouTubeVideoPlayerDialog(
        video: video,
        isDarkMode: isDarkMode,
        languageCode: languageCode,
      ),
    );
  }

  @override
  State<YouTubeVideoPlayerDialog> createState() =>
      _YouTubeVideoPlayerDialogState();
}

class _YouTubeVideoPlayerDialogState extends State<YouTubeVideoPlayerDialog> {
  bool _isOfflineSaved = false;
  bool _isSavingOffline = false;

  @override
  void initState() {
    super.initState();
    _checkOfflineStatus();
  }

  Future<void> _checkOfflineStatus() async {
    final downloaded = await OfflineManager.isOfflineVideoDownloaded(widget.video.id);
    if (mounted) {
      setState(() {
        _isOfflineSaved = downloaded;
      });
    }
  }

  Future<void> _toggleOfflineDownload() async {
    setState(() {
      _isSavingOffline = true;
    });

    if (_isOfflineSaved) {
      await OfflineManager.removeOfflineVideo(widget.video.id);
      if (mounted) {
        setState(() {
          _isOfflineSaved = false;
          _isSavingOffline = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.languageCode == 'am'
                ? 'ቪዲዮው ከመስመር ውጭ ዝርዝር ተሰርዟል'
                : 'Video removed from offline library'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      await OfflineManager.saveOfflineVideo(widget.video);
      if (mounted) {
        setState(() {
          _isOfflineSaved = true;
          _isSavingOffline = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.languageCode == 'am'
                ? 'ቪዲዮው ከመስመር ውጭ ዝግጁ ሆኗል!'
                : 'Video saved for offline learning!'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLight = !widget.isDarkMode;
    final bool isAmharic = widget.languageCode == 'am';
    final Color bgColor = isLight ? Colors.white : const Color(0xFF1E293B);
    final Color textColor =
        isLight ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final Color subColor =
        isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

    // Responsive embed HTML for YouTube unlisted / embedded player with smooth in-app integration (height reduced by 12%)
    final String youtubeEmbedHtml = '''
      <div style="position: relative; padding-bottom: 49.5%; height: 0; overflow: hidden; border-radius: 16px; background-color: #000000; box-shadow: 0 10px 25px rgba(0,0,0,0.3);">
        <iframe 
          src="https://www.youtube.com/embed/${widget.video.youtubeVideoId}?autoplay=1&playsinline=1&enablejsapi=1&rel=0&modestbranding=1" 
          frameborder="0" 
          allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" 
          allowfullscreen
          style="position: absolute; top: 0; left: 0; width: 100%; height: 100%; border: 0; border-radius: 16px;">
        </iframe>
      </div>
    ''';

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: isLight ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // Header with close button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Color(0xFFEF4444),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAmharic ? 'የቪዲዮ ትምህርት ማጫወቻ' : 'In-App Video Lesson',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                      Text(
                        'Grade ${widget.video.grade} • ${widget.video.subject} • Unit ${widget.video.unitNumber} • Part ${widget.video.partNumber}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: subColor,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close_rounded,
                    color: isLight ? const Color(0xFF64748B) : Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1),

          // Main video content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // YouTube Embedded Player
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: HtmlWidget(
                      youtubeEmbedHtml,
                      renderMode: RenderMode.column,
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Video Title & Duration badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.video.title,
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                            height: 1.35,
                          ),
                        ),
                      ),
                      if (widget.video.durationText != null) ...[
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isLight
                                ? const Color(0xFFF1F5F9)
                                : const Color(0xFF334155),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                size: 14,
                                color: subColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.video.durationText!,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: subColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Subject, Grade, & Part tags
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildChip(
                        label: 'Grade ${widget.video.grade}',
                        color: const Color(0xFF3B82F6),
                        isLight: isLight,
                      ),
                      _buildChip(
                        label: widget.video.subject,
                        color: const Color(0xFF10B981),
                        isLight: isLight,
                      ),
                      _buildChip(
                        label: 'Unit ${widget.video.unitNumber}',
                        color: const Color(0xFF8B5CF6),
                        isLight: isLight,
                      ),
                      _buildChip(
                        label: 'Part ${widget.video.partNumber}',
                        color: const Color(0xFFEC4899),
                        isLight: isLight,
                      ),
                      _buildChip(
                        label: isAmharic ? 'የተረጋገጠ ይዘት' : 'Curriculum Verified',
                        color: const Color(0xFFF59E0B),
                        isLight: isLight,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Download for Offline Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isSavingOffline ? null : _toggleOfflineDownload,
                      icon: _isSavingOffline
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              _isOfflineSaved
                                  ? Icons.cloud_done_rounded
                                  : Icons.download_for_offline_rounded,
                              size: 18,
                              color: _isOfflineSaved
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF0084FF),
                            ),
                      label: Text(
                        _isOfflineSaved
                            ? (isAmharic
                                ? 'ከመስመር ውጭ ወርዷል (Downloaded)'
                                : 'Available Offline')
                            : (isAmharic
                                ? 'ከመስመር ውጭ ለማየት አውርድ'
                                : 'Download for Offline'),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: _isOfflineSaved
                              ? const Color(0xFF10B981)
                              : const Color(0xFF0084FF),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: _isOfflineSaved
                              ? const Color(0xFF10B981)
                              : const Color(0xFF0084FF).withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // In-App Learning Action: Telegram Discussion / Ask Tutor
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final msg = Uri.encodeComponent(
                            'ሰላም ኢትዮ ኮንሴፕት ሴንተር፣ ስለ Grade ${widget.video.grade} ${widget.video.subject} Unit ${widget.video.unitNumber} Part ${widget.video.partNumber} (${widget.video.title}) ጥያቄ አለኝ።');
                        final uri = Uri.parse(
                            'https://t.me/EthioconceptcenterAcademy?text=$msg');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri,
                              mode: LaunchMode.externalApplication);
                        }
                      },
                      icon: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                      label: Text(
                        isAmharic ? 'መምህራንን በቴሌግራም ጥያቄ ጠይቅ' : 'Ask Tutor on Telegram',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Tips card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isLight
                          ? const Color(0xFFF8FAFC)
                          : const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isLight
                            ? const Color(0xFFE2E8F0)
                            : const Color(0xFF334155),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.lightbulb_outline_rounded,
                          color: Color(0xFFF59E0B),
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isAmharic ? 'የማጥናት ምክር' : 'Smart Study Tip',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isAmharic
                                    ? 'ቪዲዮውን እየተመለከቱ አጫጭር ማስታወሻዎችን ይያዙ። ከጨረሱ በኋላ በ"ጥያቄዎች" ክፍል ውስጥ የዚህን ዩኒት ሞዴል ፈተና ይስሩ።'
                                    : 'Take summary notes while watching the concept walkthrough. Test your understanding immediately by taking the unit quiz in the Quizzes tab!',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: subColor,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required Color color,
    required bool isLight,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isLight ? 0.12 : 0.22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
