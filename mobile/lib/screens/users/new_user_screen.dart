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
  bool hasCreditAccess = false;
  bool canTransfer = false;
  bool canViewWarehouseHistory = false;
  bool canViewCreditHistory = false;
  bool canViewReports = false;
  bool canManageDesigns = false;
  bool canManageDesignNames = false;
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
        "can_view_warehouse_history": canViewWarehouseHistory,
        "can_view_credit_history": canViewCreditHistory,
        "can_view_reports": canViewReports,
        "can_manage_designs": canManageDesigns,
        "can_manage_design_names": canManageDesignNames,
        "can_manage_credits": canManageCredits,
        "can_move_out": canMoveOut,
        "can_import_items": canImport,
      };

      List<String> roles = [];
      if (isOwner) {
        roles.add("owner");
      } else {
        if (allowedWarehouses.isNotEmpty) roles.add("warehouse");
        if (hasCreditAccess) roles.add("credit");
      }

      await UserService().createUser(
        firstName: first.text,
        lastName: last.text,
        roles: roles,
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
            const Text("Top Level Access", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            
            SwitchListTile(title: const Text("Credit Access"), subtitle: const Text("View Credits Tab"), value: hasCreditAccess, onChanged: (v) => setState(() => hasCreditAccess = v)),

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

            const Divider(height: 40),
            const Text("Permissions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            SwitchListTile(title: const Text("Can View Reports"), value: canViewReports, onChanged: (v) => setState(() => canViewReports = v)),
            SwitchListTile(title: const Text("Can View Warehouse History"), value: canViewWarehouseHistory, onChanged: (v) => setState(() => canViewWarehouseHistory = v)),
            SwitchListTile(title: const Text("Can View Credit History"), value: canViewCreditHistory, onChanged: (v) => setState(() => canViewCreditHistory = v)),
            SwitchListTile(title: const Text("Can Move Out Items"), value: canMoveOut, onChanged: (v) => setState(() => canMoveOut = v)),
            SwitchListTile(title: const Text("Can Transfer Warehouses"), value: canTransfer, onChanged: (v) => setState(() => canTransfer = v)),
            SwitchListTile(title: const Text("Can Manage Designs"), value: canManageDesigns, onChanged: (v) => setState(() => canManageDesigns = v)),
            SwitchListTile(title: const Text("Can Give Design Name/Price"), value: canManageDesignNames, onChanged: (v) => setState(() => canManageDesignNames = v)),
            SwitchListTile(title: const Text("Can Manage Credits"), value: canManageCredits, onChanged: (v) => setState(() => canManageCredits = v)),
            SwitchListTile(title: const Text("Can Import Items"), value: canImport, onChanged: (v) => setState(() => canImport = v)),
          ],


          const SizedBox(height: 30),
          ElevatedButton(onPressed: save, child: Text(S.of(context, "register"))),
        ],
      ),
    );
  }
}
