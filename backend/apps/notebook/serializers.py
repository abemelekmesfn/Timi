from rest_framework import serializers
from .models import Note

class NoteSerializer(serializers.ModelSerializer):

    created_by_name = serializers.CharField(
        source="created_by.first_name",
        read_only=True
    )

    class Meta:
        model = Note
        fields = (
            "id",
            "title",
            "content",
            "pinned",
            "created_by_name",
            "created_at",
            "updated_at",
        )

    def create(self, validated_data):
        validated_data["created_by"] = self.context["request"].user
        return super().create(validated_data)