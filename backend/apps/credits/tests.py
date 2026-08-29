import uuid
from decimal import Decimal
from rest_framework.test import APITestCase
from rest_framework import status
from apps.users.models import User
from apps.credits.models import Client, Credit, Payment


class CreditTests(APITestCase):

    def setUp(self):
        self.owner = User.objects.create_user(
            first_name="Owner",
            access_code="111111",
            role="owner"
        )
        self.credit_user = User.objects.create_user(
            first_name="CreditUser",
            access_code="333333",
            role="credit"
        )
        self.warehouse = User.objects.create_user(
            first_name="Warehouse",
            access_code="222222",
            role="warehouse"
        )
        self.client_obj = Client.objects.create(
            first_name="John",
            last_name="Doe"
        )
        self.client.force_authenticate(user=self.owner)

        self.credit = Credit.objects.create(
            client=self.client_obj,
            meters=Decimal("10.00"),
            price_per_meter=Decimal("100.00"),
            total_credit=Decimal("1000.00"),
            remaining_balance=Decimal("1000.00"),
            created_by=self.owner
        )

    # --- Client Search ---

    def test_client_search(self):
        response = self.client.get("/api/credits/clients/search/?search=John")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)

    # --- Credit Creation ---

    def test_credit_creation(self):
        response = self.client.post("/api/credits/", {
            "client_id": str(self.client_obj.id),
            "meters": "5.00",
            "price_per_meter": "200.00"
        })
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(Decimal(response.data["total_credit"]), Decimal("1000.00"))
        self.assertEqual(Decimal(response.data["remaining_balance"]), Decimal("1000.00"))

    def test_credit_creation_invalid_client(self):
        response = self.client.post("/api/credits/", {
            "client_id": str(uuid.uuid4()),
            "meters": "5.00",
            "price_per_meter": "200.00"
        })
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    # --- Payments ---

    def test_receive_payment(self):
        response = self.client.post(
            f"/api/credits/{self.credit.id}/pay/",
            {"amount": "400.00"}
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.credit.refresh_from_db()
        self.assertEqual(self.credit.paid_amount, Decimal("400.00"))
        self.assertEqual(self.credit.remaining_balance, Decimal("600.00"))
        self.assertEqual(self.credit.status, "active")

    def test_receive_payment_full_marks_paid(self):
        response = self.client.post(
            f"/api/credits/{self.credit.id}/pay/",
            {"amount": "1000.00"}
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.credit.refresh_from_db()
        self.assertEqual(self.credit.status, "paid")
        self.assertEqual(self.credit.remaining_balance, Decimal("0.00"))

    def test_receive_payment_excess_rejected(self):
        response = self.client.post(
            f"/api/credits/{self.credit.id}/pay/",
            {"amount": "1500.00"}
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("Payment exceeds", response.data["detail"])

    # --- History ---

    def test_credit_history_shows_paid(self):
        self.credit.status = "paid"
        self.credit.remaining_balance = Decimal("0.00")
        self.credit.paid_amount = Decimal("1000.00")
        self.credit.save()

        response = self.client.get("/api/credits/history/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)

    # --- Permissions ---

    def test_credit_role_can_access(self):
        self.client.force_authenticate(user=self.credit_user)
        response = self.client.get("/api/credits/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_warehouse_role_denied(self):
        self.client.force_authenticate(user=self.warehouse)
        response = self.client.get("/api/credits/")
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
