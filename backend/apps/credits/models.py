import uuid
from django.db import models
from apps.users.models import User


class Client(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

    first_name = models.CharField(max_length=50)
    last_name = models.CharField(max_length=50, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "clients"

    def __str__(self):
        return f"{self.first_name} {self.last_name}".strip()

class Credit(models.Model):

    class Status(models.TextChoices):
        ACTIVE = "active", "Active"
        PAID = "paid", "Paid"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

    client = models.ForeignKey(
        Client,
        on_delete=models.PROTECT,
        related_name="credits"
    )

    meters = models.DecimalField(max_digits=8, decimal_places=2)

    price_per_meter = models.DecimalField(max_digits=10, decimal_places=2)

    total_credit = models.DecimalField(max_digits=12, decimal_places=2)

    paid_amount = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=0
    )

    remaining_balance = models.DecimalField(max_digits=12, decimal_places=2)

    status = models.CharField(
        max_length=10,
        choices=Status.choices,
        default=Status.ACTIVE
    )

    created_by = models.ForeignKey(
        User,
        on_delete=models.PROTECT,
        related_name="credits_created"
    )

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "credits"

    def __str__(self):
        return str(self.client)

class Payment(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

    credit = models.ForeignKey(
        Credit,
        on_delete=models.CASCADE,
        related_name="payments"
    )

    amount = models.DecimalField(max_digits=12, decimal_places=2)

    received_by = models.ForeignKey(
        User,
        on_delete=models.PROTECT,
        related_name="payments_received"
    )

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "payments"
        ordering = ["-created_at"]

    def __str__(self):
        return str(self.amount)