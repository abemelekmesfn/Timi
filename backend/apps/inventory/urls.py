from django.urls import path

from .views import (
    InventoryListCreateView,
    InventoryDetailView,
    MoveOutView,
    InventoryHistoryView,
)

urlpatterns = [
    path("", InventoryListCreateView.as_view()),
    path("history/", InventoryHistoryView.as_view()),
    path("<uuid:pk>/", InventoryDetailView.as_view()),
    path("<uuid:pk>/move-out/", MoveOutView.as_view()),
]