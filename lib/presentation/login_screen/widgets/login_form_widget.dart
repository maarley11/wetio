import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/supabase_service.dart';
import '../../../theme/app_theme.dart';

class LoginFormWidget extends StatefulWidget {
  final Function(String identifier, String password) onLogin;
  final bool isLoading;

  const LoginFormWidget({
    super.key,
    required this.onLogin,
    this.isLoading = false,
  });

  @override
  State<LoginFormWidget> createState() => _LoginFormWidgetState();
}

class _LoginFormWidgetState extends State<LoginFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isFormValid = false;
  bool _useEmail = false; // false = phone, true = email

  @override
  void initState() {
    super.initState();
    _identifierController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validateForm() {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text.trim();

    bool identifierValid;
    if (_useEmail) {
      identifierValid =
          RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(identifier);
    } else {
      final cleaned = identifier.replaceAll(RegExp(r'[\s\-\.\(\)\+]'), '');
      identifierValid = cleaned.length >= 7 &&
          cleaned.length <= 15 &&
          RegExp(r'^[0-9]+$').hasMatch(cleaned);
    }

    final isValid =
        identifierValid && password.isNotEmpty && password.length >= 6;

    if (_isFormValid != isValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  String? _validateIdentifier(String? value) {
    if (value == null || value.isEmpty) {
      return _useEmail
          ? 'Veuillez saisir votre adresse email'
          : 'Veuillez saisir votre numéro de téléphone';
    }
    if (_useEmail) {
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
        return 'Adresse email invalide';
      }
    } else {
      final cleaned = value.trim().replaceAll(RegExp(r'[\s\-\.\(\)\+]'), '');
      if (cleaned.length < 7 ||
          cleaned.length > 15 ||
          !RegExp(r'^[0-9]+$').hasMatch(cleaned)) {
        return 'Numéro invalide (7 à 15 chiffres)';
      }
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez saisir votre mot de passe';
    }
    if (value.length < 6) {
      return 'Le mot de passe doit contenir au moins 6 caractères';
    }
    return null;
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate() &&
        _isFormValid &&
        !widget.isLoading) {
      HapticFeedback.lightImpact();
      widget.onLogin(
          _identifierController.text.trim(), _passwordController.text);
    }
  }

  void _toggleLoginMode() {
    setState(() {
      _useEmail = !_useEmail;
      _identifierController.clear();
      _isFormValid = false;
    });
  }

  void _showForgotPasswordDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final controller = TextEditingController();
    bool isSending = false;
    bool sent = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.lock_reset, color: colorScheme.primary, size: 28),
              SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  'Mot de passe oublié',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          content: sent
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle,
                        color: AppTheme.successGreen, size: 48),
                    SizedBox(height: 17.0),
                    Text(
                      'Un SMS de récupération a été envoyé à votre numéro.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Entrez votre numéro de téléphone pour recevoir un SMS de récupération:',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 12.8),
                    TextField(
                      controller: controller,
                      keyboardType: TextInputType.phone,
                      style: GoogleFonts.inter(
                          fontSize: 14, color: colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Numéro de téléphone',
                        hintText: '77 123 45 67',
                        prefixIcon: Icon(Icons.phone,
                            color: colorScheme.onSurfaceVariant, size: 20),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: colorScheme.outline),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                              color:
                                  colorScheme.outline.withValues(alpha: 0.5)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              BorderSide(color: colorScheme.primary, width: 2),
                        ),
                        labelStyle: GoogleFonts.inter(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant),
                        hintStyle: GoogleFonts.inter(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.6)),
                      ),
                    ),
                  ],
                ),
          actions: sent
              ? [
                  ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      'Fermer',
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onPrimary),
                    ),
                  ),
                ]
              : [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text('Annuler',
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            color: colorScheme.onSurfaceVariant)),
                  ),
                  ElevatedButton(
                    onPressed: isSending
                        ? null
                        : () async {
                            final value = controller.text.trim();
                            if (value.isEmpty) return;
                            setDialogState(() => isSending = true);
                            try {
                              await SupabaseService.resetPasswordByPhone(value);
                              setDialogState(() {
                                isSending = false;
                                sent = true;
                              });
                            } catch (e) {
                              setDialogState(() => isSending = false);
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Erreur: Vérifiez votre numéro et réessayez.',
                                        style:
                                            GoogleFonts.inter(fontSize: 13)),
                                    backgroundColor: colorScheme.error,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: isSending
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                color: colorScheme.onPrimary, strokeWidth: 2))
                        : Text('Envoyer',
                            style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onPrimary)),
                  ),
                ],
        ),
      ),
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
          // Toggle email / phone
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildToggleButton(
                label: 'Téléphone',
                icon: Icons.phone,
                isSelected: !_useEmail,
                colorScheme: colorScheme,
                onTap: _useEmail ? _toggleLoginMode : null,
              ),
              SizedBox(width: 8.0),
              _buildToggleButton(
                label: 'Email',
                icon: Icons.email,
                isSelected: _useEmail,
                colorScheme: colorScheme,
                onTap: !_useEmail ? _toggleLoginMode : null,
              ),
            ],
          ),

          SizedBox(height: 17.0),

          // Identifier Field (phone or email)
          TextFormField(
            controller: _identifierController,
            keyboardType:
                _useEmail ? TextInputType.emailAddress : TextInputType.phone,
            textInputAction: TextInputAction.next,
            enabled: !widget.isLoading,
            style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: colorScheme.onSurface),
            decoration: InputDecoration(
              labelText: _useEmail ? 'Adresse email' : 'Numéro de téléphone',
              hintText: _useEmail ? 'exemple@email.com' : '77 123 45 67',
              prefixIcon: Padding(
                padding: EdgeInsets.all(12.0),
                child: Icon(
                  _useEmail ? Icons.email : Icons.phone,
                  color: colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
              filled: true,
              fillColor: colorScheme.surface,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.8),
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
                  fontSize: 12,
                  fontWeight: FontWeight.w300),
              errorStyle: GoogleFonts.inter(
                  color: colorScheme.error,
                  fontSize: 11,
                  fontWeight: FontWeight.w400),
            ),
            validator: _validateIdentifier,
          ),

          SizedBox(height: 17.0),

          // Password Field
          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            textInputAction: TextInputAction.done,
            enabled: !widget.isLoading,
            style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: colorScheme.onSurface),
            decoration: InputDecoration(
              labelText: 'Mot de passe',
              hintText: 'Entrez votre mot de passe',
              prefixIcon: Padding(
                padding: EdgeInsets.all(12.0),
                child: Icon(Icons.lock,
                    color: colorScheme.onSurfaceVariant, size: 20),
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
                  child: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
              ),
              filled: true,
              fillColor: colorScheme.surface,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.8),
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
            ),
            validator: _validatePassword,
            onFieldSubmitted: (_) => _handleLogin(),
          ),

          SizedBox(height: 8.5),

          // Forgot Password Link
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: widget.isLoading
                  ? null
                  : () {
                      HapticFeedback.lightImpact();
                      _showForgotPasswordDialog(context);
                    },
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.3),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Mot de passe oublié?',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.primary),
              ),
            ),
          ),

          SizedBox(height: 25.5),

          // Login Button
          SizedBox(
            width: double.infinity,
            height: 51.0,
            child: ElevatedButton(
              onPressed:
                  _isFormValid && !widget.isLoading ? _handleLogin : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isFormValid && !widget.isLoading
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                foregroundColor: _isFormValid && !widget.isLoading
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                elevation: _isFormValid && !widget.isLoading ? 2 : 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding: EdgeInsets.symmetric(vertical: 12.8),
              ),
              child: widget.isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.onPrimary)),
                    )
                  : Text(
                      'Se connecter',
                      style: GoogleFonts.inter(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
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
