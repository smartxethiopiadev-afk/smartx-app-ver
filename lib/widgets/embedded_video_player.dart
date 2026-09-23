import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

/// Embedded in-app video player widget for streaming Supabase Storage videos directly.
class EmbeddedVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String title;
  final String? subtitle;
  final String? thumbnailUrl;
  final bool isDarkMode;
  final String languageCode;
  final bool autoPlay;
  final VoidCallback? onClose;

  const EmbeddedVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.title,
    this.subtitle,
    this.thumbnailUrl,
    required this.isDarkMode,
    required this.languageCode,
    this.autoPlay = true,
    this.onClose,
  });

  @override
  State<EmbeddedVideoPlayer> createState() => _EmbeddedVideoPlayerState();
}

class _EmbeddedVideoPlayerState extends State<EmbeddedVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _showControls = true;
  Timer? _hideControlsTimer;
  double _playbackSpeed = 1.0;
  bool _isMuted = false;
  bool _isFullscreen = false;

  final List<double> _availableSpeeds = [0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void didUpdateWidget(covariant EmbeddedVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _disposePlayer();
      _initializePlayer();
    }
  }

  Future<void> _initializePlayer() async {
    setState(() {
      _isInitialized = false;
      _hasError = false;
      _errorMessage = '';
    });

    final String url = widget.videoUrl.trim();
    if (url.isEmpty) {
      setState(() {
        _hasError = true;
        _errorMessage = widget.languageCode == 'am'
            ? 'የቪዲዮ ማጫወቻ አድራሻ አልተገኘም።'
            : 'No streaming video URL provided.';
      });
      return;
    }

    try {
      final uri = Uri.parse(url);
      _controller = VideoPlayerController.networkUrl(uri);

      await _controller!.initialize();
      _controller!.addListener(_onPlayerStateChanged);

      if (widget.autoPlay) {
        await _controller!.play();
      }

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _startHideControlsTimer();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = widget.languageCode == 'am'
              ? 'ቪዲዮውን ከ Supabase ማጫወት አልተቻለም። እባክዎ የበይነመረብ ግንኙነትዎን ያረጋግጡ።'
              : 'Failed to stream video from Supabase Storage. Please check your connection.';
        });
      }
    }
  }

  void _onPlayerStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _disposePlayer() {
    _hideControlsTimer?.cancel();
    _controller?.removeListener(_onPlayerStateChanged);
    _controller?.dispose();
    _controller = null;
  }

  @override
  void dispose() {
    _disposePlayer();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_controller!.value.isPlaying) {
      _controller!.pause();
      _showControlsTemporarily();
    } else {
      _controller!.play();
      _startHideControlsTimer();
    }
  }

  void _seekRelative(int seconds) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    final currentPos = _controller!.value.position;
    final target = currentPos + Duration(seconds: seconds);
    final total = _controller!.value.duration;

    if (target < Duration.zero) {
      _controller!.seekTo(Duration.zero);
    } else if (target > total) {
      _controller!.seekTo(total);
    } else {
      _controller!.seekTo(target);
    }
    _showControlsTemporarily();
  }

  void _toggleMute() {
    if (_controller == null) return;
    setState(() {
      _isMuted = !_isMuted;
      _controller!.setVolume(_isMuted ? 0.0 : 1.0);
    });
    _showControlsTemporarily();
  }

  void _cyclePlaybackSpeed() {
    if (_controller == null) return;
    final int nextIdx = (_availableSpeeds.indexOf(_playbackSpeed) + 1) % _availableSpeeds.length;
    final double nextSpeed = _availableSpeeds[nextIdx];
    setState(() {
      _playbackSpeed = nextSpeed;
    });
    _controller!.setPlaybackSpeed(nextSpeed);
    _showControlsTemporarily();
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _controller != null && _controller!.value.isPlaying) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _showControlsTemporarily() {
    setState(() {
      _showControls = true;
    });
    _startHideControlsTimer();
  }

  void _toggleControlsVisibility() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls && _controller != null && _controller!.value.isPlaying) {
      _startHideControlsTimer();
    } else {
      _hideControlsTimer?.cancel();
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      final hours = d.inHours.toString().padLeft(2, '0');
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final bool isAm = widget.languageCode == 'am';
    final bool isLight = !widget.isDarkMode;
    final Color bgColor = isLight ? const Color(0xFF0F172A) : const Color(0xFF020617);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(_isFullscreen ? 0 : 20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Video Surface with 16:9 Aspect Ratio
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 1. Video Player Surface
                if (_isInitialized && _controller != null)
                  GestureDetector(
                    onTap: _toggleControlsVisibility,
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: _controller!.value.aspectRatio > 0
                            ? _controller!.value.aspectRatio
                            : 16 / 9,
                        child: VideoPlayer(_controller!),
                      ),
                    ),
                  )
                else if (_hasError)
                  _buildErrorSurface(isAm)
                else
                  _buildLoadingSurface(isAm),

                // 2. Interactive Controls Overlay
                if (_isInitialized && _controller != null)
                  AnimatedOpacity(
                    opacity: _showControls ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 250),
                    child: IgnorePointer(
                      ignoring: !_showControls,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.7),
                              Colors.black.withValues(alpha: 0.2),
                              Colors.black.withValues(alpha: 0.8),
                            ],
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Top Bar (Title & Close)
                            _buildTopBar(),

                            // Center Transport Controls (Rewind, Play/Pause, Forward)
                            _buildCenterControls(),

                            // Bottom Bar (Scrubber, Timestamps, Speed, Volume)
                            _buildBottomControls(),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Video Meta Header below player (when not in full screen)
          if (!_isFullscreen && widget.title.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: isLight ? Colors.white : const Color(0xFF1E293B),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.play_circle_fill_rounded,
                      color: Color(0xFF0284C7),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isLight ? const Color(0xFF0F172A) : Colors.white,
                          ),
                        ),
                        if (widget.subtitle != null && widget.subtitle!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.notoSansEthiopic(
                              fontSize: 11.5,
                              color: isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_done_rounded, size: 12, color: Color(0xFF10B981)),
                        const SizedBox(width: 4),
                        Text(
                          'Supabase Stream',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
              ),
            ),
          ),
          if (widget.onClose != null)
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
              onPressed: widget.onClose,
              tooltip: 'Close',
            ),
        ],
      ),
    );
  }

  Widget _buildCenterControls() {
    final bool isPlaying = _controller?.value.isPlaying ?? false;
    final bool isCompleted = _controller != null &&
        _controller!.value.position >= _controller!.value.duration &&
        _controller!.value.duration > Duration.zero;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Rewind 10s
        IconButton(
          onPressed: () => _seekRelative(-10),
          icon: const Icon(Icons.replay_10_rounded, color: Colors.white, size: 30),
          tooltip: 'Rewind 10s',
        ),
        const SizedBox(width: 20),

        // Play / Pause / Replay
        GestureDetector(
          onTap: isCompleted
              ? () {
                  _controller?.seekTo(Duration.zero);
                  _controller?.play();
                  _showControlsTemporarily();
                }
              : _togglePlayPause,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF0284C7),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.6),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              isCompleted
                  ? Icons.replay_rounded
                  : (isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
              color: Colors.white,
              size: 34,
            ),
          ),
        ),
        const SizedBox(width: 20),

        // Forward 10s
        IconButton(
          onPressed: () => _seekRelative(10),
          icon: const Icon(Icons.forward_10_rounded, color: Colors.white, size: 30),
          tooltip: 'Forward 10s',
        ),
      ],
    );
  }

  Widget _buildBottomControls() {
    final position = _controller?.value.position ?? Duration.zero;
    final duration = _controller?.value.duration ?? Duration.zero;

    final double progress = duration.inMilliseconds > 0
        ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Scrubber Bar
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3.5,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              activeTrackColor: const Color(0xFF0284C7),
              inactiveTrackColor: Colors.white24,
              thumbColor: Colors.white,
              overlayColor: const Color(0xFF0284C7).withValues(alpha: 0.3),
            ),
            child: Slider(
              value: progress,
              onChanged: (val) {
                final targetMs = (val * duration.inMilliseconds).toInt();
                _controller?.seekTo(Duration(milliseconds: targetMs));
                _showControlsTemporarily();
              },
            ),
          ),

          // Bottom Toolbar (Time + Speed + Volume)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Timestamps
                Text(
                  '${_formatDuration(position)} / ${_formatDuration(duration)}',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Speed Selector
                    InkWell(
                      onTap: _cyclePlaybackSpeed,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${_playbackSpeed}x',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Mute Toggle
                    IconButton(
                      icon: Icon(
                        _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: _toggleMute,
                      tooltip: _isMuted ? 'Unmute' : 'Mute',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSurface(bool isAm) {
    return Container(
      color: const Color(0xFF0F172A),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 38,
              height: 38,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0284C7)),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              isAm ? 'ቪዲዮው ከ Supabase በመጫን ላይ ነው...' : 'Streaming from Supabase Storage...',
              style: GoogleFonts.notoSansEthiopic(
                fontSize: 12,
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorSurface(bool isAm) {
    return Container(
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.all(18),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: Color(0xFFF59E0B), size: 36),
            const SizedBox(height: 10),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansEthiopic(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _initializePlayer,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(
                isAm ? 'እንደገና ሞክር' : 'Retry',
                style: GoogleFonts.notoSansEthiopic(fontWeight: FontWeight.w800, fontSize: 12),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
