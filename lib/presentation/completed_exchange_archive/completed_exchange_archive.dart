import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/archive_empty_state.dart';
import './widgets/completed_exchange_card.dart';
import './widgets/filter_modal.dart';
import './widgets/search_bar.dart';
import './widgets/statistics_header.dart';

class CompletedExchangeArchive extends StatefulWidget {
  const CompletedExchangeArchive({Key? key}) : super(key: key);

  @override
  State<CompletedExchangeArchive> createState() =>
      _CompletedExchangeArchiveState();
}

class _CompletedExchangeArchiveState extends State<CompletedExchangeArchive> {
  bool _isLoading = true;
  bool _isRefreshing = false;
  List<Map<String, dynamic>> _completedExchanges = [];
  List<Map<String, dynamic>> _filteredExchanges = [];
  String _searchQuery = '';
  String _selectedFilter = 'all';
  String _selectedSort = 'date_desc';

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadCompletedExchanges();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCompletedExchanges() async {
    try {
      setState(() => _isLoading = true);

      final exchanges = await SupabaseService.getCompletedExchanges();

      setState(() {
        _completedExchanges = exchanges;
        _filteredExchanges = exchanges;
        _isLoading = false;
      });

      _applyFiltersAndSort();
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Erreur lors du chargement des échanges');
    }
  }

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    await _loadCompletedExchanges();
    setState(() => _isRefreshing = false);
    HapticFeedback.lightImpact();
  }

  void _applyFiltersAndSort() {
    List<Map<String, dynamic>> filtered = List.from(_completedExchanges);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((exchange) {
        final targetProduct =
            exchange['target_product_title']?.toLowerCase() ?? '';
        final requesterProduct =
            exchange['requester_product_title']?.toLowerCase() ?? '';
        final query = _searchQuery.toLowerCase();
        return targetProduct.contains(query) ||
            requesterProduct.contains(query);
      }).toList();
    }

    // Apply exchange method filter
    if (_selectedFilter != 'all') {
      filtered = filtered
          .where((exchange) => exchange['exchange_method'] == _selectedFilter)
          .toList();
    }

    // Apply sorting
    filtered.sort((a, b) {
      switch (_selectedSort) {
        case 'date_asc':
          return DateTime.parse(a['completion_date'])
              .compareTo(DateTime.parse(b['completion_date']));
        case 'rating_desc':
          final aRating =
              (a['rating_given'] ?? 0) + (a['rating_received'] ?? 0);
          final bRating =
              (b['rating_given'] ?? 0) + (b['rating_received'] ?? 0);
          return bRating.compareTo(aRating);
        case 'rating_asc':
          final aRating =
              (a['rating_given'] ?? 0) + (a['rating_received'] ?? 0);
          final bRating =
              (b['rating_given'] ?? 0) + (b['rating_received'] ?? 0);
          return aRating.compareTo(bRating);
        case 'date_desc':
        default:
          return DateTime.parse(b['completion_date'])
              .compareTo(DateTime.parse(a['completion_date']));
      }
    });

    setState(() => _filteredExchanges = filtered);
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    _applyFiltersAndSort();
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => FilterModal(
        selectedFilter: _selectedFilter,
        selectedSort: _selectedSort,
        onFilterChanged: (filter, sort) {
          setState(() {
            _selectedFilter = filter;
            _selectedSort = sort;
          });
          _applyFiltersAndSort();
        },
      ),
    );
  }

  Future<void> _showDeleteConfirmation(Map<String, dynamic> exchange) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            CustomIconWidget(
              iconName: 'warning',
              color: AppTheme.warningOrange,
              size: 24.0,
            ),
            SizedBox(width: 8.0),
            Text(
              'Supprimer l\'échange',
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
              'Êtes-vous sûr de vouloir supprimer cet échange de votre historique ?',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 17.0),
            Container(
              padding: EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: AppTheme.warningOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.warningOrange.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                'Cette action est irréversible. L\'échange sera définitivement supprimé de votre archive.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.warningOrange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Annuler',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteExchange(exchange);
    }
  }

  Future<void> _deleteExchange(Map<String, dynamic> exchange) async {
    try {
      await SupabaseService.deleteCompletedExchange(exchange['id']);

      setState(() {
        _completedExchanges.removeWhere((e) => e['id'] == exchange['id']);
        _filteredExchanges.removeWhere((e) => e['id'] == exchange['id']);
      });

      _showSuccessSnackBar('Échange supprimé de l\'archive');
      HapticFeedback.lightImpact();
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la suppression');
    }
  }

  Future<void> _exportExchangeHistory() async {
    try {
      HapticFeedback.lightImpact();

      final exported = await SupabaseService.exportExchangeHistory();

      if (exported) {
        _showSuccessSnackBar('Historique exporté avec succès');
      } else {
        _showErrorSnackBar('Erreur lors de l\'exportation');
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors de l\'exportation');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: CustomAppBar(
        title: "Échanges Terminés",
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_completedExchanges.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) {
                switch (value) {
                  case 'export':
                    _exportExchangeHistory();
                    break;
                  case 'filter':
                    _showFilterModal();
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'filter',
                  child: Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'filter_list',
                        color: colorScheme.onSurface,
                        size: 20.0,
                      ),
                      SizedBox(width: 8.0),
                      const Text('Filtrer'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'export',
                  child: Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'file_download',
                        color: colorScheme.onSurface,
                        size: 20.0,
                      ),
                      SizedBox(width: 8.0),
                      const Text('Exporter'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _handleRefresh,
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Statistics Header
                    StatisticsHeader(
                      totalExchanges: _completedExchanges.length,
                      storageInfo: _calculateStorageInfo(),
                    ),

                    // Search Bar
                    if (_completedExchanges.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.all(16.0),
                        child: ArchiveSearchBar(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          onFilterTap: _showFilterModal,
                          hasActiveFilters: _selectedFilter != 'all' ||
                              _selectedSort != 'date_desc',
                        ),
                      ),

                    // Exchange List or Empty State
                    _filteredExchanges.isEmpty
                        ? ArchiveEmptyState(
                            hasExchanges: _completedExchanges.isNotEmpty,
                            searchQuery: _searchQuery,
                            onClearSearch: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            itemCount: _filteredExchanges.length,
                            itemBuilder: (context, index) {
                              final exchange = _filteredExchanges[index];
                              return CompletedExchangeCard(
                                exchange: exchange,
                                onTap: () => _showExchangeDetails(exchange),
                                onDelete: () =>
                                    _showDeleteConfirmation(exchange),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
    );
  }

  Map<String, dynamic> _calculateStorageInfo() {
    final totalSize =
        _completedExchanges.length * 2.5; // Approximate KB per exchange
    final usagePercentage = (totalSize / 1024) * 100; // Percentage of 1MB

    return {
      'totalSize': totalSize,
      'usagePercentage': usagePercentage.clamp(0.0, 100.0),
      'maxSize': 1024.0, // 1MB limit
    };
  }

  void _showExchangeDetails(Map<String, dynamic> exchange) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: 90.h,
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
                  iconName: 'history',
                  color: colorScheme.primary,
                  size: 28.0,
                ),
                SizedBox(width: 12.0),
                Expanded(
                  child: Text(
                    'Détails de l\'échange',
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
            SizedBox(height: 25.5),

            // Exchange Details Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailSection(
                      'Produits échangés',
                      Column(
                        children: [
                          _buildProductInfo(
                            'Mon produit',
                            exchange['target_product_title'],
                            Icons.arrow_upward,
                            AppTheme.successGreen,
                          ),
                          SizedBox(height: 17.0),
                          _buildProductInfo(
                            'Produit reçu',
                            exchange['requester_product_title'],
                            Icons.arrow_downward,
                            colorScheme.primary,
                          ),
                        ],
                      ),
                      colorScheme,
                      theme,
                    ),
                    SizedBox(height: 25.5),

                    _buildDetailSection(
                      'Évaluations',
                      Row(
                        children: [
                          Expanded(
                            child: _buildRatingInfo(
                              'Note donnée',
                              exchange['rating_given'] ?? 0,
                              colorScheme,
                              theme,
                            ),
                          ),
                          SizedBox(width: 16.0),
                          Expanded(
                            child: _buildRatingInfo(
                              'Note reçue',
                              exchange['rating_received'] ?? 0,
                              colorScheme,
                              theme,
                            ),
                          ),
                        ],
                      ),
                      colorScheme,
                      theme,
                    ),
                    SizedBox(height: 25.5),

                    _buildDetailSection(
                      'Informations',
                      Column(
                        children: [
                          _buildInfoRow(
                            'Méthode d\'échange',
                            exchange['exchange_method'] == 'direct'
                                ? 'Échange direct'
                                : 'Livraison',
                            colorScheme,
                            theme,
                          ),
                          SizedBox(height: 8.5),
                          _buildInfoRow(
                            'Date de fin',
                            _formatDate(exchange['completion_date']),
                            colorScheme,
                            theme,
                          ),
                          SizedBox(height: 8.5),
                          _buildInfoRow(
                            'Suppression automatique',
                            _formatAutoDeleteDate(exchange['auto_delete_at']),
                            colorScheme,
                            theme,
                          ),
                        ],
                      ),
                      colorScheme,
                      theme,
                    ),
                    SizedBox(height: 34.0),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _showDeleteConfirmation(exchange);
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppTheme.errorRed),
                              padding: EdgeInsets.symmetric(vertical: 12.0),
                            ),
                            icon: CustomIconWidget(
                              iconName: 'delete',
                              color: AppTheme.errorRed,
                              size: 20.0,
                            ),
                            label: Text(
                              'Supprimer',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppTheme.errorRed,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.0),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              // Export single exchange
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              padding: EdgeInsets.symmetric(vertical: 12.0),
                            ),
                            icon: CustomIconWidget(
                              iconName: 'file_download',
                              color: colorScheme.onPrimary,
                              size: 20.0,
                            ),
                            label: Text(
                              'Exporter',
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
      ),
    );
  }

  Widget _buildDetailSection(
    String title,
    Widget content,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 17.0),
          content,
        ],
      ),
    );
  }

  Widget _buildProductInfo(
    String label,
    String product,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24.0),
          SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  product,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingInfo(
    String label,
    int rating,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Container(
      padding: EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 8.5),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return CustomIconWidget(
                iconName: index < rating ? 'star' : 'star_border',
                color: index < rating
                    ? AppTheme.warningOrange
                    : colorScheme.outline,
                size: 16.0,
              );
            }),
          ),
          SizedBox(height: 4.3),
          Text(
            '$rating/5',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Aujourd\'hui';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'Il y a $weeks semaine${weeks > 1 ? 's' : ''}';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return 'Il y a $months mois';
    } else {
      final years = (difference.inDays / 365).floor();
      return 'Il y a $years an${years > 1 ? 's' : ''}';
    }
  }

  String _formatAutoDeleteDate(String dateString) {
    final deleteDate = DateTime.parse(dateString);
    final now = DateTime.now();
    final difference = deleteDate.difference(now);

    if (difference.isNegative) {
      return 'Supprimé automatiquement';
    } else if (difference.inDays < 30) {
      return 'Dans ${difference.inDays} jours';
    } else {
      final months = (difference.inDays / 30).floor();
      return 'Dans $months mois';
    }
  }
}
