from rest_framework.permissions import BasePermission

def _is_owner(user):
    return user and user.is_authenticated and "owner" in user.roles

class IsCreditOrOwner(BasePermission):
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        return bool(set(request.user.roles) & {"owner", "credit"})

class HasCreditPermission(BasePermission):
    def has_permission(self, request, view):
        if _is_owner(request.user): return True
        if not request.user or not request.user.is_authenticated: return False
        return request.user.permissions.get("can_manage_credits") == True

class HasCreditHistoryPermission(BasePermission):
    def has_permission(self, request, view):
        if _is_owner(request.user): return True
        if not request.user or not request.user.is_authenticated: return False
        return request.user.permissions.get("can_view_credit_history") == True