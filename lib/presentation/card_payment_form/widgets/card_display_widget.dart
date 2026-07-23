import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CardDisplayWidget extends StatefulWidget {
  final String cardNumber;
  final String cardholderName;
  final String expirationDate;
  final String cvv;
  final String cardType;

  const CardDisplayWidget({
    Key? key,
    required this.cardNumber,
    required this.cardholderName,
    required this.expirationDate,
    required this.cvv,
    required this.cardType,
  }) : super(key: key);

  @override
  State<CardDisplayWidget> createState() => _CardDisplayWidgetState();
}

class _CardDisplayWidgetState extends State<CardDisplayWidget>
    with TickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _isShowingFront = true;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _flipAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _flipController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_isShowingFront) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
    setState(() {
      _isShowingFront = !_isShowingFront;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Card Animation
        GestureDetector(
          onTap: _flipCard,
          child: AnimatedBuilder(
            animation: _flipAnimation,
            builder: (context, child) {
              final isShowingFront = _flipAnimation.value < 0.5;
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(_flipAnimation.value * 3.14159),
                child: isShowingFront ? _buildCardFront() : _buildCardBack(),
              );
            },
          ),
        ),

        SizedBox(height: 12),

        // Flip instruction
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flip, color: Colors.grey[600], size: 16),
            SizedBox(width: 8),
            Text(
              'Touchez pour voir le verso',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCardFront() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        gradient: _getCardGradient(),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(38),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Brand and Type
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'WETIO',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                _buildCardTypeIcon(),
              ],
            ),

            SizedBox(height: 20),

            // Chip
            Container(
              width: 45,
              height: 35,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(76),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.sim_card,
                color: Colors.white.withAlpha(179),
                size: 24,
              ),
            ),

            SizedBox(height: 16),

            // Card Number
            Text(
              _formatDisplayCardNumber(widget.cardNumber),
              style: GoogleFonts.robotoMono(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),

            Spacer(),

            // Cardholder and Expiry
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TITULAIRE',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withAlpha(179),
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      widget.cardholderName.isEmpty
                          ? 'VOTRE NOM'
                          : widget.cardholderName.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EXPIRE',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withAlpha(179),
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      widget.expirationDate.isEmpty
                          ? 'MM/AA'
                          : widget.expirationDate,
                      style: GoogleFonts.robotoMono(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardBack() {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..rotateY(3.14159),
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          gradient: _getCardGradient(),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(38),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            SizedBox(height: 20),

            // Magnetic stripe
            Container(
              width: double.infinity,
              height: 40,
              color: Colors.black87,
            ),

            SizedBox(height: 20),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // CVV Section
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CVV',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withAlpha(179),
                            letterSpacing: 1,
                          ),
                        ),
                        SizedBox(height: 4),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            widget.cvv.isEmpty ? '***' : widget.cvv,
                            style: GoogleFonts.robotoMono(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(width: 20),

                  // Card brand logo
                  _buildCardTypeIcon(),
                ],
              ),
            ),

            Spacer(),

            // Security text
            Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Cette carte est protégée par la technologie de sécurité avancée',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.white.withAlpha(153),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardTypeIcon() {
    switch (widget.cardType.toLowerCase()) {
      case 'visa':
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'VISA',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Colors.blue[800],
              letterSpacing: 1,
            ),
          ),
        );
      case 'mastercard':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: 20,
              height: 20,
              margin: EdgeInsets.only(left: -10),
              decoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
            ),
          ],
        );
      case 'amex':
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'AMEX',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Colors.blue[900],
              letterSpacing: 1,
            ),
          ),
        );
      default:
        return Icon(
          Icons.credit_card,
          color: Colors.white.withAlpha(179),
          size: 24,
        );
    }
  }

  LinearGradient _getCardGradient() {
    switch (widget.cardType.toLowerCase()) {
      case 'visa':
        return LinearGradient(
          colors: [Colors.blue[700]!, Colors.blue[900]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'mastercard':
        return LinearGradient(
          colors: [Colors.red[600]!, Colors.orange[800]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'amex':
        return LinearGradient(
          colors: [Colors.green[700]!, Colors.teal[800]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return LinearGradient(
          colors: [Colors.grey[700]!, Colors.grey[900]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  String _formatDisplayCardNumber(String cardNumber) {
    if (cardNumber.isEmpty) {
      return '•••• •••• •••• ••••';
    }

    String cleanNumber = cardNumber.replaceAll(' ', '');
    String masked = '';

    for (int i = 0; i < 16; i += 4) {
      if (i + 4 <= cleanNumber.length) {
        if (i == 12) {
          // Show last 4 digits
          masked += cleanNumber.substring(i, i + 4);
        } else if (i == 0 && cleanNumber.length >= 4) {
          // Show first 4 digits
          masked += cleanNumber.substring(i, i + 4);
        } else {
          // Mask middle digits
          masked += '••••';
        }
      } else {
        // Incomplete number
        int remaining = cleanNumber.length - i;
        if (remaining > 0) {
          masked += cleanNumber.substring(i) + ('•' * (4 - remaining));
        } else {
          masked += '••••';
        }
      }

      if (i < 12) {
        masked += ' ';
      }
    }

    return masked;
  }
}
