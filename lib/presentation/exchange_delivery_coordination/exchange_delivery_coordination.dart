import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import './widgets/confirmation_code_widget.dart';
import './widgets/cost_sharing_widget.dart';
import './widgets/delivery_steps_widget.dart';
import './widgets/distance_validation_widget.dart';
import './widgets/exchange_summary_widget.dart';
import './widgets/rating_dialog_widget.dart';

class ExchangeDeliveryCoordination extends StatefulWidget {
  const ExchangeDeliveryCoordination({super.key});

  @override
  State<ExchangeDeliveryCoordination> createState() =>
      _ExchangeDeliveryCoordinationState();
}

class _ExchangeDeliveryCoordinationState
    extends State<ExchangeDeliveryCoordination> {
  final supabase = Supabase.instance.client;

  bool _isLoading = true;
  bool _isInitiator = true;
  int _currentStep = 0;
  String? _deliveryRequestId;
  String? _deliveryPersonName;
  String? _deliveryPersonPhone;
  String? _deliveryPersonImage;
  double? _deliveryPersonLat;
  double? _deliveryPersonLng;
  String _deliveryStatus = 'pending';
  bool _partnerAccepted = false;
  bool _distanceValid = true;
  double _distanceKm = 0;
  bool _showRating = false;

  // Confirmation codes
  String _myCode = '';
  String _partnerCode = '';
  final _codeInputController = TextEditingController();
  bool _codeError = false;

  // Exchange info
  Map<String, dynamic> _exchangeData = {};
  Map<String, dynamic> _personAData = {};
  Map<String, dynamic> _personBData = {};

  // Cost
  int _totalCost = 0;
  int _myCost = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _codeInputController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is Map<String, dynamic>) {
        _deliveryRequestId = args['deliveryRequestId'] as String?;
        _isInitiator = args['isInitiator'] as bool? ?? true;
        _exchangeData = args['exchangeData'] as Map<String, dynamic>? ?? {};
        _personAData = args['personA'] as Map<String, dynamic>? ?? {};
        _personBData = args['personB'] as Map<String, dynamic>? ?? {};
      }

      // Calculate distance
      if (_personAData['lat'] != null && _personBData['lat'] != null) {
        _distanceKm = _calculateDistance(
          _personAData['lat'] as double,
          _personAData['lng'] as double,
          _personBData['lat'] as double,
          _personBData['lng'] as double,
        );
        _distanceValid = _distanceKm <= 10.0;
      }

      // Calculate cost
      _totalCost = (_distanceKm * 500).round() + 1000;
      _myCost = (_totalCost / 2).round();

      // Generate confirmation codes
      _myCode = _generateCode();
      _partnerCode = _generateCode();

      if (_deliveryRequestId != null) {
        await _loadDeliveryStatus();
      }
    } catch (e) {
      debugPrint('Error loading exchange delivery data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadDeliveryStatus() async {
    try {
      final response = await supabase
          .from('delivery_requests')
          .select('*, delivery_persons(*)')
          .eq('id', _deliveryRequestId!)
          .single();

      if (mounted) {
        setState(() {
          _deliveryStatus = response['delivery_status'] ?? 'pending';
          _currentStep = response['current_step'] ?? 0;
          _partnerAccepted = response['person_b_accepted'] ?? false;
          if (response['delivery_persons'] != null) {
            final dp = response['delivery_persons'] as Map<String, dynamic>;
            _deliveryPersonName = dp['full_name'];
            _deliveryPersonPhone = dp['phone'];
            _deliveryPersonImage = dp['profile_image'];
            _deliveryPersonLat = dp['current_lat']?.toDouble();
            _deliveryPersonLng = dp['current_lng']?.toDouble();
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading delivery status: $e');
    }
  }

  double _calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const R = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _toRad(double deg) => deg * pi / 180;

  String _generateCode() {
    final rng = Random();
    return (1000 + rng.nextInt(9000)).toString();
  }

  Future<void> _validateCode() async {
    final entered = _codeInputController.text.trim();
    final expectedCode = _isInitiator ? _partnerCode : _myCode;

    if (entered == expectedCode) {
      setState(() {
        _codeError = false;
        _currentStep++;
        _codeInputController.clear();
      });

      HapticFeedback.mediumImpact();

      if (_currentStep >= 3) {
        setState(() => _showRating = true);
      }

      // Update step in DB
      if (_deliveryRequestId != null) {
        try {
          await supabase.from('delivery_requests').update(
              {'current_step': _currentStep}).eq('id', _deliveryRequestId!);
        } catch (e) {
          debugPrint('Error updating step: $e');
        }
      }
    } else {
      setState(() => _codeError = true);
      HapticFeedback.heavyImpact();
    }
  }

  Future<void> _submitRating(int rating) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (_deliveryRequestId != null && userId != null) {
        await supabase.from('delivery_ratings').insert({
          'delivery_request_id': _deliveryRequestId,
          'delivery_person_id': _exchangeData['deliveryPersonId'],
          'rater_id': userId,
          'rating': rating,
        });
      }

      if (mounted) {
        setState(() => _showRating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Échange terminé ! Merci pour votre évaluation.',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 1200));
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.completedExchangeArchive,
            (route) => route.settings.name == AppRoutes.homeFeed,
          );
        }
      }
    } catch (e) {
      debugPrint('Error submitting rating: $e');
      // Even if rating fails, navigate to completed archive
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.completedExchangeArchive,
          (route) => route.settings.name == AppRoutes.homeFeed,
        );
      }
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
          'Échange avec Livreur',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGreen),
            )
          : _showRating
              ? RatingDialogWidget(
                  onSubmit: _submitRating,
                  deliveryPersonName: _deliveryPersonName ?? 'Livreur',
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Distance validation
                      if (!_distanceValid)
                        DistanceValidationWidget(
                          distanceKm: _distanceKm,
                          isValid: false,
                        ),

                      if (_distanceValid) ..._buildContent(),
                    ],
                  ),
                ),
    );
  }

  List<Widget> _buildContent() {
    return [
      // Exchange summary
      ExchangeSummaryWidget(
        personAName: _personAData['name'] ?? 'Personne A',
        personBName: _personBData['name'] ?? 'Personne B',
        personAProduct: _personAData['product'] ?? 'Produit A',
        personBProduct: _personBData['product'] ?? 'Produit B',
        personAAddress: _personAData['address'] ?? '',
        personBAddress: _personBData['address'] ?? '',
      ),

      SizedBox(height: 17.0),

      // Distance info
      DistanceValidationWidget(distanceKm: _distanceKm, isValid: true),

      SizedBox(height: 17.0),

      // Delivery steps
      DeliveryStepsWidget(
        currentStep: _currentStep,
        personAName: _personAData['name'] ?? 'Personne A',
        personBName: _personBData['name'] ?? 'Personne B',
        personAProduct: _personAData['product'] ?? 'Produit A',
        personBProduct: _personBData['product'] ?? 'Produit B',
      ),

      SizedBox(height: 17.0),

      // Confirmation code
      if (_deliveryStatus == 'accepted' || _deliveryStatus == 'in_transit')
        ConfirmationCodeWidget(
          myCode: _myCode,
          currentStep: _currentStep,
          isInitiator: _isInitiator,
          codeController: _codeInputController,
          hasError: _codeError,
          onValidate: _validateCode,
        ),

      SizedBox(height: 17.0),

      // Livreur confirmed info
      if (_deliveryStatus == 'accepted' && _deliveryPersonName != null)
        _buildDeliveryPersonCard(),

      SizedBox(height: 17.0),

      // Cost sharing
      CostSharingWidget(
        totalCost: _totalCost,
        myCost: _myCost,
        distanceKm: _distanceKm,
      ),

      SizedBox(height: 34.0),
    ];
  }

  Widget _buildDeliveryPersonCard() {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppTheme.successGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: AppTheme.successGreen.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: AppTheme.successGreen,
                size: 20,
              ),
              SizedBox(width: 8.0),
              Text(
                'Livreur Confirmé',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.successGreen,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.8),
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: _deliveryPersonImage != null
                    ? NetworkImage(_deliveryPersonImage!)
                    : null,
                backgroundColor: AppTheme.borderLight,
                child: _deliveryPersonImage == null
                    ? const Icon(Icons.person, color: AppTheme.textSecondary)
                    : null,
              ),
              SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _deliveryPersonName ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (_deliveryPersonPhone != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.phone,
                            size: 14,
                            color: AppTheme.textSecondary,
                          ),
                          SizedBox(width: 4.0),
                          Text(
                            _deliveryPersonPhone!,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Text(
                  'En route',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
