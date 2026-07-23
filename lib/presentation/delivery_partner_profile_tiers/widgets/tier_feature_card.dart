import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class TierFeatureCard extends StatelessWidget {
  final String tierName;
  final String price;
  final String? additionalInfo;
  final Color color;
  final List<Map<String, dynamic>> features;
  final bool isCurrentTier;
  final bool isPremium;
  final VoidCallback? onSelect;

  const TierFeatureCard({
    super.key,
    required this.tierName,
    required this.price,
    this.additionalInfo,
    required this.color,
    required this.features,
    this.isCurrentTier = false,
    this.isPremium = false,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentTier
              ? color.withValues(alpha: 0.5)
              : colorScheme.outline.withValues(alpha: 0.2),
          width: isCurrentTier ? 2 : 1,
        ),
        boxShadow: [
          if (isCurrentTier || isPremium)
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              gradient: isPremium
                  ? LinearGradient(
                      colors: [AppTheme.premiumGold, Colors.amber.shade600],
                    )
                  : LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.1),
                        color.withValues(alpha: 0.2),
                      ],
                    ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isPremium) ...[
                      CustomIconWidget(
                        iconName: 'stars',
                        color: Colors.white,
                        size: 24.0,
                      ),
                      SizedBox(width: 8.0),
                    ],
                    Text(
                      tierName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isPremium ? Colors.white : color,
                      ),
                    ),
                  ],
                ),
                if (isCurrentTier) ...[
                  SizedBox(height: 8.5),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: isPremium
                          ? Colors.white.withValues(alpha: 0.2)
                          : color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'ACTUEL',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isPremium ? Colors.white : color,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
                SizedBox(height: 17.0),
                Text(
                  price,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isPremium ? Colors.white : colorScheme.onSurface,
                  ),
                ),
                if (additionalInfo != null)
                  Text(
                    additionalInfo!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isPremium
                          ? Colors.white.withValues(alpha: 0.8)
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),

          // Features list
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: features
                  .map(
                    (feature) => _buildFeatureItem(
                      feature['name'] as String,
                      feature['included'] as bool,
                      theme,
                      colorScheme,
                    ),
                  )
                  .toList(),
            ),
          ),

          // Action button
          if (onSelect != null)
            Padding(
              padding: EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onSelect,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPremium ? AppTheme.premiumGold : color,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isPremium ? 'Passer Premium' : 'Sélectionner',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(
    String featureName,
    bool included,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 4.3),
            child: CustomIconWidget(
              iconName: included ? 'check_circle' : 'cancel',
              color: included ? AppTheme.successGreen : colorScheme.outline,
              size: 16.0,
            ),
          ),
          SizedBox(width: 12.0),
          Expanded(
            child: Text(
              featureName,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: included
                    ? colorScheme.onSurface
                    : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                fontWeight: included ? FontWeight.w500 : FontWeight.normal,
                decoration: included ? null : TextDecoration.lineThrough,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
