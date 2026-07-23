import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ProductTabBar extends StatefulWidget {
  final int availableCount;
  final int wantedCount;
  final int completedCount;
  final int currentIndex;
  final ValueChanged<int> onTabChanged;
  final int productLimit;

  const ProductTabBar({
    super.key,
    required this.availableCount,
    required this.wantedCount,
    required this.completedCount,
    required this.currentIndex,
    required this.onTabChanged,
    this.productLimit = 10,
  });

  @override
  State<ProductTabBar> createState() => _ProductTabBarState();
}

class _ProductTabBarState extends State<ProductTabBar>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.currentIndex,
    );

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        HapticFeedback.lightImpact();
        widget.onTabChanged(_tabController.index);
      }
    });
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

    return Container(
      color: colorScheme.surface,
      child: Column(
        children: [
          // Product Limit Indicator
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mes Produits',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.3,
                      ),
                      decoration: BoxDecoration(
                        color:
                            widget.availableCount >= widget.productLimit * 0.8
                                ? AppTheme.warningOrange.withValues(alpha: 0.1)
                                : colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              widget.availableCount >= widget.productLimit * 0.8
                                  ? AppTheme.warningOrange
                                  : colorScheme.primary,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${widget.availableCount}/${widget.productLimit}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color:
                              widget.availableCount >= widget.productLimit * 0.8
                                  ? AppTheme.warningOrange
                                  : colorScheme.primary,
                        ),
                      ),
                    ),
                    if (widget.availableCount >= widget.productLimit * 0.8) ...[
                      SizedBox(width: 8.0),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _showUpgradeDialog(context);
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 4.3,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Améliorer',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Tab Bar
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16.0),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.25),
                width: 0.8,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton(
                    0,
                    'AMNA LI',
                    widget.availableCount,
                    colorScheme,
                    theme,
                  ),
                ),
                Container(
                  width: 1,
                  height: 34.0,
                  color: colorScheme.outline.withValues(alpha: 0.3),
                ),
                Expanded(
                  child: _buildTabButton(
                    1,
                    'LI LA BEUGUE',
                    widget.wantedCount,
                    colorScheme,
                    theme,
                  ),
                ),
                Container(
                  width: 1,
                  height: 34.0,
                  color: colorScheme.outline.withValues(alpha: 0.3),
                ),
                Expanded(
                  child: _buildTabButton(
                    2,
                    'LI LA WETIO',
                    widget.completedCount,
                    colorScheme,
                    theme,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8.5),
        ],
      ),
    );
  }

  Widget _buildTabButton(
    int index,
    String label,
    int count,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    final isSelected = _tabController.index == index;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _tabController.animateTo(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: 10.2, horizontal: 4.0),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
                fontSize: 9.5,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (count > 0 && index != 2) ...[
              SizedBox(height: 3.4),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 6.0,
                  vertical: 1.7,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.onPrimary.withValues(alpha: 0.2)
                      : colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 8,
                    color: isSelected
                        ? colorScheme.onPrimary
                        : colorScheme.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showUpgradeDialog(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            CustomIconWidget(
              iconName: 'star',
              color: AppTheme.warningOrange,
              size: 24.0,
            ),
            SizedBox(width: 8.0),
            Text(
              'Améliorer votre compte',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Débloquez plus de fonctionnalités :',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 17.0),
            _buildFeatureItem(context, 'Jusqu\'à 50 produits', colorScheme),
            _buildFeatureItem(
              context,
              'Priorité dans les recherches',
              colorScheme,
            ),
            _buildFeatureItem(context, 'Statistiques avancées', colorScheme),
            _buildFeatureItem(context, 'Support prioritaire', colorScheme),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Plus tard',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to upgrade screen
            },
            child: const Text('Améliorer'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context,
    String text,
    ColorScheme colorScheme,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: 8.5),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: 'check_circle',
            color: AppTheme.successGreen,
            size: 16.0,
          ),
          SizedBox(width: 8.0),
          Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
