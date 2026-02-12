import 'package:flutter/material.dart';
import '../models/class_item.dart';
import '../utils/constants.dart';

class ClassCard extends StatelessWidget {
  final ClassItem classItem;
  final VoidCallback onTap;

  const ClassCard({
    super.key,
    required this.classItem,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Ensure the color index is within bounds
    final color = AppColors.predefinedColors[classItem.colorIndex % AppColors.predefinedColors.length];
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4.0), // reduced margin
        padding: const EdgeInsets.all(8.0), // reduced padding
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              classItem.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14.0,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${classItem.startTime} - ${classItem.endTime}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12.0,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
