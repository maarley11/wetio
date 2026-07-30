import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_export.dart';
import '../../services/ad_banner_service.dart';
import '../../services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/auth_guard.dart';
import '../../widgets/adaptive_scaffold.dart';
import './widgets/desktop_home_layout.dart';
import './widgets/empty_state_widget.dart';
import './widgets/filter_bottom_sheet_widget.dart';
import './widgets/header_widget.dart';
import './widgets/product_card_widget.dart';
import './widgets/quick_actions_bottom_sheet_widget.dart';
import './widgets/search_bar_widget.dart';

class HomeFeed extends StatefulWidget {
  const HomeFeed({super.key});

  @override
  State<HomeFeed> createState() => _HomeFeedState();
}

class _HomeFeedState extends State<HomeFeed> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  RealtimeChannel? _productSubscription;

  bool _isLoading = false;
  bool _isLoadingMore = false;
  String _currentLocation = 'Dakar, Sénégal';
  int _notificationCount = 3;
  bool _isLoadingFromSupabase = false;

  Map<String, dynamic> _currentFilters = {
    'category': 'Tous',
    'demographic': 'Tous',
    'distance': 50.0,
  };

  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  List<Map<String, dynamic>> _supabaseProducts = [];
  int _supabaseOffset = 0;
  bool _hasMoreSupabaseProducts = true;

  Set<String> _favoriteProductIds = {};

  final AdBannerService _adBannerService = AdBannerService();
  AdBanner? _currentBanner;
  Timer? _bannerRotationTimer;
  final List<Map<String, dynamic>> _mockProducts = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
    _setupScrollListener();
    _loadFavoriteIds();
    _initBannerRotation();
    _setupRealtimeListener();
  }

  void _setupRealtimeListener() {
    final supabase = SupabaseService.safeClient;
    if (supabase == null) return;

    _productSubscription = supabase
        .channel('public:products')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'products',
          callback: (payload) {
            _loadProductsFromSupabase();
          },
        )
        .subscribe();
  }

  void _initBannerRotation() {
    final banners = _adBannerService.activeBanners;
    if (banners.isEmpty) return;
    setState(() {
      _currentBanner = banners.first;
    });
    _adBannerService.recordImpression(banners.first.id);
    _scheduleBannerRotation();
  }

  void _scheduleBannerRotation() {
    _bannerRotationTimer?.cancel();
    final freq = _currentBanner?.rotationFrequencySeconds ?? 10;
    _bannerRotationTimer = Timer(Duration(seconds: freq), () {
      if (!mounted) return;
      final next = _adBannerService.getNextBanner(_currentBanner?.id);
      if (next != null && next.id != _currentBanner?.id) {
        setState(() => _currentBanner = next);
        _adBannerService.recordImpression(next.id);
      }
      _scheduleBannerRotation();
    });
  }

  @override
  void dispose() {
    _bannerRotationTimer?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    _productSubscription?.unsubscribe();
    super.dispose();
  }

  void _initializeData() {
    setState(() {
      _isLoading = true;
    });

    // Load from Supabase first, fallback to mock data
    _loadProductsFromSupabase();
  }

  Future<void> _loadFavoriteIds() async {
    try {
      final ids = await SupabaseService.getFavoriteProductIds();
      if (mounted) {
        setState(() {
          _favoriteProductIds = ids;
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleFavorite(Map<String, dynamic> product, bool isFav) async {
    requireAuth(context, () async {
      final productId = product['id']?.toString() ?? '';
      if (productId.isEmpty) return;
      try {
        if (isFav) {
          await SupabaseService.addFavorite(productId, productData: product);
          setState(() => _favoriteProductIds.add(productId));
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Ajouté à LI LA BEUGUE ❤️'),
                backgroundColor: Colors.red[400],
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          await SupabaseService.removeFavorite(productId);
          setState(() => _favoriteProductIds.remove(productId));
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Retiré de LI LA BEUGUE'),
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      } catch (_) {}
    });
  }

  Future<void> _loadProductsFromSupabase({bool isLoadMore = false}) async {
    try {
      final supabase = SupabaseService.safeClient;
      if (supabase == null) return;

      if (!isLoadMore) {
        _supabaseOffset = 0;
        _hasMoreSupabaseProducts = true;
      }

      final response = await supabase
          .from('products')
          .select('*, owner:user_profiles!owner_id(*)')
          .order('created_at', ascending: false)
          .range(_supabaseOffset, _supabaseOffset + 19);

      if (mounted) {
        final List<dynamic> data = (response as List<dynamic>?) ?? [];
        
        if (data.length < 20) {
          _hasMoreSupabaseProducts = false;
        }
        _supabaseOffset += data.length;
        final titlesToRemove = [
          'Robe été fleurie',
          'Livre de cuisine végétarienne',
          'Sac à main vintage',
          'cosmetique',
          't-chirt polo',
          'Resserre vagin, lutte contre les bactéries',
          'Gel et savon intime',
          'Savon et gel intime+parfums de classe'
        ];

        final List<Map<String, dynamic>> dbProducts = data
            .where((item) => !titlesToRemove.contains(item['title']))
            .map((item) {
          final Map<String, dynamic> productMap =
              Map<String, dynamic>.from(item as Map);
          final images = productMap['images'] as List?;
          final ownerData = productMap['owner'] as Map<String, dynamic>?;

          return {
            'id': productMap['id'],
            'title': productMap['title'] ?? 'Sans titre',
            'description': productMap['description'] ?? '',
            'category': productMap['category'] ?? 'Autres',
            'image': (images != null && images.isNotEmpty) ? images[0] : null,
            'images': images,
            'location': productMap['location'] ?? 'Sénégal',
            'price': item['price'] ??
                item['Price'] ??
                item['amount'] ??
                item['montant'],
            'ownerId': productMap['owner_id'],
            'owner_id': productMap['owner_id'],
            'owner': ownerData,
            'condition': productMap['product_condition'],
            'type': productMap['product_type'],
            'demographic': 'Tous',
            'userName': ownerData?['full_name'] ?? ownerData?['pseudo'] ?? 'Utilisateur',
            'distance': '~2 km',
          };
        }).toList();

        setState(() {
          if (isLoadMore) {
            _supabaseProducts.addAll(dbProducts);
            _products.addAll(dbProducts);
          } else {
            _supabaseProducts = dbProducts;
            _products = dbProducts;
          }
          _applyFilters();
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Critical error loading products: $e');
      if (mounted) {
        setState(() {
          _products = [];
          _supabaseProducts = [];
          _filteredProducts = [];
          _isLoading = false;
        });
      }
    }
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadMoreProducts();
      }
    });
  }

  void _loadMoreProducts() {
    if (_isLoadingMore || !_hasMoreSupabaseProducts) return;

    setState(() {
      _isLoadingMore = true;
    });

    _loadProductsFromSupabase(isLoadMore: true);
  }

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    await _loadProductsFromSupabase();
  }

  void _applyFilters() {
    setState(() {
      _filteredProducts = _products.where((product) {
        // Category filter
        if (_currentFilters['category'] != 'Tous') {
          final filterValue = _mapCategoryLabelToValue(_currentFilters['category']);
          if (product['category'] != filterValue &&
              product['category'] != _currentFilters['category']) {
            return false;
          }
        }

        // Demographic filter
        if (_currentFilters['demographic'] != 'Tous' &&
            product['demographic'] != _currentFilters['demographic'] &&
            product['demographic'] != 'Tous') {
          return false;
        }

        // Search filter
        if (_searchController.text.isNotEmpty) {
          final searchTerm = _searchController.text.toLowerCase();
          final title = (product['title'] as String).toLowerCase();
          final description = (product['description'] as String).toLowerCase();
          if (!title.contains(searchTerm) &&
              !description.contains(searchTerm)) {
            return false;
          }
        }

        return true;
      }).toList();
    });
  }

  String _mapCategoryLabelToValue(String label) {
    switch (label) {
      case 'Vêtements':
        return 'vetements';
      case 'Vêtements de fêtes':
        return 'vetements_fetes';
      case 'Chaussures':
        return 'chaussures';
      case 'Jeux':
        return 'jeux';
      case 'Livres':
        return 'livres';
      case 'Services':
        return 'services';
      case 'Autres':
        return 'autres';
      default:
        return label.toLowerCase();
    }
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => FilterBottomSheetWidget(
          currentFilters: _currentFilters,
          onFiltersChanged: (filters) {
            setState(() {
              _currentFilters = filters;
            });
            _applyFilters();
          },
        ),
      ),
    );
  }

  void _showQuickActions(Map<String, dynamic> product) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => QuickActionsBottomSheetWidget(
        product: product,
        onSaveToFavorites: () => _saveToFavorites(product),
        onReport: () => _reportProduct(product),
        onShare: () => _shareProduct(product),
      ),
    );
  }

  void _saveToFavorites(Map<String, dynamic> product) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product['title']} ajouté aux favoris'),
        backgroundColor: AppTheme.successGreen,
      ),
    );
  }

  void _reportProduct(Map<String, dynamic> product) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Produit signalé'),
        backgroundColor: AppTheme.warningOrange,
      ),
    );
  }

  void _shareProduct(Map<String, dynamic> product) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Partage de ${product['title']}'),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }

  void _navigateWithAuthGuard(String route, {Object? arguments}) {
    requireAuth(context, () {
      if (arguments != null) {
        Navigator.pushNamed(context, route, arguments: arguments);
      } else {
        Navigator.pushNamed(context, route);
      }
    });
  }

  void _showAuthRequiredDialog() {
    // Auth dialog removed - no authentication required
  }

  // Admin check — only the account owner can manage banners
  static const String _adminEmail = 'admin@wetio.sn';

  bool get _isAdmin {
    final supabase = SupabaseService.safeClient;
    if (supabase == null) return false;
    final user = supabase.auth.currentUser;
    if (user == null) return false;
    final email = user.email ?? '';
    return email == _adminEmail;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;

    return AdaptiveScaffold(
      currentIndex: 0,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'whatsapp_fab',
            onPressed: () async {
              final Uri whatsappUri = Uri.parse('https://wa.me/221707661502');
              if (await canLaunchUrl(whatsappUri)) {
                await launchUrl(
                  whatsappUri,
                  mode: LaunchMode.externalApplication,
                );
              }
            },
            backgroundColor: const Color(0xFF25D366),
            shape: const CircleBorder(),
            child: SvgPicture.string(
              '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 175.216 175.552" fill="white"><path d="M87.6 0C39.3 0 0 39.3 0 87.6c0 15.3 4 29.7 11 42.2L0 175.6l47.2-10.8c12 6.4 25.7 10 40.4 10 48.3 0 87.6-39.3 87.6-87.6S135.9 0 87.6 0zm0 160.3c-13.4 0-26-3.5-37-9.6l-2.6-1.6-27.2 6.2 6.4-26.4-1.7-2.7c-6.8-11.3-10.6-24.4-10.6-38.4C14.9 47.1 47.1 14.9 87.6 14.9c19.9 0 38.6 7.7 52.7 21.8 14 14 21.8 32.7 21.8 52.7-.1 40.5-32.3 70.9-74.5 70.9zm40.8-53.1c-2.2-1.1-13.1-6.5-15.2-7.2-2-.7-3.5-1.1-5 1.1-1.5 2.2-5.7 7.2-7 8.7-1.3 1.5-2.5 1.7-4.7.6-2.2-1.1-9.3-3.4-17.7-10.9-6.5-5.8-10.9-13-12.2-15.2-1.3-2.2-.1-3.4 1-4.5.9-.9 2.2-2.5 3.2-3.7 1.1-1.5 1.5-2.1 2.2-3.5.7-1.5.4-2.7-.2-3.8-.6-1.1-5-12-6.8-16.4-1.8-4.3-3.6-3.7-5-3.8-1.3-.1-2.7-.1-4.2-.1-1.5 0-3.8.6-5.8 2.7-2 2.2-7.6 7.4-7.6 18.1s7.8 21 8.9 22.5c1.1 1.5 15.3 23.4 37.1 32.8 5.2 2.2 9.2 3.6 12.4 4.6 5.2 1.7 9.9 1.4 13.7.9 4.2-.6 12.9-5.3 14.7-10.4 1.8-5.1 1.8-9.5 1.3-10.4-.6-.9-2.1-1.5-4.3-2.6z"/></svg>''',
              width: 28,
              height: 28,
            ),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'add_product_fab',
            onPressed: () {
              HapticFeedback.lightImpact();
              _navigateWithAuthGuard(AppRoutes.addProduct);
            },
            backgroundColor: const Color(0xFFFF6B00),
            shape: const CircleBorder(),
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header
          HeaderWidget(
            currentLocation: _currentLocation,
            notificationCount: _notificationCount,
            onLocationTap: () async {
              HapticFeedback.lightImpact();
              final selectedLocation = await Navigator.pushNamed(
                context,
                AppRoutes.locationSelectionScreen,
              );
              if (selectedLocation != null && mounted) {
                setState(() {
                  _currentLocation = selectedLocation as String;
                });
              }
            },
            onNotificationTap: () {
              HapticFeedback.lightImpact();
              _navigateWithAuthGuard(AppRoutes.notificationsScreen);
            },
          ),

          // Search Bar
          SearchBarWidget(
            controller: _searchController,
            onChanged: (value) {
              _applyFilters();
            },
            onFilterTap: _showFilterBottomSheet,
          ),

          // Advertising Banner
          _buildAdvertisingBanner(colorScheme),

          // Content
          Expanded(child: _isLoading ? _buildLoadingState() : _buildContent()),
        ],
      ),
    );
  }

  Widget _buildAmenityChip(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 9),
          SizedBox(width: 3.2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 7.5,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return GridView.builder(
      padding: EdgeInsets.symmetric(vertical: 17.0, horizontal: 16.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _getCrossAxisCount(context),
        crossAxisSpacing: 12.0,
        mainAxisSpacing: 17.0,
        childAspectRatio: 0.57,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => _buildSkeletonCard(),
    );
  }

  Widget _buildSkeletonCard() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 170.0,
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  height: 12.8,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                SizedBox(height: 8.5),
                Container(
                  width: double.infinity,
                  height: 8.5,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_filteredProducts.isEmpty) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppTheme.primaryGreen,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(top: 85.0),
          child: EmptyStateWidget(
            title: 'Aucun produit trouvé',
            subtitle:
                'Essayez d\'ajuster vos filtres ou votre recherche pour trouver des produits disponibles.',
            actionText: 'Réinitialiser les filtres',
            onActionTap: () {
              setState(() {
                _currentFilters = {
                  'category': 'Tous',
                  'demographic': 'Tous',
                  'distance': 50.0,
                };
                _searchController.clear();
              });
              _applyFilters();
            },
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppTheme.primaryGreen,
      child: GridView.builder(
        controller: _scrollController,
        padding: EdgeInsets.symmetric(vertical: 17.0, horizontal: 16.0),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _getCrossAxisCount(context),
          crossAxisSpacing: 12.0,
          mainAxisSpacing: 17.0,
          childAspectRatio: 0.57,
        ),
        itemCount: _filteredProducts.length + (_isLoadingMore ? 2 : 0),
        itemBuilder: (context, index) {
          if (index >= _filteredProducts.length) {
            return _buildLoadingMoreIndicator();
          }

          final product = _filteredProducts[index];
          final isFavorited = _favoriteProductIds.contains(product['id']);
          return ProductCardWidget(
            product: product,
            isGridView: true,
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pushNamed(
                context,
                AppRoutes.productDetail,
                arguments: product,
              );
            },
            onPropose: () {
              HapticFeedback.lightImpact();
              _navigateWithAuthGuard(
                AppRoutes.exchangeProposal,
                arguments: product,
              );
            },
            onBuy: () {
              HapticFeedback.mediumImpact();
              _navigateWithAuthGuard(
                AppRoutes.productPurchase,
                arguments: product,
              );
            },
            onLongPress: () => _showQuickActions(product),
            isFavorited: isFavorited,
            onFavoriteToggle: (isFav) => _toggleFavorite(product, isFav),
          );
        },
      ),
    );
  }

  Widget _buildLoadingMoreIndicator() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(8.0),
      child: Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryGreen,
          backgroundColor: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width > 1200) return 5;
    if (width > 800) return 4;
    if (width > 600) return 3;
    return 2;
  }

  Widget _buildAdvertisingBanner(ColorScheme colorScheme) {
    final banner = _currentBanner;
    if (banner == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () async {
        _adBannerService.recordClick(banner.id);
        final uri = Uri.parse(
          'https://www.airbnb.fr/rooms/1537058868792369322',
        );
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        if (!_isAdmin) {
          return;
        }
        _showBannerManagementMenu(colorScheme);
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.5),
        height: 153.0,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.0),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                banner.imageUrl,
                fit: BoxFit.cover,
                semanticLabel: 'Bannière publicitaire ${banner.title}',
                errorBuilder: (_, __, ___) =>
                    Container(color: const Color(0xFF1A1A2E)),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.72),
                      Colors.black.withValues(alpha: 0.15),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.0,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF5A5F),
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: Colors.white,
                                  size: 10,
                                ),
                                SizedBox(width: 4.0),
                                Text(
                                  banner.category,
                                  style: GoogleFonts.inter(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 5.1),
                          Text(
                            banner.title,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 3.4),
                          Row(
                            children: [
                              const Icon(
                                Icons.business_rounded,
                                color: Color(0xFFFF5A5F),
                                size: 12,
                              ),
                              SizedBox(width: 2.0),
                              Text(
                                banner.advertiser,
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4.3),
                          // Rotation indicator dots
                          _buildRotationDots(),
                        ],
                      ),
                    ),
                    SizedBox(width: 12.0),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 10.2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Pub',
                            style: GoogleFonts.inter(
                              fontSize: 8,
                              color: const Color(0xFF717171),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 3.4),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.0,
                              vertical: 4.3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF5A5F),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Text(
                              banner.ctaText,
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Advertiser watermark
              Positioned(
                top: 8.5,
                right: 12.0,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 2.5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: Text(
                    banner.advertiser.split(' ').first.toLowerCase(),
                    style: GoogleFonts.inter(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFFF5A5F),
                    ),
                  ),
                ),
              ),
              // Manage button
              Positioned(
                bottom: 8.5,
                right: 12.0,
                child: _isAdmin
                    ? GestureDetector(
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.adBannerScheduling,
                        ),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.settings_rounded,
                                color: Colors.white,
                                size: 10,
                              ),
                              SizedBox(width: 4.0),
                              Text(
                                'Gérer',
                                style: GoogleFonts.inter(
                                  fontSize: 8,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRotationDots() {
    final active = _adBannerService.activeBanners;
    if (active.length <= 1) return const SizedBox.shrink();
    return Row(
      children: active.map((b) {
        final isSelected = b.id == _currentBanner?.id;
        return Container(
          margin: EdgeInsets.only(right: 4.0),
          width: isSelected ? 12.0 : 6.0,
          height: 4,
          decoration: BoxDecoration(
            color:
                isSelected ? Colors.white : Colors.white.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(2.0),
          ),
        );
      }).toList(),
    );
  }

  void _showBannerManagementMenu(ColorScheme colorScheme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16.0)),
        ),
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 17.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.0,
              height: 4.3,
              decoration: BoxDecoration(
                color: colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4.0),
              ),
            ),
            SizedBox(height: 17.0),
            Text(
              'Bannières publicitaires',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 17.0),
            ListTile(
              leading: Icon(
                Icons.schedule_rounded,
                color: AppTheme.primaryGreen,
              ),
              title: Text(
                'Planifier les bannières',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: colorScheme.onSurface,
                ),
              ),
              subtitle: Text(
                'Gérer les dates et la rotation',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.adBannerScheduling);
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart_rounded, color: Colors.blue),
              title: Text(
                'Analytics des performances',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: colorScheme.onSurface,
                ),
              ),
              subtitle: Text(
                'Impressions, clics, CTR',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  AppRoutes.adBannerAnalyticsDashboard,
                );
              },
            ),
            SizedBox(height: 8.5),
          ],
        ),
      ),
    );
  }
}
