import 'package:flutter/material.dart';

class ButterflyCard extends StatelessWidget {
  final String name;
  final String scientificName;
  final String imageAsset;
  final String? description;

  const ButterflyCard({
    super.key,
    required this.name,
    required this.scientificName,
    required this.imageAsset,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Imagen de la mariposa
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 60,
              height: 60,
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
              child: imageAsset.isNotEmpty
                  ? Image.asset(
                      imageAsset,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.flutter_dash_outlined,
                          size: 30,
                          color: isDark ? Colors.white54 : Colors.black54,
                        );
                      },
                    )
                  : Icon(
                      Icons.flutter_dash_outlined,
                      size: 30,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
            ),
          ),

          const SizedBox(width: 16),

          // Información de la mariposa
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  scientificName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (description?.isNotEmpty == true) ...[
                  const SizedBox(height: 6),
                  Text(
                    description!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Icono de flecha
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
        ],
      ),
    );
  }
}
