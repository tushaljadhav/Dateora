import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });

  static const List<CategoryModel> presetCategories = [
    CategoryModel(id: 'groceries', name: 'Groceries', icon: Icons.local_grocery_store_outlined, color: Color(0xFF10B981)),
    CategoryModel(id: 'medicine', name: 'Medicine', icon: Icons.medical_services_outlined, color: Color(0xFFEF4444)),
    CategoryModel(id: 'skincare', name: 'Skincare', icon: Icons.spa_outlined, color: Color(0xFFEC4899)),
    CategoryModel(id: 'dairy', name: 'Dairy & Eggs', icon: Icons.egg_outlined, color: Color(0xFFF59E0B)),
    CategoryModel(id: 'household', name: 'Household', icon: Icons.home_outlined, color: Color(0xFF8B5CF6)),
    CategoryModel(id: 'documents', name: 'Documents', icon: Icons.description_outlined, color: Color(0xFF3B82F6)),
    CategoryModel(id: 'beverages', name: 'Beverages', icon: Icons.coffee_outlined, color: Color(0xFF06B6D4)),
    CategoryModel(id: 'pantry', name: 'Pantry', icon: Icons.kitchen_outlined, color: Color(0xFFF97316)),
    CategoryModel(id: 'custom', name: 'Custom', icon: Icons.label_outline, color: Color(0xFF64748B)),
  ];

  static CategoryModel getById(String id) {
    return presetCategories.firstWhere(
      (c) => c.id == id,
      orElse: () => const CategoryModel(
        id: 'custom',
        name: 'Custom',
        icon: Icons.label_outline,
        color: Color(0xFF64748B),
      ),
    );
  }
}
