import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

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

    if (imageUrl.startsWith('/')) {
      final fileChild = Image.file(
        File(imageUrl),
        fit: boxFit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) => _placeholder(),
      );
      return borderRadius != null
          ? ClipRRect(borderRadius: borderRadius!, child: fileChild)
          : fileChild;
    }

    final child = CachedNetworkImage(
      imageUrl: imageUrl,
      fit: boxFit,
      width: width,
      height: height,
      placeholder: (context, url) => Shimmer.fromColors(
        baseColor: Colors.grey.shade800,
        highlightColor: Colors.grey.shade600,
        child: Container(color: Colors.grey.shade800),
      ),
      errorWidget: (context, url, error) => _placeholder(),
    );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: child);
    }
    return child;
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
