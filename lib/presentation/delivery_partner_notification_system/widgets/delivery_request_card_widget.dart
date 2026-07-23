import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class DeliveryRequestCardWidget extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final VoidCallback? onPickup;
  final VoidCallback? onComplete;
  final VoidCallback? onViewDetails;
  final bool isDetailView;

  const DeliveryRequestCardWidget({
    super.key,
    required this.request,
    this.onAccept,
    this.onDecline,
    this.onPickup,
    this.onComplete,
    this.onViewDetails,
    this.isDetailView = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final deliveryData = request['deliveryData'] ?? request['data'] ?? {};
    final client1 = deliveryData is Map ? (deliveryData['client1'] ?? {}) : {};
    final client2 = deliveryData is Map ? (deliveryData['client2'] ?? {}) : {};

    if (isDetailView) {
      return _buildDetailView(
        context,
        theme,
        colorScheme,
        deliveryData,
        client1,
        client2,
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.5),
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
          color: colorScheme.primary.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Header with priority and earnings
          Container(
            padding: EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withValues(alpha: 0.1),
                  colorScheme.primaryContainer.withValues(alpha: 0.2),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: CustomIconWidget(
                    iconName: 'local_shipping',
                    color: colorScheme.onPrimary,
                    size: 20.0,
                  ),
                ),
                SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nouvelle demande de livraison',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      Text(
                        '${request['distance'] ?? '---'} • ${request['estimatedEarnings'] ?? '---'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: AppTheme.successGreen,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'PRIORITÉ',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Exchange details
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Route info
                Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'location_on',
                      color: AppTheme.successGreen,
                      size: 20.0,
                    ),
                    SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        '${deliveryData['pickup']} → ${deliveryData['delivery']}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Text(
                      (deliveryData['estimatedDuration'] ?? '---').toString(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 25.5),

                // Clients info
                Row(
                  children: [
                    Expanded(
                      child: _buildClientInfo(
                        context,
                        client1,
                        theme,
                        colorScheme,
                      ),
                    ),
                    SizedBox(width: 16.0),
                    CustomIconWidget(
                      iconName: 'swap_horiz',
                      color: colorScheme.primary,
                      size: 24.0,
                    ),
                    SizedBox(width: 16.0),
                    Expanded(
                      child: _buildClientInfo(
                        context,
                        client2,
                        theme,
                        colorScheme,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 25.5),

                // Items to exchange
                Container(
                  padding: EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Articles à livrer',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 8.5),
                      if (deliveryData['items'] is List)
                        ...((deliveryData['items'] as List).map(
                          (item) => Padding(
                            padding: EdgeInsets.symmetric(vertical: 4.3),
                            child: Row(
                              children: [
                                CustomIconWidget(
                                  iconName: 'inventory_2',
                                  size: 16.0,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                SizedBox(width: 8.0),
                                Text(
                                  (item ?? 'Article inconnu').toString(),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )),
                      if (deliveryData['items'] == null || (deliveryData['items'] is List && (deliveryData['items'] as List).isEmpty))
                        Text(
                          'Détails des articles en cours...',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Action buttons based on status
          Container(
            padding: EdgeInsets.all(16.0),
            child: _buildActionButtons(context, theme, colorScheme),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    final status = (request['status'] ?? request['delivery_status'] ?? 'en_attente').toString();

    if (status == 'en_attente') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onDecline,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.errorRed,
                side: BorderSide(color: AppTheme.errorRed),
                padding: EdgeInsets.symmetric(vertical: 12.0),
              ),
              icon: CustomIconWidget(
                iconName: 'close',
                color: AppTheme.errorRed,
                size: 16.0,
              ),
              label: Text(
                'Refuser',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.0),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: onAccept,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successGreen,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12.0),
              ),
              icon: CustomIconWidget(
                iconName: 'check',
                color: Colors.white,
                size: 16.0,
              ),
              label: Text(
                'Accepter la livraison',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      );
    } else if (status == 'accepted') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onPickup,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryGreen,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 14.0),
          ),
          icon: CustomIconWidget(
            iconName: 'inventory_2',
            color: Colors.white,
            size: 20.0,
          ),
          label: Text(
            'CONFIRMER LA RÉCUPÉRATION',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
      );
    } else if (status == 'recupere') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onComplete,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2196F3),
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 14.0),
          ),
          icon: CustomIconWidget(
            iconName: 'verified',
            color: Colors.white,
            size: 20.0,
          ),
          label: Text(
            'TERMINER LA LIVRAISON',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
      );
    } else if (status == 'terminee') {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: AppTheme.successGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(iconName: 'check_circle', color: AppTheme.successGreen, size: 20.0),
            SizedBox(width: 8.0),
            Text(
              'LIVRAISON TERMINÉE',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.successGreen,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildDetailView(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    Map<String, dynamic> deliveryData,
    Map<String, dynamic> client1,
    Map<String, dynamic> client2,
  ) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                Container(
                  width: 48.0,
                  height: 4.3,
                  decoration: BoxDecoration(
                    color: colorScheme.outline.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 25.5),
                CustomIconWidget(
                  iconName: 'local_shipping',
                  size: 60.0,
                  color: colorScheme.primary,
                ),
                SizedBox(height: 17.0),
                Text(
                  'Demande de livraison',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 8.5),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.successGreen.withValues(alpha: 0.1),
                        AppTheme.successGreen.withValues(alpha: 0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Text(
                    '${request['estimatedEarnings'] ?? 'Gain à confirmer'} • ${request['distance'] ?? '---'} • ${deliveryData['estimatedDuration'] ?? '---'}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.successGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Detailed content
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Route details with map-like visualization
                Container(
                  padding: EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Itinéraire de livraison',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 17.0),
                      Row(
                        children: [
                          Column(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  color: AppTheme.successGreen,
                                  shape: BoxShape.circle,
                                ),
                                child: CustomIconWidget(
                                  iconName: 'play_arrow',
                                  color: Colors.white,
                                  size: 16.0,
                                ),
                              ),
                              Container(
                                width: 2.0,
                                height: 68.0,
                                color: colorScheme.outline,
                              ),
                              Container(
                                padding: EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  color: AppTheme.errorRed,
                                  shape: BoxShape.circle,
                                ),
                                child: CustomIconWidget(
                                  iconName: 'flag',
                                  color: Colors.white,
                                  size: 16.0,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(width: 16.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Récupération',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  (deliveryData['pickup'] ?? 'Point de départ').toString(),
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                SizedBox(height: 34.0),
                                Text(
                                  'Livraison',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  (deliveryData['delivery'] ?? 'Point d\'arrivée').toString(),
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 25.5),

                // Detailed client information
                _buildDetailedClientInfo(
                  context,
                  client1,
                  client2,
                  theme,
                  colorScheme,
                ),

                SizedBox(height: 25.5),

                // Items with more details
                _buildDetailedItemsList(
                  context,
                  deliveryData,
                  theme,
                  colorScheme,
                ),

                SizedBox(height: 34.0),

                // Action buttons
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onAccept,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successGreen,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: CustomIconWidget(
                          iconName: 'check',
                          color: Colors.white,
                          size: 24.0,
                        ),
                        label: Text(
                          'Accepter cette livraison',
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
                        onPressed: onDecline,
                        child: Text(
                          'Refuser cette demande',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.errorRed,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientInfo(
    BuildContext context,
    Map<String, dynamic> client,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Column(
      children: [
        Container(
          width: 48.0,
          height: 48.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: ClipOval(
            child: CustomImageWidget(
              imageUrl: (client['avatar'] ?? '').toString(),
              fit: BoxFit.cover,
            ),
          ),
        ),
        SizedBox(height: 8.5),
        Text(
          (client['name'] ?? 'Utilisateur').toString(),
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(iconName: 'star', color: Colors.amber, size: 12.0),
            Text(
              ' ${client['rating']}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailedClientInfo(
    BuildContext context,
    Map<String, dynamic> client1,
    Map<String, dynamic> client2,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Participants à l\'échange',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 17.0),
          Row(
            children: [
              Expanded(
                child: _buildDetailedClientCard(
                  context,
                  client1,
                  'Expéditeur',
                  theme,
                  colorScheme,
                ),
              ),
              SizedBox(width: 16.0),
              CustomIconWidget(
                iconName: 'swap_horiz',
                color: colorScheme.primary,
                size: 32.0,
              ),
              SizedBox(width: 16.0),
              Expanded(
                child: _buildDetailedClientCard(
                  context,
                  client2,
                  'Destinataire',
                  theme,
                  colorScheme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedClientCard(
    BuildContext context,
    Map<String, dynamic> client,
    String role,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            width: 60.0,
            height: 60.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: ClipOval(
              child: CustomImageWidget(
                imageUrl: (client['avatar'] ?? '').toString(),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(height: 8.5),
          Text(
            role,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            (client['name'] ?? 'Utilisateur').toString(),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4.3),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomIconWidget(
                iconName: 'star',
                color: Colors.amber,
                size: 14.0,
              ),
              Text(
                ' ${client['rating']}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedItemsList(
    BuildContext context,
    Map<String, dynamic> deliveryData,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'inventory_2',
                color: colorScheme.primary,
                size: 24.0,
              ),
              SizedBox(width: 8.0),
              Text(
                'Articles à échanger',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: 17.0),
          if (deliveryData['items'] is List)
            ...((deliveryData['items'] as List).asMap().entries.map(
                  (entry) => Container(
                    margin: EdgeInsets.only(bottom: 17.0),
                    padding: EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${entry.key + 1}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(width: 12.0),
                        Expanded(
                          child: Text(
                            (entry.value ?? 'Article inconnu').toString(),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        CustomIconWidget(
                          iconName: 'check_circle_outline',
                          color: AppTheme.successGreen,
                          size: 20.0,
                        ),
                      ],
                    ),
                  ),
                )),
        ],
      ),
    );
  }
}
