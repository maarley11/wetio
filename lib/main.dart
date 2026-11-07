import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_export.dart';
import './services/notification_service.dart';
import './services/supabase_service.dart';
import './widgets/custom_error_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase FIRST - gracefully handle failures
  try {
    await SupabaseService.initialize();
  } catch (e) {
    debugPrint('Failed to initialize Supabase: $e');
  }

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  NotificationService.setNavigatorKey(navigatorKey);

  // Listen to Supabase Auth state changes (handles email confirmation link redirect)
  if (SupabaseService.isInitialized) {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;
      if (event == AuthChangeEvent.signedIn && session?.user != null) {
        NotificationService.bindUser(session!.user.id);
      } else if (event == AuthChangeEvent.signedOut) {
        NotificationService.unbindUser();
      }
    });
  }

  bool _hasShownError = false;

  // 🚨 CRITICAL: Custom error handling - DO NOT REMOVE
  ErrorWidget.builder = (FlutterErrorDetails details) {
    debugPrint('Flutter error: ${details.exception}');
    if (!_hasShownError) {
      _hasShownError = true;

      // Reset flag after 3 seconds to allow error widget on new screens
      Future.delayed(Duration(seconds: 5), () {
        _hasShownError = false;
      });

      return CustomErrorWidget(errorDetails: details);
    }
    return SizedBox.shrink();
  };

  // 🚨 CRITICAL: Device orientation lock - only on mobile, not web
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  runApp(MyApp());

  // Non-blocking background initialization after first frame for instant startup
  WidgetsBinding.instance.addPostFrameCallback((_) {
    const stripePublishableKey = String.fromEnvironment(
      'STRIPE_PUBLISHABLE_KEY',
      defaultValue: '',
    );
    if (stripePublishableKey.isNotEmpty) {
      if (kReleaseMode && stripePublishableKey.startsWith('pk_test_')) {
        debugPrint('🚨 SECURITY WARNING: Clé Stripe pk_test_ détectée en build de production !');
      }
      Stripe.publishableKey = stripePublishableKey;
      if (kIsWeb) {
        unawaited(Stripe.instance.applySettings());
      }
    }
    unawaited(NotificationService.init());
  });
}

class MyApp extends StatelessWidget {
  static const Set<String> _instantTabRoutes = {
    AppRoutes.homeFeed,
    AppRoutes.chatMessagesHub,
    AppRoutes.addProduct,
    AppRoutes.deliveryPartnerRegistrationSimplified,
    AppRoutes.userProfile,
  };

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        color: const Color(0xFFF5F5F5), // Light background for web empty space
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480), // Mobile width constraint
            child: Sizer(
              builder: (context, orientation, screenType) {
        return MaterialApp(
          navigatorKey: NotificationService.navigatorKey,
          title: 'wetio',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          // 🚨 CRITICAL: NEVER REMOVE OR MODIFY
          builder: (context, child) {
            final mediaQueryData = MediaQuery.of(context);
            final clampedWidth = mediaQueryData.size.width > 480 ? 480.0 : mediaQueryData.size.width;
            
            return MediaQuery(
              data: mediaQueryData.copyWith(
                textScaler: TextScaler.linear(1.0),
                size: Size(clampedWidth, mediaQueryData.size.height),
              ),
              child: child!,
            );
          },
          // 🚨 END CRITICAL SECTION
          debugShowCheckedModeBanner: false,
          initialRoute: kIsWeb ? AppRoutes.homeFeed : AppRoutes.splashScreen,
          onGenerateRoute: (settings) {
            final routeBuilder = AppRoutes.routes[settings.name];
            if (routeBuilder == null) return null;

            final isTabRoute = _instantTabRoutes.contains(settings.name);
            return PageRouteBuilder(
              settings: settings,
              transitionDuration: isTabRoute
                  ? Duration.zero
                  : const Duration(milliseconds: 110),
              reverseTransitionDuration: isTabRoute
                  ? Duration.zero
                  : const Duration(milliseconds: 90),
              pageBuilder: (context, animation, secondaryAnimation) =>
                  routeBuilder(context),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                if (isTabRoute || animation.value == 1.0) return child;
                return FadeTransition(
                  opacity: CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOut,
                  ),
                  child: child,
                );
              },
            );
          },
        );
      },
    )
          )
        )
      )
    );
  }
}
