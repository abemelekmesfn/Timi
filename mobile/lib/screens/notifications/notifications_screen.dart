import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/app_locale.dart';
import '../../l10n/language_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/friendly_error_widget.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  
  @override
  void initState() {
    super.initState();
    _markAsRead();
  }

  Future<void> _markAsRead() async {
    try {
      await ref.read(notificationServiceProvider).markAsRead();
      ref.invalidate(notificationsProvider);
    } catch (e) {
      // Ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(notificationsProvider);
    final locale = ref.watch(languageProvider);
    final isAm = locale.languageCode == "am";

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context, "notifications")),
      ),
      body: notifications.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(child: Text(S.of(context, "noNotifications")));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final notification = items[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: notification.isRead ? AppColors.white : AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: notification.isRead ? AppColors.border : AppColors.primary.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAm ? notification.messageAm : notification.messageEn,
                      style: const TextStyle(fontSize: 15),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      notification.createdAt,
                      style: const TextStyle(color: AppColors.warmGrey, fontSize: 12),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => FriendlyErrorWidget(
          error: err,
          onRetry: () => ref.invalidate(notificationServiceProvider),
        ),
      ),
    );
  }
}
