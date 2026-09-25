import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

/// Fullscreen in-app video player utilizing `video_player` and `chewie`
/// to stream direct Supabase Storage and MP4 URLs with full playback controls.
class FullscreenVideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String title;
  final String? subtitle;
  final bool isDarkMode;
  final String languageCode;
  final bool autoPlay;

  const FullscreenVideoPlayerScreen({
    super.key,
    required this.videoUrl,
    required this.title,
    this.subtitle,
    this.isDarkMode = true,
    this.languageCode = 'en',
    this.autoPlay = true,
  });

  /// Static helper to quickly push the player onto the navigation stack
  static Future<void> open(
    BuildContext context, {
    required String videoUrl,
    required String title,
    String? subtitle,
    bool isDarkMode = true,
    String languageCode = 'en',
    bool autoPlay = true,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FullscreenVideoPlayerScreen(
          videoUrl: videoUrl,
          title: title,
          subtitle: subtitle,
          isDarkMode: isDarkMode,
          languageCode: languageCode,
          autoPlay: autoPlay,
        ),
      ),
    );
  }

  @override
  State<FullscreenVideoPlayerScreen> createState() => _FullscreenVideoPlayerScreenState();
}

class _FullscreenVideoPlayerScreenState extends State<FullscreenVideoPlayerScreen> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final String trimmedUrl = widget.videoUrl.trim();
    if (trimmedUrl.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = widget.languageCode == 'am'
              ? 'የቪዲዮ አድራሻ አልተገኘም። እባክዎ እንደገና ይሞክሩ።'
              : 'Video URL not found. Please try again.';
        });
      }
      return;
    }

    try {
      final uri = Uri.parse(trimmedUrl);
      _videoPlayerController = VideoPlayerController.networkUrl(uri);
      await _videoPlayerController!.initialize();

      final double aspect = _videoPlayerController!.value.isInitialized &&
              _videoPlayerController!.value.aspectRatio > 0
          ? _videoPlayerController!.value.aspectRatio
          : 16 / 9;

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: widget.autoPlay,
        looping: false,
        aspectRatio: aspect,
        autoInitialize: true,
        showControls: true,
        allowFullScreen: true,
        allowMuting: true,
        allowPlaybackSpeedChanging: true,
        playbackSpeeds: const [0.5, 0.75, 1.0, 1.25, 1.5, 2.0],
        materialProgressColors: ChewieProgressColors(
          playedColor: const Color(0xFF00BFFF),
          handleColor: const Color(0xFF00BFFF),
          bufferedColor: Colors.white30,
          backgroundColor: Colors.white12,
        ),
        cupertinoProgressColors: ChewieProgressColors(
          playedColor: const Color(0xFF00BFFF),
          handleColor: const Color(0xFF00BFFF),
          bufferedColor: Colors.white30,
          backgroundColor: Colors.white12,
        ),
        errorBuilder: (context, errorMsg) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_off_rounded, color: Color(0xFFEF4444), size: 48),
                  const SizedBox(height: 12),
                  Text(
                    widget.languageCode == 'am'
                        ? 'ቪዲዮውን መጫን አልተቻለም። እባክዎ የበይነመረብ ግንኙነትዎን ያረጋግጡ።'
                        : 'Could not stream video. Please check your internet connection.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.notoSansEthiopic(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _initializePlayer,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: Text(widget.languageCode == 'am' ? 'እንደገና ሞክር' : 'Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00BFFF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = widget.languageCode == 'am'
              ? 'ቪዲዮውን መክፈት አልተቻለም፡ $e'
              : 'Failed to load video: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    // Restore orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isAm = widget.languageCode == 'am';

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Center Video Area with Chewie
            Center(
              child: _isLoading
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 44,
                          height: 44,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00BFFF)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isAm
                              ? 'ቪዲዮው ከ Supabase በመጫን ላይ ነው...'
                              : 'Streaming video from Supabase Storage...',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : _errorMessage != null
                      ? Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  color: Color(0xFFEF4444), size: 48),
                              const SizedBox(height: 12),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _initializePlayer,
                                icon: const Icon(Icons.refresh_rounded, size: 16),
                                label: Text(isAm ? 'እንደገና ሞክር' : 'Retry'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF00BFFF),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                        )
                      : (_chewieController != null &&
                              _videoPlayerController != null &&
                              _videoPlayerController!.value.isInitialized)
                          ? Chewie(controller: _chewieController!)
                          : const SizedBox.shrink(),
            ),

            // Top Header Overlay Bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.85),
                      Colors.black.withValues(alpha: 0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Row(
                  children: [
                    // Back button with subtle primary touch overlay
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
                      splashColor: const Color(0xFF00BFFF).withValues(alpha: 0.15),
                      highlightColor: Colors.transparent,
                      tooltip: isAm ? 'ተመለስ' : 'Back',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (widget.subtitle != null && widget.subtitle!.isNotEmpty)
                            Text(
                              widget.subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white60,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Supabase Streaming Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00BFFF).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF00BFFF).withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.cloud_done_rounded, color: Color(0xFF00BFFF), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Supabase HD',
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF00BFFF),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
