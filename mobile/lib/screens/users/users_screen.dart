import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_locale.dart';
import '../../providers/user_provider.dart';
import '../../services/user_service.dart';
import '../../widgets/user_tile.dart';
import 'new_user_screen.dart';
import 'edit_user_screen.dart';
import '../../widgets/friendly_error_widget.dart';

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
        data: (list) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(usersProvider);
            // Optional delay for UI smoothness
            await Future.delayed(const Duration(milliseconds: 300));
          },
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
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
                onLongPress: () {
                  _showDeleteUserDialog(context, ref, list[i].id, list[i].firstName);
                },
              );
            },
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => FriendlyErrorWidget(
          error: err,
          onRetry: () => ref.invalidate(usersProvider),
        ),
      ),
    );
  }

  void _showDeleteUserDialog(BuildContext context, WidgetRef ref, String userId, String userName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.of(context, "deleteUser")),
        content: Text(
          "${S.of(context, "deleteUserConfirm")} \"$userName\"?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(S.of(context, "cancel")),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await UserService().deleteUser(userId);
                ref.invalidate(usersProvider);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(S.of(context, "userDeleted"))),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("${S.of(context, "error")}: $e")),
                  );
                }
              }
            },
            child: Text(S.of(context, "delete")),
          ),
        ],
      ),
    );
  }
}
