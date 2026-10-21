import 'package:flutter/material.dart';
import '../models/category_model.dart';

class CategoryBadge extends StatelessWidget {
  final String categoryId;
  final double size;

  const CategoryBadge({
    super.key,
    required this.categoryId,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final cat = CategoryModel.getById(categoryId);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: cat.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Center(
        child: Icon(cat.icon, size: size * 0.52, color: cat.color),
      ),
    );
  }
}
