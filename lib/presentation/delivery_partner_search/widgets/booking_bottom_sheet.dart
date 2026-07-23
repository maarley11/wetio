import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../theme/app_theme.dart';

class BookingBottomSheet extends StatefulWidget {
  final Map<String, dynamic> partner;

  const BookingBottomSheet({super.key, required this.partner});

  @override
  State<BookingBottomSheet> createState() => _BookingBottomSheetState();
}

class _BookingBottomSheetState extends State<BookingBottomSheet> {
  final _pickupController = TextEditingController();
  final _deliveryController = TextEditingController();
  final _instructionsController = TextEditingController();
  String _selectedTimeSlot = 'now';
  String _selectedPaymentMethod = 'cash';
  bool _isLoading = false;
  bool _requestSent = false;
  String? _deliveryRequestId;
  String _requestStatus = 'pending';

  final List<Map<String, String>> _timeSlots = [
    {'id': 'now', 'label': 'Maintenant', 'time': 'Livraison immédiate'},
    {'id': '30min', 'label': 'Dans 30 min', 'time': '30-45 minutes'},
    {'id': '1hour', 'label': 'Dans 1 heure', 'time': '1-1.5 heures'},
    {'id': '2hours', 'label': 'Dans 2 heures', 'time': '2-2.5 heures'},
  ];

  final List<Map<String, dynamic>> _paymentMethods = [
    {'id': 'cash', 'name': 'Espèces', 'icon': Icons.money},
    {'id': 'mobile', 'name': 'Mobile Money', 'icon': Icons.phone_android},
    {'id': 'card', 'name': 'Carte bancaire', 'icon': Icons.credit_card},
  ];

  @override
  void dispose() {
    _pickupController.dispose();
    _deliveryController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _sendDeliveryRequest() async {
    if (_pickupController.text.isEmpty || _deliveryController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Veuillez remplir les adresses de collecte et livraison',
          ),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        // No auth required - show error and return
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossible de traiter la demande pour le moment.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      final estimatedCost = (widget.partner['basePrice'] as int? ?? 2000);

      final response = await supabase
          .from('delivery_requests')
          .insert({
            'requester_id': userId,
            'delivery_person_id': widget.partner['dbId'],
            'pickup_address': _pickupController.text.trim(),
            'delivery_address': _deliveryController.text.trim(),
            'delivery_notes': _instructionsController.text.trim(),
            'estimated_cost_fcfa': estimatedCost,
            'delivery_status': 'pending',
          })
          .select()
          .single();

      if (mounted) {
        setState(() {
          _requestSent = true;
          _deliveryRequestId = response['id'];
          _requestStatus = 'pending';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: Image.network(
                    widget.partner['profileImage'] ?? '',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppTheme.borderLight,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: const Icon(
                          Icons.person,
                          color: AppTheme.textSecondary,
                          size: 30,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.partner['name'] ?? '',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: AppTheme.warningOrange,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.partner['rating']} • ${widget.partner['vehicleModel']}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Content
          Expanded(
            child: _requestSent
                ? _buildRequestSentView()
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Adresses de livraison'),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _pickupController,
                          decoration: const InputDecoration(
                            labelText: 'Adresse de collecte',
                            hintText: 'D\'où voulez-vous récupérer?',
                            prefixIcon: Icon(
                              Icons.my_location,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _deliveryController,
                          decoration: const InputDecoration(
                            labelText: 'Adresse de livraison',
                            hintText: 'Où livrer?',
                            prefixIcon: Icon(
                              Icons.location_on,
                              color: AppTheme.errorRed,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildSectionTitle('Créneaux horaires'),
                        const SizedBox(height: 12),
                        ...List.generate(_timeSlots.length, (index) {
                          final slot = _timeSlots[index];
                          final isSelected = _selectedTimeSlot == slot['id'];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: InkWell(
                              onTap: () => setState(
                                () => _selectedTimeSlot = slot['id']!,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: isSelected
                                        ? AppTheme.primaryGreen
                                        : AppTheme.borderLight,
                                    width: isSelected ? 2 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  color: isSelected
                                      ? AppTheme.primaryGreen.withValues(
                                          alpha: 0.1,
                                        )
                                      : AppTheme.surfaceWhite,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            slot['label']!,
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: isSelected
                                                  ? AppTheme.primaryGreen
                                                  : AppTheme.textPrimary,
                                            ),
                                          ),
                                          Text(
                                            slot['time']!,
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(
                                        Icons.check_circle,
                                        color: AppTheme.primaryGreen,
                                        size: 20,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 24),
                        _buildSectionTitle('Instructions spéciales'),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _instructionsController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText:
                                'Instructions particulières pour le livreur...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildSectionTitle('Mode de paiement'),
                        const SizedBox(height: 12),
                        ...List.generate(_paymentMethods.length, (index) {
                          final method = _paymentMethods[index];
                          final isSelected =
                              _selectedPaymentMethod == method['id'];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: InkWell(
                              onTap: () => setState(
                                () => _selectedPaymentMethod =
                                    method['id'] as String,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: isSelected
                                        ? AppTheme.primaryGreen
                                        : AppTheme.borderLight,
                                    width: isSelected ? 2 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  color: isSelected
                                      ? AppTheme.primaryGreen.withValues(
                                          alpha: 0.1,
                                        )
                                      : AppTheme.surfaceWhite,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      method['icon'] as IconData,
                                      color: isSelected
                                          ? AppTheme.primaryGreen
                                          : AppTheme.textSecondary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      method['name'] as String,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: isSelected
                                            ? AppTheme.primaryGreen
                                            : AppTheme.textPrimary,
                                      ),
                                    ),
                                    const Spacer(),
                                    if (isSelected)
                                      const Icon(
                                        Icons.check_circle,
                                        color: AppTheme.primaryGreen,
                                        size: 20,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 32),
                        // Price summary
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundWhite,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.borderLight),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Prix estimé',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              Text(
                                '${widget.partner['basePrice']} FCFA',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Demander livraison button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _sendDeliveryRequest,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'Demander livraison',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestSentView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.send,
              color: AppTheme.primaryGreen,
              size: 48,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Demande envoyée !',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Votre demande a été envoyée à ${widget.partner['name']}.\nVous recevrez une notification dès qu\'il accepte ou refuse.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.backgroundWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Column(
              children: [
                _buildInfoRow(
                  Icons.location_on,
                  'Collecte',
                  _pickupController.text,
                ),
                const Divider(height: 16),
                _buildInfoRow(
                  Icons.flag,
                  'Livraison',
                  _deliveryController.text,
                ),
                const Divider(height: 16),
                _buildInfoRow(
                  Icons.attach_money,
                  'Prix estimé',
                  '${widget.partner['basePrice']} FCFA',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Fermer',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryGreen, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
    );
  }
}
