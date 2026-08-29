from django.contrib import admin
from .models import Client, Credit, Payment

admin.site.register(Client)
admin.site.register(Credit)
admin.site.register(Payment)