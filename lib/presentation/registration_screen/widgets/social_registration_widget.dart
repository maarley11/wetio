import 'package:flutter/material.dart';

/// Legacy social registration widget - disabled for App Store submission
class SocialRegistrationWidget extends StatelessWidget {
  final VoidCallback? onGoogleSignUp;
  final VoidCallback? onAppleSignUp;
  final bool isLoading;

  const SocialRegistrationWidget({
    super.key,
    this.onGoogleSignUp,
    this.onAppleSignUp,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
