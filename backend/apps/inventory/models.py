import uuid
from django.db import models
from apps.users.models import User


class Warehouse(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=100)
    created_by = models.ForeignKey(
        User,
        on_delete=models.PROTECT,
        related_name="warehouses",
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "warehouses"

    def __str__(self):
        return self.name


class DesignName(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    design_number = models.CharField(max_length=30, unique=True)
    design_name = models.CharField(max_length=100)
    price_per_meter = models.DecimalField(max_digits=10, decimal_places=2, default=0.0)
    created_by = models.ForeignKey(
        User,
        on_delete=models.PROTECT,
        related_name="design_names",
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "design_names"

    def __str__(self):
        return f"{self.design_name} ({self.design_number})"


class Inventory(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

    warehouse = models.ForeignKey(
        Warehouse,
        on_delete=models.CASCADE,
        related_name="inventory_items",
        null=True,
        blank=True,
    )

    design_number = models.CharField(max_length=30)
    color_number = models.CharField(max_length=50, blank=True, default="")

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
        return self.design_number


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
        return f"{self.inventory.design_number} - {self.meters_out}m"

class InventoryTransfer(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

    from_warehouse = models.ForeignKey(
        Warehouse,
        on_delete=models.CASCADE,
        related_name="transfers_out"
    )
    to_warehouse = models.ForeignKey(
        Warehouse,
        on_delete=models.CASCADE,
        related_name="transfers_in"
    )

    design_number = models.CharField(max_length=30)
    meters_transferred = models.DecimalField(max_digits=10, decimal_places=2)
    
    transferred_by = models.ForeignKey(
        User,
        on_delete=models.PROTECT,
        related_name="inventory_transfers"
    )
    
    note = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "inventory_transfers"
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.design_number} ({self.meters_transferred}m) {self.from_warehouse.name} -> {self.to_warehouse.name}"


class AdminNotification(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    message_en = models.TextField()
    message_am = models.TextField()
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "admin_notifications"
        ordering = ["-created_at"]

    def __str__(self):
        return f"Notification at {self.created_at}"

class ReservedInventory(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    inventory = models.ForeignKey(Inventory, on_delete=models.CASCADE, related_name="reservations")
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="reserved_items")
    meters = models.DecimalField(max_digits=10, decimal_places=2)
    # Store what the user actually added to cart (for UI purposes)
    design_number = models.CharField(max_length=30)
    move_type = models.CharField(max_length=20)  # "items" or "meters"
    requested_value = models.DecimalField(max_digits=10, decimal_places=2)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "reserved_inventory"

    def __str__(self):
        return f"{self.meters}m reserved by {self.user.first_name}"

# ═══════════════════════════════════════════════
#  Signals for Admin Notifications
# ═══════════════════════════════════════════════
from django.db.models.signals import post_save
from django.dispatch import receiver

@receiver(post_save, sender=Inventory)
def notify_new_inventory(sender, instance, created, **kwargs):
    # Only notify on new items
    if created and instance.original_meters > 0:
        design = instance.design_number
        meters = instance.original_meters
        warehouse = instance.warehouse.name if instance.warehouse else "Unknown"
        user = instance.created_by.first_name if instance.created_by else "System"
        
        AdminNotification.objects.create(
            message_en=f"Imported: {meters}m of {design} to {warehouse} by {user}.",
            message_am=f"ገብቷል: {meters}ሜ የ {design} ወደ {warehouse} በ {user}."
        )

@receiver(post_save, sender=InventoryMovement)
def notify_inventory_movement(sender, instance, created, **kwargs):
    if created:
        design = instance.inventory.design_number
        meters = instance.meters_out
        user = instance.moved_by.first_name if instance.moved_by else "System"
        
        AdminNotification.objects.create(
            message_en=f"Moved Out: {meters}m of {design} by {user}.",
            message_am=f"ወጥቷል: {meters}ሜ የ {design} በ {user}."
        )

@receiver(post_save, sender=InventoryTransfer)
def notify_inventory_transfer(sender, instance, created, **kwargs):
    if created:
        design = instance.design_number
        meters = instance.meters_transferred
        from_wh = instance.from_warehouse.name
        to_wh = instance.to_warehouse.name
        user = instance.transferred_by.first_name if instance.transferred_by else "System"
        
        AdminNotification.objects.create(
            message_en=f"Transferred: {meters}m of {design} from {from_wh} to {to_wh} by {user}.",
            message_am=f"ተዛውሯል: {meters}ሜ የ {design} ከ {from_wh} ወደ {to_wh} በ {user}."
        )