import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_locale.dart';
import '../../l10n/language_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/storage/auth_storage.dart';
import '../../core/theme/app_colors.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(languageProvider);
    final user = ref.watch(userProvider);

    return Scaffold(
      appBar: AppBar(title: Text(S.of(context, "settings"))),

      body: ListView(
        children: [
          const SizedBox(height: 10),

          user.when(
            data: (u) => ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(u.fullName),
              subtitle: Text(
                u.roles.map((r) => S.of(context, r)).join(', ').toUpperCase(),
              ),
            ),
            loading: () => ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(S.of(context, "loading")),
            ),
            error: (_, __) => ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(S.of(context, "appName")),
            ),
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.language),
            title: Text(S.of(context, "language")),
            subtitle: Text(locale.languageCode == "am" ? "አማርኛ" : "English"),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: "am", label: Text("አማርኛ")),
                ButtonSegment(value: "en", label: Text("English")),
              ],
              selected: {locale.languageCode},
              onSelectionChanged: (value) {
                ref.read(languageProvider.notifier).change(value.first);
              },
            ),
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(S.of(context, "version")),
            subtitle: const Text("TIMI v1.0.0"),
          ),

          const SizedBox(height: 30),

          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              icon: const Icon(Icons.logout),
              label: Text(S.of(context, "logout")),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.danger,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                await AuthStorage().logout();

                if (!context.mounted) return;

                ref.invalidate(userProvider);
                context.go("/login");
              },
            ),
          ),
        ],
      ),
    );
  }
}
