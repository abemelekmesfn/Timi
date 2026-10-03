import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/app_locale.dart';
import '../../l10n/language_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/credit_provider.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/summary_card.dart';
import '../inventory/warehouses_screen.dart';
import '../credits/credit_screen.dart';
import '../notebook/notebook_screen.dart';
import '../users/users_screen.dart';
import '../settings/settings_screen.dart';
import '../cart/cart_screen.dart';
import '../notifications/notifications_screen.dart';
import '../../providers/cart_provider.dart';
import '../../providers/notification_provider.dart';
import '../../services/notification_service.dart';
import 'admin_reports_screen.dart';
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final locale = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: user.when(
        data: (u) {
          if (u.roles.contains("owner")) {
            NotificationService.initialize().then((_) {
              NotificationService.requestPermission();
              // Check unread and show local notification
              ref.read(notificationServiceProvider).getNotifications().then((notifs) {
                final unread = notifs.where((n) => !n.isRead).toList();
                if (unread.isNotEmpty) {
                  final latest = unread.first;
                  final isAm = ref.read(languageProvider).languageCode == "am";
                  NotificationService.showNotification(
                    title: isAm ? "አዲስ የቲሚ ማሳወቂያ" : "New TIMI Notification",
                    body: isAm ? latest.messageAm : latest.messageEn,
                  );
                }
              });
            });
          }

          return SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.primary.withAlpha(18),
                      child: const Icon(Icons.person, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            S.of(context, "welcome"),
                            style: const TextStyle(color: AppColors.warmGrey, fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            u.fullName,
                            style: const TextStyle(
                              color: AppColors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Language toggle chip
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          final newCode =
                              locale.languageCode == "am" ? "en" : "am";
                          ref.read(languageProvider.notifier).change(newCode);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.language,
                                color: AppColors.primary,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                locale.languageCode == "am" ? "EN" : "አማ",
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Cart Icon with Badge
                    Consumer(
                      builder: (context, ref, child) {
                        final cartAsync = ref.watch(cartProvider);
                        final cartItems = cartAsync.valueOrNull ?? [];
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.primary.withAlpha(18),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.shopping_cart, color: AppColors.primary, size: 20),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const CartScreen()),
                                  );
                                },
                              ),
                            ),
                            if (cartItems.isNotEmpty)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${cartItems.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    // Notification Icon (Admin only)
                    if (u.roles.contains("owner")) ...[
                      const SizedBox(width: 8),
                      Consumer(
                        builder: (context, ref, child) {
                          final notifications = ref.watch(notificationsProvider).valueOrNull ?? [];
                          final unreadCount = notifications.where((n) => !n.isRead).length;

                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withAlpha(18),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.notifications, color: AppColors.primary, size: 20),
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                                    );
                                    ref.invalidate(notificationsProvider);
                                  },
                                ),
                              ),
                              if (unreadCount > 0)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '$unreadCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                    const SizedBox(width: 4),
                  ],
                ),
              ),



              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(userProvider);
                    ref.invalidate(notificationServiceProvider);
                    ref.invalidate(cartProvider);
                    await Future.delayed(const Duration(milliseconds: 300));
                  },
                  child: GridView.count(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    children: [
                      if (u.roles.contains("owner") || (u.permissions["can_view_reports"] == true))
                        DashboardCard(
                          icon: Icons.bar_chart,
                          title: S.of(context, "reports"),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AdminReportsScreen(),
                              ),
                            );
                          },
                        ),
                        
                      if (u.roles.contains("owner") || u.roles.contains("warehouse"))
                        DashboardCard(
                          icon: Icons.warehouse,
                          title: S.of(context, "warehouse"),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const WarehousesScreen(),
                              ),
                            );
                          },
                        ),

                      if (u.roles.contains("owner") || u.roles.contains("credit"))
                        DashboardCard(
                          icon: Icons.account_balance_wallet,
                          title: S.of(context, "credit"),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CreditScreen(),
                              ),
                            );
                          },
                        ),

                      DashboardCard(
                        icon: Icons.note_alt,
                        title: S.of(context, "notebook"),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotebookScreen(),
                            ),
                          );
                        },
                      ),

                      if (u.roles.contains("owner"))
                        DashboardCard(
                          icon: Icons.people,
                          title: S.of(context, "users"),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const UsersScreen(),
                              ),
                            );
                          },
                        ),

                      DashboardCard(
                        icon: Icons.settings,
                        title: S.of(context, "settings"),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SettingsScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(S.of(context, "error"))),
      ),
    );
  }
}
