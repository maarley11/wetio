import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_export.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/auth_guard.dart';
import 'product_card_widget.dart';

/// Layout extraordinaire pour Desktop (width >= 900px)
/// Donne envie de rester, explorer et acheter.
class DesktopHomeLayout extends StatefulWidget {
  final List<Map<String, dynamic>> products;
  final List<Map<String, dynamic>> filteredProducts;
  final Set<String> favoriteProductIds;
  final Function(Map<String, dynamic>, bool) onFavoriteToggle;
  final Function(Map<String, dynamic>) onProductTap;
  final Function(Map<String, dynamic>) onProductPropose;
  final String currentLocation;
  final bool isLoading;
  final VoidCallback onLoadMore;
  final bool hasMore;

  const DesktopHomeLayout({
    super.key,
    required this.products,
    required this.filteredProducts,
    required this.favoriteProductIds,
    required this.onFavoriteToggle,
    required this.onProductTap,
    required this.onProductPropose,
    required this.currentLocation,
    required this.isLoading,
    required this.onLoadMore,
    required this.hasMore,
  });

  @override
  State<DesktopHomeLayout> createState() => _DesktopHomeLayoutState();
}

class _DesktopHomeLayoutState extends State<DesktopHomeLayout> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _selectedCategory = 'Tous';
  String _selectedCondition = 'Tous';
  RangeValues _priceRange = const RangeValues(0, 500000);
  String _searchQuery = '';

  final List<Map<String, dynamic>> _categories = [
    {'label': 'Tous', 'icon': Icons.apps},
    {'label': 'Vêtements', 'icon': Icons.checkroom},
    {'label': 'Téléphones', 'icon': Icons.phone_android},
    {'label': 'Maison', 'icon': Icons.home},
    {'label': 'Électronique', 'icon': Icons.devices},
    {'label': 'Chaussures', 'icon': Icons.directions_walk},
    {'label': 'Sport', 'icon': Icons.sports_soccer},
    {'label': 'Livres', 'icon': Icons.menu_book},
    {'label': 'Beauté', 'icon': Icons.face},
    {'label': 'Autres', 'icon': Icons.more_horiz},
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 400) {
      if (!widget.isLoading && widget.hasMore) {
        widget.onLoadMore();
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _displayedProducts {
    var products = widget.filteredProducts.isNotEmpty ? widget.filteredProducts : widget.products;

    if (_searchQuery.isNotEmpty) {
      products = products.where((p) {
        final title = (p['title'] as String? ?? '').toLowerCase();
        return title.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    if (_selectedCategory != 'Tous') {
      products = products.where((p) {
        final category = (p['category'] as String? ?? '').toLowerCase();
        return category.contains(_selectedCategory.toLowerCase());
      }).toList();
    }

    if (_selectedCondition != 'Tous') {
      products = products.where((p) {
        final condition = p['product_condition'] as String? ?? '';
        return condition == _selectedCondition;
      }).toList();
    }

    return products;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F6),
      body: Column(
        children: [
          _buildTopNav(context),
          _buildHeroBanner(context),
          _buildCategoryBar(context),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFilterSidebar(context),
                Expanded(
                  child: _buildProductGrid(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── TOP NAVIGATION BAR ──────────────────────────────────────────────────
  Widget _buildTopNav(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          // Logo
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryGreen, Color(0xFF2E7D32)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.swap_horiz, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 8),
              Text(
                'WETIO',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryGreen,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),

          const SizedBox(width: 32),

          // Search bar
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F4F6),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                style: GoogleFonts.inter(fontSize: 14, color: Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Rechercher un produit, une marque...',
                  hintStyle: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade500),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          const SizedBox(width: 24),

          // Location
          InkWell(
            onTap: () => Navigator.pushNamed(context, AppRoutes.locationSelectionScreen),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: AppTheme.primaryGreen, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    widget.currentLocation.split(',').first,
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87),
                  ),
                  const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey),
                ],
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Notifications
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined, size: 24, color: Colors.black54),
                Positioned(
                  top: 0, right: 0,
                  child: Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  ),
                ),
              ],
            ),
            onPressed: () => requireAuth(context, () => Navigator.pushNamed(context, AppRoutes.notificationsScreen)),
          ),

          const SizedBox(width: 8),

          // Profile
          IconButton(
            icon: const Icon(Icons.person_outline, size: 24, color: Colors.black54),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.userProfile),
          ),

          const SizedBox(width: 12),

          // Publish button
          ElevatedButton.icon(
            onPressed: () => requireAuth(context, () => Navigator.pushNamed(context, AppRoutes.addProduct)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryOrange,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: Text(
              'Publier',
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // ─── HERO BANNER ─────────────────────────────────────────────────────────
  Widget _buildHeroBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 36),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF4CAF50), Color(0xFFFF7043)],
          stops: [0.0, 0.55, 1.0],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Achetez, vendez & échangez au Sénégal',
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Des milliers d\'annonces près de chez vous. C\'est gratuit, facile et sécurisé.',
            style: GoogleFonts.inter(fontSize: 15, color: Colors.white.withValues(alpha: 0.9)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Big Search
          Container(
            constraints: const BoxConstraints(maxWidth: 680),
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 20),
                const Icon(Icons.search, color: Colors.grey, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: GoogleFonts.inter(fontSize: 15, color: Colors.black87),
                    decoration: InputDecoration(
                      hintText: 'Que recherchez-vous ?',
                      hintStyle: GoogleFonts.inter(fontSize: 15, color: Colors.grey.shade400),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(6),
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      elevation: 0,
                    ),
                    child: Text(
                      'Rechercher',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStat('25 000+', 'Annonces actives'),
              _buildStatDivider(),
              _buildStat('12 000+', 'Vendeurs'),
              _buildStatDivider(),
              _buildStat('0%', 'Commission'),
              _buildStatDivider(),
              _buildStat('100%', 'Sécurisé'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.white.withValues(alpha: 0.8))),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      color: Colors.white.withValues(alpha: 0.3),
    );
  }

  // ─── CATEGORY BAR ────────────────────────────────────────────────────────
  Widget _buildCategoryBar(BuildContext context) {
    return Container(
      height: 56,
      color: Colors.white,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final cat = _categories[i];
          final isSelected = _selectedCategory == cat['label'];
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat['label'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryGreen : const Color(0xFFF2F4F6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppTheme.primaryGreen : Colors.transparent,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    cat['icon'] as IconData,
                    size: 16,
                    color: isSelected ? Colors.white : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    cat['label'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── FILTER SIDEBAR ───────────────────────────────────────────────────────
  Widget _buildFilterSidebar(BuildContext context) {
    return Container(
      width: 240,
      color: Colors.white,
      margin: const EdgeInsets.only(right: 1),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filtres', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black87)),
            const SizedBox(height: 20),

            // État du produit
            Text('État', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54)),
            const SizedBox(height: 8),
            ...['Tous', 'neuf', 'tres_bon_etat', 'bon_etat', 'etat_correct'].map((c) {
              final labels = {
                'Tous': 'Tous',
                'neuf': '✨ Neuf',
                'tres_bon_etat': '👍 Très bon état',
                'bon_etat': '👌 Bon état',
                'etat_correct': '📦 État correct',
              };
              return RadioListTile<String>(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(labels[c]!, style: GoogleFonts.inter(fontSize: 13)),
                value: c,
                groupValue: _selectedCondition,
                activeColor: AppTheme.primaryGreen,
                onChanged: (v) => setState(() => _selectedCondition = v!),
              );
            }),

            const Divider(height: 32),

            // Fourchette de prix
            Text('Prix (FCFA)', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54)),
            const SizedBox(height: 8),
            RangeSlider(
              values: _priceRange,
              min: 0,
              max: 500000,
              divisions: 50,
              activeColor: AppTheme.primaryGreen,
              labels: RangeLabels(
                '${_priceRange.start.round()}',
                '${_priceRange.end.round()}',
              ),
              onChanged: (v) => setState(() => _priceRange = v),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${_priceRange.start.round()} FCFA', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
                Text('${_priceRange.end.round()} FCFA', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
              ],
            ),

            const Divider(height: 32),

            // Reset
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => setState(() {
                  _selectedCategory = 'Tous';
                  _selectedCondition = 'Tous';
                  _priceRange = const RangeValues(0, 500000);
                }),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.primaryGreen),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('Réinitialiser', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.primaryGreen, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── PRODUCT GRID ─────────────────────────────────────────────────────────
  Widget _buildProductGrid(BuildContext context) {
    final products = _displayedProducts;

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Text(
                  '${products.length} résultat${products.length != 1 ? 's' : ''}',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black54),
                ),
                const Spacer(),
                Text('Trier par :', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey)),
                const SizedBox(width: 8),
                _buildSortChip('Récent'),
                const SizedBox(width: 6),
                _buildSortChip('Prix ↑'),
                const SizedBox(width: 6),
                _buildSortChip('Prix ↓'),
              ],
            ),
          ),
        ),

        if (products.isEmpty && !widget.isLoading)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.search_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('Aucun produit trouvé', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey)),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index >= products.length) {
                    return widget.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : const SizedBox.shrink();
                  }
                  final product = products[index];
                  return _DesktopProductCard(
                    product: product,
                    isFavorited: widget.favoriteProductIds.contains(product['id']),
                    onTap: () => widget.onProductTap(product),
                    onFavoriteToggle: (v) => widget.onFavoriteToggle(product, v),
                    onPropose: () => widget.onProductPropose(product),
                  );
                },
                childCount: products.length + (widget.isLoading ? 1 : 0),
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.72,
              ),
            ),
          ),

        const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
      ],
    );
  }

  Widget _buildSortChip(String label) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F4F6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.black54)),
      ),
    );
  }
}

// ─── DESKTOP PRODUCT CARD ────────────────────────────────────────────────────
class _DesktopProductCard extends StatefulWidget {
  final Map<String, dynamic> product;
  final bool isFavorited;
  final VoidCallback onTap;
  final ValueChanged<bool> onFavoriteToggle;
  final VoidCallback onPropose;

  const _DesktopProductCard({
    required this.product,
    required this.isFavorited,
    required this.onTap,
    required this.onFavoriteToggle,
    required this.onPropose,
  });

  @override
  State<_DesktopProductCard> createState() => _DesktopProductCardState();
}

class _DesktopProductCardState extends State<_DesktopProductCard> {
  bool _isHovered = false;
  late bool _isFavorited;

  @override
  void initState() {
    super.initState();
    _isFavorited = widget.isFavorited;
  }

  String _formatPrice(dynamic rawPrice) {
    if (rawPrice == null) return 'Prix à discuter';
    try {
      double v = rawPrice is num ? rawPrice.toDouble() : double.tryParse(rawPrice.toString().replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
      if (v <= 0) return 'Prix à discuter';
      return '${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} FCFA';
    } catch (_) {
      return 'Prix à discuter';
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.product['image'] as String?;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty && imageUrl.startsWith('http');
    final isNew = widget.product['product_condition'] == 'neuf';

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? AppTheme.primaryGreen.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.06),
                blurRadius: _isHovered ? 20 : 10,
                offset: Offset(0, _isHovered ? 8 : 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Expanded(
                flex: 5,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Image
                      hasImage
                          ? AnimatedScale(
                              scale: _isHovered ? 1.05 : 1.0,
                              duration: const Duration(milliseconds: 300),
                              child: CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => _buildPlaceholder(),
                              ),
                            )
                          : _buildPlaceholder(),

                      // Gradient on hover
                      if (_isHovered)
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.3)],
                            ),
                          ),
                        ),

                      // Badge NEW
                      if (isNew)
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('NEUF', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5)),
                          ),
                        ),

                      // Favorite button
                      Positioned(
                        top: 10,
                        right: 10,
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setState(() => _isFavorited = !_isFavorited);
                            widget.onFavoriteToggle(_isFavorited);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: _isHovered ? 1.0 : 0.9),
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6)],
                            ),
                            child: Icon(
                              _isFavorited ? Icons.favorite : Icons.favorite_border,
                              size: 16,
                              color: _isFavorited ? Colors.red : Colors.grey.shade400,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Info
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.product['title'] as String? ?? '',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87, height: 1.3),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _formatPrice(widget.product['price'] ?? widget.product['Price']),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryGreen,
                        ),
                      ),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: widget.onPropose,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryOrange.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppTheme.primaryOrange.withValues(alpha: 0.3)),
                                ),
                                child: Center(
                                  child: Text('Wetio', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primaryOrange)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: GestureDetector(
                              onTap: widget.onTap,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGreen.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
                                ),
                                child: Center(
                                  child: Text('Acheter', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primaryGreen)),
                                ),
                              ),
                            ),
                          ),
                        ],
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

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: const Center(child: Icon(Icons.shopping_bag_outlined, size: 40, color: Colors.grey)),
    );
  }
}
