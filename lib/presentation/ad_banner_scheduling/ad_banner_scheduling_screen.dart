import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/ad_banner_service.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_routes.dart';

class AdBannerSchedulingScreen extends StatefulWidget {
  const AdBannerSchedulingScreen({super.key});

  @override
  State<AdBannerSchedulingScreen> createState() =>
      _AdBannerSchedulingScreenState();
}

class _AdBannerSchedulingScreenState extends State<AdBannerSchedulingScreen> {
  static const String _adminEmail = 'admin@wetio.sn';

  bool get _isAdmin {
    final user = Supabase.instance.client.auth.currentUser;
    return user != null && (user.email ?? '') == _adminEmail;
  }

  final AdBannerService _service = AdBannerService();
  List<AdBanner> _banners = [];

  @override
  void initState() {
    super.initState();
    _loadBanners();
  }

  void _loadBanners() {
    setState(() {
      _banners = List.from(_service.allBanners);
    });
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
          'Bannières Publicitaires',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(
                context, AppRoutes.adBannerAnalyticsDashboard),
            icon: Icon(Icons.bar_chart_rounded,
                color: AppTheme.primaryGreen, size: 18),
            label: Text(
              'Analytics',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryGreen,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSummaryBar(colorScheme),
          Expanded(
            child: _banners.isEmpty
                ? _buildEmptyState(colorScheme)
                : ListView.builder(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.5),
                    itemCount: _banners.length,
                    itemBuilder: (context, index) =>
                        _buildBannerCard(_banners[index], colorScheme),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBannerFormDialog(context, null),
        backgroundColor: AppTheme.primaryGreen,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Nouvelle bannière',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryBar(ColorScheme colorScheme) {
    final active = _banners.where((b) => b.isCurrentlyActive).length;
    final scheduled = _banners
        .where((b) => b.isActive && DateTime.now().isBefore(b.startDate))
        .length;
    final expired =
        _banners.where((b) => DateTime.now().isAfter(b.endDate)).length;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.5),
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.8),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat('Actives', active.toString(), Colors.green, colorScheme),
          _buildDivider(colorScheme),
          _buildStat(
              'Planifiées', scheduled.toString(), Colors.blue, colorScheme),
          _buildDivider(colorScheme),
          _buildStat('Expirées', expired.toString(), Colors.grey, colorScheme),
          _buildDivider(colorScheme),
          _buildStat('Total', _banners.length.toString(), AppTheme.primaryGreen,
              colorScheme),
        ],
      ),
    );
  }

  Widget _buildStat(
      String label, String value, Color color, ColorScheme colorScheme) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(ColorScheme colorScheme) {
    return Container(
      width: 1,
      height: 34.0,
      color: colorScheme.outline.withValues(alpha: 0.3),
    );
  }

  Widget _buildBannerCard(AdBanner banner, ColorScheme colorScheme) {
    final statusInfo = _getBannerStatus(banner);
    return Container(
      margin: EdgeInsets.only(bottom: 12.8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Banner preview
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(12.0)),
            child: Stack(
              children: [
                Image.network(
                  banner.imageUrl,
                  width: double.infinity,
                  height: 102.0,
                  fit: BoxFit.cover,
                  semanticLabel: 'Aperçu bannière ${banner.title}',
                  errorBuilder: (_, __, ___) => Container(
                    height: 102.0,
                    color: colorScheme.surfaceContainerHighest,
                    child: Icon(Icons.image_not_supported_outlined,
                        color: colorScheme.onSurfaceVariant),
                  ),
                ),
                Positioned(
                  top: 8.5,
                  left: 12.0,
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.4),
                    decoration: BoxDecoration(
                      color: statusInfo['color'] as Color,
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusInfo['icon'] as IconData,
                            color: Colors.white, size: 10),
                        SizedBox(width: 4.0),
                        Text(
                          statusInfo['label'] as String,
                          style: GoogleFonts.inter(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Info
          Padding(
            padding: EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        banner.title,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert_rounded,
                          color: colorScheme.onSurfaceVariant, size: 20),
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showBannerFormDialog(context, banner);
                        } else if (value == 'delete') {
                          _confirmDelete(banner);
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined,
                                  size: 16, color: colorScheme.onSurface),
                              SizedBox(width: 8.0),
                              Text('Modifier',
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: colorScheme.onSurface)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(Icons.delete_outline_rounded,
                                  size: 16, color: Colors.red),
                              SizedBox(width: 8.0),
                              Text('Supprimer',
                                  style: GoogleFonts.inter(
                                      fontSize: 12, color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 4.3),
                Text(
                  banner.advertiser,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 8.5),
                // Schedule info
                Row(
                  children: [
                    Icon(Icons.schedule_rounded,
                        size: 14, color: AppTheme.primaryGreen),
                    SizedBox(width: 4.0),
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
                  ],
                ),
                SizedBox(height: 4.3),
                Row(
                  children: [
                    Icon(Icons.refresh_rounded, size: 14, color: Colors.blue),
                    SizedBox(width: 4.0),
                    Text(
                      'Rotation: ${_formatFrequency(banner.rotationFrequencySeconds)}',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    // Mini analytics
                    Icon(Icons.visibility_outlined,
                        size: 12, color: colorScheme.onSurfaceVariant),
                    SizedBox(width: 4.0),
                    Text(
                      '${_formatNumber(banner.impressions)}',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(width: 8.0),
                    Icon(Icons.touch_app_outlined,
                        size: 12, color: colorScheme.onSurfaceVariant),
                    SizedBox(width: 4.0),
                    Text(
                      '${banner.ctr.toStringAsFixed(1)}%',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getBannerStatus(AdBanner banner) {
    final now = DateTime.now();
    if (now.isAfter(banner.endDate)) {
      return {
        'label': 'Expiré',
        'color': Colors.grey,
        'icon': Icons.timer_off_rounded
      };
    }
    if (!banner.isActive) {
      return {
        'label': 'Inactif',
        'color': Colors.orange,
        'icon': Icons.pause_circle_outline_rounded
      };
    }
    if (now.isBefore(banner.startDate)) {
      return {
        'label': 'Planifié',
        'color': Colors.blue,
        'icon': Icons.schedule_rounded
      };
    }
    return {
      'label': 'Actif',
      'color': Colors.green,
      'icon': Icons.play_circle_outline_rounded
    };
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatFrequency(int seconds) {
    if (seconds < 60) return '${seconds}s';
    return '${(seconds / 60).round()}min';
  }

  String _formatNumber(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.campaign_outlined,
              size: 60, color: colorScheme.onSurfaceVariant),
          SizedBox(height: 17.0),
          Text(
            'Aucune bannière',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 8.5),
          Text(
            'Créez votre première bannière publicitaire',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(AdBanner banner) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Supprimer la bannière',
            style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface)),
        content: Text(
          'Voulez-vous vraiment supprimer "${banner.title}" ?',
          style: GoogleFonts.inter(
              fontSize: 12, color: colorScheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler',
                style: GoogleFonts.inter(
                    fontSize: 13, color: colorScheme.onSurfaceVariant)),
          ),
          ElevatedButton(
            onPressed: () {
              _service.deleteBanner(banner.id);
              Navigator.pop(context);
              _loadBanners();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bannière supprimée')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Supprimer',
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showBannerFormDialog(BuildContext context, AdBanner? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BannerFormSheet(
        existing: existing,
        service: _service,
        onSaved: _loadBanners,
      ),
    );
  }
}

// ─── Banner Form Sheet ────────────────────────────────────────────────────────

class _BannerFormSheet extends StatefulWidget {
  final AdBanner? existing;
  final AdBannerService service;
  final VoidCallback onSaved;

  const _BannerFormSheet({
    required this.existing,
    required this.service,
    required this.onSaved,
  });

  @override
  State<_BannerFormSheet> createState() => _BannerFormSheetState();
}

class _BannerFormSheetState extends State<_BannerFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _advertiserCtrl;
  late TextEditingController _imageUrlCtrl;
  late TextEditingController _ctaCtrl;
  late TextEditingController _targetUrlCtrl;

  late DateTime _startDate;
  late DateTime _endDate;
  late int _rotationSeconds;
  late bool _isActive;
  late String _category;

  final List<String> _categories = [
    'Immobilier',
    'Mode',
    'Technologie',
    'Livraison',
    'Alimentation',
    'Services',
    'Autre',
  ];

  final List<Map<String, dynamic>> _frequencyOptions = [
    {'label': '5 secondes', 'value': 5},
    {'label': '8 secondes', 'value': 8},
    {'label': '10 secondes', 'value': 10},
    {'label': '15 secondes', 'value': 15},
    {'label': '20 secondes', 'value': 20},
    {'label': '30 secondes', 'value': 30},
    {'label': '1 minute', 'value': 60},
    {'label': '2 minutes', 'value': 120},
  ];

  @override
  void initState() {
    super.initState();
    final b = widget.existing;
    _titleCtrl = TextEditingController(text: b?.title ?? '');
    _advertiserCtrl = TextEditingController(text: b?.advertiser ?? '');
    _imageUrlCtrl = TextEditingController(text: b?.imageUrl ?? '');
    _ctaCtrl = TextEditingController(text: b?.ctaText ?? 'Découvrir');
    _targetUrlCtrl = TextEditingController(text: b?.targetUrl ?? '');
    _startDate = b?.startDate ?? DateTime.now();
    _endDate = b?.endDate ?? DateTime.now().add(const Duration(days: 30));
    _rotationSeconds = b?.rotationFrequencySeconds ?? 10;
    _isActive = b?.isActive ?? true;
    _category = b?.category ?? 'Autre';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _advertiserCtrl.dispose();
    _imageUrlCtrl.dispose();
    _ctaCtrl.dispose();
    _targetUrlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEdit = widget.existing != null;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.95,
      minChildSize: 0.6,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20.0)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: EdgeInsets.only(top: 8.5),
              width: 40.0,
              height: 4.3,
              decoration: BoxDecoration(
                color: colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4.0),
              ),
            ),
            // Title
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      isEdit ? 'Modifier la bannière' : 'Nouvelle bannière',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded,
                        color: colorScheme.onSurfaceVariant),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(
                height: 1, color: colorScheme.outline.withValues(alpha: 0.2)),
            // Form
            Expanded(
              child: SingleChildScrollView(
                controller: scrollCtrl,
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 17.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Informations', colorScheme),
                      SizedBox(height: 8.5),
                      _buildTextField(_titleCtrl, 'Titre de la bannière',
                          Icons.title_rounded, colorScheme,
                          required: true),
                      SizedBox(height: 12.8),
                      _buildTextField(_advertiserCtrl, 'Annonceur',
                          Icons.business_rounded, colorScheme,
                          required: true),
                      SizedBox(height: 12.8),
                      _buildTextField(_imageUrlCtrl, 'URL de l\'image',
                          Icons.image_rounded, colorScheme,
                          required: true),
                      SizedBox(height: 12.8),
                      _buildTextField(_ctaCtrl, 'Texte du bouton (CTA)',
                          Icons.touch_app_rounded, colorScheme),
                      SizedBox(height: 12.8),
                      _buildTextField(_targetUrlCtrl, 'URL de destination',
                          Icons.link_rounded, colorScheme),
                      SizedBox(height: 12.8),
                      // Category
                      _buildDropdown(colorScheme),
                      SizedBox(height: 17.0),
                      _buildSectionTitle('Planification', colorScheme),
                      SizedBox(height: 8.5),
                      _buildDateTimePicker(
                          'Date de début', _startDate, colorScheme,
                          onChanged: (dt) => setState(() => _startDate = dt)),
                      SizedBox(height: 12.8),
                      _buildDateTimePicker('Date de fin', _endDate, colorScheme,
                          onChanged: (dt) => setState(() => _endDate = dt)),
                      SizedBox(height: 17.0),
                      _buildSectionTitle('Fréquence de rotation', colorScheme),
                      SizedBox(height: 8.5),
                      _buildFrequencySelector(colorScheme),
                      SizedBox(height: 17.0),
                      // Active toggle
                      _buildActiveToggle(colorScheme),
                      SizedBox(height: 25.5),
                      // Save button
                      SizedBox(
                        width: double.infinity,
                        height: 51.0,
                        child: ElevatedButton(
                          onPressed: _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                          child: Text(
                            isEdit ? 'Enregistrer' : 'Créer la bannière',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 17.0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ColorScheme colorScheme) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppTheme.primaryGreen,
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label,
      IconData icon, ColorScheme colorScheme,
      {bool required = false}) {
    return TextFormField(
      controller: ctrl,
      style: GoogleFonts.inter(fontSize: 12, color: colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(
            fontSize: 11, color: colorScheme.onSurfaceVariant),
        prefixIcon: Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide:
              BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide:
              BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: AppTheme.primaryGreen, width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.8),
      ),
      validator: required
          ? (v) => (v == null || v.isEmpty) ? 'Champ requis' : null
          : null,
    );
  }

  Widget _buildDropdown(ColorScheme colorScheme) {
    return DropdownButtonFormField<String>(
      initialValue: _category,
      decoration: InputDecoration(
        labelText: 'Catégorie',
        labelStyle: GoogleFonts.inter(
            fontSize: 11, color: colorScheme.onSurfaceVariant),
        prefixIcon: Icon(Icons.category_rounded,
            size: 18, color: colorScheme.onSurfaceVariant),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide:
              BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide:
              BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: AppTheme.primaryGreen, width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.8),
      ),
      style: GoogleFonts.inter(fontSize: 12, color: colorScheme.onSurface),
      items: _categories
          .map((c) => DropdownMenuItem(
              value: c,
              child: Text(c,
                  style: GoogleFonts.inter(
                      fontSize: 12, color: colorScheme.onSurface))))
          .toList(),
      onChanged: (v) => setState(() => _category = v ?? 'Autre'),
    );
  }

  Widget _buildDateTimePicker(
      String label, DateTime current, ColorScheme colorScheme,
      {required ValueChanged<DateTime> onChanged}) {
    return GestureDetector(
      onTap: () => _pickDateTime(current, onChanged),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.8),
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded,
                size: 18, color: colorScheme.onSurfaceVariant),
            SizedBox(width: 8.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    _formatDateTime(current),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.edit_calendar_rounded,
                size: 18, color: AppTheme.primaryGreen),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencySelector(ColorScheme colorScheme) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.5,
      children: _frequencyOptions.map((opt) {
        final isSelected = _rotationSeconds == opt['value'];
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _rotationSeconds = opt['value'] as int);
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryGreen
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20.0),
              border: Border.all(
                color: isSelected
                    ? AppTheme.primaryGreen
                    : colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              opt['label'] as String,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : colorScheme.onSurface,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActiveToggle(ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Row(
        children: [
          Icon(Icons.toggle_on_rounded, size: 20, color: AppTheme.primaryGreen),
          SizedBox(width: 8.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bannière active',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  'La bannière sera affichée selon la planification',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
            activeThumbColor: AppTheme.primaryGreen,
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateTime(
      DateTime current, ValueChanged<DateTime> onChanged) async {
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx)
              .colorScheme
              .copyWith(primary: AppTheme.primaryGreen),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx)
              .colorScheme
              .copyWith(primary: AppTheme.primaryGreen),
        ),
        child: child!,
      ),
    );
    if (time == null || !mounted) return;

    onChanged(
        DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_endDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('La date de fin doit être après la date de début')),
      );
      return;
    }

    final banner = AdBanner(
      id: widget.existing?.id ?? widget.service.generateId(),
      title: _titleCtrl.text.trim(),
      imageUrl: _imageUrlCtrl.text.trim(),
      advertiser: _advertiserCtrl.text.trim(),
      ctaText: _ctaCtrl.text.trim(),
      targetUrl: _targetUrlCtrl.text.trim(),
      category: _category,
      startDate: _startDate,
      endDate: _endDate,
      rotationFrequencySeconds: _rotationSeconds,
      isActive: _isActive,
      impressions: widget.existing?.impressions ?? 0,
      clicks: widget.existing?.clicks ?? 0,
      conversions: widget.existing?.conversions ?? 0,
    );

    if (widget.existing != null) {
      widget.service.updateBanner(banner);
    } else {
      widget.service.addBanner(banner);
    }

    Navigator.pop(context);
    widget.onSaved();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.existing != null
            ? 'Bannière mise à jour ✓'
            : 'Bannière créée ✓'),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }
}
