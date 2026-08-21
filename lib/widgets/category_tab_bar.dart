import 'package:flutter/material.dart';

const _border = Color(0xFF3A3328);
const _surfaceHigh = Color(0xFF2C2820);
const _primary = Color(0xFFF0A500);
const _onPrimary = Color(0xFF1A1714);
const _muted = Color(0xFF9C8E7E);
const _onSurface = Color(0xFFF5EFE6);

/// A horizontal scrollable tab bar for filtering event categories.
class CategoryTabBar extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  static const categories = ['All', 'Exams', 'Submissions', 'Fests'];

  const CategoryTabBar({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: categories.map((cat) {
          final isSelected = cat == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelected(cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? _primary : _surfaceHigh,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? _primary : _border,
                  ),
                ),
                child: Text(
                  cat,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? _onPrimary : _muted,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
