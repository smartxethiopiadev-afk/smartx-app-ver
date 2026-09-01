import 'package:flutter/material.dart';
import 'app_vector_logo.dart';

/// A robust image widget that loads a network image with timeout & error handling,
/// seamlessly falling back to a local asset image if offline or if loading fails.
class SafeNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final String fallbackAssetPath;
  final Widget? placeholder;
  final bool showOfflineBadge;
  final BorderRadius? borderRadius;

  const SafeNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fallbackAssetPath = 'assets/images/app_icon.png',
    this.placeholder,
    this.showOfflineBadge = false,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final bool isUrlValid = imageUrl.isNotEmpty && 
        (imageUrl.startsWith('http://') || imageUrl.startsWith('https://'));

    Widget imageWidget;

    if (!isUrlValid) {
      imageWidget = _buildFallbackWidget();
    } else {
      imageWidget = Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          if (placeholder != null) return placeholder!;
          return Container(
            width: width,
            height: height,
            color: Colors.grey.withValues(alpha: 0.15),
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackWidget();
        },
      );
    }

    if (borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    if (showOfflineBadge) {
      return Stack(
        children: [
          imageWidget,
          Positioned(
            bottom: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wifi_off_rounded, size: 10, color: Colors.amberAccent),
                  SizedBox(width: 4),
                  Text(
                    'Offline Asset',
                    style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return imageWidget;
  }

  Widget _buildFallbackWidget() {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFF1E293B),
      child: Center(
        child: AppVectorLogo(
          size: width != null ? (width! * 0.45).clamp(24.0, 64.0) : 40.0,
          showGlow: false,
        ),
      ),
    );
  }
}
