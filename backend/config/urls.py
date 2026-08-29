from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/auth/", include("apps.authentication.urls")),
    path("api/inventory/", include("apps.inventory.urls")),
    path("api/credits/", include("apps.credits.urls")),
    path("api/notebook/", include("apps.notebook.urls")),
    path("api/users/", include("apps.users.urls")),
]
