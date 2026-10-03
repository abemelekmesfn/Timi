from django.urls import path
from .views import UserListCreateView, UserDetailView, MeView

urlpatterns = [
    path("me/", MeView.as_view()),
    path("", UserListCreateView.as_view()),
    path("<uuid:pk>/", UserDetailView.as_view()),
]