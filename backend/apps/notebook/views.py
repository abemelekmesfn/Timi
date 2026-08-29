from rest_framework import generics

from .models import Note
from .serializers import NoteSerializer
from .permissions import NotebookPermission


class NoteListCreateView(generics.ListCreateAPIView):

    serializer_class = NoteSerializer
    permission_classes = [NotebookPermission]

    queryset = Note.objects.select_related(
        "created_by"
    )


class NoteDetailView(generics.RetrieveUpdateDestroyAPIView):

    serializer_class = NoteSerializer
    permission_classes = [NotebookPermission]

    queryset = Note.objects.select_related(
        "created_by"
    )