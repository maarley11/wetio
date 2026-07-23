import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_routes.dart';
import './widgets/exchange_participants_widget.dart';
import './widgets/cost_preview_widget.dart';
import './widgets/distance_check_widget.dart';
import './widgets/approval_request_banner_widget.dart';

class DeliveryRequestConfirmationScreen extends StatefulWidget {
  const DeliveryRequestConfirmationScreen({super.key});

  @override
  State<DeliveryRequestConfirmationScreen> createState() =>
      _DeliveryRequestConfirmationScreenState();
}

class _DeliveryRequestConfirmationScreenState
    extends State<DeliveryRequestConfirmationScreen> {
  final supabase = Supabase.instance.client;

  bool _isLoading = false;
  bool _isInitiator = true;
  bool _partnerAccepted = false;
  bool _distanceValid = true;
  double _distanceKm = 3.5;
  int _totalCost = 2000;
  int _userShare = 1000;

  String _initiatorName = 'Fatou';
  String _partnerName = 'Awa';
  String _initiatorProduct = 'Sac en cuir';
  String _partnerProduct = 'Robe fleurie';
  String? _exchangeId;
  String? _deliveryRequestId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadArguments();
    });
  }

  void _loadArguments() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is Map<String, dynamic>) {
      setState(() {
        _isInitiator = args['isInitiator'] as bool? ?? true;
        _initiatorName = args['initiatorName'] as String? ?? 'Fatou';
        _partnerName = args['partnerName'] as String? ?? 'Awa';
        _initiatorProduct =
            args['initiatorProduct'] as String? ?? 'Sac en cuir';
        _partnerProduct = args['partnerProduct'] as String? ?? 'Robe fleurie';
        _exchangeId = args['exchangeId'] as String?;
        _deliveryRequestId = args['deliveryRequestId'] as String?;

        final double? lat1 = args['initiatorLat'] as double?;
        final double? lng1 = args['initiatorLng'] as double?;
        final double? lat2 = args['partnerLat'] as double?;
        final double? lng2 = args['partnerLng'] as double?;

        if (lat1 != null && lng1 != null && lat2 != null && lng2 != null) {
          _distanceKm = _calculateDistance(lat1, lng1, lat2, lng2);
        }
        _distanceValid = _distanceKm <= 10.0;
        _totalCost = (_distanceKm * 300).round() + 1000;
        if (_totalCost < 2000) _totalCost = 2000;
        _userShare = (_totalCost / 2).round();

        _partnerAccepted = args['partnerAccepted'] as bool? ?? false;
      });
    }
  }

  double _calculateDistance(
      double lat1, double lng1, double lat2, double lng2) {
    const R = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _toRad(double deg) => deg * pi / 180;

  Future<void> _handleAccept() async {
    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();
    try {
      if (_deliveryRequestId != null) {
        await supabase.from('delivery_requests').update({
          'person_b_accepted': true,
          'delivery_status': 'accepted'
        }).eq('id', _deliveryRequestId!);
      }
      if (mounted) {
        setState(() => _partnerAccepted = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Livraison acceptée ! Choisissez maintenant un livreur.',
              style: GoogleFonts.dmSans(color: Colors.white),
            ),
            backgroundColor: AppTheme.successGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          Navigator.pushNamed(
            context,
            AppRoutes.deliveryPartnerSearch,
            arguments: {
              'exchangeId': _exchangeId,
              'deliveryRequestId': _deliveryRequestId,
              'isSharedDelivery': true,
              'initiatorName': _initiatorName,
              'partnerName': _partnerName,
            },
          );
        }
      }
    } catch (e) {
      debugPrint('Error accepting delivery: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur lors de l\'acceptation. Réessayez.',
              style: GoogleFonts.dmSans(),
            ),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRefuse() async {
    HapticFeedback.lightImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        title: Text(
          'Refuser la livraison ?',
          style: GoogleFonts.dmSans(
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        content: Text(
          'Si vous refusez, vous devrez organiser l\'échange autrement (point de rencontre).',
          style: GoogleFonts.dmSans(
            color: AppTheme.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Annuler',
              style: GoogleFonts.dmSans(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
            child: Text(
              'Refuser',
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        if (_deliveryRequestId != null) {
          await supabase.from('delivery_requests').update({
            'person_b_accepted': false,
            'delivery_status': 'refused'
          }).eq('id', _deliveryRequestId!);
        }
      } catch (e) {
        debugPrint('Error refusing delivery: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Livraison refusée. Organisez un point de rencontre.',
              style: GoogleFonts.dmSans(),
            ),
            backgroundColor: AppTheme.warningOrange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _organizeDelivery() async {
    if (!_distanceValid) return;
    setState(() => _isLoading = true);
    try {
      final userId = supabase.auth.currentUser?.id;
      String? requestId = _deliveryRequestId;

      if (requestId == null && userId != null && _exchangeId != null) {
        final result = await supabase
            .from('delivery_requests')
            .insert({
              'exchange_id': _exchangeId,
              'initiator_id': userId,
              'delivery_status': 'pending_acceptance',
              'person_b_accepted': false,
              'total_cost': _totalCost,
              'distance_km': _distanceKm,
            })
            .select()
            .single();
        requestId = result['id'] as String?;
        setState(() => _deliveryRequestId = requestId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Demande envoyée à $_partnerName !',
              style: GoogleFonts.dmSans(color: Colors.white),
            ),
            backgroundColor: AppTheme.primaryGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error organizing delivery: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
          'Livraison partagée',
          style: GoogleFonts.dmSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.borderLight),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8.5),

            // Distance check
            DistanceCheckWidget(
              distanceKm: _distanceKm,
              isValid: _distanceValid,
            ),

            SizedBox(height: 17.0),

            // Exchange participants
            ExchangeParticipantsWidget(
              initiatorName: _initiatorName,
              initiatorProduct: _initiatorProduct,
              partnerName: _partnerName,
              partnerProduct: _partnerProduct,
            ),

            SizedBox(height: 17.0),

            // Cost preview
            CostPreviewWidget(
              totalCost: _totalCost,
              userShare: _userShare,
            ),

            SizedBox(height: 17.0),

            // Approval banner (shown to partner)
            if (!_isInitiator && !_partnerAccepted)
              ApprovalRequestBannerWidget(
                initiatorName: _initiatorName,
                onAccept: _handleAccept,
                onRefuse: _handleRefuse,
                isLoading: _isLoading,
              ),

            // Status for initiator waiting
            if (_isInitiator && !_partnerAccepted) _buildWaitingStatus(),

            // Both accepted - proceed to partner selection
            if (_partnerAccepted) _buildBothAcceptedSection(),

            SizedBox(height: 25.5),

            // Initiator action button
            if (_isInitiator && !_partnerAccepted && _distanceValid)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _organizeDelivery,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send_outlined, size: 20),
                  label: Text(
                    'Organiser la livraison',
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 15.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.0),
                    ),
                    elevation: 2,
                  ),
                ),
              ),

            SizedBox(height: 17.0),
          ],
        ),
      ),
    );
  }

  Widget _buildWaitingStatus() {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppTheme.warningOrange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: AppTheme.warningOrange.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppTheme.warningOrange,
            ),
          ),
          SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'En attente de $_partnerName',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.warningOrange,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$_partnerName doit accepter la livraison partagée avant de choisir un livreur.',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBothAcceptedSection() {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppTheme.successGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: AppTheme.successGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: AppTheme.successGreen,
                size: 28,
              ),
              SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Les deux parties ont accepté !',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.successGreen,
                      ),
                    ),
                    Text(
                      'Choisissez maintenant un livreur ensemble.',
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
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.pushNamed(
                  context,
                  AppRoutes.deliveryPartnerSearch,
                  arguments: {
                    'exchangeId': _exchangeId,
                    'deliveryRequestId': _deliveryRequestId,
                    'isSharedDelivery': true,
                  },
                );
              },
              icon: const Icon(Icons.search, size: 20),
              label: Text(
                'Choisir un livreur',
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 13.6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
