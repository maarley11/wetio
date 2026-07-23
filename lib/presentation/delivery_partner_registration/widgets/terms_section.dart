import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class TermsSection extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final Function(Map<String, dynamic>) onDataChanged;

  const TermsSection({
    super.key,
    required this.formKey,
    required this.onDataChanged,
  });

  @override
  State<TermsSection> createState() => _TermsSectionState();
}

class _TermsSectionState extends State<TermsSection> {
  bool _acceptTerms = false;
  bool _acceptPrivacy = false;
  bool _acceptBackground = false;

  @override
  void initState() {
    super.initState();
    _updateData();
  }

  void _updateData() {
    widget.onDataChanged({
      'acceptTerms': _acceptTerms,
      'acceptPrivacy': _acceptPrivacy,
      'acceptBackground': _acceptBackground,
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: widget.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome message
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.celebration,
                        color: AppTheme.primaryGreen,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Dernière étape !',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Félicitations ! Vous êtes sur le point de rejoindre l\'équipe WETIO. Veuillez lire et accepter nos conditions pour finaliser votre inscription.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Terms and conditions
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.borderLight),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildTermsItem(
                    'Conditions générales d\'utilisation',
                    'J\'accepte les conditions générales d\'utilisation de WETIO en tant que partenaire livreur.',
                    _acceptTerms,
                    (value) {
                      setState(() {
                        _acceptTerms = value;
                      });
                      _updateData();
                    },
                    Icons.description,
                    required: true,
                  ),
                  const Divider(height: 1),
                  _buildTermsItem(
                    'Politique de confidentialité',
                    'J\'accepte la politique de confidentialité et le traitement de mes données personnelles.',
                    _acceptPrivacy,
                    (value) {
                      setState(() {
                        _acceptPrivacy = value;
                      });
                      _updateData();
                    },
                    Icons.privacy_tip,
                    required: true,
                  ),
                  const Divider(height: 1),
                  _buildTermsItem(
                    'Vérification des antécédents',
                    'J\'autorise WETIO à effectuer une vérification de mes antécédents pour des raisons de sécurité.',
                    _acceptBackground,
                    (value) {
                      setState(() {
                        _acceptBackground = value;
                      });
                      _updateData();
                    },
                    Icons.verified_user,
                    required: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Key points
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceWhite,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppTheme.primaryGreen,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Points clés à retenir',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildKeyPoint(
                      'Vous êtes un partenaire indépendant, pas un employé'),
                  _buildKeyPoint('Les paiements sont effectués chaque semaine'),
                  _buildKeyPoint(
                      'Vous pouvez travailler selon vos propres horaires'),
                  _buildKeyPoint('Un service client est disponible 24h/7j'),
                  _buildKeyPoint(
                      'Vous pouvez suspendre votre compte à tout moment'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Next steps
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppTheme.primaryOrange.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        color: AppTheme.primaryOrange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Prochaines étapes',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryOrange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildNextStep('1', 'Vérification de votre dossier (24-48h)'),
                  _buildNextStep('2', 'Activation de votre compte livreur'),
                  _buildNextStep('3', 'Formation en ligne obligatoire'),
                  _buildNextStep('4', 'Première livraison test'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Form validation
            FormField<bool>(
              initialValue: _acceptTerms && _acceptPrivacy && _acceptBackground,
              validator: (value) {
                if (!_acceptTerms || !_acceptPrivacy || !_acceptBackground) {
                  return 'Vous devez accepter toutes les conditions pour continuer';
                }
                return null;
              },
              builder: (field) {
                return field.hasError
                    ? Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          field.errorText!,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.errorRed,
                          ),
                        ),
                      )
                    : const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsItem(String title, String description, bool value,
      Function(bool) onChanged, IconData icon,
      {bool required = false}) {
    return CheckboxListTile(
      title: Row(
        children: [
          Icon(
            icon,
            color: AppTheme.primaryGreen,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          if (required)
            Text(
              ' *',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.errorRed,
              ),
            ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(left: 28, top: 4),
        child: Text(
          description,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ),
      value: value,
      onChanged: (bool? newValue) => onChanged(newValue ?? false),
      activeColor: AppTheme.primaryGreen,
      controlAffinity: ListTileControlAffinity.trailing,
      isThreeLine: true,
    );
  }

  Widget _buildKeyPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 16,
            color: AppTheme.successGreen,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: AppTheme.primaryOrange,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                number,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.surfaceWhite,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
