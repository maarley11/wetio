import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class CardInputFormWidget extends StatefulWidget {
  final TextEditingController cardNumberController;
  final TextEditingController expirationController;
  final TextEditingController cvvController;
  final TextEditingController cardholderController;
  final Function(String) onCardNumberChanged;
  final VoidCallback onFieldChanged;

  const CardInputFormWidget({
    Key? key,
    required this.cardNumberController,
    required this.expirationController,
    required this.cvvController,
    required this.cardholderController,
    required this.onCardNumberChanged,
    required this.onFieldChanged,
  }) : super(key: key);

  @override
  State<CardInputFormWidget> createState() => _CardInputFormWidgetState();
}

class _CardInputFormWidgetState extends State<CardInputFormWidget> {
  final _cardNumberFocus = FocusNode();
  final _expirationFocus = FocusNode();
  final _cvvFocus = FocusNode();
  final _cardholderFocus = FocusNode();

  @override
  void dispose() {
    _cardNumberFocus.dispose();
    _expirationFocus.dispose();
    _cvvFocus.dispose();
    _cardholderFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Card Number Field
        _buildInputField(
          label: 'Numéro de carte',
          controller: widget.cardNumberController,
          focusNode: _cardNumberFocus,
          hintText: '1234 5678 9012 3456',
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(16),
          ],
          onChanged: widget.onCardNumberChanged,
          validator: _validateCardNumber,
          suffixIcon: _buildCardTypeIcon(),
        ),

        SizedBox(height: 20),

        // Expiration and CVV Row
        Row(
          children: [
            // Expiration Date
            Expanded(
              flex: 2,
              child: _buildInputField(
                label: 'Date d\'expiration',
                controller: widget.expirationController,
                focusNode: _expirationFocus,
                hintText: 'MM/AA',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                  _ExpirationDateFormatter(),
                ],
                onChanged: (value) {
                  widget.onFieldChanged();
                  if (value.length == 5) {
                    FocusScope.of(context).requestFocus(_cvvFocus);
                  }
                },
                validator: _validateExpirationDate,
              ),
            ),

            SizedBox(width: 16),

            // CVV Field
            Expanded(
              flex: 1,
              child: _buildInputField(
                label: 'CVV',
                controller: widget.cvvController,
                focusNode: _cvvFocus,
                hintText: '123',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                onChanged: (value) {
                  widget.onFieldChanged();
                  if (value.length >= 3) {
                    FocusScope.of(context).requestFocus(_cardholderFocus);
                  }
                },
                validator: _validateCVV,
                suffixIcon: IconButton(
                  icon: Icon(Icons.help_outline, size: 18),
                  onPressed: _showCVVInfo,
                ),
                obscureText: true,
              ),
            ),
          ],
        ),

        SizedBox(height: 20),

        // Cardholder Name
        _buildInputField(
          label: 'Nom du titulaire',
          controller: widget.cardholderController,
          focusNode: _cardholderFocus,
          hintText: 'Comme indiqué sur la carte',
          keyboardType: TextInputType.name,
          textCapitalization: TextCapitalization.words,
          onChanged: (value) => widget.onFieldChanged(),
          validator: _validateCardholderName,
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    Function(String)? onChanged,
    String? Function(String?)? validator,
    Widget? suffixIcon,
    bool obscureText = false,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),

        // Input Field
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          validator: validator,
          obscureText: obscureText,
          textCapitalization: textCapitalization,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.inter(
              color: Colors.grey[500],
              fontSize: 16,
            ),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red[400]!, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red[400]!, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget? _buildCardTypeIcon() {
    String cardNumber = widget.cardNumberController.text.replaceAll(' ', '');

    if (cardNumber.startsWith('4')) {
      return Padding(
        padding: EdgeInsets.only(right: 12),
        child: Icon(Icons.credit_card, color: Colors.blue[600]),
      );
    } else if (cardNumber.startsWith('5') ||
        (cardNumber.length >= 2 &&
            int.tryParse(cardNumber.substring(0, 2)) != null &&
            int.parse(cardNumber.substring(0, 2)) >= 51 &&
            int.parse(cardNumber.substring(0, 2)) <= 55)) {
      return Padding(
        padding: EdgeInsets.only(right: 12),
        child: Icon(Icons.credit_card, color: Colors.orange[600]),
      );
    } else if (cardNumber.startsWith('34') || cardNumber.startsWith('37')) {
      return Padding(
        padding: EdgeInsets.only(right: 12),
        child: Icon(Icons.credit_card, color: Colors.green[600]),
      );
    }
    return null;
  }

  String? _validateCardNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez saisir le numéro de carte';
    }

    String cleanValue = value.replaceAll(' ', '');
    if (cleanValue.length < 16) {
      return 'Le numéro de carte doit contenir 16 chiffres';
    }

    // Luhn algorithm validation
    if (!_isValidLuhn(cleanValue)) {
      return 'Numéro de carte invalide';
    }

    return null;
  }

  String? _validateExpirationDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez saisir la date d\'expiration';
    }

    if (value.length != 5) {
      return 'Format invalide (MM/AA)';
    }

    List<String> parts = value.split('/');
    if (parts.length != 2) {
      return 'Format invalide (MM/AA)';
    }

    int? month = int.tryParse(parts[0]);
    int? year = int.tryParse(parts[1]);

    if (month == null || year == null) {
      return 'Date invalide';
    }

    if (month < 1 || month > 12) {
      return 'Mois invalide';
    }

    DateTime now = DateTime.now();
    int currentYear = now.year % 100;
    int currentMonth = now.month;

    if (year < currentYear || (year == currentYear && month < currentMonth)) {
      return 'Carte expirée';
    }

    return null;
  }

  String? _validateCVV(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez saisir le CVV';
    }

    if (value.length < 3) {
      return 'CVV invalide';
    }

    return null;
  }

  String? _validateCardholderName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez saisir le nom du titulaire';
    }

    if (value.trim().length < 2) {
      return 'Nom trop court';
    }

    return null;
  }

  bool _isValidLuhn(String cardNumber) {
    int sum = 0;
    bool alternate = false;

    for (int i = cardNumber.length - 1; i >= 0; i--) {
      int digit = int.parse(cardNumber[i]);

      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit = (digit % 10) + 1;
        }
      }

      sum += digit;
      alternate = !alternate;
    }

    return (sum % 10) == 0;
  }

  void _showCVVInfo() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.security, color: Colors.blue[600], size: 20),
              SizedBox(width: 8),
              Text(
                'Qu\'est-ce que le CVV ?',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Le CVV est un code de sécurité à 3 ou 4 chiffres :',
                style: GoogleFonts.inter(fontSize: 14),
              ),
              SizedBox(height: 12),
              Text(
                '• Visa/Mastercard : 3 chiffres au verso',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[700]),
              ),
              Text(
                '• American Express : 4 chiffres au recto',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[700]),
              ),
              SizedBox(height: 12),
              Text(
                'Ce code garantit la sécurité de votre transaction.',
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Compris',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[600],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ExpirationDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    if (text.length <= 2) {
      return newValue;
    }

    if (text.length <= 4) {
      return TextEditingValue(
        text: '${text.substring(0, 2)}/${text.substring(2)}',
        selection: TextSelection.collapsed(offset: text.length + 1),
      );
    }

    return TextEditingValue(
      text: '${text.substring(0, 2)}/${text.substring(2, 4)}',
      selection: TextSelection.collapsed(offset: 5),
    );
  }
}
