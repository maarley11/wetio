import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/token_service.dart';
import '../../services/supabase_service.dart';
import './widgets/payment_methods_section.dart';
import './widgets/purchase_package_card.dart';
import './widgets/token_benefits_section.dart';

class TokenPurchaseScreen extends StatefulWidget {
  const TokenPurchaseScreen({Key? key}) : super(key: key);

  @override
  State<TokenPurchaseScreen> createState() => _TokenPurchaseScreenState();
}

class _TokenPurchaseScreenState extends State<TokenPurchaseScreen> {
  bool _isProcessingPayment = false;
  int _currentTokenBalance = 0;
  String? _errorMessage;
  String? _successMessage;
  bool _isLoading = true;
  String _selectedPaymentMethod = 'wave';

  // Wave Business phone number
  static const String _waveBusinessNumber = '70 766 15 02';

  // Token package options
  final List<TokenPackage> _packages = [
    TokenPackage(
      tokens: 30,
      price: 1000,
      isPopular: true,
      savings: 0,
      label: '3 produits',
    ),
    TokenPackage(
      tokens: 100,
      price: 3000,
      isPopular: false,
      savings: 333,
      label: '10 produits',
    ),
    TokenPackage(
      tokens: 250,
      price: 6500,
      isPopular: false,
      savings: 1000,
      label: '25 produits',
    ),
    TokenPackage(
      tokens: 500,
      price: 11000,
      isPopular: false,
      savings: 3000,
      label: '50 produits',
    ),
  ];

  TokenPackage _selectedPackage = TokenPackage(
    tokens: 30,
    price: 1000,
    isPopular: true,
    savings: 0,
    label: '3 produits',
  );

  @override
  void initState() {
    super.initState();
    _loadCurrentBalance();
  }

  Future<void> _loadCurrentBalance() async {
    try {
      final balance = await TokenService.instance.getCurrentTokenBalance();
      setState(() {
        _currentTokenBalance = balance;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement du solde: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Acheter des jetons',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF1E88E5)))
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current Balance Header
                  _buildCurrentBalanceCard(),
                  SizedBox(height: 24),

                  // Token Benefits
                  TokenBenefitsSection(),
                  SizedBox(height: 24),

                  // Package Selection
                  Text(
                    'Choisissez votre package',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 16),

                  // Package Cards
                  Column(
                    children: _packages.map((package) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: PurchasePackageCard(
                          package: package,
                          isSelected: package == _selectedPackage,
                          onTap: () {
                            setState(() {
                              _selectedPackage = package;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),

                  SizedBox(height: 24),

                  // Payment Methods (Wave only)
                  PaymentMethodsSection(
                    onPaymentMethodChanged: (method) {
                      setState(() {
                        _selectedPaymentMethod = method;
                      });
                    },
                  ),

                  SizedBox(height: 24),

                  // Messages
                  if (_successMessage != null)
                    Container(
                      padding: EdgeInsets.all(12),
                      margin: EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        border: Border.all(color: Colors.green[200]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _successMessage!,
                                  style: TextStyle(color: Colors.green[800]),
                                ),
                              ),
                            ],
                          ),
                          if (_successMessage!.contains('Wave'))
                            Padding(
                              padding: const EdgeInsets.only(top: 12.0),
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  launchUrl(Uri.parse('https://pay.wave.com/m/M_sn_F7IKNV0jou_P/c/sn/'), mode: LaunchMode.externalApplication);
                                },
                                icon: Icon(Icons.open_in_new),
                                label: Text('Ouvrir Wave manuellement'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  minimumSize: Size(double.infinity, 45),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                  if (_errorMessage != null)
                    Container(
                      padding: EdgeInsets.all(12),
                      margin: EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        border: Border.all(color: Colors.red[200]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.error, color: Colors.red, size: 16),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(color: Colors.red[800]),
                                ),
                              ),
                            ],
                          ),
                          if (_errorMessage!.contains('bloquée'))
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0, left: 24.0),
                              child: TextButton(
                                onPressed: () {
                                  launchUrl(Uri.parse('https://pay.wave.com/m/M_sn_F7IKNV0jou_P/c/sn/'), mode: LaunchMode.externalApplication);
                                },
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.red[100],
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                                child: Text(
                                  'Cliquer ici pour payer sur Wave',
                                  style: TextStyle(color: Colors.red[900], fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                  // Purchase Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed:
                          _isProcessingPayment ? null : _handleWavePayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF1E88E5),
                        foregroundColor: Colors.white,
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
                                Text('Redirection vers Wave...'),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.phone_android, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Payer ${_selectedPackage.price} FCFA avec Wave',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  SizedBox(height: 16),

                  // Wave Instructions
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xFF1E88E5).withAlpha(13),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Color(0xFF1E88E5).withAlpha(51),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Color(0xFF1E88E5),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Instructions de paiement',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E88E5),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          '1. Appuyez sur le bouton "Payer avec Wave"\n'
                          '2. Vous serez redirigé vers l\'application Wave\n'
                          '3. Le montant (${_selectedPackage.price} FCFA) sera pré-rempli\n'
                          '4. Validez le paiement dans Wave\n'
                          '5. Vos jetons seront ajoutés automatiquement',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16),

                  // Security info
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.security, color: Colors.green, size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Paiement 100% sécurisé par Wave. Vos informations financières sont protégées.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.green[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCurrentBalanceCard() {
    final balanceColor = TokenService.getBalanceColor(_currentTokenBalance);
    final statusMessage = TokenService.getBalanceStatusMessage(
      _currentTokenBalance,
    );

    Color backgroundColor;
    Color textColor;
    Color iconColor;

    switch (balanceColor) {
      case TokenBalanceColor.green:
        backgroundColor = Colors.green[50]!;
        textColor = Colors.green[800]!;
        iconColor = Colors.green;
        break;
      case TokenBalanceColor.orange:
        backgroundColor = Colors.orange[50]!;
        textColor = Colors.orange[800]!;
        iconColor = Colors.orange;
        break;
      case TokenBalanceColor.red:
        backgroundColor = Colors.red[50]!;
        textColor = Colors.red[800]!;
        iconColor = Colors.red;
        break;
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.account_balance_wallet, color: iconColor, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'Votre solde actuel',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.refresh, color: iconColor, size: 20),
                onPressed: _loadCurrentBalance,
                tooltip: 'Actualiser le solde',
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            '$_currentTokenBalance jetons',
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          SizedBox(height: 4),
          Text(
            statusMessage,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: textColor.withAlpha(204),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleWavePayment() async {
    setState(() {
      _isProcessingPayment = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      // 1. Create a real purchase intent on the backend
      final intentResult = await TokenService.instance.createTokenPurchaseIntent(
        tokensToPurchase: _selectedPackage.tokens,
        amountFcfa: _selectedPackage.price,
        paymentMethod: _selectedPaymentMethod,
      );

      if (intentResult['success'] != true && _selectedPaymentMethod != 'wave') {
        throw Exception(intentResult['error'] ?? 'Échec de l\'initialisation du paiement');
      }

      final String? paymentIntentId = intentResult['payment_intent_id'] ?? 
          (_selectedPaymentMethod == 'wave' ? 'WAVE_FB_${DateTime.now().millisecondsSinceEpoch}_${SupabaseService.instance.client.auth.currentUser?.id.substring(0, 5)}' : null);
          
      final String? waveUrl = intentResult['payment_url'] ?? intentResult['wave_url'] ?? 
          (_selectedPaymentMethod == 'wave' ? _generateWavePaymentUrl(
            phoneNumber: _waveBusinessNumber,
            amount: _selectedPackage.price,
            description: '${_selectedPackage.tokens} jetons WETIO',
          ) : null);

      // If intentResult failed but it's Wave, we create the record ourselves here as a fallback
      if (intentResult['success'] != true && _selectedPaymentMethod == 'wave' && paymentIntentId != null) {
        try {
          final client = SupabaseService.instance.client;
          await client.from('payment_transactions').insert({
            'user_id': client.auth.currentUser?.id,
            'payment_intent_id': paymentIntentId,
            'amount_fcfa': _selectedPackage.price,
            'tokens_purchased': _selectedPackage.tokens,
            'payment_status': 'awaiting_verification',
            'payment_method': 'wave'
          });
          debugPrint('Transaction created via client fallback');
        } catch (e) {
          debugPrint('Failed to create fallback transaction: $e');
        }
      }

      if (waveUrl == null) {
        throw Exception('URL de paiement non générée');
      }

      // 1.5 Force status update to awaiting_verification
      if (_selectedPaymentMethod == 'wave' && paymentIntentId != null) {
        try {
          await SupabaseService.instance.client
              .from('payment_transactions')
              .update({'payment_status': 'awaiting_verification'})
              .eq('payment_intent_id', paymentIntentId);
        } catch (_) {}
      }

      // 2. Launch Wave URL
      final uri = Uri.parse(waveUrl);
      
      // On Web, Safari and others block popups triggered after an await.
      // We try to launch, and if it's blocked, we show a manual link.
      try {
        // Use platformDefault which is better for Web (usually opens in new tab)
        await launchUrl(uri, mode: LaunchMode.platformDefault);
        
        setState(() {
          _successMessage = 'Redirection vers Wave... Veuillez valider le paiement.';
        });

        // 3. Start polling for confirmation if we have an ID
        if (paymentIntentId != null) {
          _startPaymentVerification(paymentIntentId);
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Redirection bloquée par le navigateur. Cliquez ci-dessous pour payer.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur: ${e.toString().replaceFirst('Exception: ', '')}';
      });
    } finally {
      setState(() {
        _isProcessingPayment = false;
      });
    }
  }

  void _startPaymentVerification(String paymentIntentId) {
    int attempts = 0;
    const maxAttempts = 12; // 1 minute (12 * 5s)
    
    Future.doWhile(() async {
      attempts++;
      if (attempts > maxAttempts) return false;
      
      await Future.delayed(const Duration(seconds: 5));
      
      if (!mounted) return false;
      
      try {
        final result = await TokenService.instance.confirmTokenPurchase(paymentIntentId);
        if (result['success'] == true) {
          _onPaymentConfirmed(result);
          return false; // Stop polling
        }
      } catch (e) {
        debugPrint('Polling error: $e');
      }
      
      return true; // Continue polling
    });
  }

  void _onPaymentConfirmed(Map<String, dynamic> result) {
    final status = result['status'];
    final message = result['message'];
    
    setState(() {
      if (status == 'completed') {
        _currentTokenBalance = result['new_balance'] ?? (_currentTokenBalance + _selectedPackage.tokens);
        _successMessage = 'Paiement validé ! ${_selectedPackage.tokens} jetons ajoutés.';
        _showSuccessDialog();
      } else {
        // For Wave, if it's not completed, it's awaiting verification (fallback for old backend)
        _successMessage = message ?? 'Paiement en attente de validation par l\'administrateur.';
        _showAwaitingVerificationDialog();
      }
    });
    _loadCurrentBalance(); // Refresh real balance from DB
  }

  void _showAwaitingVerificationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.hourglass_empty, color: Colors.orange, size: 28),
              SizedBox(width: 12),
              Text(
                'Paiement en attente',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Votre paiement Wave a bien été enregistré. Il est actuellement en cours de vérification par notre équipe.',
                style: GoogleFonts.inter(),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Les jetons seront ajoutés à votre compte dès que nous aurons reçu la confirmation de Wave (Généralement moins de 5 min).',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.orange[800],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Return to previous screen
              },
              child: Text(
                'Fermer',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  String _generateWavePaymentUrl({
    required String phoneNumber,
    required int amount,
    required String description,
  }) {
    // Official Wave Checkout Link provided by user
    return 'https://pay.wave.com/m/M_sn_F7IKNV0jou_P/c/sn/';
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
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 12),
              Text(
                'Achat réussi !',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vos jetons ont été ajoutés avec succès à votre compte via Wave.',
                style: GoogleFonts.inter(),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jetons achetés: ${_selectedPackage.tokens}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Nouveau solde: $_currentTokenBalance jetons',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Montant payé: ${_selectedPackage.price} FCFA via Wave',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Return to previous screen
              },
              child: Text(
                'Continuer',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class TokenPackage {
  final int tokens;
  final int price;
  final bool isPopular;
  final int savings;
  final String label;

  TokenPackage({
    required this.tokens,
    required this.price,
    required this.isPopular,
    required this.savings,
    this.label = '',
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TokenPackage &&
          runtimeType == other.runtimeType &&
          tokens == other.tokens &&
          price == other.price;

  @override
  int get hashCode => tokens.hashCode ^ price.hashCode;
}
