import django.db.models.deletion
import uuid
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("inventory", "0001_initial"),
        ("users", "0001_initial"),
    ]

    operations = [
        # ── Create Warehouse table ──
        migrations.CreateModel(
            name="Warehouse",
            fields=[
                ("id", models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ("name", models.CharField(max_length=100)),
                ("created_by", models.ForeignKey(
                    on_delete=django.db.models.deletion.PROTECT,
                    related_name="warehouses",
                    to="users.user",
                )),
                ("created_at", models.DateTimeField(auto_now_add=True)),
            ],
            options={"db_table": "warehouses"},
        ),

        # ── Create DesignName table ──
        migrations.CreateModel(
            name="DesignName",
            fields=[
                ("id", models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ("design_number", models.CharField(max_length=30, unique=True)),
                ("design_name", models.CharField(max_length=100)),
                ("created_by", models.ForeignKey(
                    on_delete=django.db.models.deletion.PROTECT,
                    related_name="design_names",
                    to="users.user",
                )),
                ("created_at", models.DateTimeField(auto_now_add=True)),
            ],
            options={"db_table": "design_names"},
        ),

        # ── Rename roll_number → design_number ──
        migrations.RenameField(
            model_name="inventory",
            old_name="roll_number",
            new_name="design_number",
        ),

        # ── Rename serial_number → color_number ──
        migrations.RenameField(
            model_name="inventory",
            old_name="serial_number",
            new_name="color_number",
        ),

        # ── Remove unique from design_number ──
        migrations.AlterField(
            model_name="inventory",
            name="design_number",
            field=models.CharField(max_length=30),
        ),

        # ── Make color_number optional and remove unique ──
        migrations.AlterField(
            model_name="inventory",
            name="color_number",
            field=models.CharField(blank=True, default="", max_length=50),
        ),

        # ── Add warehouse FK to Inventory (nullable for existing data) ──
        migrations.AddField(
            model_name="inventory",
            name="warehouse",
            field=models.ForeignKey(
                blank=True,
                null=True,
                on_delete=django.db.models.deletion.CASCADE,
                related_name="inventory_items",
                to="inventory.warehouse",
            ),
        ),
    ]
