import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/ad_banner_service.dart';
import '../../theme/app_theme.dart';

class AdBannerAnalyticsDashboard extends StatefulWidget {
  const AdBannerAnalyticsDashboard({super.key});

  @override
  State<AdBannerAnalyticsDashboard> createState() =>
      _AdBannerAnalyticsDashboardState();
}

class _AdBannerAnalyticsDashboardState extends State<AdBannerAnalyticsDashboard>
    with SingleTickerProviderStateMixin {
  static const String _adminEmail = 'admin@wetio.sn';

  bool get _isAdmin {
    final user = Supabase.instance.client.auth.currentUser;
    return user != null && (user.email ?? '') == _adminEmail;
  }

  final AdBannerService _service = AdBannerService();
  late TabController _tabController;
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdmin) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_rounded, size: 48, color: Colors.grey),
              SizedBox(height: 17.0),
              Text(
                'Accès réservé à l\'administrateur',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: colorScheme.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Analytics Bannières',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: colorScheme.onSurfaceVariant,
          indicatorColor: AppTheme.primaryGreen,
          labelStyle:
              GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Vue globale'),
            Tab(text: 'Par bannière'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGlobalView(colorScheme),
          _buildPerBannerView(colorScheme),
        ],
      ),
    );
  }

  // ── Global View ──────────────────────────────────────────────────────────

  Widget _buildGlobalView(ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 17.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildKpiRow(colorScheme),
          SizedBox(height: 17.0),
          _buildSectionTitle('Impressions (7 derniers jours)', colorScheme),
          SizedBox(height: 8.5),
          _buildImpressionsChart(colorScheme),
          SizedBox(height: 17.0),
          _buildSectionTitle('Répartition par catégorie', colorScheme),
          SizedBox(height: 8.5),
          _buildCategoryPieChart(colorScheme),
          SizedBox(height: 17.0),
          _buildSectionTitle('Performance globale', colorScheme),
          SizedBox(height: 8.5),
          _buildPerformanceMetrics(colorScheme),
          SizedBox(height: 17.0),
        ],
      ),
    );
  }

  Widget _buildKpiRow(ColorScheme colorScheme) {
    final kpis = [
      {
        'label': 'Impressions',
        'value': _formatNumber(_service.totalImpressions),
        'icon': Icons.visibility_rounded,
        'color': Colors.blue,
      },
      {
        'label': 'Clics',
        'value': _formatNumber(_service.totalClicks),
        'icon': Icons.touch_app_rounded,
        'color': Colors.orange,
      },
      {
        'label': 'CTR',
        'value': '${_service.overallCtr.toStringAsFixed(1)}%',
        'icon': Icons.trending_up_rounded,
        'color': AppTheme.primaryGreen,
      },
      {
        'label': 'Conversions',
        'value': _formatNumber(_service.totalConversions),
        'icon': Icons.check_circle_outline_rounded,
        'color': Colors.purple,
      },
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12.0,
      mainAxisSpacing: 12.8,
      childAspectRatio: 2.2,
      children: kpis.map((kpi) => _buildKpiCard(kpi, colorScheme)).toList(),
    );
  }

  Widget _buildKpiCard(Map<String, dynamic> kpi, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.5),
      decoration: BoxDecoration(
        color: (kpi['color'] as Color).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: (kpi['color'] as Color).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6.0),
            decoration: BoxDecoration(
              color: (kpi['color'] as Color).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(kpi['icon'] as IconData,
                color: kpi['color'] as Color, size: 18),
          ),
          SizedBox(width: 8.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  kpi['value'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  kpi['label'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImpressionsChart(ColorScheme colorScheme) {
    final data = _service.weeklyImpressions;
    return Container(
      height: 187.0,
      padding: EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 1200,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${data[groupIndex]['day']}\n${rod.toY.toInt()} vues',
                  GoogleFonts.inter(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= data.length) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    data[idx]['day'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 8,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  );
                },
                reservedSize: 20,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 35,
                getTitlesWidget: (value, meta) => Text(
                  _formatNumber(value.toInt()),
                  style: GoogleFonts.inter(
                    fontSize: 7,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: colorScheme.outline.withValues(alpha: 0.15),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(
            data.length,
            (i) => BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: (data[i]['impressions'] as int).toDouble(),
                  color: AppTheme.primaryGreen,
                  width: 20.0,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(4.0)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryPieChart(ColorScheme colorScheme) {
    final banners = _service.allBanners;
    final Map<String, int> categoryImpressions = {};
    for (final b in banners) {
      categoryImpressions[b.category] =
          (categoryImpressions[b.category] ?? 0) + b.impressions;
    }

    final colors = [
      AppTheme.primaryGreen,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.red,
    ];

    final entries = categoryImpressions.entries.toList();
    final total = entries.fold(0, (sum, e) => sum + e.value);

    if (total == 0) {
      return Container(
        height: 170.0,
        alignment: Alignment.center,
        child: Text(
          'Aucune donnée disponible',
          style: GoogleFonts.inter(
              fontSize: 12, color: colorScheme.onSurfaceVariant),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 140.0,
            height: 170.0,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    setState(() {
                      _touchedIndex =
                          response?.touchedSection?.touchedSectionIndex ?? -1;
                    });
                  },
                ),
                sections: List.generate(entries.length, (i) {
                  final isTouched = i == _touchedIndex;
                  final pct =
                      total > 0 ? (entries[i].value / total * 100) : 0.0;
                  return PieChartSectionData(
                    color: colors[i % colors.length],
                    value: entries[i].value.toDouble(),
                    title: '${pct.toStringAsFixed(0)}%',
                    radius: isTouched ? 55 : 45,
                    titleStyle: GoogleFonts.inter(
                      fontSize: isTouched ? 10 : 8,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  );
                }),
                centerSpaceRadius: 20,
                sectionsSpace: 2,
              ),
            ),
          ),
          SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                entries.length,
                (i) => Padding(
                  padding: EdgeInsets.only(bottom: 6.8),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: colors[i % colors.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 8.0),
                      Expanded(
                        child: Text(
                          entries[i].key,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatNumber(entries[i].value),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics(ColorScheme colorScheme) {
    final metrics = [
      {
        'label': 'Taux de clic moyen',
        'value': '${_service.overallCtr.toStringAsFixed(2)}%',
        'target': '5.00%',
        'progress': (_service.overallCtr / 5.0).clamp(0.0, 1.0),
        'color': AppTheme.primaryGreen,
      },
      {
        'label': 'Taux de conversion',
        'value': _service.totalClicks > 0
            ? '${(_service.totalConversions / _service.totalClicks * 100).toStringAsFixed(2)}%'
            : '0.00%',
        'target': '15.00%',
        'progress': _service.totalClicks > 0
            ? (_service.totalConversions / _service.totalClicks).clamp(0.0, 1.0)
            : 0.0,
        'color': Colors.blue,
      },
      {
        'label': 'Bannières actives',
        'value':
            '${_service.activeBanners.length}/${_service.allBanners.length}',
        'target': '${_service.allBanners.length}',
        'progress': _service.allBanners.isNotEmpty
            ? _service.activeBanners.length / _service.allBanners.length
            : 0.0,
        'color': Colors.orange,
      },
    ];

    return Container(
      padding: EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: metrics.map((m) {
          return Padding(
            padding: EdgeInsets.only(bottom: 12.8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      m['label'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          m['value'] as String,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: m['color'] as Color,
                          ),
                        ),
                        Text(
                          ' / ${m['target']}',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 4.3),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4.0),
                  child: LinearProgressIndicator(
                    value: (m['progress'] as double).clamp(0.0, 1.0),
                    backgroundColor:
                        (m['color'] as Color).withValues(alpha: 0.15),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(m['color'] as Color),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Per Banner View ──────────────────────────────────────────────────────

  Widget _buildPerBannerView(ColorScheme colorScheme) {
    final banners = _service.allBanners;
    if (banners.isEmpty) {
      return Center(
        child: Text(
          'Aucune bannière',
          style: GoogleFonts.inter(
              fontSize: 14, color: colorScheme.onSurfaceVariant),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 17.0),
      itemCount: banners.length,
      itemBuilder: (_, i) => _buildBannerAnalyticsCard(banners[i], colorScheme),
    );
  }

  Widget _buildBannerAnalyticsCard(AdBanner banner, ColorScheme colorScheme) {
    final statusColor = banner.isCurrentlyActive ? Colors.green : Colors.grey;

    return Container(
      margin: EdgeInsets.only(bottom: 17.0),
      padding: EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  banner.imageUrl,
                  width: 60.0,
                  height: 68.0,
                  fit: BoxFit.cover,
                  semanticLabel: 'Miniature ${banner.title}',
                  errorBuilder: (_, __, ___) => Container(
                    width: 60.0,
                    height: 68.0,
                    color: colorScheme.surfaceContainerHighest,
                    child: Icon(Icons.image_not_supported_outlined,
                        color: colorScheme.onSurfaceVariant, size: 20),
                  ),
                ),
              ),
              SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      banner.title,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      banner.advertiser,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 4.3),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 4.0),
                        Text(
                          banner.isCurrentlyActive ? 'Active' : 'Inactive',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 8.0),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 6.0, vertical: 1.7),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: Text(
                            banner.category,
                            style: GoogleFonts.inter(
                              fontSize: 8,
                              color: colorScheme.onSurfaceVariant,
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
          SizedBox(height: 12.8),
          Divider(
              height: 1, color: colorScheme.outline.withValues(alpha: 0.15)),
          SizedBox(height: 12.8),
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCell('Impressions', _formatNumber(banner.impressions),
                  Colors.blue, colorScheme),
              _buildStatCell('Clics', _formatNumber(banner.clicks),
                  Colors.orange, colorScheme),
              _buildStatCell('CTR', '${banner.ctr.toStringAsFixed(1)}%',
                  AppTheme.primaryGreen, colorScheme),
              _buildStatCell('Conversions', _formatNumber(banner.conversions),
                  Colors.purple, colorScheme),
            ],
          ),
          SizedBox(height: 12.8),
          // Schedule info
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.5),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              children: [
                Icon(Icons.schedule_rounded,
                    size: 14, color: AppTheme.primaryGreen),
                SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    '${_formatDate(banner.startDate)} → ${_formatDate(banner.endDate)}',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.refresh_rounded, size: 14, color: Colors.blue),
                SizedBox(width: 4.0),
                Text(
                  _formatFrequency(banner.rotationFrequencySeconds),
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCell(
      String label, String value, Color color, ColorScheme colorScheme) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 8,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, ColorScheme colorScheme) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  String _formatFrequency(int seconds) {
    if (seconds < 60) return '${seconds}s';
    return '${(seconds / 60).round()}min';
  }
}
