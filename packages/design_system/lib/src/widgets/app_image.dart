import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class AppImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit boxFit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const AppImage({
    super.key,
    required this.imageUrl,
    this.boxFit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return _placeholder();
    }

    final dpr = MediaQuery.devicePixelRatioOf(context);

    if (imageUrl.startsWith('/')) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final fileChild = Image.file(
            File(imageUrl),
            fit: boxFit,
            width: width,
            height: height,
            // Decode at display size to avoid huge bitmaps in memory.
            cacheWidth: _decodeWidth(constraints, dpr),
            errorBuilder: (context, error, stackTrace) => _placeholder(),
          );
          return borderRadius != null
              ? ClipRRect(borderRadius: borderRadius!, child: fileChild)
              : fileChild;
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final child = CachedNetworkImage(
          imageUrl: imageUrl,
          fit: boxFit,
          width: width,
          height: height,
          // Cap the in-memory bitmap to the display resolution — full-res
          // backdrops/posters otherwise pile up and OOM-crash on Android.
          memCacheWidth: _decodeWidth(constraints, dpr),
          placeholder: (context, url) => Container(color: Colors.grey.shade900),
          errorWidget: (context, url, error) => _placeholder(),
        );

        if (borderRadius != null) {
          return ClipRRect(borderRadius: borderRadius!, child: child);
        }
        return child;
      },
    );
  }

  /// Target decode width in physical pixels, clamped so a single image can
  /// never decode larger than a full-screen backdrop.
  int? _decodeWidth(BoxConstraints constraints, double dpr) {
    // `width` may be double.infinity (e.g. full-bleed hero); fall back to the
    // real laid-out width from constraints in that case.
    double? logical;
    if (width != null && width!.isFinite && width! > 0) {
      logical = width;
    } else if (constraints.maxWidth.isFinite && constraints.maxWidth > 0) {
      logical = constraints.maxWidth;
    }
    if (logical == null) return null;
    return (logical * dpr).round().clamp(64, 1080);
  }

  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade800,
      child: const Icon(Icons.movie, color: Colors.grey, size: 40),
    );
  }
}
