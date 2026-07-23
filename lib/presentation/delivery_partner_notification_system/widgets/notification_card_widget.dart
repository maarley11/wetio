import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class NotificationCardWidget extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback? onTap;
  final VoidCallback? onMarkAsRead;

  const NotificationCardWidget({
    super.key,
    required this.notification,
    this.onTap,
    this.onMarkAsRead,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isUnread = !notification['isRead'];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.5),
      decoration: BoxDecoration(
        color: isUnread
            ? colorScheme.primary.withValues(alpha: 0.05)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnread
              ? colorScheme.primary.withValues(alpha: 0.2)
              : colorScheme.outline.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(12.0),
        leading: _buildNotificationIcon(colorScheme),
        title: Text(
          (notification['title'] ?? 'Notification').toString(),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4.3),
            Text(
              (notification['subtitle'] ?? '').toString(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 8.5),
            Row(
              children: [
                CustomIconWidget(
                  iconName: 'schedule',
                  size: 12.0,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
                SizedBox(width: 4.0),
                Text(
                  _formatTimestamp(notification['timestamp'] is DateTime ? notification['timestamp'] : DateTime.now()),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
                if (notification.containsKey('distance')) ...[
                  SizedBox(width: 8.0),
                  CustomIconWidget(
                    iconName: 'location_on',
                    size: 12.0,
                    color: colorScheme.primary,
                  ),
                  SizedBox(width: 2.0),
                  Text(
                    (notification['distance'] ?? '').toString(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (notification.containsKey('estimatedEarnings')) ...[
                  const Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 2.0,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.successGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      (notification['estimatedEarnings'] ?? '').toString(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.successGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: isUnread
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8.0,
                    height: 8.0,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (onMarkAsRead != null) ...[
                    SizedBox(height: 8.5),
                    GestureDetector(
                      onTap: onMarkAsRead,
                      child: Container(
                        padding: EdgeInsets.all(4.0),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainer,
                          shape: BoxShape.circle,
                        ),
                        child: CustomIconWidget(
                          iconName: 'check',
                          size: 12.0,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ],
              )
            : null,
        onTap: onTap,
      ),
    );
  }

  Widget _buildNotificationIcon(ColorScheme colorScheme) {
    String iconName;
    Color iconColor;
    Color backgroundColor;

    switch ((notification['type'] ?? '').toString()) {
      case 'delivery_request':
        iconName = 'local_shipping';
        iconColor = colorScheme.primary;
        backgroundColor = colorScheme.primaryContainer;
        break;
      case 'booking_confirmed':
        iconName = 'event_available';
        iconColor = AppTheme.successGreen;
        backgroundColor = AppTheme.successGreen.withValues(alpha: 0.1);
        break;
      case 'payment_received':
        iconName = 'payments';
        iconColor = AppTheme.successGreen;
        backgroundColor = AppTheme.successGreen.withValues(alpha: 0.1);
        break;
      case 'customer_message':
        iconName = 'chat';
        iconColor = colorScheme.secondary;
        backgroundColor = colorScheme.secondaryContainer;
        break;
      default:
        iconName = 'notifications';
        iconColor = colorScheme.onSurfaceVariant;
        backgroundColor = colorScheme.surfaceContainer;
    }

    return Container(
      padding: EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: CustomIconWidget(iconName: iconName, color: iconColor, size: 24.0),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else {
      return 'Il y a ${difference.inDays}j';
    }
  }
}
