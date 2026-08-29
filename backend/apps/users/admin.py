from django.contrib import admin
from django.contrib.auth.admin import UserAdmin

from .models import User


@admin.register(User)
class CustomUserAdmin(UserAdmin):
    ordering = ["first_name"]

    list_display = (
        "first_name",
        "last_name",
        "access_code",
        "roles",
        "is_active",
    )

    fieldsets = (
        (None, {"fields": ("access_code",)}),
        ("Personal info", {"fields": ("first_name", "last_name")}),
        ("Role", {"fields": ("roles",)}),
        ("Permissions", {
            "fields": (
                "is_active",
                "is_staff",
                "is_superuser",
                "groups",
                "user_permissions",
            )
        }),
    )

    add_fieldsets = (
        (None, {
            "classes": ("wide",),
            "fields": (
                "access_code",
                "first_name",
                "last_name",
                "roles",
                "is_active",
            ),
        }),
    )

    search_fields = ("first_name", "last_name", "access_code")