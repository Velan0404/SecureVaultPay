import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Shows a themed floating snackbar for API/error feedback, replacing plain
/// inline error text with a consistent, dismissable surface.
void showAppSnackBar(BuildContext context, String message, {bool isError = true}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: isError ? AppColors.accentCrimson : Colors.greenAccent,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}
