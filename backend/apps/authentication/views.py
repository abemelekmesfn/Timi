from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework_simplejwt.tokens import RefreshToken

from apps.users.models import User
from .serializers import LoginSerializer


class LoginView(APIView):
    authentication_classes = []
    permission_classes = []

    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        code = serializer.validated_data["access_code"]

        try:
            user = User.objects.get(
                access_code=code,
                is_active=True
            )
        except User.DoesNotExist:
            return Response(
                {"detail": "Invalid access code"},
                status=status.HTTP_401_UNAUTHORIZED
            )

        refresh = RefreshToken.for_user(user)

        return Response({
            "access": str(refresh.access_token),
            "refresh": str(refresh),
            "user": {
                "id": str(user.id),
                "first_name": user.first_name,
                "last_name": user.last_name,
                "roles": user.roles,
                "access_code": user.access_code,
            }
        })


class VerifyPasswordView(APIView):
    """Verifies if the provided access code belongs to an admin/owner."""
    authentication_classes = []
    permission_classes = []

    def post(self, request):
        code = request.data.get("access_code", "")
        try:
            user = User.objects.get(
                access_code=code,
                is_active=True
            )
            if "owner" in user.roles:
                return Response({"valid": True})
            else:
                return Response({"valid": False, "detail": "User is not an admin"})
        except User.DoesNotExist:
            return Response({"valid": False, "detail": "Invalid access code"}, status=status.HTTP_400_BAD_REQUEST)

class ResetDemoDataView(APIView):
    authentication_classes = []
    permission_classes = []

    def post(self, request):
        secret = request.data.get("secret")
        if secret != "konjit_demo_reset_2026":
            return Response({"detail": "Invalid secret key"}, status=status.HTTP_403_FORBIDDEN)
        
        from apps.inventory.models import (
            Inventory, InventoryMovement, Warehouse, DesignName,
            InventoryTransfer, AdminNotification, ReservedInventory,
        )
        from apps.credits.models import Client, Credit, Payment
        from apps.notebook.models import Note
        
        # Inventory-related
        ReservedInventory.objects.all().delete()
        AdminNotification.objects.all().delete()
        InventoryTransfer.objects.all().delete()
        InventoryMovement.objects.all().delete()
        Inventory.objects.all().delete()
        DesignName.objects.all().delete()
        Warehouse.objects.all().delete()
        
        # Credits
        Payment.objects.all().delete()
        Credit.objects.all().delete()
        Client.objects.all().delete()
        
        # Notebook
        Note.objects.all().delete()
        
        # Users (keep owner)
        User.objects.exclude(access_code="123456").delete()
        
        return Response({"detail": "Demo data wiped!"})
