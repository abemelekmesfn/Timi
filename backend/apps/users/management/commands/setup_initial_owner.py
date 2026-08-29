from django.core.management.base import BaseCommand
from apps.users.models import User

class Command(BaseCommand):
    help = "Creates the initial owner user if no users exist"

    def handle(self, *args, **kwargs):
        if User.objects.exists():
            self.stdout.write(self.style.SUCCESS("Users already exist. Skipping initial owner setup."))
            return

        owner = User.objects.create(
            first_name="Konjit",
            last_name="Tesfaye",
            access_code="123456",
            roles=["owner", "warehouse", "credit"]
        )
        
        self.stdout.write(self.style.SUCCESS(f"Successfully created initial owner with PIN: {owner.access_code}"))
