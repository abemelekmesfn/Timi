from decimal import Decimal
from rest_framework.test import APITestCase
from rest_framework import status
from apps.users.models import User
from apps.inventory.models import Inventory, InventoryMovement


class InventoryTests(APITestCase):

    def setUp(self):
        self.owner = User.objects.create_user(
            first_name="Owner",
            access_code="111111",
            role="owner"
        )
        self.warehouse = User.objects.create_user(
            first_name="Warehouse",
            access_code="222222",
            role="warehouse"
        )
        self.credit_user = User.objects.create_user(
            first_name="Credit",
            access_code="333333",
            role="credit"
        )
        self.client.force_authenticate(user=self.owner)

        self.inventory = Inventory.objects.create(
            roll_number="R001",
            serial_number="S001",
            original_meters=Decimal("100.00"),
            remaining_meters=Decimal("100.00"),
            created_by=self.owner
        )

    # --- List & Create ---

    def test_inventory_list(self):
        response = self.client.get("/api/inventory/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)

    def test_inventory_creation_sets_remaining(self):
        response = self.client.post("/api/inventory/", {
            "roll_number": "R002",
            "serial_number": "S002",
            "original_meters": "50.50"
        })
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(Decimal(response.data["remaining_meters"]), Decimal("50.50"))

    def test_inventory_detail(self):
        response = self.client.get(f"/api/inventory/{self.inventory.id}/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["roll_number"], "R001")

    # --- Move Out ---

    def test_move_out_success(self):
        response = self.client.post(
            f"/api/inventory/{self.inventory.id}/move-out/",
            {"meters_out": "20.50", "note": "Test move"}
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.inventory.refresh_from_db()
        self.assertEqual(self.inventory.remaining_meters, Decimal("79.50"))
        self.assertEqual(InventoryMovement.objects.count(), 1)

    def test_move_out_insufficient_meters(self):
        response = self.client.post(
            f"/api/inventory/{self.inventory.id}/move-out/",
            {"meters_out": "150.00"}
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("Insufficient", response.data["detail"])

    # --- History ---

    def test_inventory_history(self):
        InventoryMovement.objects.create(
            inventory=self.inventory,
            meters_out=Decimal("10.00"),
            moved_by=self.owner,
            note="test"
        )
        response = self.client.get("/api/inventory/history/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)

    # --- Permissions ---

    def test_warehouse_can_access(self):
        self.client.force_authenticate(user=self.warehouse)
        response = self.client.get("/api/inventory/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_credit_role_denied(self):
        self.client.force_authenticate(user=self.credit_user)
        response = self.client.get("/api/inventory/")
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
