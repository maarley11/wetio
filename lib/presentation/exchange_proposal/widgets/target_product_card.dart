import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class TargetProductCard extends StatelessWidget {
  final Map<String, dynamic> targetProduct;

  const TargetProductCard({
    super.key,
    required this.targetProduct,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryOrange.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryOrange.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: AspectRatio(
              aspectRatio: 1.25,
              child: CustomImageWidget(
                imageUrl: (targetProduct["images"] as List?)?.isNotEmpty == true 
                    ? targetProduct["images"][0] 
                    : (targetProduct["image"] as String? ?? ""),
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Title
                Text(
                  targetProduct["title"] as String? ?? "Produit",
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: colorScheme.onSurface,
                    fontSize: 16,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),

                SizedBox(height: 17.0),

                // Product Details Grid
                Container(
                  padding: EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest
                        .withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      // Category and Demographic Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildDetailItem(
                              context,
                              icon: Icons.category_outlined,
                              label: 'Catégorie',
                              value: targetProduct['category'] as String? ??
                                  'Non spécifié',
                            ),
                          ),
                          SizedBox(width: 12.0),
                          Expanded(
                            child: _buildDetailItem(
                              context,
                              icon: Icons.people_outline,
                              label: 'Démographie',
                              value: targetProduct['demographic'] as String? ??
                                  'Non spécifié',
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 17.0),

                      // Condition and Size Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildDetailItem(
                              context,
                              icon: Icons.check_circle_outline,
                              label: 'État du produit',
                              value: _formatCondition(
                                targetProduct['product_condition']?.toString() ??
                                targetProduct['condition']?.toString() ??
                                targetProduct['etat']?.toString(),
                              ),
                            ),
                          ),
                          SizedBox(width: 12.0),
                          Expanded(
                            child: _buildDetailItem(
                              context,
                              icon: Icons.straighten_outlined,
                              label: 'Taille / Pointure',
                              value: _extractSize(targetProduct) ?? 'Non spécifiée',
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 17.0),

                      // Owner Information
                      _buildDetailItem(
                        context,
                        icon: Icons.person_outline,
                        label: 'Propriétaire',
                        value:
                            '👨 ${targetProduct["owner"] != null ? (targetProduct["owner"]["full_name"] ?? targetProduct["owner"]["pseudo"]) : (targetProduct["userName"] ?? "Propriétaire")}',
                      ),

                      if (targetProduct["owner"] != null && 
                          targetProduct["owner"]["payout_phone"] != null && 
                          targetProduct["owner"]["payout_phone"].toString().isNotEmpty) ...[
                        SizedBox(height: 17.0),
                        _buildDetailItem(
                          context,
                          icon: Icons.phone_android_outlined,
                          label: 'Numéro de réception',
                          value: '${targetProduct["owner"]["payout_phone"]}',
                        ),
                      ],

                      SizedBox(height: 17.0),

                      // Location Information
                      _buildDetailItem(
                        context,
                        icon: Icons.location_on_outlined,
                        label: 'Localisation',
                        value:
                            '${targetProduct["location"] as String? ?? "Localisation"} • ${targetProduct["distance"] as String? ?? ""}',
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 17.0),

                // Product Description
                if (targetProduct['description'] != null &&
                    (targetProduct['description'] as String).isNotEmpty) ...[
                  Container(
                    padding: EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color:
                          colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.primary.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.description_outlined,
                              size: 18,
                              color: colorScheme.primary,
                            ),
                            SizedBox(width: 8.0),
                            Text(
                              'Description',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.5),
                        Text(
                          targetProduct['description'] as String,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: colorScheme.primary,
            ),
            SizedBox(width: 4.0),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                fontSize: 9,
              ),
            ),
          ],
        ),
        SizedBox(height: 4.3),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  String _formatCondition(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'Non spécifié';
    final clean = raw.trim().toLowerCase().replaceAll('-', '_');
    switch (clean) {
      case 'neuf':
        return 'Neuf';
      case 'tres_bon_etat':
      case 'très bon état':
        return 'Très bon état';
      case 'bon_etat':
      case 'bon état':
        return 'Bon état';
      case 'etat_correct':
      case 'état correct':
        return 'État correct';
      case 'a_reparer':
      case 'à réparer':
        return 'À réparer';
      default:
        return raw;
    }
  }

  String? _extractSize(Map<String, dynamic> product) {
    final sizeVal = product['size'] ?? product['taille'] ?? product['product_size'];
    if (sizeVal != null && sizeVal.toString().trim().isNotEmpty) {
      return sizeVal.toString().trim();
    }
    return null;
  }
}
