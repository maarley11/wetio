import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class UserProfileSection extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback? onViewProfile;

  const UserProfileSection({
    super.key,
    required this.user,
    this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 100.w,
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // User avatar
          Container(
            width: 48.0,
            height: 48.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: ClipOval(
              child: CustomImageWidget(
                imageUrl: (user["avatar"] as String? ??
                    "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png"),
                width: 48.0,
                height: 48.0,
                fit: BoxFit.cover,
              ),
            ),
          ),

          SizedBox(width: 12.0),

          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (user["name"] as String? ?? "Utilisateur"),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 4.3),
                Row(
                  children: [
                    // Rating stars
                    Row(
                      children: List.generate(5, (index) {
                        final rating = (user["rating"] as double? ?? 4.5);
                        return CustomIconWidget(
                          iconName:
                              index < rating.floor() ? 'star' : 'star_border',
                          color: AppTheme.warningOrange,
                          size: 16,
                        );
                      }),
                    ),
                    SizedBox(width: 8.0),
                    Text(
                      "${user["rating"] ?? 4.5} • ${user["reviewCount"] ?? 23} avis",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // View profile button
          GestureDetector(
            onTap: onViewProfile ??
                () {
                  Navigator.pushNamed(context, '/user-profile');
                },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 17.0),
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppTheme.lightTheme.colorScheme.primary,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "Voir profil",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.lightTheme.colorScheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
