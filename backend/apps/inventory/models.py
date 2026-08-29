import uuid
from django.db import models
from apps.users.models import User


class Inventory(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

    roll_number = models.CharField(max_length=30, unique=True)
    serial_number = models.CharField(max_length=50, unique=True)

    original_meters = models.DecimalField(max_digits=8, decimal_places=2)
    remaining_meters = models.DecimalField(max_digits=8, decimal_places=2)

    created_by = models.ForeignKey(
        User,
        on_delete=models.PROTECT,
        related_name="inventories"
    )

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "inventory"

    def __str__(self):
        return self.roll_number

class InventoryMovement(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

    inventory = models.ForeignKey(
        Inventory,
        on_delete=models.CASCADE,
        related_name="movements"
    )

    meters_out = models.DecimalField(max_digits=8, decimal_places=2)

    moved_by = models.ForeignKey(
        User,
        on_delete=models.PROTECT,
        related_name="inventory_movements"
    )

    note = models.TextField(blank=True)

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "inventory_movements"
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.inventory.roll_number} - {self.meters_out}m"