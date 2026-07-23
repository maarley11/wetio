import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PaymentMethodsSection extends StatefulWidget {
  final Function(String)? onPaymentMethodChanged;

  const PaymentMethodsSection({
    Key? key,
    this.onPaymentMethodChanged,
  }) : super(key: key);

  @override
  State<PaymentMethodsSection> createState() => _PaymentMethodsSectionState();
}

class _PaymentMethodsSectionState extends State<PaymentMethodsSection> {
  String _selectedMethod = 'wave';

  @override
  void initState() {
    super.initState();
    // Auto-notify parent that Wave is selected by default
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.onPaymentMethodChanged != null) {
        widget.onPaymentMethodChanged!('wave');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Méthode de paiement',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 16),

        // Wave Payment Method - Only available option
        _buildWavePaymentCard(),

        SizedBox(height: 16),

        // Wave Business Information
        _buildWaveBusinessInfo(),
      ],
    );
  }

  Widget _buildWavePaymentCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF1E88E5), width: 2),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF1E88E5).withAlpha(26),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFF1E88E5).withAlpha(26),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.phone_android,
                  color: Color(0xFF1E88E5),
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Wave',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(width: 12),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'SEUL MOYEN',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Paiement mobile sécurisé au Sénégal',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.radio_button_checked,
                color: Color(0xFF1E88E5),
                size: 24,
              ),
            ],
          ),

          SizedBox(height: 16),

          // Wave Features
          Row(
            children: [
              Expanded(
                child: _buildFeatureItem(
                  icon: Icons.security,
                  text: 'Sécurisé',
                ),
              ),
              Expanded(
                child: _buildFeatureItem(
                  icon: Icons.flash_on,
                  text: 'Instantané',
                ),
              ),
              Expanded(
                child: _buildFeatureItem(
                  icon: Icons.verified,
                  text: 'Fiable',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({required IconData icon, required String text}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: Color(0xFF1E88E5)),
        SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildWaveBusinessInfo() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1E88E5).withAlpha(13),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF1E88E5).withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFF1E88E5), size: 20),
              SizedBox(width: 8),
              Text(
                'Informations de paiement Wave',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E88E5),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Numéro Wave Business: ',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Color(0xFF1E88E5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '70 766 15 02',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '• Vous serez redirigé vers votre application Wave\n• Le montant sera pré-rempli automatiquement\n• Validez simplement le paiement dans Wave',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
