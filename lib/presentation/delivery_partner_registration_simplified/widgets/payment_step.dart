import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../services/supabase_service.dart';
import '../../../core/app_export.dart';

class PaymentStep extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback onPrevious;

  const PaymentStep({
    super.key,
    required this.onComplete,
    required this.onPrevious,
  });

  @override
  State<PaymentStep> createState() => _PaymentStepState();
}

class _PaymentStepState extends State<PaymentStep> {
  String _selectedPaymentMethod = 'wave';
  bool _isProcessing = false;

  void _processPayment() async {
    if (_selectedPaymentMethod != 'wave') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez utiliser Wave pour le moment.")),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    HapticFeedback.mediumImpact();

    try {
      // 1. Launch Official Wave Checkout Link
      final waveUrl = 'https://pay.wave.com/m/M_sn_F7IKNV0jou_P/c/sn/';
      final uri = Uri.parse(waveUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        
        // Show confirmation that we're waiting for payment
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Redirection vers Wave... Validez le paiement pour activer votre compte."),
              backgroundColor: AppTheme.primaryGreen,
            ),
          );
        }

        // 2. Register as delivery partner in database (simulate activation)
        // In a real production app, this would be handled by a Wave webhook.
        final success = await SupabaseService.registerAsDeliveryPartner();

        if (success && mounted) {
          widget.onComplete();
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Erreur lors de l'activation du compte livreur.")),
          );
        }
      } else {
        throw Exception("Impossible d'ouvrir le lien Wave.");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Une erreur est survenue: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: colorScheme.surface,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Paiement',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 8.5),
            Text(
              'Payez 2000 FCFA pour 1 mois d\'accès au service de livraison.',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
            SizedBox(height: 34.0),

            // Payment Amount
            Container(
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withAlpha(26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Montant total',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    '2000 FCFA',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 34.0),

            // Payment Methods
            Text(
              'Méthode de paiement',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 17.0),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildPaymentMethodCard(
                      method: 'wave',
                      title: 'Wave',
                      description: 'Paiement mobile Wave',
                      icon: 'account_balance_wallet',
                    ),
                    SizedBox(height: 17.0),
                    _buildPaymentMethodCard(
                      method: 'orange_money',
                      title: 'Orange Money',
                      description: 'Paiement mobile Orange',
                      icon: 'payment',
                    ),
                    SizedBox(height: 17.0),
                    _buildPaymentMethodCard(
                      method: 'free_money',
                      title: 'Free Money',
                      description: 'Paiement mobile Free',
                      icon: 'account_balance',
                    ),
                  ],
                ),
              ),
            ),

            // Navigation Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isProcessing
                        ? null
                        : () {
                            HapticFeedback.lightImpact();
                            widget.onPrevious();
                          },
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 17.0),
                      side: BorderSide(
                        color: _isProcessing
                            ? colorScheme.outline.withAlpha(77)
                            : AppTheme.primaryGreen,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Retour',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _isProcessing
                            ? AppTheme.textSecondary
                            : AppTheme.primaryGreen,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16.0),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _processPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isProcessing
                          ? colorScheme.outline.withAlpha(77)
                          : AppTheme.primaryGreen,
                      padding: EdgeInsets.symmetric(vertical: 17.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isProcessing
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            'Payer',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard({
    required String method,
    required String title,
    required String description,
    required String icon,
  }) {
    final isSelected = _selectedPaymentMethod == method;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedPaymentMethod = method;
        });
      },
      child: Container(
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected ? AppTheme.primaryGreen : Colors.grey.withAlpha(51),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryGreen.withAlpha(26)
                    : Colors.grey.withAlpha(26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: CustomIconWidget(
                iconName: icon,
                size: 32,
                color:
                    isSelected ? AppTheme.primaryGreen : AppTheme.textSecondary,
              ),
            ),
            SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4.3),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              CustomIconWidget(
                iconName: 'check_circle',
                size: 24,
                color: AppTheme.primaryGreen,
              ),
          ],
        ),
      ),
    );
  }
}
