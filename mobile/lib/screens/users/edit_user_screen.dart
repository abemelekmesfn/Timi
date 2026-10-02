import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_locale.dart';
import '../../models/user_model.dart';
import '../../providers/warehouse_provider.dart';
import '../../services/user_service.dart';

class EditUserScreen extends ConsumerStatefulWidget {
  final UserModel user;

  const EditUserScreen({super.key, required this.user});

  @override
  ConsumerState<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends ConsumerState<EditUserScreen> {
  late final TextEditingController first;
  late final TextEditingController last;
  late final TextEditingController accessCode;
  
  bool isOwner = false;
  late bool isActive;

  // Permissions
  late List<String> allowedWarehouses;
  bool canTransfer = false;
  bool canViewHistory = false;
  bool canViewDashboard = false;
  bool canManageDesigns = false;
  bool canManageCredits = false;
  bool canMoveOut = false;
  bool canImport = false;

  @override
  void initState() {
    super.initState();
    first = TextEditingController(text: widget.user.firstName);
    last = TextEditingController(text: widget.user.lastName);
    accessCode = TextEditingController(text: widget.user.accessCode);
    
    isOwner = widget.user.roles.contains("owner");
    isActive = widget.user.isActive;

    final p = widget.user.permissions;
    allowedWarehouses = List<String>.from(p["warehouses"] ?? []);
    canTransfer = p["can_transfer"] == true;
    canViewHistory = p["can_view_history"] == true;
    canViewDashboard = p["can_view_dashboard"] == true;
    canManageDesigns = p["can_manage_designs"] == true;
    canManageCredits = p["can_manage_credits"] == true;
    canMoveOut = p["can_move_out"] == true;
    canImport = p["can_import"] == true;
  }

  Future<void> save() async {
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

      await UserService().updateUser(
        id: widget.user.id,
        firstName: first.text,
        lastName: last.text,
        roles: isOwner ? ["owner"] : [],
        permissions: permissions,
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
    final warehousesAsync = ref.watch(warehousesProvider);
    final disableFields = isOwner && widget.user.roles.contains("owner"); // Cannot remove owner permissions if editing yourself but keeping simple here.

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

          SwitchListTile(
            title: const Text("Is Admin (Owner)"),
            subtitle: const Text("Gives full access to all features"),
            value: isOwner,
            onChanged: widget.user.roles.contains("owner") 
                ? null 
                : (val) {
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

          const Divider(height: 40),
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
