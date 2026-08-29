from rest_framework import serializers
from .models import Inventory, InventoryMovement


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


class MoveOutSerializer(serializers.Serializer):
    meters_out = serializers.DecimalField(
        max_digits=8,
        decimal_places=2
    )
    note = serializers.CharField(required=False, allow_blank=True)


class InventoryHistorySerializer(serializers.ModelSerializer):

    roll_number = serializers.CharField(source="inventory.roll_number", read_only=True)
    serial_number = serializers.CharField(source="inventory.serial_number", read_only=True)
    moved_by_name = serializers.CharField(source="moved_by.first_name", read_only=True)

    class Meta:
        model = InventoryMovement
        fields = (
            "id",
            "roll_number",
            "serial_number",
            "meters_out",
            "moved_by_name",
            "note",
            "created_at",
        )