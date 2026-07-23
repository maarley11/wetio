import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SelectedProductsSection extends StatelessWidget {
  final List<Map<String, dynamic>> selectedProducts;
  final Function(Map<String, dynamic>) onRemoveProduct;

  const SelectedProductsSection({
    super.key,
    required this.selectedProducts,
    required this.onRemoveProduct,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (selectedProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Produits sélectionnés (${selectedProducts.length})",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 17.0),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: selectedProducts.map((product) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: CustomImageWidget(
                      imageUrl: (product["images"] as List?)?.isNotEmpty == true 
                          ? product["images"][0] 
                          : (product["image"] as String? ?? ""),
                      width: 32.0,
                      height: 32.0,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(width: 8.0),
                  Flexible(
                    child: Text(
                      product["title"] as String? ?? "Produit",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 8.0),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onRemoveProduct(product);
                    },
                    child: Container(
                      padding: EdgeInsets.all(2.0),
                      decoration: BoxDecoration(
                        color: colorScheme.error.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: CustomIconWidget(
                        iconName: 'close',
                        size: 14,
                        color: colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
