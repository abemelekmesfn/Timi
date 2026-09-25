from rest_framework import serializers
from .models import Inventory, InventoryMovement, Warehouse, DesignName, InventoryTransfer, AdminNotification, ReservedInventory


# ── Warehouse ──

class WarehouseSerializer(serializers.ModelSerializer):
    item_count = serializers.IntegerField(read_only=True, default=0)

    class Meta:
        model = Warehouse
        fields = ("id", "name", "item_count", "created_at")
        read_only_fields = ("id", "created_at")

    def create(self, validated_data):
        validated_data["created_by"] = self.context["request"].user
        return super().create(validated_data)


# ── Design Name ──

class DesignNameSerializer(serializers.ModelSerializer):

    class Meta:
        model = DesignName
        fields = ("id", "design_number", "design_name", "price_per_meter", "created_at")
        read_only_fields = ("id", "created_at")

    def create(self, validated_data):
        validated_data["created_by"] = self.context["request"].user
        return super().create(validated_data)


# ── Inventory ──

class InventorySerializer(serializers.ModelSerializer):

    class Meta:
        model = Inventory
        fields = "__all__"
        read_only_fields = (
            "id",
            "remaining_meters",
            "created_by",
            "created_at",
        )

    def create(self, validated_data):
        validated_data["remaining_meters"] = validated_data["original_meters"]
        validated_data["created_by"] = self.context["request"].user
        return super().create(validated_data)


# ── Move Out (single item) ──

class MoveOutSerializer(serializers.Serializer):
    meters_out = serializers.DecimalField(
        max_digits=8,
        decimal_places=2
    )
    note = serializers.CharField(required=False, allow_blank=True)


# ── Design-level Move Out ──

class DesignMoveOutSerializer(serializers.Serializer):
    warehouse = serializers.UUIDField()
    design_number = serializers.CharField(max_length=30)
    move_type = serializers.ChoiceField(choices=["items", "meters"])
    value = serializers.DecimalField(max_digits=10, decimal_places=2)
    note = serializers.CharField(required=False, allow_blank=True, default="")


# ── Batch Cart Move Out ──

class CartItemSerializer(serializers.Serializer):
    warehouse = serializers.UUIDField()
    design_number = serializers.CharField(max_length=30)
    move_type = serializers.ChoiceField(choices=["items", "meters"])
    value = serializers.DecimalField(max_digits=10, decimal_places=2)
    note = serializers.CharField(required=False, allow_blank=True, default="")

class BatchCartMoveOutSerializer(serializers.Serializer):
    items = CartItemSerializer(many=True)


# ── Bulk Inventory Create ──

class BulkItemSerializer(serializers.Serializer):
    design_number = serializers.CharField(max_length=30)
    color_number = serializers.CharField(max_length=50, required=False, allow_blank=True, default="")
    original_meters = serializers.DecimalField(max_digits=8, decimal_places=2)


class BulkInventorySerializer(serializers.Serializer):
    warehouse = serializers.UUIDField()
    items = BulkItemSerializer(many=True)


# ── History ──

class InventoryHistorySerializer(serializers.ModelSerializer):

    design_number = serializers.CharField(source="inventory.design_number", read_only=True, default="")
    color_number = serializers.CharField(source="inventory.color_number", read_only=True, default="")
    moved_by_name = serializers.SerializerMethodField()

    class Meta:
        model = InventoryMovement
        fields = (
            "id",
            "design_number",
            "color_number",
            "meters_out",
            "moved_by_name",
            "note",
            "created_at",
        )

    def get_moved_by_name(self, obj):
        if obj.moved_by:
            return obj.moved_by.first_name or "User"
        return "System"

# ── Transfers ──

class TransferItemSerializer(serializers.Serializer):
    design_number = serializers.CharField(max_length=30)
    move_type = serializers.ChoiceField(choices=["items", "meters"])
    value = serializers.DecimalField(max_digits=10, decimal_places=2)

class InventoryTransferSerializer(serializers.Serializer):
    from_warehouse = serializers.UUIDField()
    to_warehouse = serializers.UUIDField()
    items = TransferItemSerializer(many=True)
    note = serializers.CharField(required=False, allow_blank=True, default="")

# ── Notifications ──

from .models import AdminNotification

class AdminNotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = AdminNotification
        fields = "__all__"

class ReservedInventorySerializer(serializers.ModelSerializer):
    design_name = serializers.SerializerMethodField()

    class Meta:
        model = ReservedInventory
        fields = ["id", "inventory", "user", "meters", "design_number", "move_type", "requested_value", "created_at", "design_name"]

    def get_design_name(self, obj):
        try:
            return DesignName.objects.get(design_number=obj.design_number).name
        except DesignName.DoesNotExist:
            return obj.design_number