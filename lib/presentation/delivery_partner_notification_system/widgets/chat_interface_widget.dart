import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ChatInterface extends StatefulWidget {
  final Map<String, dynamic> conversation;
  final Function(String)? onSendMessage;
  final VoidCallback? onTap;
  final bool isFullscreen;

  const ChatInterface({
    super.key,
    required this.conversation,
    this.onSendMessage,
    this.onTap,
    this.isFullscreen = false,
  });

  @override
  State<ChatInterface> createState() => _ChatInterfaceState();
}

class _ChatInterfaceState extends State<ChatInterface> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  // Mock messages for the conversation
  final List<Map<String, dynamic>> _messages = [
    {
      "id": "msg_001",
      "senderId": "livreur_001",
      "senderName": "Moi",
      "message":
          "Bonjour ! J'ai accepté votre demande de livraison. Je peux récupérer les articles à partir de 14h.",
      "timestamp": DateTime.now().subtract(const Duration(minutes: 30)),
      "isDeliveryPartner": true,
      "type": "text",
    },
    {
      "id": "msg_002",
      "senderId": "client_001",
      "senderName": "Aminata Diallo",
      "message":
          "Parfait ! L'iPhone sera prêt. L'adresse est 15 Rue de la République, Plateau.",
      "timestamp": DateTime.now().subtract(const Duration(minutes: 25)),
      "isDeliveryPartner": false,
      "type": "text",
    },
    {
      "id": "msg_003",
      "senderId": "client_002",
      "senderName": "Mamadou Ba",
      "message":
          "De mon côté aussi c'est bon pour 14h. Je serai disponible jusqu'à 16h.",
      "timestamp": DateTime.now().subtract(const Duration(minutes: 20)),
      "isDeliveryPartner": false,
      "type": "text",
    },
    {
      "id": "msg_004",
      "senderId": "livreur_001",
      "senderName": "Moi",
      "message":
          "D'accord, je commence par récupérer chez Aminata vers 14h15, puis je livre chez Mamadou vers 14h45. Ça vous convient ?",
      "timestamp": DateTime.now().subtract(const Duration(minutes: 15)),
      "isDeliveryPartner": true,
      "type": "text",
    },
    {
      "id": "msg_005",
      "senderId": "client_001",
      "senderName": "Aminata Diallo",
      "message": "Parfait ! Merci beaucoup 😊",
      "timestamp": DateTime.now().subtract(const Duration(minutes: 10)),
      "isDeliveryPartner": false,
      "type": "text",
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (!widget.isFullscreen) {
      return _buildConversationSummary(context, theme, colorScheme);
    }

    return Column(
      children: [
        // Chat Header
        _buildChatHeader(context, theme, colorScheme),

        // Messages List
        Expanded(
          child: Container(
            color: colorScheme.surfaceContainer.withValues(alpha: 0.3),
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(
                  context,
                  message,
                  theme,
                  colorScheme,
                );
              },
            ),
          ),
        ),

        // Typing Indicator
        if (_isTyping)
          Container(
            padding: EdgeInsets.all(12.0),
            child: Row(
              children: [
                SizedBox(width: 16.0),
                Text(
                  'Quelqu\'un tape...',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

        // Message Input
        _buildMessageInput(context, theme, colorScheme),
      ],
    );
  }

  Widget _buildConversationSummary(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final participants = widget.conversation['participants'] as List;
    final unreadCount = widget.conversation['unreadCount'] as int;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.5),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
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
        leading: Stack(
          children: [
            // Multiple avatars for group chat
            SizedBox(
              width: 48.0,
              height: 48.0,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    child: Container(
                      width: 32.0,
                      height: 32.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.surface,
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: CustomImageWidget(
                          imageUrl: participants[0]['avatar'] as String,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 32.0,
                      height: 32.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.surface,
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: CustomImageWidget(
                          imageUrl: participants[1]['avatar'] as String,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        title: Text(
          'Échange ${participants[0]['name']} ↔ ${participants[1]['name']}',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4.3),
            Text(
              widget.conversation['lastMessage'] as String,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 8.5),
            Text(
              _formatTimestamp(widget.conversation['timestamp'] as DateTime),
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        trailing: unreadCount > 0
            ? Container(
                padding: EdgeInsets.all(6.0),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  unreadCount.toString(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              )
            : CustomIconWidget(
                iconName: 'chevron_right',
                color: colorScheme.onSurfaceVariant,
                size: 20.0,
              ),
        onTap: widget.onTap,
      ),
    );
  }

  Widget _buildChatHeader(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final participants = widget.conversation['participants'] as List;

    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1)),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainer,
                  shape: BoxShape.circle,
                ),
                child: CustomIconWidget(
                  iconName: 'arrow_back',
                  size: 20.0,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            SizedBox(width: 12.0),

            // Group avatar
            SizedBox(
              width: 48.0,
              height: 40.0,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    child: Container(
                      width: 32.0,
                      height: 32.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.surface,
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: CustomImageWidget(
                          imageUrl: participants[0]['avatar'] as String,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    child: Container(
                      width: 32.0,
                      height: 32.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.surface,
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: CustomImageWidget(
                          imageUrl: participants[1]['avatar'] as String,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(width: 12.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chat de livraison',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    '${participants[0]['name']} & ${participants[1]['name']}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Call button (optional)
            GestureDetector(
              onTap: () => _initiateCall(),
              child: Container(
                padding: EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: CustomIconWidget(
                  iconName: 'phone',
                  size: 20.0,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
    BuildContext context,
    Map<String, dynamic> message,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final isDeliveryPartner = message['isDeliveryPartner'] as bool;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.5),
      child: Row(
        mainAxisAlignment:
            isDeliveryPartner ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isDeliveryPartner) ...[
            // Sender avatar
            Container(
              width: 32.0,
              height: 32.0,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: ClipOval(
                child: CustomImageWidget(
                  imageUrl: _getAvatarForSender(
                    message['senderName'] as String,
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(width: 8.0),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isDeliveryPartner
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isDeliveryPartner)
                  Padding(
                    padding: EdgeInsets.only(bottom: 4.3, left: 12.0),
                    child: Text(
                      message['senderName'] as String,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: isDeliveryPartner
                        ? colorScheme.primary
                        : colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomLeft: isDeliveryPartner
                          ? const Radius.circular(16)
                          : const Radius.circular(4),
                      bottomRight: isDeliveryPartner
                          ? const Radius.circular(4)
                          : const Radius.circular(16),
                    ),
                  ),
                  child: Text(
                    message['message'] as String,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDeliveryPartner
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface,
                    ),
                  ),
                ),
                SizedBox(height: 4.3),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    _formatTimestamp(message['timestamp'] as DateTime),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 9,
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.6,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isDeliveryPartner) SizedBox(width: 8.0),
        ],
      ),
    );
  }

  Widget _buildMessageInput(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Tapez votre message...',
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.6,
                      ),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                  maxLines: null,
                  onChanged: (value) {
                    setState(() {
                      // Handle typing indicator
                    });
                  },
                ),
              ),
            ),
            SizedBox(width: 8.0),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                padding: EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: CustomIconWidget(
                  iconName: 'send',
                  size: 20.0,
                  color: colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    HapticFeedback.lightImpact();

    setState(() {
      _messages.add({
        "id": "msg_${DateTime.now().millisecondsSinceEpoch}",
        "senderId": "livreur_001",
        "senderName": "Moi",
        "message": message,
        "timestamp": DateTime.now(),
        "isDeliveryPartner": true,
        "type": "text",
      });
      _messageController.clear();
    });

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });

    if (widget.onSendMessage != null) {
      widget.onSendMessage!(message);
    }
  }

  void _initiateCall() {
    HapticFeedback.lightImpact();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contacter les clients'),
        content: const Text(
          'Cette fonctionnalité permettra d\'appeler les clients directement depuis l\'app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _getAvatarForSender(String senderName) {
    final participants = widget.conversation['participants'] as List;
    for (final participant in participants) {
      if (participant['name'] == senderName) {
        return participant['avatar'] as String;
      }
    }
    return participants[0]['avatar'] as String;
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}
