import uuid
from django.db import models
from apps.users.models import User


class Note(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

    title = models.CharField(max_length=100, blank=True)

    content = models.TextField()

    pinned = models.BooleanField(default=False)

    created_by = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name="notes"
    )

    created_at = models.DateTimeField(auto_now_add=True)

    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "notes"
        ordering = ["-pinned", "-updated_at"]

    def __str__(self):
        return self.title or "Note"