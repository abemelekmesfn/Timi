import uuid
from django.db import models
from django.contrib.auth.models import AbstractBaseUser, PermissionsMixin

from .managers import UserManager


class User(AbstractBaseUser, PermissionsMixin):

    class Role(models.TextChoices):
        OWNER = "owner", "Owner"
        WAREHOUSE = "warehouse", "Warehouse"
        CREDIT = "credit", "Credit"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

    first_name = models.CharField(max_length=50)
    last_name = models.CharField(max_length=50, blank=True)

    access_code = models.CharField(max_length=6, unique=True)

    roles = models.JSONField(default=list)

    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)

    created_at = models.DateTimeField(auto_now_add=True)

    objects = UserManager()

    USERNAME_FIELD = "access_code"
    REQUIRED_FIELDS = ["first_name"]

    class Meta:
        db_table = "users"

    def __str__(self):
        return f"{self.first_name} {self.last_name}".strip()