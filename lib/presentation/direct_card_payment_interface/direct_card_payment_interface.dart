import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/token_service.dart';
import './widgets/card_preview_widget.dart';
import './widgets/payment_form_widget.dart';
import './widgets/security_indicators_widget.dart';
import './widgets/token_package_summary_widget.dart';

class DirectCardPaymentInterface extends StatefulWidget {
  const DirectCardPaymentInterface({Key? key}) : super(key: key);

  @override
  State<DirectCardPaymentInterface> createState() =>
      _DirectCardPaymentInterfaceState();
}

class _DirectCardPaymentInterfaceState extends State<DirectCardPaymentInterface>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Form and payment state
  bool _isProcessingPayment = false;
  String? _errorMessage;
  String? _successMessage;
  bool _isCardComplete = false;

  // Default token package (100 tokens for 1000 FCFA)
  final int _tokensToPurchase = 100;
  final int _priceInFcfa = 1000;

  // Controllers for billing information
  final _nameController = TextEditingController(text: 'Utilisateur WETIO');
  final _emailController = TextEditingController(text: 'user@wetio.com');
  final _phoneController = TextEditingController(text: '+221 77 123 45 67');

  // Card form key
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              'Paiement par carte',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
            Spacer(),
            // Security indicator
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.security, color: Colors.green, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Sécurisé',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.green[800],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: Icon(Icons.close, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Token Package Summary
                TokenPackageSummaryWidget(
                  tokens: _tokensToPurchase,
                  priceInFcfa: _priceInFcfa,
                ),
                SizedBox(height: 24),

                // Card Preview
                CardPreviewWidget(
                  isProcessing: _isProcessingPayment,
                ),
                SizedBox(height: 24),

                // Payment Form Section
                Text(
                  'Informations de paiement',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 12),

                PaymentFormWidget(
                  nameController: _nameController,
                  emailController: _emailController,
                  phoneController: _phoneController,
                  onCardChanged: (isComplete) {
                    setState(() {
                      _isCardComplete = isComplete;
                      // Clear error messages when user types
                      if (_errorMessage != null) {
                        _errorMessage = null;
                      }
                    });
                  },
                ),
                SizedBox(height: 24),

                // Security Indicators
                SecurityIndicatorsWidget(),
                SizedBox(height: 24),

                // Error/Success Messages
                if (_errorMessage != null)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    margin: EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      border: Border.all(color: Colors.red[200]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.error, color: Colors.red, size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: GoogleFonts.inter(
                              color: Colors.red[800],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                if (_successMessage != null)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    margin: EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      border: Border.all(color: Colors.green[200]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _successMessage!,
                            style: GoogleFonts.inter(
                              color: Colors.green[800],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Payment Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isProcessingPayment || !_isCardComplete
                        ? null
                        : _handlePayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[300],
                      disabledForegroundColor: Colors.grey[600],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isProcessingPayment
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Traitement sécurisé en cours...',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            'Confirmer le paiement - $_priceInFcfa FCFA',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                SizedBox(height: 16),

                // Estimated completion time
                if (_isProcessingPayment)
                  Center(
                    child: Text(
                      'Temps estimé: 5-10 secondes',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),

                SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handlePayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isProcessingPayment = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      // Create payment intent
      final paymentIntentResponse =
          await TokenService.instance.createTokenPurchaseIntent(
        tokensToPurchase: _tokensToPurchase,
        amountFcfa: _priceInFcfa,
      );

      // Confirm token purchase in backend
      final confirmResult = await TokenService.instance.confirmTokenPurchase(
          paymentIntentResponse['payment_intent_id'] ?? '');

      if (confirmResult['success'] == true) {
        setState(() {
          _successMessage = 'Paiement effectué avec succès !';
        });
        _showSuccessNotification();
      } else {
        throw Exception(
            confirmResult['error'] ?? 'Erreur de confirmation du paiement');
      }
    } catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e.toString());
      });
    } finally {
      setState(() {
        _isProcessingPayment = false;
      });
    }
  }

  String _getErrorMessage(String error) {
    if (error.contains('card_declined')) {
      return 'Votre carte a été refusée. Veuillez vérifier vos informations.';
    } else if (error.contains('insufficient_funds')) {
      return 'Fonds insuffisants sur votre carte.';
    } else if (error.contains('expired_card')) {
      return 'Votre carte a expiré. Utilisez une carte valide.';
    } else if (error.contains('incorrect_cvc')) {
      return 'Le code CVC est incorrect.';
    } else if (error.contains('processing_error')) {
      return 'Erreur de traitement. Veuillez réessayer.';
    } else if (error.contains('network')) {
      return 'Problème de connexion. Vérifiez votre internet.';
    } else {
      return 'Une erreur est survenue. Veuillez réessayer.';
    }
  }

  void _showSuccessNotification() {
    // Show snackbar first
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green,
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Text(
              'Paiement effectué avec succès !',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );

    // Then show success dialog with celebration animation
    Future.delayed(Duration(milliseconds: 500), () {
      _showSuccessDialog();
    });
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Column(
            children: [
              // Success animation
              TweenAnimationBuilder(
                duration: Duration(milliseconds: 600),
                tween: Tween<double>(begin: 0.0, end: 1.0),
                builder: (context, double value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 16),
              Text(
                'Paiement réussi !',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Votre paiement a été effectué avec succès et vos jetons vont arriver.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 20),

              // Transaction details
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  children: [
                    _buildDetailRow(
                        'Jetons achetés', '$_tokensToPurchase jetons'),
                    SizedBox(height: 8),
                    _buildDetailRow('Montant payé', '$_priceInFcfa FCFA'),
                    SizedBox(height: 8),
                    _buildDetailRow('Statut', 'Confirmé', isStatus: true),
                  ],
                ),
              ),

              SizedBox(height: 16),

              Text(
                '🎉 Vos jetons seront disponibles dans quelques instants !',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.green[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Return to previous screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Continuer',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isStatus = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isStatus ? Colors.green[700] : Colors.black87,
          ),
        ),
      ],
    );
  }
}
