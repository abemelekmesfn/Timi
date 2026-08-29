from django.core.management.base import BaseCommand
from apps.inventory.models import Inventory, InventoryMovement
from apps.credits.models import Client, Credit, Payment
from apps.notebook.models import Note
from apps.users.models import User

class Command(BaseCommand):
    help = "Resets all app data for a fresh start, keeping only the initial owner."

    def handle(self, *args, **kwargs):
        self.stdout.write("Wiping demo data...")
        
        InventoryMovement.objects.all().delete()
        Inventory.objects.all().delete()
        
        Payment.objects.all().delete()
        Credit.objects.all().delete()
        Client.objects.all().delete()
        
        Note.objects.all().delete()
        
        # Keep the initial owner, delete everyone else
        User.objects.exclude(access_code="123456").delete()
        
        self.stdout.write(self.style.SUCCESS("All demo data has been successfully wiped! The app is completely fresh."))
