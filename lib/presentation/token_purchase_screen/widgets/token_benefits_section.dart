import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TokenBenefitsSection extends StatelessWidget {
  const TokenBenefitsSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pourquoi acheter des jetons ?',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 16),

        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              _buildBenefitItem(
                icon: Icons.add_circle_outline,
                title: 'Publiez plus de produits',
                description: 'Chaque produit publié coûte 10 jetons',
                color: Colors.blue,
              ),
              SizedBox(height: 16),
              _buildBenefitItem(
                icon: Icons.priority_high,
                title: 'Accès prioritaire',
                description: 'Vos annonces apparaissent en premier',
                color: Colors.orange,
              ),
              SizedBox(height: 16),
              _buildBenefitItem(
                icon: Icons.star_outline,
                title: 'Fonctionnalités premium',
                description: 'Accédez aux options avancées',
                color: Colors.purple,
              ),
              SizedBox(height: 16),
              _buildBenefitItem(
                icon: Icons.trending_up,
                title: 'Boostez votre visibilité',
                description: 'Plus de vues pour vos produits',
                color: Colors.green,
              ),
            ],
          ),
        ),

        SizedBox(height: 16),

        // Token economy explanation
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Comment ça marche ?',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[800],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                '• Vous commencez avec 50 jetons gratuits\n'
                '• Chaque publication coûte 10 jetons\n'
                '• Achetez 100 jetons pour 1000 FCFA\n'
                '• Continuez à publier sans limite',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.blue[700],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withAlpha(26),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
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
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
