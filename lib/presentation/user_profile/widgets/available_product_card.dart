import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class AvailableProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isOwnProfile;

  const AvailableProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onLongPress,
    this.isOwnProfile = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      onLongPress: isOwnProfile
          ? () {
              HapticFeedback.mediumImpact();
              onLongPress?.call();
            }
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      color: colorScheme.surfaceContainerHighest,
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: product['image'] != null
                          ? CustomImageWidget(
                              imageUrl: product['image'] as String,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: colorScheme.surfaceContainerHighest,
                              child: Center(
                                child: CustomIconWidget(
                                  iconName: 'image',
                                  color: colorScheme.onSurfaceVariant,
                                  size: 32.0,
                                ),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),

            // Product Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Title
                    Text(
                      product['title'] as String? ?? 'Produit sans titre',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8.5),

                    // Product Details
                    if (product['size'] != null ||
                        product['color'] != null) ...[
                      Row(
                        children: [
                          if (product['size'] != null) ...[
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6.0,
                                vertical: 1.7,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                product['size'] as String,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.primary,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                            SizedBox(width: 4.0),
                          ],
                          if (product['color'] != null) ...[
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6.0,
                                vertical: 1.7,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                product['color'] as String,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.secondary,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 8.5),
                    ],

                    // Location and Date
                    Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'location_on',
                          color: colorScheme.onSurfaceVariant,
                          size: 12.0,
                        ),
                        SizedBox(width: 2.0),
                        Expanded(
                          child: Text(
                            product['location'] as String? ?? 'Dakar',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 9,
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
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 12.8),
                                  Text(
                                    '${priceValue.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]} ")} FCFA',
                                    style: GoogleFonts.inter(
                                      fontSize: 14, // Slightly smaller for grid
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.primaryGreen,
                                    ),
                                  ),
                                ],
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
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return AppTheme.successGreen;
      case 'exchanged':
        return AppTheme.primaryOrange;
      case 'sold':
        return AppTheme.errorRed;
      case 'reserved':
        return AppTheme.warningOrange;
      default:
        return AppTheme.successGreen;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return 'Disponible';
      case 'exchanged':
        return 'Échangé';
      case 'sold':
        return 'Vendu';
      case 'reserved':
        return 'Réservé';
      default:
        return 'Disponible';
    }
  }
}
