from rest_framework.permissions import BasePermission


class IsWarehouseOrOwner(BasePermission):

    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        return bool(set(request.user.roles) & {"owner", "warehouse"})


class IsOwner(BasePermission):
    """Only users with the 'owner' role (admin) can access."""

    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        return "owner" in request.user.roles