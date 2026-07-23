import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../theme/app_theme.dart';

class CodeInputKeypadWidget extends StatelessWidget {
  final String enteredCode;
  final bool hasError;
  final bool isValidating;
  final bool isSuccess;
  final VoidCallback onValidate;
  final Function(String) onCodeChanged;

  const CodeInputKeypadWidget({
    super.key,
    required this.enteredCode,
    required this.hasError,
    required this.isValidating,
    required this.isSuccess,
    required this.onValidate,
    required this.onCodeChanged,
  });

  void _onKeyTap(String key, BuildContext context) {
    HapticFeedback.lightImpact();
    if (key == 'del') {
      if (enteredCode.isNotEmpty) {
        onCodeChanged(enteredCode.substring(0, enteredCode.length - 1));
      }
    } else if (enteredCode.length < 4) {
      onCodeChanged(enteredCode + key);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Code display dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (i) {
            final filled = i < enteredCode.length;
            final char = filled ? enteredCode[i] : null;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.symmetric(horizontal: 12.0),
              width: 64.0,
              height: 64.0,
              decoration: BoxDecoration(
                color: isSuccess
                    ? AppTheme.successGreen.withValues(alpha: 0.12)
                    : hasError
                        ? AppTheme.errorRed.withValues(alpha: 0.08)
                        : filled
                            ? AppTheme.primaryGreen.withValues(alpha: 0.08)
                            : AppTheme.backgroundWhite,
                borderRadius: BorderRadius.circular(14.0),
                border: Border.all(
                  color: isSuccess
                      ? AppTheme.successGreen
                      : hasError
                          ? AppTheme.errorRed
                          : filled
                              ? AppTheme.primaryGreen
                              : AppTheme.borderLight,
                  width: filled ? 2 : 1.5,
                ),
                boxShadow: filled
                    ? [
                        BoxShadow(
                          color: (isSuccess
                                  ? AppTheme.successGreen
                                  : hasError
                                      ? AppTheme.errorRed
                                      : AppTheme.primaryGreen)
                              .withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: char != null
                    ? Text(
                        char,
                        style: GoogleFonts.dmSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: isSuccess
                              ? AppTheme.successGreen
                              : hasError
                                  ? AppTheme.errorRed
                                  : AppTheme.primaryGreen,
                        ),
                      )
                    : null,
              ),
            );
          }),
        ),

        SizedBox(height: 8.5),

        // Status message
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: isSuccess
              ? Row(
                  key: const ValueKey('success'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: AppTheme.successGreen,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Code validé avec succès !',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.successGreen,
                      ),
                    ),
                  ],
                )
              : hasError
                  ? Row(
                      key: const ValueKey('error'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppTheme.errorRed,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Code incorrect. Réessayez.',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.errorRed,
                          ),
                        ),
                      ],
                    )
                  : SizedBox(key: const ValueKey('empty'), height: 20),
        ),

        SizedBox(height: 17.0),

        // Numeric keypad
        _buildKeypad(context),

        SizedBox(height: 17.0),

        // Validate button
        SizedBox(
          width: double.infinity,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: ElevatedButton(
              onPressed: enteredCode.length == 4 && !isValidating && !isSuccess
                  ? onValidate
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                disabledBackgroundColor: AppTheme.borderLight,
                padding: EdgeInsets.symmetric(vertical: 15.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.0),
                ),
                elevation: enteredCode.length == 4 ? 3 : 0,
              ),
              child: isValidating
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      'Valider le code',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKeypad(BuildContext context) {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'del'],
    ];

    return Column(
      children: keys.map((row) {
        return Padding(
          padding: EdgeInsets.only(bottom: 8.5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((key) {
              if (key.isEmpty) {
                return SizedBox(width: 80.0, height: 56.0);
              }
              return GestureDetector(
                onTap: () => _onKeyTap(key, context),
                child: Container(
                  width: 80.0,
                  height: 56.0,
                  margin: EdgeInsets.symmetric(horizontal: 8.0),
                  decoration: BoxDecoration(
                    color: key == 'del'
                        ? AppTheme.errorRed.withValues(alpha: 0.08)
                        : AppTheme.surfaceWhite,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: key == 'del'
                          ? AppTheme.errorRed.withValues(alpha: 0.2)
                          : AppTheme.borderLight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: key == 'del'
                        ? const Icon(
                            Icons.backspace_outlined,
                            color: AppTheme.errorRed,
                            size: 22,
                          )
                        : Text(
                            key,
                            style: GoogleFonts.dmSans(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}
