import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ArchiveEmptyState extends StatelessWidget {
  final bool hasExchanges;
  final String searchQuery;
  final VoidCallback? onClearSearch;

  const ArchiveEmptyState({
    Key? key,
    required this.hasExchanges,
    required this.searchQuery,
    this.onClearSearch,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (searchQuery.isNotEmpty) {
      // Search results empty state
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(32.0),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: CustomIconWidget(
                  iconName: 'search_off',
                  color: colorScheme.primary,
                  size: 60.0,
                ),
              ),
              SizedBox(height: 34.0),
              Text(
                'Aucun résultat trouvé',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 17.0),
              Text(
                'Nous n\'avons trouvé aucun échange terminé correspondant à "${searchQuery}".',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 34.0),
              ElevatedButton.icon(
                onPressed: onClearSearch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 12.0,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: CustomIconWidget(
                  iconName: 'clear',
                  color: colorScheme.onPrimary,
                  size: 20.0,
                ),
                label: Text(
                  'Effacer la recherche',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!hasExchanges) {
      // No completed exchanges at all
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(32.0),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: CustomIconWidget(
                  iconName: 'history',
                  color: colorScheme.primary,
                  size: 80.0,
                ),
              ),
              SizedBox(height: 34.0),
              Text(
                'Aucun échange archivé',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 17.0),
              Text(
                'Vos échanges terminés apparaîtront ici automatiquement. '
                'Une fois archivés, ils seront supprimés après 6 mois pour optimiser l\'espace de stockage.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 34.0),

              // Features of the archive
              Container(
                padding: EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fonctionnalités de l\'archive :',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 17.0),
                    _buildFeatureItem(
                      'Historique complet des échanges',
                      'check_circle',
                      AppTheme.successGreen,
                      colorScheme,
                      theme,
                    ),
                    SizedBox(height: 8.5),
                    _buildFeatureItem(
                      'Évaluations mutuelles',
                      'star',
                      AppTheme.warningOrange,
                      colorScheme,
                      theme,
                    ),
                    SizedBox(height: 8.5),
                    _buildFeatureItem(
                      'Export PDF disponible',
                      'file_download',
                      colorScheme.primary,
                      colorScheme,
                      theme,
                    ),
                    SizedBox(height: 8.5),
                    _buildFeatureItem(
                      'Suppression automatique après 6 mois',
                      'schedule',
                      colorScheme.secondary,
                      colorScheme,
                      theme,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 34.0),

              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 12.0,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: CustomIconWidget(
                  iconName: 'arrow_back',
                  color: colorScheme.onPrimary,
                  size: 20.0,
                ),
                label: Text(
                  'Retour au profil',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Has exchanges but filters show empty results
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(32.0),
              decoration: BoxDecoration(
                color: AppTheme.warningOrange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: CustomIconWidget(
                iconName: 'filter_alt_off',
                color: AppTheme.warningOrange,
                size: 60.0,
              ),
            ),
            SizedBox(height: 34.0),
            Text(
              'Aucun échange avec ces filtres',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 17.0),
            Text(
              'Essayez de modifier vos critères de filtrage ou de tri pour voir plus d\'échanges.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
    String text,
    String iconName,
    Color iconColor,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Row(
      children: [
        CustomIconWidget(
          iconName: iconName,
          color: iconColor,
          size: 16.0,
        ),
        SizedBox(width: 12.0),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
