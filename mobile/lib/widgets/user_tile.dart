import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/user_model.dart';

class UserTile extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;

  const UserTile({super.key, required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    if (user.roles.contains("owner")) {
      icon = Icons.admin_panel_settings;
      color = AppColors.primary;
    } else if (user.roles.contains("credit")) {
      icon = Icons.account_balance_wallet;
      color = Colors.green;
    } else {
      icon = Icons.warehouse;
      color = Colors.orange;
    }

    return Card(
      elevation: 0,
      color: AppColors.white,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withAlpha(25),
          foregroundColor: color,
          child: Icon(icon),
        ),
        title: Text(
          user.fullName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            user.roles.join(', ').toUpperCase(),
            style: TextStyle(
              color: user.isActive ? AppColors.warmGrey : Colors.red,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.warmGrey, size: 20),
      ),
    );
  }
}
