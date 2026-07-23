import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class AnalyticsDashboard extends StatelessWidget {
  final Map<String, dynamic> analyticsData;

  const AnalyticsDashboard({super.key, required this.analyticsData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with premium badge
        Row(
          children: [
            CustomIconWidget(
              iconName: 'analytics',
              color: AppTheme.premiumGold,
              size: 32.0,
            ),
            SizedBox(width: 12.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Analytics Premium',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.premiumGold,
                    ),
                  ),
                  Text(
                    'Vos performances détaillées',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.premiumGold, Colors.amber.shade600],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'PREMIUM',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: 25.5),

        // Key metrics cards
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                context,
                'Revenus mensuels',
                analyticsData['monthlyEarnings'],
                'trending_up',
                AppTheme.successGreen,
                analyticsData['trends']['earningsGrowth'],
                theme,
                colorScheme,
              ),
            ),
            SizedBox(width: 12.0),
            Expanded(
              child: _buildMetricCard(
                context,
                'Livraisons',
                '${analyticsData['totalDeliveries']}',
                'local_shipping',
                Colors.blue,
                analyticsData['trends']['deliveriesGrowth'],
                theme,
                colorScheme,
              ),
            ),
          ],
        ),

        SizedBox(height: 17.0),

        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                context,
                'Note moyenne',
                '${analyticsData['customerRating']}⭐',
                'star',
                Colors.amber,
                analyticsData['trends']['ratingImprovement'],
                theme,
                colorScheme,
              ),
            ),
            SizedBox(width: 12.0),
            Expanded(
              child: _buildMetricCard(
                context,
                'Taux de succès',
                '${analyticsData['completionRate']}%',
                'check_circle',
                AppTheme.premiumGold,
                '+2%',
                theme,
                colorScheme,
              ),
            ),
          ],
        ),

        SizedBox(height: 34.0),

        // Earnings chart
        Container(
          padding: EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CustomIconWidget(
                    iconName: 'timeline',
                    color: AppTheme.premiumGold,
                    size: 24.0,
                  ),
                  SizedBox(width: 8.0),
                  Text(
                    'Évolution des revenus',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 25.5),
              Container(
                height: 212.5,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            const months = [
                              'Jan',
                              'Fév',
                              'Mar',
                              'Avr',
                              'Mai',
                              'Jun',
                            ];
                            return Text(
                              value < months.length
                                  ? months[value.toInt()]
                                  : '',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '${(value / 1000).toInt()}k',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: [
                          FlSpot(0, 25000),
                          FlSpot(1, 30000),
                          FlSpot(2, 28000),
                          FlSpot(3, 35000),
                          FlSpot(4, 40000),
                          FlSpot(5, 45000),
                        ],
                        isCurved: true,
                        color: AppTheme.premiumGold,
                        barWidth: 3,
                        dotData: FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppTheme.premiumGold.withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 25.5),

        // Performance insights
        Container(
          padding: EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.premiumGold.withValues(alpha: 0.1),
                AppTheme.premiumGold.withValues(alpha: 0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.premiumGold.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CustomIconWidget(
                    iconName: 'lightbulb',
                    color: AppTheme.premiumGold,
                    size: 24.0,
                  ),
                  SizedBox(width: 8.0),
                  Text(
                    'Insights Premium',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.premiumGold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 17.0),
              _buildInsightItem(
                'Meilleurs créneaux',
                'Vos livraisons les plus rentables sont entre 14h-17h',
                'schedule',
                theme,
                colorScheme,
              ),
              _buildInsightItem(
                'Zone optimale',
                'Le Plateau génère 35% de vos revenus avec le moins de distance',
                'location_on',
                theme,
                colorScheme,
              ),
              _buildInsightItem(
                'Recommandation',
                'Augmentez vos créneaux week-end pour +20% de revenus',
                'trending_up',
                theme,
                colorScheme,
              ),
            ],
          ),
        ),

        SizedBox(height: 25.5),

        // Customer feedback summary
        Container(
          padding: EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CustomIconWidget(
                    iconName: 'feedback',
                    color: colorScheme.primary,
                    size: 24.0,
                  ),
                  SizedBox(width: 8.0),
                  Text(
                    'Feedback clients',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 17.0),
              Row(
                children: [
                  Expanded(
                    child: _buildFeedbackStat(
                      'Ponctualité',
                      '4.9/5',
                      Colors.green,
                      theme,
                      colorScheme,
                    ),
                  ),
                  Expanded(
                    child: _buildFeedbackStat(
                      'Professionnalisme',
                      '4.8/5',
                      Colors.blue,
                      theme,
                      colorScheme,
                    ),
                  ),
                  Expanded(
                    child: _buildFeedbackStat(
                      'Communication',
                      '4.7/5',
                      Colors.orange,
                      theme,
                      colorScheme,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String title,
    String value,
    String iconName,
    Color color,
    String trend,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomIconWidget(
                  iconName: iconName,
                  color: color,
                  size: 20.0,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                decoration: BoxDecoration(
                  color: trend.startsWith('+')
                      ? AppTheme.successGreen.withValues(alpha: 0.1)
                      : AppTheme.errorRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  trend,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: trend.startsWith('+')
                        ? AppTheme.successGreen
                        : AppTheme.errorRed,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 17.0),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem(
    String title,
    String description,
    String iconName,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 17.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 4.3),
            padding: EdgeInsets.all(6.0),
            decoration: BoxDecoration(
              color: AppTheme.premiumGold.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: CustomIconWidget(
              iconName: iconName,
              color: AppTheme.premiumGold,
              size: 16.0,
            ),
          ),
          SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.premiumGold,
                  ),
                ),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
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

  Widget _buildFeedbackStat(
    String category,
    String score,
    Color color,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Column(
      children: [
        Text(
          score,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          category,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
