import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class DeliveryPartnerCardWidget extends StatelessWidget {
  final Map<String, dynamic> partner;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onRequestDelivery;

  const DeliveryPartnerCardWidget({
    super.key,
    required this.partner,
    required this.isSelected,
    required this.onSelect,
    required this.onRequestDelivery,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final rating = (partner['rating'] as num?)?.toDouble() ?? 0.0;

    return GestureDetector(
      onTap: onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.8),
        padding: EdgeInsets.all(14.0),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.06)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24.0,
                  backgroundImage: partner['profileImage'] != null
                      ? NetworkImage(partner['profileImage'])
                      : null,
                  backgroundColor: colorScheme.primaryContainer,
                  child: partner['profileImage'] == null
                      ? Icon(
                          Icons.person,
                          color: colorScheme.primary,
                          size: 24.0,
                        )
                      : null,
                ),
                SizedBox(width: 12.0),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              partner['name'] ?? '',
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Badge disponible
                          if (partner['isAvailable'] == true)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.0,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF22C55E,
                                ).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Disponible',
                                style: GoogleFonts.dmSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF16A34A),
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 3.4),
                      Row(
                        children: [
                          // Stars
                          Row(
                            children: List.generate(5, (i) {
                              return Icon(
                                i < rating.floor()
                                    ? Icons.star
                                    : (i < rating
                                        ? Icons.star_half
                                        : Icons.star_outline),
                                color: const Color(0xFFF59E0B),
                                size: 14.0,
                              );
                            }),
                          ),
                          SizedBox(width: 4.0),
                          Text(
                            '$rating (${partner['reviewCount']})',
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 3.4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14.0,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          Text(
                            '${partner['distance']} km',
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          SizedBox(width: 12.0),
                          Icon(
                            Icons.access_time,
                            size: 14.0,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          Text(
                            ' ${partner['estimatedTime']}',
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Price
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${partner['basePrice']} F',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                      ),
                    ),
                    Text(
                      'CFA',
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (isSelected) ...[
              SizedBox(height: 17.0),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onRequestDelivery,
                  icon: const Icon(Icons.local_shipping, size: 18),
                  label: Text(
                    'Demander livraison',
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
          ],
        ),
      ),
    );
  }
}
