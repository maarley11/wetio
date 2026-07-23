import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ProductInfoSection extends StatelessWidget {
  final Map<String, dynamic> product;

  const ProductInfoSection({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 100.w,
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product title and category
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (product["title"] as String? ?? "Produit sans titre"),
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 8.5),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.5),
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.primary
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        (product["category"] as String? ?? "Autre"),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.lightTheme.colorScheme.primary,
                        ),
                      ),
                    ),
                    Builder(
                      builder: (context) {
                        final rawPrice = product['price'] ?? product['Price'] ?? product['amount'] ?? product['montant'];
                        if (rawPrice != null && rawPrice.toString() != 'null' && rawPrice.toString().isNotEmpty && rawPrice.toString() != '0') {
                          try {
                            double priceValue = 0;
                            if (rawPrice is num) {
                              priceValue = rawPrice.toDouble();
                            } else if (rawPrice is String) {
                              priceValue = double.tryParse(rawPrice.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
                            }
                            
                            if (priceValue > 0) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 12.8),
                                  Text(
                                    '${priceValue.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]} ")} FCFA',
                                    style: GoogleFonts.inter(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.primaryGreen,
                                    ),
                                  ),
                                ],
                              );
                            }
                          } catch (_) {}
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.5),
                decoration: BoxDecoration(
                  color: (product["isAvailable"] as bool? ?? true)
                      ? AppTheme.successGreen.withValues(alpha: 0.1)
                      : AppTheme.errorRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8.0,
                      height: 8.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (product["isAvailable"] as bool? ?? true)
                            ? AppTheme.successGreen
                            : AppTheme.errorRed,
                      ),
                    ),
                    SizedBox(width: 8.0),
                    Text(
                      (product["isAvailable"] as bool? ?? true)
                          ? "Disponible"
                          : "Échangé",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: (product["isAvailable"] as bool? ?? true)
                            ? AppTheme.successGreen
                            : AppTheme.errorRed,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 25.5),

          // Product variants (if applicable)
          if (product["variants"] != null &&
              (product["variants"] as List).isNotEmpty) ...[
            Text(
              "Variantes disponibles",
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 8.5),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.5,
              children: (product["variants"] as List).map<Widget>((variant) {
                final variantMap = variant as Map<String, dynamic>;
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.5),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "${variantMap["type"]}: ${variantMap["value"]}",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: colorScheme.onSurface,
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 25.5),
          ],

          // Condition and location
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "État",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 4.3),
                    Text(
                      (product["condition"] as String? ?? "Bon état"),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Localisation",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 4.3),
                    Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'location_on',
                          color: colorScheme.onSurfaceVariant,
                          size: 16,
                        ),
                        SizedBox(width: 4.0),
                        Expanded(
                          child: Text(
                            "${product["location"] ?? "Dakar"} • ${product["distance"] ?? "2.5"} km",
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
