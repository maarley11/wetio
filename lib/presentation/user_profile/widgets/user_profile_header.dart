import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/supabase_service.dart';

import '../../../services/app_language_service.dart';

class UserProfileHeader extends StatelessWidget {
  final Map<String, dynamic> userData;

  const UserProfileHeader({
    Key? key,
    required this.userData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final lang = AppLanguageService.instance;

    return AnimatedBuilder(
      animation: lang,
      builder: (context, _) {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primaryContainer,
                colorScheme.secondaryContainer,
              ],
            ),
          ),
          child: Column(
            children: [
              // Profile Photo
              Container(
                width: 120.0,
                height: 120.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.primary,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: userData['avatar'] != null &&
                          userData['avatar'].toString().isNotEmpty
                      ? CustomImageWidget(
                          imageUrl: userData['avatar'],
                          width: 120.0,
                          height: 120.0,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: colorScheme.primaryContainer,
                          child: Center(
                            child: CustomIconWidget(
                              iconName: 'person',
                              color: colorScheme.primary,
                              size: 60.0,
                            ),
                          ),
                        ),
                ),
              ),

              SizedBox(height: 17.0),

              // User Name
              Text(
                userData['name'] ?? 'Utilisateur',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),

              // Username/Pseudo
              if (userData['pseudo'] != null &&
                  userData['pseudo'].toString().isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 4.3),
                  child: Text(
                    '@${userData['pseudo']}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

              // Location
              if (userData['location'] != null &&
                  userData['location'].toString().isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 4.3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomIconWidget(
                        iconName: 'location_on',
                        color: colorScheme.onSurfaceVariant,
                        size: 16.0,
                      ),
                      SizedBox(width: 4.3),
                      Text(
                        userData['location'],
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

              SizedBox(height: 17.0),

              // Stats Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: _buildStatItem(
                      context,
                      lang.translate('exchanges'),
                      '${userData['exchangeCount'] ?? 0}',
                      'swap_horiz',
                      colorScheme,
                    ),
                  ),
                  Container(
                    height: 51.0,
                    width: 1,
                    color: colorScheme.outline.withValues(alpha: 0.3),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      context,
                      lang.translate('rating'),
                      '${userData['rating'] ?? 0.0}',
                      'star',
                      colorScheme,
                    ),
                  ),
                  Container(
                    height: 51.0,
                    width: 1,
                    color: colorScheme.outline.withValues(alpha: 0.3),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      context,
                      lang.translate('member_since'),
                      userData['memberSince'] ?? DateTime.now().year.toString(),
                      'calendar_today',
                      colorScheme,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    String iconName,
    ColorScheme colorScheme,
  ) {
    final theme = Theme.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CustomIconWidget(
          iconName: iconName,
          color: colorScheme.primary,
          size: 24.0,
        ),
        SizedBox(height: 8.5),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
