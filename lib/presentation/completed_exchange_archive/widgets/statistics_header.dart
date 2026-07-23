import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class StatisticsHeader extends StatelessWidget {
  final int totalExchanges;
  final Map<String, dynamic> storageInfo;

  const StatisticsHeader({
    Key? key,
    required this.totalExchanges,
    required this.storageInfo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final usagePercentage = storageInfo['usagePercentage'] as double;
    final totalSize = storageInfo['totalSize'] as double;

    return Container(
      margin: EdgeInsets.all(16.0),
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer.withValues(alpha: 0.3),
            colorScheme.primary.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and title
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CustomIconWidget(
                  iconName: 'assessment',
                  color: colorScheme.onPrimary,
                  size: 24.0,
                ),
              ),
              SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Archive des échanges',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Historique complet et statistiques',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 25.5),

          // Statistics cards
          Row(
            children: [
              // Total exchanges card
              Expanded(
                child: _buildStatCard(
                  'Échanges terminés',
                  totalExchanges.toString(),
                  'handshake',
                  colorScheme.primary,
                  colorScheme,
                  theme,
                ),
              ),
              SizedBox(width: 12.0),

              // Storage usage card
              Expanded(
                child: _buildStatCard(
                  'Stockage utilisé',
                  '${totalSize.toStringAsFixed(1)} KB',
                  'storage',
                  _getStorageColor(usagePercentage),
                  colorScheme,
                  theme,
                ),
              ),
            ],
          ),
          SizedBox(height: 17.0),

          // Storage usage bar
          _buildStorageUsageBar(usagePercentage, colorScheme, theme),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    String iconName,
    Color iconColor,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Container(
      padding: EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.0),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomIconWidget(
                  iconName: iconName,
                  color: iconColor,
                  size: 16.0,
                ),
              ),
              const Spacer(),
            ],
          ),
          SizedBox(height: 12.8),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 4.3),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageUsageBar(
    double percentage,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    final storageColor = _getStorageColor(percentage);

    return Container(
      padding: EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Utilisation de l\'espace',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: storageColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.5),

          // Progress bar
          Container(
            height: 8.5,
            decoration: BoxDecoration(
              color: colorScheme.outline.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (percentage / 100).clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: storageColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          SizedBox(height: 8.5),

          // Storage info
          Row(
            children: [
              CustomIconWidget(
                iconName: percentage > 80 ? 'warning' : 'info',
                color: storageColor,
                size: 16.0,
              ),
              SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  percentage > 80
                      ? 'Espace bientôt saturé. Les anciens échanges seront supprimés automatiquement.'
                      : 'Les échanges sont automatiquement supprimés après 6 mois.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStorageColor(double percentage) {
    if (percentage > 80) {
      return AppTheme.errorRed;
    } else if (percentage > 60) {
      return AppTheme.warningOrange;
    } else {
      return AppTheme.successGreen;
    }
  }
}
