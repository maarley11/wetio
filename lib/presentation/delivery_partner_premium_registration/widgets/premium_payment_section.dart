import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

enum PaymentMethod { orangeMoney, wave, freeMoney, card }

class PremiumPaymentSection extends StatefulWidget {
  final Function(Map<String, dynamic>) onDataChanged;

  const PremiumPaymentSection({
    super.key,
    required this.onDataChanged,
  });

  @override
  State<PremiumPaymentSection> createState() => _PremiumPaymentSectionState();
}

class _PremiumPaymentSectionState extends State<PremiumPaymentSection> {
  PaymentMethod _selectedPaymentMethod = PaymentMethod.orangeMoney;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  bool _isProcessing = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _onPaymentMethodChanged(PaymentMethod method) {
    setState(() {
      _selectedPaymentMethod = method;
    });
    _updateData();
  }

  void _updateData() {
    widget.onDataChanged({
      'paymentMethod': _selectedPaymentMethod.name,
      'phoneNumber': _phoneController.text,
      'cardNumber': _cardNumberController.text,
      'expiryDate': _expiryController.text,
      'cvv': _cvvController.text,
      'cardHolderName': _nameController.text,
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Payment header
          Container(
            padding: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withValues(alpha: 0.1),
                  colorScheme.primaryContainer.withValues(alpha: 0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.payment,
                  size: 48,
                  color: colorScheme.primary,
                ),
                SizedBox(height: 17.0),
                Text(
                  'Paiement sécurisé',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                SizedBox(height: 8.5),
                Text(
                  '500 FCFA - Paiement unique pour l\'inscription Premium',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          SizedBox(height: 25.5),

          Text(
            'Méthode de paiement',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),

          SizedBox(height: 17.0),

          // Payment method selection
          _buildPaymentMethodCard(
            PaymentMethod.orangeMoney,
            'Orange Money',
            Icons.phone_android,
            Colors.orange,
            colorScheme,
            theme,
          ),
          _buildPaymentMethodCard(
            PaymentMethod.wave,
            'Wave',
            Icons.waves,
            Colors.blue,
            colorScheme,
            theme,
          ),
          _buildPaymentMethodCard(
            PaymentMethod.freeMoney,
            'Free Money',
            Icons.account_balance_wallet,
            Colors.red,
            colorScheme,
            theme,
          ),
          _buildPaymentMethodCard(
            PaymentMethod.card,
            'Carte bancaire',
            Icons.credit_card,
            Colors.green,
            colorScheme,
            theme,
          ),

          SizedBox(height: 25.5),

          // Payment form based on selected method
          if (_selectedPaymentMethod != PaymentMethod.card)
            _buildMobileMoneyForm(colorScheme, theme)
          else
            _buildCardForm(colorScheme, theme),

          SizedBox(height: 25.5),

          // Security notice
          Container(
            padding: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: AppTheme.successGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.successGreen.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.security,
                  color: AppTheme.successGreen,
                  size: 24,
                ),
                SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Paiement 100% sécurisé',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.successGreen,
                        ),
                      ),
                      Text(
                        'Vos données sont cryptées et protégées selon les standards bancaires internationaux.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard(
    PaymentMethod method,
    String title,
    IconData icon,
    Color color,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    final isSelected = _selectedPaymentMethod == method;

    return GestureDetector(
      onTap: () => _onPaymentMethodChanged(method),
      child: Container(
        margin: EdgeInsets.only(bottom: 17.0),
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer.withValues(alpha: 0.3)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            SizedBox(width: 16.0),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: colorScheme.primary,
                size: 24,
              )
            else
              Icon(
                Icons.radio_button_unchecked,
                color: colorScheme.outline,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileMoneyForm(ColorScheme colorScheme, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Numéro de téléphone',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 8.5),
        TextFormField(
          controller: _phoneController,
          decoration: InputDecoration(
            hintText: 'Ex: 77 123 45 67',
            prefixIcon: Icon(Icons.phone, color: colorScheme.primary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
          ),
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(9),
          ],
          onChanged: (_) => _updateData(),
        ),
        SizedBox(height: 17.0),
        Text(
          'Vous recevrez un SMS de confirmation pour valider le paiement.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildCardForm(ColorScheme colorScheme, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card number
        Text(
          'Numéro de carte',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 8.5),
        TextFormField(
          controller: _cardNumberController,
          decoration: InputDecoration(
            hintText: '1234 5678 9012 3456',
            prefixIcon: Icon(Icons.credit_card, color: colorScheme.primary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(16),
            // Add card number formatting
          ],
          onChanged: (_) => _updateData(),
        ),

        SizedBox(height: 17.0),

        Row(
          children: [
            // Expiry date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date d\'expiration',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 8.5),
                  TextFormField(
                    controller: _expiryController,
                    decoration: InputDecoration(
                      hintText: 'MM/YY',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colorScheme.outline),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: colorScheme.primary, width: 2),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    onChanged: (_) => _updateData(),
                  ),
                ],
              ),
            ),

            SizedBox(width: 16.0),

            // CVV
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CVV',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 8.5),
                  TextFormField(
                    controller: _cvvController,
                    decoration: InputDecoration(
                      hintText: '123',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colorScheme.outline),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: colorScheme.primary, width: 2),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    obscureText: true,
                    onChanged: (_) => _updateData(),
                  ),
                ],
              ),
            ),
          ],
        ),

        SizedBox(height: 17.0),

        // Cardholder name
        Text(
          'Nom du titulaire',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 8.5),
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: 'Nom complet du titulaire',
            prefixIcon: Icon(Icons.person, color: colorScheme.primary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
          ),
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => _updateData(),
        ),
      ],
    );
  }
}
