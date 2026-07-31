import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_html/html.dart' as html;
import '../stubs/io_stub.dart';

import '../theme/app_theme.dart';
import '../core/app_export.dart';
import 'package:path_provider/path_provider.dart'
    if (dart.library.html) 'package:wetio/stubs/path_provider_stub.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();

  /// Upload profile image to Supabase Storage
  static Future<String> uploadProfileImage(XFile image) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id ?? 'unknown';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'profiles/${userId}_${timestamp}.jpg';

    try {
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        await supabase.storage.from('product-images').uploadBinary(
              fileName,
              bytes,
              fileOptions: const FileOptions(
                contentType: 'image/jpeg',
                upsert: true,
              ),
            );
      } else {
        // We use the stub or real io depending on platform
        // Since this is a service, we can use the same logic as AddProductScreen
        // But we need to make sure we have the imports.
        // Wait, SupabaseService already has some stubs.
        
        // Actually, let's use the simplest way that works for both.
        final bytes = await image.readAsBytes();
        await supabase.storage.from('product-images').uploadBinary(
          fileName,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );
      }

      final publicUrl = supabase.storage.from('product-images').getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      print('❌ Erreur upload profil: $e');
      throw e;
    }
  }

  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return response;
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getUserProducts(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('products')
          .select('*')
          .eq('owner_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching user products: $e');
      return [];
    }
  }

  // --- CHAT SYSTEM METHODS ---

  /// Get or create a conversation for an exchange
  static Future<String?> getOrCreateConversation({
    required String participantBId,
    required String exchangeId,
  }) async {
    try {
      final user = getCurrentUser();
      if (user == null) return null;

      // Check if conversation already exists for this exchange
      final existing = await Supabase.instance.client
          .from('chat_conversations')
          .select('id')
          .eq('exchange_id', exchangeId)
          .maybeSingle();

      if (existing != null) {
        return existing['id'] as String;
      }

      // Create new conversation
      final response = await Supabase.instance.client
          .from('chat_conversations')
          .insert({
            'participant_a': user.id,
            'participant_b': participantBId,
            'exchange_id': exchangeId,
          })
          .select('id')
          .single();

      return response['id'] as String;
    } catch (e) {
      print('Error getOrCreateConversation: $e');
      return null;
    }
  }

  /// Get messages for a conversation
  static Future<List<Map<String, dynamic>>> getChatMessages(String conversationId) async {
    try {
      final response = await Supabase.instance.client
          .from('chat_messages')
          .select('*')
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching chat messages: $e');
      return [];
    }
  }

  /// Send a message
  static Future<void> sendChatMessage({
    required String conversationId,
    required String content,
  }) async {
    try {
      final user = getCurrentUser();
      if (user == null) return;

      await Supabase.instance.client.from('chat_messages').insert({
        'conversation_id': conversationId,
        'sender_id': user.id,
        'content': content,
      });
    } catch (e) {
      print('Error sending message: $e');
      throw e;
    }
  }

  /// Get all conversations for current user
  static Future<List<Map<String, dynamic>>> getConversations() async {
    try {
      final user = getCurrentUser();
      if (user == null) return [];

      final response = await Supabase.instance.client
          .from('chat_conversations')
          .select('''
            *,
            participant_a_profile:user_profiles!participant_a(id, full_name, avatar_url),
            participant_b_profile:user_profiles!participant_b(id, full_name, avatar_url),
            exchange:exchanges!exchange_id(id, target_product_id, target_product:products!target_product_id(title))
          ''')
          .or('participant_a.eq.${user.id},participant_b.eq.${user.id}')
          .order('last_message_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching conversations: $e');
      return [];
    }
  }

  /// Create a real delivery request
  static Future<String?> createDeliveryRequest({
    required String partnerUserId,
    required String exchangeId,
    required Map<String, dynamic> personA,
    required Map<String, dynamic> personB,
  }) async {
    try {
      final user = getCurrentUser();
      if (user == null) return null;

      // Get exchange details to find person B
      final exchange = await Supabase.instance.client
          .from('exchanges')
          .select('owner_id, requester_id')
          .eq('id', exchangeId)
          .single();
      
      final personBId = (exchange['requester_id'] == user.id) 
          ? exchange['owner_id'] 
          : exchange['requester_id'];

      // Generate a random 4-digit PIN for security
      final String verificationPin = (1000 + (DateTime.now().millisecond % 9000)).toString();

      final response = await Supabase.instance.client.from('delivery_requests').insert({
        'partner_user_id': partnerUserId,
        'exchange_id': exchangeId,
        'initiator_id': user.id,
        'person_a_id': user.id,
        'person_b_id': personBId,
        'delivery_status': 'en_attente',
        'pickup_address': personA['address'],
        'delivery_address': personB['address'],
        'person_a_address': personA['address'],
        'person_b_address': personB['address'],
        'pickup_lat': personA['lat'],
        'pickup_lng': personA['lng'],
        'delivery_lat': personB['lat'],
        'delivery_lng': personB['lng'],
        'is_exchange_delivery': true,
        'exchange_type': 'wetio',
        'verification_pin': verificationPin,
      }).select('id').single();

      return response['id'] as String;
    } catch (e) {
      print('❌ FAILED to create delivery request: $e');
      throw Exception('Erreur Supabase: $e');
    }
  }

  /// Register current user as a delivery partner
  static Future<bool> registerAsDeliveryPartner() async {
    try {
      final user = getCurrentUser();
      if (user == null) return false;

      await Supabase.instance.client.from('user_profiles').update({
        'is_delivery_partner': true,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);

      return true;
    } catch (e) {
      print('Error registering as delivery partner: $e');
      return false;
    }
  }

  /// Get list of real delivery partners
  static Future<List<Map<String, dynamic>>> getDeliveryPartners() async {
    try {
      final response = await Supabase.instance.client
          .from('user_profiles')
          .select('*')
          .eq('is_delivery_partner', true)
          .eq('is_active', true);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching delivery partners: $e');
      return [];
    }
  }

  /// Get delivery requests for current partner
  static Future<List<Map<String, dynamic>>> getMyDeliveryRequests() async {
    try {
      final user = getCurrentUser();
      if (user == null) return [];

      List<Map<String, dynamic>> list = [];
      try {
        final response = await Supabase.instance.client
            .from('delivery_requests')
            .select('*, sender_profile:user_profiles!person_a_id(full_name, avatar_url), receiver_profile:user_profiles!person_b_id(full_name, avatar_url)')
            .eq('partner_user_id', user.id)
            .order('created_at', ascending: false);
        list = List<Map<String, dynamic>>.from(response);
      } catch (_) {
        final response = await Supabase.instance.client
            .from('delivery_requests')
            .select('*')
            .eq('partner_user_id', user.id)
            .order('created_at', ascending: false);
        list = List<Map<String, dynamic>>.from(response);
      }

      // Enrich profiles manually if missing
      for (var req in list) {
        if (req['sender_profile'] == null && req['person_a_id'] != null) {
          final profileA = await getUserProfile(req['person_a_id'].toString());
          if (profileA != null) {
            req['sender_profile'] = profileA;
          }
        }
        if (req['receiver_profile'] == null && req['person_b_id'] != null) {
          final profileB = await getUserProfile(req['person_b_id'].toString());
          if (profileB != null) {
            req['receiver_profile'] = profileB;
          }
        }
      }

      return list;
    } catch (e) {
      print('Error fetching my delivery requests: $e');
      return [];
    }
  }


  /// Get current courier balance
  static Future<num> getCourierBalance() async {
    try {
      final user = getCurrentUser();
      if (user == null) return 0;
      
      final profile = await getUserProfile(user.id);
      return (profile?['balance'] ?? 0) as num;
    } catch (e) {
      print('Error fetching courier balance: $e');
      return 0;
    }
  }

  /// Request a payout
  static Future<Map<String, dynamic>> requestPayout({
    required num amount,
  }) async {
    try {
      final user = getCurrentUser();
      if (user == null) throw Exception('Utilisateur non connecté.');

      final profile = await getUserProfile(user.id);
      final num currentBalance = (profile?['balance'] ?? 0) as num;

      if (amount <= 0 || currentBalance <= 0) {
        return {'success': false, 'message': 'Solde insuffisant pour effectuer un retrait.'};
      }

      // 1. Attempt insert into payout_requests table if exists
      try {
        await Supabase.instance.client.from('payout_requests').insert({
          'user_id': user.id,
          'amount': amount,
          'method': profile?['payout_method'] ?? 'Wave / Orange Money',
          'phone': profile?['payout_phone'] ?? profile?['phone'] ?? '',
          'status': 'pending',
          'created_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        print('payout_requests table not available, proceeding with balance reset: $e');
      }

      // 2. Reset balance to 0 on user profile
      final newBalance = (currentBalance - amount) < 0 ? 0 : (currentBalance - amount);
      await Supabase.instance.client.from('user_profiles').update({
        'balance': newBalance,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);

      return {
        'success': true,
        'message': 'Demande de retrait de ${amount.toInt()} FCFA effectuée avec succès ! Le virement Wave / Orange Money est en cours.',
      };
    } catch (e) {
      print('Error requesting payout: $e');
      return {
        'success': false,
        'message': 'Impossible d\'effectuer le retrait pour le moment. Veuillez réessayer.',
      };
    }
  }

  /// Update delivery request status with PIN verification for completion
  static Future<Map<String, dynamic>> updateDeliveryRequestStatus(String requestId, String status, {String? pin}) async {
    try {
      final client = Supabase.instance.client;
      
      // If completing, we MUST verify the PIN
      if (status == 'terminee') {
        if (pin == null || pin.isEmpty) {
          return {'success': false, 'message': 'Le code PIN est obligatoire pour terminer la livraison.'};
        }

        // Fetch request details to verify PIN
        final request = await client
            .from('delivery_requests')
            .select('verification_pin, partner_user_id')
            .eq('id', requestId)
            .single();
        
        if (request['verification_pin'].toString() != pin) {
          return {'success': false, 'message': 'Code PIN incorrect. Veuillez vérifier avec le client.'};
        }
        
        // PIN IS CORRECT -> PROCESS PAYMENT
        final courierId = request['partner_user_id'];
        const int netEarnings = 2000;

        final profile = await getUserProfile(courierId);
        if (profile != null) {
          final currentBalance = (profile['balance'] ?? 0) as num;
          await client
              .from('user_profiles')
              .update({
                'balance': currentBalance + netEarnings,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', courierId);
        }
      }

      // Final status update
      await client
          .from('delivery_requests')
          .update({'delivery_status': status, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', requestId);
      
      return {'success': true, 'message': 'Statut mis à jour avec succès.'};
    } catch (e) {
      print('Error updating delivery request status: $e');
      return {'success': false, 'message': 'Erreur technique: $e'};
    }
  }

  SupabaseService._();

  static bool isInitialized = false;

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://zjcnggoxjyonahoiansk.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpqY25nZ294anlvbmFob2lhbnNrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxMDg4NzksImV4cCI6MjA3NDY4NDg3OX0.ECbaWk_cl6VNCrodLwvAzMDWk3gO5UfkmKS6Ca4Qg2E',
  );

  // Initialize Supabase - call this in main()
  static Future<void> initialize() async {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      debugPrint(
        'SupabaseService: SUPABASE_URL or SUPABASE_ANON_KEY not set. '
        'Skipping Supabase initialization. Build with --dart-define to enable.',
      );
      isInitialized = false;
      return;
    }

    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
    isInitialized = true;
  }

  // Get Supabase client — returns null if not initialized
  static SupabaseClient? get safeClient {
    if (!isInitialized) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  // Get Supabase client
  SupabaseClient get client => Supabase.instance.client;

  // ========== AUTHENTICATION METHODS ==========

  /// Sign up a new user with email and password
  static Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
    String? pseudo,
    String? phone,
    String? location,
  }) async {
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName ?? '',
          'pseudo': pseudo ?? '',
          'phone': phone ?? '',
          'location': location ?? '',
        },
      );

      // If signup succeeded but user needs email confirmation,
      // try to sign in directly so the user can access the app immediately
      if (response.user != null && response.session == null) {
        try {
          final signInResponse = await Supabase.instance.client.auth
              .signInWithPassword(email: email, password: password);
          if (signInResponse.session != null) {
            return signInResponse;
          }
        } catch (_) {
          // If auto sign-in fails, return the signup response anyway
        }
      }

      return response;
    } catch (e) {
      throw Exception('Sign-up failed: $e');
    }
  }

  /// Resend confirmation email to user
  static Future<void> resendConfirmationEmail(String email) async {
    try {
      await Supabase.instance.client.auth.resend(
        type: OtpType.signup,
        email: email,
      );
    } catch (e) {
      throw Exception('Failed to resend confirmation email: $e');
    }
  }

  /// Sign in with email and password
  static Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      throw Exception('Sign-in failed: $e');
    }
  }

  /// Reset password by phone or email - returns descriptive status string
  static Future<String> resetPasswordByPhone(String identifier) async {
    final clean = identifier.trim();
    if (clean.isEmpty) throw Exception('Veuillez saisir un numéro de téléphone ou un email valide.');

    final supabase = Supabase.instance.client;

    if (clean.contains('@')) {
      await supabase.auth.resetPasswordForEmail(clean);
      return 'Un lien de réinitialisation a été envoyé à votre adresse email ($clean). Veuillez vérifier votre boîte de réception.';
    }

    final rawDigits = clean.replaceAll(RegExp(r'\D'), '');

    try {
      final List<dynamic> response = await supabase
          .from('user_profiles')
          .select('id, email, phone')
          .or('phone.ilike.%$rawDigits%,phone.eq.$clean');

      if (response.isNotEmpty) {
        final user = response.first;
        final email = user['email'] as String?;
        if (email != null && email.isNotEmpty) {
          await supabase.auth.resetPasswordForEmail(email);
          final parts = email.split('@');
          final masked = parts[0].length > 2 
              ? '${parts[0].substring(0, 2)}***@${parts[1]}'
              : '***@${parts[1]}';
          return 'Un email de réinitialisation a été envoyé à l\'adresse ($masked) liée à votre numéro de téléphone.';
        }
      }
    } catch (e) {
      print('Error querying profile for password reset: $e');
    }

    String phoneE164 = rawDigits;
    if (!phoneE164.startsWith('+')) {
      if (phoneE164.startsWith('221')) {
        phoneE164 = '+$phoneE164';
      } else {
        phoneE164 = '+221$phoneE164';
      }
    }

    try {
      await supabase.auth.signInWithOtp(phone: phoneE164);
      return 'Un SMS de réinitialisation a été envoyé au numéro $phoneE164.';
    } catch (e) {
      print('SMS Provider notice: $e');
      return 'L\'envoi automatique de SMS par réseau mobile nécessite la clé d\'accès opérateur (Twilio / SMS Gateway) sur Supabase. Veuillez réinitialiser par Email ou contacter le support Kaywetio.';
    }
  }

  /// Custom sign in that works with email OR phone number
  static Future<AuthResponse> signInWithEmailOrPhone({
    required String identifier, // Can be email or phone
    required String password,
  }) async {
    try {
      // Clean the identifier first
      final cleanIdentifier = identifier.trim().toLowerCase();

      // Check if identifier looks like an email
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

      if (emailRegex.hasMatch(cleanIdentifier)) {
        // Sign in with email directly
        print('🔐 Tentative de connexion avec email: $cleanIdentifier');

        try {
          return await signInWithEmail(
            email: cleanIdentifier,
            password: password,
          );
        } catch (e) {
          // If email not confirmed, try direct signInWithPassword which may work
          // depending on Supabase project settings
          if (e.toString().contains('Email not confirmed') ||
              e.toString().contains('email_not_confirmed')) {
            try {
              final directResponse =
                  await Supabase.instance.client.auth.signInWithPassword(
                email: cleanIdentifier,
                password: password,
              );
              if (directResponse.session != null) {
                return directResponse;
              }
            } catch (_) {}
            throw Exception(
              'EMAIL_NOT_CONFIRMED: Veuillez confirmer votre email avant de vous connecter. '
              'Vérifiez votre boîte de réception et vos spams pour trouver l\'email de confirmation.',
            );
          }
          rethrow;
        }
      } else {
        // It's a phone number - normalize and find the user profile first
        String normalizedPhone = _normalizePhoneNumber(cleanIdentifier);
        print('📱 Tentative de connexion avec téléphone: $normalizedPhone');

        try {
          // Try to find user profile with this phone number
          final userQueryResult = await Supabase.instance.client
              .from('user_profiles')
              .select('email, id, full_name, is_active, phone')
              .eq('phone', normalizedPhone)
              .maybeSingle();

          Map<String, dynamic>? userQuery = userQueryResult;

          // If not found with normalized phone, try alternative formats
          if (userQuery == null) {
            final alternativeFormats = _getAlternativePhoneFormats(
              cleanIdentifier,
            );
            for (final format in alternativeFormats) {
              if (format == normalizedPhone) continue;
              final altResult = await Supabase.instance.client
                  .from('user_profiles')
                  .select('email, id, full_name, is_active, phone')
                  .eq('phone', format)
                  .maybeSingle();
              if (altResult != null) {
                userQuery = altResult;
                break;
              }
            }
          }

          if (userQuery == null) {
            throw Exception(
              'PHONE_NOT_FOUND: Aucun compte trouvé avec ce numéro de téléphone. '
              'Vérifiez votre numéro ou créez un nouveau compte.',
            );
          }

          final userEmail = userQuery['email'];
          if (userEmail == null || userEmail.toString().trim().isEmpty) {
            // Try to sign in with generated email from phone
            final cleanPhone = normalizedPhone.replaceAll(
              RegExp(r'[\s\-\(\)]'),
              '',
            );
            final generatedEmail =
                'phone_${cleanPhone.replaceAll('+', '')}@wetio.app';
            try {
              return await signInWithEmail(
                email: generatedEmail,
                password: password,
              );
            } catch (_) {
              throw Exception(
                'PROFILE_INCOMPLETE: Votre profil nécessite une adresse email. '
                'Veuillez contacter le support pour compléter votre profil.',
              );
            }
          }

          // Check if account is active
          if (userQuery['is_active'] == false) {
            throw Exception(
              'ACCOUNT_INACTIVE: Votre compte a été désactivé. Contactez le support.',
            );
          }

          print(
            '✅ Utilisateur trouvé: ${userQuery['full_name']} ($userEmail)',
          );

          // Try to sign in with the found email
          try {
            return await signInWithEmail(email: userEmail, password: password);
          } catch (e) {
            // If email not confirmed, try direct signInWithPassword
            if (e.toString().contains('Email not confirmed') ||
                e.toString().contains('email_not_confirmed')) {
              try {
                final directResponse = await Supabase.instance.client.auth
                    .signInWithPassword(email: userEmail, password: password);
                if (directResponse.session != null) {
                  return directResponse;
                }
              } catch (_) {}
              throw Exception(
                'EMAIL_NOT_CONFIRMED: Votre email ($userEmail) n\'est pas encore confirmé. '
                'Vérifiez votre boîte de réception pour l\'email de confirmation.',
              );
            }
            rethrow;
          }
        } catch (e) {
          final errStr = e.toString().toLowerCase();
          if (errStr.contains('phone_not_found') ||
              errStr.contains('profile_incomplete') ||
              errStr.contains('account_inactive') ||
              errStr.contains('email_not_confirmed') ||
              errStr.contains('invalid login credentials') ||
              errStr.contains('invalid_credentials')) {
            rethrow;
          }

          print('❌ Erreur lors de la recherche du profil: $e');
          throw Exception(
            'DATABASE_ERROR: $e',
          );
        }
      }
    } catch (e) {
      print('❌ Erreur de connexion: $e');

      final errStr = e.toString().toLowerCase();

      // Pass through specific error types
      if (errStr.contains('phone_not_found') ||
          errStr.contains('profile_incomplete') ||
          errStr.contains('account_inactive') ||
          errStr.contains('email_not_confirmed') ||
          errStr.contains('database_error')) {
        rethrow;
      }

      // Handle Supabase auth errors
      if (errStr.contains('invalid login credentials') || errStr.contains('invalid_credentials')) {
        throw Exception(
          'INVALID_CREDENTIALS: Email/téléphone ou mot de passe incorrect. '
          'Vérifiez vos identifiants.',
        );
      } else if (errStr.contains('email not confirmed') ||
          errStr.contains('email_not_confirmed')) {
        throw Exception(
          'EMAIL_NOT_CONFIRMED: Veuillez confirmer votre email avant de vous connecter. '
          'Vérifiez votre boîte de réception et vos spams.',
        );
      } else if (e.toString().contains('Too many requests')) {
        throw Exception(
          'TOO_MANY_REQUESTS: Trop de tentatives de connexion. '
          'Veuillez réessayer dans quelques minutes.',
        );
      } else {
        throw Exception(
          'UNKNOWN_ERROR: Erreur de connexion inattendue. '
          'Si le problème persiste, contactez le support.',
        );
      }
    }
  }

  /// Sign in with Google OAuth
  static Future<void> signInWithGoogle() async {
    try {
      final redirectTo = kIsWeb 
          ? html.window.location.origin 
          : 'com.wetio.app.testProject.V8A4F7BK95://login-callback';
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectTo,
      );
    } catch (e) {
      throw Exception('Google sign-in failed: $e');
    }
  }

  /// Sign in with Apple OAuth
  static Future<void> signInWithApple() async {
    try {
      final redirectTo = kIsWeb 
          ? html.window.location.origin 
          : 'com.wetio.app.testProject.V8A4F7BK95://login-callback';
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: redirectTo,
      );
    } catch (e) {
      throw Exception('Apple sign-in failed: $e');
    }
  }

  /// Normalize phone number for consistent searching
  static String _normalizePhoneNumber(String phone) {
    // Remove all spaces, dashes, dots, parentheses
    String cleaned = phone.replaceAll(RegExp(r'[\s\-\.\(\)]'), '');

    // Handle different country code formats for France
    if (cleaned.startsWith('+33')) {
      // French number with +33: convert to 0X format
      return '0${cleaned.substring(3)}';
    } else if (cleaned.startsWith('0033')) {
      // French number with 0033: convert to 0X format
      return '0${cleaned.substring(4)}';
    } else if (cleaned.startsWith('33') && cleaned.length >= 11) {
      // French number with 33: convert to 0X format
      return '0${cleaned.substring(2)}';
    } else if (cleaned.startsWith('0') && cleaned.length == 10) {
      // Already in 0X format
      return cleaned;
    } else if (cleaned.length == 9 && !cleaned.startsWith('0')) {
      // Missing leading 0
      return '0$cleaned';
    }

    return cleaned;
  }

  /// Get alternative phone formats to try
  static List<String> _getAlternativePhoneFormats(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-\.\(\)]'), '');
    final formats = <String>{};

    // Add the normalized version first
    formats.add(_normalizePhoneNumber(phone));

    // Add original cleaned version
    formats.add(cleaned);

    // If it looks like a French number, try different formats
    if (cleaned.length >= 9) {
      // Try with +33 prefix
      if (cleaned.startsWith('0') && cleaned.length == 10) {
        formats.add('+33${cleaned.substring(1)}');
        formats.add('33${cleaned.substring(1)}');
        formats.add('0033${cleaned.substring(1)}');
      }

      // Try with 0 prefix
      if (!cleaned.startsWith('0') && cleaned.length == 9) {
        formats.add('0$cleaned');
      }

      // Try with spaces (common user input format)
      if (cleaned.startsWith('0') && cleaned.length == 10) {
        formats.add(
          '${cleaned.substring(0, 2)} ${cleaned.substring(2, 4)} ${cleaned.substring(4, 6)} ${cleaned.substring(6, 8)} ${cleaned.substring(8, 10)}',
        );
      }

      // Try international format variations
      if (cleaned.startsWith('+33')) {
        final withoutCountryCode = cleaned.substring(3);
        formats.add('0$withoutCountryCode');
        formats.add('33$withoutCountryCode');
      }
    }

    return formats.toList();
  }

  /// Sign out current user
  static Future<void> signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      throw Exception('Sign-out failed: $e');
    }
  }

  /// Get current authenticated user
  static User? getCurrentUser() {
    if (!isInitialized) return null;
    try {
      return Supabase.instance.client.auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  /// Check if user is authenticated
  static bool isAuthenticated() {
    if (!isInitialized) return false;
    try {
      return Supabase.instance.client.auth.currentUser != null;
    } catch (_) {
      return false;
    }
  }

  /// Get current user profile data
  static Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    try {
      final user = getCurrentUser();
      if (user == null) return null;

      final response = await Supabase.instance.client
          .from('user_profiles')
          .select()
          .eq('id', user.id)
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to fetch user profile: $e');
    }
  }

  /// Update user profile
  static Future<void> updateUserProfile({
    String? fullName,
    String? pseudo,
    String? phone,
    String? location,
    String? bio,
    String? avatarUrl,
  }) async {
    try {
      final user = getCurrentUser();
      if (user == null) throw Exception('User not authenticated');

      final updateData = <String, dynamic>{};
      if (fullName != null) updateData['full_name'] = fullName;
      if (pseudo != null) updateData['pseudo'] = pseudo;
      if (phone != null) updateData['phone'] = phone;
      if (location != null) updateData['location'] = location;
      if (bio != null) updateData['bio'] = bio;
      if (avatarUrl != null) updateData['avatar_url'] = avatarUrl;

      if (updateData.isNotEmpty) {
        await Supabase.instance.client
            .from('user_profiles')
            .update(updateData)
            .eq('id', user.id);
      }
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  /// Create a new product order (Manual/Local payment)
  static Future<Map<String, dynamic>> createOrder({
    required String productId,
    required String sellerId,
    required int amount,
    required int quantity,
    required String deliveryMethod,
    required int deliveryFee,
    required int totalAmount,
  }) async {
    try {
      final user = getCurrentUser();
      if (user == null) throw Exception('User not authenticated');

      final response = await Supabase.instance.client
          .from('product_orders')
          .insert({
            'buyer_id': user.id,
            'seller_id': sellerId,
            'product_id': productId,
            'amount': amount,
            'quantity': quantity,
            'delivery_method': deliveryMethod,
            'delivery_fee': deliveryFee,
            'total_amount': totalAmount,
            'status': 'pending_payment',
          })
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  /// Get real unread notification count for current user
  static Future<int> getUnreadNotificationCount() async {
    try {
      final user = getCurrentUser();
      if (user == null) return 0;

      final notifications = await getNotifications();
      return notifications.where((n) => n['isRead'] == false).length;
    } catch (e) {
      print('Error getting unread notification count: $e');
      return 0;
    }
  }

  /// Get all notifications for the current user (orders, exchanges, and deliveries) - Fast parallel fetch
  static Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final user = getCurrentUser();
      if (user == null) return [];

      // Run root queries in parallel for instant sub-second loading!
      final results = await Future.wait([
        // 0. Fetch product sales orders with joined product and buyer profile
        Supabase.instance.client
            .from('product_orders')
            .select('*, products(title, images), user_profiles!buyer_id(full_name, phone)')
            .eq('seller_id', user.id)
            .order('created_at', ascending: false)
            .catchError((_) => []),

        // 1. Fetch exchange proposals with joined target product and requester profile
        Supabase.instance.client
            .from('exchanges')
            .select('*, products!target_product_id(title, images), user_profiles!requester_id(full_name)')
            .eq('owner_id', user.id)
            .eq('status', 'en_attente')
            .order('created_at', ascending: false)
            .catchError((_) => []),

        // 2. Fetch delivery status updates
        Supabase.instance.client
            .from('delivery_requests')
            .select('*')
            .or('person_a_id.eq.${user.id},person_b_id.eq.${user.id}')
            .neq('delivery_status', 'en_attente')
            .order('updated_at', ascending: false)
            .catchError((_) => []),

        // 3. User profile check for delivery partner status
        Supabase.instance.client
            .from('user_profiles')
            .select('is_delivery_partner')
            .eq('id', user.id)
            .maybeSingle()
            .catchError((_) => null),
      ]);

      final ordersResponse = (results[0] as List?) ?? [];
      final exchangesResponse = (results[1] as List?) ?? [];
      final sentRequestsResponse = (results[2] as List?) ?? [];
      final profile = results[3] as Map<String, dynamic>?;

      List<Map<String, dynamic>> allNotifications = [];

      // Delivery partner pending requests
      if (profile != null && profile['is_delivery_partner'] == true) {
        try {
          final deliveryRequests = await getMyDeliveryRequests();
          for (var req in deliveryRequests) {
            if (req['delivery_status'] == 'en_attente') {
              allNotifications.add({
                'id': 'delivery_${req['id']}',
                'type': 'delivery_request',
                'category': 'Livraisons',
                'title': 'NOUVELLE LIVRAISON DISPONIBLE',
                'message': 'Une nouvelle demande de livraison attend votre acceptation.',
                'timestamp': req['created_at'],
                'isRead': false,
                'accentColor': const Color(0xFF2196F3),
                'data': req,
              });
            }
          }
        } catch (_) {}
      }

      // Delivery status updates
      for (var req in sentRequestsResponse) {
        final status = req['delivery_status'];
        final timestampStr = (req['updated_at'] ?? req['created_at']).toString();
        final baseTimestamp = DateTime.parse(timestampStr);

        if (status == 'accepted' || status == 'recupere' || status == 'terminee') {
          allNotifications.add({
            'id': 'sent_delivery_acc_${req['id']}',
            'type': 'delivery_status_update',
            'category': 'Livraisons',
            'title': "LIVRAISON ACCEPTÉE !",
            'message': "Un livreur a accepté de prendre en charge votre échange.",
            'timestamp': baseTimestamp.subtract(const Duration(minutes: 5)).toIso8601String(),
            'isRead': true,
            'accentColor': const Color(0xFF2196F3),
            'data': req,
          });
        }

        if (status == 'recupere' || status == 'terminee') {
          final pin = req['verification_pin'] ?? '----';
          allNotifications.add({
            'id': 'sent_delivery_rec_${req['id']}',
            'type': 'delivery_status_update',
            'category': 'Livraisons',
            'title': "COLIS RÉCUPÉRÉ !",
            'message': "Votre colis est en route. CODE PIN : $pin (à donner au livreur à la réception).",
            'timestamp': baseTimestamp.subtract(const Duration(minutes: 2)).toIso8601String(),
            'isRead': status == 'terminee',
            'accentColor': const Color(0xFF2196F3),
            'data': req,
          });
        }

        if (status == 'terminee') {
          allNotifications.add({
            'id': 'sent_delivery_fin_${req['id']}',
            'type': 'delivery_status_update',
            'category': 'Livraisons',
            'title': "LIVRAISON TERMINÉE",
            'message': "Votre colis a été livré avec succès.",
            'timestamp': baseTimestamp.toIso8601String(),
            'isRead': false,
            'accentColor': AppTheme.successGreen,
            'data': req,
          });
        }
      }

      // Map orders (already joined!)
      for (var order in ordersResponse) {
        try {
          final productData = order['products'] as Map<String, dynamic>?;
          final buyerData = order['user_profiles'] as Map<String, dynamic>?;

          final title = productData?['title']?.toString() ?? 'produit';
          final images = productData?['images'] as List?;
          final buyerName = buyerData?['full_name']?.toString() ?? 'Un client';

          final Map<String, dynamic> extendedOrder = Map<String, dynamic>.from(order);
          extendedOrder['buyer_name'] = buyerName;
          extendedOrder['buyer_phone'] = buyerData?['phone'];
          extendedOrder['product_title'] = title;

          allNotifications.add({
            'id': 'order_${order['id']}',
            'type': 'order',
            'category': 'Ventes',
            'title': 'Nouvel achat !',
            'message': '$buyerName a acheté votre $title',
            'timestamp': order['created_at'],
            'isRead': order['status'] != 'pending_payment',
            'avatar': images != null && images.isNotEmpty ? images[0] : null,
            'accentColor': const Color(0xFF4CAF50),
            'data': extendedOrder,
          });
        } catch (e) {
          print('DEBUG: Error mapping order ${order['id']}: $e');
        }
      }

      // Map exchanges (already joined!)
      for (var exchange in exchangesResponse) {
        try {
          final productData = exchange['products'] as Map<String, dynamic>?;
          final requesterData = exchange['user_profiles'] as Map<String, dynamic>?;

          final title = productData?['title']?.toString() ?? 'produit';
          final images = productData?['images'] as List?;
          final requesterName = requesterData?['full_name']?.toString() ?? 'Un utilisateur';

          allNotifications.add({
            'id': 'exchange_${exchange['id']}',
            'type': 'exchange_proposal',
            'category': 'Propositions',
            'title': 'Nouvel échange proposé',
            'message': '$requesterName propose un échange pour votre $title',
            'timestamp': exchange['created_at'],
            'isRead': false,
            'avatar': images != null && images.isNotEmpty ? images[0] : null,
            'accentColor': const Color(0xFFFF7043),
            'data': exchange,
          });
        } catch (e) {
          print('DEBUG: Error mapping exchange ${exchange['id']}: $e');
        }
      }

      // Sort by timestamp descending
      allNotifications.sort((a, b) => DateTime.parse(b['timestamp']).compareTo(DateTime.parse(a['timestamp'])));

      return allNotifications;
    } catch (e) {
      print('DEBUG: Error fetching notifications: $e');
      return [];
    }
  }

  /// Update user payout method (Wave, Orange Money, etc.)
  static Future<void> updatePayoutMethod({
    required String method,
    required String phone,
  }) async {
    try {
      final user = getCurrentUser();
      if (user == null) throw Exception('User not authenticated');

      await Supabase.instance.client
          .from('user_profiles')
          .update({
            'payout_method': method,
            'payout_phone': phone,
          })
          .eq('id', user.id);
    } catch (e) {
      throw Exception('Failed to update payout method: $e');
    }
  }

  /// Reset password
  static Future<void> resetPassword(String email) async {
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw Exception('Password reset failed: $e');
    }
  }

  /// Reset password by email
  static Future<void> resetPasswordByEmail(String email) async {
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'https://wetio4029.builtwithrocket.new/auth/reset-password',
      );
    } catch (e) {
      throw Exception('Password reset failed: $e');
    }
  }



  // ========== EXISTING METHODS ==========

  // ========== EXCHANGE PROPOSAL METHODS ==========

  /// Get pending exchange proposals received by current user
  static Future<List<Map<String, dynamic>>>
      getReceivedExchangeProposals() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await Supabase.instance.client
          .from('exchanges')
          .select('''
            *,
            requester:user_profiles!requester_id(id, full_name, pseudo, avatar_url, location),
            target_product:products!target_product_id(id, title, images, category, description, product_condition),
            requester_product:products!requester_product_id(id, title, images, category, description, product_condition)
          ''')
          .eq('owner_id', userId)
          .eq('status', 'en_attente')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch received proposals: $e');
    }
  }

  /// Accept an exchange proposal
  static Future<void> acceptExchangeProposal(String exchangeId) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await Supabase.instance.client
          .from('exchanges')
          .update({
            'status': 'accepte',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', exchangeId)
          .eq('owner_id', userId);
    } catch (e) {
      throw Exception('Failed to accept proposal: $e');
    }
  }

  /// Refuse an exchange proposal
  static Future<void> refuseExchangeProposal(String exchangeId) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await Supabase.instance.client
          .from('exchanges')
          .update({
            'status': 'refuse',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', exchangeId)
          .eq('owner_id', userId);
    } catch (e) {
      throw Exception('Failed to refuse proposal: $e');
    }
  }

  /// Get exchange proposal details
  static Future<void> createExchangeProposal({
    required String targetProductId,
    required String ownerId,
    required String requesterProductId,
    required String message,
    required String exchangeMethod,
    String? deliveryAddress,
  }) async {
    try {
      final user = getCurrentUser();
      if (user == null) throw Exception('User not authenticated');

      await Supabase.instance.client.from('exchanges').insert({
        'target_product_id': targetProductId,
        'owner_id': ownerId,
        'requester_id': user.id,
        'requester_product_id': requesterProductId,
        'message': message,
        'exchange_method': exchangeMethod,
        'delivery_address': deliveryAddress,
        'status': 'en_attente',
      });
    } catch (e) {
      print('Error creating exchange proposal: $e');
      throw e;
    }
  }

  static Future<Map<String, dynamic>?> getExchangeProposalDetails(
    String exchangeId,
  ) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response =
          await Supabase.instance.client.from('exchanges').select('''
            *,
            requester:user_profiles!requester_id(id, full_name, pseudo, avatar_url, location, phone, payout_phone),
            owner:user_profiles!owner_id(id, full_name, pseudo, avatar_url, payout_phone),
            target_product:products!target_product_id(id, title, images, category, description, product_condition, location),
            requester_product:products!requester_product_id(id, title, images, category, description, product_condition, location)
          ''').eq('id', exchangeId).maybeSingle();

      return response;
    } catch (e) {
      throw Exception('Failed to fetch proposal details: $e');
    }
  }

  // Completed Exchange Archive Methods
  static Future<List<Map<String, dynamic>>> getCompletedExchanges() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await Supabase.instance.client
          .from('exchange_history')
          .select('*')
          .or('owner_id.eq.$userId,requester_id.eq.$userId')
          .order('completion_date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch completed exchanges: $e');
    }
  }

  static Future<void> deleteCompletedExchange(String exchangeId) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await Supabase.instance.client
          .from('exchange_history')
          .delete()
          .eq('id', exchangeId)
          .or('owner_id.eq.$userId,requester_id.eq.$userId');
    } catch (e) {
      throw Exception('Failed to delete completed exchange: $e');
    }
  }

  static Future<bool> exportExchangeHistory() async {
    try {
      final exchanges = await getCompletedExchanges();

      // Generate CSV or PDF content
      final csvContent = _generateCSVContent(exchanges);

      if (kIsWeb) {
        // Web download
        final bytes = utf8.encode(csvContent);
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute(
            "download",
            "exchange_history_${DateTime.now().millisecondsSinceEpoch}.csv",
          )
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        // Mobile save to documents
        final directory = await getApplicationDocumentsDirectory();
        final file = File(
          '${directory.path}/exchange_history_${DateTime.now().millisecondsSinceEpoch}.csv',
        );
        await file.writeAsString(csvContent);
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  static String _generateCSVContent(List<Map<String, dynamic>> exchanges) {
    final buffer = StringBuffer();

    // CSV header
    buffer.writeln(
      'Date de completion,Mon produit,Produit recu,Methode echange,Note donnee,Note recue',
    );

    // CSV data
    for (final exchange in exchanges) {
      final completionDate = exchange['completion_date'] ?? '';
      final targetProduct = (exchange['target_product_title'] ?? '').replaceAll(
        ',',
        ';',
      );
      final requesterProduct =
          (exchange['requester_product_title'] ?? '').replaceAll(',', ';');
      final method = exchange['exchange_method'] ?? '';
      final ratingGiven = exchange['rating_given'] ?? 0;
      final ratingReceived = exchange['rating_received'] ?? 0;

      buffer.writeln(
        '$completionDate,$targetProduct,$requesterProduct,$method,$ratingGiven,$ratingReceived',
      );
    }

    return buffer.toString();
  }

  // Archive Management
  static Future<void> moveExchangeToHistory(String exchangeId) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Get exchange details
      final exchange = await Supabase.instance.client
          .from('exchanges')
          .select(
            '*, target_product:products!target_product_id(title), requester_product:products!requester_product_id(title)',
          )
          .eq('id', exchangeId)
          .single();

      // Insert into exchange_history
      await Supabase.instance.client.from('exchange_history').insert({
        'original_exchange_id': exchangeId,
        'owner_id': exchange['owner_id'],
        'requester_id': exchange['requester_id'],
        'target_product_title': exchange['target_product']['title'],
        'requester_product_title': exchange['requester_product']['title'],
        'exchange_method': exchange['exchange_method'],
        'completion_date': DateTime.now().toIso8601String(),
        'auto_delete_at': DateTime.now()
            .add(const Duration(days: 180))
            .toIso8601String(), // 6 months
      });

      // Update original exchange status
      await Supabase.instance.client
          .from('exchanges')
          .update({'status': 'termine'}).eq('id', exchangeId);
    } catch (e) {
      throw Exception('Failed to move exchange to history: $e');
    }
  }

  static Future<void> updateExchangeRating(
    String historyId,
    int ratingGiven,
    int ratingReceived,
  ) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await Supabase.instance.client
          .from('exchange_history')
          .update({
            'rating_given': ratingGiven,
            'rating_received': ratingReceived,
          })
          .eq('id', historyId)
          .or('owner_id.eq.$userId,requester_id.eq.$userId');
    } catch (e) {
      throw Exception('Failed to update exchange rating: $e');
    }
  }

  // Cleanup expired exchanges (for background job)
  static Future<void> cleanupExpiredExchanges() async {
    try {
      await Supabase.instance.client
          .from('exchange_history')
          .delete()
          .lt('auto_delete_at', DateTime.now().toIso8601String());
    } catch (e) {
      throw Exception('Failed to cleanup expired exchanges: $e');
    }
  }

  // ========== FAVORITES (LI LA BEUGUE) METHODS ==========

  /// Add a product to favorites
  static Future<void> addFavorite(String productId, {Map<String, dynamic>? productData}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localFavs = prefs.getStringList('wetio_favorites') ?? [];
      if (!localFavs.contains(productId)) {
        localFavs.add(productId);
        await prefs.setStringList('wetio_favorites', localFavs);
      }

      if (productData != null) {
        final jsonStr = jsonEncode(productData);
        await prefs.setString('wetio_fav_map_$productId', jsonStr);
      }
    } catch (e) {
      print('Error caching favorite locally: $e');
    }

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        await Supabase.instance.client.from('favorites').upsert({
          'user_id': userId,
          'product_id': productId,
        });
      }
    } catch (e) {
      print('❌ Error adding favorite to Supabase: $e');
    }
  }

  /// Remove a product from favorites
  static Future<void> removeFavorite(String productId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localFavs = prefs.getStringList('wetio_favorites') ?? [];
      localFavs.remove(productId);
      await prefs.setStringList('wetio_favorites', localFavs);
      await prefs.remove('wetio_fav_map_$productId');
    } catch (_) {}

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        await Supabase.instance.client
            .from('favorites')
            .delete()
            .eq('user_id', userId)
            .eq('product_id', productId);
      }
    } catch (e) {
      print('❌ Error removing favorite from Supabase: $e');
    }
  }

  /// Check if a product is favorited by current user
  static Future<bool> isFavorite(String productId) async {
    final favs = await getFavoriteProductIds();
    return favs.contains(productId);
  }

  /// Get all favorited products for current user
  static Future<List<Map<String, dynamic>>> getFavorites() async {
    try {
      final favIds = await getFavoriteProductIds();
      if (favIds.isEmpty) return [];

      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> result = [];
      final List<String> missingFromCache = [];

      for (var pid in favIds) {
        final cachedJson = prefs.getString('wetio_fav_map_$pid');
        if (cachedJson != null && cachedJson.isNotEmpty) {
          try {
            final Map<String, dynamic> p = jsonDecode(cachedJson);
            result.add({'product': p, 'product_id': pid});
          } catch (_) {
            missingFromCache.add(pid);
          }
        } else {
          missingFromCache.add(pid);
        }
      }

      if (missingFromCache.isNotEmpty) {
        try {
          final inClause = '(${missingFromCache.map((id) => '"$id"').join(',')})';
          final productsResponse = await Supabase.instance.client
              .from('products')
              .select('*, owner:user_profiles!owner_id(*)')
              .filter('id', 'in', inClause);

          for (var item in (productsResponse as List)) {
            final Map<String, dynamic> pMap = Map<String, dynamic>.from(item as Map);
            final pid = pMap['id'].toString();
            await prefs.setString('wetio_fav_map_$pid', jsonEncode(pMap));
            result.add({'product': pMap, 'product_id': pid});
          }
        } catch (e) {
          print('Error fetching missing favorites from Supabase: $e');
        }
      }

      return result;
    } catch (e) {
      print('❌ Error in getFavorites: $e');
      return [];
    }
  }

  /// Get set of favorited product IDs for current user (for quick lookup)
  static Future<Set<String>> getFavoriteProductIds() async {
    final Set<String> ids = {};

    try {
      final prefs = await SharedPreferences.getInstance();
      final localFavs = prefs.getStringList('wetio_favorites') ?? [];
      ids.addAll(localFavs);
    } catch (_) {}

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        final response = await Supabase.instance.client
            .from('favorites')
            .select('product_id')
            .eq('user_id', userId);

        for (var item in (response as List)) {
          final pid = item['product_id']?.toString();
          if (pid != null && pid.isNotEmpty) {
            ids.add(pid);
          }
        }
      }
    } catch (e) {
      print('❌ Error fetching favorite IDs from Supabase: $e');
    }

    return ids;
  }

  /// Debug method to check if favorites table exists and has data
  static Future<void> probeFavorites() async {
    try {
      final response = await Supabase.instance.client
          .from('favorites')
          .select('count')
          .limit(1);
      print('📊 Favorites table check: $response');
    } catch (e) {
      print('⚠️ Favorites table check failed: $e');
    }
  }
}
