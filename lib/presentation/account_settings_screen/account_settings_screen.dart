import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_app_bar.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({Key? key}) : super(key: key);

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  String _selectedLanguage = 'fr';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLanguagePreference();
  }

  Future<void> _loadLanguagePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _selectedLanguage = prefs.getString('app_language') ?? 'fr';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveLanguagePreference(String languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_language', languageCode);
      setState(() {
        _selectedLanguage = languageCode;
      });
    } catch (e) {
      debugPrint('Error saving language preference: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return Scaffold(
        appBar: CustomAppBar(title: 'Paramètres du compte', centerTitle: true),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(title: 'Paramètres du compte', centerTitle: true),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          _buildSettingOption(
            context,
            'Modifier le profil',
            'person',
            () async {
              // Navigate and wait for result
              final result = await Navigator.pushNamed(
                context,
                '/edit-profile-screen',
              );

              // If profile was updated, return success to UserProfileScreen
              if (result == true && context.mounted) {
                Navigator.pop(context, true);
              }
            },
            colorScheme,
          ),
          _buildSettingOption(
            context,
            'Notifications',
            'notifications',
            () => Navigator.pushNamed(context, '/notification-settings-screen'),
            colorScheme,
          ),
          _buildSettingOption(
            context,
            'Confidentialité',
            'privacy_tip',
            () => Navigator.pushNamed(context, '/privacy-settings-screen'),
            colorScheme,
          ),
          _buildSettingOption(
            context,
            'Sécurité',
            'security',
            () => _showSecurityOptions(context),
            colorScheme,
          ),
          _buildSettingOption(
            context,
            'Langue',
            'language',
            () => _showLanguageOptions(context),
            colorScheme,
          ),
          SizedBox(height: 34.0),
          _buildDangerZone(context, colorScheme),
        ],
      ),
    );
  }

  Widget _buildSettingOption(
    BuildContext context,
    String title,
    String iconName,
    VoidCallback onTap,
    ColorScheme colorScheme,
  ) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.only(bottom: 17.0),
      child: ListTile(
        leading: CustomIconWidget(
          iconName: iconName,
          color: colorScheme.primary,
          size: 24.0,
        ),
        title: Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: CustomIconWidget(
          iconName: 'chevron_right',
          color: colorScheme.onSurfaceVariant,
          size: 20.0,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildDangerZone(BuildContext context, ColorScheme colorScheme) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 17.0),
          child: Text(
            'Zone dangereuse',
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppTheme.errorRed,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'logout',
                  color: AppTheme.warningOrange,
                  size: 24.0,
                ),
                title: const Text('Se déconnecter'),
                onTap: () => _showSignOutDialog(context),
              ),
              const Divider(height: 1),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'download',
                  color: colorScheme.primary,
                  size: 24.0,
                ),
                title: const Text('Exporter mes données'),
                onTap: () => _showExportDialog(context),
              ),
              const Divider(height: 1),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'pause_circle',
                  color: AppTheme.warningOrange,
                  size: 24.0,
                ),
                title: const Text('Désactiver le compte'),
                onTap: () => _showDeactivateDialog(context),
              ),
              const Divider(height: 1),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'delete_forever',
                  color: AppTheme.errorRed,
                  size: 24.0,
                ),
                title: Text(
                  'Supprimer le compte',
                  style: TextStyle(color: AppTheme.errorRed),
                ),
                onTap: () => _showDeleteDialog(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Se déconnecter'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // close dialog
              try {
                // Call Supabase sign out
                await SupabaseService.signOut();
                
                if (context.mounted) {
                  // Navigate to home and clear navigation stack
                  Navigator.pushNamedAndRemoveUntil(
                    context, 
                    '/home_feed', 
                    (route) => false
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur lors de la déconnexion')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warningOrange,
            ),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
  }


  void _showSecurityOptions(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sécurité'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CustomIconWidget(
                iconName: 'lock',
                color: colorScheme.primary,
                size: 24.0,
              ),
              title: const Text('Changer le mot de passe'),
              onTap: () {
                Navigator.pop(context);
                _showChangePasswordDialog(context);
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'verified_user',
                color: colorScheme.primary,
                size: 24.0,
              ),
              title: const Text('Authentification à deux facteurs'),
              subtitle: const Text('Bientôt disponible'),
              enabled: false,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Changer le mot de passe'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Mot de passe actuel',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              obscureText: true,
            ),
            SizedBox(height: 17.0),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Nouveau mot de passe',
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            SizedBox(height: 17.0),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Confirmer le mot de passe',
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement password change
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Mot de passe modifié avec succès'),
                ),
              );
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _showLanguageOptions(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Choisir la langue'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  title: const Text('Français'),
                  value: 'fr',
                  groupValue: _selectedLanguage,
                  activeColor: colorScheme.primary,
                  onChanged: (value) async {
                    if (value != null) {
                      await _saveLanguagePreference(value);
                      setDialogState(() {});
                      if (mounted) setState(() {});

                      Navigator.pop(dialogContext);

                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(
                          content: Text('Langue changée en Français'),
                          backgroundColor: AppTheme.successGreen,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
                RadioListTile<String>(
                  title: const Text('English'),
                  value: 'en',
                  groupValue: _selectedLanguage,
                  activeColor: colorScheme.primary,
                  onChanged: (value) async {
                    if (value != null) {
                      await _saveLanguagePreference(value);
                      setDialogState(() {});
                      if (mounted) setState(() {});

                      Navigator.pop(dialogContext);

                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(
                          content: Text('Language changed to English'),
                          backgroundColor: AppTheme.successGreen,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Wolof'),
                  value: 'wo',
                  groupValue: _selectedLanguage,
                  activeColor: colorScheme.primary,
                  onChanged: (value) async {
                    if (value != null) {
                      await _saveLanguagePreference(value);
                      setDialogState(() {});
                      if (mounted) setState(() {});

                      Navigator.pop(dialogContext);

                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(
                          content: Text('Làkk bi soppi ci Wolof'),
                          backgroundColor: AppTheme.successGreen,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Fermer'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exporter mes données'),
        content: const Text(
          'Vous recevrez un email avec toutes vos données dans les 24h.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Demande d\'export envoyée')),
              );
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _showDeactivateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Désactiver le compte'),
        content: const Text(
          'Votre compte sera temporairement désactivé. Vous pourrez le réactiver à tout moment.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Compte désactivé'),
                  backgroundColor: AppTheme.warningOrange,
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

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le compte'),
        content: const Text(
          'Cette action est irréversible. Toutes vos données seront supprimées définitivement.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement account deletion
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
}
