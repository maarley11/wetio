import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/supabase_service.dart';

class FavoritesTabWidget extends StatefulWidget {
  const FavoritesTabWidget({super.key});

  @override
  State<FavoritesTabWidget> createState() => _FavoritesTabWidgetState();
}

class _FavoritesTabWidgetState extends State<FavoritesTabWidget> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _favorites = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);
    try {
      final favs = await SupabaseService.getFavorites();
      if (mounted) {
        setState(() {
          _favorites = favs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _removeFavorite(String productId, int index) async {
    try {
      await SupabaseService.removeFavorite(productId);
      setState(() => _favorites.removeAt(index));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Retiré de LI LA BEUGUE'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {}
  }

  bool _isExchanged(Map<String, dynamic> product) {
    return product['is_exchanged'] == true || product['is_active'] == false;
  }

  String? _getImageUrl(Map<String, dynamic> product) {
    final images = product['images'];
    if (images is List && images.isNotEmpty) {
      return images[0] as String?;
    }
    return null;
  }

  bool _hasValidImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return false;
    try {
      Uri.parse(imageUrl);
      return imageUrl.startsWith('http://') || imageUrl.startsWith('https://');
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_favorites.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 34.0),
            Container(
              padding: EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.red[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_border,
                size: 48.0,
                color: Colors.red[300],
              ),
            ),
            SizedBox(height: 17.0),
            Text(
              'LI LA BEUGUE est vide',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 8.5),
            Text(
              'Appuyez sur ❤️ sur un produit pour l\'ajouter à vos favoris',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 25.5),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/home_feed');
              },
              icon: const Icon(Icons.explore),
              label: const Text('Parcourir les produits'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 34.0),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFavorites,
      child: Column(
        children: [
          if (kDebugMode || true)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.5),
              child: Text(
                'Debug: ${_favorites.length} favoris trouvés',
                style: TextStyle(fontSize: 10, color: Colors.grey[400]),
              ),
            ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.all(16.0),
            itemCount: _favorites.length,
            itemBuilder: (context, index) {
          final favItem = _favorites[index];
          final productData = favItem['product'] as Map<String, dynamic>?;
          
          if (productData == null) {
            // Join failed or product was deleted
            return Container(
              margin: EdgeInsets.only(bottom: 12.0),
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.grey[600]),
                  SizedBox(width: 12.0),
                  Expanded(
                    child: Text(
                      'Produit introuvable ou supprimé',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _removeFavorite(favItem['product_id']?.toString() ?? '', index),
                  ),
                ],
              ),
            );
          }

          final product = productData;
          final productId = product['id']?.toString() ?? '';
          final title = product['title'] as String? ?? 'Produit';
          final category = product['category'] as String? ?? 'Autres';
          final imageUrl = _getImageUrl(product);
          final isExchanged = _isExchanged(product);
          final owner = product['owner'] as Map<String, dynamic>? ?? {};
          final ownerName = owner['full_name'] as String? ??
              owner['pseudo'] as String? ??
              'Utilisateur';
          final location = product['location'] as String? ?? 'Dakar';

          return Container(
            margin: EdgeInsets.only(bottom: 12.0),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: isExchanged
                  ? Border.all(
                      color: Colors.orange.withValues(alpha: 0.5), width: 1.5)
                  : Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.15)),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Exchanged banner
                if (isExchanged)
                  Container(
                    width: double.infinity,
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.5),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.12),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.swap_horiz,
                          color: Colors.orange[700],
                          size: 16,
                        ),
                        SizedBox(width: 8.0),
                        Text(
                          'Ce produit a déjà été échangé',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.orange[800],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Product content
                Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Stack(
                          children: [
                            _hasValidImage(imageUrl)
                                ? CustomImageWidget(
                                    imageUrl: imageUrl!,
                                    width: 88.0,
                                    height: 88.0,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    width: 88.0,
                                    height: 88.0,
                                    color: colorScheme.surfaceContainer,
                                    child: Icon(
                                      Icons.shopping_bag_outlined,
                                      color: colorScheme.onSurfaceVariant,
                                      size: 32.0,
                                    ),
                                  ),
                            // Dim overlay if exchanged
                            if (isExchanged)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.35),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.swap_horiz,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      SizedBox(width: 12.0),

                      // Product info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isExchanged
                                    ? colorScheme.onSurface
                                        .withValues(alpha: 0.5)
                                    : colorScheme.onSurface,
                                decoration: isExchanged
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4.3),
                            Row(
                              children: [
                                Icon(
                                  Icons.category_outlined,
                                  size: 12,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                SizedBox(width: 4.0),
                                Text(
                                  category,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4.3),
                            Row(
                              children: [
                                const Text('👨',
                                    style: TextStyle(fontSize: 12)),
                                SizedBox(width: 4.0),
                                Expanded(
                                  child: Text(
                                    '$ownerName • $location',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            Builder(
                              builder: (context) {
                                final rawPrice = product['price'] ?? product['Price'] ?? product['amount'] ?? product['montant'];
                                if (rawPrice != null && rawPrice.toString() != 'null' && rawPrice.toString().isNotEmpty && rawPrice.toString() != '0') {
                                  try {
                                    double priceValue = 0;
                                    if (rawPrice is num) {
                                      priceValue = rawPrice.toDouble();
                                    } else if (rawPrice is String) {
                                      priceValue = double.tryParse(rawPrice.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
                                    }
                                    
                                    if (priceValue > 0) {
                                      return Padding(
                                        padding: EdgeInsets.only(top: 4.3),
                                        child: Text(
                                          '${priceValue.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]} ")} FCFA',
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: AppTheme.primaryGreen,
                                            fontSize: 11,
                                          ),
                                        ),
                                      );
                                    }
                                  } catch (_) {}
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ],
                        ),
                      ),

                      // Remove from favorites button
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _removeFavorite(productId, index);
                        },
                        child: Container(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.favorite,
                            color: Colors.red,
                            size: 20.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Je te propose button (always shown, disabled if exchanged)
                Padding(
                  padding: EdgeInsets.fromLTRB(12.0, 0, 12.0, 12.0),
                  child: isExchanged
                      ? Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: 12.8),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.swap_horiz,
                                size: 16,
                                color: Colors.grey[500],
                              ),
                              SizedBox(width: 8.0),
                              Text(
                                'Produit déjà échangé',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ElevatedButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Navigator.pushNamed(
                              context,
                              AppRoutes.exchangeProposal,
                              arguments: product,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryOrange,
                            foregroundColor: Colors.white,
                            minimumSize: Size(double.infinity, 42.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.handshake_outlined,
                                size: 18,
                                color: Colors.white,
                              ),
                              SizedBox(width: 8.0),
                              Text(
                                'Je te propose',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              SizedBox(width: 8.0),
                              const Icon(
                                Icons.arrow_forward,
                                size: 18,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    ],
  ),
);
  }
}
