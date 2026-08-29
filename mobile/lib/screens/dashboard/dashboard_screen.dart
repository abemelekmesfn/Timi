import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/app_locale.dart';
import '../../l10n/language_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/credit_provider.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/summary_card.dart';
import '../inventory/inventory_screen.dart';
import '../credits/credit_screen.dart';
import '../notebook/notebook_screen.dart';
import '../users/users_screen.dart';
import '../settings/settings_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final locale = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: user.when(
        data: (u) => SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
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
                    const SizedBox(width: 4),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Consumer(builder: (context, ref, child) {
                  final totalCredit = ref.watch(totalCreditProvider);
                  return totalCredit.when(
                    data: (total) => SummaryCard(
                      title: S.of(context, "totalCredit"),
                      value: "${total.toStringAsFixed(2)} ETB",
                    ),
                    loading: () => SummaryCard(
                      title: S.of(context, "totalCredit"),
                      value: S.of(context, "loading"),
                    ),
                    error: (_, __) => SummaryCard(
                      title: S.of(context, "totalCredit"),
                      value: S.of(context, "error"),
                    ),
                  );
                }),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    children: [
                      if (u.roles.contains("owner") || u.roles.contains("warehouse"))
                        DashboardCard(
                          icon: Icons.warehouse,
                          title: S.of(context, "warehouse"),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const InventoryScreen(),
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
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(S.of(context, "error"))),
      ),
    );
  }
}
