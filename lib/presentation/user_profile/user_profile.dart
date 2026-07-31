import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../routes/app_routes.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import '../token_balance_widget/token_balance_widget.dart';
import '../admin_panel/admin_panel.dart';
import './widgets/available_product_card.dart';
import './widgets/empty_state_widget.dart';
import './widgets/favorites_tab_widget.dart';
import './widgets/product_tab_bar.dart';
import './widgets/user_profile_header.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({Key? key}) : super(key: key);

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with TickerProviderStateMixin {
  int _currentTabIndex = 0;
  bool _isRefreshing = false;
  final ImagePicker _imagePicker = ImagePicker();
  bool isLoading = true;

  // User data from Supabase
  Map<String, dynamic> _userData = {};

  // Real products from Supabase
  List<Map<String, dynamic>> _availableProducts = [];
  List<Map<String, dynamic>> _wantedProducts = [];

  // Mock completed exchanges data
  final List<Map<String, dynamic>> _completedExchanges = [
    {
      "id": "c28ef1c8-23bb-4930-a4f0-488d81cec43f",
      "target_product_title": "Casque audio Bluetooth",
      "requester_product_title": "Montre connectée",
      "exchange_method": "livraison",
      "completion_date": "2025-09-29T04:10:21.820319+00:00",
      "rating_given": 5,
      "rating_received": 4,
      "auto_delete_at": "2026-03-29T04:10:21.820319+00:00",
    },
    {
      "id": "b64bc011-f99c-4f8c-897f-8e33081cc4e5",
      "target_product_title": "Livre de philosophie",
      "requester_product_title": "Appareil photo vintage",
      "exchange_method": "direct",
      "completion_date": "2025-08-15T14:30:00.000000+00:00",
      "rating_given": 4,
      "rating_received": 5,
      "auto_delete_at": "2026-02-15T14:30:00.000000+00:00",
    },
  ];

  late TabController _tabController;
  int selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProfileData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload profile data when returning from edit screen
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => isLoading = true);

    try {
      final profile = await SupabaseService.getCurrentUserProfile();

      if (profile != null && mounted) {
        setState(() {
          _userData = {
            'id': profile['id'],
            'name': profile['full_name'] ?? 'Utilisateur',
            'location': profile['location'] ?? '',
            'avatar': profile['avatar_url'],
            'rating': (profile['rating'] != null) ? (profile['rating'] as num).toDouble() : 5.0,
            'reviewCount': profile['review_count'] ?? 0,
            'exchangeCount': profile['exchange_count'] ?? 0,
            'memberSince': _formatYear(profile['created_at']),
            'responseRate': 98,
            'pseudo': profile['pseudo'] ?? '',
            'phone': profile['phone'] ?? '',
            'bio': profile['bio'] ?? '',
            'payout_method': profile['payout_method'] ?? '',
            'payout_phone': profile['payout_phone'] ?? '',
            'is_delivery_partner': profile['is_delivery_partner'] ?? false,
          };
          isLoading = false;
        });
        // Load products after profile
        await _loadUserProducts(profile['id']);
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('❌ Erreur lors du chargement du profil: $e');
      setState(() => isLoading = false);
      _showErrorSnackBar('Erreur lors du chargement du profil');
    }
  }

  Future<void> _loadUserProducts(String userId) async {
    try {
      final supabase = Supabase.instance.client;

      // Load available products
      print('📦 Loading products for user: $userId');
      final availableResponse = await supabase
          .from('products')
          .select(
            'id, title, category, images, location, product_condition, created_at, is_active, price, owner:user_profiles!owner_id(*)',
          )
          .eq('owner_id', userId)
          .eq('product_type', 'disponible')
          .eq('is_active', true)
          .order('created_at', ascending: false);

      print('📦 Found ${availableResponse.length} available products');

      // Load wanted products
      final wantedResponse = await supabase
          .from('products')
          .select('id, title, category, description, created_at')
          .eq('owner_id', userId)
          .eq('product_type', 'recherche')
          .eq('is_active', true)
          .order('created_at', ascending: false);
      
      print('📦 Found ${wantedResponse.length} wanted products');

      if (mounted) {
        setState(() {
          if (availableResponse is List) {
            _availableProducts = availableResponse.map((item) {
              final images = item['images'] as List?;
              final rawPrice = item['price'] ?? item['Price'] ?? item['amount'] ?? item['montant'];
              
              return {
                'id': item['id'],
                'title': item['title'] ?? '',
                'category': item['category'] ?? 'Autres',
                'image': (images != null && images.isNotEmpty) ? images[0] : null,
                'images': images,
                'status': 'available',
                'location': item['location'] ?? 'Dakar',
                'datePosted': _formatDate(item['created_at']),
                'price': rawPrice,
                'owner': item['owner'],
                'userName': item['owner']?['full_name'] ?? item['owner']?['pseudo'] ?? 'Utilisateur',
              };
            }).toList();
          }

          if (wantedResponse is List) {
            _wantedProducts = wantedResponse.map((item) {
              return {
                'id': item['id'],
                'title': item['title'] ?? '',
                'category': item['category'] ?? 'Autres',
                'description': item['description'] ?? '',
                'urgency': 'medium',
                'location': 'Dakar',
                'datePosted': _formatDate(item['created_at']),
              };
            }).toList();
          }
        });
      }
    } catch (e) {
      print('❌ Erreur lors du chargement des produits: $e');
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Récemment';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inDays == 0) return "Aujourd'hui";
      if (diff.inDays == 1) return 'Hier';
      if (diff.inDays < 7) return 'Il y a ${diff.inDays} jours';
      return 'Il y a ${(diff.inDays / 7).floor()} semaine(s)';
    } catch (_) {
      return 'Récemment';
    }
  }

  Widget _buildPayoutMethodBanner() {
    final hasPayoutMethod =
        (_userData['payout_method'] as String?)?.isNotEmpty ?? false;
        
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () async {
          await Navigator.pushNamed(context, '/payout-methods');
          // Refresh profile after returning
          _loadProfileData();
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: hasPayoutMethod
                  ? [const Color(0xFF1A7F37), const Color(0xFF2DA44E)] // Green if configured
                  : [AppTheme.primaryGreen, const Color(0xFF635BFF)], // Primary blue if not
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14.0),
            boxShadow: [
              BoxShadow(
                color:
                    (hasPayoutMethod ? Colors.green : AppTheme.primaryGreen)
                        .withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(hasPayoutMethod ? 4 : 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: hasPayoutMethod
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.asset(
                          _userData['payout_method'] == 'Wave'
                              ? 'assets/images/wave_logo.webp'
                              : (_userData['payout_method'] == 'FreeMoney' || _userData['payout_method'] == 'Free Money' || _userData['payout_method'] == 'free_money')
                                  ? 'assets/images/freemoney.jpg'
                                  : 'assets/images/orange_money.png',
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Icon(
                        Icons.phone_android_outlined,
                        color: Colors.white,
                        size: 22,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasPayoutMethod
                          ? 'Mode de réception configuré ✓'
                          : 'Configurer mon mode de réception',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasPayoutMethod
                          ? '${_userData['payout_method']} (${_userData['payout_phone'] ?? '...'})'
                          : 'Ajoutez votre numéro Wave, Orange Money ou FreeMoney',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminBanner() {
    final user = SupabaseService.getCurrentUser();
    final isAdmin = user?.email == 'admin@wetio.com';
    
    if (!isAdmin) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.heavyImpact();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AdminPanel()),
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF673AB7),
                Color(0xFF9C27B0)
              ], // Purple gradient for Admin
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14.0),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF673AB7).withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: const Icon(
                  Icons.admin_panel_settings,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PANEL ADMINISTRATEUR',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Valider les paiements en attente',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveryPartnerBanner() {
    final isPartner = _userData['is_delivery_partner'] ?? false;
    if (!isPartner) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.heavyImpact();
          Navigator.pushNamed(
            context,
            AppRoutes.deliveryPartnerNotificationSystem,
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF2196F3),
                Color(0xFF00BCD4)
              ], // Blue/Cyan gradient
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14.0),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2196F3).withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: const CustomIconWidget(
                  iconName: 'local_shipping',
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ESPACE LIVREUR WETIO',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Gérez vos livraisons et vos revenus',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "Mon Profil",
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black),
            onPressed: () {
              Navigator.pushNamed(context, '/account-settings-screen');
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _handleRefresh,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // User Profile Header
                    UserProfileHeader(userData: _userData),

                    const SizedBox(height: 16),

                    // Token Balance Widget
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: TokenBalanceWidget(),
                    ),

                    const SizedBox(height: 12),

                    // Admin Panel for authorized admins
                    _buildAdminBanner(),

                    const SizedBox(height: 12),

                    // Payout Method Banner for sellers
                    _buildPayoutMethodBanner(),

                    const SizedBox(height: 12),

                    // Delivery Partner Space for Couriers
                    _buildDeliveryPartnerBanner(),

                    const SizedBox(height: 16),

                    // Product Tab Bar and Content
                    Container(
                      color: Colors.white,
                      child: Column(
                        children: [
                          ProductTabBar(
                            availableCount: _availableProducts.length,
                            wantedCount: _wantedProducts.length,
                            completedCount: _completedExchanges.length,
                            currentIndex: selectedTab,
                            onTabChanged: (index) {
                              setState(() {
                                selectedTab = index;
                              });

                              // Navigate to full archive when completed tab is selected
                              if (index == 2) {
                                Navigator.pushNamed(
                                  context,
                                  '/completed-exchange-archive',
                                );
                                // Reset to available tab after navigation
                                setState(() {
                                  selectedTab = 0;
                                });
                              }
                            },
                          ),

                          // Products content based on selected tab
                          _buildProductsContent(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: const CustomBottomBar(
        currentIndex: 4,
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

  Widget _buildProductsContent() {
    if (selectedTab == 0) {
      // Available Products Tab
      if (_availableProducts.isEmpty) {
        return EmptyStateWidget(
          title: 'Aucun produit disponible',
          subtitle:
              'Commencez par ajouter vos premiers produits à échanger. C\'est gratuit et facile !',
          buttonText: 'Ajouter votre premier produit',
          iconName: 'inventory_2',
          onButtonPressed: () => _navigateToAddProduct(false),
        );
      } else {
        return Padding(
          padding: EdgeInsets.all(16.0),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12.0,
              mainAxisSpacing: 12.0,
              childAspectRatio: 0.61,
            ),
            itemCount: _availableProducts.length,
            itemBuilder: (context, index) {
              final product = _availableProducts[index];
              return AvailableProductCard(
                product: product,
                onTap: () => _navigateToProductDetail(product),
                onLongPress: () => _showProductOptions(context, product),
                isOwnProfile: true,
              );
            },
          ),
        );
      }
    } else if (selectedTab == 1) {
      // LI LA BEUGUE - Favorites Tab
      return const FavoritesTabWidget();
    } else {
      // Completed Exchanges Tab
      return Container(
        height: 50.h,
        child: Column(
          children: [
            // Quick access to full archive
            Container(
              margin: EdgeInsets.all(16.0),
              padding: EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                    Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CustomIconWidget(
                      iconName: 'history',
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 24.0,
                    ),
                  ),
                  SizedBox(width: 12.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Archive complète',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                        Text(
                          '${_completedExchanges.length} échange${_completedExchanges.length > 1 ? 's' : ''} terminé${_completedExchanges.length > 1 ? 's' : ''}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 6.0,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Voir tout',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        SizedBox(width: 4.0),
                        CustomIconWidget(
                          iconName: 'arrow_forward',
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 16.0,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Recent exchanges preview or empty state
            Expanded(
              child: _completedExchanges.isEmpty
                  ? EmptyStateWidget(
                      title: 'Aucun échange terminé',
                      subtitle:
                          'Vos échanges terminés apparaîtront ici automatiquement.',
                      buttonText: 'Découvrir les échanges',
                      iconName: 'history',
                      onButtonPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.homeFeed),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: _completedExchanges.take(3).length,
                      itemBuilder: (context, index) {
                        final exchange = _completedExchanges[index];
                        return Container(
                          margin: EdgeInsets.only(bottom: 12.0),
                          padding: EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.outline.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CustomIconWidget(
                                    iconName:
                                        exchange['exchange_method'] == 'direct'
                                        ? 'handshake'
                                        : 'local_shipping',
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    size: 20.0,
                                  ),
                                  SizedBox(width: 8.0),
                                  Expanded(
                                    child: Text(
                                      _formatCompletionDate(
                                        exchange['completion_date'],
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                          ),
                                    ),
                                  ),
                                  if (exchange['rating_given'] != null)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CustomIconWidget(
                                          iconName: 'star',
                                          color: AppTheme.warningOrange,
                                          size: 16.0,
                                        ),
                                        SizedBox(width: 2.0),
                                        Text(
                                          '${exchange['rating_given']}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurface,
                                              ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                              SizedBox(height: 8.0),
                              Text(
                                '${exchange['target_product_title']} ↔ ${exchange['requester_product_title']}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      );
    }
  }

  String _formatCompletionDate(String dateString) {
    final date = DateTime.parse(dateString);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Terminé aujourd\'hui';
    } else if (difference.inDays == 1) {
      return 'Terminé hier';
    } else if (difference.inDays < 7) {
      return 'Terminé il y a ${difference.inDays} jours';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'Terminé il y a $weeks semaine${weeks > 1 ? 's' : ''}';
    } else {
      final years = (difference.inDays / 365).floor();
      return years > 0
          ? 'Terminé il y a $years an${years > 1 ? 's' : ''}'
          : 'Terminé il y a ${(difference.inDays / 30).floor()} mois';
    }
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _isRefreshing = true;
    });

    await _loadProfileData();

    setState(() {
      _isRefreshing = false;
    });

    HapticFeedback.lightImpact();
  }

  Future<void> _handleAvatarTap() async {
    HapticFeedback.lightImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAvatarOptionsSheet(context),
    );
  }

  Widget _buildAvatarOptionsSheet(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
            'Changer la photo de profil',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 25.5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildAvatarOption(
                context,
                'Caméra',
                'camera_alt',
                () => _pickImage(ImageSource.camera),
                colorScheme,
              ),
              _buildAvatarOption(
                context,
                'Galerie',
                'photo_library',
                () => _pickImage(ImageSource.gallery),
                colorScheme,
              ),
              _buildAvatarOption(
                context,
                'Supprimer',
                'delete',
                () => _removeAvatar(),
                colorScheme,
              ),
            ],
          ),
          SizedBox(height: 34.0),
        ],
      ),
    );
  }

  Widget _buildAvatarOption(
    BuildContext context,
    String label,
    String iconName,
    VoidCallback onTap,
    ColorScheme colorScheme,
  ) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Column(
        children: [
          Container(
            width: 60.0,
            height: 60.0,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: iconName,
                color: colorScheme.primary,
                size: 28.0,
              ),
            ),
          ),
          SizedBox(height: 8.5),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      if (source == ImageSource.camera && !kIsWeb) {
        final permission = await Permission.camera.request();
        if (!permission.isGranted) {
          _showPermissionDialog('caméra');
          return;
        }
      }

      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _userData['avatar'] = image.path;
        });
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la sélection de l\'image');
    }
  }

  void _removeAvatar() {
    setState(() {
      _userData['avatar'] = null;
    });
    HapticFeedback.lightImpact();
  }

  void _showPermissionDialog(String permission) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text(
          'Permission requise',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        content: Text(
          'L\'accès à la $permission est nécessaire pour changer votre photo de profil.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Paramètres'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _navigateToProductDetail(Map<String, dynamic> product) {
    Navigator.pushNamed(
      context,
      AppRoutes.productDetail,
      arguments: product,
    );
  }

  void _navigateToAddProduct(bool isWantedProduct) {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(
      context,
      AppRoutes.addProduct,
      arguments: {'isWantedProduct': isWantedProduct},
    );
  }

  void _showProductOptions(BuildContext context, Map<String, dynamic> product) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
              product['title'] as String,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 25.5),
            _buildOptionItem(
              context,
              'Modifier',
              'edit',
              () => _editProduct(product),
              colorScheme,
            ),
            _buildOptionItem(
              context,
              'Marquer comme échangé',
              'check_circle',
              () => _markAsExchanged(product),
              colorScheme,
            ),
            _buildOptionItem(
              context,
              'Supprimer',
              'delete',
              () => _deleteProduct(product),
              colorScheme,
              isDestructive: true,
            ),
            SizedBox(height: 17.0),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionItem(
    BuildContext context,
    String title,
    String iconName,
    VoidCallback onTap,
    ColorScheme colorScheme, {
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);

    return ListTile(
      leading: CustomIconWidget(
        iconName: iconName,
        color: isDestructive ? AppTheme.errorRed : colorScheme.onSurface,
        size: 24.0,
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: isDestructive ? AppTheme.errorRed : colorScheme.onSurface,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  void _editProduct(Map<String, dynamic> product) {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(
      context,
      AppRoutes.addProduct,
      arguments: {'product': product, 'isEdit': true},
    );
  }

  void _markAsExchanged(Map<String, dynamic> product) {
    HapticFeedback.lightImpact();
    setState(() {
      product['status'] = 'exchanged';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product['title']} marqué comme échangé'),
        backgroundColor: AppTheme.successGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _deleteProduct(Map<String, dynamic> product) {
    HapticFeedback.mediumImpact();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le produit'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer "${product['title']}" ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                if (selectedTab == 0) {
                  _availableProducts.removeWhere(
                    (p) => p['id'] == product['id'],
                  );
                } else {
                  _wantedProducts.removeWhere((p) => p['id'] == product['id']);
                }
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${product['title']} supprimé'),
                  backgroundColor: AppTheme.errorRed,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showSettingsBottomSheet(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
              'Paramètres du compte',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 25.5),
            _buildSettingItem(
              context,
              'Modifier le profil',
              'person',
              () => Navigator.pushNamed(context, AppRoutes.accountSettingsScreen),
              colorScheme,
            ),
            _buildSettingItem(
              context,
              'Notifications',
              'notifications',
              () => _showNotificationSettings(context),
              colorScheme,
            ),
            _buildSettingItem(
              context,
              'Confidentialité',
              'privacy_tip',
              () => Navigator.pushNamed(context, AppRoutes.privacySettingsScreen),
              colorScheme,
            ),
            _buildSettingItem(
              context,
              'Aide et support',
              'help',
              () => _showHelpAndSupport(),
              colorScheme,
            ),
            _buildSettingItem(
              context,
              'À propos',
              'info',
              () => _showAboutDialog(),
              colorScheme,
            ),
            _buildSettingItem(
              context,
              'Se déconnecter',
              'logout',
              () => Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.loginScreen,
                (route) => false,
              ),
              colorScheme,
              isDestructive: true,
            ),
            SizedBox(height: 34.0),
          ],
        ),
      ),
    );
  }

  void _showNotificationSettings(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Row(
          children: [
            CustomIconWidget(
              iconName: 'notifications',
              color: colorScheme.primary,
              size: 24.0,
            ),
            SizedBox(width: 8.0),
            Text(
              'Paramètres des notifications',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildNotificationOption(
              context,
              'Nouvelles propositions d\'échange',
              true,
              colorScheme,
            ),
            _buildNotificationOption(
              context,
              'Messages reçus',
              true,
              colorScheme,
            ),
            _buildNotificationOption(
              context,
              'Mises à jour de livraison',
              true,
              colorScheme,
            ),
            _buildNotificationOption(
              context,
              'Promotions et nouveautés',
              false,
              colorScheme,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Fermer',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationOption(
    BuildContext context,
    String title,
    bool initialValue,
    ColorScheme colorScheme,
  ) {
    final theme = Theme.of(context);

    return StatefulBuilder(
      builder: (context, setState) {
        bool isEnabled = initialValue;
        return SwitchListTile(
          title: Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          value: isEnabled,
          onChanged: (value) {
            setState(() {
              isEnabled = value;
            });
            HapticFeedback.lightImpact();
          },
          activeThumbColor: colorScheme.primary,
        );
      },
    );
  }

  void _showPrivacySettings(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Row(
          children: [
            CustomIconWidget(
              iconName: 'privacy_tip',
              color: colorScheme.primary,
              size: 24.0,
            ),
            SizedBox(width: 8.0),
            Text(
              'Confidentialité',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPrivacyOption(
              context,
              'Profil public',
              'Votre profil est visible par tous les utilisateurs',
              true,
              colorScheme,
            ),
            _buildPrivacyOption(
              context,
              'Afficher le numéro de téléphone',
              'Les autres utilisateurs peuvent voir votre numéro',
              false,
              colorScheme,
            ),
            _buildPrivacyOption(
              context,
              'Afficher l\'adresse exacte',
              'Afficher votre adresse complète dans les annonces',
              false,
              colorScheme,
            ),
            SizedBox(height: 17.0),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'description',
                color: colorScheme.primary,
                size: 24.0,
              ),
              title: Text(
                'Conditions d\'utilisation',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.termsOfServiceScreen);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyOption(
    BuildContext context,
    String title,
    String subtitle,
    bool initialValue,
    ColorScheme colorScheme,
  ) {
    final theme = Theme.of(context);

    return StatefulBuilder(
      builder: (context, setState) {
        bool isEnabled = initialValue;
        return SwitchListTile(
          title: Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          value: isEnabled,
          onChanged: (value) {
            setState(() {
              isEnabled = value;
            });
            HapticFeedback.lightImpact();
          },
          activeThumbColor: colorScheme.primary,
        );
      },
    );
  }

  void _showHelpAndSupport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aide et support'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Questions fréquentes',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 8),
              _buildFAQItem(
                'Comment échanger un produit ?',
                'Sélectionnez un produit, proposez un échange et attendez la réponse du propriétaire.',
              ),
              _buildFAQItem(
                'Comment devenir livreur ?',
                'Allez dans les paramètres et cliquez sur "Devenir livreur" pour commencer l\'inscription.',
              ),
              _buildFAQItem(
                'Mes données sont-elles sécurisées ?',
                'Oui, toutes vos données sont cryptées et protégées selon les normes de sécurité.',
              ),
              const SizedBox(height: 16),
              const Text(
                'Contactez-nous',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text('Email: support@wetio.com'),
              const Text('Téléphone: +221 XX XXX XX XX'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question, style: const TextStyle(fontWeight: FontWeight.normal)),
          const SizedBox(height: 4),
          Text(answer, style: TextStyle(color: Colors.grey[700])),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('À propos de Wetio'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Version 1.0.0',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              const Text(
                'Wetio est une plateforme d\'échange de produits qui permet aux utilisateurs de troquer leurs biens de manière simple et sécurisée.',
              ),
              const SizedBox(height: 16),
              const Text(
                'Fonctionnalités principales :',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text('• Échange de produits entre utilisateurs'),
              const Text('• Service de livraison intégré'),
              const Text('• Système de notation et avis'),
              const Text('• Chat en temps réel'),
              const SizedBox(height: 16),
              const Text(
                '© 2024 Wetio. Tous droits réservés.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context,
    String title,
    String iconName,
    VoidCallback onTap,
    ColorScheme colorScheme, {
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);

    return ListTile(
      leading: CustomIconWidget(
        iconName: iconName,
        color: isDestructive ? AppTheme.errorRed : colorScheme.onSurface,
        size: 24.0,
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: isDestructive ? AppTheme.errorRed : colorScheme.onSurface,
        ),
      ),
      trailing: CustomIconWidget(
        iconName: 'chevron_right',
        color: colorScheme.onSurfaceVariant,
        size: 20.0,
      ),
      onTap: () {
        Navigator.pop(context);
        HapticFeedback.lightImpact();
        onTap();
      },
    );
  }

  void _showDeliveryPartnerOptions(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
            CustomIconWidget(
              iconName: 'local_shipping',
              color: colorScheme.primary,
              size: 60.0,
            ),
            SizedBox(height: 17.0),
            Text(
              'Devenir Livreur WETIO',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 8.5),
            Text(
              'Gagnez de l\'argent en livrant des échanges dans votre région',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 25.5),
            _buildDeliveryFeature(
              context,
              'Inscription Premium',
              '500 FCFA seulement',
              'payment',
              colorScheme,
            ),
            _buildDeliveryFeature(
              context,
              'Revenus Flexibles',
              'Travaillez quand vous voulez',
              'schedule',
              colorScheme,
            ),
            _buildDeliveryFeature(
              context,
              'Zone de Couverture',
              'Choisissez vos régions',
              'map',
              colorScheme,
            ),
            SizedBox(height: 34.0),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    AppRoutes.deliveryPartnerPremiumRegistration,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: CustomIconWidget(
                  iconName: 'how_to_reg',
                  color: colorScheme.onPrimary,
                  size: 24.0,
                ),
                label: Text(
                  'S\'inscrire maintenant - 500 FCFA',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
            SizedBox(height: 17.0),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/delivery-partner-search');
              },
              child: Text(
                'Voir les livreurs disponibles',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            SizedBox(height: 17.0),
          ],
        ),
      ),
    );
  }

  String _formatYear(String? dateString) {
    if (dateString == null) return DateTime.now().year.toString();
    try {
      return DateTime.parse(dateString).year.toString();
    } catch (e) {
      return DateTime.now().year.toString();
    }
  }

  Widget _buildDeliveryFeature(
    BuildContext context,
    String title,
    String subtitle,
    String iconName,
    ColorScheme colorScheme,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.5),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: CustomIconWidget(
              iconName: iconName,
              color: colorScheme.primary,
              size: 20.0,
            ),
          ),
          SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
