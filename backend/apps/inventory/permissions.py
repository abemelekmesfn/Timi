from rest_framework.permissions import BasePermission

def _is_owner(user):
    return user and user.is_authenticated and "owner" in user.roles

class IsOwner(BasePermission):
    """Only users with the 'owner' role (admin) can access."""
    def has_permission(self, request, view):
        return _is_owner(request.user)

class IsWarehouseOrOwner(BasePermission):
    # Deprecated - kept for fallback during migration
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated: return False
        return bool(set(request.user.roles) & {"owner", "warehouse"})

def check_perm(request, perm_key):
    if _is_owner(request.user): return True
    if not request.user or not request.user.is_authenticated: return False
    return request.user.permissions.get(perm_key) == True

class HasTransferPermission(BasePermission):
    def has_permission(self, request, view): return check_perm(request, "can_transfer")

class HasHistoryPermission(BasePermission):
    def has_permission(self, request, view): return check_perm(request, "can_view_warehouse_history")

class HasDashboardPermission(BasePermission):
    def has_permission(self, request, view): return check_perm(request, "can_view_reports")

class HasDesignPermission(BasePermission):
    def has_permission(self, request, view): return check_perm(request, "can_manage_designs")

class HasMoveOutPermission(BasePermission):
    def has_permission(self, request, view): return check_perm(request, "can_move_out")

class HasImportPermission(BasePermission):
    def has_permission(self, request, view): return check_perm(request, "can_import_items")

class HasDesignNamePermission(BasePermission):
    def has_permission(self, request, view): return check_perm(request, "can_manage_design_names")

class HasWarehouseAccess(BasePermission):
    def has_permission(self, request, view):
        # Allow passing to the view where queryset filtering will happen based on allowed warehouses
        return request.user and request.user.is_authenticated

    def has_object_permission(self, request, view, obj):
        if _is_owner(request.user): return True
        allowed_warehouses = request.user.permissions.get("warehouses", [])
        
        from .models import Warehouse
        if isinstance(obj, Warehouse):
            return str(obj.id) in allowed_warehouses
            
        warehouse_id = getattr(obj, "warehouse_id", None)
        if warehouse_id:
            return str(warehouse_id) in allowed_warehouses
            
        return False