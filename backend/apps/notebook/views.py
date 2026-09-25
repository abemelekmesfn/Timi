from rest_framework import generics

from .models import Note
from .serializers import NoteSerializer
from .permissions import NotebookPermission


class NoteListCreateView(generics.ListCreateAPIView):
    serializer_class = NoteSerializer
    permission_classes = [NotebookPermission]

    def get_queryset(self):
        return Note.objects.filter(created_by=self.request.user).select_related("created_by")

    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)


class NoteDetailView(generics.RetrieveUpdateDestroyAPIView):
    serializer_class = NoteSerializer
    permission_classes = [NotebookPermission]

    def get_queryset(self):
        return Note.objects.filter(created_by=self.request.user).select_related("created_by")