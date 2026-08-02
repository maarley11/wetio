import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import '../../services/notification_service.dart';
import './widgets/step_progress_widget.dart';
import './widgets/code_display_card_widget.dart';
import './widgets/code_validation_widget.dart';
import './widgets/step_detail_card_widget.dart';

class ThreeStepDeliveryCoordinationScreen extends StatefulWidget {
  const ThreeStepDeliveryCoordinationScreen({super.key});

  @override
  State<ThreeStepDeliveryCoordinationScreen> createState() =>
      _ThreeStepDeliveryCoordinationScreenState();
}

class _ThreeStepDeliveryCoordinationScreenState
    extends State<ThreeStepDeliveryCoordinationScreen> {
  final supabase = Supabase.instance.client;
  final _codeController = TextEditingController();

  bool _isLoading = true;
  bool _isValidating = false;
  bool _codeError = false;
  int _currentStep = 0;
  bool _exchangeCompleted = false;

  // User role: 'initiator' (Fatou), 'partner' (Awa), 'livreur'
  String _userRole = 'initiator';
  String? _deliveryRequestId;

  // Participants
  String _personAName = 'Fatou';
  String _personBName = 'Awa';
  String _personAProduct = 'Sac en cuir';
  String _personBProduct = 'Robe fleurie';
  String _personAAddress = 'Dakar, Plateau';
  String _personBAddress = 'Dakar, Almadies';

  // Codes
  String _codeA = '';
  String _codeB = '';

  // Cost
  int _totalCost = 2000;
  int _userShare = 1000;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is Map<String, dynamic>) {
        _deliveryRequestId = args['deliveryRequestId'] as String?;
        _userRole = args['userRole'] as String? ?? 'initiator';
        _personAName = args['personAName'] as String? ?? 'Fatou';
        _personBName = args['personBName'] as String? ?? 'Awa';
        _personAProduct = args['personAProduct'] as String? ?? 'Sac en cuir';
        _personBProduct = args['personBProduct'] as String? ?? 'Robe fleurie';
        _personAAddress = args['personAAddress'] as String? ?? 'Dakar, Plateau';
        _personBAddress =
            args['personBAddress'] as String? ?? 'Dakar, Almadies';
        _totalCost = args['totalCost'] as int? ?? 2000;
        _userShare = args['userShare'] as int? ?? 1000;
      }

      // Generate unique codes
      final rng = Random();
      _codeA = (1000 + rng.nextInt(9000)).toString();
      do {
        _codeB = (1000 + rng.nextInt(9000)).toString();
      } while (_codeB == _codeA);

      // Load existing step from DB if available
      if (_deliveryRequestId != null) {
        try {
          final response = await supabase
              .from('delivery_requests')
              .select('current_step, delivery_status, code_a, code_b')
              .eq('id', _deliveryRequestId!)
              .single();

          if (mounted) {
            setState(() {
              _currentStep = response['current_step'] as int? ?? 0;
              _exchangeCompleted = response['delivery_status'] == 'completed';
              if (response['code_a'] != null) {
                _codeA = response['code_a'] as String;
              }
              if (response['code_b'] != null) {
                _codeB = response['code_b'] as String;
              }
            });
          }

          // Save codes to DB if not already saved
          if (response['code_a'] == null) {
            await supabase
                .from('delivery_requests')
                .update({'code_a': _codeA, 'code_b': _codeB}).eq(
                    'id', _deliveryRequestId!);
          }
        } catch (e) {
          debugPrint('Error loading delivery request: $e');
        }
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String get _myCode {
    if (_userRole == 'initiator') return _codeA;
    if (_userRole == 'partner') return _codeB;
    return '';
  }

  String get _expectedCodeForCurrentStep {
    switch (_currentStep) {
      case 0:
        return _codeA; // Livreur enters Fatou's code
      case 1:
        return _codeB; // Livreur enters Awa's code
      case 2:
        return _codeA; // Livreur enters Fatou's code again for final
      default:
        return '';
    }
  }

  Future<void> _validateCode() async {
    final entered = _codeController.text.trim();
    if (entered.length < 4) {
      setState(() => _codeError = true);
      return;
    }

    setState(() => _isValidating = true);

    await Future.delayed(const Duration(milliseconds: 600));

    if (entered == _expectedCodeForCurrentStep) {
      HapticFeedback.mediumImpact();
      setState(() {
        _codeError = false;
        _codeController.clear();
      });

      final newStep = _currentStep + 1;

      if (newStep >= 3) {
        // Exchange completed
        await _completeExchange();
      } else {
        setState(() => _currentStep = newStep);
        await _updateStepInDB(newStep);
        _showStepConfirmation(newStep);
      }
    } else {
      HapticFeedback.heavyImpact();
      setState(() => _codeError = true);
    }

    if (mounted) setState(() => _isValidating = false);
  }

  Future<void> _updateStepInDB(int step) async {
    if (_deliveryRequestId == null) return;
    try {
      await supabase
          .from('delivery_requests')
          .update({'current_step': step}).eq('id', _deliveryRequestId!);

      // Send push notifications for each step to both users
      await _sendStepPushNotifications(step);
    } catch (e) {
      debugPrint('Error updating step: $e');
    }
  }

  Future<void> _sendStepPushNotifications(int step) async {
    if (_deliveryRequestId == null) return;
    try {
      final req = await supabase
          .from('delivery_requests')
          .select('person_a_id, person_b_id')
          .eq('id', _deliveryRequestId!)
          .maybeSingle();
      if (req == null) return;

      final personAId = req['person_a_id']?.toString() ?? '';
      final personBId = req['person_b_id']?.toString() ?? '';

      String title = '';
      String body = '';

      if (step == 1) {
        // Livreur vient de récupérer le colis chez Person A (Gass)
        title = '📦 Colis récupéré !';
        body = 'Le livreur a récupéré le colis chez $_personAName et est en route. Les deux colis seront échangés ensemble.';
      } else if (step == 2) {
        // Livreur vient de livrer à Person B (Ngary) et a récupéré son colis
        title = '🔄 Échange en cours !';
        body = 'Le livreur a remis le colis à $_personBName et récupère le sien. Il est maintenant en route vers $_personAName !';
      }

      if (title.isNotEmpty) {
        for (final uid in {personAId, personBId}.where((id) => id.isNotEmpty)) {
          NotificationService.sendPushNotification(
            recipientUserId: uid,
            title: title,
            body: body,
            data: {'type': 'delivery_status', 'deliveryId': _deliveryRequestId!, 'step': step.toString()},
          );
        }
      }
    } catch (e) {
      debugPrint('Error sending step push: $e');
    }
  }

  Future<void> _completeExchange() async {
    try {
      if (_deliveryRequestId != null) {
        await supabase.from('delivery_requests').update({
          'current_step': 3,
          'delivery_status': 'completed',
        }).eq('id', _deliveryRequestId!);

        // Send final push to BOTH users
        try {
          final req = await supabase
              .from('delivery_requests')
              .select('person_a_id, person_b_id')
              .eq('id', _deliveryRequestId!)
              .maybeSingle();
          if (req != null) {
            final personAId = req['person_a_id']?.toString() ?? '';
            final personBId = req['person_b_id']?.toString() ?? '';
            for (final uid in {personAId, personBId}.where((id) => id.isNotEmpty)) {
              NotificationService.sendPushNotification(
                recipientUserId: uid,
                title: '🎉 Livraison terminée !',
                body: 'Le double échange a été réalisé avec succès ! Kaywetio vous remercie pour votre confiance. À très vite ! 🤝',
                data: {'type': 'delivery_status', 'deliveryId': _deliveryRequestId!, 'status': 'completed'},
              );
            }
          }
        } catch (pushErr) {
          debugPrint('Error sending completion push: $pushErr');
        }
      }
      if (mounted) {
        setState(() {
          _currentStep = 3;
          _exchangeCompleted = true;
        });
        _showCompletionDialog();
      }
    } catch (e) {
      debugPrint('Error completing exchange: $e');
      if (mounted) {
        setState(() {
          _currentStep = 3;
          _exchangeCompleted = true;
        });
        _showCompletionDialog();
      }
    }
  }

  void _showStepConfirmation(int step) {
    final messages = [
      '',
      'Produit récupéré chez $_personAName ✓',
      'Produit remis à $_personBName ✓',
    ];
    if (step < messages.length && messages[step].isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            messages[step],
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: AppTheme.successGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.successGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppTheme.successGreen,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Échange terminé !',
              style: GoogleFonts.dmSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'La livraison a été complétée avec succès. Les deux produits ont été échangés.',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                child: Text(
                  'Retour à l\'accueil',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Suivi de livraison',
          style: GoogleFonts.dmSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_deliveryRequestId != null)
            IconButton(
              icon: const Icon(
                Icons.refresh_outlined,
                color: AppTheme.textSecondary,
              ),
              onPressed: _loadData,
              tooltip: 'Actualiser',
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.borderLight),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGreen),
            )
          : _exchangeCompleted
              ? _buildCompletedView()
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 8.5),

                      // Step progress
                      StepProgressWidget(currentStep: _currentStep),

                      SizedBox(height: 17.0),

                      // Cost sharing info
                      _buildCostBanner(),

                      SizedBox(height: 17.0),

                      // Step detail
                      StepDetailCardWidget(
                        currentStep: _currentStep,
                        personAName: _personAName,
                        personBName: _personBName,
                        personAProduct: _personAProduct,
                        personBProduct: _personBProduct,
                        personAAddress: _personAAddress,
                        personBAddress: _personBAddress,
                      ),

                      SizedBox(height: 17.0),

                      // Show user's code (for initiator and partner)
                      if (_userRole == 'initiator')
                        CodeDisplayCardWidget(
                          userName: _personAName,
                          code: _codeA,
                          color: AppTheme.primaryGreen,
                          stepDescription: _currentStep == 0
                              ? 'À donner au livreur à l\'étape 1'
                              : 'À donner au livreur à l\'étape 3',
                        ),

                      if (_userRole == 'partner')
                        CodeDisplayCardWidget(
                          userName: _personBName,
                          code: _codeB,
                          color: AppTheme.primaryOrange,
                          stepDescription: 'À donner au livreur à l\'étape 2',
                        ),

                      // Show both codes for admin/livreur view
                      if (_userRole == 'livreur') ..._buildLivreurCodes(),

                      SizedBox(height: 17.0),

                      // Code validation (for livreur role or admin)
                      if (_userRole == 'livreur' || _userRole == 'admin')
                        CodeValidationWidget(
                          currentStep: _currentStep,
                          controller: _codeController,
                          hasError: _codeError,
                          isValidating: _isValidating,
                          onValidate: _validateCode,
                          personAName: _personAName,
                          personBName: _personBName,
                        ),

                      // Demo validation for testing (shown when no specific role)
                      if (_userRole != 'livreur' && _userRole != 'admin')
                        _buildDemoValidation(),

                      SizedBox(height: 25.5),
                    ],
                  ),
                ),
    );
  }

  List<Widget> _buildLivreurCodes() {
    return [
      CodeDisplayCardWidget(
        userName: _personAName,
        code: _codeA,
        color: AppTheme.primaryGreen,
        stepDescription: 'Code pour étapes 1 et 3',
      ),
      SizedBox(height: 12.8),
      CodeDisplayCardWidget(
        userName: _personBName,
        code: _codeB,
        color: AppTheme.primaryOrange,
        stepDescription: 'Code pour étape 2',
      ),
    ];
  }

  Widget _buildDemoValidation() {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blue, size: 18),
              SizedBox(width: 8.0),
              Text(
                'Interface livreur (démonstration)',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.5),
          Text(
            'Le livreur utilise cette interface pour valider chaque étape en entrant le code fourni par le client.',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          SizedBox(height: 12.8),
          CodeValidationWidget(
            currentStep: _currentStep,
            controller: _codeController,
            hasError: _codeError,
            isValidating: _isValidating,
            onValidate: _validateCode,
            personAName: _personAName,
            personBName: _personBName,
          ),
        ],
      ),
    );
  }

  Widget _buildCostBanner() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.8),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: AppTheme.primaryGreen.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.receipt_outlined,
            color: AppTheme.primaryGreen,
            size: 20,
          ),
          SizedBox(width: 8.0),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
                children: [
                  TextSpan(
                    text: 'Livraison totale : $_totalCost FCFA',
                  ),
                  const TextSpan(text: '  •  '),
                  TextSpan(
                    text: 'Votre part : $_userShare FCFA',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.successGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppTheme.successGreen,
                size: 64,
              ),
            ),
            SizedBox(height: 25.5),
            Text(
              'Échange terminé !',
              style: GoogleFonts.dmSans(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 8.5),
            Text(
              '$_personAName et $_personBName ont bien échangé leurs produits.',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12.8),
            Container(
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: AppTheme.surfaceWhite,
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildExchangeRow(
                    _personAName,
                    _personBProduct,
                    AppTheme.primaryGreen,
                  ),
                  const Divider(height: 16),
                  _buildExchangeRow(
                    _personBName,
                    _personAProduct,
                    AppTheme.primaryOrange,
                  ),
                ],
              ),
            ),
            SizedBox(height: 25.5),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 15.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.0),
                  ),
                ),
                child: Text(
                  'Retour à l\'accueil',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExchangeRow(String name, String product, Color color) {
    return Row(
      children: [
        Container(
          width: 36.0,
          height: 36.0,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.person, color: color, size: 18),
        ),
        SizedBox(width: 12.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                'A reçu : $product',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.check_circle, color: AppTheme.successGreen, size: 20),
      ],
    );
  }
}
