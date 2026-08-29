from django.db.models import Q
from rest_framework import generics
from django.db import transaction
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status

from .models import Client, Credit, Payment
from .serializers import ClientSerializer, CreditSerializer, PaymentSerializer
from .permissions import IsCreditOrOwner

class ClientSearchView(generics.ListCreateAPIView):

    serializer_class = ClientSerializer
    permission_classes = [IsCreditOrOwner]

    def get_queryset(self):
        search = self.request.query_params.get("search", "")

        return Client.objects.filter(
            Q(first_name__icontains=search) |
            Q(last_name__icontains=search)
        )[:10]

class CreditListCreateView(generics.ListCreateAPIView):

    serializer_class = CreditSerializer
    permission_classes = [IsCreditOrOwner]

    def get_queryset(self):
        return Credit.objects.filter(
            status="active"
        ).select_related("client")

class CreditUpdateView(generics.UpdateAPIView):

    queryset = Credit.objects.all()

    serializer_class = CreditSerializer

    permission_classes = [IsCreditOrOwner]




class ReceivePaymentView(APIView):

    permission_classes = [IsCreditOrOwner]

    @transaction.atomic
    def post(self, request, pk):

        credit = Credit.objects.select_for_update().get(pk=pk)

        serializer = PaymentSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        amount = serializer.validated_data["amount"]

        if amount > credit.remaining_balance:
            return Response(
                {"detail": "Payment exceeds remaining balance."},
                status=status.HTTP_400_BAD_REQUEST
            )

        Payment.objects.create(
            credit=credit,
            amount=amount,
            received_by=request.user
        )

        credit.paid_amount += amount
        credit.remaining_balance -= amount

        if credit.remaining_balance == 0:
            credit.status = "paid"

        credit.save()

        return Response({
            "remaining_balance": credit.remaining_balance,
            "status": credit.status
        })

class CreditHistoryView(generics.ListAPIView):

    serializer_class = CreditSerializer

    permission_classes = [IsCreditOrOwner]

    def get_queryset(self):
        return Credit.objects.filter(
            status="paid"
        ).select_related("client")