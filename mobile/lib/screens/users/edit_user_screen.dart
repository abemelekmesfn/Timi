import 'package:flutter/material.dart';

import '../../l10n/app_locale.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';

class EditUserScreen extends StatefulWidget {
  final UserModel user;

  const EditUserScreen({super.key, required this.user});

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  late final TextEditingController first;
  late final TextEditingController last;
  late final TextEditingController accessCode;
  
  late Set<String> roles;
  late bool isActive;

  @override
  void initState() {
    super.initState();
    first = TextEditingController(text: widget.user.firstName);
    last = TextEditingController(text: widget.user.lastName);
    accessCode = TextEditingController(text: widget.user.accessCode);
    roles = widget.user.roles.toSet();
    isActive = widget.user.isActive;
  }

  Future<void> save() async {
    try {
      await UserService().updateUser(
        id: widget.user.id,
        firstName: first.text,
        lastName: last.text,
        roles: roles.toList(),
        accessCode: accessCode.text,
        isActive: isActive,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context, "userUpdated"))),
      );
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
      appBar: AppBar(title: Text("${S.of(context, "edit")} ${widget.user.firstName}")),
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
            decoration: InputDecoration(labelText: S.of(context, "lastName")),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: accessCode,
            decoration: InputDecoration(labelText: S.of(context, "accessCode")),
          ),
          const SizedBox(height: 20),
          Text(S.of(context, "role")),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: [
              if (widget.user.roles.contains("owner"))
                ButtonSegment(value: "owner", label: Text(S.of(context, "owner"))),
              ButtonSegment(value: "warehouse", label: Text(S.of(context, "warehouse"))),
              ButtonSegment(value: "credit", label: Text(S.of(context, "credit"))),
            ],
            selected: roles,
            multiSelectionEnabled: true,
            emptySelectionAllowed: true,
            onSelectionChanged: widget.user.roles.contains("owner") 
                ? null 
                : (value) {
                    setState(() {
                      roles = value;
                    });
                  },
          ),
          const SizedBox(height: 20),
          SwitchListTile(
            title: Text(S.of(context, "activeAccount")),
            value: isActive,
            onChanged: widget.user.roles.contains("owner") 
                ? null 
                : (val) {
                    setState(() {
                      isActive = val;
                    });
                  },
          ),
          const SizedBox(height: 30),
          ElevatedButton(onPressed: save, child: Text(S.of(context, "updateUser"))),
        ],
      ),
    );
  }
}
