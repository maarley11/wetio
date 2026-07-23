import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class FilterModal extends StatefulWidget {
  final String selectedFilter;
  final String selectedSort;
  final Function(String filter, String sort) onFilterChanged;

  const FilterModal({
    Key? key,
    required this.selectedFilter,
    required this.selectedSort,
    required this.onFilterChanged,
  }) : super(key: key);

  @override
  State<FilterModal> createState() => _FilterModalState();
}

class _FilterModalState extends State<FilterModal> {
  late String _currentFilter;
  late String _currentSort;

  final List<Map<String, dynamic>> _filterOptions = [
    {
      'value': 'all',
      'label': 'Tous les échanges',
      'icon': 'select_all',
      'description': 'Afficher tous les échanges terminés'
    },
    {
      'value': 'direct',
      'label': 'Échanges directs',
      'icon': 'handshake',
      'description': 'Échanges sans livraison'
    },
    {
      'value': 'livraison',
      'label': 'Avec livraison',
      'icon': 'local_shipping',
      'description': 'Échanges avec service de livraison'
    },
  ];

  final List<Map<String, dynamic>> _sortOptions = [
    {
      'value': 'date_desc',
      'label': 'Plus récents en premier',
      'icon': 'calendar_today',
      'description': 'Trier par date décroissante'
    },
    {
      'value': 'date_asc',
      'label': 'Plus anciens en premier',
      'icon': 'history',
      'description': 'Trier par date croissante'
    },
    {
      'value': 'rating_desc',
      'label': 'Meilleures notes en premier',
      'icon': 'star',
      'description': 'Trier par notes décroissantes'
    },
    {
      'value': 'rating_asc',
      'label': 'Notes les plus basses en premier',
      'icon': 'star_border',
      'description': 'Trier par notes croissantes'
    },
  ];

  @override
  void initState() {
    super.initState();
    _currentFilter = widget.selectedFilter;
    _currentSort = widget.selectedSort;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: 80.h,
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 48.0,
              height: 4.3,
              decoration: BoxDecoration(
                color: colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: 25.5),

          // Header
          Row(
            children: [
              CustomIconWidget(
                iconName: 'filter_list',
                color: colorScheme.primary,
                size: 28.0,
              ),
              SizedBox(width: 12.0),
              Expanded(
                child: Text(
                  'Filtrer et trier',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: CustomIconWidget(
                  iconName: 'close',
                  color: colorScheme.onSurfaceVariant,
                  size: 24.0,
                ),
              ),
            ],
          ),
          SizedBox(height: 34.0),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filter Section
                  _buildSectionTitle('Filtrer par type', colorScheme, theme),
                  SizedBox(height: 17.0),
                  ..._filterOptions.map((option) => _buildFilterOption(
                        option,
                        _currentFilter == option['value'],
                        () {
                          setState(() => _currentFilter = option['value']);
                          HapticFeedback.lightImpact();
                        },
                        colorScheme,
                        theme,
                      )),
                  SizedBox(height: 34.0),

                  // Sort Section
                  _buildSectionTitle('Trier par', colorScheme, theme),
                  SizedBox(height: 17.0),
                  ..._sortOptions.map((option) => _buildSortOption(
                        option,
                        _currentSort == option['value'],
                        () {
                          setState(() => _currentSort = option['value']);
                          HapticFeedback.lightImpact();
                        },
                        colorScheme,
                        theme,
                      )),
                  SizedBox(height: 34.0),

                  // Reset and Apply buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _currentFilter = 'all';
                              _currentSort = 'date_desc';
                            });
                            HapticFeedback.lightImpact();
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: colorScheme.outline),
                            padding: EdgeInsets.symmetric(vertical: 12.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: CustomIconWidget(
                            iconName: 'refresh',
                            color: colorScheme.onSurface,
                            size: 20.0,
                          ),
                          label: Text(
                            'Réinitialiser',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.0),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            widget.onFilterChanged(
                                _currentFilter, _currentSort);
                            Navigator.pop(context);
                            HapticFeedback.lightImpact();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            padding: EdgeInsets.symmetric(vertical: 12.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: CustomIconWidget(
                            iconName: 'check',
                            color: colorScheme.onPrimary,
                            size: 20.0,
                          ),
                          label: Text(
                            'Appliquer les filtres',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
      String title, ColorScheme colorScheme, ThemeData theme) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
    );
  }

  Widget _buildFilterOption(
    Map<String, dynamic> option,
    bool isSelected,
    VoidCallback onTap,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.0),
      child: Material(
        color: isSelected
            ? colorScheme.primaryContainer.withValues(alpha: 0.3)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.outline.withValues(alpha: 0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primary.withValues(alpha: 0.2)
                        : colorScheme.surfaceContainer.withValues(alpha: 0.5) ??
                            colorScheme.surface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CustomIconWidget(
                    iconName: option['icon'],
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                    size: 20.0,
                  ),
                ),
                SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option['label'],
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 4.3),
                      Text(
                        option['description'],
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  CustomIconWidget(
                    iconName: 'check_circle',
                    color: colorScheme.primary,
                    size: 24.0,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSortOption(
    Map<String, dynamic> option,
    bool isSelected,
    VoidCallback onTap,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.0),
      child: Material(
        color: isSelected
            ? colorScheme.secondaryContainer.withValues(alpha: 0.3)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? colorScheme.secondary
                    : colorScheme.outline.withValues(alpha: 0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.secondary.withValues(alpha: 0.2)
                        : colorScheme.surfaceContainer.withValues(alpha: 0.5) ??
                            colorScheme.surface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CustomIconWidget(
                    iconName: option['icon'],
                    color: isSelected
                        ? colorScheme.secondary
                        : colorScheme.onSurfaceVariant,
                    size: 20.0,
                  ),
                ),
                SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option['label'],
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected
                              ? colorScheme.secondary
                              : colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 4.3),
                      Text(
                        option['description'],
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  CustomIconWidget(
                    iconName: 'check_circle',
                    color: colorScheme.secondary,
                    size: 24.0,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
