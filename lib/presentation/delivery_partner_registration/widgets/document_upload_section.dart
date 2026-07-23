import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../theme/app_theme.dart';

class DocumentUploadSection extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final Function(Map<String, dynamic>) onDataChanged;

  const DocumentUploadSection({
    super.key,
    required this.formKey,
    required this.onDataChanged,
  });

  @override
  State<DocumentUploadSection> createState() => _DocumentUploadSectionState();
}

class _DocumentUploadSectionState extends State<DocumentUploadSection> {
  XFile? _idCardFront;
  XFile? _idCardBack;
  XFile? _selfieWithId;
  XFile? _criminalRecord;

  final List<Map<String, dynamic>> _documents = [
    {
      'id': 'id_front',
      'title': 'Carte d\'identité (recto)',
      'description': 'Photo claire du recto de votre CNI',
      'required': true,
      'icon': Icons.credit_card,
    },
    {
      'id': 'id_back',
      'title': 'Carte d\'identité (verso)',
      'description': 'Photo claire du verso de votre CNI',
      'required': true,
      'icon': Icons.credit_card,
    },
    {
      'id': 'selfie_id',
      'title': 'Selfie avec la CNI',
      'description': 'Une photo de vous tenant votre CNI',
      'required': true,
      'icon': Icons.face,
    },
    {
      'id': 'criminal_record',
      'title': 'Casier judiciaire',
      'description': 'Extrait de casier judiciaire (optionnel)',
      'required': false,
      'icon': Icons.verified_user,
    },
  ];

  @override
  void initState() {
    super.initState();
    _updateData();
  }

  void _updateData() {
    widget.onDataChanged({
      'idCardFront': _idCardFront,
      'idCardBack': _idCardBack,
      'selfieWithId': _selfieWithId,
      'criminalRecord': _criminalRecord,
    });
  }

  Future<void> _pickDocument(String documentId) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        switch (documentId) {
          case 'id_front':
            _idCardFront = image;
            break;
          case 'id_back':
            _idCardBack = image;
            break;
          case 'selfie_id':
            _selfieWithId = image;
            break;
          case 'criminal_record':
            _criminalRecord = image;
            break;
        }
      });
      _updateData();
    }
  }

  XFile? _getDocumentFile(String documentId) {
    switch (documentId) {
      case 'id_front':
        return _idCardFront;
      case 'id_back':
        return _idCardBack;
      case 'selfie_id':
        return _selfieWithId;
      case 'criminal_record':
        return _criminalRecord;
      default:
        return null;
    }
  }

  String _getPlaceholderImage(String documentId) {
    switch (documentId) {
      case 'id_front':
      case 'id_back':
        return 'https://images.unsplash.com/photo-1614624532983-4ce03382d63d?w=400&h=250&fit=crop';
      case 'selfie_id':
        return 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=250&fit=crop&crop=face';
      case 'criminal_record':
        return 'https://images.unsplash.com/photo-1586953208448-b95a79798f07?w=400&h=250&fit=crop';
      default:
        return '';
    }
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
            // Information section
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
                        Icons.security,
                        color: AppTheme.primaryGreen,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Vérification d\'identité',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Vos documents sont traités de manière sécurisée et confidentielle. La vérification prend généralement 24-48h.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Documents upload
            Text(
              'Documents requis',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            ...List.generate(_documents.length, (index) {
              final document = _documents[index];
              final file = _getDocumentFile(document['id']);
              final hasFile = file != null;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color:
                        hasFile ? AppTheme.successGreen : AppTheme.borderLight,
                    width: hasFile ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            document['icon'],
                            color: hasFile
                                ? AppTheme.successGreen
                                : AppTheme.textSecondary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      document['title'],
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    if (document['required'])
                                      Text(
                                        ' *',
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.errorRed,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  document['description'],
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (hasFile)
                            const Icon(
                              Icons.check_circle,
                              color: AppTheme.successGreen,
                              size: 24,
                            ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _pickDocument(document['id']),
                      child: Container(
                        height: 160,
                        width: double.infinity,
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        decoration: BoxDecoration(
                          color: AppTheme.borderLight.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.borderLight,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: hasFile
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(7),
                                child: Stack(
                                  children: [
                                    Image.network(
                                      _getPlaceholderImage(document['id']),
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return const Center(
                                          child: Icon(
                                            Icons.image,
                                            size: 40,
                                            color: AppTheme.textSecondary,
                                          ),
                                        );
                                      },
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppTheme.successGreen,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: const Icon(
                                          Icons.check,
                                          color: AppTheme.surfaceWhite,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.camera_alt,
                                    size: 40,
                                    color: AppTheme.textSecondary,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Prendre une photo',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            // Guidelines
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
                        Icons.tips_and_updates,
                        color: AppTheme.primaryOrange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Conseils pour de bonnes photos',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTip(
                      'Assurez-vous que la photo est claire et bien éclairée'),
                  _buildTip('Évitez les reflets et les ombres'),
                  _buildTip('Tous les textes doivent être lisibles'),
                  _buildTip('Cadrez bien le document dans son intégralité'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(String text) {
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
}
