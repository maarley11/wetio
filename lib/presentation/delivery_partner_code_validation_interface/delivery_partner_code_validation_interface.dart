import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/app_theme.dart';
import './widgets/step_progress_indicator_widget.dart';
import './widgets/code_input_keypad_widget.dart';
import './widgets/handoff_instruction_widget.dart';
import './widgets/participant_info_card_widget.dart';
import './widgets/exchange_complete_widget.dart';

class DeliveryPartnerCodeValidationInterface extends StatefulWidget {
  const DeliveryPartnerCodeValidationInterface({super.key});

  @override
  State<DeliveryPartnerCodeValidationInterface> createState() =>
      _DeliveryPartnerCodeValidationInterfaceState();
}

class _DeliveryPartnerCodeValidationInterfaceState
    extends State<DeliveryPartnerCodeValidationInterface> {
  final supabase = Supabase.instance.client;

  // Step management
  int _currentStep = 0; // 0=chez A, 1=chez B, 2=retour chez A, 3=terminé
  bool _isComplete = false;

  // Code state
  String _enteredCode = '';
  bool _hasError = false;
  bool _isValidating = false;
  bool _isSuccess = false;

  // Codes for each step (generated per exchange)
  late String _codeStep0; // Fatou's code for step 1
  late String _codeStep1; // Awa's code for step 2

  // Exchange data
  String _personAName = 'Fatou';
  String _personBName = 'Awa';
  String _personAProduct = 'Sac';
  String _personBProduct = 'Robe';
  String _personAAddress = '';
  String _personBAddress = '';
  String? _personAPhone;
  String? _personBPhone;
  int _totalCost = 2000;
  int _myCost = 1000;
  String? _deliveryRequestId;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _codeStep0 = _generateCode();
    _codeStep1 = _generateCode();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  String _generateCode() {
    final rng = Random();
    String code;
    do {
      code = (1000 + rng.nextInt(9000)).toString();
    } while (code == _codeStep0);
    return code;
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is Map<String, dynamic>) {
        _deliveryRequestId = args['deliveryRequestId'] as String?;
        _personAName = args['personAName'] as String? ?? 'Fatou';
        _personBName = args['personBName'] as String? ?? 'Awa';
        _personAProduct = args['personAProduct'] as String? ?? 'Produit A';
        _personBProduct = args['personBProduct'] as String? ?? 'Produit B';
        _personAAddress = args['personAAddress'] as String? ?? '';
        _personBAddress = args['personBAddress'] as String? ?? '';
        _personAPhone = args['personAPhone'] as String?;
        _personBPhone = args['personBPhone'] as String?;
        _totalCost = args['totalCost'] as int? ?? 2000;
        _myCost = args['myCost'] as int? ?? 1000;
        // Use provided codes if available
        if (args['codeStep0'] != null) {
          _codeStep0 = args['codeStep0'] as String;
        }
        if (args['codeStep1'] != null) {
          _codeStep1 = args['codeStep1'] as String;
        }
        if (args['currentStep'] != null) {
          _currentStep = args['currentStep'] as int;
        }
      }
    } catch (e) {
      debugPrint('Error loading validation data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String get _expectedCode {
    switch (_currentStep) {
      case 0:
        return _codeStep0; // Fatou's code
      case 1:
        return _codeStep1; // Awa's code
      default:
        return '';
    }
  }

  Future<void> _validateCode() async {
    if (_enteredCode.length != 4) return;

    setState(() {
      _isValidating = true;
      _hasError = false;
    });

    // Simulate brief validation delay for UX
    await Future.delayed(const Duration(milliseconds: 400));

    if (_enteredCode == _expectedCode) {
      HapticFeedback.mediumImpact();
      setState(() {
        _isSuccess = true;
        _isValidating = false;
      });

      // Show success briefly then advance
      await Future.delayed(const Duration(milliseconds: 900));

      if (mounted) {
        await _advanceStep();
      }
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _hasError = true;
        _isValidating = false;
        _isSuccess = false;
      });
    }
  }

  Future<void> _advanceStep() async {
    final nextStep = _currentStep + 1;

    // Update DB if we have a request ID
    if (_deliveryRequestId != null) {
      try {
        final statusMap = {
          1: 'step_1_complete',
          2: 'step_2_complete',
          3: 'completed',
        };
        await supabase.from('delivery_requests').update({
          'current_step': nextStep,
          if (statusMap[nextStep] != null)
            'delivery_status': statusMap[nextStep],
        }).eq('id', _deliveryRequestId!);
      } catch (e) {
        debugPrint('Error updating step: $e');
      }
    }

    if (mounted) {
      setState(() {
        _currentStep = nextStep;
        _enteredCode = '';
        _hasError = false;
        _isSuccess = false;
        _isValidating = false;
        if (_currentStep >= 3) {
          _isComplete = true;
        }
      });
    }
  }

  void _onCodeChanged(String code) {
    setState(() {
      _enteredCode = code;
      _hasError = false;
      _isSuccess = false;
    });
  }

  String _getAppBarTitle() {
    if (_isComplete) return 'Échange terminé';
    switch (_currentStep) {
      case 0:
        return 'Étape 1 : Chez $_personAName';
      case 1:
        return 'Étape 2 : Chez $_personBName';
      case 2:
        return 'Étape 3 : Retour chez $_personAName';
      default:
        return 'Validation livraison';
    }
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
          _getAppBarTitle(),
          style: GoogleFonts.dmSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          if (!_isComplete)
            Padding(
              padding: EdgeInsets.only(right: 12.0),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Text(
                    '${_currentStep + 1}/3',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGreen),
            )
          : _isComplete
              ? ExchangeCompleteWidget(
                  personAName: _personAName,
                  personBName: _personBName,
                  onFinish: () => Navigator.pop(context),
                )
              : _buildMainContent(),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16.0, 17.0, 16.0, 34.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step progress
          StepProgressIndicatorWidget(
            currentStep: _currentStep,
            personAName: _personAName,
            personBName: _personBName,
          ),

          SizedBox(height: 17.0),

          // Handoff instruction
          HandoffInstructionWidget(
            currentStep: _currentStep,
            personAName: _personAName,
            personBName: _personBName,
            personAProduct: _personAProduct,
            personBProduct: _personBProduct,
            personAAddress: _personAAddress,
            personBAddress: _personBAddress,
          ),

          SizedBox(height: 17.0),

          // Participant info + cost
          ParticipantInfoCardWidget(
            personAName: _personAName,
            personBName: _personBName,
            personAProduct: _personAProduct,
            personBProduct: _personBProduct,
            personAPhone: _personAPhone,
            personBPhone: _personBPhone,
            totalCost: _totalCost,
            myCost: _myCost,
          ),

          SizedBox(height: 17.0),

          // Code entry section
          if (_currentStep < 2)
            Container(
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: AppTheme.surfaceWhite,
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: const Icon(
                          Icons.lock_outline,
                          color: AppTheme.primaryGreen,
                          size: 18,
                        ),
                      ),
                      SizedBox(width: 8.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Saisir le code de validation',
                              style: GoogleFonts.dmSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              _currentStep == 0
                                  ? 'Demandez le code à $_personAName'
                                  : 'Demandez le code à $_personBName',
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 17.0),
                  CodeInputKeypadWidget(
                    enteredCode: _enteredCode,
                    hasError: _hasError,
                    isValidating: _isValidating,
                    isSuccess: _isSuccess,
                    onValidate: _validateCode,
                    onCodeChanged: _onCodeChanged,
                  ),
                ],
              ),
            )
          else
            _buildStep3FinalConfirmation(),

          SizedBox(height: 17.0),

          // Emergency contacts
          _buildEmergencyContacts(),
        ],
      ),
    );
  }

  Widget _buildStep3FinalConfirmation() {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: const Icon(
                  Icons.home_outlined,
                  color: Colors.blue,
                  size: 22,
                ),
              ),
              SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dernière étape',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                    Text(
                      'Remise finale à $_personAName',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.8),
          Text(
            'Remettez « $_personBProduct » à $_personAName. $_personAName confirmera la réception dans l\'application pour finaliser l\'échange.',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
          SizedBox(height: 17.0),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                HapticFeedback.mediumImpact();
                await _advanceStep();
              },
              icon: const Icon(Icons.check_circle_outline, size: 20),
              label: Text(
                'Confirmer la remise finale',
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 13.6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContacts() {
    return Container(
      padding: EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contacts d\'urgence',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 8.5),
          Row(
            children: [
              Expanded(
                child: _buildContactButton(
                  label: _personAName,
                  phone: _personAPhone ?? 'N/A',
                  color: AppTheme.primaryGreen,
                ),
              ),
              SizedBox(width: 8.0),
              Expanded(
                child: _buildContactButton(
                  label: _personBName,
                  phone: _personBPhone ?? 'N/A',
                  color: Colors.orange,
                ),
              ),
              SizedBox(width: 8.0),
              Expanded(
                child: _buildContactButton(
                  label: 'Support',
                  phone: 'Wetio',
                  color: AppTheme.primaryOrange,
                  isSupport: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton({
    required String label,
    required String phone,
    required Color color,
    bool isSupport = false,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isSupport
                  ? 'Contacter le support Wetio'
                  : 'Appeler $label : $phone',
              style: GoogleFonts.dmSans(),
            ),
            backgroundColor: color,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.5, horizontal: 8.0),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(
              isSupport ? Icons.headset_mic_outlined : Icons.phone_outlined,
              color: color,
              size: 20,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
