from rest_framework import serializers
from .models import Client, Credit, Payment


class ClientSerializer(serializers.ModelSerializer):

    full_name = serializers.SerializerMethodField()

    class Meta:
        model = Client
        fields = (
            "id",
            "first_name",
            "last_name",
            "full_name",
        )

    def get_full_name(self, obj):
        return f"{obj.first_name} {obj.last_name}".strip()


class CreditSerializer(serializers.ModelSerializer):

    client = ClientSerializer(read_only=True)

    client_id = serializers.PrimaryKeyRelatedField(
        queryset=Client.objects.all(),
        source="client",
        write_only=True
    )

    class Meta:
        model = Credit
        fields = (
            "id",
            "client",
            "client_id",
            "meters",
            "price_per_meter",
            "total_credit",
            "paid_amount",
            "remaining_balance",
            "status",
            "created_at",
        )
        read_only_fields = (
            "total_credit",
            "paid_amount",
            "remaining_balance",
            "status",
        )

    def create(self, validated_data):

        client = validated_data.pop("client")

        meters = validated_data["meters"]
        price = validated_data["price_per_meter"]

        total = meters * price

        return Credit.objects.create(
            client=client,
            total_credit=total,
            remaining_balance=total,
            created_by=self.context["request"].user,
            **validated_data
        )


class PaymentSerializer(serializers.Serializer):
    amount = serializers.DecimalField(
        max_digits=12,
        decimal_places=2
    )

class CreditHistorySerializer(serializers.ModelSerializer):

    client_name = serializers.SerializerMethodField()

    class Meta:
        model = Credit
        fields = (
            "id",
            "client_name",
            "remaining_balance",
            "status",
            "created_at",
        )

    def get_client_name(self, obj):
        return str(obj.client)