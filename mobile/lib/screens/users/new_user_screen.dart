import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/app_locale.dart';
import '../../services/user_service.dart';

class NewUserScreen extends StatefulWidget {
  const NewUserScreen({super.key});

  @override
  State<NewUserScreen> createState() => _NewUserScreenState();
}

class _NewUserScreenState extends State<NewUserScreen> {
  final first = TextEditingController();
  final last = TextEditingController();
  final accessCode = TextEditingController();

  Set<String> roles = {"warehouse"};

  Future<void> save() async {
    try {
      final user = await UserService().createUser(
        firstName: first.text,
        lastName: last.text,
        roles: roles.toList(),
        accessCode: accessCode.text,
      );

      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: Text(S.of(context, "userCreated")),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                user.fullName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(S.of(context, "accessCode")),
              const SizedBox(height: 8),
              SelectableText(
                user.accessCode,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                S.of(context, "giveCode"),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(S.of(context, "done")),
            ),
          ],
        ),
      );

      if (!mounted) return;

      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${S.of(context, "error")}: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context, "newEmployee"))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: first,
            decoration: InputDecoration(labelText: S.of(context, "firstName")),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: last,
            decoration: InputDecoration(
              labelText: "${S.of(context, "lastName")} (${S.of(context, "optional")})",
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: accessCode,
            decoration: InputDecoration(
              labelText: S.of(context, "accessCodeManual"),
            ),
          ),
          const SizedBox(height: 20),
          Text(S.of(context, "role")),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: "warehouse", label: Text(S.of(context, "warehouse"))),
              ButtonSegment(value: "credit", label: Text(S.of(context, "credit"))),
            ],
            selected: roles,
            multiSelectionEnabled: true,
            emptySelectionAllowed: true,
            onSelectionChanged: (value) {
              setState(() {
                roles = value;
              });
            },
          ),
          const SizedBox(height: 30),
          ElevatedButton(onPressed: save, child: Text(S.of(context, "createUser"))),
        ],
      ),
    );
  }
}
