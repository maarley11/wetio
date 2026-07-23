import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/delivery_coordination_section.dart';
import './widgets/exchange_summary_section.dart';

class ExchangeAgreementDelivery extends StatefulWidget {
  const ExchangeAgreementDelivery({super.key});

  @override
  State<ExchangeAgreementDelivery> createState() =>
      _ExchangeAgreementDeliveryState();
}

class _ExchangeAgreementDeliveryState extends State<ExchangeAgreementDelivery> {
  // Mock exchange data - would come from route arguments
  final Map<String, dynamic> _exchangeData = {
    "id": "EXG001",
    "status": "agreed", // agreed, in_delivery, completed
    "createdAt": "2025-01-02",
    "user1": {
      "id": 1,
      "name": "Aminata Diallo",
      "avatar":
          "https://images.pexels.com/photos/1239291/pexels-photo-1239291.jpeg?auto=compress&cs=tinysrgb&w=400",
      "location": "Dakar, Plateau",
      "rating": 4.8,
    },
    "user2": {
      "id": 2,
      "name": "Mamadou Ba",
      "avatar":
          "https://images.pexels.com/photos/1040881/pexels-photo-1040881.jpeg?auto=compress&cs=tinysrgb&w=400",
      "location": "Dakar, Médina",
      "rating": 4.6,
    },
    "products": {
      "user1Product": {
        "title": "iPhone 12 Pro",
        "image":
            "https://images.pexels.com/photos/788946/pexels-photo-788946.jpeg?auto=compress&cs=tinysrgb&w=400",
        "condition": "Très bon état",
      },
      "user2Product": {
        "title": "MacBook Air M1",
        "image":
            "https://images.pexels.com/photos/205421/pexels-photo-205421.jpeg?auto=compress&cs=tinysrgb&w=400",
        "condition": "Excellent état",
      }
    },
    "deliveryMethod": "delivery_service", // direct, delivery_service
    "meetingPoint": null,
    "estimatedDeliveryDate": "2025-01-05",
  };

  bool _deliveryRequested = false;
  Map<String, dynamic>? _selectedDeliveryPartner;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: CustomAppBar(
        title: 'Coordination de l\'échange',
        variant: CustomAppBarVariant.primary,
      ),
      body: CustomScrollView(
        slivers: [
          // Exchange Summary Section
          SliverToBoxAdapter(
            child: ExchangeSummarySection(
              exchangeData: _exchangeData,
            ),
          ),

          // Delivery Status & Actions
          SliverToBoxAdapter(
            child: _buildDeliveryStatusSection(context, theme, colorScheme),
          ),

          // Delivery Coordination Section
          if (_deliveryRequested)
            SliverToBoxAdapter(
              child: DeliveryCoordinationSection(
                selectedOption:
                    _selectedDeliveryPartner != null ? 'organize' : '',
                onOptionChanged: (option) {
                  // Handle option change if needed
                },
              ),
            ),

          // Action Buttons
          SliverToBoxAdapter(
            child: _buildActionButtons(context, theme, colorScheme),
          ),

          // Bottom spacing
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryStatusSection(
      BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      margin: EdgeInsets.all(16.0),
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: _deliveryRequested
                      ? AppTheme.successGreen.withValues(alpha: 0.1)
                      : colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _deliveryRequested ? Icons.local_shipping : Icons.handshake,
                  color: _deliveryRequested
                      ? AppTheme.successGreen
                      : colorScheme.primary,
                  size: 24.0,
                ),
              ),
              SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _deliveryRequested
                          ? 'Livraison demandée'
                          : 'Échange confirmé',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      _deliveryRequested
                          ? 'Recherche d\'un livreur en cours...'
                          : 'Prêt pour la livraison',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!_deliveryRequested) ...[
            SizedBox(height: 25.5),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.local_shipping_outlined,
                    color: colorScheme.primary,
                    size: 40.0,
                  ),
                  SizedBox(height: 17.0),
                  Text(
                    'Service de Livraison WETIO',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: 8.5),
                  Text(
                    'Trouvez un livreur dans votre région pour finaliser l\'échange en toute sécurité',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(
      BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: [
          if (!_deliveryRequested) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _requestDelivery(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(
                  Icons.local_shipping,
                  size: 24.0,
                ),
                label: Text(
                  'Demander une Livraison',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
            SizedBox(height: 17.0),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _arrangeDirectMeeting(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                  side: BorderSide(color: colorScheme.primary),
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(
                  Icons.handshake,
                  size: 24.0,
                ),
                label: Text(
                  'Rencontre Directe',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ),
          ] else ...[
            if (_selectedDeliveryPartner != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _confirmDeliveryBooking(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successGreen,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(
                    Icons.check_circle,
                    size: 24.0,
                  ),
                  label: Text(
                    'Confirmer la Réservation',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            SizedBox(height: 17.0),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => _cancelDeliveryRequest(),
                child: Text(
                  'Annuler la demande de livraison',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.errorRed,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _requestDelivery(BuildContext context) {
    HapticFeedback.lightImpact();
    setState(() {
      _deliveryRequested = true;
    });

    // Navigate to delivery partner search with regional filtering
    Navigator.pushNamed(
      context,
      '/regional-delivery-search',
      arguments: {
        'exchangeData': _exchangeData,
        'searchRadius': 10, // km
        'deliveryType': 'exchange',
      },
    ).then((result) {
      if (result != null && result is Map<String, dynamic>) {
        setState(() {
          _selectedDeliveryPartner = result;
        });
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Recherche de livreurs dans votre région...'),
        backgroundColor: AppTheme.successGreen,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Voir',
          textColor: Colors.white,
          onPressed: () {
            Navigator.pushNamed(context, '/delivery-partner-search');
          },
        ),
      ),
    );
  }

  void _arrangeDirectMeeting(BuildContext context) {
    HapticFeedback.lightImpact();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rencontre Directe'),
        content: Text(
            'Voulez-vous organiser une rencontre directe avec ${_exchangeData['user2']['name']} pour finaliser l\'échange ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Here you would typically navigate to a meeting arrangement screen
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Demande de rencontre envoyée'),
                  backgroundColor: AppTheme.successGreen,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _confirmDeliveryBooking(BuildContext context) {
    HapticFeedback.lightImpact();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmer la Réservation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Livreur: ${_selectedDeliveryPartner!['name']}'),
            Text('Prix estimé: ${_selectedDeliveryPartner!['price']} FCFA'),
            Text(
                'Durée estimée: ${_selectedDeliveryPartner!['estimatedDuration']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to previous screen
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Livraison confirmée ! Le livreur vous contactera bientôt.'),
                  backgroundColor: AppTheme.successGreen,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _cancelDeliveryRequest() {
    HapticFeedback.lightImpact();
    setState(() {
      _deliveryRequested = false;
      _selectedDeliveryPartner = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Demande de livraison annulée'),
        backgroundColor: AppTheme.errorRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
