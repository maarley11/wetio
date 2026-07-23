import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ValidationIndicatorsWidget extends StatelessWidget {
  const ValidationIndicatorsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.verified_user, color: Colors.green[600], size: 18),
              SizedBox(width: 8),
              Text(
                'Sécurité garantie',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.green[800],
                ),
              ),
            ],
          ),

          SizedBox(height: 12),

          // Security Features
          _buildSecurityFeature(
            icon: Icons.lock,
            title: 'Cryptage SSL 256-bit',
            description: 'Vos données sont protégées',
            isActive: true,
          ),

          SizedBox(height: 8),

          _buildSecurityFeature(
            icon: Icons.verified,
            title: 'Certification PCI DSS',
            description: 'Norme de sécurité bancaire',
            isActive: true,
          ),

          SizedBox(height: 8),

          _buildSecurityFeature(
            icon: Icons.shield,
            title: 'Protection anti-fraude',
            description: 'Surveillance en temps réel',
            isActive: true,
          ),

          SizedBox(height: 8),

          _buildSecurityFeature(
            icon: Icons.credit_card_off,
            title: 'Aucun stockage des données',
            description: 'Informations non sauvegardées',
            isActive: true,
          ),

          SizedBox(height: 12),

          // Trust Badges
          Row(
            children: [
              _buildTrustBadge('VISA', Colors.blue[700]!),
              SizedBox(width: 8),
              _buildTrustBadge('MASTERCARD', Colors.orange[600]!),
              SizedBox(width: 8),
              _buildTrustBadge('AMEX', Colors.green[700]!),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green[600],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'SÉCURISÉ',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityFeature({
    required IconData icon,
    required String title,
    required String description,
    required bool isActive,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isActive ? Colors.green[100] : Colors.grey[200],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 14,
            color: isActive ? Colors.green[700] : Colors.grey[500],
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.green[800] : Colors.grey[600],
                ),
              ),
              Text(
                description,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: isActive ? Colors.green[600] : Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
        if (isActive)
          Icon(Icons.check_circle, size: 16, color: Colors.green[600]),
      ],
    );
  }

  Widget _buildTrustBadge(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(51)),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
