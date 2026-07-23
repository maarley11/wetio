import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _isLoading = true;
  bool _hasChanges = false;

  // Global notification toggle
  bool _notificationsEnabled = true;

  // Exchange notifications
  bool _newExchangeProposals = true;
  bool _exchangeConfirmations = true;
  bool _deliveryUpdates = true;
  bool _exchangeCompletions = true;

  // Message notifications
  bool _newMessages = true;
  bool _typingIndicators = true;
  bool _readReceipts = true;

  // Marketing communications
  bool _promotionalOffers = false;
  bool _appUpdates = true;
  bool _newsletter = false;

  // Delivery notifications
  bool _partnerAvailability = true;
  bool _bookingConfirmations = true;
  bool _trackingUpdates = true;

  // Notification preferences
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  // Quiet hours
  bool _quietHoursEnabled = false;
  TimeOfDay _quietHoursStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietHoursEnd = const TimeOfDay(hour: 8, minute: 0);

  // Frequency control
  String _notificationFrequency = 'immediate'; // immediate, daily, weekly

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    await Future.delayed(const Duration(milliseconds: 500));

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return Scaffold(
        appBar: CustomAppBar(
          title: 'Paramètres de notification',
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        if (_hasChanges) {
          await _saveSettings();
        }
        return true;
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Paramètres de notification',
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              _buildGlobalToggle(theme, colorScheme),
              if (_notificationsEnabled) ...[
                _buildSectionHeader(
                  'Notifications d\'échange',
                  'swap_horiz',
                  theme,
                  colorScheme,
                ),
                _buildExchangeNotifications(theme),
                _buildDivider(),
                _buildSectionHeader(
                  'Notifications de message',
                  'chat_bubble_outline',
                  theme,
                  colorScheme,
                ),
                _buildMessageNotifications(theme),
                _buildDivider(),
                _buildSectionHeader(
                  'Notifications de livraison',
                  'local_shipping',
                  theme,
                  colorScheme,
                ),
                _buildDeliveryNotifications(theme),
                _buildDivider(),
                _buildSectionHeader(
                  'Communications marketing',
                  'campaign',
                  theme,
                  colorScheme,
                ),
                _buildMarketingCommunications(theme),
                _buildDivider(),
                _buildSectionHeader(
                  'Préférences sonores',
                  'volume_up',
                  theme,
                  colorScheme,
                ),
                _buildSoundPreferences(theme),
                _buildDivider(),
                _buildSectionHeader(
                  'Heures silencieuses',
                  'bedtime',
                  theme,
                  colorScheme,
                ),
                _buildQuietHours(theme, colorScheme),
                _buildDivider(),
                _buildSectionHeader(
                  'Fréquence des notifications',
                  'schedule',
                  theme,
                  colorScheme,
                ),
                _buildFrequencyControl(theme),
              ],
              SizedBox(height: 34.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlobalToggle(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(16.0),
      color: colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: CustomIconWidget(
              iconName: 'notifications_active',
              color: colorScheme.primary,
              size: 32.0,
            ),
          ),
          SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Toutes les notifications',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4.3),
                Text(
                  _notificationsEnabled
                      ? 'Notifications activées'
                      : 'Notifications désactivées',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
                _hasChanges = true;
              });
              HapticFeedback.lightImpact();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    String iconName,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.0, 25.5, 16.0, 8.5),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: iconName,
            color: colorScheme.primary,
            size: 24.0,
          ),
          SizedBox(width: 8.0),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExchangeNotifications(ThemeData theme) {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Nouvelles propositions d\'échange'),
          subtitle: const Text('Notification lors de nouvelles propositions'),
          value: _newExchangeProposals,
          onChanged: (value) {
            setState(() {
              _newExchangeProposals = value;
              _hasChanges = true;
            });
          },
        ),
        SwitchListTile(
          title: const Text('Confirmations d\'échange'),
          subtitle: const Text('Notification quand un échange est confirmé'),
          value: _exchangeConfirmations,
          onChanged: (value) {
            setState(() {
              _exchangeConfirmations = value;
              _hasChanges = true;
            });
          },
        ),
        SwitchListTile(
          title: const Text('Mises à jour de livraison'),
          subtitle: const Text('Notifications sur le statut de la livraison'),
          value: _deliveryUpdates,
          onChanged: (value) {
            setState(() {
              _deliveryUpdates = value;
              _hasChanges = true;
            });
          },
        ),
        SwitchListTile(
          title: const Text('Échange terminé'),
          subtitle: const Text('Notification de fin d\'échange'),
          value: _exchangeCompletions,
          onChanged: (value) {
            setState(() {
              _exchangeCompletions = value;
              _hasChanges = true;
            });
          },
        ),
      ],
    );
  }

  Widget _buildMessageNotifications(ThemeData theme) {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Nouveaux messages'),
          subtitle: const Text('Notification pour chaque nouveau message'),
          value: _newMessages,
          onChanged: (value) {
            setState(() {
              _newMessages = value;
              _hasChanges = true;
            });
          },
        ),
        SwitchListTile(
          title: const Text('Indicateurs de saisie'),
          subtitle: const Text('Afficher quand quelqu\'un tape'),
          value: _typingIndicators,
          onChanged: (value) {
            setState(() {
              _typingIndicators = value;
              _hasChanges = true;
            });
          },
        ),
        SwitchListTile(
          title: const Text('Accusés de lecture'),
          subtitle: const Text('Notification quand vos messages sont lus'),
          value: _readReceipts,
          onChanged: (value) {
            setState(() {
              _readReceipts = value;
              _hasChanges = true;
            });
          },
        ),
      ],
    );
  }

  Widget _buildDeliveryNotifications(ThemeData theme) {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Disponibilité des livreurs'),
          subtitle: const Text('Alertes sur les livreurs disponibles'),
          value: _partnerAvailability,
          onChanged: (value) {
            setState(() {
              _partnerAvailability = value;
              _hasChanges = true;
            });
          },
        ),
        SwitchListTile(
          title: const Text('Confirmations de réservation'),
          subtitle: const Text('Notification de confirmation de livraison'),
          value: _bookingConfirmations,
          onChanged: (value) {
            setState(() {
              _bookingConfirmations = value;
              _hasChanges = true;
            });
          },
        ),
        SwitchListTile(
          title: const Text('Suivi en temps réel'),
          subtitle: const Text('Mises à jour de la position du livreur'),
          value: _trackingUpdates,
          onChanged: (value) {
            setState(() {
              _trackingUpdates = value;
              _hasChanges = true;
            });
          },
        ),
      ],
    );
  }

  Widget _buildMarketingCommunications(ThemeData theme) {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Offres promotionnelles'),
          subtitle: const Text('Offres spéciales et réductions'),
          value: _promotionalOffers,
          onChanged: (value) {
            setState(() {
              _promotionalOffers = value;
              _hasChanges = true;
            });
          },
        ),
        SwitchListTile(
          title: const Text('Mises à jour de l\'application'),
          subtitle: const Text('Nouvelles fonctionnalités et améliorations'),
          value: _appUpdates,
          onChanged: (value) {
            setState(() {
              _appUpdates = value;
              _hasChanges = true;
            });
          },
        ),
        SwitchListTile(
          title: const Text('Newsletter WETIO'),
          subtitle: const Text('Actualités et conseils d\'échange'),
          value: _newsletter,
          onChanged: (value) {
            setState(() {
              _newsletter = value;
              _hasChanges = true;
            });
          },
        ),
      ],
    );
  }

  Widget _buildSoundPreferences(ThemeData theme) {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Son des notifications'),
          subtitle: const Text('Jouer un son lors de nouvelles notifications'),
          value: _soundEnabled,
          onChanged: (value) {
            setState(() {
              _soundEnabled = value;
              _hasChanges = true;
            });
          },
        ),
        SwitchListTile(
          title: const Text('Vibration'),
          subtitle: const Text('Activer la vibration pour les notifications'),
          value: _vibrationEnabled,
          onChanged: (value) {
            setState(() {
              _vibrationEnabled = value;
              _hasChanges = true;
            });
          },
        ),
      ],
    );
  }

  Widget _buildQuietHours(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Activer les heures silencieuses'),
          subtitle:
              const Text('Désactiver les notifications pendant une période'),
          value: _quietHoursEnabled,
          onChanged: (value) {
            setState(() {
              _quietHoursEnabled = value;
              _hasChanges = true;
            });
          },
        ),
        if (_quietHoursEnabled) ...[
          ListTile(
            leading: const Icon(Icons.nightlight_round),
            title: const Text('Début'),
            subtitle: Text(_formatTime(_quietHoursStart)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _selectTime(true),
          ),
          ListTile(
            leading: const Icon(Icons.wb_sunny_rounded),
            title: const Text('Fin'),
            subtitle: Text(_formatTime(_quietHoursEnd)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _selectTime(false),
          ),
        ],
      ],
    );
  }

  Widget _buildFrequencyControl(ThemeData theme) {
    return Column(
      children: [
        RadioListTile<String>(
          title: const Text('Immédiate'),
          subtitle: const Text('Recevoir les notifications immédiatement'),
          value: 'immediate',
          groupValue: _notificationFrequency,
          onChanged: (value) {
            setState(() {
              _notificationFrequency = value!;
              _hasChanges = true;
            });
          },
        ),
        RadioListTile<String>(
          title: const Text('Résumé quotidien'),
          subtitle: const Text('Une notification par jour avec résumé'),
          value: 'daily',
          groupValue: _notificationFrequency,
          onChanged: (value) {
            setState(() {
              _notificationFrequency = value!;
              _hasChanges = true;
            });
          },
        ),
        RadioListTile<String>(
          title: const Text('Résumé hebdomadaire'),
          subtitle: const Text('Une notification par semaine avec résumé'),
          value: 'weekly',
          groupValue: _notificationFrequency,
          onChanged: (value) {
            setState(() {
              _notificationFrequency = value!;
              _hasChanges = true;
            });
          },
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey.withValues(alpha: 0.2),
    );
  }

  Future<void> _selectTime(bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _quietHoursStart : _quietHoursEnd,
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _quietHoursStart = picked;
        } else {
          _quietHoursEnd = picked;
        }
        _hasChanges = true;
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _saveSettings() async {
    if (!_hasChanges) return;

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      _showSuccessSnackBar('Paramètres enregistrés avec succès');

      setState(() => _hasChanges = false);
    } catch (e) {
      _showErrorSnackBar('Erreur lors de l\'enregistrement des paramètres');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
