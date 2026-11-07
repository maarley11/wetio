import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/prebuilt_thumbs.dart';

class CustomImageWidget extends StatelessWidget {
  final String? imageUrl;
  final double width;
  final double height;
  final BoxFit fit;

  /// Optional widget to show when the image fails to load.
  /// If null, a default asset image is shown.
  final Widget? errorWidget;

  const CustomImageWidget({
    Key? key,
    required this.imageUrl,
    this.width = 60,
    this.height = 60,
    this.fit = BoxFit.cover,
    this.errorWidget,
  }) : super(key: key);

  static String resolveOptimizedUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.isEmpty) {
      return 'https://images.unsplash.com/photo-1584824486509-112e4181ff6b?q=80&w=600&auto=format&fit=crop';
    }
    final trimmed = rawUrl.trim();
    final thumbRel = kPrebuiltThumbMap[trimmed];
    if (thumbRel != null) {
      return kIsWeb ? thumbRel : 'https://www.kaywetio.com/$thumbRel';
    }
    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = resolveOptimizedUrl(imageUrl);

    if (kIsWeb) {
      return Image.network(
        resolvedUrl,
        width: width,
        height: height,
        fit: fit,
        alignment: Alignment.center,
        filterQuality: FilterQuality.low,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) {
            return child;
          }
          return Container(
            width: width,
            height: height,
            color: const Color(0xFFF1F3F2),
          );
        },
        errorBuilder: (context, error, stackTrace) =>
            errorWidget ??
            Image.asset(
              "assets/images/no-image.jpg",
              fit: fit,
              width: width,
              height: height,
            ),
      );
    }

    return CachedNetworkImage(
      imageUrl: resolvedUrl,
      width: width,
      height: height,
      fit: fit,
      alignment: Alignment.center,
      fadeInDuration: const Duration(milliseconds: 60),
      fadeOutDuration: Duration.zero,
      memCacheWidth: 480,
      errorWidget: (context, url, error) =>
          errorWidget ??
          Image.asset(
            "assets/images/no-image.jpg",
            fit: fit,
            width: width,
            height: height,
          ),
      placeholder: (context, url) => Container(
        width: width,
        height: height,
        color: const Color(0xFFF1F3F2),
      ),
    );
  }
}
