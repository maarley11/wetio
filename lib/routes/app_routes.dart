import 'package:flutter/material.dart';

import '../presentation/add_product/add_product.dart';
import '../presentation/chat_messages_hub/chat_messages_hub.dart';
import '../presentation/login_screen/login_screen.dart';
import '../presentation/registration_screen/registration_screen.dart';
import '../presentation/delivery_partner_registration_simplified/delivery_partner_registration_simplified.dart';
import '../presentation/delivery_request_system/delivery_request_system.dart';
import '../presentation/direct_card_payment_interface/direct_card_payment_interface.dart';
import '../presentation/card_payment_form/card_payment_form.dart';
import '../presentation/exchange_proposal/exchange_proposal.dart';
import '../presentation/exchange_conversation_actions/exchange_conversation_actions.dart';
import '../presentation/exchange_delivery_coordination/exchange_delivery_coordination.dart';
import '../presentation/exchange_agreement_delivery/exchange_agreement_delivery.dart';
import '../presentation/home_feed/home_feed.dart';
import '../presentation/product_detail/product_detail.dart';
import '../presentation/token_purchase_screen/token_purchase_screen.dart';
import '../presentation/user_profile/user_profile.dart';
import '../presentation/terms_of_service_screen/terms_of_service_screen.dart';
import '../presentation/completed_exchange_archive/completed_exchange_archive.dart';
import '../presentation/account_settings_screen/account_settings_screen.dart';
import '../presentation/edit_profile_screen/edit_profile_screen.dart';
import '../presentation/notification_settings_screen/notification_settings_screen.dart';
import '../presentation/privacy_settings_screen/privacy_settings_screen.dart';
import '../presentation/notifications_screen/notifications_screen.dart';
import '../presentation/location_selection_screen/location_selection_screen.dart';
import '../presentation/commission_management_dashboard/commission_management_dashboard.dart';
import '../presentation/secure_payment_escrow_system/secure_payment_escrow_system.dart';
import '../presentation/delivery_partner_earnings_dashboard/delivery_partner_earnings_dashboard.dart';
import '../presentation/delivery_request_confirmation_screen/delivery_request_confirmation_screen.dart';
import '../presentation/three_step_delivery_coordination_screen/three_step_delivery_coordination_screen.dart';
import '../presentation/delivery_partner_code_validation_interface/delivery_partner_code_validation_interface.dart';
import '../presentation/delivery_partner_notification_system/delivery_partner_notification_system.dart';
import '../presentation/delivery_partner_search/delivery_partner_search.dart';
import '../presentation/delivery_partner_profile_tiers/delivery_partner_profile_tiers.dart';
import '../presentation/regional_delivery_search/regional_delivery_search.dart';
import '../presentation/ad_banner_scheduling/ad_banner_scheduling_screen.dart';
import '../presentation/ad_banner_analytics/ad_banner_analytics_dashboard.dart';
import '../presentation/product_purchase_screen/product_purchase_screen.dart';
import '../presentation/payout_methods_screen/payout_methods_screen.dart';

class AppRoutes {
  static const String splashScreen = '/splash_screen';
  static const String loginScreen = '/login_screen';
  static const String registrationScreen = '/registration-screen';
  static const String termsOfServiceScreen = '/terms-of-service-screen';
  static const String homeFeed = '/home_feed';
  static const String userProfile = '/user_profile';
  static const String addProduct = '/add_product';
  static const String productDetail = '/product_detail';
  static const String exchangeProposal = '/exchange_proposal';
  static const String exchangeConversationActions =
      '/exchange_conversation_actions';
  static const String exchangeAgreementDelivery =
      '/exchange_agreement_delivery';
  static const String exchangeDeliveryCoordination =
      '/exchange-delivery-coordination';
  static const String deliveryPartnerSearch = '/delivery_partner_search';
  static const String deliveryPartnerRegistration =
      '/delivery_partner_registration';
  static const String deliveryPartnerRegistrationSimplified =
      '/delivery_partner_registration_simplified';
  static const String deliveryPartnerPremiumRegistration =
      '/delivery_partner_premium_registration';
  static const String deliveryPartnerProfileTiers =
      '/delivery_partner_profile_tiers';
  static const String deliveryPartnerNotificationSystem =
      '/delivery_partner_notification_system';
  static const String regionalDeliverySearch = '/regional_delivery_search';
  static const String tokenPurchaseScreen = '/token_purchase_screen';
  static const String directCardPaymentInterface =
      '/direct-card-payment-interface';
  static const String cardPaymentForm = '/card-payment-form';
  static const String completedExchangeArchive = '/completed-exchange-archive';
  static const String accountSettingsScreen = '/account-settings-screen';
  static const String editProfileScreen = '/edit-profile-screen';
  static const String notificationSettingsScreen =
      '/notification-settings-screen';
  static const String privacySettingsScreen = '/privacy-settings-screen';
  static const String notificationsScreen = '/notifications-screen';
  static const String locationSelectionScreen = '/location-selection-screen';
  static const String commissionManagementDashboard =
      '/commission-management-dashboard';
  static const String securePaymentEscrowSystem =
      '/secure-payment-escrow-system';
  static const String deliveryPartnerEarningsDashboard =
      '/delivery-partner-earnings-dashboard';
  static const String chatMessagesHub = '/chat-messages-hub';
  static const String deliveryRequestSystem = '/delivery-request-system';
  static const String deliveryRequestConfirmationScreen =
      '/delivery-request-confirmation-screen';
  static const String threeStepDeliveryCoordinationScreen =
      '/three-step-delivery-coordination-screen';
  static const String deliveryPartnerCodeValidationInterface =
      '/delivery-partner-code-validation-interface';
  static const String adBannerScheduling = '/ad-banner-scheduling';
  static const String adBannerAnalyticsDashboard =
      '/ad-banner-analytics-dashboard';
  static const String productPurchase = '/product-purchase';
  static const String payoutMethods = '/payout-methods';

  static Map<String, WidgetBuilder> get routes => {
        loginScreen: (context) => const LoginScreen(),
        registrationScreen: (context) => const RegistrationScreen(),
        termsOfServiceScreen: (context) => const TermsOfServiceScreen(),
        homeFeed: (context) => const HomeFeed(),
        userProfile: (context) => const UserProfileScreen(),
        addProduct: (context) => const AddProductScreen(),
        tokenPurchaseScreen: (context) => const TokenPurchaseScreen(),
        directCardPaymentInterface: (context) =>
            const DirectCardPaymentInterface(),
        cardPaymentForm: (context) => const CardPaymentFormScreen(),
        productDetail: (context) => const ProductDetail(),
        exchangeProposal: (context) => const ExchangeProposal(),
        exchangeConversationActions: (context) =>
            const ExchangeConversationActions(),
        exchangeAgreementDelivery: (context) =>
            const ExchangeAgreementDelivery(),
        exchangeDeliveryCoordination: (context) =>
            const ExchangeDeliveryCoordination(),
        deliveryPartnerSearch: (context) => const DeliveryPartnerSearch(),
        deliveryPartnerRegistrationSimplified: (context) =>
            const DeliveryPartnerRegistrationSimplified(),
        deliveryPartnerProfileTiers: (context) =>
            const DeliveryPartnerProfileTiers(),
        deliveryPartnerNotificationSystem: (context) =>
            const DeliveryPartnerNotificationSystem(),
        regionalDeliverySearch: (context) => const RegionalDeliverySearch(),
        completedExchangeArchive: (context) => const CompletedExchangeArchive(),
        accountSettingsScreen: (context) => const AccountSettingsScreen(),
        editProfileScreen: (context) => const EditProfileScreen(),
        notificationSettingsScreen: (context) =>
            const NotificationSettingsScreen(),
        privacySettingsScreen: (context) => const PrivacySettingsScreen(),
        notificationsScreen: (context) => const NotificationsScreen(),
        locationSelectionScreen: (context) => const LocationSelectionScreen(),
        commissionManagementDashboard: (context) =>
            const CommissionManagementDashboard(),
        securePaymentEscrowSystem: (context) =>
            const SecurePaymentEscrowSystem(),
        deliveryPartnerEarningsDashboard: (context) =>
            const DeliveryPartnerEarningsDashboard(),
        chatMessagesHub: (context) => const ChatMessagesHub(),
        deliveryRequestSystem: (context) => const DeliveryRequestSystem(),
        deliveryRequestConfirmationScreen: (context) =>
            const DeliveryRequestConfirmationScreen(),
        threeStepDeliveryCoordinationScreen: (context) =>
            const ThreeStepDeliveryCoordinationScreen(),
        deliveryPartnerCodeValidationInterface: (context) =>
            const DeliveryPartnerCodeValidationInterface(),
        adBannerScheduling: (context) => const AdBannerSchedulingScreen(),
        adBannerAnalyticsDashboard: (context) =>
            const AdBannerAnalyticsDashboard(),
        productPurchase: (context) => const ProductPurchaseScreen(),
        payoutMethods: (context) => const PayoutMethodsScreen(),
      };
}
