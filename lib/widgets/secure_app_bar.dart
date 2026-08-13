import 'package:flutter/material.dart';

/// Consistent app bar with security-themed branding.
class SecureAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final bool showSecurityIcon;

  const SecureAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = true,
    this.showSecurityIcon = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: showBackButton,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showSecurityIcon) ...[
            Icon(
              Icons.verified_user_rounded,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
          ],
          Text(title),
        ],
      ),
      actions: actions,
    );
  }
}
