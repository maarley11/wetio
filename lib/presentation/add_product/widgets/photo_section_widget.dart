import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PhotoSectionWidget extends StatefulWidget {
  final List<XFile> selectedImages;
  final Function(List<XFile>) onImagesChanged;

  const PhotoSectionWidget({
    super.key,
    required this.selectedImages,
    required this.onImagesChanged,
  });

  @override
  State<PhotoSectionWidget> createState() => _PhotoSectionWidgetState();
}

class _PhotoSectionWidgetState extends State<PhotoSectionWidget> {
  final ImagePicker _picker = ImagePicker();

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              if (!kIsWeb)
                ListTile(
                  leading: CustomIconWidget(
                    iconName: 'camera_alt',
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 24,
                  ),
                  title: Text(
                    'Prendre une photo',
                    style: AppTheme.lightTheme.textTheme.bodyMedium,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickFromCamera();
                  },
                ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'photo_library',
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 24,
                ),
                title: Text(
                  'Choisir depuis la galerie',
                  style: AppTheme.lightTheme.textTheme.bodyMedium,
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromGallery();
                },
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'close',
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  size: 24,
                ),
                title: Text(
                  'Annuler',
                  style: AppTheme.lightTheme.textTheme.bodyMedium,
                ),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (image != null) {
        final updatedImages = List<XFile>.from(widget.selectedImages)
          ..add(image);
        widget.onImagesChanged(updatedImages);
      }
    } catch (e) {
      debugPrint('Camera error: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (images.isNotEmpty) {
        final updatedImages = List<XFile>.from(widget.selectedImages)
          ..addAll(images);
        widget.onImagesChanged(updatedImages);
      }
    } catch (e) {
      debugPrint('Gallery picker error: $e');
    }
  }

  void _removeImage(int index) {
    final updatedImages = List<XFile>.from(widget.selectedImages)
      ..removeAt(index);
    widget.onImagesChanged(updatedImages);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Photos du produit',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 17.0),
        widget.selectedImages.isEmpty
            ? _buildPhotoPlaceholder()
            : _buildImageGrid(),
        if (widget.selectedImages.isNotEmpty) ...[
          SizedBox(height: 17.0),
          _buildAddMoreButton(),
        ],
      ],
    );
  }

  Widget _buildPhotoPlaceholder() {
    return GestureDetector(
      onTap: _showImageSourceActionSheet,
      child: Container(
        width: double.infinity,
        height: 170.0,
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.lightTheme.colorScheme.outline,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'add_photo_alternate',
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 48,
            ),
            SizedBox(height: 8.5),
            Text(
              'Ajouter des photos',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 4.3),
            Text(
              'Appuyez pour sélectionner',
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGrid() {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.selectedImages.length,
      onReorder: (oldIndex, newIndex) {
        if (newIndex > oldIndex) newIndex -= 1;
        final updatedImages = List<XFile>.from(widget.selectedImages);
        final item = updatedImages.removeAt(oldIndex);
        updatedImages.insert(newIndex, item);
        widget.onImagesChanged(updatedImages);
      },
      itemBuilder: (context, index) {
        final image = widget.selectedImages[index];
        return Stack(
          key: ValueKey(image.path),
          children: [
            Container(
              margin: EdgeInsets.only(bottom: 8.5),
              height: 170.0,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppTheme.lightTheme.colorScheme.surface,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: kIsWeb
                    ? Image.network(
                        image.path,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => _buildImageError(),
                      )
                    : Image.asset(
                        image.path,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => _buildImageError(),
                      ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => _removeImage(index),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildImageError() {
    return Container(
      color: AppTheme.lightTheme.colorScheme.surface,
      child: Center(
        child: CustomIconWidget(
          iconName: 'broken_image',
          color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          size: 48,
        ),
      ),
    );
  }

  Widget _buildAddMoreButton() {
    return GestureDetector(
      onTap: _showImageSourceActionSheet,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 12.8),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.lightTheme.colorScheme.primary.withAlpha(128),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'add_photo_alternate',
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 20,
            ),
            SizedBox(width: 8.0),
            Text(
              'Ajouter plus de photos',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
