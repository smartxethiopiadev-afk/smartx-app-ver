import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/video_model.dart';
import '../services/video_service.dart';
import '../widgets/youtube_video_player_dialog.dart';
import '../services/offline_manager.dart';

class VideoLessonScreen extends StatefulWidget {
  final int grade;
  final String subject;
  final int unitNumber;
  final String unitTitle;
  final bool isDarkMode;
  final String languageCode;

  const VideoLessonScreen({
    super.key,
    required this.grade,
    required this.subject,
    required this.unitNumber,
    required this.unitTitle,
    required this.isDarkMode,
    required this.languageCode,
  });

  @override
  State<VideoLessonScreen> createState() => _VideoLessonScreenState();
}

class _VideoLessonScreenState extends State<VideoLessonScreen> {
  bool _isLoading = true;
  List<VideoModel> _videos = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await VideoService.fetchVideos(
        grade: widget.grade,
        subject: widget.subject,
        unit: widget.unitNumber,
      );

      if (mounted) {
        setState(() {
          _videos = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _playVideo(VideoModel video) {
    YouTubeVideoPlayerDialog.show(
      context,
      video: video,
      isDarkMode: widget.isDarkMode,
      languageCode: widget.languageCode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isAm = widget.languageCode == 'am';
    final bool isLight = !widget.isDarkMode;

    final Color bgColor = isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final Color cardBg = isLight ? Colors.white : const Color(0xFF1E293B);
    final Color textColor = isLight ? const Color(0xFF0F172A) : Colors.white;
    final Color subColor = isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    final Color borderColor = isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155);
    const Color primaryColor = Color(0xFF0284C7);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAm
                  ? '${widget.grade}ኛ ክፍል • ${widget.subject}'
                  : 'Grade ${widget.grade} • ${widget.subject}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            Text(
              widget.unitTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.notoSansEthiopic(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: subColor,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: textColor),
            tooltip: isAm ? 'እንደገና ጫን' : 'Refresh',
            onPressed: _loadVideos,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: borderColor, height: 1),
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: primaryColor),
                  const SizedBox(height: 16),
                  Text(
                    isAm
                        ? 'የቪዲዮ ትምህርቶች ከዳታቤዝ በመጫን ላይ...'
                        : 'Loading video lessons from database...',
                    style: GoogleFonts.notoSansEthiopic(color: subColor, fontSize: 13),
                  ),
                ],
              ),
            )
          : _videos.isEmpty
              ? Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.video_library_outlined,
                            size: 44,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          isAm
                              ? 'የምዕራፍ ${widget.unitNumber} ቪዲዮ በቅርቡ ይጫናል'
                              : 'Unit ${widget.unitNumber} Video Lessons Coming Soon',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _errorMessage != null
                              ? (isAm ? 'ስህተት ተከስቷል፡ $_errorMessage' : 'Notice: $_errorMessage')
                              : (isAm
                                  ? 'የዚህ ክፍል ቪዲዮ በሱፓቤዝ ዳታቤዝ (Supabase Database/Storage) ገና አልተጫነም። አዲስ ቪዲዮ ሲጨመር ወዲያውኑ እዚህ ይታያል።'
                                  : 'No video lessons have been published for this unit in the Supabase database/storage yet. When uploaded by the academic team, they will stream automatically here.'),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.notoSansEthiopic(
                            fontSize: 13,
                            color: subColor,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loadVideos,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: Text(
                            isAm ? 'ዳታቤዝ ፈትሽ (Refresh)' : 'Check Database for Videos',
                            style: GoogleFonts.notoSansEthiopic(fontWeight: FontWeight.w700),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _videos.length,
                  itemBuilder: (context, index) {
                    final video = _videos[index];
                    final bool hasDirectStream = video.hasDirectStream;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isLight ? 0.03 : 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Video Card Header / Thumbnail Banner
                          Container(
                            height: 140,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF0F172A),
                                  primaryColor.withValues(alpha: 0.85),
                                ],
                                begin: Alignment.bottomLeft,
                                end: Alignment.topRight,
                              ),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Play Icon Button
                                InkWell(
                                  onTap: () => _playVideo(video),
                                  borderRadius: BorderRadius.circular(35),
                                  child: Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.95),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.3),
                                          blurRadius: 14,
                                        ),
                                      ],
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.play_arrow_rounded,
                                        size: 38,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ),
                                ),
                                // Duration Badge
                                Positioned(
                                  right: 12,
                                  bottom: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.75),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.schedule_rounded, size: 12, color: Colors.white),
                                        const SizedBox(width: 4),
                                        Text(
                                          video.durationText ?? '15 mins',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Source Badge (Supabase Storage vs Stream)
                                Positioned(
                                  left: 12,
                                  top: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.9),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.cloud_done_rounded, size: 12, color: Colors.white),
                                        const SizedBox(width: 4),
                                        Text(
                                          hasDirectStream ? 'Supabase Storage' : 'Cloud Stream',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Video Details
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ክፍል ${video.partNumber} • ${video.title}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  isAm
                                      ? 'ይህ ቪዲዮ የ${widget.subject} ምዕራፍ ${widget.unitNumber} ዋና ዋና ፅንሰ-ሀሳቦችን እና ፈተና ተኮር ትንታኔዎችን የያዘ ነው።'
                                      : 'Comprehensive lecture breaking down core syllabus formulas and concepts for this unit.',
                                  style: GoogleFonts.notoSansEthiopic(
                                    fontSize: 12,
                                    color: subColor,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // Action Buttons
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => _playVideo(video),
                                        icon: const Icon(Icons.play_arrow_rounded, size: 18),
                                        label: Text(
                                          isAm ? 'ቪዲዮውን አጫውት' : 'Watch Lesson',
                                          style: GoogleFonts.notoSansEthiopic(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: primaryColor,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    // Offline Download Button
                                    OutlinedButton.icon(
                                      onPressed: () async {
                                        await OfflineManager.saveOfflineVideo(video);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                isAm
                                                    ? 'ቪዲዮው ከመስመር ውጭ ተቀምጧል!'
                                                    : 'Video saved for offline learning!',
                                              ),
                                              backgroundColor: const Color(0xFF10B981),
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                      },
                                      icon: const Icon(Icons.download_rounded, size: 16),
                                      label: Text(
                                        isAm ? 'አውርድ' : 'Save',
                                        style: GoogleFonts.notoSansEthiopic(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: textColor,
                                        side: BorderSide(color: borderColor),
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
