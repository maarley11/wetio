import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ProductTypeToggleWidget extends StatelessWidget {
  final bool isWantedProduct;
  final Function(bool) onToggle;

  const ProductTypeToggleWidget({
    super.key,
    required this.isWantedProduct,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    // Auto-select AMNA LI (not wanted) on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isWantedProduct) {
        onToggle(false);
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Type de produit',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 17.0),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color:
                AppTheme.lightTheme.colorScheme.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.lightTheme.colorScheme.outline
                  .withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(vertical: 17.0, horizontal: 16.0),
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.lightTheme.colorScheme.shadow
                            .withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      CustomIconWidget(
                        iconName: 'inventory_2',
                        color: Colors.white,
                        size: 24,
                      ),
                      SizedBox(height: 8.5),
                      Text(
                        'AMNA LI',
                        textAlign: TextAlign.center,
                        style:
                            AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4.3),
                      Text(
                        'J\'ai ce produit',
                        textAlign: TextAlign.center,
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
