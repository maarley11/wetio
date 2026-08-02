
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import 'package:url_launcher/url_launcher.dart';
import '../../core/app_export.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_app_bar.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _selectedFilter = 'Toutes';
  final List<String> _filterOptions = [
    'Toutes',
    'Propositions',
    'Ventes',
    'Messages',
    'Livraisons',
    'Système'
  ];

  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final realNotifications = await SupabaseService.getNotifications();
      setState(() {
        _notifications = realNotifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      print('Error loading notifications: $e');
    }
  }

  List<Map<String, dynamic>> get _filteredNotifications {
    if (_selectedFilter == 'Toutes') {
      return _notifications;
    }
    return _notifications
        .where((notif) => notif['category'] == _selectedFilter)
        .toList();
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in _notifications) {
        notification['isRead'] = true;
      }
    });
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Toutes les notifications marquées comme lues'),
        backgroundColor: AppTheme.successGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _deleteNotification(String id) {
    setState(() {
      _notifications.removeWhere((notif) => notif['id'] == id);
    });
    HapticFeedback.lightImpact();
  }

  void _markAsRead(String id) {
    setState(() {
      final notification =
          _notifications.firstWhere((notif) => notif['id'] == id);
      notification['isRead'] = true;
    });
    HapticFeedback.lightImpact();
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    _markAsRead(notification['id']);

    final notifData = notification['data'] as Map<String, dynamic>?;

    // Navigate based on notification type
    switch (notification['type']) {
      case 'exchange_proposal':
        if (notifData != null && notifData['id'] != null) {
          Navigator.pushNamed(
            context, 
            AppRoutes.exchangeProposal,
            arguments: {'exchangeId': notifData['id']},
          );
        }
        break;
      case 'order':
        if (notifData != null) {
          _showOrderDetails(notifData);
        }
        break;
      case 'message':
      case 'chat':
        Navigator.pushNamed(context, AppRoutes.chatMessagesHub);
        break;
      case 'delivery':
      case 'delivery_status_update':
        if (notifData != null && notifData['id'] != null) {
          Navigator.pushNamed(
            context,
            AppRoutes.threeStepDeliveryCoordinationScreen,
            arguments: {'deliveryRequestId': notifData['id']},
          );
        }
        break;
      case 'system':
        break;
    }
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48.0,
                height: 5,
                decoration: BoxDecoration(
                  color: colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 25.5),
            Text(
              'Détails de la commande',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 25.5),
            
            _buildDetailRow('Produit', order['product_title'] ?? 'Inconnu'),
            _buildDetailRow('Acheteur', order['buyer_name'] ?? 'Inconnu'),
            _buildDetailRow('Téléphone', order['buyer_phone'] ?? 'Non renseigné', isActionable: true),
            
            SizedBox(height: 8.5),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _launchURL('tel:${order['buyer_phone']}'),
                    icon: const Icon(Icons.phone),
                    label: const Text('Appeler'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryGreen,
                      side: BorderSide(color: AppTheme.primaryGreen),
                      padding: EdgeInsets.symmetric(vertical: 10.2),
                    ),
                  ),
                ),
                SizedBox(width: 12.0),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _launchURL('https://wa.me/${_formatWhatsApp(order['buyer_phone'])}'),
                    icon: const Icon(Icons.message),
                    label: const Text('WhatsApp'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF25D366),
                      side: const BorderSide(color: Color(0xFF25D366)),
                      padding: EdgeInsets.symmetric(vertical: 10.2),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 25.5),
            _buildDetailRow('Montant total', '${order['total_amount']} FCFA'),
            _buildDetailRow('Mode de livraison', order['delivery_method'] == 'express' ? 'Express' : 'Standard'),
            
            SizedBox(height: 34.0),
            
            Container(
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: AppTheme.primaryGreen, size: 20),
                      SizedBox(width: 8.0),
                      Text(
                        'En attente du paiement',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.5),
                  Text(
                    'L\'acheteur a reçu vos coordonnées de paiement. Une fois que vous aurez reçu l\'argent, vous pourrez procéder à la livraison.',
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                  ),
                ],
              ),
            ),

            
            SizedBox(height: 34.0),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  padding: EdgeInsets.symmetric(vertical: 12.8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('J\'ai compris', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            SizedBox(height: 17.0),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isActionable = false}) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: 12.8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
          Row(
            children: [
              Text(value, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
              if (isActionable) ...[
                SizedBox(width: 4.0),
                IconButton(
                  icon: const Icon(Icons.copy, size: 16, color: Colors.grey),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copié dans le presse-papier')),
                    );
                  },
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $urlString';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible d\'ouvrir l\'application : $e')),
      );
    }
  }

  String _formatWhatsApp(dynamic phone) {
    String p = phone?.toString() ?? '';
    p = p.replaceAll(RegExp(r'[^0-9]'), '');
    if (p.length == 9 && (p.startsWith('77') || p.startsWith('78') || p.startsWith('70') || p.startsWith('76'))) {
      return '221$p';
    }
    return p;
  }



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: CustomAppBar(
        title: 'Notifications',
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _markAllAsRead,
            child: Text(
              'Tout marquer comme lu',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(width: 8.0),
        ],
      ),
      body: Column(
        children: [
          // Filter toggles
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 17.0),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filterOptions.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                        HapticFeedback.lightImpact();
                      },
                      backgroundColor: colorScheme.surface,
                      selectedColor:
                          AppTheme.primaryGreen.withValues(alpha: 0.2),
                      labelStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: isSelected
                            ? AppTheme.primaryGreen
                            : colorScheme.onSurface,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? AppTheme.primaryGreen
                            : colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Notifications list
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? _buildErrorState(_errorMessage!)
                : _filteredNotifications.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadNotifications,
                    color: AppTheme.primaryGreen,
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(vertical: 17.0),
                      itemCount: _filteredNotifications.length,
                      itemBuilder: (context, index) {
                        final notification = _filteredNotifications[index];
                        return _buildNotificationCard(notification);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            SizedBox(height: 17.0),
            Text(
              'Erreur de chargement',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.5),
            Text(
              error,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 25.5),
            ElevatedButton(
              onPressed: _loadNotifications,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isRead = notification['isRead'] as bool;

    return Dismissible(
      key: Key(notification['id'].toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 24.0),
        color: AppTheme.errorRed,
        child: const Icon(
          Icons.delete,
          size: 24,
          color: Colors.white,
        ),
      ),
      onDismissed: (direction) {
        _deleteNotification(notification['id']);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification supprimée'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: InkWell(
        onTap: () => _handleNotificationTap(notification),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.5),
          padding: EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: isRead
                ? colorScheme.surface
                : AppTheme.primaryGreen.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isRead
                  ? colorScheme.outline.withValues(alpha: 0.2)
                  : AppTheme.primaryGreen.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar or icon
              Container(
                width: 48.0,
                height: 48.0,
                decoration: BoxDecoration(
                  color: (notification['accentColor'] as Color)
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: notification['avatar'] != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CustomImageWidget(
                          imageUrl: notification['avatar'],
                          fit: BoxFit.cover,
                        ),
                      )
                    : Center(
                        child: Icon(
                          _getIconForType(notification['type']),
                          size: 20,
                          color: notification['accentColor'] as Color,
                        ),
                      ),
              ),

              SizedBox(width: 12.0),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification['title'],
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight:
                                  isRead ? FontWeight.w500 : FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8.0,
                            height: 8.0,
                            decoration: BoxDecoration(
                              color: notification['accentColor'] as Color,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 4.3),
                    Text(
                      notification['message'],
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: isRead ? FontWeight.w400 : FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8.5),
                    Text(
                      _formatTimestamp(notification['timestamp']),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120.0,
              height: 120.0,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.notifications_none,
                  size: 48,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ),
            SizedBox(height: 25.5),
            Text(
              'Aucune notification',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 8.5),
            Text(
              'Vos notifications apparaîtront ici',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 25.5),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.homeFeed);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32.0, vertical: 12.8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Explorer la marketplace',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'exchange_proposal':
        return Icons.swap_horiz;
      case 'order':
        return Icons.shopping_bag_outlined;
      case 'message':
        return Icons.message;
      case 'delivery':
        return Icons.local_shipping;
      case 'system':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 60) {
        return 'Il y a ${difference.inMinutes} min';
      } else if (difference.inHours < 24) {
        return 'Il y a ${difference.inHours}h';
      } else if (difference.inDays < 7) {
        return 'Il y a ${difference.inDays}j';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return '';
    }
  }
}
