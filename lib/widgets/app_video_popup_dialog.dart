import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import '../models/video_model.dart';
import '../screens/fullscreen_video_player_screen.dart';
import '../services/video_service.dart';
import 'account_upgrade_dialog.dart';

/// Clean, YouTube-style In-Place Video Pop-up Modal Dialog
/// Plays videos smoothly in-app over the current screen with rich actions.
class AppVideoPopupDialog extends StatefulWidget {
  final VideoModel? video;
  final String? customTitle;
  final String? customSubtitle;
  final int? grade;
  final String? subject;
  final int? unitNumber;
  final bool isDarkMode;
  final String languageCode;
  final VoidCallback? onUnlocked;

  const AppVideoPopupDialog({
    super.key,
    this.video,
    this.customTitle,
    this.customSubtitle,
    this.grade,
    this.subject,
    this.unitNumber,
    required this.isDarkMode,
    required this.languageCode,
    this.onUnlocked,
  });

  /// Opens the YouTube-like pop-up video player dialog over the current screen
  static Future<void> show(
    BuildContext context, {
    VideoModel? video,
    String? customTitle,
    String? customSubtitle,
    int? grade,
    String? subject,
    int? unitNumber,
    required bool isDarkMode,
    required String languageCode,
    VoidCallback? onUnlocked,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.78),
      builder: (ctx) => AppVideoPopupDialog(
        video: video,
        customTitle: customTitle,
        customSubtitle: customSubtitle,
        grade: grade,
        subject: subject,
        unitNumber: unitNumber,
        isDarkMode: isDarkMode,
        languageCode: languageCode,
        onUnlocked: onUnlocked,
      ),
    );
  }

  @override
  State<AppVideoPopupDialog> createState() => _AppVideoPopupDialogState();
}

class _AppVideoPopupDialogState extends State<AppVideoPopupDialog> {
  VideoPlayerController? _controller;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isPlaying = false;
  bool _showControls = true;
  Timer? _hideControlsTimer;
  VideoModel? _resolvedVideo;

  @override
  void initState() {
    super.initState();
    _loadAndInitialize();
  }

  Future<void> _loadAndInitialize() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      VideoModel videoToUse;
      if (widget.video != null) {
        videoToUse = widget.video!;
      } else {
        videoToUse = await VideoService.fetchAppTutorialVideo();
      }

      _resolvedVideo = videoToUse;
      final String streamUrl = videoToUse.streamUrl.isNotEmpty
          ? videoToUse.streamUrl
          : (videoToUse.videoUrl ?? '');

      if (streamUrl.isNotEmpty) {
        final uri = Uri.parse(streamUrl.trim());
        _controller = VideoPlayerController.networkUrl(uri);
        await _controller!.initialize();
        _controller!.addListener(_onControllerUpdate);
        await _controller!.play();
        _isPlaying = true;
      }
    } catch (_) {
      _hasError = true;
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _startHideControlsTimer();
      }
    }
  }

  void _onControllerUpdate() {
    if (mounted && _controller != null) {
      final isCurrentlyPlaying = _controller!.value.isPlaying;
      if (_isPlaying != isCurrentlyPlaying) {
        setState(() {
          _isPlaying = isCurrentlyPlaying;
        });
      }
    }
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _isPlaying) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _togglePlayPause() {
    if (_controller == null || !_controller!.value.isInitialized) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        _isPlaying = false;
        _showControls = true;
      } else {
        _controller!.play();
        _isPlaying = true;
        _startHideControlsTimer();
      }
    });
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _controller?.removeListener(_onControllerUpdate);
    _controller?.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _launchTelegram() async {
    final uri = Uri.parse('https://t.me/smart_x_help?text=Hello%20Admin%2C%20I%20want%20to%20upgrade%20my%20account%20on%20Smart%20Learn');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  void _openUpgradeModal() {
    _controller?.pause();
    Navigator.of(context).pop();
    AccountUpgradeDialog.show(
      context,
      isDarkMode: widget.isDarkMode,
      languageCode: widget.languageCode,
      initialGrade: widget.grade ?? _resolvedVideo?.grade ?? 12,
      onSuccess: widget.onUnlocked,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isAm = widget.languageCode == 'am';
    final bool isLight = !widget.isDarkMode;
    final Color dialogBg = isLight ? Colors.white : const Color(0xFF0F172A);
    final Color textPrimary = isLight ? const Color(0xFF0F172A) : Colors.white;
    final Color textSecondary = isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

    final String displayTitle = widget.customTitle ??
        (_resolvedVideo?.title.isNotEmpty == true
            ? _resolvedVideo!.title
            : (isAm ? '🎬 የመተግበሪያ አጠቃቀም እና ምዝገባ መመሪያ' : '🎬 App Overview & How to Start'));

    final String displaySubtitle = widget.customSubtitle ??
        (isAm
            ? 'ቪዲዮውን በመመልከት አካውንትዎን በቀላሉ ያሻሽሉ'
            : 'Watch step-by-step video guide to unlock your account.');

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 460),
        decoration: BoxDecoration(
          color: dialogBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFF0284C7).withValues(alpha: 0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0284C7).withValues(alpha: 0.25),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0B132B),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.smart_display_rounded, size: 14, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              isAm ? 'የቪዲዮ መመሪያ' : 'VIDEO GUIDE',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 22),
                        color: textSecondary,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),

                // YouTube-Style 16:9 Video Player Frame
                Container(
                  width: double.infinity,
                  color: Colors.black,
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Video Player or Loading / Placeholder Frame
                        if (!_hasError && _controller != null && _controller!.value.isInitialized)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _showControls = !_showControls;
                              });
                              if (_showControls && _isPlaying) {
                                _startHideControlsTimer();
                              }
                            },
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: SizedBox(
                                width: _controller!.value.size.width,
                                height: _controller!.value.size.height,
                                child: VideoPlayer(_controller!),
                              ),
                            ),
                          )
                        else if (_isLoading)
                          Container(
                            color: const Color(0xFF0F172A),
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0284C7)),
                              ),
                            ),
                          )
                        else
                          // Fallback Thumbnail / Coming Soon Card
                          Container(
                            color: const Color(0xFF0F172A),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                if (_resolvedVideo?.thumbnailUrl.isNotEmpty == true)
                                  Image.network(
                                    _resolvedVideo!.thumbnailUrl,
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const SizedBox(),
                                  ),
                                Container(
                                  color: Colors.black.withValues(alpha: 0.5),
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFF0284C7).withValues(alpha: 0.9),
                                      ),
                                      child: const Icon(
                                        Icons.play_arrow_rounded,
                                        color: Colors.white,
                                        size: 34,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      isAm ? 'ቪዲዮው በዝግጅት ላይ ነው' : 'Video Tutorial Coming Soon',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                        // Video Controls Overlay (Like YouTube)
                        if (_controller != null && _controller!.value.isInitialized && _showControls)
                          Container(
                            color: Colors.black.withValues(alpha: 0.45),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Top overlay actions (Fullscreen Expand)
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 26),
                                        onPressed: () {
                                          final String streamUrl = _resolvedVideo?.streamUrl.isNotEmpty == true
                                              ? _resolvedVideo!.streamUrl
                                              : (_resolvedVideo?.videoUrl ?? '');
                                          if (streamUrl.isNotEmpty) {
                                            _controller?.pause();
                                            FullscreenVideoPlayerScreen.open(
                                              context,
                                              videoUrl: streamUrl,
                                              title: displayTitle,
                                              subtitle: displaySubtitle,
                                              isDarkMode: widget.isDarkMode,
                                              languageCode: widget.languageCode,
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),

                                // Center Play / Pause button
                                GestureDetector(
                                  onTap: _togglePlayPause,
                                  child: Container(
                                    width: 54,
                                    height: 54,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFF0284C7).withValues(alpha: 0.9),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF0284C7).withValues(alpha: 0.5),
                                          blurRadius: 16,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                      color: Colors.white,
                                      size: 36,
                                    ),
                                  ),
                                ),

                                // Bottom Progress bar & timer
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  child: Row(
                                    children: [
                                      Text(
                                        _formatDuration(_controller!.value.position),
                                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                                      ),
                                      Expanded(
                                        child: SliderTheme(
                                          data: SliderTheme.of(context).copyWith(
                                            trackHeight: 3.0,
                                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                                            activeTrackColor: const Color(0xFF0284C7),
                                            inactiveTrackColor: Colors.white24,
                                            thumbColor: const Color(0xFF00BFFF),
                                          ),
                                          child: Slider(
                                            value: _controller!.value.position.inMilliseconds
                                                .clamp(0, _controller!.value.duration.inMilliseconds)
                                                .toDouble(),
                                            min: 0.0,
                                            max: (_controller!.value.duration.inMilliseconds.toDouble() > 0)
                                                ? _controller!.value.duration.inMilliseconds.toDouble()
                                                : 1.0,
                                            onChanged: (val) {
                                              _controller!.seekTo(Duration(milliseconds: val.toInt()));
                                            },
                                          ),
                                        ),
                                      ),
                                      Text(
                                        _formatDuration(_controller!.value.duration),
                                        style: const TextStyle(color: Colors.white70, fontSize: 11),
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

                // Video Info & Details
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        displayTitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: textPrimary,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        displaySubtitle,
                        style: GoogleFonts.notoSansEthiopic(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                          height: 1.35,
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Action Buttons (Upgrade & Verification + Contact Admin)
                      // 1. Upgrade & Verification Button
                      Container(
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0284C7), Color(0xFF00BFFF)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: _openUpgradeModal,
                          icon: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 20),
                          label: Text(
                            isAm ? '🔑 አካውንት ያሻሽሉ / ማረጋገጫ' : '🔑 Verify & Upgrade Account',
                            style: GoogleFonts.notoSansEthiopic(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // 2. Telegram Contact Admin Button
                      Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: const Color(0xFF229ED9).withValues(alpha: isLight ? 0.12 : 0.18),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFF229ED9).withValues(alpha: 0.4),
                            width: 1.2,
                          ),
                        ),
                        child: TextButton.icon(
                          onPressed: _launchTelegram,
                          icon: const Icon(Icons.send_rounded, color: Color(0xFF229ED9), size: 18),
                          label: Text(
                            isAm ? '💬 አድሚኑን በቴሌግራም አነጋግር (@smart_x_help)' : '💬 Contact Admin Telegram (@smart_x_help)',
                            style: GoogleFonts.notoSansEthiopic(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF229ED9),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
