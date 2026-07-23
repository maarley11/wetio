import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class UpgradeFlowWidget extends StatefulWidget {
  final String currentTier;
  final String targetTier;
  final VoidCallback onUpgrade;
  final bool isProcessing;
  final bool isModal;

  const UpgradeFlowWidget({
    super.key,
    required this.currentTier,
    required this.targetTier,
    required this.onUpgrade,
    this.isProcessing = false,
    this.isModal = false,
  });

  @override
  State<UpgradeFlowWidget> createState() => _UpgradeFlowWidgetState();
}

class _UpgradeFlowWidgetState extends State<UpgradeFlowWidget> {
  int _currentStep = 0;
  String _selectedPaymentMethod = 'mobile_money';

  final List<Map<String, dynamic>> _upgradeSteps = [
    {
      'title': 'Avantages Premium',
      'description': 'Découvrez tout ce que vous obtiendrez',
      'icon': 'stars',
    },
    {
      'title': 'Méthode de paiement',
      'description': 'Choisissez votre mode de paiement',
      'icon': 'payment',
    },
    {
      'title': 'Confirmation',
      'description': 'Finalisez votre upgrade',
      'icon': 'check_circle',
    },
  ];

  final List<Map<String, dynamic>> _premiumBenefits = [
    {
      'icon': 'trending_up',
      'title': 'Revenus +15%',
      'description': 'Commission réduite pour plus de gains',
    },
    {
      'icon': 'verified',
      'title': 'Badge Premium',
      'description': 'Profil vérifié et mis en avant',
    },
    {
      'icon': 'support_agent',
      'title': 'Support prioritaire',
      'description': 'Assistance dédiée et rapide',
    },
    {
      'icon': 'analytics',
      'title': 'Analytics avancées',
      'description': 'Suivez vos performances en détail',
    },
    {
      'icon': 'security',
      'title': 'Assurance incluse',
      'description': 'Protection professionnelle',
    },
    {
      'icon': 'local_shipping',
      'title': 'Services spécialisés',
      'description': 'Livraisons express et fragiles',
    },
  ];

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 'mobile_money',
      'name': 'Mobile Money',
      'icon': 'phone_android',
      'description': 'Orange Money, Wave, Free Money',
    },
    {
      'id': 'bank_card',
      'name': 'Carte bancaire',
      'icon': 'credit_card',
      'description': 'Visa, Mastercard',
    },
    {
      'id': 'bank_transfer',
      'name': 'Virement bancaire',
      'icon': 'account_balance',
      'description': 'Virement direct',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        if (widget.isModal) ...[
          Container(
            padding: EdgeInsets.all(16.0),
            child: Container(
              width: 48.0,
              height: 4.3,
              decoration: BoxDecoration(
                color: colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],

        // Header with stepper
        Container(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  if (widget.isModal)
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainer,
                          shape: BoxShape.circle,
                        ),
                        child: CustomIconWidget(
                          iconName: 'close',
                          size: 20.0,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  if (widget.isModal) SizedBox(width: 12.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upgrade vers Premium',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Étape ${_currentStep + 1} sur ${_upgradeSteps.length}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CustomIconWidget(
                    iconName: 'workspace_premium',
                    size: 40.0,
                    color: AppTheme.premiumGold,
                  ),
                ],
              ),

              SizedBox(height: 25.5),

              // Progress stepper
              Row(
                children: _upgradeSteps.asMap().entries.map((entry) {
                  final index = entry.key;
                  final step = entry.value;
                  final isActive = index <= _currentStep;
                  final isCurrent = index == _currentStep;

                  return Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? AppTheme.premiumGold
                                      : colorScheme.surfaceContainer,
                                  shape: BoxShape.circle,
                                  border: isCurrent
                                      ? Border.all(
                                          color: AppTheme.premiumGold,
                                          width: 2,
                                        )
                                      : null,
                                ),
                                child: CustomIconWidget(
                                  iconName: step['icon'],
                                  color: isActive
                                      ? Colors.white
                                      : colorScheme.onSurfaceVariant,
                                  size: 20.0,
                                ),
                              ),
                              SizedBox(height: 8.5),
                              Text(
                                step['title'],
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: isActive
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: isActive
                                      ? AppTheme.premiumGold
                                      : colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        if (index < _upgradeSteps.length - 1)
                          Container(
                            width: 32.0,
                            height: 2.0,
                            color: index < _currentStep
                                ? AppTheme.premiumGold
                                : colorScheme.outline.withValues(
                                    alpha: 0.3,
                                  ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        // Content
        Expanded(child: _buildStepContent(context, theme, colorScheme)),

        // Navigation buttons
        Container(
          padding: EdgeInsets.all(16.0),
          child: Row(
            children: [
              if (_currentStep > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _currentStep--;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.onSurface,
                      side: BorderSide(color: colorScheme.outline),
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                    ),
                    child: Text('Retour'),
                  ),
                ),
              if (_currentStep > 0) SizedBox(width: 16.0),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: widget.isProcessing ? null : _handleNextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.premiumGold,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: widget.isProcessing
                      ? SizedBox(
                          width: 20.0,
                          height: 20.0,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _currentStep == _upgradeSteps.length - 1
                              ? 'Finaliser - 1000 FCFA'
                              : 'Suivant',
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
    );
  }

  Widget _buildStepContent(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    switch (_currentStep) {
      case 0:
        return _buildBenefitsStep(context, theme, colorScheme);
      case 1:
        return _buildPaymentStep(context, theme, colorScheme);
      case 2:
        return _buildConfirmationStep(context, theme, colorScheme);
      default:
        return Container();
    }
  }

  Widget _buildBenefitsStep(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
            ),
            child: Column(
              children: [
                CustomIconWidget(
                  iconName: 'workspace_premium',
                  size: 60.0,
                  color: AppTheme.premiumGold,
                ),
                SizedBox(height: 17.0),
                Text(
                  'Débloquez votre potentiel',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.premiumGold,
                  ),
                ),
                Text(
                  'Gagnez plus et livrez mieux avec Premium',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          SizedBox(height: 25.5),
          Text(
            'Tous les avantages Premium',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 17.0),
          ..._premiumBenefits.map(
            (benefit) => Container(
              margin: EdgeInsets.only(bottom: 17.0),
              padding: EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: AppTheme.premiumGold.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CustomIconWidget(
                      iconName: benefit['icon'],
                      color: AppTheme.premiumGold,
                      size: 24.0,
                    ),
                  ),
                  SizedBox(width: 12.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          benefit['title'],
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          benefit['description'],
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
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentStep(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: AppTheme.successGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.successGreen.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'info',
                  color: AppTheme.successGreen,
                  size: 24.0,
                ),
                SizedBox(width: 12.0),
                Expanded(
                  child: Text(
                    'Coût supplémentaire: 1000 FCFA\nVotre abonnement passera de 500 FCFA à 1500 FCFA/mois',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.successGreen,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 25.5),
          Text(
            'Choisissez votre méthode de paiement',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 17.0),
          ..._paymentMethods.map(
            (method) => GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _selectedPaymentMethod = method['id'];
                });
              },
              child: Container(
                margin: EdgeInsets.only(bottom: 17.0),
                padding: EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: _selectedPaymentMethod == method['id']
                      ? AppTheme.premiumGold.withValues(alpha: 0.1)
                      : colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedPaymentMethod == method['id']
                        ? AppTheme.premiumGold
                        : colorScheme.outline.withValues(alpha: 0.2),
                    width: _selectedPaymentMethod == method['id'] ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: _selectedPaymentMethod == method['id']
                            ? AppTheme.premiumGold.withValues(alpha: 0.2)
                            : colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: CustomIconWidget(
                        iconName: method['icon'],
                        color: _selectedPaymentMethod == method['id']
                            ? AppTheme.premiumGold
                            : colorScheme.onSurfaceVariant,
                        size: 24.0,
                      ),
                    ),
                    SizedBox(width: 16.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            method['name'],
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: _selectedPaymentMethod == method['id']
                                  ? AppTheme.premiumGold
                                  : colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            method['description'],
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_selectedPaymentMethod == method['id'])
                      CustomIconWidget(
                        iconName: 'check_circle',
                        color: AppTheme.premiumGold,
                        size: 24.0,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationStep(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final selectedMethod = _paymentMethods.firstWhere(
      (method) => method['id'] == _selectedPaymentMethod,
      orElse: () => _paymentMethods[0],
    );

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: [
          CustomIconWidget(
            iconName: 'workspace_premium',
            size: 80.0,
            color: AppTheme.premiumGold,
          ),
          SizedBox(height: 25.5),
          Text(
            'Confirmation de l\'upgrade',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 8.5),
          Text(
            'Vérifiez les détails avant de finaliser',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 34.0),
          Container(
            padding: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                _buildConfirmationRow(
                  'Niveau actuel',
                  'Standard (500 FCFA/mois)',
                  theme,
                  colorScheme,
                ),
                SizedBox(height: 17.0),
                _buildConfirmationRow(
                  'Nouveau niveau',
                  'Premium (1500 FCFA/mois)',
                  theme,
                  colorScheme,
                ),
                SizedBox(height: 17.0),
                _buildConfirmationRow(
                  'Coût supplémentaire',
                  '1000 FCFA',
                  theme,
                  colorScheme,
                  isHighlight: true,
                ),
                SizedBox(height: 17.0),
                _buildConfirmationRow(
                  'Mode de paiement',
                  selectedMethod['name'],
                  theme,
                  colorScheme,
                ),
              ],
            ),
          ),
          SizedBox(height: 25.5),
          Container(
            padding: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.premiumGold.withValues(alpha: 0.1),
                  AppTheme.premiumGold.withValues(alpha: 0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  'Vous débloquerez immédiatement:',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.premiumGold,
                  ),
                ),
                SizedBox(height: 8.5),
                Text(
                  '• Commission +15% • Badge vérifié • Support prioritaire • Analytics avancées',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationRow(
    String label,
    String value,
    ThemeData theme,
    ColorScheme colorScheme, {
    bool isHighlight = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
            color: isHighlight ? AppTheme.premiumGold : colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  void _handleNextStep() {
    HapticFeedback.lightImpact();

    if (_currentStep < _upgradeSteps.length - 1) {
      setState(() {
        _currentStep++;
      });
    } else {
      // Final step - process upgrade
      widget.onUpgrade();
    }
  }
}
