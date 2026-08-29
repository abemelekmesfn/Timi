from rest_framework import generics
from .models import User
from .serializers import UserSerializer
from .permissions import IsOwner

class UserListCreateView(generics.ListCreateAPIView):
    queryset = User.objects.all().order_by("first_name")
    serializer_class = UserSerializer
    permission_classes = [IsOwner]


class UserDetailView(generics.RetrieveUpdateAPIView):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [IsOwner]