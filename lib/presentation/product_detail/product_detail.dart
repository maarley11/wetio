
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../exchange_proposal/widgets/target_product_card.dart';

class ProductDetail extends StatefulWidget {
  const ProductDetail({super.key});

  @override
  State<ProductDetail> createState() => _ProductDetailState();
}

class _ProductDetailState extends State<ProductDetail> {
  Map<String, dynamic>? _productData;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_productData == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        setState(() {
          _productData = args;
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_hasError || _productData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Erreur")),
        body: Center(child: Text("Produit non trouvé")),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context, theme, colorScheme),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Informations du produit",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 17.0),
                    // TargetProductCard design
                    TargetProductCard(targetProduct: _productData!),
                    SizedBox(height: 25.5),

                    // Seller Information Section
                    if (_productData!["owner"] != null) ...[
                      Text(
                        "Informations du vendeur",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 12.8),
                      _buildSellerInfoCard(context, theme, colorScheme),
                    ],
                    SizedBox(height: 34.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActions(context, theme, colorScheme),
    );
  }

  Widget _buildSellerInfoCard(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    final owner = _productData!["owner"] as Map<String, dynamic>;
    final registrationPhone = owner["phone"]?.toString() ?? "";
    final payoutPhone = owner["payout_phone"]?.toString() ?? "";
    final payoutMethod = owner["payout_method"]?.toString() ?? "Paiement";

    // Deduplication logic
    final bool hasRegistrationPhone = registrationPhone.isNotEmpty;
    final bool hasPayoutPhone = payoutPhone.isNotEmpty;
    final bool phonesAreIdentical = hasRegistrationPhone && 
                                    hasPayoutPhone && 
                                    registrationPhone.replaceAll(RegExp(r'\s+'), '') == 
                                    payoutPhone.replaceAll(RegExp(r'\s+'), '');

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar or Icon
          Container(
            width: 48.0,
            height: 48.0,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: owner["avatar_url"] != null && owner["avatar_url"].toString().isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        owner["avatar_url"],
                        width: 48.0,
                        height: 48.0,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Icon(Icons.person, color: AppTheme.primaryGreen, size: 24.0),
            ),
          ),
          SizedBox(width: 16.0),
          // Name and Phone
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  owner["full_name"] ?? owner["pseudo"] ?? "Vendeur",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 4.3),
                if (phonesAreIdentical) ...[
                  Row(
                    children: [
                      Icon(Icons.phone_android, size: 14, color: AppTheme.primaryGreen),
                      SizedBox(width: 4.0),
                      Expanded(
                        child: Text(
                          "Contact & $payoutMethod : $registrationPhone",
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  if (hasRegistrationPhone)
                    Row(
                      children: [
                        Icon(Icons.phone, size: 14, color: AppTheme.primaryGreen),
                        SizedBox(width: 4.0),
                        Expanded(
                          child: Text(
                            "Contact : $registrationPhone",
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (hasPayoutPhone) ...[
                    if (hasRegistrationPhone) SizedBox(height: 1.7),
                    Row(
                      children: [
                        Icon(Icons.payments_outlined, size: 14, color: AppTheme.primaryOrange),
                        SizedBox(width: 4.0),
                        Expanded(
                          child: Text(
                            "$payoutMethod : $payoutPhone",
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                              color: AppTheme.primaryOrange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
          // Contact badge/icon
          Container(
            padding: EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.verified_user, color: AppTheme.primaryGreen, size: 20.0),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(bottom: BorderSide(color: colorScheme.outline.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          SizedBox(width: 8.0),
          Text(
            "Détails du produit",
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.0, 17.0, 16.0, 34.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Wetio Button (Exchange)
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.exchangeProposal,
                  arguments: _productData,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange.withOpacity(0.1),
                foregroundColor: AppTheme.primaryOrange,
                elevation: 0,
                padding: EdgeInsets.symmetric(vertical: 12.8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppTheme.primaryOrange.withOpacity(0.3)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.handshake_outlined, size: 20),
                  SizedBox(width: 8.0),
                  Text(
                    "Wetio",
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 16.0),
          // Acheter Button
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.productPurchase,
                  arguments: _productData,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                elevation: 2,
                padding: EdgeInsets.symmetric(vertical: 12.8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_cart_outlined, size: 20),
                  SizedBox(width: 8.0),
                  Text(
                    "Acheter",
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
