import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class VerificationStatusWidget extends StatelessWidget {
  final String currentTier;
  final bool isVerified;

  const VerificationStatusWidget({
    super.key,
    required this.currentTier,
    required this.isVerified,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isPremium = currentTier == 'premium';

    // Mock verification data
    final verificationItems = [
      {
        'title': 'Identité vérifiée',
        'description': 'Pièce d\'identité validée',
        'status': isPremium ? 'verified' : 'required',
        'icon': 'verified_user',
      },
      {
        'title': 'Assurance professionnelle',
        'description': 'Couverture pour les livraisons',
        'status': isPremium ? 'verified' : 'premium_required',
        'icon': 'security',
      },
      {
        'title': 'Vérification de domicile',
        'description': 'Adresse confirmée',
        'status': isPremium ? 'verified' : 'pending',
        'icon': 'home',
      },
      {
        'title': 'Antécédents judiciaires',
        'description': 'Casier judiciaire vérifié',
        'status': isPremium ? 'verified' : 'premium_required',
        'icon': 'gavel',
      },
      {
        'title': 'Formation de sécurité',
        'description': 'Formation aux bonnes pratiques',
        'status': isPremium ? 'verified' : 'premium_required',
        'icon': 'school',
      },
      {
        'title': 'Évaluation initiale',
        'description': 'Entretien et test pratique',
        'status': isPremium ? 'verified' : 'premium_required',
        'icon': 'assignment',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with verification status
        Container(
          padding: EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            gradient: isPremium
                ? LinearGradient(
                    colors: [
                      AppTheme.premiumGold.withValues(alpha: 0.1),
                      AppTheme.premiumGold.withValues(alpha: 0.2),
                    ],
                  )
                : LinearGradient(
                    colors: [
                      colorScheme.primary.withValues(alpha: 0.1),
                      colorScheme.primaryContainer.withValues(alpha: 0.2),
                    ],
                  ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPremium
                  ? AppTheme.premiumGold.withValues(alpha: 0.3)
                  : colorScheme.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: isPremium
                          ? AppTheme.premiumGold
                          : colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: CustomIconWidget(
                      iconName: isPremium ? 'verified' : 'person',
                      color: Colors.white,
                      size: 32.0,
                    ),
                  ),
                  SizedBox(width: 16.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPremium
                              ? 'Profil Vérifié Premium'
                              : 'Profil Standard',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isPremium
                                ? AppTheme.premiumGold
                                : colorScheme.primary,
                          ),
                        ),
                        Text(
                          isPremium
                              ? 'Toutes les vérifications sont complètes'
                              : 'Vérifications de base uniquement',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (isPremium) ...[
                SizedBox(height: 25.5),
                Container(
                  padding: EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildVerificationStat(
                        'Niveau de confiance',
                        '95%',
                        'security',
                        theme,
                        colorScheme,
                      ),
                      _buildVerificationStat(
                        'Badge',
                        'Premium',
                        'workspace_premium',
                        theme,
                        colorScheme,
                      ),
                      _buildVerificationStat(
                        'Statut',
                        'Vérifié',
                        'verified',
                        theme,
                        colorScheme,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        SizedBox(height: 34.0),

        Text(
          'Étapes de vérification',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),

        SizedBox(height: 17.0),

        // Verification items
        ...verificationItems.map(
          (item) => _buildVerificationItem(
            context,
            item,
            theme,
            colorScheme,
            isPremium,
          ),
        ),

        if (!isPremium) ...[
          SizedBox(height: 34.0),

          // Upgrade prompt
          Container(
            padding: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.premiumGold.withValues(alpha: 0.1),
                  AppTheme.premiumGold.withValues(alpha: 0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.premiumGold.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                CustomIconWidget(
                  iconName: 'workspace_premium',
                  color: AppTheme.premiumGold,
                  size: 48.0,
                ),
                SizedBox(height: 17.0),
                Text(
                  'Débloquez la vérification complète',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.premiumGold,
                  ),
                ),
                SizedBox(height: 8.5),
                Text(
                  'Passez Premium pour compléter toutes les vérifications et augmenter votre crédibilité',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 25.5),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _upgradeToPremium(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.premiumGold,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: CustomIconWidget(
                      iconName: 'upgrade',
                      color: Colors.white,
                      size: 20.0,
                    ),
                    label: Text(
                      'Passer Premium - 1000 FCFA',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildVerificationStat(
    String title,
    String value,
    String iconName,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Column(
      children: [
        CustomIconWidget(
          iconName: iconName,
          color: AppTheme.premiumGold,
          size: 24.0,
        ),
        SizedBox(height: 4.3),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        Text(
          title,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildVerificationItem(
    BuildContext context,
    Map<String, dynamic> item,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isPremium,
  ) {
    final status = item['status'] as String;
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case 'verified':
        statusColor = AppTheme.successGreen;
        statusText = 'Vérifié';
        statusIcon = Icons.check_circle;
        break;
      case 'required':
        statusColor = Colors.orange;
        statusText = 'Requis';
        statusIcon = Icons.pending;
        break;
      case 'pending':
        statusColor = Colors.blue;
        statusText = 'En attente';
        statusIcon = Icons.schedule;
        break;
      case 'premium_required':
        statusColor = AppTheme.premiumGold;
        statusText = 'Premium requis';
        statusIcon = Icons.star;
        break;
      default:
        statusColor = colorScheme.outline;
        statusText = 'Non démarré';
        statusIcon = Icons.circle_outlined;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 17.0),
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: status == 'verified'
              ? AppTheme.successGreen.withValues(alpha: 0.3)
              : colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: CustomIconWidget(
              iconName: item['icon'],
              color: statusColor,
              size: 24.0,
            ),
          ),
          SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'],
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  item['description'],
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 16.0),
                    SizedBox(width: 4.0),
                    Text(
                      statusText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              if (status == 'premium_required' && !isPremium) ...[
                SizedBox(height: 8.5),
                GestureDetector(
                  onTap: () => _upgradeToPremium(context),
                  child: Text(
                    'Débloquer',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.premiumGold,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _upgradeToPremium(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(
      context,
      '/delivery-partner-profile-tiers',
      arguments: {'showUpgrade': true},
    );
  }
}
