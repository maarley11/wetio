import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../routes/app_routes.dart';
import 'auth_guard.dart';

import '../services/app_language_service.dart';

enum CustomBottomBarVariant { standard, floating, minimal }

class CustomBottomBar extends StatefulWidget {
  final CustomBottomBarVariant variant;
  final int currentIndex;
  final ValueChanged<int>? onTap;
  final Color? backgroundColor;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;
  final double? elevation;

  const CustomBottomBar({
    super.key,
    this.variant = CustomBottomBarVariant.standard,
    this.currentIndex = 0,
    this.onTap,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.elevation,
  });

  @override
  State<CustomBottomBar> createState() => _CustomBottomBarState();
}

class _CustomBottomBarState extends State<CustomBottomBar>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  List<_BottomBarItem> _getItems() {
    final lang = AppLanguageService.instance;
    return [
      _BottomBarItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        label: lang.translate('home'),
        route: AppRoutes.homeFeed,
      ),
      _BottomBarItem(
        icon: Icons.chat_bubble_outline,
        activeIcon: Icons.chat_bubble,
        label: lang.translate('chat'),
        route: AppRoutes.chatMessagesHub,
      ),
      _BottomBarItem(
        icon: Icons.add_circle_outline,
        activeIcon: Icons.add_circle,
        label: lang.translate('add'),
        route: AppRoutes.addProduct,
      ),
      _BottomBarItem(
        icon: Icons.local_shipping_outlined,
        activeIcon: Icons.local_shipping,
        label: lang.translate('courier'),
        route: AppRoutes.deliveryPartnerRegistrationSimplified,
        isHighlighted: false,
      ),
      _BottomBarItem(
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: lang.translate('profile'),
        route: AppRoutes.userProfile,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: AppLanguageService.instance,
      builder: (context, _) {
        switch (widget.variant) {
          case CustomBottomBarVariant.standard:
            return _buildStandardBottomBar(context, theme, colorScheme);
          case CustomBottomBarVariant.floating:
            return _buildFloatingBottomBar(context, theme, colorScheme);
          case CustomBottomBarVariant.minimal:
            return _buildMinimalBottomBar(context, theme, colorScheme);
        }
      },
    );
  }

  Widget _buildStandardBottomBar(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _getItems().asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = index == widget.currentIndex;
              final isHighlighted = item.isHighlighted;

              return Expanded(
                child: GestureDetector(
                  onTap: () => _onItemTapped(index, item.route),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: null,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            isSelected ? item.activeIcon : item.icon,
                            key: ValueKey(isSelected),
                            color: isSelected
                                ? (widget.selectedItemColor ??
                                    colorScheme.primary)
                                : (widget.unselectedItemColor ??
                                    colorScheme.onSurfaceVariant),
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected
                                ? (widget.selectedItemColor ??
                                    colorScheme.primary)
                                : (widget.unselectedItemColor ??
                                    colorScheme.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingBottomBar(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? colorScheme.surface,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _getItems().asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isSelected = index == widget.currentIndex;
            final isHighlighted = item.isHighlighted;

            return Expanded(
              child: GestureDetector(
                onTap: () => _onItemTapped(index, item.route),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (widget.selectedItemColor ?? colorScheme.primary)
                            .withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          isSelected ? item.activeIcon : item.icon,
                          key: ValueKey(isSelected),
                          color: isSelected
                              ? (widget.selectedItemColor ??
                                  colorScheme.primary)
                              : (widget.unselectedItemColor ??
                                  colorScheme.onSurfaceVariant),
                          size: 20,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.label,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: (widget.selectedItemColor ??
                                colorScheme.primary),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMinimalBottomBar(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      height: 50,
      color: widget.backgroundColor ?? colorScheme.surface,
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _getItems().asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isSelected = index == widget.currentIndex;
            final isHighlighted = item.isHighlighted;

            return GestureDetector(
              onTap: () => _onItemTapped(index, item.route),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(8),
                decoration: null,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isSelected ? item.activeIcon : item.icon,
                    key: ValueKey(isSelected),
                    color: isSelected
                        ? (widget.selectedItemColor ?? colorScheme.primary)
                        : (widget.unselectedItemColor ??
                            colorScheme.onSurfaceVariant),
                    size: 24,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _onItemTapped(int index, String route) {
    HapticFeedback.lightImpact();

    if (widget.onTap != null) {
      widget.onTap!(index);
    }

    // Routes that require authentication
    const authRequiredRoutes = {
      AppRoutes.chatMessagesHub,
      AppRoutes.addProduct,
      AppRoutes.deliveryPartnerRegistrationSimplified,
    };

    if (authRequiredRoutes.contains(route)) {
      requireAuth(context, () {
        if (ModalRoute.of(context)?.settings.name != route) {
          Navigator.pushNamedAndRemoveUntil(context, route, (r) => false);
        }
      });
    } else {
      // Navigate to the corresponding route
      if (ModalRoute.of(context)?.settings.name != route) {
        Navigator.pushNamedAndRemoveUntil(context, route, (route) => false);
      }
    }
  }

  void _showAuthRequiredDialog(String targetRoute) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.lock_outline, color: colorScheme.primary, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Connexion requise',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Vous devez être connecté pour effectuer cette action.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Annuler',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomBarItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
  final bool isHighlighted;

  const _BottomBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
    this.isHighlighted = false,
  });
}
