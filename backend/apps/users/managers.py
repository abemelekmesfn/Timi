from django.contrib.auth.base_user import BaseUserManager

class UserManager(BaseUserManager):
    def create_user(self, access_code, first_name, roles=None, password=None, **extra_fields):
        if not access_code:
            raise ValueError("Access code is required")

        if roles is None:
            roles = []

        user = self.model(
            access_code=access_code,
            first_name=first_name,
            roles=roles,
            **extra_fields
        )

        user.set_unusable_password()
        user.save(using=self._db)
        return user

    def create_superuser(self, access_code, first_name, password=None, **extra_fields):
        extra_fields.setdefault("roles", ["owner"])
        extra_fields.setdefault("is_staff", True)
        extra_fields.setdefault("is_superuser", True)

        return self.create_user(
            access_code=access_code,
            first_name=first_name,
            password=password,
            **extra_fields
        )