from decimal import Decimal
from rest_framework.test import APITestCase
from rest_framework import status
from apps.users.models import User

class UserAndAuthTests(APITestCase):

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

    # --- Authentication Tests ---

    def test_login_success(self):
        response = self.client.post("/api/auth/login/", {"access_code": "111111"})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("access", response.data)
        self.assertIn("refresh", response.data)
        self.assertEqual(response.data["user"]["role"], "owner")

    def test_login_invalid_code(self):
        """A valid 6-digit code that doesn't match any user should return 401."""
        response = self.client.post("/api/auth/login/", {"access_code": "999999"})
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_login_bad_format(self):
        """A code that doesn't match the serializer constraints should return 400."""
        response = self.client.post("/api/auth/login/", {"access_code": "bad"})
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_login_missing_field(self):
        response = self.client.post("/api/auth/login/", {})
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    # --- User Management Tests ---

    def test_user_list_owner_access(self):
        self.client.force_authenticate(user=self.owner)
        response = self.client.get("/api/users/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_user_list_denied_for_non_owner(self):
        self.client.force_authenticate(user=self.warehouse)
        response = self.client.get("/api/users/")
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_user_create(self):
        self.client.force_authenticate(user=self.owner)
        response = self.client.post("/api/users/", {
            "first_name": "NewUser",
            "last_name": "Test",
            "role": "credit"
        })
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertTrue(User.objects.filter(first_name="NewUser").exists())
        # access_code should be auto-generated (6 digits)
        self.assertEqual(len(response.data["access_code"]), 6)

    def test_user_update(self):
        self.client.force_authenticate(user=self.owner)
        response = self.client.patch(
            f"/api/users/{self.warehouse.id}/",
            {"last_name": "Updated"}
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.warehouse.refresh_from_db()
        self.assertEqual(self.warehouse.last_name, "Updated")
