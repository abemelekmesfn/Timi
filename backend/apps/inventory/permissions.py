from rest_framework.permissions import BasePermission


class IsWarehouseOrOwner(BasePermission):

    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        return bool(set(request.user.roles) & {"owner", "warehouse"})