from django.db import transaction
from django.db.models import Q

from rest_framework import generics, status
from rest_framework.views import APIView
from rest_framework.response import Response

from .models import Inventory, InventoryMovement
from .serializers import (
    InventorySerializer,
    MoveOutSerializer,
    InventoryHistorySerializer,
)
from .permissions import IsWarehouseOrOwner


class InventoryListCreateView(generics.ListCreateAPIView):

    serializer_class = InventorySerializer
    permission_classes = [IsWarehouseOrOwner]

    def get_queryset(self):
        search = self.request.query_params.get("search")

        queryset = Inventory.objects.filter(remaining_meters__gt=0).order_by("-created_at")

        if search:
            queryset = queryset.filter(
                Q(roll_number__icontains=search) |
                Q(serial_number__icontains=search)
            )

        return queryset


class InventoryDetailView(generics.RetrieveAPIView):

    queryset = Inventory.objects.all()
    serializer_class = InventorySerializer
    permission_classes = [IsWarehouseOrOwner]


class MoveOutView(APIView):

    permission_classes = [IsWarehouseOrOwner]

    @transaction.atomic
    def post(self, request, pk):

        inventory = Inventory.objects.select_for_update().get(pk=pk)

        serializer = MoveOutSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        meters = serializer.validated_data["meters_out"]

        if meters > inventory.remaining_meters:
            return Response(
                {"detail": "Insufficient meters."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        inventory.remaining_meters -= meters
        inventory.save()

        InventoryMovement.objects.create(
            inventory=inventory,
            meters_out=meters,
            moved_by=request.user,
            note=serializer.validated_data.get("note", "")
        )

        return Response({
            "message": "Moved successfully.",
            "remaining_meters": inventory.remaining_meters
        })


class InventoryHistoryView(generics.ListAPIView):

    serializer_class = InventoryHistorySerializer
    permission_classes = [IsWarehouseOrOwner]

    def get_queryset(self):
        search = self.request.query_params.get("search")

        queryset = InventoryMovement.objects.select_related(
            "inventory",
            "moved_by"
        )

        if search:
            queryset = queryset.filter(
                Q(inventory__roll_number__icontains=search) |
                Q(inventory__serial_number__icontains=search)
            )

        return queryset