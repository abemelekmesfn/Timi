from django.contrib import admin
from .models import Inventory, InventoryMovement, Warehouse, DesignName

admin.site.register(Inventory)
admin.site.register(InventoryMovement)
admin.site.register(Warehouse)
admin.site.register(DesignName)