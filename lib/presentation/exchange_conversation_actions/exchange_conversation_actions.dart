import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './widgets/action_buttons_section.dart';
import './widgets/conversation_history_section.dart';
import './widgets/meeting_point_modal.dart';

class ExchangeConversationActions extends StatefulWidget {
  const ExchangeConversationActions({super.key});

  @override
  State<ExchangeConversationActions> createState() =>
      _ExchangeConversationActionsState();
}

class _ExchangeConversationActionsState
    extends State<ExchangeConversationActions> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Real conversation data
  List<Map<String, dynamic>> _messages = [];
  String? _exchangeId;
  String? _conversationId;
  Map<String, dynamic>? _targetProduct;
  Map<String, dynamic>? _proposedProduct;
  
  bool _isLoading = true;
  bool _isExchangeAgreed = true; // Show action buttons when true
  RealtimeChannel? _messageSubscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic> && _exchangeId == null) {
      _exchangeId = args['exchangeId']?.toString();
      _targetProduct = args['targetProduct'] as Map<String, dynamic>?;
      _proposedProduct = args['proposedProduct'] as Map<String, dynamic>?;
      _loadConversationAndMessages();
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  Future<void> _loadConversationAndMessages() async {
    if (_exchangeId == null) return;

    setState(() => _isLoading = true);

    try {
      // Determine the other participant ID
      final currentUser = SupabaseService.getCurrentUser();
      if (currentUser == null) return;

      String? otherParticipantId;
      if (_targetProduct != null) {
        final ownerId = _targetProduct!['owner_id']?.toString() ?? _targetProduct!['owner']?['id']?.toString();
        if (ownerId == currentUser.id) {
          // I am the owner, other is requester
          // We might need to fetch the exchange to find requester_id if not in args
        } else {
          otherParticipantId = ownerId;
        }
      }

      // If we don't have otherParticipantId yet, we fetch exchange details
      if (otherParticipantId == null) {
        final details = await SupabaseService.getExchangeProposalDetails(_exchangeId!);
        if (details != null) {
          otherParticipantId = details['requester_id'] == currentUser.id 
              ? details['owner_id'] 
              : details['requester_id'];
        }
      }

      if (otherParticipantId == null) return;

      // Get or create conversation
      _conversationId = await SupabaseService.getOrCreateConversation(
        participantBId: otherParticipantId,
        exchangeId: _exchangeId!,
      );

      if (_conversationId != null) {
        // Load existing messages
        final messages = await SupabaseService.getChatMessages(_conversationId!);
        
        if (mounted) {
          setState(() {
            _messages = messages.map((m) => {
              'id': m['id'],
              'sender': m['sender_id'] == currentUser.id ? 'Moi' : 'Autre',
              'isCurrentUser': m['sender_id'] == currentUser.id,
              'message': m['content'],
              'timestamp': DateTime.parse(m['created_at']),
              'avatar': null,
            }).toList();
            _isLoading = false;
          });
          
          _setupRealtime();
          _scrollToBottom();
        }
      }
    } catch (e) {
      print('Error loading conversation: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _setupRealtime() {
    if (_conversationId == null) return;

    final supabase = SupabaseService.safeClient;
    if (supabase == null) return;

    _messageSubscription = supabase
        .channel('public:chat_messages:conversation_id=eq.$_conversationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: _conversationId,
          ),
          callback: (payload) {
            final newMessage = payload.newRecord;
            final currentUser = SupabaseService.getCurrentUser();
            
            // Only add if not already present (avoid duplicates for sender)
            if (newMessage['sender_id'] != currentUser?.id) {
              if (mounted) {
                setState(() {
                  _messages.add({
                    'id': newMessage['id'],
                    'sender': 'Autre',
                    'isCurrentUser': false,
                    'message': newMessage['content'],
                    'timestamp': DateTime.parse(newMessage['created_at']),
                    'avatar': null,
                  });
                });
                _scrollToBottom();
              }
            }
          },
        )
        .subscribe();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _messageSubscription?.unsubscribe();
    super.dispose();
  }

  void _showDeliverySearch() {
    HapticFeedback.mediumImpact();
    // Navigate directly to the delivery request system screen
    Navigator.pushNamed(
      context,
      AppRoutes.deliveryRequestSystem,
      arguments: {
        'fromExchange': true,
        'exchangeId': _exchangeId,
        'conversationId': _conversationId,
      },
    );
  }

  void _showHandToHandExchange() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.9,
        minChildSize: 0.6,
        builder: (context, scrollController) => MeetingPointModal(
          onMeetingPointConfirmed: (meetingPoint) {
            Navigator.pop(context);
            _showHandToHandConfirmation(meetingPoint);
          },
        ),
      ),
    );
  }

  void _showDeliveryConfirmation(Map<String, dynamic> deliveryPartner) {
    HapticFeedback.mediumImpact();
    Navigator.pushNamed(
      context,
      AppRoutes.deliveryRequestSystem,
      arguments: {
        'fromExchange': true,
        'preSelectedPartner': deliveryPartner,
      },
    );
  }

  void _showHandToHandConfirmation(Map<String, dynamic> meetingPoint) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomIconWidget(
              iconName: 'handshake',
              size: 48,
              color: AppTheme.primaryOrange,
            ),
            SizedBox(height: 17.0),
            Text(
              'Échange confirmé',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 8.5),
            Text(
              'Votre choix d\'échange en mains propres a été enregistré. Rendez-vous au ${meetingPoint['name']}.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 25.5),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryOrange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'OK',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _conversationId == null) return;

    final content = _messageController.text.trim();
    _messageController.clear();
    HapticFeedback.lightImpact();

    try {
      final currentUser = SupabaseService.getCurrentUser();
      
      // Optimistic update
      setState(() {
        _messages.add({
          'id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
          'sender': 'Moi',
          'isCurrentUser': true,
          'message': content,
          'timestamp': DateTime.now(),
          'avatar': null,
        });
      });
      _scrollToBottom();

      await SupabaseService.sendChatMessage(
        conversationId: _conversationId!,
        content: content,
      );
    } catch (e) {
      _showErrorToast("Erreur lors de l'envoi du message");
    }
  }

  void _showErrorToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Theme.of(context).colorScheme.error,
      textColor: Colors.white,
    );
  }

  void _showSuccessToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AppTheme.successGreen,
      textColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: CustomAppBar(
        title: 'Conversation d\'échange',
        centerTitle: true,
        leading: IconButton(
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            color: colorScheme.onSurface,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: CustomIconWidget(
              iconName: 'more_vert',
              color: colorScheme.onSurface,
            ),
            onPressed: () {
              // Show conversation options
            },
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              // Conversation History
              Expanded(
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : ConversationHistorySection(
                      messages: _messages,
                      scrollController: _scrollController,
                    ),
              ),

              // Action Buttons (shown when exchange is agreed)
              if (_isExchangeAgreed)
                ActionButtonsSection(
                  onFindDelivery: _showDeliverySearch,
                  onHandToHandExchange: _showHandToHandExchange,
                ),

              // Message Input
              Container(
                padding: EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  border: Border(
                    top: BorderSide(color: colorScheme.outline.withAlpha(51)),
                  ),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Écrivez votre message...',
                            hintStyle: GoogleFonts.inter(
                              color: AppTheme.textSecondary,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(
                                color: colorScheme.outline.withAlpha(77),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(
                                color: AppTheme.primaryGreen,
                                width: 2,
                              ),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 12.8,
                            ),
                          ),
                          maxLines: 3,
                          minLines: 1,
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      SizedBox(width: 8.0),
                      GestureDetector(
                        onTap: _sendMessage,
                        child: Container(
                          padding: EdgeInsets.all(12.0),
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryGreen,
                            shape: BoxShape.circle,
                          ),
                          child: CustomIconWidget(
                            iconName: 'send',
                            size: 24,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
