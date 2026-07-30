import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './widgets/chat_interface_widget.dart';
import './widgets/delivery_request_card_widget.dart';
import './widgets/notification_card_widget.dart';

class DeliveryPartnerNotificationSystem extends StatefulWidget {
  const DeliveryPartnerNotificationSystem({super.key});

  @override
  State<DeliveryPartnerNotificationSystem> createState() =>
      _DeliveryPartnerNotificationSystemState();
}

class _DeliveryPartnerNotificationSystemState
    extends State<DeliveryPartnerNotificationSystem>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isOnline = true;
  bool _isLoading = true;
  RealtimeChannel? _newRequestSubscription;

  // Real data from Supabase
  List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> _chatConversations = [];
  double _balance = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
    _setupRealtimeRequests();
  }

  Future<void> _loadData() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final profile = await SupabaseService.getUserProfile(user.id);
        if (profile != null && mounted) {
          setState(() {
            _balance = (profile['balance'] ?? 0).toDouble();
          });
        }
      }

      final requests = await SupabaseService.getMyDeliveryRequests();
      if (mounted) {
        setState(() {
          _notifications = requests.map((r) => {
            "id": r['id'],
            "type": "delivery_request",
            "title": "Demande de livraison",
            "subtitle": r['pickup_address'] ?? 'Dakar',
            "timestamp": DateTime.parse(r['created_at']),
            "distance": "À proximité",
            "priority": "high",
            "estimatedEarnings": "2000 FCFA", // Real net earnings
            "isRead": r['delivery_status'] != 'en_attente',
            "status": r['delivery_status'],
            "deliveryData": {
              "id": r['id'],
              "exchangeId": r['exchange_id'],
              "pickup": r['pickup_address'] ?? r['sender_address'] ?? r['pickup_location'] ?? r['pickup'] ?? 'Dakar Plateau, Rue 14',
              "delivery": r['delivery_address'] ?? r['receiver_address'] ?? r['delivery_location'] ?? r['delivery'] ?? 'Almadies, Zone B (Dakar)',
              "estimatedDuration": r['estimated_duration'] ?? "25 min",
              "items": r['items'] ?? ["Colis d'échange (Robe & Accessoires)"],
              "client1": {
                "name": r['sender_name'] ?? r['sender_profile']?['full_name'] ?? 'Moussa Diallo',
                "avatar": r['sender_avatar'] ?? r['sender_profile']?['avatar_url'] ?? '',
                "rating": r['sender_rating'] ?? 4.8,
              },
              "client2": {
                "name": r['receiver_name'] ?? r['receiver_profile']?['full_name'] ?? 'Awa Ndiaye',
                "avatar": r['receiver_avatar'] ?? r['receiver_profile']?['avatar_url'] ?? '',
                "rating": r['receiver_rating'] ?? 4.9,
              },
            },
          }).toList();
          _isLoading = false;
        });

        // Diagnostic alert
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${requests.length} demandes trouvées"),
            duration: const Duration(seconds: 2),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      print('Error loading courier data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Erreur de chargement"),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    }
  }

  void _setupRealtimeRequests() {
    final user = SupabaseService.getCurrentUser();
    if (user == null) return;

    final supabase = SupabaseService.safeClient;
    if (supabase == null) return;

    _newRequestSubscription = supabase
        .channel('public:delivery_requests:partner_user_id=eq.${user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'delivery_requests',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'partner_user_id',
            value: user.id,
          ),
          callback: (payload) {
            if (mounted) {
              _loadData(); // Refresh list on new request
              _showNewRequestNotification();
            }
          },
        )
        .subscribe();
  }

  void _showNewRequestNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Nouvelle demande de livraison reçue !"),
        backgroundColor: AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _newRequestSubscription?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: CustomAppBar(
        title: 'Notifications Livreur',
        variant: CustomAppBarVariant.primary,
        actions: [
          // Online/Offline Toggle
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                // Real Balance Display (Clickable to go to Dashboard)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.pushNamed(context, '/delivery-partner-earnings-dashboard');
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                    margin: EdgeInsets.only(right: 8.0),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.account_balance_wallet, color: colorScheme.primary, size: 12.0),
                        SizedBox(width: 6.0),
                        Text(
                          '${_balance.toInt()} FCFA',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _toggleOnlineStatus(),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 4.0,
                    ),
                    decoration: BoxDecoration(
                      color:
                          _isOnline ? AppTheme.successGreen : AppTheme.errorRed,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8.0,
                          height: 8.0,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 4.0),
                        Text(
                          _isOnline ? 'En ligne' : 'Hors ligne',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Banner
          if (_isOnline)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.0),
              color: AppTheme.successGreen.withValues(alpha: 0.1),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'notifications_active',
                    color: AppTheme.successGreen,
                    size: 20.0,
                  ),
                  SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      'Vous recevrez des notifications pour les demandes à proximité',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.successGreen,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

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
                      CustomIconWidget(iconName: 'notifications', size: 16.0),
                      SizedBox(width: 4.0),
                      Text('Notifications', style: TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomIconWidget(iconName: 'chat', size: 16.0),
                      SizedBox(width: 4.0),
                      Text('Chat', style: TextStyle(fontSize: 11)),
                      if (_chatConversations.any(
                        (chat) => chat['unreadCount'] > 0,
                      ))
                        Container(
                          margin: EdgeInsets.only(left: 4.0),
                          padding: EdgeInsets.all(4.0),
                          decoration: BoxDecoration(
                            color: AppTheme.errorRed,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${_chatConversations.map((chat) => chat['unreadCount'] as int).reduce((a, b) => a + b)}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomIconWidget(iconName: 'local_shipping', size: 16.0),
                      SizedBox(width: 4.0),
                      Text('Demandes', style: TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
              ],
              indicator: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(25),
              ),
              labelColor: colorScheme.onPrimary,
              unselectedLabelColor: colorScheme.onSurfaceVariant,
              dividerColor: Colors.transparent,
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Notifications Tab
                _buildNotificationsTab(context, theme, colorScheme),

                // Chat Tab
                _buildChatTab(context, theme, colorScheme),

                // Delivery Requests Tab
                _buildDeliveryRequestsTab(context, theme, colorScheme),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _isOnline
          ? FloatingActionButton.extended(
              onPressed: () => _showQuickResponseTemplates(context),
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              icon: CustomIconWidget(
                iconName: 'quick_phrases',
                color: colorScheme.onPrimary,
                size: 20.0,
              ),
              label: Text(
                'Réponses rapides',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onPrimary,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildNotificationsTab(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final unreadNotifications =
        _notifications.where((notif) => !notif['isRead']).toList();
    final readNotifications =
        _notifications.where((notif) => notif['isRead']).toList();

    return CustomScrollView(
      slivers: [
        if (unreadNotifications.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Text(
                    'Nouveaux',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  SizedBox(width: 8.0),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 2.0,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${unreadNotifications.length}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final notification = unreadNotifications[index];
              return NotificationCardWidget(
                notification: notification,
                onTap: () => _handleNotificationTap(notification),
                onMarkAsRead: () => _markAsRead(notification['id']),
              );
            }, childCount: unreadNotifications.length),
          ),
        ],
        if (readNotifications.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Précédents',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final notification = readNotifications[index];
              return NotificationCardWidget(
                notification: notification,
                onTap: () => _handleNotificationTap(notification),
              );
            }, childCount: readNotifications.length),
          ),
        ],
        if (_notifications.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomIconWidget(
                    iconName: 'notifications_none',
                    size: 60.0,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  SizedBox(height: 17.0),
                  Text(
                    'Aucune notification',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: 8.5),
                  Text(
                    'Les nouvelles demandes apparaîtront ici',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.7,
                      ),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildChatTab(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return _chatConversations.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomIconWidget(
                  iconName: 'chat_bubble_outline',
                  size: 60.0,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                SizedBox(height: 17.0),
                Text(
                  'Aucune conversation',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 8.5),
                Text(
                  'Les discussions avec les clients apparaîtront ici',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: EdgeInsets.all(16.0),
            itemCount: _chatConversations.length,
            itemBuilder: (context, index) {
              final conversation = _chatConversations[index];
              return ChatInterface(
                conversation: conversation,
                onTap: () => _openChatWindow(conversation),
                onSendMessage: (message) =>
                    _sendMessage(conversation['id'], message),
              );
            },
          );
  }

  Widget _buildDeliveryRequestsTab(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final pendingRequests = _notifications
        .where((notif) => notif['type'] == 'delivery_request' && notif['status'] == 'en_attente')
        .toList();

    final activeMissions = _notifications
        .where((notif) => notif['type'] == 'delivery_request' && (notif['status'] == 'accepted' || notif['status'] == 'recupere'))
        .toList();

    if (pendingRequests.isEmpty && activeMissions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'local_shipping_outlined',
              size: 60.0,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            SizedBox(height: 17.0),
            Text(
              'Aucune demande active',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 8.5),
            Text(
              _isOnline
                  ? 'Vous recevrez des notifications pour les demandes à proximité'
                  : 'Activez le mode en ligne pour recevoir des demandes',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.all(16.0),
      children: [
        if (activeMissions.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.5),
            child: Row(
              children: [
                CustomIconWidget(iconName: 'assignment', color: colorScheme.primary, size: 20.0),
                SizedBox(width: 8.0),
                Text(
                  'MES MISSIONS EN COURS',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          ...activeMissions.map((request) => DeliveryRequestCardWidget(
                request: request,
                onPickup: () => _pickupDeliveryRequest(request),
                onComplete: () => _completeDeliveryRequest(request),
                onViewDetails: () => _viewRequestDetails(request),
              )),
          SizedBox(height: 25.5),
        ],
        if (pendingRequests.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.5),
            child: Row(
              children: [
                CustomIconWidget(iconName: 'explore', color: AppTheme.successGreen, size: 20.0),
                SizedBox(width: 8.0),
                Text(
                  'DEMANDES DISPONIBLES',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          ...pendingRequests.map((request) => DeliveryRequestCardWidget(
                request: request,
                onAccept: () => _acceptDeliveryRequest(request),
                onDecline: () => _declineDeliveryRequest(request),
                onViewDetails: () => _viewRequestDetails(request),
              )),
        ],
      ],
    );
  }

  void _toggleOnlineStatus() {
    HapticFeedback.lightImpact();
    setState(() {
      _isOnline = !_isOnline;
    });

    final message = _isOnline
        ? 'Mode en ligne activé - Vous recevrez des notifications'
        : 'Mode hors ligne - Notifications désactivées';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _isOnline ? AppTheme.successGreen : AppTheme.errorRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    HapticFeedback.lightImpact();

    if (!notification['isRead']) {
      _markAsRead(notification['id']);
    }

    switch (notification['type']) {
      case 'delivery_request':
        _viewDeliveryRequest(notification);
        break;
      case 'customer_message':
        // Open chat with specific customer
        break;
      case 'booking_confirmed':
        // Navigate to booking details
        break;
      case 'payment_received':
        // Navigate to earnings/wallet
        break;
    }
  }

  void _markAsRead(String notificationId) {
    setState(() {
      final index = _notifications.indexWhere(
        (notif) => notif['id'] == notificationId,
      );
      if (index != -1) {
        _notifications[index]['isRead'] = true;
      }
    });
  }

  void _viewDeliveryRequest(Map<String, dynamic> notification) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Material(
        color: Colors.transparent,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: DeliveryRequestCardWidget(
            request: notification,
            onAccept: () => _acceptDeliveryRequest(notification),
            onDecline: () => _declineDeliveryRequest(notification),
            isDetailView: true,
          ),
        ),
      ),
    );
  }

  void _acceptDeliveryRequest(Map<String, dynamic> request) async {
    HapticFeedback.lightImpact();
    
    final result = await SupabaseService.updateDeliveryRequestStatus(request['id'], 'accepted');
    
    if (result['success'] == true) {
      if (mounted) {
        Navigator.pop(context);
        _loadData(); // Refresh UI
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demande acceptée ! L\'expéditeur a été notifié.'),
            backgroundColor: AppTheme.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? "Erreur lors de l'acceptation.")),
        );
      }
    }
  }

  void _declineDeliveryRequest(Map<String, dynamic> request) async {
    HapticFeedback.lightImpact();
    
    final result = await SupabaseService.updateDeliveryRequestStatus(request['id'], 'refused');
    
    if (result['success'] == true) {
      if (mounted) {
        Navigator.pop(context);
        _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demande déclinée'),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _pickupDeliveryRequest(Map<String, dynamic> request) async {
    HapticFeedback.mediumImpact();
    
    final result = await SupabaseService.updateDeliveryRequestStatus(request['id'], 'recupere');
    
    if (result['success'] == true) {
      if (mounted) {
        _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Colis marqué comme récupéré ! L\'expéditeur a été prévenu.'),
            backgroundColor: AppTheme.primaryGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _completeDeliveryRequest(Map<String, dynamic> request) async {
    HapticFeedback.heavyImpact();
    
    final TextEditingController pinController = TextEditingController();
    
    final String? enteredPin = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Validation de livraison'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Veuillez saisir le code PIN fourni par le client pour confirmer la remise du colis.'),
            const SizedBox(height: 16),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: const InputDecoration(
                labelText: 'Code PIN (4 chiffres)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, pinController.text),
            child: const Text('Valider'),
          ),
        ],
      ),
    );

    if (enteredPin == null || enteredPin.isEmpty) return;

    if (mounted) setState(() => _isLoading = true);

    final result = await SupabaseService.updateDeliveryRequestStatus(
      request['id'], 
      'terminee',
      pin: enteredPin,
    );
    
    if (mounted) setState(() => _isLoading = false);

    if (result['success'] == true) {
      if (mounted) {
        _loadData();
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Félicitations !'),
            content: const Text('Livraison terminée avec succès. Votre gain a été crédité.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Super !'),
              ),
            ],
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Erreur lors de la validation.'),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _viewRequestDetails(Map<String, dynamic> request) {
    _viewDeliveryRequest(request);
  }

  void _openChatWindow(Map<String, dynamic> conversation) {
    // Navigate to full chat interface
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 90.h,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: ChatInterface(
          conversation: conversation,
          isFullscreen: true,
          onSendMessage: (message) => _sendMessage(conversation['id'], message),
        ),
      ),
    );
  }

  void _sendMessage(String conversationId, String message) {
    HapticFeedback.lightImpact();
    // Handle message sending
    setState(() {
      final index = _chatConversations.indexWhere(
        (chat) => chat['id'] == conversationId,
      );
      if (index != -1) {
        _chatConversations[index]['lastMessage'] = message;
        _chatConversations[index]['timestamp'] = DateTime.now();
      }
    });
  }

  void _showQuickResponseTemplates(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final quickResponses = [
      "Je suis en route pour récupérer le colis",
      "Livraison effectuée avec succès",
      "Petit retard, j'arrive dans 10 minutes",
      "Pouvez-vous confirmer l'adresse ?",
      "Le destinataire n'est pas disponible",
      "Merci pour votre confiance !",
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            Text(
              'Réponses rapides',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 25.5),
            ...quickResponses.map(
              (response) => ListTile(
                leading: CustomIconWidget(
                  iconName: 'chat_bubble',
                  color: colorScheme.primary,
                  size: 20.0,
                ),
                title: Text(
                  response,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Use this response in active chat
                },
              ),
            ),
            SizedBox(height: 17.0),
          ],
        ),
      ),
    );
  }
}
