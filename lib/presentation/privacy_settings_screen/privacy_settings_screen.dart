import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({Key? key}) : super(key: key);

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  // Profile visibility settings
  String _profileVisibility = 'public';
  bool _requireApproval = false;

  // Exchange history privacy
  String _exchangeHistoryVisibility = 'partners_only';

  // Location sharing settings
  bool _preciseLocation = true;
  bool _cityLevelOnly = false;
  bool _manualLocation = false;

  // Contact information visibility
  bool _showPhone = false;
  bool _showEmail = false;

  // Data collection preferences
  bool _analyticsParticipation = true;
  bool _crashReporting = true;
  bool _usageStatistics = true;

  // Account security
  bool _twoFactorAuth = false;
  bool _loginNotifications = true;
  bool _suspiciousActivityAlerts = true;

  bool _hasChanges = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Paramètres de confidentialité',
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _saveSettings,
              child: Text(
                'Enregistrer',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with icon
            Container(
              padding: EdgeInsets.all(16.0),
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: CustomIconWidget(
                      iconName: 'security',
                      color: colorScheme.onPrimary,
                      size: 32.0,
                    ),
                  ),
                  SizedBox(width: 12.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Protégez vos données',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Contrôlez qui peut voir vos informations',
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

            SizedBox(height: 17.0),

            // Profile Visibility Section
            _buildSection(
              context,
              'Visibilité du profil',
              'Contrôlez qui peut voir votre profil',
              [
                _buildRadioOption(
                  context,
                  'Complètement public',
                  'Tout le monde peut voir votre profil',
                  'public',
                  _profileVisibility,
                  (value) {
                    setState(() {
                      _profileVisibility = value!;
                      _hasChanges = true;
                    });
                  },
                ),
                _buildRadioOption(
                  context,
                  'Utilisateurs inscrits uniquement',
                  'Seuls les utilisateurs WETIO peuvent voir',
                  'registered',
                  _profileVisibility,
                  (value) {
                    setState(() {
                      _profileVisibility = value!;
                      _hasChanges = true;
                    });
                  },
                ),
                _buildRadioOption(
                  context,
                  'Privé',
                  'Approbation manuelle requise',
                  'private',
                  _profileVisibility,
                  (value) {
                    setState(() {
                      _profileVisibility = value!;
                      _hasChanges = true;
                    });
                  },
                ),
                if (_profileVisibility == 'private')
                  _buildSwitchTile(
                    context,
                    'Approbation manuelle',
                    'Vous approuvez chaque demande de vue',
                    _requireApproval,
                    (value) {
                      setState(() {
                        _requireApproval = value;
                        _hasChanges = true;
                      });
                    },
                  ),
              ],
            ),

            // Exchange History Privacy Section
            _buildSection(
              context,
              'Historique des échanges',
              'Gérez la visibilité de vos échanges terminés',
              [
                _buildRadioOption(
                  context,
                  'Caché du public',
                  'Personne ne peut voir votre historique',
                  'hidden',
                  _exchangeHistoryVisibility,
                  (value) {
                    setState(() {
                      _exchangeHistoryVisibility = value!;
                      _hasChanges = true;
                    });
                  },
                ),
                _buildRadioOption(
                  context,
                  'Partenaires d\'échange uniquement',
                  'Visible seulement par vos partenaires',
                  'partners_only',
                  _exchangeHistoryVisibility,
                  (value) {
                    setState(() {
                      _exchangeHistoryVisibility = value!;
                      _hasChanges = true;
                    });
                  },
                ),
                _buildRadioOption(
                  context,
                  'Public',
                  'Visible pour construire votre réputation',
                  'public',
                  _exchangeHistoryVisibility,
                  (value) {
                    setState(() {
                      _exchangeHistoryVisibility = value!;
                      _hasChanges = true;
                    });
                  },
                ),
              ],
            ),

            // Location Sharing Section
            _buildSection(
              context,
              'Partage de localisation',
              'Contrôlez comment votre position est partagée',
              [
                _buildSwitchTile(
                  context,
                  'Position précise',
                  'Partager votre localisation exacte',
                  _preciseLocation,
                  (value) {
                    setState(() {
                      _preciseLocation = value;
                      if (value) {
                        _cityLevelOnly = false;
                        _manualLocation = false;
                      }
                      _hasChanges = true;
                    });
                  },
                ),
                _buildSwitchTile(
                  context,
                  'Niveau ville uniquement',
                  'Ne montrer que votre ville',
                  _cityLevelOnly,
                  (value) {
                    setState(() {
                      _cityLevelOnly = value;
                      if (value) {
                        _preciseLocation = false;
                        _manualLocation = false;
                      }
                      _hasChanges = true;
                    });
                  },
                ),
                _buildSwitchTile(
                  context,
                  'Saisie manuelle',
                  'Entrer manuellement votre localisation',
                  _manualLocation,
                  (value) {
                    setState(() {
                      _manualLocation = value;
                      if (value) {
                        _preciseLocation = false;
                        _cityLevelOnly = false;
                      }
                      _hasChanges = true;
                    });
                  },
                ),
              ],
            ),

            // Contact Information Visibility Section
            _buildSection(
              context,
              'Visibilité des coordonnées',
              'Contrôlez qui peut voir vos coordonnées',
              [
                _buildSwitchTile(
                  context,
                  'Afficher le numéro de téléphone',
                  'Visible dans votre profil',
                  _showPhone,
                  (value) {
                    setState(() {
                      _showPhone = value;
                      _hasChanges = true;
                    });
                  },
                ),
                _buildSwitchTile(
                  context,
                  'Afficher l\'adresse e-mail',
                  'Visible dans votre profil',
                  _showEmail,
                  (value) {
                    setState(() {
                      _showEmail = value;
                      _hasChanges = true;
                    });
                  },
                ),
              ],
            ),

            // Data Collection Section
            _buildSection(
              context,
              'Collecte de données',
              'Gérez comment vos données sont utilisées',
              [
                _buildSwitchTile(
                  context,
                  'Participation aux analyses',
                  'Aide à améliorer WETIO',
                  _analyticsParticipation,
                  (value) {
                    setState(() {
                      _analyticsParticipation = value;
                      _hasChanges = true;
                    });
                  },
                ),
                _buildSwitchTile(
                  context,
                  'Rapports de plantage',
                  'Envoi automatique des erreurs',
                  _crashReporting,
                  (value) {
                    setState(() {
                      _crashReporting = value;
                      _hasChanges = true;
                    });
                  },
                ),
                _buildSwitchTile(
                  context,
                  'Statistiques d\'utilisation',
                  'Partager les données d\'utilisation',
                  _usageStatistics,
                  (value) {
                    setState(() {
                      _usageStatistics = value;
                      _hasChanges = true;
                    });
                  },
                ),
              ],
            ),

            // Account Security Section
            _buildSection(
              context,
              'Sécurité du compte',
              'Protégez votre compte',
              [
                _buildSwitchTile(
                  context,
                  'Authentification à deux facteurs',
                  'Sécurité supplémentaire pour votre compte',
                  _twoFactorAuth,
                  (value) {
                    setState(() {
                      _twoFactorAuth = value;
                      _hasChanges = true;
                    });
                    if (value) {
                      _showTwoFactorSetup(context);
                    }
                  },
                ),
                _buildSwitchTile(
                  context,
                  'Notifications de connexion',
                  'Alertes lors de nouvelles connexions',
                  _loginNotifications,
                  (value) {
                    setState(() {
                      _loginNotifications = value;
                      _hasChanges = true;
                    });
                  },
                ),
                _buildSwitchTile(
                  context,
                  'Alertes d\'activité suspecte',
                  'Notification en cas d\'activité inhabituelle',
                  _suspiciousActivityAlerts,
                  (value) {
                    setState(() {
                      _suspiciousActivityAlerts = value;
                      _hasChanges = true;
                    });
                  },
                ),
              ],
            ),

            // Data Management Section
            _buildSection(
              context,
              'Gestion des données',
              'Exportez ou supprimez vos données',
              [
                _buildActionTile(
                  context,
                  'Exporter mes données',
                  'Télécharger toutes vos données en PDF',
                  'download',
                  () => _exportData(context),
                ),
                _buildActionTile(
                  context,
                  'Désactiver temporairement',
                  'Votre compte sera mis en pause',
                  'pause_circle',
                  () => _showDeactivateDialog(context),
                ),
                _buildActionTile(
                  context,
                  'Supprimer définitivement',
                  'Cette action est irréversible',
                  'delete_forever',
                  () => _showDeleteAccountDialog(context),
                  isDestructive: true,
                ),
              ],
            ),

            SizedBox(height: 34.0),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    String subtitle,
    List<Widget> children,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 17.0),
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
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
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
          Divider(
            height: 1,
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRadioOption(
    BuildContext context,
    String title,
    String subtitle,
    String value,
    String groupValue,
    ValueChanged<String?> onChanged,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return RadioListTile<String>(
      title: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      activeColor: colorScheme.primary,
    );
  }

  Widget _buildSwitchTile(
    BuildContext context,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SwitchListTile(
      title: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: colorScheme.primary,
    );
  }

  Widget _buildActionTile(
    BuildContext context,
    String title,
    String subtitle,
    String iconName,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: isDestructive
              ? AppTheme.errorRed.withValues(alpha: 0.1)
              : colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: CustomIconWidget(
          iconName: iconName,
          color: isDestructive ? AppTheme.errorRed : colorScheme.primary,
          size: 20.0,
        ),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: isDestructive ? AppTheme.errorRed : colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: CustomIconWidget(
        iconName: 'chevron_right',
        color: colorScheme.onSurfaceVariant,
        size: 20.0,
      ),
      onTap: onTap,
    );
  }

  void _saveSettings() {
    HapticFeedback.lightImpact();

    // In a real app, save to Supabase
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Paramètres de confidentialité enregistrés'),
        backgroundColor: AppTheme.successGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );

    setState(() {
      _hasChanges = false;
    });
  }

  void _showTwoFactorSetup(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Row(
          children: [
            CustomIconWidget(
              iconName: 'security',
              color: colorScheme.primary,
              size: 24.0,
            ),
            SizedBox(width: 8.0),
            Text(
              'Configuration 2FA',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'L\'authentification à deux facteurs ajoute une couche de sécurité supplémentaire à votre compte.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 17.0),
            Text(
              'Un code sera envoyé à votre téléphone lors de chaque connexion.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _twoFactorAuth = false;
                _hasChanges = true;
              });
              Navigator.pop(context);
            },
            child: Text(
              'Annuler',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('2FA activé avec succès'),
                  backgroundColor: AppTheme.successGreen,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Activer'),
          ),
        ],
      ),
    );
  }

  void _exportData(BuildContext context) {
    HapticFeedback.lightImpact();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Row(
          children: [
            CustomIconWidget(
              iconName: 'download',
              color: colorScheme.primary,
              size: 24.0,
            ),
            SizedBox(width: 8.0),
            Text(
              'Exporter mes données',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Nous allons préparer un fichier PDF contenant toutes vos données.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 17.0),
            Container(
              padding: EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'schedule',
                    color: colorScheme.primary,
                    size: 20.0,
                  ),
                  SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      'Traitement : 24-48 heures',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'Demande d\'export enregistrée. Vous recevrez un e-mail.',
                  ),
                  backgroundColor: AppTheme.successGreen,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _showDeactivateDialog(BuildContext context) {
    HapticFeedback.mediumImpact();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Row(
          children: [
            CustomIconWidget(
              iconName: 'pause_circle',
              color: AppTheme.warningOrange,
              size: 24.0,
            ),
            SizedBox(width: 8.0),
            Text(
              'Désactiver le compte',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Votre compte sera temporairement désactivé :',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 17.0),
            _buildConsequenceItem(
              context,
              'Votre profil ne sera plus visible',
            ),
            _buildConsequenceItem(
              context,
              'Vos annonces seront masquées',
            ),
            _buildConsequenceItem(
              context,
              'Vous pouvez le réactiver à tout moment',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Compte désactivé temporairement'),
                  backgroundColor: AppTheme.warningOrange,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warningOrange,
            ),
            child: const Text('Désactiver'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    HapticFeedback.heavyImpact();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Row(
          children: [
            CustomIconWidget(
              iconName: 'delete_forever',
              color: AppTheme.errorRed,
              size: 24.0,
            ),
            SizedBox(width: 8.0),
            Text(
              'Supprimer le compte',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.errorRed,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cette action est IRRÉVERSIBLE :',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.errorRed,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 17.0),
            _buildConsequenceItem(
              context,
              'Toutes vos données seront supprimées',
            ),
            _buildConsequenceItem(
              context,
              'Vos annonces seront retirées',
            ),
            _buildConsequenceItem(
              context,
              'Votre historique sera effacé',
            ),
            _buildConsequenceItem(
              context,
              'Vous ne pourrez pas récupérer votre compte',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login-screen',
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Widget _buildConsequenceItem(BuildContext context, String text) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.3),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: 'check_circle',
            color: colorScheme.primary,
            size: 16.0,
          ),
          SizedBox(width: 8.0),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
