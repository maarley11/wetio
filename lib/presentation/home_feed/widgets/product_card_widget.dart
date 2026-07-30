import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';


class ProductCardWidget extends StatefulWidget {
  final Map<String, dynamic> product;
  final VoidCallback? onTap;
  final VoidCallback? onPropose;
  final VoidCallback? onBuy;
  final VoidCallback? onLongPress;
  final bool isGridView;
  final bool isFavorited;
  final ValueChanged<bool>? onFavoriteToggle;

  const ProductCardWidget({
    super.key,
    required this.product,
    this.onTap,
    this.onPropose,
    this.onBuy,
    this.onLongPress,
    this.isGridView = false,
    this.isFavorited = false,
    this.onFavoriteToggle,
  });

  @override
  State<ProductCardWidget> createState() => _ProductCardWidgetState();
}

class _ProductCardWidgetState extends State<ProductCardWidget> {
  late bool _isFavorited;

  @override
  void initState() {
    super.initState();
    _isFavorited = widget.isFavorited;
  }

  @override
  void didUpdateWidget(ProductCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFavorited != widget.isFavorited) {
      _isFavorited = widget.isFavorited;
    }
  }

  // Helper method to determine if product has valid image
  bool _hasValidImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return false;
    if (imageUrl == 'invalid-url' ||
        imageUrl == 'null' ||
        imageUrl == 'undefined') {
      return false;
    }
    try {
      Uri.parse(imageUrl);
      return imageUrl.startsWith('http://') || imageUrl.startsWith('https://');
    } catch (e) {
      return false;
    }
  }

  Widget _getClothingPlaceholder(
    BuildContext context,
    String category,
    String? userGender,
    bool isGridView,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    IconData clothingIcon;
    String placeholderText;
    Color iconColor;

    switch (category.toLowerCase()) {
      case 'vêtements':
        clothingIcon = (userGender?.toLowerCase() == 'female')
            ? Icons.woman_outlined
            : Icons.man_outlined;
        placeholderText = 'Vêtement';
        iconColor = AppTheme.primaryOrange;
        break;
      case 'vêtements de fêtes':
        clothingIcon = Icons.celebration_outlined;
        placeholderText = 'Tenue de fête';
        iconColor = AppTheme.primaryGreen;
        break;
      case 'chaussures':
        clothingIcon = Icons.help_outline;
        placeholderText = 'Chaussures';
        iconColor = Colors.brown;
        break;
      default:
        clothingIcon = Icons.shopping_bag_outlined;
        placeholderText = 'Produit';
        iconColor = Colors.grey[600]!;
    }

    return Container(
      width: double.infinity,
      height: isGridView ? 136.0 : 170.0,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surfaceContainer.withValues(alpha: 0.8),
            colorScheme.surfaceContainer.withValues(alpha: 0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(isGridView ? 8.0 : 12.0),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: iconColor.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Icon(
              clothingIcon,
              size: isGridView ? 32.0 : 40.0,
              color: iconColor,
            ),
          ),
          SizedBox(height: 8.5),
          Text(
            'Image non disponible',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: isGridView ? 9 : 10,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4.3),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isGridView ? 8.0 : 10.0,
              vertical: 4.3,
            ),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: iconColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              placeholderText,
              style: theme.textTheme.labelSmall?.copyWith(
                color: iconColor,
                fontSize: isGridView ? 8 : 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final String? imageUrl = widget.product['image'] as String?;
    final String category = widget.product['category'] as String? ?? 'Autres';
    final String? userGender = widget.product['userGender'] as String?;
    
    
    
    // Action buttons (Wetio/Acheter) are now always shown for all products per client request.

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: () {
        HapticFeedback.mediumImpact();
        widget.onLongPress?.call();
      },
      child: Container(
        margin: widget.isGridView
            ? EdgeInsets.zero
            : EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.2),
        padding: EdgeInsets.all(widget.isGridView ? 4.0 : 6.0),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image with favorite button overlay
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  // Image
                  _hasValidImage(imageUrl)
                      ? AspectRatio(
                          aspectRatio: widget.isGridView ? 1.05 : 1.5,
                          child: CustomImageWidget(
                            imageUrl: imageUrl!,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorWidget: _getClothingPlaceholder(
                              context,
                              category,
                              userGender,
                              widget.isGridView,
                            ),
                          ),
                        )
                      : _getClothingPlaceholder(
                          context,
                          category,
                          userGender,
                          widget.isGridView,
                        ),

                  // "Image manquante" indicator
                  if (!_hasValidImage(imageUrl) &&
                      (category.toLowerCase().contains('vêtement') ||
                          category.toLowerCase().contains('chaussures')))
                    Positioned(
                      top: widget.isGridView ? 8.5 : 12.8,
                      right: widget.isGridView ? 8.0 : 10.0,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: widget.isGridView ? 4.0 : 6.0,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.image_not_supported_outlined,
                              size: widget.isGridView ? 10 : 12,
                              color: Colors.white,
                            ),
                            if (!widget.isGridView) ...[
                              SizedBox(width: 4.0),
                              Text(
                                'Sans photo',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.white,
                                  fontSize: 7,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                  // ❤️ Favorite button - top left
                  Positioned(
                    top: widget.isGridView ? 6.8 : 8.5,
                    left: widget.isGridView ? 6.0 : 8.0,
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          _isFavorited = !_isFavorited;
                        });
                        widget.onFavoriteToggle?.call(_isFavorited);
                      },
                      child: Container(
                        padding: EdgeInsets.all(
                          widget.isGridView ? 6.0 : 8.0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          _isFavorited ? Icons.favorite : Icons.favorite_border,
                          color: _isFavorited ? Colors.red : Colors.grey[600],
                          size: widget.isGridView ? 16 : 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: widget.isGridView ? 12.8 : 17.0),

            // Product Title
            SizedBox(
              height: widget.isGridView ? 38.3 : 46.8,
              child: Text(
                widget.product['title'] as String,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: colorScheme.onSurface,
                  fontSize: widget.isGridView ? 11 : 13,
                  height: 1.3,
                  letterSpacing: 0.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            SizedBox(height: widget.isGridView ? 6.8 : 8.5),

             // Price - always visible
             Padding(
               padding: EdgeInsets.only(
                 bottom: widget.isGridView ? 5.1 : 6.8,
               ),
               child: Builder(
                 builder: (context) {
                   final rawPrice = widget.product['price'] ?? widget.product['Price'] ?? widget.product['amount'] ?? widget.product['montant'];
                   String displayPrice = 'Prix non renseigné';
                   bool hasPrice = false;

                   if (rawPrice != null && rawPrice.toString() != 'null' && rawPrice.toString().isNotEmpty) {
                      try {
                        double priceValue = 0;
                        if (rawPrice is num) {
                          priceValue = rawPrice.toDouble();
                        } else if (rawPrice is String) {
                          priceValue = double.tryParse(rawPrice.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
                        }
                        
                        if (priceValue > 0) {
                          displayPrice = '${priceValue.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]} ")} FCFA';
                          hasPrice = true;
                        } else if (priceValue == 0 && (widget.product['type'] == 'disponible' || widget.product['product_type'] == 'disponible')) {
                          displayPrice = 'Prix à discuter';
                          hasPrice = false;
                        }
                      } catch (_) {}
                   }

                   return Text(
                     displayPrice,
                     style: theme.textTheme.titleMedium?.copyWith(
                       fontWeight: FontWeight.w900,
                       color: hasPrice
                           ? AppTheme.primaryGreen
                           : colorScheme.onSurface.withValues(alpha: 0.45),
                       fontSize: widget.isGridView ? 11 : 13,
                       letterSpacing: 0.2,
                     ),
                     maxLines: 1,
                     overflow: TextOverflow.ellipsis,
                   );
                 }
               ),
             ),

            // Buttons row: Wetio + Acheter
            Row(
              children: [
                  // Wetio button
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          widget.onPropose?.call();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryOrange.withValues(alpha: 0.1),
                          foregroundColor: AppTheme.primaryOrange,
                          padding: EdgeInsets.symmetric(
                            vertical: widget.isGridView ? 8.5 : 11.1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: AppTheme.primaryOrange.withValues(alpha: 0.3)),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.handshake_outlined,
                              size: widget.isGridView ? 14 : 16,
                              color: AppTheme.primaryOrange,
                            ),
                            SizedBox(width: widget.isGridView ? 4.0 : 6.0),
                            Text(
                              'Wetio',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: AppTheme.primaryOrange,
                                fontWeight: FontWeight.w700,
                                fontSize: widget.isGridView ? 10 : 11,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: widget.isGridView ? 6.0 : 8.0),

                  // Acheter button
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          if (widget.onBuy != null) {
                            widget.onBuy!();
                          } else {
                            Navigator.pushNamed(
                              context,
                              '/product-purchase',
                              arguments: widget.product,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
                          foregroundColor: AppTheme.primaryGreen,
                          padding: EdgeInsets.symmetric(
                            vertical: widget.isGridView ? 8.5 : 11.1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_cart_outlined,
                              size: widget.isGridView ? 14 : 16,
                              color: AppTheme.primaryGreen,
                            ),
                            SizedBox(width: widget.isGridView ? 4.0 : 6.0),
                            Text(
                              'Acheter',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: AppTheme.primaryGreen,
                                fontWeight: FontWeight.w700,
                                fontSize: widget.isGridView ? 10 : 11,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
