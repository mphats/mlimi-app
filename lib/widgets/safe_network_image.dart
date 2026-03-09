import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/image_url_processor.dart';

class SafeNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;
  final Widget Function(BuildContext, Widget, ImageChunkEvent?)? loadingBuilder;

  const SafeNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.errorBuilder,
    this.loadingBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildPlaceholder();
    }

    final processedUrl = ImageUrlProcessor.processImageUrl(imageUrl);
    
    // Validate URL format
    if (!ImageUrlProcessor.isValidUrl(processedUrl)) {
      return _buildPlaceholder();
    }

    return Image.network(
      processedUrl,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: errorBuilder ?? (context, error, stackTrace) {
        return _buildPlaceholder();
      },
      loadingBuilder: loadingBuilder ?? (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
            backgroundColor: AppColors.primary.withValues(alpha: 0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: AppColors.primary.withValues(alpha: 0.1),
      child: Icon(
        Icons.person,
        size: width != null && height != null 
            ? (width! < height! ? width! * 0.5 : height! * 0.5)
            : 50,
        color: AppColors.textSecondary,
      ),
    );
  }
}