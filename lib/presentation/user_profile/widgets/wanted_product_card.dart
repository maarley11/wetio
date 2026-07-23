import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class WantedProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isOwnProfile;

  const WantedProductCard({
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
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 17.0),
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Category and Urgency
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.3),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    product['category'] as String? ?? 'Autre',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                if (product['urgency'] != null)
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.3),
                    decoration: BoxDecoration(
                      color: _getUrgencyColor(product['urgency'] as String),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomIconWidget(
                          iconName:
                              _getUrgencyIcon(product['urgency'] as String),
                          color: Colors.white,
                          size: 12.0,
                        ),
                        SizedBox(width: 4.0),
                        Text(
                          _getUrgencyText(product['urgency'] as String),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            SizedBox(height: 17.0),

            // Product Title
            Text(
              product['title'] as String? ?? 'Produit recherché',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 8.5),

            // Description
            if (product['description'] != null) ...[
              Text(
                product['description'] as String,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 17.0),
            ],

            // Specifications
            if (product['specifications'] != null) ...[
              Wrap(
                spacing: 8.0,
                runSpacing: 8.5,
                children: (product['specifications'] as List<dynamic>)
                    .map((spec) => Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 4.3,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color:
                                  colorScheme.secondary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            spec as String,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: colorScheme.secondary,
                            ),
                          ),
                        ))
                    .toList(),
              ),
              SizedBox(height: 17.0),
            ],

            // Footer with Location and Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'location_on',
                      color: colorScheme.onSurfaceVariant,
                      size: 16.0,
                    ),
                    SizedBox(width: 4.0),
                    Text(
                      product['location'] as String? ?? 'Dakar',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'schedule',
                      color: colorScheme.onSurfaceVariant,
                      size: 16.0,
                    ),
                    SizedBox(width: 4.0),
                    Text(
                      product['datePosted'] as String? ?? 'Aujourd\'hui',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Budget Range (if specified)
            if (product['budgetRange'] != null) ...[
              SizedBox(height: 8.5),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.5),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'payments',
                      color: colorScheme.tertiary,
                      size: 16.0,
                    ),
                    SizedBox(width: 8.0),
                    Text(
                      'Budget: ${product['budgetRange']}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: colorScheme.tertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getUrgencyColor(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'high':
        return AppTheme.errorRed;
      case 'medium':
        return AppTheme.warningOrange;
      case 'low':
        return AppTheme.successGreen;
      default:
        return AppTheme.warningOrange;
    }
  }

  String _getUrgencyIcon(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'high':
        return 'priority_high';
      case 'medium':
        return 'schedule';
      case 'low':
        return 'schedule';
      default:
        return 'schedule';
    }
  }

  String _getUrgencyText(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'high':
        return 'Urgent';
      case 'medium':
        return 'Modéré';
      case 'low':
        return 'Pas pressé';
      default:
        return 'Modéré';
    }
  }
}
