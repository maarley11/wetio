import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';

class PayoutMethodsScreen extends StatefulWidget {
  const PayoutMethodsScreen({super.key});

  @override
  State<PayoutMethodsScreen> createState() => _PayoutMethodsScreenState();
}

class _PayoutMethodsScreenState extends State<PayoutMethodsScreen> {
  bool _isLoading = false;
  bool _isCheckingStatus = true;
  String _errorMessage = '';
  
  String _selectedMethod = 'Wave';
  final TextEditingController _phoneController = TextEditingController();
  
  final List<String> _methods = ['Wave', 'Orange Money', 'Free Money'];

  @override
  void initState() {
    super.initState();
    _loadCurrentMethod();
  }
  
  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentMethod() async {
    setState(() {
      _isCheckingStatus = true;
      _errorMessage = '';
    });
    try {
      final profile = await SupabaseService.getCurrentUserProfile();
      
      if (profile != null) {
        final method = profile['payout_method'] as String?;
        final phone = profile['payout_phone'] as String?;
        
        if (mounted) {
          setState(() {
            if (method != null && _methods.contains(method)) {
              _selectedMethod = method;
            }
            if (phone != null) {
              _phoneController.text = phone;
            }
            _isCheckingStatus = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isCheckingStatus = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingStatus = false;
          _errorMessage = 'Impossible de charger vos informations.';
        });
      }
    }
  }

  Future<void> _saveMethod() async {
    HapticFeedback.mediumImpact();
    
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 9) {
      setState(() {
        _errorMessage = 'Veuillez entrer un numéro de téléphone valide.';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      await SupabaseService.updatePayoutMethod(
        method: _selectedMethod,
        phone: phone,
      );
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Mode de réception enregistré avec succès',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white,
            ),
          ),
          backgroundColor: AppTheme.successGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      );
      
      // Go back to profile
      Navigator.pop(context, true);
      
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception:', '').trim();
        _isLoading = false;
      });
    }
  }

  String _getMethodLogo(String method) {
    switch (method) {
      case 'Wave':
        return 'assets/images/wave_logo.webp';
      case 'Orange Money':
        return 'assets/images/orange_money.png';
      case 'Free Money':
        return 'assets/images/freemoney.png';
      default:
        return '';
    }
  }

  Color _getMethodColor(String method) {
    switch (method) {
      case 'Wave':
        return const Color(0xFF1B40DF); // Wave blue
      case 'Orange Money':
        return const Color(0xFFFF6600); // Orange
      case 'Free Money':
        return const Color(0xFFE3000F); // Free red
      default:
        return AppTheme.primaryGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Mode de Réception',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: _isCheckingStatus
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child: Icon(
                                Icons.phone_android,
                                color: AppTheme.primaryGreen,
                                size: 24.0,
                              ),
                            ),
                            SizedBox(width: 12.0),
                            Expanded(
                              child: Text(
                                'Où recevoir votre argent ?',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.0),
                        Text(
                          'Configurez votre numéro Wave ou Orange Money. Lorsque vous vendez un produit, l\'argent sera transféré sur ce numéro.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16.0),

                  // Form
                  Text(
                    'Réseau',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 6.0),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedMethod,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down),
                        items: _methods.map((String method) {
                          return DropdownMenuItem<String>(
                            value: method,
                            child: Row(
                              children: [
                                Container(
                                  width: 32.0,
                                  height: 32.0,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    image: DecorationImage(
                                      image: AssetImage(_getMethodLogo(method)),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12.0),
                                Text(
                                  method,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedMethod = newValue;
                            });
                          }
                        },
                      ),
                    ),
                  ),

                  SizedBox(height: 16.0),

                  Text(
                    'Numéro de téléphone',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 6.0),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: GoogleFonts.inter(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Ex: 77 123 45 67',
                      hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: Icon(Icons.phone, color: Colors.grey.shade500),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 25.5,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.primaryGreen),
                      ),
                    ),
                  ),

                  SizedBox(height: 16.0),

                  // Error message
                  if (_errorMessage.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12.0),
                      margin: EdgeInsets.only(bottom: 12.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(10.0),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.red, size: 18),
                          SizedBox(width: 8.0),
                          Expanded(
                            child: Text(
                              _errorMessage,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  SizedBox(height: 17.0),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 51.0,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveMethod,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Enregistrer',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  SizedBox(height: 16.0),

                  // Security note
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_outline,
                            size: 14, color: Colors.grey),
                        SizedBox(width: 4.0),
                        Flexible(
                          child: Text(
                            'Vos informations sont sécurisées et cryptées',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
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
}
