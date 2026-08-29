from rest_framework.test import APITestCase
from rest_framework import status
from apps.users.models import User
from apps.notebook.models import Note

class NotebookTests(APITestCase):

    def setUp(self):
        self.user = User.objects.create_user(
            first_name="Owner",
            access_code="111111",
            role="owner"
        )
        self.client.force_authenticate(user=self.user)
        self.note = Note.objects.create(
            title="Test Note",
            content="This is a test note.",
            created_by=self.user
        )

    def test_note_creation(self):
        response = self.client.post("/api/notebook/", {
            "title": "New Note",
            "content": "Content here"
        })
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data["created_by_name"], "Owner")

    def test_note_update(self):
        response = self.client.patch(f"/api/notebook/{self.note.id}/", {
            "pinned": True
        })
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.note.refresh_from_db()
        self.assertTrue(self.note.pinned)

    def test_unauthenticated_access(self):
        self.client.logout()
        response = self.client.get("/api/notebook/")
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
