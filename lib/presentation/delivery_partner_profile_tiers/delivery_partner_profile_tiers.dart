import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/analytics_dashboard_widget.dart';
import './widgets/tier_feature_card.dart';
import './widgets/upgrade_flow_widget.dart';
import './widgets/verification_status_widget.dart';

class DeliveryPartnerProfileTiers extends StatefulWidget {
  const DeliveryPartnerProfileTiers({super.key});

  @override
  State<DeliveryPartnerProfileTiers> createState() =>
      _DeliveryPartnerProfileTiersState();
}

class _DeliveryPartnerProfileTiersState
    extends State<DeliveryPartnerProfileTiers> with TickerProviderStateMixin {
  late TabController _tabController;

  // Current tier status - would come from user data
  String _currentTier = 'standard'; // standard or premium
  bool _isUpgrading = false;

  // Mock user tier data
  final Map<String, dynamic> _tierData = {
    'standard': {
      'name': 'Standard',
      'price': '500 FCFA',
      'monthlyPrice': '500 FCFA/mois',
      'color': Colors.blue,
      'features': [
        {'name': 'Accès aux demandes de livraison', 'included': true},
        {'name': 'Commission standard (10%)', 'included': true},
        {'name': 'Support client de base', 'included': true},
        {'name': 'Profil vérifié', 'included': false},
        {'name': 'Commission réduite (15% de plus)', 'included': false},
        {'name': 'Support prioritaire', 'included': false},
        {'name': 'Badge Premium', 'included': false},
        {'name': 'Analytics avancées', 'included': false},
      ],
    },
    'premium': {
      'name': 'Premium',
      'price': '1500 FCFA',
      'monthlyPrice': '1500 FCFA/mois',
      'additionalCost': '1000 FCFA de plus',
      'color': AppTheme.premiumGold,
      'features': [
        {'name': 'Accès aux demandes de livraison', 'included': true},
        {'name': 'Commission réduite (15% de plus)', 'included': true},
        {'name': 'Support client prioritaire', 'included': true},
        {'name': 'Profil vérifié avec badge', 'included': true},
        {'name': 'Analytics et rapports avancés', 'included': true},
        {'name': 'Système de réservation prioritaire', 'included': true},
        {'name': 'Services spécialisés', 'included': true},
        {'name': 'Assurance professionnelle', 'included': true},
      ],
    },
  };

  // Mock analytics data for premium users
  final Map<String, dynamic> _premiumAnalytics = {
    'monthlyEarnings': '45000 FCFA',
    'totalDeliveries': 127,
    'customerRating': 4.8,
    'completionRate': 98.5,
    'trends': {
      'earningsGrowth': '+12%',
      'deliveriesGrowth': '+8%',
      'ratingImprovement': '+0.2',
    },
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Get current tier from arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['currentTier'] != null) {
        setState(() {
          _currentTier = args['currentTier'];
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isPremium = _currentTier == 'premium';

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: CustomAppBar(
        title: 'Profil Livreur - Niveaux',
        variant: CustomAppBarVariant.primary,
        actions: [
          if (isPremium)
            Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.premiumGold, Colors.amber.shade600],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomIconWidget(
                      iconName: 'stars',
                      color: Colors.white,
                      size: 16.0,
                    ),
                    SizedBox(width: 4.0),
                    Text(
                      'PREMIUM',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Current Status Banner
          _buildCurrentStatusBanner(context, theme, colorScheme, isPremium),

          // Tab Bar
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 17.0),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(25),
            ),
            child: TabBar(
              controller: _tabController,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomIconWidget(iconName: 'compare', size: 16.0),
                      SizedBox(width: 4.0),
                      Text('Comparer', style: TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomIconWidget(
                        iconName: isPremium ? 'analytics' : 'upgrade',
                        size: 16.0,
                      ),
                      SizedBox(width: 4.0),
                      Text(
                        isPremium ? 'Analytics' : 'Upgrade',
                        style: TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomIconWidget(iconName: 'verified', size: 16.0),
                      SizedBox(width: 4.0),
                      Text('Vérification', style: TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
              ],
              indicator: BoxDecoration(
                color: isPremium ? AppTheme.premiumGold : colorScheme.primary,
                borderRadius: BorderRadius.circular(25),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: colorScheme.onSurfaceVariant,
              dividerColor: Colors.transparent,
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Compare tiers
                _buildComparisonTab(context, theme, colorScheme),

                // Upgrade or Analytics
                isPremium
                    ? _buildAnalyticsTab(context, theme, colorScheme)
                    : _buildUpgradeTab(context, theme, colorScheme),

                // Verification status
                _buildVerificationTab(context, theme, colorScheme),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: !isPremium
          ? FloatingActionButton.extended(
              onPressed: () => _startUpgradeProcess(context),
              backgroundColor: AppTheme.premiumGold,
              foregroundColor: Colors.white,
              icon: CustomIconWidget(
                iconName: 'upgrade',
                color: Colors.white,
                size: 20.0,
              ),
              label: Text(
                'Passer Premium',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildCurrentStatusBanner(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isPremium,
  ) {
    final tierInfo = _tierData[_currentTier]!;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPremium
              ? [
                  AppTheme.premiumGold.withValues(alpha: 0.1),
                  AppTheme.premiumGold.withValues(alpha: 0.2),
                ]
              : [
                  colorScheme.primary.withValues(alpha: 0.1),
                  colorScheme.primaryContainer.withValues(alpha: 0.2),
                ],
        ),
        border: Border(
          bottom: BorderSide(
            color: isPremium
                ? AppTheme.premiumGold.withValues(alpha: 0.3)
                : colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: isPremium ? AppTheme.premiumGold : colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CustomIconWidget(
                  iconName: isPremium ? 'workspace_premium' : 'person',
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
                      'Profil ${tierInfo['name']}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isPremium
                            ? AppTheme.premiumGold
                            : colorScheme.primary,
                      ),
                    ),
                    Text(
                      'Abonnement actuel - ${tierInfo['monthlyPrice']}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (isPremium) ...[
                Container(
                  padding: EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: AppTheme.premiumGold,
                    shape: BoxShape.circle,
                  ),
                  child: CustomIconWidget(
                    iconName: 'verified',
                    color: Colors.white,
                    size: 24.0,
                  ),
                ),
              ],
            ],
          ),
          if (isPremium) ...[
            SizedBox(height: 17.0),
            Container(
              padding: EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    context,
                    'Revenus',
                    _premiumAnalytics['monthlyEarnings'],
                    'trending_up',
                    theme,
                    colorScheme,
                  ),
                  _buildStatItem(
                    context,
                    'Livraisons',
                    '${_premiumAnalytics['totalDeliveries']}',
                    'local_shipping',
                    theme,
                    colorScheme,
                  ),
                  _buildStatItem(
                    context,
                    'Note',
                    '${_premiumAnalytics['customerRating']}⭐',
                    'star',
                    theme,
                    colorScheme,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
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
          size: 20.0,
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
        ),
      ],
    );
  }

  Widget _buildComparisonTab(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final standardFeatures =
        _tierData['standard']!['features'] as List<Map<String, dynamic>>;
    final premiumFeatures =
        _tierData['premium']!['features'] as List<Map<String, dynamic>>;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comparaison des niveaux',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 17.0),

          // Feature comparison cards
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Standard column
              Expanded(
                child: TierFeatureCard(
                  tierName: 'Standard',
                  price: _tierData['standard']!['price'],
                  color: Colors.blue,
                  features: standardFeatures,
                  isCurrentTier: _currentTier == 'standard',
                  onSelect: _currentTier != 'standard'
                      ? () => _switchToStandard(context)
                      : null,
                ),
              ),

              SizedBox(width: 16.0),

              // Premium column
              Expanded(
                child: TierFeatureCard(
                  tierName: 'Premium',
                  price: _tierData['premium']!['price'],
                  additionalInfo: _tierData['premium']!['additionalCost'],
                  color: AppTheme.premiumGold,
                  features: premiumFeatures,
                  isCurrentTier: _currentTier == 'premium',
                  isPremium: true,
                  onSelect: _currentTier != 'premium'
                      ? () => _startUpgradeProcess(context)
                      : null,
                ),
              ),
            ],
          ),

          SizedBox(height: 34.0),

          // Benefits explanation
          Container(
            padding: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'lightbulb',
                      color: colorScheme.primary,
                      size: 24.0,
                    ),
                    SizedBox(width: 8.0),
                    Text(
                      'Avantages Premium',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 17.0),
                _buildBenefitItem(
                  'Commission plus élevée de 15%',
                  'Le premium vous permet de gagner plus par livraison',
                  theme,
                  colorScheme,
                ),
                _buildBenefitItem(
                  'Badge de confiance',
                  'Les clients préfèrent les livreurs vérifiés',
                  theme,
                  colorScheme,
                ),
                _buildBenefitItem(
                  'Support prioritaire',
                  'Résolution rapide de vos problèmes',
                  theme,
                  colorScheme,
                ),
                _buildBenefitItem(
                  'Analytics détaillées',
                  'Suivez vos performances et optimisez vos revenus',
                  theme,
                  colorScheme,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(
    String title,
    String description,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 17.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 4.3),
            padding: EdgeInsets.all(4.0),
            decoration: BoxDecoration(
              color: AppTheme.successGreen,
              shape: BoxShape.circle,
            ),
            child: CustomIconWidget(
              iconName: 'check',
              color: Colors.white,
              size: 12.0,
            ),
          ),
          SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradeTab(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: UpgradeFlowWidget(
        currentTier: _currentTier,
        targetTier: 'premium',
        onUpgrade: () => _processUpgrade(context),
        isProcessing: _isUpgrading,
      ),
    );
  }

  Widget _buildAnalyticsTab(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: AnalyticsDashboard(analyticsData: _premiumAnalytics),
    );
  }

  Widget _buildVerificationTab(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: VerificationStatusWidget(
        currentTier: _currentTier,
        isVerified: _currentTier == 'premium',
      ),
    );
  }

  void _startUpgradeProcess(BuildContext context) {
    HapticFeedback.lightImpact();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 80.h,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: UpgradeFlowWidget(
          currentTier: _currentTier,
          targetTier: 'premium',
          onUpgrade: () => _processUpgrade(context),
          isProcessing: _isUpgrading,
          isModal: true,
        ),
      ),
    );
  }

  void _processUpgrade(BuildContext context) async {
    HapticFeedback.lightImpact();

    setState(() {
      _isUpgrading = true;
    });

    // Simulate payment processing
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _currentTier = 'premium';
      _isUpgrading = false;
    });

    Navigator.pop(context); // Close modal if open

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            CustomIconWidget(
              iconName: 'celebration',
              color: Colors.white,
              size: 24.0,
            ),
            SizedBox(width: 8.0),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Félicitations !',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('Vous êtes maintenant Premium'),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.premiumGold,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _switchToStandard(BuildContext context) {
    HapticFeedback.lightImpact();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rétrograder vers Standard'),
        content: Text(
          'Êtes-vous sûr de vouloir passer au niveau Standard ? Vous perdrez tous les avantages Premium.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _currentTier = 'standard';
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Profil rétrogradé vers Standard'),
                  backgroundColor: AppTheme.errorRed,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
            ),
            child: Text('Confirmer'),
          ),
        ],
      ),
    );
  }
}
