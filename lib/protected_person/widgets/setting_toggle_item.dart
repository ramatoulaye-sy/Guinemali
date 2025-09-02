import 'package:flutter/material.dart';

/// Widget pour un élément de paramètre avec toggle
class SettingToggleItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData? icon;
  final Color? activeColor;

  const SettingToggleItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.icon,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: activeColor ?? Colors.red.shade600,
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      secondary: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: activeColor ?? Colors.red.shade600,
      ),
    );
  }
}
