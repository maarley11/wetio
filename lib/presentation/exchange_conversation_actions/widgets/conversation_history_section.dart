import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ConversationHistorySection extends StatelessWidget {
  final List<Map<String, dynamic>> messages;
  final ScrollController scrollController;

  const ConversationHistorySection({
    super.key,
    required this.messages,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView.builder(
      controller: scrollController,
      padding: EdgeInsets.all(16.0),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isCurrentUser = message['isCurrentUser'] as bool;
        final timestamp = message['timestamp'] as DateTime;

        return Container(
          margin: EdgeInsets.only(bottom: 25.5),
          child: Row(
            mainAxisAlignment:
                isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Other user's avatar
              if (!isCurrentUser) ...[
                Container(
                  width: 40.0,
                  height: 40.0,
                  margin: EdgeInsets.only(right: 8.0),
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  child: ClipOval(
                    child: CustomImageWidget(
                      imageUrl: message['avatar'] ?? '',
                      fit: BoxFit.cover,
                      errorWidget: Container(
                        color: Colors.grey[200],
                        child: Icon(
                          Icons.person,
                          color: AppTheme.textSecondary,
                          size: 24.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ],

              // Message bubble
              Flexible(
                child: Column(
                  crossAxisAlignment: isCurrentUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    // Sender name (for other users only)
                    if (!isCurrentUser)
                      Padding(
                        padding: EdgeInsets.only(bottom: 4.3, left: 12.0),
                        child: Text(
                          message['sender'],
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),

                    // Message content
                    Container(
                      constraints: BoxConstraints(maxWidth: 75.w),
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 17.0,
                      ),
                      decoration: BoxDecoration(
                        color: isCurrentUser
                            ? AppTheme.primaryGreen
                            : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(18),
                          topRight: const Radius.circular(18),
                          bottomLeft: Radius.circular(isCurrentUser ? 18 : 6),
                          bottomRight: Radius.circular(isCurrentUser ? 6 : 18),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message['message'],
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: isCurrentUser
                                  ? Colors.white
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),

                          // Images if present
                          if (message['hasImages'] == true) ...[
                            SizedBox(height: 17.0),
                            Container(
                              height: 170.0,
                              decoration: BoxDecoration(
                                color: Colors.grey.withAlpha(51),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  'Photos de la chemise',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: isCurrentUser
                                        ? Colors.white.withAlpha(204)
                                        : AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Timestamp
                    Padding(
                      padding: EdgeInsets.only(
                        top: 4.3,
                        left: isCurrentUser ? 0 : 12.0,
                        right: isCurrentUser ? 12.0 : 0,
                      ),
                      child: Text(
                        _formatTimestamp(timestamp),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Current user's avatar placeholder
              if (isCurrentUser) SizedBox(width: 48.0), // Space for alignment
            ],
          ),
        );
      },
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Maintenant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else {
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}
