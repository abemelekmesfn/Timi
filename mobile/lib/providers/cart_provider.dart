import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart_item_model.dart';
import '../services/inventory_service.dart';

class CartNotifier extends StateNotifier<AsyncValue<List<CartItemModel>>> {
  CartNotifier() : super(const AsyncValue.loading()) {
    loadCart();
  }

  Future<void> loadCart() async {
    state = const AsyncValue.loading();
    try {
      final items = await InventoryService().getCartItems();
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addItem({
    required String warehouseId,
    required String designNumber,
    required String moveType,
    required double value,
  }) async {
    await InventoryService().addToCart(
      warehouseId: warehouseId,
      designNumber: designNumber,
      moveType: moveType,
      value: value,
    );
    await loadCart();
  }

  Future<void> removeItem(String id) async {
    await InventoryService().removeFromCart(id);
    await loadCart();
  }

  Future<void> clearCart() async {
    await InventoryService().clearCart();
    await loadCart();
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, AsyncValue<List<CartItemModel>>>((ref) {
  return CartNotifier();
});
