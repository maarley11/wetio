import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import 'auth_guard.dart';

/// Widget de navigation adaptive:
/// - Sur mobile (< 700px): barre de navigation en bas (standard)
/// - Sur tablette/desktop (>= 700px): menu latéral fixe à gauche
class AdaptiveScaffold extends StatelessWidget {
  final Widget body;
  final int currentIndex;
  final Widget? floatingActionButton;
  final PreferredSizeWidget? appBar;

  const AdaptiveScaffold({
    super.key,
    required this.body,
    required this.currentIndex,
    this.floatingActionButton,
    this.appBar,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 700;

    if (isDesktop) {
      return Scaffold(
        appBar: appBar,
        backgroundColor: const Color(0xFFF4F6F8),
        body: Row(
          children: [
            _DesktopSideNav(currentIndex: currentIndex),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: body),
          ],
        ),
        floatingActionButton: floatingActionButton,
      );
    }

    // Mobile layout
    return Scaffold(
      appBar: appBar,
      body: body,
      bottomNavigationBar: _MobileBottomBar(currentIndex: currentIndex),
      floatingActionButton: floatingActionButton,
    );
  }
}

class _DesktopSideNav extends StatelessWidget {
  final int currentIndex;

  const _DesktopSideNav({required this.currentIndex});

  static const _items = [
    _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Accueil', route: AppRoutes.homeFeed),
    _NavItem(icon: Icons.chat_bubble_outline, activeIcon: Icons.chat_bubble, label: 'Messages', route: AppRoutes.chatMessagesHub, requiresAuth: true),
    _NavItem(icon: Icons.add_circle_outline, activeIcon: Icons.add_circle, label: 'Publier', route: AppRoutes.addProduct, requiresAuth: true),
    _NavItem(icon: Icons.local_shipping_outlined, activeIcon: Icons.local_shipping, label: 'Livreur', route: AppRoutes.deliveryPartnerRegistrationSimplified, requiresAuth: true),
    _NavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profil', route: AppRoutes.userProfile),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.swap_horiz, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'WETIO',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryGreen,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),

            // Nav items
            ..._items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = index == currentIndex;

              return _SideNavItem(
                item: item,
                isSelected: isSelected,
              );
            }),

            const Spacer(),

            // Bottom hint
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                '© 2025 Wetio',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.grey.shade400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SideNavItem extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;

  const _SideNavItem({required this.item, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          HapticFeedback.lightImpact();
          if (item.requiresAuth) {
            requireAuth(context, () {
              if (ModalRoute.of(context)?.settings.name != item.route) {
                Navigator.pushNamedAndRemoveUntil(context, item.route, (r) => false);
              }
            });
          } else {
            if (ModalRoute.of(context)?.settings.name != item.route) {
              Navigator.pushNamedAndRemoveUntil(context, item.route, (r) => false);
            }
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryGreen.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? item.activeIcon : item.icon,
                color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade500,
                size: 22,
              ),
              const SizedBox(width: 12),
              Text(
                item.label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade700,
                ),
              ),
              if (isSelected) ...[
                const Spacer(),
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileBottomBar extends StatelessWidget {
  final int currentIndex;

  const _MobileBottomBar({required this.currentIndex});

  static const _items = [
    _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Accueil', route: AppRoutes.homeFeed),
    _NavItem(icon: Icons.chat_bubble_outline, activeIcon: Icons.chat_bubble, label: 'Chat', route: AppRoutes.chatMessagesHub, requiresAuth: true),
    _NavItem(icon: Icons.add_circle_outline, activeIcon: Icons.add_circle, label: 'Ajouter', route: AppRoutes.addProduct, requiresAuth: true),
    _NavItem(icon: Icons.local_shipping_outlined, activeIcon: Icons.local_shipping, label: 'Livreur', route: AppRoutes.deliveryPartnerRegistrationSimplified, requiresAuth: true),
    _NavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profil', route: AppRoutes.userProfile),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = index == currentIndex;

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    if (item.requiresAuth) {
                      requireAuth(context, () {
                        if (ModalRoute.of(context)?.settings.name != item.route) {
                          Navigator.pushNamedAndRemoveUntil(context, item.route, (r) => false);
                        }
                      });
                    } else {
                      if (ModalRoute.of(context)?.settings.name != item.route) {
                        Navigator.pushNamedAndRemoveUntil(context, item.route, (r) => false);
                      }
                    }
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isSelected ? item.activeIcon : item.icon,
                        color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
  final bool requiresAuth;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
    this.requiresAuth = false,
  });
}
