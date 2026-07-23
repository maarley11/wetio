import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../theme/app_theme.dart';
import './widgets/commission_breakdown_widget.dart';
import './widgets/confirmation_workflow_widget.dart';
import './widgets/escrow_status_widget.dart';
import './widgets/payment_methods_widget.dart';

class SecurePaymentEscrowSystem extends StatefulWidget {
  const SecurePaymentEscrowSystem({super.key});

  @override
  State<SecurePaymentEscrowSystem> createState() =>
      _SecurePaymentEscrowSystemState();
}

class _SecurePaymentEscrowSystemState extends State<SecurePaymentEscrowSystem> {
  int _currentStep = 0;
  String _selectedPaymentMethod = 'orange_money';
  bool _isPaymentProcessing = false;
  bool _isPaymentConfirmed = false;

  final double _deliveryFee = 1500;
  final double _commissionRate = 0.20;

  double get _platformCommission => _deliveryFee * _commissionRate;
  double get _partnerPayout => _deliveryFee - _platformCommission;

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 'orange_money',
      'name': 'Orange Money',
      'icon': Icons.phone_android,
      'color': Color(0xFFFF6600),
    },
    {
      'id': 'wave',
      'name': 'Wave',
      'icon': Icons.waves,
      'color': Color(0xFF1E88E5),
    },
    {
      'id': 'free_money',
      'name': 'Free Money',
      'icon': Icons.account_balance_wallet,
      'color': Color(0xFF4CAF50),
    },
  ];

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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Paiement Sécurisé',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: EdgeInsets.only(right: 12.0),
            padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.3),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.lock, color: AppTheme.primaryGreen, size: 14),
                SizedBox(width: 4.0),
                Text(
                  'Sécurisé',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDeliverySummary(context),
            SizedBox(height: 17.0),
            CommissionBreakdownWidget(
              deliveryFee: _deliveryFee,
              commissionRate: _commissionRate,
              platformCommission: _platformCommission,
              partnerPayout: _partnerPayout,
            ),
            SizedBox(height: 17.0),
            EscrowStatusWidget(
              isConfirmed: _isPaymentConfirmed,
              deliveryFee: _deliveryFee,
            ),
            SizedBox(height: 17.0),
            if (!_isPaymentConfirmed) ...[
              PaymentMethodsWidget(
                paymentMethods: _paymentMethods,
                selectedMethod: _selectedPaymentMethod,
                onMethodSelected: (method) =>
                    setState(() => _selectedPaymentMethod = method),
              ),
              SizedBox(height: 17.0),
              _buildPayButton(context),
            ] else ...[
              ConfirmationWorkflowWidget(
                onConfirm: _handleDeliveryConfirmation,
              ),
            ],
            SizedBox(height: 17.0),
            _buildSecurityInfo(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliverySummary(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Résumé de la livraison',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 12.8),
          _buildSummaryRow(context, 'De', 'Plateau, Dakar'),
          _buildSummaryRow(context, 'À', 'Almadies, Dakar'),
          _buildSummaryRow(context, 'Distance', '8.5 km'),
          _buildSummaryRow(context, 'Livreur', 'Amadou Diallo ⭐ 4.8'),
          Divider(height: 17.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Frais de livraison',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                '${_deliveryFee.toStringAsFixed(0)} FCFA',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: 8.5),
      child: Row(
        children: [
          SizedBox(
            width: 80.0,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 51.0,
      child: ElevatedButton(
        onPressed: _isPaymentProcessing ? null : _handlePayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isPaymentProcessing
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 12.0),
                  Text(
                    'Traitement en cours...',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, size: 18),
                  SizedBox(width: 8.0),
                  Text(
                    'Payer ${_deliveryFee.toStringAsFixed(0)} FCFA en séquestre',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSecurityInfo(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.verified_user, color: AppTheme.primaryGreen, size: 18),
              SizedBox(width: 8.0),
              Text(
                'Protection séquestre WETIO',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.5),
          Text(
            '• Votre paiement est bloqué jusqu\'à confirmation de réception\n'
            '• Le livreur est garanti d\'être payé après livraison\n'
            '• Remboursement automatique en cas de litige',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppTheme.primaryGreen,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePayment() async {
    setState(() => _isPaymentProcessing = true);
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _isPaymentProcessing = false;
        _isPaymentConfirmed = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Paiement sécurisé! Fonds bloqués en séquestre.',
            style: GoogleFonts.inter(fontSize: 13),
          ),
          backgroundColor: AppTheme.successGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  void _handleDeliveryConfirmation() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppTheme.successGreen, size: 28),
            SizedBox(width: 8.0),
            Text(
              'Livraison confirmée!',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          'Les fonds ont été libérés.\n\n'
          '• Livreur reçoit: ${_partnerPayout.toStringAsFixed(0)} FCFA\n'
          '• Commission WETIO: ${_platformCommission.toStringAsFixed(0)} FCFA',
          style: GoogleFonts.inter(fontSize: 13, height: 1.5),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Terminer',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
