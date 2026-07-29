import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import './supabase_service.dart';

class TokenService {
  static TokenService? _instance;
  static TokenService get instance => _instance ??= TokenService._();
  TokenService._();

  final Dio _dio = Dio();
  final String _baseUrl =
      '${String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://zjcnggoxjyonahoiansk.supabase.co')}/functions/v1';

  /// Get current user token balance with improved null safety
  Future<int> getCurrentTokenBalance() async {
    try {
      final client = SupabaseService.instance.client;
      final user = client.auth.currentUser;

      if (user?.id == null) {
        throw Exception('Utilisateur non connecté');
      }

      final response = await client
          .from('user_profiles')
          .select('tokens')
          .eq('id', user!.id)
          .maybeSingle();

      // Better null handling with explicit checks
      if (response == null) {
        if (kDebugMode) {
          print('No user profile found for user ${user.id}');
        }
        return 0;
      }

      final tokens = response['tokens'];
      if (tokens == null) {
        if (kDebugMode) {
          print('Tokens field is null for user ${user.id}');
        }
        return 0;
      }

      // Ensure we return a valid integer
      if (tokens is int) {
        return tokens;
      } else if (tokens is num) {
        return tokens.toInt();
      } else {
        if (kDebugMode) {
          print(
            'Invalid token type: ${tokens.runtimeType} for user ${user.id}',
          );
        }
        return 0;
      }
    } catch (error) {
      if (kDebugMode) {
        print('Error getting token balance: $error');
      }

      // Return default value instead of throwing to prevent UI crashes
      return 0;
    }
  }

  /// Check if user can publish a product with better error handling
  Future<Map<String, dynamic>> canUserPublishProduct({
    int requiredTokens = 10,
  }) async {
    try {
      final client = SupabaseService.instance.client;
      final user = client.auth.currentUser;

      if (user?.id == null) {
        return {
          'success': false,
          'message': 'Utilisateur non connecté',
          'can_publish': false,
        };
      }

      final response = await client.rpc(
        'can_user_publish_product',
        params: {'user_uuid': user!.id, 'required_tokens': requiredTokens},
      );

      if (response == null) {
        return {
          'success': false,
          'message': 'Erreur lors de la vérification',
          'can_publish': false,
        };
      }

      return Map<String, dynamic>.from(response);
    } catch (error) {
      if (kDebugMode) {
        print('Error checking publication eligibility: $error');
      }

      return {
        'success': false,
        'message': 'Erreur lors de la vérification des jetons',
        'can_publish': false,
      };
    }
  }

  /// Deduct tokens for product publication with improved error handling
  Future<Map<String, dynamic>> deductTokensForPublication({
    required String productTitle,
    int tokensToDeduct = 10,
  }) async {
    try {
      final client = SupabaseService.instance.client;
      final user = client.auth.currentUser;

      if (user?.id == null) {
        return {'success': false, 'message': 'Utilisateur non connecté'};
      }

      // Ensure productTitle is not null or empty
      final safeProductTitle =
          productTitle.trim().isEmpty ? 'Produit sans titre' : productTitle;

      final response = await client.rpc(
        'deduct_tokens_for_publication',
        params: {
          'user_uuid': user!.id,
          'product_title': safeProductTitle,
          'tokens_to_deduct': tokensToDeduct,
        },
      );

      if (response == null) {
        return {
          'success': false,
          'message': 'Erreur lors de la déduction des jetons',
        };
      }

      return Map<String, dynamic>.from(response);
    } catch (error) {
      if (kDebugMode) {
        print('Error deducting tokens: $error');
      }

      return {
        'success': false,
        'message':
            'Erreur lors de la déduction des jetons: ${error.toString()}',
      };
    }
  }

  /// Get user token transaction history with better null safety
  Future<List<Map<String, dynamic>>> getTokenHistory({int limit = 20}) async {
    try {
      final client = SupabaseService.instance.client;
      final user = client.auth.currentUser;

      if (user?.id == null) {
        if (kDebugMode) {
          print('User not connected for token history');
        }
        return [];
      }

      final response = await client.rpc(
        'get_user_token_history',
        params: {'user_uuid': user!.id, 'limit_count': limit},
      );

      if (response == null) {
        if (kDebugMode) {
          print('No token history response for user ${user.id}');
        }
        return [];
      }

      if (response is List) {
        return response
            .whereType<Map<String, dynamic>>()
            .where((item) => item.isNotEmpty)
            .toList();
      }

      if (kDebugMode) {
        print('Invalid token history response type: ${response.runtimeType}');
      }
      return [];
    } catch (error) {
      if (kDebugMode) {
        print('Error getting token history: $error');
      }

      // Return empty list instead of throwing to prevent UI crashes
      return [];
    }
  }

  /// Create payment intent for token purchase with enhanced error handling
  Future<Map<String, dynamic>> createTokenPurchaseIntent({
    int tokensToPurchase = 100,
    int amountFcfa = 1000,
    String paymentMethod = 'stripe',
  }) async {
    try {
      final client = SupabaseService.instance.client;
      final user = client.auth.currentUser;
      final session = client.auth.currentSession;

      if (user?.id == null || session?.accessToken == null) {
        return {
          'success': false,
          'error': 'Utilisateur non connecté ou session expirée',
        };
      }

      final response = await _dio.post(
        '$_baseUrl/purchase-tokens',
        data: {
          'tokens_to_purchase': tokensToPurchase,
          'amount_fcfa': amountFcfa,
          'payment_method': paymentMethod,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer ${session!.accessToken}',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        return Map<String, dynamic>.from(response.data);
      } else {
        return {
          'success': false,
          'error':
              'Échec de la création du paiement: ${response.statusMessage ?? 'Erreur inconnue'}',
        };
      }
    } on DioException catch (e) {
      String errorMessage = 'Erreur réseau';

      if (e.response?.data != null) {
        final responseData = e.response!.data;
        if (responseData is Map && responseData['error'] != null) {
          errorMessage = 'Erreur de paiement: ${responseData['error']}';
        } else {
          errorMessage =
              'Erreur serveur: ${e.response?.statusMessage ?? 'Erreur inconnue'}';
        }
      } else if (e.message?.contains('SocketException') == true) {
        errorMessage = 'Pas de connexion internet. Vérifiez votre réseau.';
      }

      return {'success': false, 'error': errorMessage};
    } catch (error) {
      return {
        'success': false,
        'error': 'Erreur inattendue: ${error.toString()}',
      };
    }
  }

  /// Confirm token purchase after successful payment with enhanced error handling
  Future<Map<String, dynamic>> confirmTokenPurchase(
    String? paymentIntentId,
  ) async {
    try {
      if (paymentIntentId?.trim().isEmpty != false) {
        return {'success': false, 'error': 'ID de paiement invalide'};
      }

      final client = SupabaseService.instance.client;
      final user = client.auth.currentUser;
      final session = client.auth.currentSession;

      if (user?.id == null || session?.accessToken == null) {
        return {
          'success': false,
          'error': 'Utilisateur non connecté ou session expirée',
        };
      }

      final response = await _dio.post(
        '$_baseUrl/confirm-token-purchase',
        data: {'payment_intent_id': paymentIntentId!.trim()},
        options: Options(
          headers: {
            'Authorization': 'Bearer ${session!.accessToken}',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        return Map<String, dynamic>.from(response.data);
      } else {
        return {
          'success': false,
          'error':
              'Échec de la confirmation du paiement: ${response.statusMessage ?? 'Erreur inconnue'}',
        };
      }
    } on DioException catch (e) {
      String errorMessage = 'Erreur réseau';

      if (e.response?.data != null) {
        final responseData = e.response!.data;
        if (responseData is Map && responseData['error'] != null) {
          errorMessage = 'Erreur de confirmation: ${responseData['error']}';
        }
      }

      return {'success': false, 'error': errorMessage};
    } catch (error) {
      return {
        'success': false,
        'error': 'Erreur inattendue: ${error.toString()}',
      };
    }
  }

  /// Get token balance color based on amount
  static TokenBalanceColor getBalanceColor(int tokens) {
    if (tokens >= 30) {
      return TokenBalanceColor.green;
    } else if (tokens >= 10) {
      return TokenBalanceColor.orange;
    } else {
      return TokenBalanceColor.red;
    }
  }

  /// Get balance status message
  static String getBalanceStatusMessage(int balance) {
    if (balance >= 30) {
      return 'Vous pouvez publier ${balance ~/ 10} produits';
    } else if (balance >= 10) {
      return 'Il vous reste ${balance ~/ 10} publication(s)';
    } else if (balance > 0) {
      return 'Jetons insuffisants pour publier (minimum 10)';
    } else {
      return 'Achetez des jetons pour publier vos produits';
    }
  }
}

enum TokenBalanceColor { green, orange, red }

/// Token transaction model with enhanced null safety
class TokenTransaction {
  final String id;
  final String transactionType;
  final int amount;
  final String description;
  final String? referenceId;
  final int balanceAfter;
  final DateTime createdAt;

  TokenTransaction({
    required this.id,
    required this.transactionType,
    required this.amount,
    required this.description,
    this.referenceId,
    required this.balanceAfter,
    required this.createdAt,
  });

  factory TokenTransaction.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      throw ArgumentError('TokenTransaction data cannot be null');
    }

    return TokenTransaction(
      id: json['id']?.toString() ?? '',
      transactionType: json['transaction_type']?.toString() ?? 'unknown',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      description: json['description']?.toString() ?? 'Aucune description',
      referenceId: json['reference_id']?.toString(),
      balanceAfter: (json['balance_after'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  bool get isDebit => amount < 0;
  bool get isCredit => amount > 0;

  String get formattedAmount {
    if (isDebit) {
      return '${amount.abs()} jetons déduits';
    } else {
      return '+$amount jetons ajoutés';
    }
  }
}
