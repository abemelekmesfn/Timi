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

  @override
  void initState() {
    super.initState();
    first = TextEditingController(text: widget.user.firstName);
    last = TextEditingController(text: widget.user.lastName);
    accessCode = TextEditingController(text: widget.user.accessCode);
    
    isOwner = widget.user.roles.contains("owner");
    isActive = widget.user.isActive;
    
    hasCreditAccess = widget.user.roles.contains("credit");

    final p = widget.user.permissions;
    allowedWarehouses = List<String>.from(p["warehouses"] ?? []);
    canTransfer = p["can_transfer"] == true;
    canViewWarehouseHistory = p["can_view_warehouse_history"] == true;
    canViewCreditHistory = p["can_view_credit_history"] == true;
    canViewReports = p["can_view_reports"] == true;
    canManageDesigns = p["can_manage_designs"] == true;
    canManageDesignNames = p["can_manage_design_names"] == true;
    canManageCredits = p["can_manage_credits"] == true;
    canMoveOut = p["can_move_out"] == true;
    canImport = p["can_import_items"] == true;
  }

  Future<void> save() async {
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

      await UserService().updateUser(
        id: widget.user.id,
        firstName: first.text,
        lastName: last.text,
        roles: roles,
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
