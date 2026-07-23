import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback? onButtonPressed;
  final String iconName;
  final bool isWantedTab;

  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    this.onButtonPressed,
    this.iconName = 'inventory_2',
    this.isWantedTab = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Illustration Container
          Container(
            width: 160.0,
            height: 160.0,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 120.0,
                height: 120.0,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: CustomIconWidget(
                    iconName: iconName,
                    color: colorScheme.primary,
                    size: 60.0,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 34.0),

          // Title
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 17.0),

          // Subtitle
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 34.0),

          // Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                onButtonPressed?.call();
              },
              icon: CustomIconWidget(
                iconName: isWantedTab ? 'search' : 'add',
                color: colorScheme.onPrimary,
                size: 20.0,
              ),
              label: Text(
                buttonText,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onPrimary,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: EdgeInsets.symmetric(vertical: 17.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),
          SizedBox(height: 17.0),

          // Secondary Tips
          if (!isWantedTab) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color:
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'lightbulb',
                        color: AppTheme.warningOrange,
                        size: 20.0,
                      ),
                      SizedBox(width: 8.0),
                      Text(
                        'Conseils pour commencer',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 17.0),
                  _buildTipItem(
                    context,
                    'Prenez des photos de qualité',
                    'Des images claires attirent plus d\'échangeurs',
                    'camera_alt',
                    colorScheme,
                  ),
                  SizedBox(height: 8.5),
                  _buildTipItem(
                    context,
                    'Décrivez précisément vos produits',
                    'Plus de détails = plus de confiance',
                    'description',
                    colorScheme,
                  ),
                  SizedBox(height: 8.5),
                  _buildTipItem(
                    context,
                    'Indiquez ce que vous souhaitez en échange',
                    'Précisez le type de produit que vous acceptez',
                    'swap_horiz',
                    colorScheme,
                  ),
                ],
              ),
            ),
          ] else ...[
            SingleChildScrollView(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.secondary.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'search',
                          color: colorScheme.secondary,
                          size: 20.0,
                        ),
                        SizedBox(width: 8.0),
                        Text(
                          'Comment ça marche',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 17.0),
                    _buildTipItem(
                      context,
                      'Décrivez ce que vous cherchez',
                      'Soyez précis sur vos besoins',
                      'edit',
                      colorScheme,
                    ),
                    SizedBox(height: 8.5),
                    _buildTipItem(
                      context,
                      'Les autres vous proposeront',
                      'Recevez des offres d\'échange',
                      'notifications',
                      colorScheme,
                    ),
                    SizedBox(height: 8.5),
                    _buildTipItem(
                      context,
                      'Négociez et échangez',
                      'Discutez pour finaliser l\'échange',
                      'handshake',
                      colorScheme,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTipItem(
    BuildContext context,
    String title,
    String subtitle,
    String iconName,
    ColorScheme colorScheme,
  ) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32.0,
          height: 32.0,
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: CustomIconWidget(
              iconName: iconName,
              color: colorScheme.primary,
              size: 16.0,
            ),
          ),
        ),
        SizedBox(width: 12.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 4.3),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
