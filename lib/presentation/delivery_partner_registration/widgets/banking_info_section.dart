import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class BankingInfoSection extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final Function(Map<String, dynamic>) onDataChanged;

  const BankingInfoSection({
    super.key,
    required this.formKey,
    required this.onDataChanged,
  });

  @override
  State<BankingInfoSection> createState() => _BankingInfoSectionState();
}

class _BankingInfoSectionState extends State<BankingInfoSection> {
  final _accountHolderController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _mobileMoneyController = TextEditingController();
  String _selectedPaymentMethod = 'bank';
  String _selectedMobileOperator = '';

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 'bank',
      'name': 'Compte bancaire',
      'icon': Icons.account_balance,
      'description': 'Virement bancaire traditionnel',
    },
    {
      'id': 'mobile_money',
      'name': 'Mobile Money',
      'icon': Icons.phone_android,
      'description': 'Orange Money, MTN Money, Moov Money',
    },
  ];

  final List<Map<String, String>> _mobileOperators = [
    {'id': 'orange', 'name': 'Orange Money'},
    {'id': 'mtn', 'name': 'MTN Money'},
    {'id': 'moov', 'name': 'Moov Money'},
  ];

  @override
  void initState() {
    super.initState();
    _accountHolderController.addListener(_updateData);
    _bankNameController.addListener(_updateData);
    _accountNumberController.addListener(_updateData);
    _mobileMoneyController.addListener(_updateData);
  }

  void _updateData() {
    widget.onDataChanged({
      'paymentMethod': _selectedPaymentMethod,
      'accountHolder': _accountHolderController.text,
      'bankName': _bankNameController.text,
      'accountNumber': _accountNumberController.text,
      'mobileOperator': _selectedMobileOperator,
      'mobileNumber': _mobileMoneyController.text,
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: widget.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Information section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.payments,
                        color: AppTheme.primaryGreen,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Informations de paiement',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Configurez votre mode de paiement pour recevoir vos gains. Les paiements sont effectués chaque semaine.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Payment method selection
            Text(
              'Mode de paiement *',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            ...List.generate(_paymentMethods.length, (index) {
              final method = _paymentMethods[index];
              final isSelected = _selectedPaymentMethod == method['id'];

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedPaymentMethod = method['id'];
                    });
                    _updateData();
                  },
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
                          ? AppTheme.primaryGreen.withValues(alpha: 0.1)
                          : AppTheme.surfaceWhite,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          method['icon'],
                          color: isSelected
                              ? AppTheme.primaryGreen
                              : AppTheme.textSecondary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                method['name'],
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected
                                      ? AppTheme.primaryGreen
                                      : AppTheme.textPrimary,
                                ),
                              ),
                              Text(
                                method['description'],
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

            // Bank account details
            if (_selectedPaymentMethod == 'bank') ...[
              Text(
                'Détails du compte bancaire',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _accountHolderController,
                decoration: const InputDecoration(
                  labelText: 'Nom du titulaire du compte *',
                  hintText: 'Nom tel qu\'il apparaît sur le compte',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le nom du titulaire est requis';
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bankNameController,
                decoration: const InputDecoration(
                  labelText: 'Nom de la banque *',
                  hintText: 'Ex: Société Générale, BICICI, UBA',
                  prefixIcon: Icon(Icons.account_balance),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le nom de la banque est requis';
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _accountNumberController,
                decoration: const InputDecoration(
                  labelText: 'Numéro de compte *',
                  hintText: 'Numéro de compte bancaire',
                  prefixIcon: Icon(Icons.credit_card),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le numéro de compte est requis';
                  }
                  if (value.length < 10) {
                    return 'Numéro de compte invalide';
                  }
                  return null;
                },
                textInputAction: TextInputAction.done,
              ),
            ],

            // Mobile money details
            if (_selectedPaymentMethod == 'mobile_money') ...[
              Text(
                'Détails Mobile Money',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedMobileOperator.isEmpty
                    ? null
                    : _selectedMobileOperator,
                decoration: const InputDecoration(
                  labelText: 'Opérateur mobile *',
                  prefixIcon: Icon(Icons.phone_android),
                ),
                items: _mobileOperators.map((operator) {
                  return DropdownMenuItem<String>(
                    value: operator['id'],
                    child: Text(operator['name']!),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedMobileOperator = value ?? '';
                  });
                  _updateData();
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez sélectionner un opérateur';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _mobileMoneyController,
                decoration: const InputDecoration(
                  labelText: 'Numéro Mobile Money *',
                  hintText: '+225 XX XX XX XX XX',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le numéro Mobile Money est requis';
                  }
                  if (value.length < 8) {
                    return 'Numéro de téléphone invalide';
                  }
                  return null;
                },
                textInputAction: TextInputAction.done,
              ),
            ],

            const SizedBox(height: 24),

            // Commission structure
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceWhite,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.monetization_on,
                        color: AppTheme.primaryOrange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Structure des commissions',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildCommissionInfo(
                      'Livraison de base', '1,500 - 3,000 FCFA'),
                  _buildCommissionInfo(
                      'Livraison express', '2,000 - 4,000 FCFA'),
                  _buildCommissionInfo(
                      'Livraison longue distance', '3,000 - 8,000 FCFA'),
                  const SizedBox(height: 8),
                  Text(
                    '* Les tarifs dépendent de la distance et du type de livraison',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommissionInfo(String type, String amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            type,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          Text(
            amount,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _accountHolderController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _mobileMoneyController.dispose();
    super.dispose();
  }
}
