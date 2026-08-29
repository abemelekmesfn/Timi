from rest_framework import serializers

class LoginSerializer(serializers.Serializer):
    access_code = serializers.CharField(
        min_length=6,
        max_length=6
    )