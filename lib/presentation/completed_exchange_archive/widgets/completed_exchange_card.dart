import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class CompletedExchangeCard extends StatelessWidget {
  final Map<String, dynamic> exchange;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const CompletedExchangeCard({
    Key? key,
    required this.exchange,
    required this.onTap,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: EdgeInsets.only(bottom: 12.0),
      child: Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        elevation: 2,
        shadowColor: colorScheme.shadow.withValues(alpha: 0.1),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with exchange info and actions
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: CustomIconWidget(
                        iconName: exchange['exchange_method'] == 'direct'
                            ? 'handshake'
                            : 'local_shipping',
                        color: colorScheme.primary,
                        size: 20.0,
                      ),
                    ),
                    SizedBox(width: 12.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exchange['exchange_method'] == 'direct'
                                ? 'Échange direct'
                                : 'Échange avec livraison',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            _formatCompletionDate(exchange['completion_date']),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Delete countdown timer
                    _buildDeleteTimer(colorScheme, theme),
                    SizedBox(width: 8.0),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        HapticFeedback.lightImpact();
                        if (value == 'delete') {
                          onDelete();
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              CustomIconWidget(
                                iconName: 'delete',
                                color: AppTheme.errorRed,
                                size: 20.0,
                              ),
                              SizedBox(width: 8.0),
                              Text(
                                'Supprimer',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.errorRed,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      child: Container(
                        padding: EdgeInsets.all(4.0),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: colorScheme.outline.withValues(alpha: 0.3),
                          ),
                        ),
                        child: CustomIconWidget(
                          iconName: 'more_vert',
                          color: colorScheme.onSurfaceVariant,
                          size: 20.0,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 25.5),

                // Exchange products
                Container(
                  padding: EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color:
                        colorScheme.surfaceContainer.withValues(alpha: 0.5) ??
                            colorScheme.surface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      // My product (given)
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(6.0),
                            decoration: BoxDecoration(
                              color:
                                  AppTheme.successGreen.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: CustomIconWidget(
                              iconName: 'arrow_upward',
                              color: AppTheme.successGreen,
                              size: 16.0,
                            ),
                          ),
                          SizedBox(width: 12.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mon produit donné',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  exchange['target_product_title'],
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 17.0),

                      // Received product
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(6.0),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: CustomIconWidget(
                              iconName: 'arrow_downward',
                              color: colorScheme.primary,
                              size: 16.0,
                            ),
                          ),
                          SizedBox(width: 12.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Produit reçu',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  exchange['requester_product_title'],
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 17.0),

                // Ratings and details
                Row(
                  children: [
                    // Ratings
                    if (exchange['rating_given'] != null ||
                        exchange['rating_received'] != null)
                      Expanded(
                        child: Row(
                          children: [
                            CustomIconWidget(
                              iconName: 'star',
                              color: AppTheme.warningOrange,
                              size: 16.0,
                            ),
                            SizedBox(width: 4.0),
                            Text(
                              '${exchange['rating_given'] ?? 0}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            SizedBox(width: 8.0),
                            Text(
                              '•',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            SizedBox(width: 8.0),
                            CustomIconWidget(
                              iconName: 'star_border',
                              color: colorScheme.primary,
                              size: 16.0,
                            ),
                            SizedBox(width: 4.0),
                            Text(
                              '${exchange['rating_received'] ?? 0}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // View details indicator
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Voir détails',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: 4.0),
                          CustomIconWidget(
                            iconName: 'chevron_right',
                            color: colorScheme.primary,
                            size: 16.0,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteTimer(ColorScheme colorScheme, ThemeData theme) {
    final deleteDate = DateTime.parse(exchange['auto_delete_at']);
    final now = DateTime.now();
    final difference = deleteDate.difference(now);

    if (difference.isNegative) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
        decoration: BoxDecoration(
          color: AppTheme.errorRed.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Expiré',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppTheme.errorRed,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    final daysLeft = difference.inDays;
    final isCloseToDelete = daysLeft <= 30;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: isCloseToDelete
            ? AppTheme.warningOrange.withValues(alpha: 0.1)
            : colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCloseToDelete ? AppTheme.warningOrange : colorScheme.primary,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomIconWidget(
            iconName: 'schedule',
            color:
                isCloseToDelete ? AppTheme.warningOrange : colorScheme.primary,
            size: 12.0,
          ),
          SizedBox(width: 4.0),
          Text(
            daysLeft < 30 ? '${daysLeft}j' : '${(daysLeft / 30).floor()}m',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isCloseToDelete
                  ? AppTheme.warningOrange
                  : colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCompletionDate(String dateString) {
    final date = DateTime.parse(dateString);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Terminé aujourd\'hui';
    } else if (difference.inDays == 1) {
      return 'Terminé hier';
    } else if (difference.inDays < 7) {
      return 'Terminé il y a ${difference.inDays} jours';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'Terminé il y a $weeks semaine${weeks > 1 ? 's' : ''}';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return 'Terminé il y a $months mois';
    } else {
      final years = (difference.inDays / 365).floor();
      return 'Terminé il y a $years an${years > 1 ? 's' : ''}';
    }
  }
}
