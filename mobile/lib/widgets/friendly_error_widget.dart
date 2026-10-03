import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// A user-friendly error widget that shows a lock icon for permission errors,
/// and a generic error icon for other errors.
class FriendlyErrorWidget extends StatelessWidget {
  final Object error;
  final VoidCallback? onRetry;

  const FriendlyErrorWidget({
    super.key,
    required this.error,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final errMsg = error.toString();
    final isPermError = errMsg.contains("403") ||
        errMsg.toLowerCase().contains("permission") ||
        errMsg.toLowerCase().contains("access denied") ||
        errMsg.toLowerCase().contains("unauthorized");

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPermError ? Icons.lock_outline : Icons.cloud_off_rounded,
              color: isPermError ? AppColors.warmGrey : AppColors.danger,
              size: 52,
            ),
            const SizedBox(height: 16),
            Text(
              isPermError
                  ? "You don't have permission to access this."
                  : "Something went wrong.",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isPermError
                  ? "Ask the admin to grant you access."
                  : errMsg,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.warmGrey,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text("Retry"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
