import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class DeliveryConfirmationWidget extends StatelessWidget {
  final Map<String, dynamic> partner;
  final VoidCallback onRateDelivery;
  final VoidCallback onClose;

  const DeliveryConfirmationWidget({
    super.key,
    required this.partner,
    required this.onRateDelivery,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40.0,
            height: 4.3,
            decoration: BoxDecoration(
              color: colorScheme.outline.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          SizedBox(height: 17.0),
          // Success header
          Container(
            padding: EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: Color(0xFF16A34A),
              size: 40,
            ),
          ),
          SizedBox(height: 12.8),
          Text(
            'Livreur Confirmé !',
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 4.3),
          Text(
            'Votre livreur a accepté la demande',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 21.3),
          // Partner info card
          Container(
            padding: EdgeInsets.all(14.0),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28.0,
                      backgroundImage: partner['profileImage'] != null
                          ? NetworkImage(partner['profileImage'])
                          : null,
                      backgroundColor: colorScheme.primaryContainer,
                      child: partner['profileImage'] == null
                          ? Icon(
                              Icons.person,
                              color: colorScheme.primary,
                              size: 28.0,
                            )
                          : null,
                    ),
                    SizedBox(width: 12.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            partner['name'] ?? '',
                            style: GoogleFonts.dmSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.star,
                                color: const Color(0xFFF59E0B),
                                size: 14.0,
                              ),
                              Text(
                                ' ${partner['rating']}',
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 17.0),
                // Contact info
                _buildInfoRow(
                  context,
                  Icons.phone_outlined,
                  'Téléphone',
                  partner['phone'] ?? '+221 XX XXX XX XX',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Appel vers ${partner['phone'] ?? 'livreur'}',
                        ),
                        backgroundColor: colorScheme.primary,
                      ),
                    );
                  },
                ),
                SizedBox(height: 8.5),
                _buildInfoRow(
                  context,
                  Icons.location_on_outlined,
                  'Position actuelle',
                  partner['currentLocation'] ?? 'En route vers vous',
                ),
                SizedBox(height: 8.5),
                _buildInfoRow(
                  context,
                  Icons.access_time,
                  'Arrivée estimée',
                  partner['estimatedTime'] ?? '15-20 min',
                ),
              ],
            ),
          ),
          SizedBox(height: 17.0),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onClose,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12.8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(
                      color: colorScheme.outline.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    'Fermer',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.0),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onRateDelivery,
                  icon: const Icon(Icons.star_outline, size: 18),
                  label: Text(
                    'Noter',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12.8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.5),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    VoidCallback? onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6.0),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16.0, color: colorScheme.primary),
          ),
          SizedBox(width: 10.0),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: onTap != null
                      ? colorScheme.primary
                      : colorScheme.onSurface,
                ),
              ),
            ],
          ),
          if (onTap != null) ...[
            const Spacer(),
            Icon(Icons.chevron_right, color: colorScheme.primary, size: 16.0),
          ],
        ],
      ),
    );
  }
}
