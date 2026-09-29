from django.urls import path

from .views import (
    WarehouseListCreateView,
    WarehouseDetailView,
    WarehouseDesignGroupView,
    InventoryListCreateView,
    InventoryDetailView,
    MoveOutView,
    DesignMoveOutView,
    BulkInventoryCreateView,
    InventoryHistoryView,
    DesignNameListCreateView,
    DesignNameDetailView,
    ParseExcelView,
    DashboardStatsView,
    DashboardExportView,
    BatchCartMoveOutView,
    CartAddView,
    CartRemoveView,
    CartCheckoutView,
    CartClearView,
    CartListView,
    InventoryTransferView,
    AdminNotificationView,
)

urlpatterns = [
    # Admin Dashboard
    path("dashboard-stats/", DashboardStatsView.as_view()),
    path("dashboard-export/", DashboardExportView.as_view()),
    path("notifications/", AdminNotificationView.as_view()),

    # Warehouses
    path("warehouses/", WarehouseListCreateView.as_view()),
    path("warehouses/<uuid:pk>/", WarehouseDetailView.as_view()),
    path("warehouses/<uuid:warehouse_id>/designs/", WarehouseDesignGroupView.as_view()),
    path("transfer/", InventoryTransferView.as_view()),

    # Inventory
    path("parse-excel/", ParseExcelView.as_view()),
    path("", InventoryListCreateView.as_view()),
    path("bulk/", BulkInventoryCreateView.as_view()),
    path("history/", InventoryHistoryView.as_view()),
    path("cart/", CartListView.as_view()),
    path("cart/add/", CartAddView.as_view()),
    path("cart/remove/<uuid:pk>/", CartRemoveView.as_view()),
    path("cart/checkout/", CartCheckoutView.as_view()),
    path("cart/clear/", CartClearView.as_view()),
    path("design-move-out/", DesignMoveOutView.as_view()),
    path("batch-move-out/", BatchCartMoveOutView.as_view()),
    path("<uuid:pk>/", InventoryDetailView.as_view()),
    path("<uuid:pk>/move-out/", MoveOutView.as_view()),

    # Design Names
    path("designs/", DesignNameListCreateView.as_view()),
    path("designs/<str:design_number>/", DesignNameDetailView.as_view()),
]