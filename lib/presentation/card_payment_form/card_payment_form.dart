import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import './widgets/payment_summary_widget.dart';
import './widgets/card_input_form_widget.dart';
import './widgets/card_display_widget.dart';
import './widgets/validation_indicators_widget.dart';

class CardPaymentFormScreen extends StatefulWidget {
  const CardPaymentFormScreen({Key? key}) : super(key: key);

  @override
  State<CardPaymentFormScreen> createState() => _CardPaymentFormScreenState();
}

class _CardPaymentFormScreenState extends State<CardPaymentFormScreen>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  // Form controllers
  final _cardNumberController = TextEditingController();
  final _expirationController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardholderController = TextEditingController();

  // Form state
  final _formKey = GlobalKey<FormState>();
  bool _isProcessing = false;
  String _cardType = '';
  String? _errorMessage;

  // Payment package details
  final int _tokensAmount = 100;
  final int _priceInFcfa = 1000;

  // Get package data from arguments
  Map<String, dynamic>? _packageArgs;
  Map<String, dynamic>? _selectedPackage;
  int _currentTokenBalance = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Get arguments passed from previous screen
    _packageArgs =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (_packageArgs != null) {
      _selectedPackage = _packageArgs!['selectedPackage'];
      _currentTokenBalance = _packageArgs!['currentBalance'] ?? 0;
    }

    // Set default package if none provided
    if (_selectedPackage == null) {
      _selectedPackage = {
        'tokens': 100,
        'price': 1000,
      };
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    // Start animations
    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _cardNumberController.dispose();
    _expirationController.dispose();
    _cvvController.dispose();
    _cardholderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Payment Summary Section
                  PaymentSummaryWidget(
                    tokenAmount: _selectedPackage?['tokens'] ?? 100,
                    price: _selectedPackage?['price'] ?? 1000,
                    currentBalance: _currentTokenBalance,
                  ),

                  SizedBox(height: 32),

                  // Card Display Widget
                  CardDisplayWidget(
                    cardNumber: _cardNumberController.text,
                    cardholderName: _cardholderController.text,
                    expirationDate: _expirationController.text,
                    cvv: _cvvController.text,
                    cardType: _cardType,
                  ),

                  SizedBox(height: 32),

                  // Main Form Section Title
                  Text(
                    'Informations de votre carte',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),

                  SizedBox(height: 4),

                  Text(
                    'Saisissez vos informations bancaires de manière sécurisée',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),

                  SizedBox(height: 24),

                  // Card Input Form
                  CardInputFormWidget(
                    cardNumberController: _cardNumberController,
                    expirationController: _expirationController,
                    cvvController: _cvvController,
                    cardholderController: _cardholderController,
                    onCardNumberChanged: _handleCardNumberChange,
                    onFieldChanged: () => setState(() {}),
                  ),

                  SizedBox(height: 24),

                  // Validation Indicators
                  ValidationIndicatorsWidget(),

                  SizedBox(height: 20),

                  // Error Message
                  if (_errorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      margin: EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        border: Border.all(color: Colors.red[200]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline,
                              color: Colors.red, size: 20),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: GoogleFonts.inter(
                                color: Colors.red[800],
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Action Buttons
                  _buildActionButtons(),

                  SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      leading: IconButton(
        icon: Icon(Icons.close, color: Colors.black87, size: 24),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          Text(
            'Paiement sécurisé',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          Spacer(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.security, color: Colors.green[700], size: 14),
                SizedBox(width: 4),
                Text(
                  'SSL',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.green[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Cancel Button
        Expanded(
          flex: 2,
          child: OutlinedButton(
            onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: Colors.grey[400]!),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Annuler',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
        ),

        SizedBox(width: 16),

        // Confirm Payment Button
        Expanded(
          flex: 3,
          child: ElevatedButton(
            onPressed: _isProcessing || !_isFormValid() ? null : _handlePayment,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[300],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isProcessing
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Traitement...',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : Text(
                    'Confirmer le paiement',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  void _handleCardNumberChange(String value) {
    setState(() {
      // Format card number with spaces
      String formatted = _formatCardNumber(value);
      if (formatted != _cardNumberController.text) {
        _cardNumberController.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }

      // Detect card type
      _cardType = _detectCardType(value);

      // Clear error when user types
      if (_errorMessage != null) {
        _errorMessage = null;
      }
    });
  }

  String _formatCardNumber(String value) {
    value = value.replaceAll(' ', '');
    String formatted = '';
    for (int i = 0; i < value.length; i += 4) {
      if (i + 4 <= value.length) {
        formatted += value.substring(i, i + 4) + ' ';
      } else {
        formatted += value.substring(i);
      }
    }
    return formatted.trim();
  }

  String _detectCardType(String cardNumber) {
    cardNumber = cardNumber.replaceAll(' ', '');

    if (cardNumber.startsWith('4')) {
      return 'visa';
    } else if (cardNumber.startsWith('5') ||
        (cardNumber.length >= 2 &&
            int.tryParse(cardNumber.substring(0, 2)) != null &&
            int.parse(cardNumber.substring(0, 2)) >= 51 &&
            int.parse(cardNumber.substring(0, 2)) <= 55)) {
      return 'mastercard';
    } else if (cardNumber.startsWith('34') || cardNumber.startsWith('37')) {
      return 'amex';
    }
    return '';
  }

  bool _isFormValid() {
    return _cardNumberController.text.replaceAll(' ', '').length >= 16 &&
        _expirationController.text.length == 5 &&
        _cvvController.text.length >= 3 &&
        _cardholderController.text.isNotEmpty;
  }

  Future<void> _handlePayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // Simulate payment processing
      await Future.delayed(Duration(seconds: 2));

      // Simulate payment success
      bool paymentSuccess =
          true; // In real implementation, this would be the actual payment result

      if (paymentSuccess) {
        _showPaymentSuccessDialog();
      } else {
        throw Exception('Payment failed');
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            'Erreur lors du traitement du paiement. Veuillez vérifier vos informations et réessayer.';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showPaymentSuccessDialog() {
    // First show success notification
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green[600],
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Text(
              'Paiement effectué avec succès !',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
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

    // Then show success dialog
    Future.delayed(Duration(milliseconds: 300), () {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            contentPadding: EdgeInsets.all(24),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success Animation
                TweenAnimationBuilder(
                  duration: Duration(milliseconds: 800),
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  builder: (context, double value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.green[600],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    );
                  },
                ),

                SizedBox(height: 24),

                // Success Title
                Text(
                  'Paiement effectué avec succès !',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),

                SizedBox(height: 12),

                // Success Message
                Text(
                  'Vos jetons vont arriver dans quelques instants.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),

                SizedBox(height: 24),

                // Transaction Summary
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Column(
                    children: [
                      _buildSummaryRow(
                          'Jetons achetés', '$_tokensAmount jetons'),
                      Divider(height: 16, color: Colors.green[200]),
                      _buildSummaryRow('Montant payé', '$_priceInFcfa FCFA'),
                      Divider(height: 16, color: Colors.green[200]),
                      _buildSummaryRow('Statut', 'Confirmé ✓', isStatus: true),
                    ],
                  ),
                ),

                SizedBox(height: 24),

                // Celebration Message
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '🎉 Félicitations ! Vos jetons seront disponibles très bientôt !',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.blue[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(); // Close dialog
                    Navigator.of(context).pop(); // Return to previous screen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Continuer',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    });
  }

  Widget _buildSummaryRow(String label, String value, {bool isStatus = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isStatus ? Colors.green[700] : Colors.black87,
          ),
        ),
      ],
    );
  }
}
