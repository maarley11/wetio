import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_app_bar.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasChanges = false;

  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  // Avatar
  String? _avatarUrl;
  XFile? _selectedImage;

  // Username availability
  bool _isCheckingUsername = false;
  bool? _usernameAvailable;
  String? _originalUsername;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _usernameController.addListener(_checkUsernameAvailability);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      final profile = await SupabaseService.getCurrentUserProfile();

      if (profile != null) {
        setState(() {
          _nameController.text = profile['full_name'] ?? '';
          _usernameController.text = profile['pseudo'] ?? '';
          _originalUsername = profile['pseudo'] ?? '';
          _bioController.text = profile['bio'] ?? '';
          _phoneController.text = profile['phone'] ?? '';
          _locationController.text = profile['location'] ?? '';
          _avatarUrl = profile['avatar_url'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Erreur lors du chargement des données');
    }
  }

  Future<void> _checkUsernameAvailability() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty || username == _originalUsername) {
      setState(() {
        _usernameAvailable = null;
        _isCheckingUsername = false;
      });
      return;
    }

    setState(() => _isCheckingUsername = true);

    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _usernameAvailable = username.length >= 3;
      _isCheckingUsername = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return Scaffold(
        appBar: CustomAppBar(title: 'Modifier le profil', centerTitle: true),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        if (_hasChanges) {
          return await _showDiscardChangesDialog();
        }
        return true;
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Modifier le profil',
          centerTitle: true,
          actions: [
            if (_hasChanges)
              TextButton(
                onPressed: _isSaving ? null : _saveChanges,
                child: _isSaving
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.primary,
                          ),
                        ),
                      )
                    : Text(
                        'Enregistrer',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
          ],
        ),
        body: Form(
          key: _formKey,
          onChanged: () {
            if (!_hasChanges) {
              setState(() => _hasChanges = true);
            }
          },
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfilePhotoSection(colorScheme),
                SizedBox(height: 34.0),
                _buildNameField(),
                SizedBox(height: 17.0),
                _buildUsernameField(),
                SizedBox(height: 17.0),
                _buildBioField(),
                SizedBox(height: 17.0),
                _buildPhoneField(),
                SizedBox(height: 17.0),
                _buildLocationField(),
                SizedBox(height: 34.0),
                _buildActionButtons(colorScheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePhotoSection(ColorScheme colorScheme) {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 120.0,
            height: 120.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: colorScheme.primary, width: 3),
            ),
            child: ClipOval(
              child: _selectedImage != null
                  ? (kIsWeb 
                      ? Image.network(_selectedImage!.path, fit: BoxFit.cover)
                      : FutureBuilder<Uint8List>(
                          future: _selectedImage!.readAsBytes(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Image.memory(snapshot.data!, fit: BoxFit.cover);
                            }
                            return const Center(child: CircularProgressIndicator());
                          },
                        ))
                  : (_avatarUrl != null
                      ? CustomImageWidget(
                          imageUrl: _avatarUrl!,
                          fit: BoxFit.cover,
                        )
                      : _buildDefaultAvatar(colorScheme)),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: _showPhotoOptions,
              child: Container(
                padding: EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: CustomIconWidget(
                  iconName: 'camera_alt',
                  color: colorScheme.onPrimary,
                  size: 20.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.primaryContainer,
      child: Center(
        child: CustomIconWidget(
          iconName: 'person',
          color: colorScheme.primary,
          size: 60.0,
        ),
      ),
    );
  }

  Widget _buildNameField() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nom complet',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 8.5),
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.person_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            hintText:
                'Votre nom complet tel qu\'il apparaîtra sur votre profil',
            hintStyle: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          textCapitalization: TextCapitalization.words,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer votre nom';
            }
            if (value.length < 3) {
              return 'Le nom doit contenir au moins 3 caractères';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildUsernameField() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nom d\'utilisateur (pseudo)',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 8.5),
        TextFormField(
          controller: _usernameController,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.alternate_email),
            suffixIcon: _isCheckingUsername
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _usernameAvailable != null
                    ? Icon(
                        _usernameAvailable! ? Icons.check_circle : Icons.cancel,
                        color: _usernameAvailable!
                            ? AppTheme.successGreen
                            : AppTheme.errorRed,
                      )
                    : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            hintText:
                '3-20 caractères, lettres, chiffres et tiret bas uniquement',
            hintStyle: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer un nom d\'utilisateur';
            }
            if (value.length < 3 || value.length > 20) {
              return 'Le pseudo doit contenir entre 3 et 20 caractères';
            }
            if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
              return 'Caractères invalides (lettres, chiffres et _ seulement)';
            }
            if (_usernameAvailable == false) {
              return 'Ce nom d\'utilisateur n\'est pas disponible';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildBioField() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Biographie (optionnel)',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 8.5),
        TextFormField(
          controller: _bioController,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.article_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            hintText: 'Parlez un peu de vous',
            hintStyle: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          maxLines: 3,
          maxLength: 150,
        ),
      ],
    );
  }

  Widget _buildPhoneField() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Numéro de téléphone',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 8.5),
        TextFormField(
          controller: _phoneController,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.phone_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            hintText: 'Format: +221 XX XXX XX XX',
            hintStyle: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer votre numéro de téléphone';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildLocationField() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Localisation',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 8.5),
        TextFormField(
          controller: _locationController,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.location_on_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            hintText: 'Ville ou quartier',
            hintStyle: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          textCapitalization: TextCapitalization.words,
        ),
      ],
    );
  }

  Widget _buildActionButtons(ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed:
                _hasChanges ? _cancelChanges : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 17.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Annuler'),
          ),
        ),
        SizedBox(width: 16.0),
        Expanded(
          child: ElevatedButton(
            onPressed: _hasChanges && !_isSaving ? _saveChanges : null,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 17.0),
              backgroundColor: colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSaving
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorScheme.onPrimary,
                      ),
                    ),
                  )
                : const Text('Enregistrer'),
          ),
        ),
      ],
    );
  }

  void _showPhotoOptions() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    HapticFeedback.lightImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48.0,
              height: 4.3,
              decoration: BoxDecoration(
                color: colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 25.5),
            Text(
              'Changer la photo de profil',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 25.5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPhotoOption(
                  context,
                  'Caméra',
                  'camera_alt',
                  () => _pickImage(ImageSource.camera),
                ),
                _buildPhotoOption(
                  context,
                  'Galerie',
                  'photo_library',
                  () => _pickImage(ImageSource.gallery),
                ),
                if (_avatarUrl != null || _selectedImage != null)
                  _buildPhotoOption(
                    context,
                    'Supprimer',
                    'delete',
                    _removeAvatar,
                  ),
              ],
            ),
            SizedBox(height: 34.0),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoOption(
    BuildContext context,
    String label,
    String iconName,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Column(
        children: [
          Container(
            width: 60.0,
            height: 60.0,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: iconName,
                color: colorScheme.primary,
                size: 28.0,
              ),
            ),
          ),
          SizedBox(height: 8.5),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      if (source == ImageSource.camera) {
        final permission = await Permission.camera.request();
        if (!permission.isGranted) {
          _showPermissionDialog('caméra');
          return;
        }
      }

      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = image;
          _hasChanges = true;
        });
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la sélection de l\'image');
    }
  }

  void _removeAvatar() {
    setState(() {
      _avatarUrl = null;
      _selectedImage = null;
      _hasChanges = true;
    });
    HapticFeedback.lightImpact();
  }

  void _showPermissionDialog(String permission) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text(
          'Permission requise',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'L\'accès à la $permission est nécessaire pour changer votre photo de profil.',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Paramètres'),
          ),
        ],
      ),
    );
  }

  void _cancelChanges() async {
    if (await _showDiscardChangesDialog()) {
      Navigator.pop(context);
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      String? newAvatarUrl = _avatarUrl;
      if (_selectedImage != null) {
        newAvatarUrl = await SupabaseService.uploadProfileImage(_selectedImage!);
      }

      await SupabaseService.updateUserProfile(
        fullName: _nameController.text.trim(),
        pseudo: _usernameController.text.trim(),
        bio: _bioController.text.trim(),
        phone: _phoneController.text.trim(),
        location: _locationController.text.trim(),
        avatarUrl: newAvatarUrl,
      );

      setState(() {
        _isSaving = false;
        _hasChanges = false;
      });

      _showSuccessSnackBar('Profil mis à jour avec succès');

      // Pop with success indicator to reload data in UserProfileScreen
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) Navigator.pop(context, true);
      });
    } catch (e) {
      setState(() => _isSaving = false);
      _showErrorSnackBar(
          'Erreur lors de la mise à jour du profil: ${e.toString()}');
    }
  }

  Future<bool> _showDiscardChangesDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifications non enregistrées'),
        content: const Text(
          'Vous avez des modifications non enregistrées. Voulez-vous les abandonner ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continuer l\'édition'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
            ),
            child: const Text('Abandonner'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
