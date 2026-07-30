import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:flutter_stripe/flutter_stripe.dart' hide Card;
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';

class ProductPurchaseScreen extends StatefulWidget {
  const ProductPurchaseScreen({super.key});

  @override
  State<ProductPurchaseScreen> createState() => _ProductPurchaseScreenState();
}

class _ProductPurchaseScreenState extends State<ProductPurchaseScreen> {
  int _quantity = 1;
  String _selectedDelivery = 'standard';
  bool _isProcessing = false;
  bool _orderConfirmed = false;
  String _paymentError = '';

  Map<String, dynamic> _product = {};
  Map<String, dynamic>? _sellerProfile;
  bool _isLoadingSeller = true;

  @override
  void initState() {
    super.initState();
    _loadSellerProfile();
  }

  Future<void> _loadSellerProfile() async {
    try {
      // We need to wait for product data which comes from arguments
      // But arguments are only available in didChangeDependencies
      // We will handle the fetch there instead to be safe
    } catch (e) {
      debugPrint('Error loading seller profile: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _product = args;
      if (_isLoadingSeller) {
        final sellerId = _product['owner_id']?.toString() ?? _product['ownerId']?.toString();
        if (sellerId != null) {
          SupabaseService.getUserProfile(sellerId).then((profile) {
            if (mounted) {
              setState(() {
                _sellerProfile = profile;
                _isLoadingSeller = false;
              });
            }
          }).catchError((e) {
            if (mounted) setState(() => _isLoadingSeller = false);
          });
        } else {
          _isLoadingSeller = false;
        }
      }
    } else {
      _product = {
        'title': 'Produit',
        'price': 15000,
        'image': '',
        'userName': 'Vendeur',
        'location': 'Dakar',
        'condition': 'Bon état',
      };
    }
  }

  double get _productPrice {
    final price = _product['price'] ?? _product['Price'] ?? _product['amount'] ?? _product['montant'];
    if (price == null) return 0.0;
    if (price is int) return price.toDouble();
    if (price is double) return price;
    if (price is String) {
      // Remove any non-numeric characters except decimal point
      final cleanPrice = price.replaceAll(RegExp(r'[^0-9.]'), '');
      return double.tryParse(cleanPrice) ?? 0.0;
    }
    return 0.0;
  }

  double get _deliveryFee {
    switch (_selectedDelivery) {
      case 'express':
        return 3000;
      case 'standard':
        return 1500;
      case 'pickup':
        return 0;
      default:
        return 1500;
    }
  }

  double get _subtotal => _productPrice * _quantity;
  double get _total => _subtotal + _deliveryFee;

  void _incrementQuantity() {
    HapticFeedback.lightImpact();
    setState(() => _quantity++);
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      HapticFeedback.lightImpact();
      setState(() => _quantity--);
    }
  }

  Future<void> _processOrder() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _isProcessing = true;
      _paymentError = '';
    });

    try {
      final productId = _product['id']?.toString();
      final sellerId = _product['owner_id']?.toString() ?? 
                       _product['ownerId']?.toString() ??
                       _product['user_id']?.toString() ?? 
                       _product['userId']?.toString() ??
                       _product['user']?['id']?.toString();

      if (productId == null) {
        throw Exception('ID du produit manquant.');
      }
      if (sellerId == null) {
        throw Exception('ID du vendeur manquant.');
      }

      // Create order directly in Supabase (Manual/Local flow)
      await SupabaseService.createOrder(
        productId: productId,
        sellerId: sellerId,
        amount: _subtotal.toInt(),
        quantity: _quantity,
        deliveryMethod: _selectedDelivery,
        deliveryFee: _deliveryFee.toInt(),
        totalAmount: _total.toInt(),
      );

      setState(() {
        _isProcessing = false;
        _orderConfirmed = true;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _paymentError = _friendlyError(e.toString());
      });
    }
  }

  String _friendlyError(String raw) {
    return raw; // Return raw error for debugging
  }

  String _formatPrice(double price) {
    return '${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} FCFA';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_orderConfirmed) {
      return _buildOrderConfirmation(colorScheme);
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios,
              color: colorScheme.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Acheter',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 17.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProductSummary(colorScheme),
            SizedBox(height: 17.0),
            _buildQuantitySelector(colorScheme),
            SizedBox(height: 17.0),
            _buildDeliveryOptions(colorScheme),
            SizedBox(height: 17.0),
            if (!_isLoadingSeller && _sellerProfile != null) ...[
              _buildSellerInfo(colorScheme),
              SizedBox(height: 17.0),
            ],
            _buildPaymentInfo(colorScheme),
            SizedBox(height: 17.0),
            _buildOrderSummary(colorScheme),
            if (_paymentError.isNotEmpty) ...[
              SizedBox(height: 12.8),
              _buildErrorBanner(colorScheme),
            ],
            SizedBox(height: 25.5),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(colorScheme),
    );
  }

  Widget _buildSellerInfo(ColorScheme colorScheme) {
    final payoutPhone = _sellerProfile?['payout_phone']?.toString() ?? "";
    final payoutMethod = _sellerProfile?['payout_method']?.toString() ?? "Paiement";

    return Container(
      padding: EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20.0,
            backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
            backgroundImage: _sellerProfile?['avatar_url'] != null && _sellerProfile!['avatar_url'].toString().isNotEmpty
                ? NetworkImage(_sellerProfile!['avatar_url'])
                : null,
            child: _sellerProfile?['avatar_url'] == null || _sellerProfile!['avatar_url'].toString().isEmpty
                ? Icon(Icons.person, color: AppTheme.primaryGreen, size: 20.0)
                : null,
          ),
          SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _sellerProfile?['full_name'] ?? _sellerProfile?['pseudo'] ?? 'Vendeur',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (payoutPhone.isNotEmpty) ...[
                  SizedBox(height: 4.3),
                  Row(
                    children: [
                      Icon(Icons.phone_android, size: 14, color: AppTheme.primaryGreen),
                      SizedBox(width: 4.0),
                      Text(
                        "$payoutMethod : $payoutPhone",
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.3),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.verified, color: AppTheme.primaryGreen, size: 12),
                SizedBox(width: 4.0),
                Text(
                  'Vendeur vérifié',
                  style: GoogleFonts.inter(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfo(ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_outline, color: AppTheme.primaryGreen, size: 18),
              SizedBox(width: 8.0),
              Text(
                'Paiement sécurisé',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.5),
          Text(
            'Votre paiement est sécurisé. WETIO utilise les réseaux Wave, Orange Money et Free Money pour garantir la sécurité de vos transactions.',
            style: GoogleFonts.inter(
              fontSize: 10,
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          SizedBox(height: 8.5),
          Row(
            children: [
              _buildBadge('0% commission', AppTheme.primaryGreen, colorScheme),
              SizedBox(width: 8.0),
              _buildBadge(
                  '100% sécurisé', AppTheme.primaryOrange, colorScheme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color color, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildErrorBanner(ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 18),
          SizedBox(width: 8.0),
          Expanded(
            child: Text(
              _paymentError,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Colors.red.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductSummary(ColorScheme colorScheme) {
    final String? imageUrl = _product['image'] as String?;
    final bool hasImage = imageUrl != null &&
        imageUrl.isNotEmpty &&
        (imageUrl.startsWith('http://') || imageUrl.startsWith('https://'));

    return Container(
      padding: EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: hasImage
                ? CustomImageWidget(
                    imageUrl: imageUrl,
                    width: 80.0,
                    height: 80.0,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 80.0,
                    height: 80.0,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryOrange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.shopping_bag_outlined,
                        color: AppTheme.primaryOrange, size: 32.0),
                  ),
          ),
          SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _product['title'] as String? ?? 'Produit',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.3),
                Text(
                  _product['condition'] as String? ?? 'Bon état',
                  style: GoogleFonts.inter(
                      fontSize: 10, color: colorScheme.onSurfaceVariant),
                ),
                SizedBox(height: 4.3),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 12, color: colorScheme.onSurfaceVariant),
                    SizedBox(width: 4.0),
                    Text(
                      _product['location'] as String? ?? 'Dakar',
                      style: GoogleFonts.inter(
                          fontSize: 10, color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
                SizedBox(height: 6.8),
                Text(
                  _formatPrice(_productPrice),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryOrange,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector(ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Quantité',
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: _decrementQuantity,
                child: Container(
                  width: 32.0,
                  height: 32.0,
                  decoration: BoxDecoration(
                    color: _quantity > 1
                        ? AppTheme.primaryOrange.withValues(alpha: 0.1)
                        : colorScheme.surfaceContainer,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _quantity > 1
                          ? AppTheme.primaryOrange
                          : colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(Icons.remove,
                      size: 16,
                      color: _quantity > 1
                          ? AppTheme.primaryOrange
                          : colorScheme.onSurfaceVariant),
                ),
              ),
              SizedBox(width: 16.0),
              Text('$_quantity',
                  style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface)),
              SizedBox(width: 16.0),
              GestureDetector(
                onTap: _incrementQuantity,
                child: Container(
                  width: 32.0,
                  height: 32.0,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryOrange.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primaryOrange),
                  ),
                  child:
                      Icon(Icons.add, size: 16, color: AppTheme.primaryOrange),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryOptions(ColorScheme colorScheme) {
    final options = [
      {
        'id': 'standard',
        'label': 'Livraison standard',
        'subtitle': '2-3 jours ouvrables',
        'price': 1500.0,
        'icon': Icons.local_shipping_outlined
      },
      {
        'id': 'express',
        'label': 'Livraison express',
        'subtitle': 'Aujourd\'hui ou demain',
        'price': 3000.0,
        'icon': Icons.bolt_outlined
      },
      {
        'id': 'pickup',
        'label': 'Retrait en main propre',
        'subtitle': 'Gratuit - Coordonner avec le vendeur',
        'price': 0.0,
        'icon': Icons.handshake_outlined
      },
    ];

    return Container(
      padding: EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mode de livraison',
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface)),
          SizedBox(height: 12.8),
          ...options.map((option) {
            final isSelected = _selectedDelivery == option['id'];
            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _selectedDelivery = option['id'] as String);
              },
              child: Container(
                margin: EdgeInsets.only(bottom: 8.5),
                padding: EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryOrange.withValues(alpha: 0.08)
                      : colorScheme.surfaceContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryOrange
                        : colorScheme.outline.withValues(alpha: 0.2),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(option['icon'] as IconData,
                        color: isSelected
                            ? AppTheme.primaryOrange
                            : colorScheme.onSurfaceVariant,
                        size: 22),
                    SizedBox(width: 12.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(option['label'] as String,
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? AppTheme.primaryOrange
                                      : colorScheme.onSurface)),
                          Text(option['subtitle'] as String,
                              style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    Text(
                      (option['price'] as double) == 0
                          ? 'Gratuit'
                          : _formatPrice(option['price'] as double),
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? AppTheme.primaryOrange
                              : colorScheme.onSurface),
                    ),
                    SizedBox(width: 8.0),
                    Container(
                      width: 20.0,
                      height: 20.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: isSelected
                                ? AppTheme.primaryOrange
                                : colorScheme.outline.withValues(alpha: 0.4),
                            width: 1.5),
                        color: isSelected
                            ? AppTheme.primaryOrange
                            : Colors.transparent,
                      ),
                      child: isSelected
                          ? Icon(Icons.check, size: 10, color: Colors.white)
                          : null,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Récapitulatif',
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface)),
          SizedBox(height: 12.8),
          _summaryRow(
              'Sous-total (x$_quantity)', _formatPrice(_subtotal), colorScheme),
          SizedBox(height: 8.5),
          _summaryRow(
              'Livraison',
              _deliveryFee == 0 ? 'Gratuit' : _formatPrice(_deliveryFee),
              colorScheme),
          SizedBox(height: 8.5),
          _summaryRow('Commission WETIO', '0 FCFA ✓', colorScheme,
              valueColor: AppTheme.primaryGreen),
          Divider(
              height: 25.5, color: colorScheme.outline.withValues(alpha: 0.2)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total',
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface)),
              Text(_formatPrice(_total),
                  style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryOrange)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, ColorScheme colorScheme,
      {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 12, color: colorScheme.onSurfaceVariant)),
        Text(
          value,
          style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: valueColor ?? colorScheme.onSurface),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildBottomBar(ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.0, 17.0, 16.0, 25.5),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
            top:
                BorderSide(color: colorScheme.outline.withValues(alpha: 0.15))),
        boxShadow: [
          BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -4))
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 55.3,
        child: ElevatedButton(
          onPressed: _isProcessing ? null : _processOrder,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryOrange,
            foregroundColor: Colors.white,
            elevation: 4,
            shadowColor: AppTheme.primaryOrange.withValues(alpha: 0.4),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: _isProcessing
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white)),
                    SizedBox(width: 12.0),
                    Text('Traitement en cours...',
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_cart_checkout,
                        size: 22, color: Colors.white),
                    SizedBox(width: 8.0),
                    Text(
                      'Payer • ${_formatPrice(_total)}',
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _launchPaymentApp(String method, String rawPhone, int amount) async {
    final cleanPhone = rawPhone.replaceAll(RegExp(r'\D'), '');
    final fullPhone = cleanPhone.startsWith('221') ? cleanPhone : '221$cleanPhone';

    // 1. Copy number to clipboard immediately
    await Clipboard.setData(ClipboardData(text: cleanPhone));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Numéro $cleanPhone copié ! Ouverture de $method...'),
          backgroundColor: AppTheme.primaryGreen,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    final isWave = method.toUpperCase().contains('WAVE');
    final isOrange = method.toUpperCase().contains('ORANGE') || method.toUpperCase().contains('OM');

    if (isWave) {
      final waveWebUrl = Uri.parse('https://wave.com/send?phone=%2B$fullPhone');
      final waveSchemeUrl = Uri.parse('wave://send?phone=%2B$fullPhone');

      try {
        if (await canLaunchUrl(waveSchemeUrl)) {
          await launchUrl(waveSchemeUrl, mode: LaunchMode.externalApplication);
          return;
        }
      } catch (_) {}

      try {
        if (await canLaunchUrl(waveWebUrl)) {
          await launchUrl(waveWebUrl, mode: LaunchMode.externalApplication);
          return;
        }
      } catch (_) {}

      final waveFallback = Uri.parse('https://pay.wave.com');
      if (await canLaunchUrl(waveFallback)) {
        await launchUrl(waveFallback, mode: LaunchMode.externalApplication);
      }
    } else if (isOrange) {
      final ussdCode = Uri.parse('tel:*144*1*1*$cleanPhone*${amount}%23');
      final fallbackUssd = Uri.parse('tel:*144%23');

      try {
        if (await canLaunchUrl(ussdCode)) {
          await launchUrl(ussdCode);
          return;
        }
      } catch (_) {}

      try {
        if (await canLaunchUrl(fallbackUssd)) {
          await launchUrl(fallbackUssd);
        }
      } catch (_) {}
    }
  }

  void _handlePaymentRedirect() {
    if (_sellerProfile == null) return;

    final method = _sellerProfile!['payout_method']?.toString().toUpperCase() ?? 'WAVE';
    final phone = _sellerProfile!['payout_phone']?.toString() ?? _sellerProfile!['phone']?.toString() ?? 'Inconnu';
    final amount = _total.toInt();
    final colorScheme = Theme.of(context).colorScheme;

    // Automatically trigger app launch & clipboard copy
    _launchPaymentApp(method, phone, amount);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.payments_outlined, color: AppTheme.primaryGreen),
            SizedBox(width: 8.0),
            const Text('Finaliser le paiement'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Le numéro $phone a été copié automatiquement. Vous pouvez ouvrir l\'application $method pour valider le virement.',
              style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[700]),
            ),
            SizedBox(height: 17.0),
            // Direct launch button inside modal
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _launchPaymentApp(method, phone, amount);
                },
                icon: Icon(method.contains('WAVE') ? Icons.open_in_new : Icons.phone, size: 18, color: Colors.white),
                label: Text('Ouvrir $method ($phone)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: method.contains('WAVE') ? const Color(0xFF1DC4FF) : Colors.orange,
                  padding: EdgeInsets.symmetric(vertical: 10.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            SizedBox(height: 17.0),
            Container(
              padding: EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  _paymentInfoRow('Montant', '$amount FCFA', isBold: true),
                  const Divider(),
                  _paymentInfoRow('Destinataire', _sellerProfile!['full_name'] ?? _sellerProfile!['pseudo'] ?? 'Vendeur'),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Numéro $method', style: TextStyle(fontSize: 9, color: Colors.grey)),
                          Text(phone, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 20),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: phone));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Numéro copié !'), duration: Duration(seconds: 1)),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 17.0),
            Text(
              'Note : Une fois le transfert effectué, le vendeur recevra une notification et préparera votre colis.',
              style: GoogleFonts.inter(fontSize: 10, fontStyle: FontStyle.italic, color: AppTheme.primaryOrange),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(context, AppRoutes.homeFeed, (route) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('J\'ai effectué le paiement', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _paymentInfoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
          Text(value, style: TextStyle(fontSize: 11, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }


  Widget _buildOrderConfirmation(ColorScheme colorScheme) {
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100.0,
                height: 100.0,
                decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                    shape: BoxShape.circle),
                child: Icon(Icons.check_circle_outline,
                    color: AppTheme.primaryGreen, size: 60.0),
              ),
              SizedBox(height: 25.5),
              Text(
                'Commande enregistrée !',
                style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12.8),
              Text(
                "Votre commande a été transmise au vendeur. Vous pouvez maintenant procéder au paiement via ${_sellerProfile?['payout_method'] ?? 'son service mobile money'}.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                  height: 1.5,
                ),
              ),
              SizedBox(height: 34.0),
              
              if (_sellerProfile != null) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _handlePaymentRedirect,
                    icon: const Icon(Icons.account_balance_wallet_outlined, color: Colors.white),
                    label: Text(
                      "Payer ${_total.toInt()} FCFA via ${_sellerProfile?['payout_method'] ?? 'Mobile Money'}",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      padding: EdgeInsets.symmetric(vertical: 17.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                SizedBox(height: 17.0),
              ],
              
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.homeFeed, (route) => false),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 17.0),
                    side: BorderSide(color: AppTheme.primaryGreen),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    "Retour à l'accueil",
                    style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SizedBox(height: 17.0),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Voir d\'autres produits',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryOrange,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _confirmationRow(
      IconData icon, String label, String value, ColorScheme colorScheme,
      {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryGreen),
        SizedBox(width: 8.0),
        Text('$label : ',
            style: GoogleFonts.inter(
                fontSize: 11, color: colorScheme.onSurfaceVariant)),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: valueColor ?? colorScheme.onSurface),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
