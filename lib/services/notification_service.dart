import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:flutter/material.dart';
import '../routes/app_routes.dart';
import 'supabase_service.dart';

class NotificationService {
  static const String _oneSignalAppId = '413a0a67-f737-42ec-ab09-8a91dea50089';
  static String get _defaultRestApiKey => utf8.decode(base64.decode(
      'b3NfdjJfYXBwX2llNWF1ejd4ZzVib3preWpya2k1NWppYXJmNHZqaWNpcmZsZWdudXVwd3ZoM3dqbHlwd3k0MnhvbDZxeDZ2cmNqYmwyZ3BsN21icXludTN5Z2NlMmw1bzJ5MzQ3YnFxNGtwaTd1aHk='));

  static GlobalKey<NavigatorState>? navigatorKey;

  static void setNavigatorKey(GlobalKey<NavigatorState> key) {
    navigatorKey = key;
  }

  /// Initialize OneSignal and bind current authenticated user
  static Future<void> init() async {
    if (kIsWeb) return;
    try {
      OneSignal.Debug.setLogLevel(OSLogLevel.none);
      OneSignal.initialize(_oneSignalAppId);
      OneSignal.Notifications.requestPermission(true);

      // Listen to Notification clicks for direct navigation
      OneSignal.Notifications.addClickListener((event) {
        final data = event.notification.additionalData;
        if (data != null) {
          handleNotificationClick(data);
        }
      });

      final user = SupabaseService.getCurrentUser();
      if (user != null) {
        bindUser(user.id);
      }
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  }

  static void handleNotificationClick(Map<String, dynamic> data) {
    debugPrint('OneSignal notification clicked: $data');
    final type = data['type']?.toString();
    final nav = navigatorKey?.currentState;
    if (nav == null) return;

    try {
      if (type == 'exchange_proposal' && data['exchangeId'] != null) {
        nav.pushNamed(
          AppRoutes.exchangeProposal,
          arguments: {'exchangeId': data['exchangeId'].toString()},
        );
      } else if (type == 'chat' && data['conversationId'] != null) {
        nav.pushNamed(
          AppRoutes.chatMessagesHub,
          arguments: {'conversationId': data['conversationId'].toString()},
        );
      } else if (type == 'delivery_request' || type == 'delivery_status') {
        final deliveryId = data['deliveryId']?.toString();
        if (deliveryId != null && deliveryId.isNotEmpty) {
          nav.pushNamed(
            AppRoutes.threeStepDeliveryCoordinationScreen,
            arguments: {'deliveryRequestId': deliveryId},
          );
        } else {
          nav.pushNamed(AppRoutes.notificationsScreen);
        }
      } else {
        nav.pushNamed(AppRoutes.notificationsScreen);
      }
    } catch (e) {
      debugPrint('Error navigating on notification click: $e');
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
      const envApiKey = String.fromEnvironment('ONESIGNAL_REST_API_KEY', defaultValue: '');
      final restApiKey = envApiKey.isNotEmpty ? envApiKey : _defaultRestApiKey;
      final authHeader = restApiKey.startsWith('os_v2_app_')
          ? 'Key $restApiKey'
          : 'Basic $restApiKey';

      final response = await http.post(
        Uri.parse('https://onesignal.com/api/v1/notifications'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': authHeader,
        },
        body: jsonEncode({
          'app_id': _oneSignalAppId,
          'include_aliases': {
            'external_id': [recipientUserId],
          },
          'target_channel': 'push',
          'headings': {'fr': title, 'en': title},
          'contents': {'fr': body, 'en': body},
          'ios_sound': 'default',
          'ios_badgeType': 'Increase',
          'ios_badgeCount': 1,
          'data': data ?? {},
        }),
      );

      debugPrint('OneSignal Push status: ${response.statusCode} -> ${response.body}');
    } catch (e) {
      debugPrint('Error sending push notification: $e');
    }
  }
}
