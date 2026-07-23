import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class RegistrationFormWidget extends StatefulWidget {
  final TextEditingController fullNameController;
  final TextEditingController pseudoController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final Function({
    required String fullName,
    required String pseudo,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
  }) onRegister;
  final bool isLoading;

  const RegistrationFormWidget({
    super.key,
    required this.fullNameController,
    required this.pseudoController,
    required this.emailController,
    required this.phoneController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.onRegister,
    this.isLoading = false,
  });

  @override
  State<RegistrationFormWidget> createState() => _RegistrationFormWidgetState();
}

class _RegistrationFormWidgetState extends State<RegistrationFormWidget> {
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isFormValid = false;
  bool _useEmail = false; // false = phone, true = email

  @override
  void initState() {
    super.initState();
    widget.fullNameController.addListener(_validateForm);
    widget.pseudoController.addListener(_validateForm);
    widget.phoneController.addListener(_validateForm);
    widget.emailController.addListener(_validateForm);
    widget.passwordController.addListener(_validateForm);
    widget.confirmPasswordController.addListener(_validateForm);
  }

  void _validateForm() {
    bool identifierValid;
    if (_useEmail) {
      final email = widget.emailController.text.trim();
      identifierValid =
          RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
    } else {
      final phone = widget.phoneController.text.trim();
      final cleaned = phone.replaceAll(RegExp(r'[\s\-\.\(\)\+]'), '');
      identifierValid = cleaned.length >= 7 &&
          cleaned.length <= 15 &&
          RegExp(r'^[0-9]+$').hasMatch(cleaned);
    }

    final isValid = widget.fullNameController.text.isNotEmpty &&
        widget.pseudoController.text.isNotEmpty &&
        identifierValid &&
        widget.passwordController.text.isNotEmpty &&
        widget.confirmPasswordController.text.isNotEmpty &&
        _isValidPseudo(widget.pseudoController.text) &&
        widget.passwordController.text.length >= 6;

    if (_isFormValid != isValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  void _toggleMode() {
    setState(() {
      _useEmail = !_useEmail;
      widget.phoneController.clear();
      widget.emailController.clear();
      _isFormValid = false;
    });
  }

  bool _isValidPhone(String phone) {
    if (phone.isEmpty) return false;
    final cleaned = phone.replaceAll(RegExp(r'[\s\-\.\(\)\+]'), '');
    if (cleaned.length < 7 || cleaned.length > 15) return false;
    return RegExp(r'^[0-9]+$').hasMatch(cleaned);
  }

  bool _isValidPseudo(String pseudo) {
    if (pseudo.isEmpty) return false;
    if (pseudo.length < 3 || pseudo.length > 20) return false;
    return RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(pseudo);
  }

  String? _validateFullName(String? value) {
    if (value == null || value.trim().isEmpty)
      return 'Veuillez saisir votre nom complet';
    if (value.trim().length < 2)
      return 'Le nom doit contenir au moins 2 caractères';
    return null;
  }

  String? _validatePseudo(String? value) {
    if (value == null || value.trim().isEmpty)
      return 'Veuillez choisir un pseudo';
    if (value.trim().length < 3)
      return 'Le pseudo doit contenir au moins 3 caractères';
    if (value.trim().length > 20)
      return 'Le pseudo ne doit pas dépasser 20 caractères';
    if (!_isValidPseudo(value.trim()))
      return 'Seuls lettres, chiffres, _ et - sont autorisés';
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty)
      return 'Veuillez saisir votre numéro de téléphone';
    if (!_isValidPhone(value)) return 'Numéro invalide (7 à 15 chiffres)';
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty)
      return 'Veuillez saisir votre adresse email';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
      return 'Adresse email invalide';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty)
      return 'Veuillez saisir un mot de passe';
    if (value.length < 6)
      return 'Le mot de passe doit contenir au moins 6 caractères';
    if (!RegExp(r'[A-Za-z]').hasMatch(value))
      return 'Le mot de passe doit contenir au moins une lettre';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty)
      return 'Veuillez confirmer votre mot de passe';
    if (value != widget.passwordController.text)
      return 'Les mots de passe ne correspondent pas';
    return null;
  }

  void _handleRegistration() {
    if (_formKey.currentState!.validate() &&
        _isFormValid &&
        !widget.isLoading) {
      HapticFeedback.lightImpact();
      widget.onRegister(
        fullName: widget.fullNameController.text.trim(),
        pseudo: widget.pseudoController.text.trim(),
        email: _useEmail ? widget.emailController.text.trim() : '',
        phone: _useEmail ? '' : widget.phoneController.text.trim(),
        password: widget.passwordController.text,
        confirmPassword: widget.confirmPasswordController.text,
      );
    }
  }

  InputDecoration _buildInputDecoration({
    required ColorScheme colorScheme,
    required String labelText,
    required String hintText,
    required Widget prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: colorScheme.surface,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.8),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline, width: 1)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline, width: 1)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 2)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.error, width: 1)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.error, width: 2)),
      labelStyle: GoogleFonts.inter(
          color: colorScheme.onSurfaceVariant,
          fontSize: 14,
          fontWeight: FontWeight.w400),
      hintStyle: GoogleFonts.inter(
          color: colorScheme.onSurfaceVariant,
          fontSize: 14,
          fontWeight: FontWeight.w300),
      errorStyle: GoogleFonts.inter(
          color: colorScheme.error,
          fontSize: 12,
          fontWeight: FontWeight.w400),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Full Name Field
          TextFormField(
            controller: widget.fullNameController,
            keyboardType: TextInputType.name,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            enabled: !widget.isLoading,
            style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: colorScheme.onSurface),
            decoration: _buildInputDecoration(
              colorScheme: colorScheme,
              labelText: 'Nom complet *',
              hintText: 'Entrez votre nom complet',
              prefixIcon: Padding(
                padding: EdgeInsets.all(12.0),
                child: CustomIconWidget(
                    iconName: 'person',
                    color: colorScheme.onSurfaceVariant,
                    size: 20),
              ),
            ),
            validator: _validateFullName,
          ),

          SizedBox(height: 17.0),

          // Pseudo Field
          TextFormField(
            controller: widget.pseudoController,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            enabled: !widget.isLoading,
            style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: colorScheme.onSurface),
            decoration: _buildInputDecoration(
              colorScheme: colorScheme,
              labelText: 'Pseudo *',
              hintText: 'Choisissez votre nom d\'utilisateur',
              prefixIcon: Padding(
                padding: EdgeInsets.all(12.0),
                child: CustomIconWidget(
                    iconName: 'alternate_email',
                    color: colorScheme.onSurfaceVariant,
                    size: 20),
              ),
            ).copyWith(
              helperText: 'Ceci sera votre identité publique sur WETIO',
              helperStyle: GoogleFonts.inter(
                  color: colorScheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w400),
            ),
            validator: _validatePseudo,
          ),

          SizedBox(height: 17.0),

          // Toggle phone / email
          Row(
            children: [
              _buildToggleButton(
                label: 'Téléphone',
                icon: Icons.phone,
                isSelected: !_useEmail,
                colorScheme: colorScheme,
                onTap: _useEmail ? _toggleMode : null,
              ),
              SizedBox(width: 8.0),
              _buildToggleButton(
                label: 'Email',
                icon: Icons.email,
                isSelected: _useEmail,
                colorScheme: colorScheme,
                onTap: !_useEmail ? _toggleMode : null,
              ),
            ],
          ),

          SizedBox(height: 12.8),

          // Phone or Email Field
          if (!_useEmail)
            TextFormField(
              controller: widget.phoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              enabled: !widget.isLoading,
              style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: colorScheme.onSurface),
              decoration: _buildInputDecoration(
                colorScheme: colorScheme,
                labelText: 'Numéro de téléphone *',
                hintText: '77 123 45 67',
                prefixIcon: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Icon(Icons.phone,
                      color: colorScheme.onSurfaceVariant, size: 20),
                ),
              ),
              validator: _validatePhone,
            )
          else
            TextFormField(
              controller: widget.emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              enabled: !widget.isLoading,
              style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: colorScheme.onSurface),
              decoration: _buildInputDecoration(
                colorScheme: colorScheme,
                labelText: 'Adresse email *',
                hintText: 'exemple@email.com',
                prefixIcon: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Icon(Icons.email,
                      color: colorScheme.onSurfaceVariant, size: 20),
                ),
              ),
              validator: _validateEmail,
            ),

          SizedBox(height: 17.0),

          // Password Field
          TextFormField(
            controller: widget.passwordController,
            obscureText: !_isPasswordVisible,
            textInputAction: TextInputAction.next,
            enabled: !widget.isLoading,
            style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: colorScheme.onSurface),
            decoration: _buildInputDecoration(
              colorScheme: colorScheme,
              labelText: 'Mot de passe *',
              hintText: 'Choisissez un mot de passe sécurisé',
              prefixIcon: Padding(
                padding: EdgeInsets.all(12.0),
                child: CustomIconWidget(
                    iconName: 'lock',
                    color: colorScheme.onSurfaceVariant,
                    size: 20),
              ),
              suffixIcon: GestureDetector(
                onTap: widget.isLoading
                    ? null
                    : () {
                        HapticFeedback.lightImpact();
                        setState(
                            () => _isPasswordVisible = !_isPasswordVisible);
                      },
                child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: CustomIconWidget(
                    iconName:
                        _isPasswordVisible ? 'visibility_off' : 'visibility',
                    color: colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
              ),
            ),
            validator: _validatePassword,
          ),

          SizedBox(height: 17.0),

          // Confirm Password Field
          TextFormField(
            controller: widget.confirmPasswordController,
            obscureText: !_isConfirmPasswordVisible,
            textInputAction: TextInputAction.done,
            enabled: !widget.isLoading,
            style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: colorScheme.onSurface),
            decoration: _buildInputDecoration(
              colorScheme: colorScheme,
              labelText: 'Confirmer le mot de passe *',
              hintText: 'Confirmez votre mot de passe',
              prefixIcon: Padding(
                padding: EdgeInsets.all(12.0),
                child: CustomIconWidget(
                    iconName: 'lock',
                    color: colorScheme.onSurfaceVariant,
                    size: 20),
              ),
              suffixIcon: GestureDetector(
                onTap: widget.isLoading
                    ? null
                    : () {
                        HapticFeedback.lightImpact();
                        setState(() => _isConfirmPasswordVisible =
                            !_isConfirmPasswordVisible);
                      },
                child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: CustomIconWidget(
                    iconName: _isConfirmPasswordVisible
                        ? 'visibility_off'
                        : 'visibility',
                    color: colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
              ),
            ),
            validator: _validateConfirmPassword,
            onFieldSubmitted: (_) => _handleRegistration(),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required ColorScheme colorScheme,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 8.5),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outline.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant),
              SizedBox(width: 4.0),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
