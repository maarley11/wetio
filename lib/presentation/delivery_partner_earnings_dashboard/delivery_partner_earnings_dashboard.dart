import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../theme/app_theme.dart';
import './widgets/commission_structure_widget.dart';
import './widgets/delivery_list_widget.dart';
import './widgets/earnings_summary_widget.dart';
import './widgets/payment_schedule_widget.dart';
import './widgets/performance_metrics_widget.dart';
import './widgets/tip_tracking_widget.dart';
import '../../services/supabase_service.dart';

class DeliveryPartnerEarningsDashboard extends StatefulWidget {
  const DeliveryPartnerEarningsDashboard({super.key});

  @override
  State<DeliveryPartnerEarningsDashboard> createState() =>
      _DeliveryPartnerEarningsDashboardState();
}

class _DeliveryPartnerEarningsDashboardState
    extends State<DeliveryPartnerEarningsDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  // Real balance from Supabase
  num _currentBalance = 0;

  // Mock earnings data for the rest
  final Map<String, dynamic> _weeklyData = {
    'currentWeekEarnings': 0, // Will be updated with _currentBalance
    'weeklyGoal': 75000,
    'completedDeliveries': 23,
    'grossEarnings': 55000,
    'platformCommission': 9350,
    'tips': 2800,
    'netPayout': 48450,
    'commissionRate': 17,
    'tier': 'Silver',
    'completionRate': 96.5,
    'avgRating': 4.8,
  };

  List<Map<String, dynamic>> _deliveries = [];
  List<Map<String, dynamic>> _paymentHistory = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _refreshBalance();
  }

  Future<void> _refreshBalance() async {
    setState(() => _isLoading = true);
    try {
      final balance = await SupabaseService.getCourierBalance();
      final myRequests = await SupabaseService.getMyDeliveryRequests();
      
      final realDeliveries = <Map<String, dynamic>>[];
      for (var r in myRequests) {
        final gross = (r['delivery_fee'] ?? 2000) as int;
        final commission = (gross * 0.17).round();
        final net = gross - commission;
        final clientName = r['sender_profile']?['full_name'] ?? r['sender_name'] ?? 'Client Wetio';
        final pickup = r['pickup_address'] ?? 'Dakar';
        final delivery = r['delivery_address'] ?? 'Dakar';
        
        realDeliveries.add({
          'id': r['id'] ?? 'DEL-${DateTime.now().millisecondsSinceEpoch}',
          'date': (r['created_at'] != null) ? r['created_at'].toString().split('T').first : 'Aujourd\'hui',
          'time': (r['created_at'] != null && r['created_at'].toString().contains('T'))
              ? r['created_at'].toString().split('T').last.substring(0, 5)
              : '12:00',
          'client': clientName,
          'from': pickup,
          'to': delivery,
          'distance': '5.0 km',
          'baseAmount': gross,
          'commission': commission,
          'commissionRate': 17,
          'tip': 0,
          'netEarning': net,
          'status': r['delivery_status'] ?? 'completed',
        });
      }

      if (mounted) {
        setState(() {
          _currentBalance = balance;
          _deliveries = realDeliveries;
          _weeklyData['currentWeekEarnings'] = balance.toInt();
          _weeklyData['netPayout'] = balance.toInt();
          _weeklyData['completedDeliveries'] = realDeliveries.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleWithdrawRequest() async {
    if (_currentBalance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Votre solde est insuffisant pour un retrait.')),
      );
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmer le retrait', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text(
          'Voulez-vous retirer l\'intégralité de votre solde (${_currentBalance.toInt()} FCFA) sur votre compte configuré ?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
            child: Text('Confirmer', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true) {
      setState(() => _isLoading = true);
      try {
        final response = await SupabaseService.requestPayout(amount: _currentBalance);
        
        if (mounted) {
          if (response['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(response['message']),
                backgroundColor: AppTheme.successGreen,
              ),
            );
            _refreshBalance();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(response['message']),
                backgroundColor: Colors.red,
              ),
            );
            setState(() => _isLoading = false);
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: colorScheme.onSurface,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Mes Revenus',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.download_outlined,
              color: colorScheme.onSurface,
              size: 22,
            ),
            onPressed: _downloadStatement,
            tooltip: 'Télécharger le relevé',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: colorScheme.onSurfaceVariant,
          indicatorColor: AppTheme.primaryGreen,
          indicatorWeight: 2,
          labelStyle: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w400,
          ),
          tabs: const [
            Tab(text: 'Résumé'),
            Tab(text: 'Livraisons'),
            Tab(text: 'Paiements'),
            Tab(text: 'Commissions'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGreen),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSummaryTab(colorScheme),
                _buildDeliveriesTab(colorScheme),
                _buildPaymentsTab(colorScheme),
                _buildCommissionsTab(colorScheme),
              ],
            ),
    );
  }

  Widget _buildSummaryTab(ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EarningsSummaryWidget(weeklyData: _weeklyData),
          
          SizedBox(height: 17.0),
          
          // NEW WITHDRAW BUTTON
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _handleWithdrawRequest,
              icon: const Icon(Icons.account_balance_wallet_outlined, size: 20),
              label: Text(
                'Retirer mes fonds',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 17.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                elevation: 0,
              ),
            ),
          ),

          SizedBox(height: 25.5),
          PerformanceMetricsWidget(weeklyData: _weeklyData),
          SizedBox(height: 25.5),
          TipTrackingWidget(deliveries: _deliveries),
          SizedBox(height: 25.5),
          PaymentScheduleWidget(paymentHistory: _paymentHistory),
          SizedBox(height: 17.0),
        ],
      ),
    );
  }

  Widget _buildDeliveriesTab(ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWeeklySummaryCard(colorScheme),
          SizedBox(height: 25.5),
          DeliveryListWidget(deliveries: _deliveries),
          SizedBox(height: 17.0),
        ],
      ),
    );
  }

  Widget _buildWeeklySummaryCard(ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryGreen,
            AppTheme.primaryGreen.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Résumé de la semaine',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          SizedBox(height: 17.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem(
                'Livraisons',
                '${_weeklyData['completedDeliveries']}',
                Colors.white,
              ),
              _buildSummaryItem(
                'Brut',
                '${_weeklyData['grossEarnings']} F',
                Colors.white,
              ),
              _buildSummaryItem(
                'Commission',
                '-${_weeklyData['platformCommission']} F',
                Colors.orange[200]!,
              ),
              _buildSummaryItem(
                'Net',
                '${_weeklyData['netPayout']} F',
                Colors.greenAccent[200]!,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
        SizedBox(height: 2.5),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentsTab(ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Upcoming payment
          _buildUpcomingPaymentCard(colorScheme),
          SizedBox(height: 25.5),
          Text(
            'Historique des paiements',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 17.0),
          ..._paymentHistory.map(
            (payment) => _buildPaymentHistoryCard(payment, colorScheme),
          ),
          SizedBox(height: 17.0),
        ],
      ),
    );
  }

  Widget _buildUpcomingPaymentCard(ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, color: AppTheme.primaryGreen, size: 20),
              SizedBox(width: 8.0),
              Text(
                'Prochain virement',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: 17.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Montant estimé',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '${_weeklyData['netPayout']} FCFA',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Date prévue',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    'Dimanche 21 Jan',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 17.0),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.5),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.account_balance,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                SizedBox(width: 8.0),
                Text(
                  'Compte bancaire: **** **** 4521',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistoryCard(
    Map<String, dynamic> payment,
    ColorScheme colorScheme,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 17.0),
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    payment['id'],
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    payment['date'],
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${payment['amount']} FCFA',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 2.5,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.successGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Text(
                      'Versé',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.successGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 12.8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${payment['deliveries']} livraisons',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                'Réf: ${payment['bankRef']}',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommissionsTab(ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CommissionStructureWidget(),
          SizedBox(height: 17.0),
        ],
      ),
    );
  }

  void _downloadStatement() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Relevé de revenus téléchargé',
          style: GoogleFonts.inter(fontSize: 13),
        ),
        backgroundColor: AppTheme.successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
