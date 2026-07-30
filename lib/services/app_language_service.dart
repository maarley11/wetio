import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLanguageService extends ChangeNotifier {
  static final AppLanguageService instance = AppLanguageService._();
  AppLanguageService._() {
    loadLanguage();
  }

  String _currentLanguage = 'fr';
  String get currentLanguage => _currentLanguage;

  Future<void> loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentLanguage = prefs.getString('app_language') ?? 'fr';
      notifyListeners();
    } catch (_) {}
  }

  Future<void> changeLanguage(String langCode) async {
    _currentLanguage = langCode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_language', langCode);
    } catch (_) {}
  }

  static const Map<String, Map<String, String>> _localizedValues = {
    'fr': {
      'account_settings': 'Paramètres du compte',
      'edit_profile': 'Modifier le profil',
      'notifications': 'Notifications',
      'privacy': 'Confidentialité',
      'security': 'Sécurité',
      'language': 'Langue',
      'dangerous_zone': 'Zone dangereuse',
      'sign_out': 'Se déconnecter',
      'sign_in': 'Se connecter / S\'inscrire',
      'export_data': 'Exporter mes données',
      'deactivate_account': 'Désactiver le compte',
      'delete_account': 'Supprimer le compte',
      'my_profile': 'Mon Profil',
      'exchanges': 'Échanges',
      'rating': 'Note',
      'member_since': 'Membre depuis',
      'my_tokens': 'Mes jetons',
      'buy': 'Acheter',
      'history': 'Historique',
      'home': 'Accueil',
      'chat': 'Chat',
      'add': 'Ajouter',
      'courier': 'Livreur',
      'profile': 'Profil',
      'search_products': 'Rechercher des produits...',
      'my_products': 'Mes Produits',
      'favorites': 'LI LA BEUGUE',
      'completed_exchanges': 'Échanges Terminés',
      'login_welcome': 'Bon retour !',
      'login_subtitle': 'Connectez-vous avec votre email ou téléphone',
      'phone': 'Téléphone',
      'email': 'Email',
      'phone_number': 'Numéro de téléphone',
      'password': 'Mot de passe',
      'forgot_password': 'Mot de passe oublié ?',
      'sign_in_btn': 'Se connecter',
      'continue_google': 'Continuer avec Google',
      'continue_apple': 'Continuer avec Apple',
      'no_account': 'Pas encore de compte ?',
      'sign_up_link': 'S\'inscrire',
      'category_all': 'Toutes',
      'category_electronics': 'Électronique',
      'category_fashion': 'Mode',
      'category_home': 'Maison',
      'category_vehicles': 'Véhicules',
      'category_services': 'Services',
    },
    'en': {
      'account_settings': 'Account Settings',
      'edit_profile': 'Edit Profile',
      'notifications': 'Notifications',
      'privacy': 'Privacy',
      'security': 'Security',
      'language': 'Language',
      'dangerous_zone': 'Danger Zone',
      'sign_out': 'Sign Out',
      'sign_in': 'Sign In / Register',
      'export_data': 'Export My Data',
      'deactivate_account': 'Deactivate Account',
      'delete_account': 'Delete Account',
      'my_profile': 'My Profile',
      'exchanges': 'Exchanges',
      'rating': 'Rating',
      'member_since': 'Member Since',
      'my_tokens': 'My Tokens',
      'buy': 'Buy',
      'history': 'History',
      'home': 'Home',
      'chat': 'Chat',
      'add': 'Add',
      'courier': 'Delivery',
      'profile': 'Profile',
      'search_products': 'Search products...',
      'my_products': 'My Products',
      'favorites': 'FAVORITES',
      'completed_exchanges': 'Completed Exchanges',
      'login_welcome': 'Welcome Back!',
      'login_subtitle': 'Sign in with your email or phone',
      'phone': 'Phone',
      'email': 'Email',
      'phone_number': 'Phone number',
      'password': 'Password',
      'forgot_password': 'Forgot password?',
      'sign_in_btn': 'Sign In',
      'continue_google': 'Continue with Google',
      'continue_apple': 'Continue with Apple',
      'no_account': 'Don\'t have an account?',
      'sign_up_link': 'Sign Up',
      'category_all': 'All',
      'category_electronics': 'Electronics',
      'category_fashion': 'Fashion',
      'category_home': 'Home',
      'category_vehicles': 'Vehicles',
      'category_services': 'Services',
    },
    'wo': {
      'account_settings': 'Parameetaru Kuru',
      'edit_profile': 'Soppi sa profiil',
      'notifications': 'Yégle yi',
      'privacy': 'Sutura',
      'security': 'Kàrànte',
      'language': 'Lakk bi',
      'dangerous_zone': 'Barab bu waaŋ',
      'sign_out': 'Génn',
      'sign_in': 'Dugg / Bindu',
      'export_data': 'Yebbal samay njàngat',
      'deactivate_account': 'Dakkal kuru bi',
      'delete_account': 'Far kuru bi',
      'my_profile': 'Sama Profiil',
      'exchanges': 'Weccee',
      'rating': 'Nattal',
      'member_since': 'Bokku na ci',
      'my_tokens': 'Samay xaalisu jeton',
      'buy': 'Jënd',
      'history': 'Tarix',
      'home': 'Keur gi',
      'chat': 'Waxtaan',
      'add': 'Yokal',
      'courier': 'Livreur bi',
      'profile': 'Profiil',
      'search_products': 'Wut ak njaay...',
      'my_products': 'Samay Njaay',
      'favorites': 'LI LA BEUGUE',
      'completed_exchanges': 'Weccee yu noppi',
      'login_welcome': 'Aksil ak jàmm !',
      'login_subtitle': 'Duggup ak sa email walla sa telefon',
      'phone': 'Telefon',
      'email': 'Email',
      'phone_number': 'Nimero telefon',
      'password': 'Baatu jàll',
      'forgot_password': 'Fatte nga sa baatu jàll ?',
      'sign_in_btn': 'Dugg',
      'continue_google': 'Dugg ak Google',
      'continue_apple': 'Dugg ak Apple',
      'no_account': 'Amuloo kuru ba tay ?',
      'sign_up_link': 'Bindu',
      'category_all': 'Yépp',
      'category_electronics': 'Alal u mbëj',
      'category_fashion': 'Muurante',
      'category_home': 'Keur',
      'category_vehicles': 'Woto',
      'category_services': 'Liggéey',
    },
  };

  String translate(String key) {
    return _localizedValues[_currentLanguage]?[key] ??
           _localizedValues['fr']?[key] ??
           key;
  }
}
