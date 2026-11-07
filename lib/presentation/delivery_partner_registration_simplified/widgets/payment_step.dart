import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

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
  bool _isProcessing = false;

  void _activateFreeAccount() async {
    setState(() {
      _isProcessing = true;
    });

    HapticFeedback.mediumImpact();

    try {
      final success = await SupabaseService.registerAsDeliveryPartner();

      if (success && mounted) {
        widget.onComplete();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Erreur lors de l'activation du compte livreur."),
          ),
        );
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Inscription Gratuite',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8.5),
            Text(
              'L\'abonnement au service de livraison WETIO est désormais 100% gratuit. Aucun paiement n\'est requis.',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 34.0),

            // Free Amount Box
            Container(
              padding: const EdgeInsets.all(16.0),
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
                    'GRATUIT (0 FCFA)',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28.0),

            // Free Access Card
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.primaryGreen,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen.withAlpha(26),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.verified_outlined,
                              size: 28,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                          const SizedBox(width: 16.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Abonnement 100% Gratuit',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4.0),
                                Text(
                                  'Accès immédiat sans frais d\'inscription',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.check_circle,
                            color: AppTheme.primaryGreen,
                            size: 24,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16.0),
                      Text(
                        'Cliquez sur « Activer gratuitement » ci-dessous pour activer immédiatement votre profil livreur et recevoir les demandes de livraison autour de vous.',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          height: 1.5,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
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
                      padding: const EdgeInsets.symmetric(vertical: 17.0),
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
                const SizedBox(width: 16.0),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _activateFreeAccount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isProcessing
                          ? colorScheme.outline.withAlpha(77)
                          : AppTheme.primaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 17.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
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
                            'Activer gratuitement',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
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
}
