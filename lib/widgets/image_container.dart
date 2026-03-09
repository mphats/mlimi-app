import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/constants/app_colors.dart';

class ImageContainer extends StatefulWidget {
  final String? imageUrl;
  final String placeholderAsset;
  final double size;
  final bool isEditable;
  final VoidCallback? onEdit;
  final File? localImage;

  const ImageContainer({
    super.key,
    this.imageUrl,
    required this.placeholderAsset,
    this.size = 80,
    this.isEditable = false,
    this.onEdit,
    this.localImage,
  });

  @override
  State<ImageContainer> createState() => _ImageContainerState();
}

class _ImageContainerState extends State<ImageContainer> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary,
              width: 2,
            ),
          ),
          child: ClipOval(
            child: _buildImageContent(),
          ),
        ),
        if (widget.isEditable)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(
                  Icons.edit,
                  size: 16,
                  color: Colors.white,
                ),
                onPressed: _showImagePickerOptions,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImageContent() {
    // Show local image if available (for preview before upload)
    if (widget.localImage != null) {
      return Image.file(
        widget.localImage!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder();
        },
      );
    }

    // Show network image if URL is available
    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      return Image.network(
        widget.imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder();
        },
      );
    }

    // Show placeholder
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.surface,
      child: Image.asset(
        widget.placeholderAsset,
        fit: BoxFit.cover,
      ),
    );
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text('Remove'),
                  onTap: () {
                    Navigator.pop(context);
                    // Handle remove action if needed
                  },
                ),
              ListTile(
                title: const Text('Cancel'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await ImagePicker().pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (pickedFile != null) {
        // Notify parent widget about the selected image
        if (widget.onEdit != null) {
          widget.onEdit!();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}