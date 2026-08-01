import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'supabase_service.dart';

class NotificationService {
  static const String _oneSignalAppId = '413a0a67-f737-42ec-ab09-8a91dea50089';

  /// Initialize OneSignal and bind current authenticated user
  static Future<void> init() async {
    if (kIsWeb) return;
    try {
      OneSignal.Debug.setLogLevel(OSLogLevel.none);
      OneSignal.initialize(_oneSignalAppId);
      OneSignal.Notifications.requestPermission(true);

      final user = SupabaseService.getCurrentUser();
      if (user != null) {
        bindUser(user.id);
      }
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  }

  /// Bind logged-in user to OneSignal External User ID
  static void bindUser(String userId) {
    if (kIsWeb) return;
    try {
      OneSignal.login(userId);
      debugPrint('OneSignal registered user: $userId');
    } catch (e) {
      debugPrint('OneSignal login error: $e');
    }
  }

  /// Logout user from OneSignal
  static void unbindUser() {
    if (kIsWeb) return;
    try {
      OneSignal.logout();
    } catch (_) {}
  }

  /// Send real-time push notification to target user's phone (works when phone is locked or closed)
  static Future<void> sendPushNotification({
    required String recipientUserId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    if (recipientUserId.isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse('https://onesignal.com/api/v1/notifications'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
        },
        body: jsonEncode({
          'app_id': _oneSignalAppId,
          'include_aliases': {
            'external_id': [recipientUserId],
          },
          'target_channel': 'push',
          'headings': {'fr': title, 'en': title},
          'contents': {'fr': body, 'en': body},
          'data': data ?? {},
        }),
      );

      debugPrint('OneSignal Push status: ${response.statusCode} -> ${response.body}');
    } catch (e) {
      debugPrint('Error sending push notification: $e');
    }
  }
}
