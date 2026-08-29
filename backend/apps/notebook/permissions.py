from rest_framework.permissions import IsAuthenticated

class NotebookPermission(IsAuthenticated):
    pass