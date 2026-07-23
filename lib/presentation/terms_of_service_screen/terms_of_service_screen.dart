import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class TermsOfServiceScreen extends StatefulWidget {
  const TermsOfServiceScreen({super.key});

  @override
  State<TermsOfServiceScreen> createState() => _TermsOfServiceScreenState();
}

class _TermsOfServiceScreenState extends State<TermsOfServiceScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isAccepted = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _acceptTermsAndReturn() {
    HapticFeedback.lightImpact();
    Navigator.pop(context, true);
  }

  void _returnToRegistration() {
    HapticFeedback.lightImpact();
    Navigator.pop(context, false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: colorScheme.onSurface,
            size: 20,
          ),
          onPressed: _returnToRegistration,
        ),
        title: Text(
          'Conditions d\'utilisation',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // WETIO Branding Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 17.0, horizontal: 16.0),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'W',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.0),
                    Text(
                      'WETIO',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.5),
                Text(
                  'Plateforme d\'échange de biens au Sénégal',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          // Scrollable Terms Content
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Introduction
                  Container(
                    padding: EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color:
                          colorScheme.primaryContainer.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Ces Conditions Générales d\'Utilisation régissent votre utilisation de la plateforme WETIO. Veuillez les lire attentivement avant d\'accepter.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),
                  ),

                  SizedBox(height: 25.5),

                  // Terms Sections
                  _buildSection(
                    context,
                    '1. Objet',
                    'Les présentes Conditions Générales d\'Utilisation (CGU) régissent l\'accès et l\'utilisation de la plateforme WETIO (ci-après « WETIO »), un service en ligne permettant aux utilisateurs d\'échanger des articles entre particuliers au Sénégal.',
                  ),

                  _buildSection(
                    context,
                    '2. Inscription et compte utilisateur',
                    '• L\'inscription est gratuite et réservée aux personnes majeures (18 ans et plus).\n\n• L\'utilisateur s\'engage à fournir des informations exactes lors de la création de son compte.\n\n• Chaque compte est personnel et ne peut être cédé.',
                  ),

                  _buildSection(
                    context,
                    '3. Fonctionnement du service',
                    '• La plateforme met en relation des particuliers souhaitant échanger des produits (Jeux, chaussure, vêtement, livre).\n\n• Les utilisateurs publient leurs annonces (photos, taille, état, description).\n\n• Les échanges se font directement entre utilisateurs, sous leur entière responsabilité.\n\n• Il est aussi possible de contacter directement les livreurs inscrits sur notre plateforme.\n\n• La Plateforme ne vend aucun article et n\'est pas partie aux contrats d\'échange.',
                  ),

                  _buildSection(
                    context,
                    '4. Règles de bonne conduite',
                    'Les utilisateurs s\'engagent à :\n\n• Respecter les autres membres (pas d\'insultes, discrimination, harcèlement).\n\n• Ne publier que des articles propres et en état d\'usage.\n\n• Ne pas publier d\'annonces frauduleuses, illicites ou contraires aux bonnes mœurs.',
                  ),

                  _buildSection(
                    context,
                    '5. Responsabilité',
                    '• La Plateforme n\'est pas responsable de la qualité, de l\'authenticité ou de l\'état des articles échangés.\n\n• Les utilisateurs assument seuls les risques liés aux échanges.\n\n• La Plateforme ne peut être tenue responsable en cas de litige, perte, vol ou dommage lié à un échange.',
                  ),

                  _buildSection(
                    context,
                    '6. Messagerie interne',
                    'La messagerie interne permet aux utilisateurs de communiquer pour organiser leurs échanges. Toute utilisation abusive (spams, arnaques, propos offensants) entraînera la suspension du compte.',
                  ),

                  _buildSection(
                    context,
                    '7. Protection des données personnelles',
                    '• Les données collectées (nom, email, numéro de téléphone, localisation) sont utilisées uniquement pour le fonctionnement de la Plateforme.\n\n• Conformément à la réglementation sénégalaise sur la protection des données, chaque utilisateur dispose d\'un droit d\'accès, de rectification et de suppression de ses données.',
                  ),

                  _buildSection(
                    context,
                    '8. Suspension et suppression de compte',
                    'La Plateforme se réserve le droit de suspendre ou supprimer tout compte en cas de non-respect des présentes CGU.',
                  ),

                  _buildSection(
                    context,
                    '9. Modification des CGU',
                    'La plateforme peut modifier les CGU à tout moment. Les utilisateurs seront informés des changements et devront les accepter pour continuer à utiliser le service.',
                  ),

                  _buildSection(
                    context,
                    '10. Droit applicable et juridiction compétente',
                    'Les présentes CGU sont régies par le droit sénégalais. Tout litige sera porté devant les juridictions compétentes du Sénégal.',
                  ),

                  SizedBox(height: 25.5),

                  // Last Updated
                  Container(
                    padding: EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        SizedBox(width: 8.0),
                        Text(
                          'Dernière mise à jour : Janvier 2025',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 34.0),
                ],
              ),
            ),
          ),

          // Bottom Action Section
          Container(
            padding: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                // Accept Checkbox
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          _isAccepted = !_isAccepted;
                        });
                      },
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: _isAccepted
                                ? colorScheme.primary
                                : colorScheme.outline,
                            width: 2,
                          ),
                          color: _isAccepted
                              ? colorScheme.primary
                              : Colors.transparent,
                        ),
                        child: _isAccepted
                            ? Icon(
                                Icons.check,
                                size: 16,
                                color: colorScheme.onPrimary,
                              )
                            : null,
                      ),
                    ),
                    SizedBox(width: 12.0),
                    Expanded(
                      child: Text(
                        'J\'accepte les conditions d\'utilisation et la politique de confidentialité de WETIO',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 17.0),

                // Action Buttons
                Row(
                  children: [
                    // Return Button
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _returnToRegistration,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: colorScheme.outline,
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12.8),
                        ),
                        child: Text(
                          'Retour à l\'inscription',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(width: 12.0),

                    // Accept Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isAccepted ? _acceptTermsAndReturn : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isAccepted
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.3),
                          foregroundColor: _isAccepted
                              ? colorScheme.onPrimary
                              : colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.6),
                          elevation: _isAccepted ? 2 : 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12.8),
                        ),
                        child: Text(
                          'J\'accepte',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: EdgeInsets.only(bottom: 25.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Container(
            padding: EdgeInsets.symmetric(vertical: 8.5, horizontal: 12.0),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
              ),
            ),
          ),

          SizedBox(height: 8.5),

          // Section Content
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Text(
              content,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: colorScheme.onSurface,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
