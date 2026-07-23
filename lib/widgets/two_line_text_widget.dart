import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class TwoLineTextWidget extends StatelessWidget {
  final String topText;
  final String bottomText;
  final Color? color;
  final double? fontSize;
  final FontWeight? fontWeight;
  final TextAlign? textAlign;

  const TwoLineTextWidget({
    super.key,
    required this.topText,
    required this.bottomText,
    this.color,
    this.fontSize,
    this.fontWeight,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          topText,
          style: GoogleFonts.inter(
            fontSize: fontSize ?? 16,
            fontWeight: fontWeight ?? FontWeight.w800,
            color: color ?? Colors.white,
            height: 1.1,
            letterSpacing: 1.2,
          ),
          textAlign: textAlign ?? TextAlign.center,
        ),
        if (bottomText.isNotEmpty) ...[
          SizedBox(height: 1.7),
          Text(
            bottomText,
            style: GoogleFonts.inter(
              fontSize: (fontSize ?? 16) * 0.95,
              fontWeight: fontWeight ?? FontWeight.w800,
              color: color ?? Colors.white,
              height: 1.1,
              letterSpacing: 1.2,
            ),
            textAlign: textAlign ?? TextAlign.center,
          ),
        ],
      ],
    );
  }
}
