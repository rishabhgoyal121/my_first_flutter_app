import 'package:flutter/material.dart';

class SafeNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final BorderRadius? borderRadius;
  final Color? placeholderColor;

  const SafeNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.borderRadius,
    this.placeholderColor,
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color:
            placeholderColor ??
            Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: borderRadius,
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.image_outlined,
        color: Theme.of(
          context,
        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
      ),
    );

    final image = Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null)
          return ClipRRect(
            borderRadius: borderRadius ?? BorderRadius.zero,
            child: child,
          );
        return placeholder;
      },
      errorBuilder: (context, error, stackTrace) {
        return placeholder;
      },
    );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }
}
