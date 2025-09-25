// lib/core/utils/snackbar_utils.dart

import 'package:flutter/material.dart';

// An enum to define the type of feedback for better code readability.
enum FeedbackType { success, error, info }

/// Shows a standardized SnackBar with a black background and white text.
///
/// [type] determines the icon and its color (green for success, red for error).
void showFeedbackSnackbar(
  BuildContext context,
  String message, {
  FeedbackType type = FeedbackType.info,
}) {
  if (!context.mounted) return;

  ScaffoldMessenger.of(context).hideCurrentSnackBar();

  // Determine the icon and color based on the feedback type.
  final IconData iconData;
  final Color iconColor;

  switch (type) {
    case FeedbackType.success:
      iconData = Icons.check_circle_outline;
      iconColor = Colors.green;
      break;
    case FeedbackType.error:
      iconData = Icons.error_outline;
      iconColor = Colors.red;
      break;
    case FeedbackType.info:
      iconData = Icons.info_outline;
      iconColor = Colors.white70;
      break;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      // THEME UPDATE: Always use a black background.
      backgroundColor: Colors.black,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      content: Row(
        children: [
          Icon(iconData, color: iconColor),
          const SizedBox(width: 12),
          // THEME UPDATE: Ensure text is always white.
          Expanded(
            child: Text(message, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ),
  );
}
