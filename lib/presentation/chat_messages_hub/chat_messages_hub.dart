import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../routes/app_routes.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_bottom_bar.dart';
import './widgets/chat_search_bar_widget.dart';
import './widgets/conversation_card_widget.dart';

class ChatMessagesHub extends StatefulWidget {
  const ChatMessagesHub({super.key});

  @override
  State<ChatMessagesHub> createState() => _ChatMessagesHubState();
}

class _ChatMessagesHubState extends State<ChatMessagesHub>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  String _searchQuery = '';
  bool _isRefreshing = false;

  // Real conversation data
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;

  List<Map<String, dynamic>> get _filteredConversations {
    List<Map<String, dynamic>> filtered = _conversations;
    if (_tabController.index == 1) {
      filtered = filtered.where((c) => c['type'] == 'exchange').toList();
    } else if (_tabController.index == 2) {
      filtered = filtered.where((c) => c['type'] == 'delivery').toList();
    }
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (c) =>
                (c['name'] as String).toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                (c['lastMessage'] as String).toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ),
          )
          .toList();
    }
    return filtered;
  }

  int get _totalUnread =>
      _conversations.fold(0, (sum, c) => sum + (c['unreadCount'] as int));

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadRealConversations();
  }

  Future<void> _loadRealConversations() async {
    setState(() => _isLoading = true);
    
    try {
      final currentUser = SupabaseService.getCurrentUser();
      if (currentUser == null) return;

      final convs = await SupabaseService.getConversations();
      
      setState(() {
        _conversations = convs.map((c) {
          final isParticipantA = c['participant_a'] == currentUser.id;
          final otherProfile = isParticipantA ? c['participant_b_profile'] : c['participant_a_profile'];
          final unreadCount = isParticipantA ? c['unread_count_a'] : c['unread_count_b'];
          
          return {
            'id': c['id'],
            'exchangeId': c['exchange_id'],
            'name': otherProfile?['full_name'] ?? 'Utilisateur',
            'avatar': otherProfile?['avatar_url'],
            'lastMessage': c['last_message'] ?? 'Commencez la discussion',
            'time': c['last_message_at'] != null 
                ? _formatTime(DateTime.parse(c['last_message_at'])) 
                : '',
            'unreadCount': unreadCount ?? 0,
            'isOnline': false,
            'productTitle': c['exchange']?['target_product']?['title'],
            'type': 'exchange',
            'data': c,
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading conversations: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day}/${dt.month}';
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    await _loadRealConversations();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Text(
              'Messages',
              style: GoogleFonts.dmSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            if (_totalUnread > 0) ...[
              SizedBox(width: 8.0),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.5),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$_totalUnread',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.edit_outlined,
              color: colorScheme.onSurface,
              size: 22.0,
            ),
            onPressed: () {
              Navigator.pushNamed(
                context,
                AppRoutes.exchangeConversationActions,
              );
            },
          ),
          SizedBox(width: 8.0),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelStyle: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurfaceVariant,
          indicatorColor: colorScheme.primary,
          indicatorWeight: 2.5,
          tabs: const [
            Tab(text: 'Tous'),
            Tab(text: 'Échanges'),
            Tab(text: 'Livraisons'),
          ],
        ),
      ),
      body: Column(
        children: [
          ChatSearchBarWidget(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildConversationList(),
                _buildConversationList(),
                _buildConversationList(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomBar(
        currentIndex: 1,
        variant: CustomBottomBarVariant.standard,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.pushNamed(context, AppRoutes.addProduct);
        },
        backgroundColor: const Color(0xFFFF6B00),
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildConversationList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final conversations = _filteredConversations;
    if (conversations.isEmpty) {
      return _buildEmptyState();
    }
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: Theme.of(context).colorScheme.primary,
      child: ListView.builder(
        itemCount: conversations.length,
        itemBuilder: (context, index) {
          return ConversationCardWidget(
            conversation: conversations[index],
            onTap: () {
              HapticFeedback.lightImpact();
              final conversation = conversations[index];
              if (conversation['type'] == 'delivery') {
                Navigator.pushNamed(
                  context,
                  AppRoutes.deliveryPartnerNotificationSystem,
                  arguments: conversation,
                );
              } else {
                Navigator.pushNamed(
                  context,
                  AppRoutes.exchangeConversationActions,
                  arguments: {
                    'exchangeId': conversation['exchangeId'],
                    'conversationId': conversation['id'],
                    // Other details will be loaded by the chat screen
                  },
                );
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 48.0,
              color: colorScheme.primary,
            ),
          ),
          SizedBox(height: 17.0),
          Text(
            'Aucune conversation',
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 8.5),
          Text(
            'Vos conversations apparaîtront ici\nlorsque vous commencerez à échanger.',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 25.5),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.homeFeed),
            icon: const Icon(Icons.explore_outlined),
            label: Text(
              'Explorer le marché',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
