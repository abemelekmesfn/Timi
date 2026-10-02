from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView
from .views import LoginView, ResetDemoDataView, VerifyPasswordView

urlpatterns = [
    path('login/', LoginView.as_view(), name='login'),
    path('verify-password/', VerifyPasswordView.as_view(), name='verify_password'),
    path('refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('reset-demo-data/', ResetDemoDataView.as_view(), name='reset_demo_data'),
]