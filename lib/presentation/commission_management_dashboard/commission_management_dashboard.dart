import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../theme/app_theme.dart';
import './widgets/commission_header_widget.dart';
import './widgets/commission_structure_widget.dart';
import './widgets/partner_earnings_widget.dart';
import './widgets/payment_processing_widget.dart';
import './widgets/revenue_analytics_widget.dart';

class CommissionManagementDashboard extends StatefulWidget {
  const CommissionManagementDashboard({super.key});

  @override
  State<CommissionManagementDashboard> createState() =>
      _CommissionManagementDashboardState();
}

class _CommissionManagementDashboardState
    extends State<CommissionManagementDashboard>
    with SingleTickerProviderStateMixin {
  bool _isWeeklyView = true;
  late TabController _tabController;

  final double _totalRevenue = 2_450_000;
  final double _weeklyRevenue = 385_000;
  final double _monthlyRevenue = 2_450_000;
  final double _avgCommissionRate = 18.5;
  final int _totalDeliveries = 1240;
  final double _totalPartnersPayouts = 1_960_000;
  final double _pendingPayouts = 245_000;

  final List<Map<String, dynamic>> _partnerStats = [
    {
      'name': 'Amadou Diallo',
      'deliveries': 145,
      'earnings': 290_000,
      'commission': 18.0,
      'status': 'active',
      'tier': 'Gold',
    },
    {
      'name': 'Fatou Seck',
      'deliveries': 98,
      'earnings': 196_000,
      'commission': 20.0,
      'status': 'active',
      'tier': 'Silver',
    },
    {
      'name': 'Moussa Ndiaye',
      'deliveries': 67,
      'earnings': 134_000,
      'commission': 22.0,
      'status': 'pending',
      'tier': 'Bronze',
    },
    {
      'name': 'Aïssatou Thiam',
      'deliveries': 112,
      'earnings': 224_000,
      'commission': 19.0,
      'status': 'active',
      'tier': 'Gold',
    },
  ];

  final List<Map<String, dynamic>> _weeklyData = [
    {'day': 'Lun', 'amount': 45_000},
    {'day': 'Mar', 'amount': 62_000},
    {'day': 'Mer', 'amount': 38_000},
    {'day': 'Jeu', 'amount': 71_000},
    {'day': 'Ven', 'amount': 89_000},
    {'day': 'Sam', 'amount': 55_000},
    {'day': 'Dim', 'amount': 25_000},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: colorScheme.onSurface,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Gestion des Commissions',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
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
            onPressed: _exportReport,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelStyle: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurfaceVariant,
          indicatorColor: colorScheme.primary,
          tabs: const [
            Tab(text: 'Revenus'),
            Tab(text: 'Livreurs'),
            Tab(text: 'Structure'),
            Tab(text: 'Paiements'),
          ],
        ),
      ),
      body: Column(
        children: [
          CommissionHeaderWidget(
            totalRevenue: _isWeeklyView ? _weeklyRevenue : _monthlyRevenue,
            isWeeklyView: _isWeeklyView,
            avgCommissionRate: _avgCommissionRate,
            onToggle: (val) => setState(() => _isWeeklyView = val),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                RevenueAnalyticsWidget(
                  weeklyData: _weeklyData,
                  totalCommissions: _totalRevenue,
                  totalDeliveries: _totalDeliveries,
                  avgRate: _avgCommissionRate,
                ),
                PartnerEarningsWidget(
                  partnerStats: _partnerStats,
                  totalPayouts: _totalPartnersPayouts,
                  pendingPayouts: _pendingPayouts,
                ),
                CommissionStructureWidget(avgRate: _avgCommissionRate),
                PaymentProcessingWidget(
                  escrowBalance: _pendingPayouts,
                  totalProcessed: _totalPartnersPayouts,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _exportReport() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Rapport hebdomadaire généré avec succès',
          style: GoogleFonts.inter(fontSize: 13),
        ),
        backgroundColor: AppTheme.successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
