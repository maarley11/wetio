import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class ProfilePhotoSectionWidget extends StatefulWidget {
  final Function(String imagePath) onPhotoSelected;
  final bool isLoading;

  const ProfilePhotoSectionWidget({
    super.key,
    required this.onPhotoSelected,
    this.isLoading = false,
  });

  @override
  State<ProfilePhotoSectionWidget> createState() =>
      _ProfilePhotoSectionWidgetState();
}

class _ProfilePhotoSectionWidgetState extends State<ProfilePhotoSectionWidget> {
  String? _selectedImagePath;
  final ImagePicker _picker = ImagePicker();

  Future<bool> _requestCameraPermission() async {
    if (kIsWeb) return true;

    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<bool> _requestStoragePermission() async {
    if (kIsWeb) return true;

    final status = await Permission.storage.request();
    return status.isGranted;
  }

  Future<void> _showPhotoOptions() async {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 25.5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40.0,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            SizedBox(height: 17.0),

            Text(
              'Choisir une photo de profil',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 25.5),

            // Camera option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomIconWidget(
                  iconName: 'camera_alt',
                  color: colorScheme.primary,
                  size: 24,
                ),
              ),
              title: Text(
                'Appareil photo',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
              ),
              subtitle: Text(
                'Prendre une nouvelle photo',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromCamera();
              },
            ),

            // Gallery option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomIconWidget(
                  iconName: 'photo_library',
                  color: colorScheme.primary,
                  size: 24,
                ),
              ),
              title: Text(
                'Galerie',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
              ),
              subtitle: Text(
                'Choisir depuis la galerie',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery();
              },
            ),

            if (_selectedImagePath != null)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CustomIconWidget(
                    iconName: 'delete',
                    color: colorScheme.error,
                    size: 24,
                  ),
                ),
                title: Text(
                  'Supprimer la photo',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.error,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _removePhoto();
                },
              ),

            SizedBox(height: 17.0),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageFromCamera() async {
    try {
      if (!await _requestCameraPermission()) {
        _showPermissionDeniedMessage('appareil photo');
        return;
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (image != null) {
        await _cropAndSetImage(image.path);
      }
    } catch (e) {
      _showErrorMessage('Erreur lors de la prise de photo');
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      if (!await _requestStoragePermission()) {
        _showPermissionDeniedMessage('galerie');
        return;
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (image != null) {
        await _cropAndSetImage(image.path);
      }
    } catch (e) {
      _showErrorMessage('Erreur lors de la sélection d\'image');
    }
  }

  Future<void> _cropAndSetImage(String imagePath) async {
    try {
      // Use image directly without cropping (web-compatible)
      setState(() {
        _selectedImagePath = imagePath;
      });
      widget.onPhotoSelected(imagePath);
      HapticFeedback.lightImpact();
    } catch (e) {
      _showErrorMessage('Erreur lors du traitement de l\'image');
    }
  }

  void _removePhoto() {
    setState(() {
      _selectedImagePath = null;
    });
    widget.onPhotoSelected('');
    HapticFeedback.lightImpact();
  }

  void _showPermissionDeniedMessage(String permission) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Permission $permission requise pour cette fonctionnalité',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(fontSize: 14),
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Photo de profil',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),

        SizedBox(height: 8.5),

        Text(
          'Optionnelle - vous pouvez l\'ajouter plus tard',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: 17.0),

        // Photo display/selector
        GestureDetector(
          onTap: widget.isLoading ? null : _showPhotoOptions,
          child: Container(
            width: 120.0,
            height: 120.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: colorScheme.outline,
                width: 2,
              ),
              color: _selectedImagePath != null
                  ? Colors.transparent
                  : colorScheme.surface,
            ),
            child: _selectedImagePath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(60.0),
                    child: kIsWeb
                        ? Image.network(
                            _selectedImagePath!,
                            width: 120.0,
                            height: 120.0,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildPlaceholder(colorScheme);
                            },
                          )
                        : _buildMobileFileImage(colorScheme),
                  )
                : _buildPlaceholder(colorScheme),
          ),
        ),

        SizedBox(height: 8.5),

        GestureDetector(
          onTap: widget.isLoading ? null : _showPhotoOptions,
          child: Text(
            _selectedImagePath != null
                ? 'Modifier la photo'
                : 'Ajouter une photo',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colorScheme.primary,
              decoration: TextDecoration.underline,
              decorationColor: colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder(ColorScheme colorScheme) {
    return Center(
      child: CustomIconWidget(
        iconName: 'add_a_photo',
        color: colorScheme.onSurfaceVariant,
        size: 32.0.toDouble(),
      ),
    );
  }

  Widget _buildMobileFileImage(ColorScheme colorScheme) {
    // Use Image.network as fallback — on mobile, XFile.path can be used as network path via image_picker
    // We avoid dart:io import entirely for web compatibility
    return Image.asset(
      _selectedImagePath!,
      width: 120.0,
      height: 120.0,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return _buildPlaceholder(colorScheme);
      },
    );
  }
}
