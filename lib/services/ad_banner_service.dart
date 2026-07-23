import 'dart:math';

class AdBanner {
  final String id;
  final String title;
  final String imageUrl;
  final String advertiser;
  final String ctaText;
  final String targetUrl;
  final String category;
  final DateTime startDate;
  final DateTime endDate;
  final int rotationFrequencySeconds;
  final bool isActive;
  int impressions;
  int clicks;
  int conversions;

  AdBanner({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.advertiser,
    required this.ctaText,
    required this.targetUrl,
    required this.category,
    required this.startDate,
    required this.endDate,
    required this.rotationFrequencySeconds,
    required this.isActive,
    this.impressions = 0,
    this.clicks = 0,
    this.conversions = 0,
  });

  double get ctr => impressions > 0 ? (clicks / impressions) * 100 : 0.0;
  double get conversionRate => clicks > 0 ? (conversions / clicks) * 100 : 0.0;

  bool get isCurrentlyActive {
    final now = DateTime.now();
    return isActive && now.isAfter(startDate) && now.isBefore(endDate);
  }

  AdBanner copyWith({
    String? id,
    String? title,
    String? imageUrl,
    String? advertiser,
    String? ctaText,
    String? targetUrl,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    int? rotationFrequencySeconds,
    bool? isActive,
    int? impressions,
    int? clicks,
    int? conversions,
  }) {
    return AdBanner(
      id: id ?? this.id,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      advertiser: advertiser ?? this.advertiser,
      ctaText: ctaText ?? this.ctaText,
      targetUrl: targetUrl ?? this.targetUrl,
      category: category ?? this.category,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      rotationFrequencySeconds:
          rotationFrequencySeconds ?? this.rotationFrequencySeconds,
      isActive: isActive ?? this.isActive,
      impressions: impressions ?? this.impressions,
      clicks: clicks ?? this.clicks,
      conversions: conversions ?? this.conversions,
    );
  }
}

class AdBannerService {
  static final AdBannerService _instance = AdBannerService._internal();
  factory AdBannerService() => _instance;
  AdBannerService._internal();

  final List<AdBanner> _banners = [
    AdBanner(
      id: 'banner_001',
      title: 'Appartement Luxe — Almadies',
      imageUrl:
          'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=800&h=400&fit=crop',
      advertiser: 'Airbnb Sénégal',
      ctaText: 'Réserver',
      targetUrl: 'https://www.airbnb.fr',
      category: 'Immobilier',
      startDate: DateTime.now().subtract(const Duration(days: 5)),
      endDate: DateTime.now().add(const Duration(days: 25)),
      rotationFrequencySeconds: 10,
      isActive: true,
      impressions: 4820,
      clicks: 312,
      conversions: 47,
    ),
  ];

  List<AdBanner> get allBanners => List.unmodifiable(_banners);

  List<AdBanner> get activeBanners =>
      _banners.where((b) => b.isCurrentlyActive).toList();

  AdBanner? getNextBanner(String? currentBannerId) {
    final active = activeBanners;
    if (active.isEmpty) return null;
    if (currentBannerId == null) return active.first;
    final idx = active.indexWhere((b) => b.id == currentBannerId);
    if (idx == -1) return active.first;
    return active[(idx + 1) % active.length];
  }

  void recordImpression(String bannerId) {
    final idx = _banners.indexWhere((b) => b.id == bannerId);
    if (idx != -1) {
      _banners[idx] = _banners[idx].copyWith(
        impressions: _banners[idx].impressions + 1,
      );
    }
  }

  void recordClick(String bannerId) {
    final idx = _banners.indexWhere((b) => b.id == bannerId);
    if (idx != -1) {
      _banners[idx] = _banners[idx].copyWith(clicks: _banners[idx].clicks + 1);
    }
  }

  void addBanner(AdBanner banner) {
    _banners.add(banner);
  }

  void updateBanner(AdBanner updated) {
    final idx = _banners.indexWhere((b) => b.id == updated.id);
    if (idx != -1) _banners[idx] = updated;
  }

  void deleteBanner(String id) {
    _banners.removeWhere((b) => b.id == id);
  }

  String generateId() =>
      'banner_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999)}';

  // Analytics aggregates
  int get totalImpressions => _banners.fold(0, (sum, b) => sum + b.impressions);
  int get totalClicks => _banners.fold(0, (sum, b) => sum + b.clicks);
  int get totalConversions => _banners.fold(0, (sum, b) => sum + b.conversions);
  double get overallCtr =>
      totalImpressions > 0 ? (totalClicks / totalImpressions) * 100 : 0.0;

  List<Map<String, dynamic>> get weeklyImpressions {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      final dayName = [
        'Lun',
        'Mar',
        'Mer',
        'Jeu',
        'Ven',
        'Sam',
        'Dim',
      ][day.weekday - 1];
      return {
        'day': dayName,
        'impressions': 400 + Random().nextInt(600),
        'clicks': 20 + Random().nextInt(80),
      };
    });
  }
}
