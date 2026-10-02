import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_locale.dart';
import '../../providers/warehouse_provider.dart';
import '../../services/user_service.dart';

class NewUserScreen extends ConsumerStatefulWidget {
  const NewUserScreen({super.key});

  @override
  ConsumerState<NewUserScreen> createState() => _NewUserScreenState();
}

class _NewUserScreenState extends ConsumerState<NewUserScreen> {
  final first = TextEditingController();
  final last = TextEditingController();
  final accessCode = TextEditingController();

  bool isOwner = false;

  // Permissions
  List<String> allowedWarehouses = [];
  bool canTransfer = false;
  bool canViewHistory = false;
  bool canViewDashboard = false;
  bool canManageDesigns = false;
  bool canManageCredits = false;
  bool canMoveOut = false;
  bool canImport = false;

  Future<void> save() async {
    if (first.text.isEmpty || accessCode.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context, "fillRequiredFields"))),
      );
      return;
    }

    try {
      final permissions = {
        "warehouses": allowedWarehouses,
        "can_transfer": canTransfer,
        "can_view_history": canViewHistory,
        "can_view_dashboard": canViewDashboard,
        "can_manage_designs": canManageDesigns,
        "can_manage_credits": canManageCredits,
        "can_move_out": canMoveOut,
        "can_import": canImport,
      };

      await UserService().createUser(
        firstName: first.text,
        lastName: last.text,
        roles: isOwner ? ["owner"] : [],
        permissions: permissions,
        accessCode: accessCode.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context, "userCreated"))),
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
    final warehousesAsync = ref.watch(warehousesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(S.of(context, "newUser"))),
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

          SwitchListTile(
            title: const Text("Is Admin (Owner)"),
            subtitle: const Text("Gives full access to all features"),
            value: isOwner,
            onChanged: (val) {
              setState(() {
                isOwner = val;
              });
            },
          ),
          
          if (!isOwner) ...[
            const Divider(height: 40),
            const Text("Permissions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            SwitchListTile(title: const Text("Can View Dashboard"), value: canViewDashboard, onChanged: (v) => setState(() => canViewDashboard = v)),
            SwitchListTile(title: const Text("Can Move Out Items"), value: canMoveOut, onChanged: (v) => setState(() => canMoveOut = v)),
            SwitchListTile(title: const Text("Can Transfer Warehouses"), value: canTransfer, onChanged: (v) => setState(() => canTransfer = v)),
            SwitchListTile(title: const Text("Can View History"), value: canViewHistory, onChanged: (v) => setState(() => canViewHistory = v)),
            SwitchListTile(title: const Text("Can Manage Designs"), value: canManageDesigns, onChanged: (v) => setState(() => canManageDesigns = v)),
            SwitchListTile(title: const Text("Can Manage Credits"), value: canManageCredits, onChanged: (v) => setState(() => canManageCredits = v)),
            SwitchListTile(title: const Text("Can Import Excel/Bulk"), value: canImport, onChanged: (v) => setState(() => canImport = v)),

            const Divider(height: 40),
            const Text("Warehouse Access", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            
            warehousesAsync.when(
              data: (warehouses) {
                if (warehouses.isEmpty) return const Text("No warehouses found.");
                return Column(
                  children: warehouses.map((w) {
                    return CheckboxListTile(
                      title: Text(w.name),
                      value: allowedWarehouses.contains(w.id),
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            allowedWarehouses.add(w.id);
                          } else {
                            allowedWarehouses.remove(w.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (err, stack) => Text("Error loading warehouses: $err"),
            ),
          ],

          const SizedBox(height: 30),
          ElevatedButton(onPressed: save, child: Text(S.of(context, "register"))),
        ],
      ),
    );
  }
}
