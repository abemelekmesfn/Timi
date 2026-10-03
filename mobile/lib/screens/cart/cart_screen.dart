import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/app_locale.dart';
import '../../providers/cart_provider.dart';
import '../../services/inventory_service.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/warehouse_provider.dart';
import '../../widgets/friendly_error_widget.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  bool isSubmitting = false;

  Future<void> submit() async {
    final cartItemsAsync = ref.read(cartProvider);
    final cartItems = cartItemsAsync.valueOrNull;
    if (cartItems == null || cartItems.isEmpty) return;

    setState(() => isSubmitting = true);

    try {
      await InventoryService().checkoutCart({});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context, "successMoved"))),
        );
        ref.read(cartProvider.notifier).clearCart();
        ref.invalidate(historyProvider);
        ref.invalidate(designGroupsProvider);
        ref.read(warehousesProvider.notifier).load();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${S.of(context, "error")}: $e")),
        );
        setState(() => isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartItemsAsync = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context, "cart")),
        actions: [
          if (cartItemsAsync.valueOrNull?.isNotEmpty == true)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                ref.read(cartProvider.notifier).clearCart();
              },
            ),
        ],
      ),
      body: cartItemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => FriendlyErrorWidget(
          error: err,
          onRetry: () => ref.invalidate(cartProvider),
        ),
        data: (cartItems) {
          if (cartItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_cart_outlined, size: 64, color: AppColors.warmGrey),
                  const SizedBox(height: 16),
                  Text(
                    S.of(context, "cartEmpty"),
                    style: const TextStyle(fontSize: 18, color: AppColors.warmGrey),
                  ),
                ],
              ),
            );
          }

          final grouped = <String, Map<String, dynamic>>{};
          for (var item in cartItems) {
            final key = "${item.designNumber}_${item.moveType}";
            if (!grouped.containsKey(key)) {
              grouped[key] = {
                "designName": item.designName.isNotEmpty ? item.designName : item.designNumber,
                "designNumber": item.designNumber,
                "moveType": item.moveType,
                "value": 0.0,
                "count": 0,
                "ids": <String>[],
              };
            }
            grouped[key]!["value"] += item.value;
            grouped[key]!["count"] += 1;
            grouped[key]!["ids"].add(item.id);
          }
          final groupedList = grouped.values.toList();

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: groupedList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = groupedList[index];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item["designName"],
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${item["moveType"] == 'items' ? item["count"] : item["value"]} ${item["moveType"] == 'items' ? S.of(context, 'items') : S.of(context, 'meters')}",
                                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          if (item["moveType"] == 'items') ...[
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                              onPressed: () {
                                if ((item["ids"] as List).isNotEmpty) {
                                  ref.read(cartProvider.notifier).removeItem((item["ids"] as List).last);
                                }
                              },
                            ),
                            Text("${item["count"]}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                              onPressed: () {
                                final warehouseId = ref.read(activeWarehouseIdProvider);
                                ref.read(cartProvider.notifier).addItem(
                                      warehouseId: warehouseId,
                                      designNumber: item["designNumber"],
                                      moveType: "items",
                                      value: 1,
                                    );
                              },
                            ),
                          ] else ...[
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () {
                                for (String id in item["ids"]) {
                                  ref.read(cartProvider.notifier).removeItem(id);
                                }
                              },
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: isSubmitting ? null : submit,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              S.of(context, "moveOutAll"),
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
