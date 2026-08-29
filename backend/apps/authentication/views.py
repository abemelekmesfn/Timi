from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework_simplejwt.tokens import RefreshToken

from apps.users.models import User
from .serializers import LoginSerializer


class LoginView(APIView):

    authentication_classes = []
    permission_classes = []

    def post(self, request):

        serializer = LoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        code = serializer.validated_data["access_code"]

        try:
            user = User.objects.get(
                access_code=code,
                is_active=True
            )
        except User.DoesNotExist:
            return Response(
                {"detail": "Invalid access code"},
                status=status.HTTP_401_UNAUTHORIZED
            )

        refresh = RefreshToken.for_user(user)

        return Response({
            "access": str(refresh.access_token),
            "refresh": str(refresh),
            "user": {
                "id": str(user.id),
                "first_name": user.first_name,
                "last_name": user.last_name,
                "roles": user.roles,
                "access_code": user.access_code,
            }
        })
