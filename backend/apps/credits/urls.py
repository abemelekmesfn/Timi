from django.urls import path

from .views import (
    ClientSearchView,
    CreditListCreateView,
    CreditUpdateView,
    ReceivePaymentView,
    CreditHistoryView,
)

urlpatterns = [

    path("clients/search/", ClientSearchView.as_view()),

    path("", CreditListCreateView.as_view()),

    path("history/", CreditHistoryView.as_view()),

    path("<uuid:pk>/", CreditUpdateView.as_view()),

    path("<uuid:pk>/pay/", ReceivePaymentView.as_view()),
]