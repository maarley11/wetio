import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class PremiumBenefitsSection extends StatelessWidget {
  final Function(Map<String, dynamic>) onDataChanged;

  const PremiumBenefitsSection({
    super.key,
    required this.onDataChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final benefits = [
      {
        'icon': Icons.priority_high,
        'title': 'Réservations prioritaires',
        'description': 'Recevez les meilleures offres de livraison en premier',
        'color': Colors.orange,
      },
      {
        'icon': Icons.trending_up,
        'title': 'Commission améliorée',
        'description': 'Gagnez jusqu\'à 25% de plus par livraison',
        'color': Colors.green,
      },
      {
        'icon': Icons.verified_user,
        'title': 'Badge partenaire vérifié',
        'description': 'Profil certifié avec badge premium visible',
        'color': Colors.blue,
      },
      {
        'icon': Icons.support_agent,
        'title': 'Support prioritaire',
        'description': 'Assistance dédiée 24h/7j pour les partenaires premium',
        'color': Colors.purple,
      },
      {
        'icon': Icons.flash_on,
        'title': 'Livraisons express',
        'description': 'Accès aux livraisons urgentes et express',
        'color': Colors.red,
      },
      {
        'icon': Icons.analytics,
        'title': 'Statistiques avancées',
        'description': 'Tableaux de bord détaillés de vos performances',
        'color': Colors.teal,
      },
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with premium badge
          Container(
            padding: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withValues(alpha: 0.1),
                  colorScheme.primaryContainer.withValues(alpha: 0.3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.diamond,
                  size: 48,
                  color: colorScheme.primary,
                ),
                SizedBox(height: 17.0),
                Text(
                  'WETIO Premium Partner',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                SizedBox(height: 8.5),
                Text(
                  'Rejoignez l\'élite des livreurs WETIO',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          SizedBox(height: 25.5),

          // Registration fee highlight
          Container(
            padding: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.payment,
                    color: colorScheme.onPrimary,
                    size: 24,
                  ),
                ),
                SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Frais d\'inscription unique',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '500 FCFA - Paiement sécurisé',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 25.5),

          Text(
            'Avantages Premium',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),

          SizedBox(height: 17.0),

          // Benefits list
          ...benefits.map((benefit) => _buildBenefitCard(
                context,
                benefit['icon'] as IconData,
                benefit['title'] as String,
                benefit['description'] as String,
                benefit['color'] as Color,
                colorScheme,
                theme,
              )),

          SizedBox(height: 25.5),

          // Success guarantee
          Container(
            padding: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.successGreen.withValues(alpha: 0.1),
                  AppTheme.successGreen.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: AppTheme.successGreen,
                  size: 32,
                ),
                SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Garantie de satisfaction',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.successGreen,
                        ),
                      ),
                      Text(
                        'Si vous n\'êtes pas satisfait dans les 30 premiers jours, nous vous remboursons intégralement.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitCard(
    BuildContext context,
    IconData icon,
    String title,
    String description,
    Color iconColor,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 17.0),
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 4.3),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
