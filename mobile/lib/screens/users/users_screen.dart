import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_locale.dart';
import '../../providers/user_provider.dart';
import '../../widgets/user_tile.dart';
import 'new_user_screen.dart';
import 'edit_user_screen.dart';

class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(usersProvider);

    return Scaffold(
      appBar: AppBar(title: Text(S.of(context, "users"))),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.person_add),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NewUserScreen()),
          );

          ref.invalidate(usersProvider);
        },
      ),
      body: users.when(
        data: (list) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (_, i) {
            return UserTile(
              user: list[i],
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditUserScreen(user: list[i]),
                  ),
                );
                ref.invalidate(usersProvider);
              },
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(S.of(context, "error"))),
      ),
    );
  }
}
