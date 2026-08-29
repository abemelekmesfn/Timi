import random
from rest_framework import serializers
from .models import User

class UserSerializer(serializers.ModelSerializer):

    class Meta:
        model = User
        fields = (
            "id",
            "first_name",
            "last_name",
            "roles",
            "access_code",
            "is_active",
            "created_at",
        )
        read_only_fields = (
            "created_at",
        )

    def create(self, validated_data):
        return User.objects.create_user(**validated_data)

    def update(self, instance, validated_data):
        if "owner" in (instance.roles or []):
            validated_data.pop("roles", None)
            validated_data.pop("is_active", None)
        return super().update(instance, validated_data)