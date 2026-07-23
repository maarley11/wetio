import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class ConfirmationWorkflowWidget extends StatefulWidget {
  final VoidCallback onConfirm;

  const ConfirmationWorkflowWidget({super.key, required this.onConfirm});

  @override
  State<ConfirmationWorkflowWidget> createState() =>
      _ConfirmationWorkflowWidgetState();
}

class _ConfirmationWorkflowWidgetState
    extends State<ConfirmationWorkflowWidget> {
  String _selectedMethod = 'pin';
  final _pinController = TextEditingController();

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Confirmer la réception',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 4.3),
          Text(
            'Choisissez votre méthode de confirmation pour libérer les fonds',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 17.0),
          Row(
            children: [
              _buildMethodChip(context, 'pin', Icons.pin, 'Code PIN'),
              SizedBox(width: 8.0),
              _buildMethodChip(context, 'photo', Icons.camera_alt, 'Photo'),
              SizedBox(width: 8.0),
              _buildMethodChip(context, 'signature', Icons.draw, 'Signature'),
            ],
          ),
          SizedBox(height: 17.0),
          if (_selectedMethod == 'pin') ...[
            TextFormField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                labelText: 'Code PIN (4 chiffres)',
                labelStyle: GoogleFonts.inter(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: AppTheme.primaryGreen,
                    width: 2,
                  ),
                ),
                counterText: '',
              ),
            ),
          ] else if (_selectedMethod == 'photo') ...[
            Container(
              height: 127.5,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.camera_alt,
                      color: colorScheme.onSurfaceVariant,
                      size: 32,
                    ),
                    SizedBox(height: 8.5),
                    Text(
                      'Prendre une photo du colis reçu',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            Container(
              height: 127.5,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.draw,
                      color: colorScheme.onSurfaceVariant,
                      size: 32,
                    ),
                    SizedBox(height: 8.5),
                    Text(
                      'Signez ici pour confirmer',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          SizedBox(height: 17.0),
          SizedBox(
            width: double.infinity,
            height: 51.0,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                widget.onConfirm();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'Confirmer la réception et libérer les fonds',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodChip(
    BuildContext context,
    String method,
    IconData icon,
    String label,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _selectedMethod == method;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => _selectedMethod = method);
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8.5),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryGreen.withValues(alpha: 0.1)
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? AppTheme.primaryGreen
                  : colorScheme.outline.withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? AppTheme.primaryGreen
                    : colorScheme.onSurfaceVariant,
                size: 20,
              ),
              SizedBox(height: 4.3),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  color: isSelected
                      ? AppTheme.primaryGreen
                      : colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
