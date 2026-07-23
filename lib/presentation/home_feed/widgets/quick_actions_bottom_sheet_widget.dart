import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class QuickActionsBottomSheetWidget extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback? onSaveToFavorites;
  final VoidCallback? onReport;
  final VoidCallback? onShare;

  const QuickActionsBottomSheetWidget({
    super.key,
    required this.product,
    this.onSaveToFavorites,
    this.onReport,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle Bar
          Container(
            margin: EdgeInsets.only(top: 8.5),
            width: 40.0,
            height: 4.3,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Product Preview
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CustomImageWidget(
                    imageUrl: product['image'] as String,
                    width: 60.0,
                    height: 60.0,
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['title'] as String,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.3),
                      Text(
                        'Par ${product['userName'] as String}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(
            color: colorScheme.outline.withValues(alpha: 0.2),
            thickness: 1,
          ),

          // Action Items
          _buildActionItem(
            context,
            icon: 'favorite_border',
            title: 'Sauvegarder',
            subtitle: 'Ajouter aux favoris',
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
              onSaveToFavorites?.call();
            },
            theme: theme,
            colorScheme: colorScheme,
          ),

          _buildActionItem(
            context,
            icon: 'share',
            title: 'Partager',
            subtitle: 'Partager ce produit',
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
              onShare?.call();
            },
            theme: theme,
            colorScheme: colorScheme,
          ),

          _buildActionItem(
            context,
            icon: 'report',
            title: 'Signaler',
            subtitle: 'Signaler un problème',
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
              onReport?.call();
            },
            theme: theme,
            colorScheme: colorScheme,
            isDestructive: true,
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 17.0),
        ],
      ),
    );
  }

  Widget _buildActionItem(
    BuildContext context, {
    required String icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required ThemeData theme,
    required ColorScheme colorScheme,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 17.0),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: (isDestructive ? AppTheme.errorRed : colorScheme.primary)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: CustomIconWidget(
                iconName: icon,
                size: 24,
                color: isDestructive ? AppTheme.errorRed : colorScheme.primary,
              ),
            ),
            SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: isDestructive
                          ? AppTheme.errorRed
                          : colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            CustomIconWidget(
              iconName: 'chevron_right',
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
