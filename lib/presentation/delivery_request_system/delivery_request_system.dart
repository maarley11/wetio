import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../widgets/custom_app_bar.dart';
import '../../routes/app_routes.dart';
import '../../services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './widgets/delivery_confirmation_widget.dart';
import './widgets/delivery_partner_card_widget.dart';

class DeliveryRequestSystem extends StatefulWidget {
  const DeliveryRequestSystem({super.key});

  @override
  State<DeliveryRequestSystem> createState() => _DeliveryRequestSystemState();
}

class _DeliveryRequestSystemState extends State<DeliveryRequestSystem> {
  String? _selectedPartnerId;
  bool _isLoading = true;
  bool _requestSent = false;
  bool _partnerConfirmed = false;
  Map<String, dynamic>? _confirmedPartner;
  int _selectedSortIndex = 0;
  String? _exchangeId;
  RealtimeChannel? _deliverySubscription;
  
  List<Map<String, dynamic>> _deliveryPartners = [];

  final List<String> _sortOptions = [
    'Plus proches',
    'Mieux notés',
    'Moins chers',
  ];

  @override
  void initState() {
    super.initState();
    _loadPartners();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && _exchangeId == null) {
      _exchangeId = args['exchangeId']?.toString();
    }
  }

  @override
  void dispose() {
    _deliverySubscription?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadPartners() async {
    setState(() => _isLoading = true);
    try {
      final partners = await SupabaseService.getDeliveryPartners();
      setState(() {
        _deliveryPartners = partners.map((p) => {
          'id': p['id'],
          'name': p['full_name'] ?? 'Livreur',
          'rating': 4.5, // Default for now
          'reviewCount': 12,
          'vehicleType': 'motorcycle',
          'distance': 1.5,
          'estimatedTime': '10-15 min',
          'basePrice': 2000,
          'isAvailable': true,
          'profileImage': p['avatar_url'],
          'phone': p['phone'] ?? '+221 00 000 00 00',
          'currentLocation': 'Dakar',
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading partners: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _sortedPartners {
    final available =
        _deliveryPartners.where((p) => p['isAvailable'] == true).toList();
    switch (_selectedSortIndex) {
      case 0: // Plus proches
        available.sort(
          (a, b) => (a['distance'] as num).compareTo(b['distance'] as num),
        );
        break;
      case 1: // Mieux notés
        available.sort(
          (a, b) => (b['rating'] as num).compareTo(a['rating'] as num),
        );
        break;
      case 2: // Moins chers
        available.sort(
          (a, b) => (a['basePrice'] as num).compareTo(b['basePrice'] as num),
        );
        break;
    }
    return available;
  }

  void _sendDeliveryRequest(Map<String, dynamic> partner) async {
    if (_exchangeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ID d'échange manquant. Veuillez réessayer.")),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    try {
      final requestId = await SupabaseService.createDeliveryRequest(
        partnerUserId: partner['id'],
        exchangeId: _exchangeId!,
        personA: {
          'address': 'Point A (Départ)',
          'lat': 14.6937,
          'lng': -17.4441,
        },
        personB: {
          'address': 'Point B (Arrivée)',
          'lat': 14.7167,
          'lng': -17.4677,
        },
      );

      if (requestId != null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _requestSent = true;
          });
          _setupRealtimeStatusListener(requestId, partner);
          _showRequestSentDialog(partner);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Erreur détaillée"),
            content: SingleChildScrollView(
              child: Text("ExchangeId: $_exchangeId\n\nErreur: $e"),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    }
  }

  void _setupRealtimeStatusListener(String requestId, Map<String, dynamic> partner) {
    final supabase = SupabaseService.safeClient;
    if (supabase == null) return;

    _deliverySubscription = supabase
        .channel('public:delivery_requests:id=eq.$requestId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'delivery_requests',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: requestId,
          ),
          callback: (payload) {
            final updated = payload.newRecord;
            if (updated['delivery_status'] == 'accepted' || updated['delivery_status'] == 'accepte') {
              if (mounted) {
                Navigator.of(context).pop(); // Close the dialog if open
                _onPartnerAccepted(partner);
              }
            } else if (updated['delivery_status'] == 'refused' || updated['delivery_status'] == 'refuse') {
              if (mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Le livreur a refusé la demande. Veuillez en choisir un autre.")),
                );
                setState(() {
                  _requestSent = false;
                });
              }
            }
          },
        )
        .subscribe();
  }

  void _onPartnerAccepted(Map<String, dynamic> partner) {
    HapticFeedback.heavyImpact();
    setState(() {
      _partnerConfirmed = true;
      _confirmedPartner = partner;
    });
    
    // Navigate to coordination screen
    Navigator.pushNamed(
      context,
      AppRoutes.exchangeDeliveryCoordination,
      arguments: {
        'isInitiator': true,
        'deliveryPersonName': partner['name'],
        'deliveryPersonPhone': partner['phone'],
        'deliveryPersonImage': partner['profileImage'],
        'exchangeId': _exchangeId,
        'personA': {
          'name': 'Moi',
          'address': 'Dakar Plateau',
          'lat': 14.6937,
          'lng': -17.4441,
        },
        'personB': {
          'name': 'Partenaire',
          'address': 'Dakar Médina',
          'lat': 14.6928,
          'lng': -17.4467,
        },
      },
    );
  }

  void _showRequestSentDialog(Map<String, dynamic> partner) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Theme.of(
                  ctx,
                ).colorScheme.primaryContainer.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.send,
                color: Theme.of(ctx).colorScheme.primary,
                size: 32.0,
              ),
            ),
            SizedBox(height: 17.0),
            Text(
              'Demande envoyée !',
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.5),
            Text(
              '${partner['name']} a reçu votre demande de livraison.\n\nIl/Elle va accepter ou refuser dans les prochaines minutes.',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: Theme.of(ctx).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 17.0),
            SizedBox(height: 17.0),
            const CircularProgressIndicator(),
            SizedBox(height: 17.0),
            Text(
              'En attente d\'acceptation...',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(ctx).colorScheme.primary,
              ),
            ),
            SizedBox(height: 17.0),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Fermer',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _simulatePartnerAcceptance(Map<String, dynamic> partner) {
    // This method is kept but will no longer be called in the final flow
    _onPartnerAccepted(partner);
  }

  void _showConfirmationSheet(Map<String, dynamic> partner) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DeliveryConfirmationWidget(
        partner: partner,
        onRateDelivery: () {
          Navigator.of(ctx).pop();
          _showRatingDialog(partner);
        },
        onClose: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  void _showRatingDialog(Map<String, dynamic> partner) {
    int selectedRating = 0;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Noter le livreur',
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 28.0,
                backgroundImage: partner['profileImage'] != null
                    ? NetworkImage(partner['profileImage'])
                    : null,
                backgroundColor: Theme.of(ctx).colorScheme.primaryContainer,
              ),
              SizedBox(height: 8.5),
              Text(
                partner['name'] ?? '',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 17.0),
              Text(
                'Comment s\'est passée la livraison ?',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12.8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setDialogState(() => selectedRating = i + 1);
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.0),
                      child: Icon(
                        i < selectedRating ? Icons.star : Icons.star_outline,
                        color: const Color(0xFFF59E0B),
                        size: 32.0,
                      ),
                    ),
                  );
                }),
              ),
              SizedBox(height: 4.3),
              Text(
                selectedRating == 0
                    ? 'Appuyez sur une étoile'
                    : [
                        '',
                        'Très mauvais',
                        'Mauvais',
                        'Correct',
                        'Bien',
                        'Excellent !',
                      ][selectedRating],
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: selectedRating > 0
                      ? const Color(0xFFF59E0B)
                      : Theme.of(ctx).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Annuler',
                style: GoogleFonts.dmSans(
                  color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: selectedRating > 0
                  ? () {
                      Navigator.of(ctx).pop();
                      HapticFeedback.mediumImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Merci ! Vous avez donné $selectedRating étoile${selectedRating > 1 ? 's' : ''} à ${partner['name']}',
                          ),
                          backgroundColor: const Color(0xFF16A34A),
                        ),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Envoyer',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: CustomAppBar(
        title: 'Trouver un Livreur',
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: colorScheme.primary),
                  SizedBox(height: 17.0),
                  Text(
                    'Envoi de la demande...',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Route summary card
                  _buildRouteSummaryCard(colorScheme),

                  // Sort filter chips
                  _buildSortFilters(colorScheme),

                  // Partners list header
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.5,
                    ),
                    child: Row(
                      children: [
                        Text(
                          '${_sortedPartners.length} livreurs disponibles',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 3.4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF22C55E,
                            ).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8.0,
                                height: 8.0,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF16A34A),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 4.0),
                              Text(
                                'Filtre auto actif',
                                style: GoogleFonts.dmSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF16A34A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Partner cards
                  ..._sortedPartners.map((partner) {
                    return DeliveryPartnerCardWidget(
                      partner: partner,
                      isSelected: _selectedPartnerId == partner['id'],
                      onSelect: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          _selectedPartnerId =
                              _selectedPartnerId == partner['id']
                                  ? null
                                  : partner['id'];
                        });
                      },
                      onRequestDelivery: () => _sendDeliveryRequest(partner),
                    );
                  }),

                  SizedBox(height: 25.5),
                ],
              ),
            ),
    );
  }

  Widget _buildRouteSummaryCard(ColorScheme colorScheme) {
    return Container(
      margin: EdgeInsets.all(16.0),
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.08),
            colorScheme.primaryContainer.withValues(alpha: 0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.route, color: colorScheme.primary, size: 20.0),
              SizedBox(width: 8.0),
              Text(
                'Détails de la livraison',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: 17.0),
          _buildAddressRow(
            colorScheme,
            Icons.circle,
            const Color(0xFF22C55E),
            'Point A (Départ)',
            'Votre adresse actuelle',
          ),
          Padding(
            padding: EdgeInsets.only(left: 16.0),
            child: Column(
              children: List.generate(
                3,
                (i) => Container(
                  width: 1.5,
                  height: 6,
                  margin: const EdgeInsets.symmetric(vertical: 1),
                  color: colorScheme.outline.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
          _buildAddressRow(
            colorScheme,
            Icons.location_on,
            colorScheme.primary,
            'Point B (Destination)',
            'Adresse de livraison',
          ),
          SizedBox(height: 12.8),
          Row(
            children: [
              _buildMetricChip(
                colorScheme,
                Icons.straighten,
                '~5 km',
                'Distance',
              ),
              SizedBox(width: 8.0),
              _buildMetricChip(
                colorScheme,
                Icons.timer_outlined,
                '15-25 min',
                'Durée',
              ),
              SizedBox(width: 8.0),
              _buildMetricChip(
                colorScheme,
                Icons.payments_outlined,
                '1500-3500 F',
                'Estimation',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddressRow(
    ColorScheme colorScheme,
    IconData icon,
    Color iconColor,
    String label,
    String address,
  ) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 16.0),
        SizedBox(width: 8.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                address,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricChip(
    ColorScheme colorScheme,
    IconData icon,
    String value,
    String label,
  ) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.5),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 14.0, color: colorScheme.primary),
            SizedBox(height: 2.5),
            Text(
              value,
              style: GoogleFonts.dmSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 9,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortFilters(ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trier par',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 8.5),
          Row(
            children: _sortOptions.asMap().entries.map((entry) {
              final i = entry.key;
              final label = entry.value;
              final isSelected = _selectedSortIndex == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _selectedSortIndex = i);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(right: i < 2 ? 8.0 : 0),
                    padding: EdgeInsets.symmetric(vertical: 8.5),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.surfaceContainerHighest.withValues(
                              alpha: 0.5,
                            ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      label,
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
