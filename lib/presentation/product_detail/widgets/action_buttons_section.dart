import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/two_line_text_widget.dart';

class ActionButtonsSection extends StatefulWidget {
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onShare;
  final VoidCallback? onReport;
  final VoidCallback? onPropose;
  final VoidCallback? onBuy;
  final bool isAvailable;
  final Map<String, dynamic>? product;

  const ActionButtonsSection({
    super.key,
    this.isFavorite = false,
    this.onFavoriteToggle,
    this.onShare,
    this.onReport,
    this.onPropose,
    this.onBuy,
    this.isAvailable = true,
    this.product,
  });

  @override
  State<ActionButtonsSection> createState() => _ActionButtonsSectionState();
}

class _ActionButtonsSectionState extends State<ActionButtonsSection> {
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.isFavorite;
  }

  void _toggleFavorite() {
    HapticFeedback.lightImpact();
    setState(() {
      _isFavorite = !_isFavorite;
    });
    if (widget.onFavoriteToggle != null) {
      widget.onFavoriteToggle!();
    }
  }

  void _handleShare() {
    HapticFeedback.lightImpact();
    if (widget.onShare != null) {
      widget.onShare!();
    }
  }

  void _handleReport() {
    HapticFeedback.lightImpact();
    if (widget.onReport != null) {
      widget.onReport!();
    }
  }

  void _handlePropose() {
    HapticFeedback.mediumImpact();
    if (widget.onPropose != null) {
      widget.onPropose!();
    } else {
      Navigator.pushNamed(
        context,
        AppRoutes.exchangeProposal,
        arguments: widget.product,
      );
    }
  }

  void _handleBuy() {
    HapticFeedback.mediumImpact();
    if (widget.onBuy != null) {
      widget.onBuy!();
    } else {
      Navigator.pushNamed(
        context,
        AppRoutes.productPurchase,
        arguments: widget.product,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 100.w,
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Secondary actions row removed per user request
          
          // Primary action buttons row: Proposer + Acheter
          Row(
            children: [
              // Proposer button
              Expanded(
                child: SizedBox(
                  height: 59.5,
                  child: ElevatedButton(
                    onPressed: widget.isAvailable ? _handlePropose : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.isAvailable
                          ? AppTheme.primaryOrange.withOpacity(0.85)
                          : colorScheme.onSurfaceVariant.withOpacity(0.3),
                      foregroundColor: widget.isAvailable
                          ? Colors.white
                          : colorScheme.onSurfaceVariant,
                      elevation: widget.isAvailable ? 3 : 0,
                      shadowColor: AppTheme.primaryOrange.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomIconWidget(
                          iconName: widget.isAvailable ? 'swap_horiz' : 'block',
                          color: widget.isAvailable
                              ? Colors.white
                              : colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        SizedBox(width: 8.0),
                        Text(
                          'Proposer',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: widget.isAvailable
                                ? Colors.white
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(width: 12.0),

              // Acheter button
              Expanded(
                child: SizedBox(
                  height: 59.5,
                  child: ElevatedButton(
                    onPressed: widget.isAvailable ? _handleBuy : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.isAvailable
                          ? AppTheme.primaryGreen
                          : colorScheme.onSurfaceVariant.withOpacity(0.3),
                      foregroundColor: widget.isAvailable
                          ? Colors.white
                          : colorScheme.onSurfaceVariant,
                      elevation: widget.isAvailable ? 3 : 0,
                      shadowColor: AppTheme.primaryGreen.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomIconWidget(
                          iconName: widget.isAvailable
                              ? 'shopping_cart'
                              : 'block',
                          color: widget.isAvailable
                              ? Colors.white
                              : colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        SizedBox(width: 8.0),
                        Text(
                          'Acheter',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: widget.isAvailable
                                ? Colors.white
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
