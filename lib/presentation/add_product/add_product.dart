import 'dart:io' if (dart.library.html) '../../stubs/io_stub.dart' as io;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../routes/app_routes.dart';
import '../../services/supabase_service.dart';
import '../../services/token_service.dart';
import '../../stubs/io_stub.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_guard.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/location_section_widget.dart';
import './widgets/photo_section_widget.dart';
import './widgets/product_form_widget.dart';
import './widgets/product_type_toggle_widget.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({Key? key}) : super(key: key);

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  List<XFile> _selectedImages = [];
  String? _selectedCategory;
  String? _selectedCondition;
  String? _selectedSize;
  String? _selectedColor;
  bool _isWantedProduct = false;
  String _currentLocation = 'Dakar';
  bool _isPublishing = false;

  bool _isCheckingTokens = false;
  String? _tokenCheckMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final client = SupabaseService.safeClient;
      final isLoggedIn = client?.auth.currentUser != null;
      if (!isLoggedIn) {
        requireAuth(context, () {
          _setupAfterAuth();
        });
        return;
      }
      _setupAfterAuth();
    });
  }

  void _setupAfterAuth() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      final isWanted = args['isWantedProduct'] as bool? ?? false;
      if (isWanted && mounted) {
        setState(() {
          _isWantedProduct = true;
        });
      }
    }
    if (!_isWantedProduct) {
      _checkTokenBalance();
    }
  }

  Future<void> _checkTokenBalance() async {
    setState(() {
      _isCheckingTokens = true;
    });

    try {
      final result = await TokenService.instance.canUserPublishProduct();
      setState(() {
        if (result['can_publish'] == false) {
          _tokenCheckMessage = result['message'];
        }
        _isCheckingTokens = false;
      });
    } catch (e) {
      setState(() {
        _tokenCheckMessage = 'Erreur lors de la vérification des jetons';
        _isCheckingTokens = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    final hasTitle = _titleController.text.trim().isNotEmpty;
    final hasCategory = _selectedCategory != null;
    final hasDescription = _descriptionController.text.trim().isNotEmpty;
    final hasCondition = _isWantedProduct || _selectedCondition != null;
    final hasImages = _isWantedProduct || _selectedImages.isNotEmpty;
    final hasPrice = _isWantedProduct || _priceController.text.trim().isNotEmpty;

    return hasTitle &&
        hasCategory &&
        hasDescription &&
        hasCondition &&
        hasImages &&
        hasPrice;
  }

  void _onImagesChanged(List<XFile> images) {
    setState(() {
      _selectedImages = images;
    });
  }

  void _onCategoryChanged(String? category) {
    setState(() {
      _selectedCategory = category;
      _selectedSize = null;
      _selectedColor = null;
    });
  }

  void _onConditionChanged(String? condition) {
    setState(() {
      _selectedCondition = condition;
    });
  }

  void _onSizeChanged(String? size) {
    setState(() {
      _selectedSize = size;
    });
  }

  void _onColorChanged(String? color) {
    setState(() {
      _selectedColor = color;
    });
  }

  void _onProductTypeToggle(bool isWanted) {
    setState(() {
      _isWantedProduct = isWanted;
      if (isWanted) {
        _selectedCondition = null;
        _selectedImages.clear();
      }
    });
  }

  void _onLocationChanged(String location) {
    setState(() {
      _currentLocation = location;
    });
  }

  /// Map French condition label to DB enum value
  String _mapConditionToEnum(String condition) {
    switch (condition) {
      case 'Neuf':
        return 'neuf';
      case 'Très bon état':
        return 'tres_bon_etat';
      case 'Bon état':
        return 'bon_etat';
      case 'État correct':
        return 'etat_correct';
      case 'À réparer':
        return 'endommage';
      default:
        return 'bon_etat';
    }
  }

  /// Upload images to Supabase Storage and return public URLs
  Future<List<String>> _uploadImages(List<XFile> images) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id ?? 'unknown';
    final List<String> uploadedUrls = [];

    for (final image in images) {
      try {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = '${userId}/${timestamp}_${image.name}';

        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          await supabase.storage
              .from('product-images')
              .uploadBinary(
                fileName,
                bytes,
                fileOptions: const FileOptions(
                  contentType: 'image/jpeg',
                  upsert: true,
                ),
              );
        } else {
          final file = io.File(image.path);
          await supabase.storage
              .from('product-images')
              .upload(
                fileName,
                file,
                fileOptions: const FileOptions(upsert: true),
              );
        }

        final publicUrl = supabase.storage
            .from('product-images')
            .getPublicUrl(fileName);
        uploadedUrls.add(publicUrl);
      } catch (e) {
        print('❌ Erreur upload image: $e');
        // Continue with other images even if one fails
      }
    }

    return uploadedUrls;
  }

  Future<void> _handleProductSubmission() async {
    if (!_isFormValid) {
      _showValidationErrors();
      return;
    }

    setState(() {
      _isPublishing = true;
    });

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        _showErrorDialog('Vous devez être connecté pour publier un produit.');
        return;
      }

      if (!_isWantedProduct) {
        // 1. Check if user has enough tokens first (WITHOUT deducting)
        final canPublish = await TokenService.instance.canUserPublishProduct();
        if (canPublish['can_publish'] != true) {
          _showErrorDialog(
            canPublish['message'] ?? 'Vous n\'avez pas assez de jetons pour publier ce produit.',
          );
          return;
        }

        // 2. Upload images
        List<String> imageUrls = [];
        if (_selectedImages.isNotEmpty) {
          imageUrls = await _uploadImages(_selectedImages);
        }

        // 3. Insert product into Supabase
        try {
          await supabase.from('products').insert({
            'owner_id': userId,
            'title': _titleController.text.trim(),
            'description': _descriptionController.text.trim(),
            'category': _selectedCategory,
            'price': int.tryParse(
              _priceController.text.trim().replaceAll(RegExp(r'[^0-9]'), ''),
            ) ?? 0,
            'product_condition': _mapConditionToEnum(_selectedCondition!),
            'product_type': 'disponible',
            'images': imageUrls,
            'location': _currentLocation,
            'is_active': true,
          });
        } catch (insertError) {
          print('❌ Database Insert Error: $insertError');
          throw Exception('Erreur lors de l\'enregistrement: $insertError');
        }

        // 4. ONLY NOW deduct tokens since insertion was successful
        final tokenResult = await TokenService.instance.deductTokensForPublication(
          productTitle: _titleController.text,
        );

        if (mounted) {
          _showSuccessDialog(
            'Produit publié avec succès !\n'
            '${tokenResult['tokens_deducted'] ?? 10} jetons ont été déduits.\n'
            'Nouveau solde: ${tokenResult['new_balance']} jetons',
          );
        }
      } else {
        // Wanted product — free, no tokens
        await supabase.from('products').insert({
          'owner_id': userId,
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'category': _selectedCategory,
          'product_condition': 'bon_etat',
          'product_type': 'recherche',
          'images': [],
          'location': _currentLocation,
          'is_active': true,
        });

        if (mounted) {
          _showSuccessDialog(
            'Recherche ajoutée avec succès !\nC\'est gratuit, aucun jeton déduit.',
          );
        }
      }
    } catch (e) {
      print('❌ Erreur publication produit: $e');
      String errorMessage = "Erreur lors de la publication. Veuillez réessayer.";
      
      // Try to extract a more user-friendly error if possible
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('duplicate key')) {
        errorMessage = "Ce produit semble déjà exister.";
      } else if (errorStr.contains('network') || errorStr.contains('socketexception')) {
        errorMessage = "Problème de connexion. Vérifiez votre réseau.";
      } else if (errorStr.contains('token')) {
        errorMessage = "Erreur liée aux jetons. Veuillez réessayer.";
      } else if (e is Exception) {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      }

      Fluttertoast.showToast(
        msg: errorMessage,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppTheme.errorRed,
        textColor: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPublishing = false;
        });
      }
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 24),
              SizedBox(width: 8),
              Text('Succès'),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to profile to see the product
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.homeFeed,
                  (route) => false,
                );
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red, size: 24),
              SizedBox(width: 8),
              Text('Erreur'),
            ],
          ),
          content: Text(message),
          actions: [
            if (message.contains('jetons'))
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushNamed(
                    context,
                    AppRoutes.tokenPurchaseScreen,
                  ).then((_) => _checkTokenBalance());
                },
                child: Text('Acheter des jetons'),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showValidationErrors() {
    String errorMessage = "Veuillez compléter tous les champs obligatoires:";

    if (_titleController.text.trim().isEmpty) {
      errorMessage += "\n• Titre du produit";
    }
    if (_selectedCategory == null) {
      errorMessage += "\n• Catégorie";
    }
    if (!_isWantedProduct && _selectedCondition == null) {
      errorMessage += "\n• État du produit";
    }
    if (_descriptionController.text.trim().isEmpty) {
      errorMessage += "\n• Description";
    }
    if (!_isWantedProduct && _selectedImages.isEmpty) {
      errorMessage += "\n• Au moins une photo";
    }
    if (!_isWantedProduct && _priceController.text.trim().isEmpty) {
      errorMessage += "\n• Prix du produit";
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Champs manquants',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            errorMessage,
            style: AppTheme.lightTheme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Compris',
                style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showProductLimitDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Limite atteinte',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'Vous avez atteint la limite de produits. Supprimez un produit existant ou passez à la version premium pour publier plus de produits.',
            style: AppTheme.lightTheme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Annuler',
                style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/user-profile');
              },
              child: Text(
                'Gérer mes produits',
                style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: CustomAppBar(
        title: "Ajouter un produit",
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/home_feed');
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // Token check warning (if needed)
            if (_tokenCheckMessage != null)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _tokenCheckMessage!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.orange[800],
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.tokenPurchaseScreen,
                        ).then((_) => _checkTokenBalance());
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.orange[700],
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Acheter',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            SizedBox(height: 34.0),

            // Product type toggle
            ProductTypeToggleWidget(
              isWantedProduct: _isWantedProduct,
              onToggle: _onProductTypeToggle,
            ),

            SizedBox(height: 34.0),

            // Photo section (only for available products)
            if (!_isWantedProduct) ...[
              PhotoSectionWidget(
                selectedImages: _selectedImages,
                onImagesChanged: _onImagesChanged,
              ),
              SizedBox(height: 34.0),
            ],

            // Product form
            ProductFormWidget(
              titleController: _titleController,
              descriptionController: _descriptionController,
              priceController: _priceController,
              selectedCategory: _selectedCategory,
              selectedCondition: _selectedCondition,
              selectedSize: _selectedSize,
              selectedColor: _selectedColor,
              onCategoryChanged: _onCategoryChanged,
              onConditionChanged: _onConditionChanged,
              onSizeChanged: _onSizeChanged,
              onColorChanged: _onColorChanged,
              isWantedProduct: _isWantedProduct,
            ),

            SizedBox(height: 34.0),

            // Location section
            LocationSectionWidget(
              currentLocation: _currentLocation,
              onLocationChanged: _onLocationChanged,
            ),

            SizedBox(height: 51.0),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed:
                    (_tokenCheckMessage != null ||
                        _isCheckingTokens ||
                        _isPublishing)
                    ? null
                    : _handleProductSubmission,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isPublishing
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text('Publication en cours...'),
                        ],
                      )
                    : _isCheckingTokens
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text('Vérification...'),
                        ],
                      )
                    : Text(
                        _tokenCheckMessage != null
                            ? 'Jetons insuffisants - Achetez des jetons'
                            : _isWantedProduct
                            ? 'Publier ma recherche (gratuit)'
                            : 'Publier le produit (10 jetons)',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

            // Token info
            if (_tokenCheckMessage == null && !_isWantedProduct)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'La publication de ce produit coûtera 10 jetons',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
