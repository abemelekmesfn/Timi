from decimal import Decimal

from django.db import transaction
from django.db.models import Q, Count, Sum

from rest_framework import generics, status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.parsers import MultiPartParser, FormParser
import pandas as pd

from .models import Inventory, InventoryMovement, Warehouse, DesignName, InventoryTransfer, AdminNotification, ReservedInventory
from .serializers import (
    InventorySerializer,
    MoveOutSerializer,
    DesignMoveOutSerializer,
    BulkInventorySerializer,
    InventoryHistorySerializer,
    WarehouseSerializer,
    DesignNameSerializer,
    BatchCartMoveOutSerializer,
    InventoryTransferSerializer,
    AdminNotificationSerializer,
    ReservedInventorySerializer,
)
from .permissions import IsWarehouseOrOwner, IsOwner


# ═══════════════════════════════════════════════
#  Warehouse
# ═══════════════════════════════════════════════

class WarehouseListCreateView(generics.ListCreateAPIView):

    serializer_class = WarehouseSerializer

    def get_permissions(self):
        if self.request.method == "POST":
            return [IsOwner()]
        return [IsWarehouseOrOwner()]

    def get_queryset(self):
        return Warehouse.objects.annotate(
            item_count=Count(
                "inventory_items",
                filter=Q(inventory_items__remaining_meters__gt=0),
            )
        ).order_by("-created_at")


class WarehouseDetailView(generics.RetrieveDestroyAPIView):
    """Admin-only: retrieve or permanently delete a warehouse."""
    serializer_class = WarehouseSerializer
    permission_classes = [IsOwner]

    def get_queryset(self):
        return Warehouse.objects.annotate(
            item_count=Count(
                "inventory_items",
                filter=Q(inventory_items__remaining_meters__gt=0),
            )
        )

# ═══════════════════════════════════════════════
#  Design Groups (aggregated view within warehouse)
# ═══════════════════════════════════════════════

class WarehouseDesignGroupView(APIView):

    permission_classes = [IsWarehouseOrOwner]

    def get(self, request, warehouse_id):
        search = request.query_params.get("search", "")

        qs = Inventory.objects.filter(
            warehouse_id=warehouse_id,
            remaining_meters__gt=0,
        )

        if search:
            # Also match by design name
            matching_dns = list(
                DesignName.objects.filter(
                    Q(design_number__icontains=search)
                    | Q(design_name__icontains=search)
                ).values_list("design_number", flat=True)
            )
            qs = qs.filter(
                Q(design_number__icontains=search)
                | Q(color_number__icontains=search)
                | Q(design_number__in=matching_dns)
            )

        groups = (
            qs.values("design_number")
            .annotate(
                item_count=Count("id"),
                total_meters=Sum("remaining_meters"),
            )
            .order_by("design_number")
        )

        # Enrich with design names and prices
        all_dns = [g["design_number"] for g in groups]
        name_price_map = dict(
            DesignName.objects.filter(design_number__in=all_dns).values_list(
                "design_number", "design_name"
            )
        )
        price_map = dict(
            DesignName.objects.filter(design_number__in=all_dns).values_list(
                "design_number", "price_per_meter"
            )
        )

        result = []
        for g in groups:
            result.append(
                {
                    "design_number": g["design_number"],
                    "design_name": name_price_map.get(g["design_number"], ""),
                    "price_per_meter": str(price_map.get(g["design_number"], 0.0)),
                    "item_count": g["item_count"],
                    "total_meters": str(g["total_meters"]),
                }
            )

        return Response(result)


# ═══════════════════════════════════════════════
#  Inventory CRUD
# ═══════════════════════════════════════════════

class InventoryListCreateView(generics.ListCreateAPIView):

    serializer_class = InventorySerializer
    permission_classes = [IsWarehouseOrOwner]

    def get_queryset(self):
        search = self.request.query_params.get("search")
        warehouse = self.request.query_params.get("warehouse")

        queryset = Inventory.objects.filter(remaining_meters__gt=0).order_by("-created_at")

        if warehouse:
            queryset = queryset.filter(warehouse_id=warehouse)

        if search:
            queryset = queryset.filter(
                Q(design_number__icontains=search)
                | Q(color_number__icontains=search)
            )

        return queryset


class InventoryDetailView(generics.RetrieveAPIView):

    queryset = Inventory.objects.all()
    serializer_class = InventorySerializer
    permission_classes = [IsWarehouseOrOwner]


# ═══════════════════════════════════════════════
#  Move Out (single item — kept for backward compat)
# ═══════════════════════════════════════════════

class MoveOutView(APIView):

    permission_classes = [IsWarehouseOrOwner]

    @transaction.atomic
    def post(self, request, pk):

        inventory = Inventory.objects.select_for_update().get(pk=pk)

        serializer = MoveOutSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        meters = serializer.validated_data["meters_out"]

        if meters > inventory.remaining_meters:
            return Response(
                {"detail": "Insufficient meters."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        inventory.remaining_meters -= meters
        inventory.save()

        InventoryMovement.objects.create(
            inventory=inventory,
            meters_out=meters,
            moved_by=request.user,
            note=serializer.validated_data.get("note", ""),
        )

        return Response(
            {
                "message": "Moved successfully.",
                "remaining_meters": inventory.remaining_meters,
            }
        )


# ═══════════════════════════════════════════════
#  Move Out by Design (new — used by warehouse page)
# ═══════════════════════════════════════════════

class DesignMoveOutView(APIView):

    permission_classes = [IsWarehouseOrOwner]

    @transaction.atomic
    def post(self, request):
        serializer = DesignMoveOutSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        warehouse_id = serializer.validated_data["warehouse"]
        design_number = serializer.validated_data["design_number"]
        move_type = serializer.validated_data["move_type"]
        value = serializer.validated_data["value"]
        note = serializer.validated_data.get("note", "")

        items = (
            Inventory.objects.select_for_update()
            .filter(
                warehouse_id=warehouse_id,
                design_number=design_number,
                remaining_meters__gt=0,
            )
            .order_by("created_at")
        )

        if move_type == "items":
            count = int(value)
            if count > items.count():
                return Response(
                    {"detail": "Not enough items."},
                    status=status.HTTP_400_BAD_REQUEST,
                )
            for item in items[:count]:
                meters_moved = item.remaining_meters
                item.remaining_meters = 0
                item.save()
                InventoryMovement.objects.create(
                    inventory=item,
                    meters_out=meters_moved,
                    moved_by=request.user,
                    note=note,
                )

        elif move_type == "meters":
            remaining_to_move = value
            total_available = items.aggregate(t=Sum("remaining_meters"))["t"] or Decimal("0")
            if remaining_to_move > total_available:
                return Response(
                    {"detail": "Insufficient meters."},
                    status=status.HTTP_400_BAD_REQUEST,
                )
            for item in items:
                if remaining_to_move <= 0:
                    break
                deduct = min(remaining_to_move, item.remaining_meters)
                item.remaining_meters -= deduct
                item.save()
                remaining_to_move -= deduct
                InventoryMovement.objects.create(
                    inventory=item,
                    meters_out=deduct,
                    moved_by=request.user,
                    note=note,
                )

        return Response({"message": "Moved successfully."})


# ═══════════════════════════════════════════════
#  Batch Cart Move Out
# ═══════════════════════════════════════════════

class BatchCartMoveOutView(APIView):
    permission_classes = [IsWarehouseOrOwner]

    @transaction.atomic
    def post(self, request):
        serializer = BatchCartMoveOutSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        items_data = serializer.validated_data["items"]
        
        for item_data in items_data:
            warehouse_id = item_data["warehouse"]
            design_number = item_data["design_number"]
            move_type = item_data["move_type"]
            value = item_data["value"]
            note = item_data.get("note", "")

            items = (
                Inventory.objects.select_for_update()
                .filter(
                    warehouse_id=warehouse_id,
                    design_number=design_number,
                    remaining_meters__gt=0,
                )
                .order_by("created_at")
            )

            if move_type == "items":
                count = int(value)
                if count > items.count():
                    return Response(
                        {"detail": f"Not enough items for {design_number}."},
                        status=status.HTTP_400_BAD_REQUEST,
                    )
                for item in items[:count]:
                    meters_moved = item.remaining_meters
                    item.remaining_meters = 0
                    item.save()
                    InventoryMovement.objects.create(
                        inventory=item,
                        meters_out=meters_moved,
                        moved_by=request.user,
                        note=note,
                    )

            elif move_type == "meters":
                remaining_to_move = value
                total_available = items.aggregate(t=Sum("remaining_meters"))["t"] or Decimal("0")
                if remaining_to_move > total_available:
                    return Response(
                        {"detail": f"Insufficient meters for {design_number}."},
                        status=status.HTTP_400_BAD_REQUEST,
                    )
                for item in items:
                    if remaining_to_move <= 0:
                        break
                    deduct = min(remaining_to_move, item.remaining_meters)
                    item.remaining_meters -= deduct
                    item.save()
                    InventoryMovement.objects.create(
                        inventory=item,
                        meters_out=deduct,
                        moved_by=request.user,
                        note=note,
                    )
                    remaining_to_move -= deduct

        return Response({"message": "Batch move out successful."})


# ═══════════════════════════════════════════════
#  Inventory Transfer
# ═══════════════════════════════════════════════

class InventoryTransferView(APIView):
    permission_classes = [IsWarehouseOrOwner]

    @transaction.atomic
    def post(self, request):
        serializer = InventoryTransferSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        from_warehouse_id = serializer.validated_data["from_warehouse"]
        to_warehouse_id = serializer.validated_data["to_warehouse"]
        items_data = serializer.validated_data["items"]
        note = serializer.validated_data.get("note", "")

        from_warehouse = Warehouse.objects.get(id=from_warehouse_id)
        to_warehouse = Warehouse.objects.get(id=to_warehouse_id)

        for item_data in items_data:
            design_number = item_data["design_number"]
            move_type = item_data["move_type"]
            value = item_data["value"]

            items = (
                Inventory.objects.select_for_update()
                .filter(
                    warehouse_id=from_warehouse_id,
                    design_number=design_number,
                    remaining_meters__gt=0,
                )
                .order_by("created_at")
            )

            if move_type == "items":
                count = int(value)
                if count > items.count():
                    return Response(
                        {"detail": f"Not enough items for {design_number}."},
                        status=status.HTTP_400_BAD_REQUEST,
                    )
                for item in items[:count]:
                    meters_moved = item.remaining_meters
                    item.remaining_meters = 0
                    item.save()
                    
                    # Create new inventory in target warehouse
                    new_item = Inventory.objects.create(
                        warehouse=to_warehouse,
                        design_number=item.design_number,
                        color_number=item.color_number,
                        original_meters=meters_moved,
                        remaining_meters=meters_moved,
                        created_by=request.user,
                    )
                    
                    # Record the transfer
                    InventoryTransfer.objects.create(
                        from_warehouse=from_warehouse,
                        to_warehouse=to_warehouse,
                        design_number=design_number,
                        meters_transferred=meters_moved,
                        transferred_by=request.user,
                        note=note,
                    )

            elif move_type == "meters":
                remaining_to_move = value
                total_available = items.aggregate(t=Sum("remaining_meters"))["t"] or Decimal("0")
                if remaining_to_move > total_available:
                    return Response(
                        {"detail": f"Insufficient meters for {design_number}."},
                        status=status.HTTP_400_BAD_REQUEST,
                    )
                for item in items:
                    if remaining_to_move <= 0:
                        break
                    deduct = min(remaining_to_move, item.remaining_meters)
                    item.remaining_meters -= deduct
                    item.save()
                    
                    # Create new inventory in target warehouse
                    new_item = Inventory.objects.create(
                        warehouse=to_warehouse,
                        design_number=item.design_number,
                        color_number=item.color_number,
                        original_meters=deduct,
                        remaining_meters=deduct,
                        created_by=request.user,
                    )
                    
                    # Record the transfer
                    InventoryTransfer.objects.create(
                        from_warehouse=from_warehouse,
                        to_warehouse=to_warehouse,
                        design_number=design_number,
                        meters_transferred=deduct,
                        transferred_by=request.user,
                        note=note,
                    )
                    remaining_to_move -= deduct

        return Response({"message": "Transfer successful."})


# ═══════════════════════════════════════════════
#  Admin Notifications
# ═══════════════════════════════════════════════

class AdminNotificationView(generics.ListAPIView):
    serializer_class = AdminNotificationSerializer
    permission_classes = [IsOwner]

    def get_queryset(self):
        return AdminNotification.objects.all()

    def post(self, request):
        # Mark all as read
        AdminNotification.objects.filter(is_read=False).update(is_read=True)
        return Response({"message": "Marked all as read."})


# ═══════════════════════════════════════════════
#  Bulk Inventory Create
# ═══════════════════════════════════════════════

class BulkInventoryCreateView(APIView):

    permission_classes = [IsWarehouseOrOwner]

    @transaction.atomic
    def post(self, request):
        serializer = BulkInventorySerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        warehouse = Warehouse.objects.get(pk=serializer.validated_data["warehouse"])
        items_data = serializer.validated_data["items"]

        created = []
        for item in items_data:
            inv = Inventory.objects.create(
                warehouse=warehouse,
                design_number=item["design_number"],
                color_number=item.get("color_number", ""),
                original_meters=item["original_meters"],
                remaining_meters=item["original_meters"],
                created_by=request.user,
            )
            created.append(inv.id)

        return Response(
            {"message": f"{len(created)} items created.", "count": len(created)},
            status=status.HTTP_201_CREATED,
        )


# ═══════════════════════════════════════════════
#  History
# ═══════════════════════════════════════════════

class InventoryHistoryView(generics.ListAPIView):

    serializer_class = InventoryHistorySerializer
    permission_classes = [IsWarehouseOrOwner]

    def get_queryset(self):
        search = self.request.query_params.get("search")

        queryset = InventoryMovement.objects.select_related(
            "inventory", "moved_by"
        )

        if search:
            queryset = queryset.filter(
                Q(inventory__design_number__icontains=search)
                | Q(inventory__color_number__icontains=search)
            )

        return queryset


# ═══════════════════════════════════════════════
#  Design Name Mapping
# ═══════════════════════════════════════════════

class DesignNameListCreateView(generics.ListCreateAPIView):

    queryset = DesignName.objects.all().order_by("-created_at")
    serializer_class = DesignNameSerializer
    permission_classes = [IsWarehouseOrOwner]

# ═══════════════════════════════════════════════
#  Excel Parsing (Fallback)
# ═══════════════════════════════════════════════

class ParseExcelView(APIView):
    parser_classes = (MultiPartParser, FormParser)

    def post(self, request, *args, **kwargs):
        file = request.FILES.get("file")
        if not file:
            return Response({"error": "No file uploaded"}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            # We try pandas since it supports old .xls (using xlrd) and html-xls.
            try:
                df = pd.read_excel(file, header=None, engine='xlrd')
            except Exception as e_excel:
                # Often legacy exports are just HTML tables wrapped in .xls
                try:
                    file.seek(0)
                    dfs = pd.read_html(file.read())
                    df = dfs[0]
                except Exception as e_html:
                    raise Exception(f"Excel Parse Error: {str(e_excel)} | HTML Fallback Error: {str(e_html)}")

            parsed_items = []
            
            # Find the header row (contains DES, COL, QTY)
            header_row_idx = -1
            data_sets = []
            
            for i, row in df.iterrows():
                if i > 5: break
                
                des_cols, col_cols, qty_cols = [], [], []
                for c, val in enumerate(row):
                    if pd.isna(val): continue
                    val_str = str(val).upper().strip()
                    if "DES" in val_str: des_cols.append(c)
                    elif "COL" in val_str and "C/NO" not in val_str: col_cols.append(c)
                    elif "QTY" in val_str or "MET" in val_str: qty_cols.append(c)
                
                if des_cols and qty_cols:
                    header_row_idx = i
                    for des_idx in des_cols:
                        qty_idx = next((q for q in qty_cols if q > des_idx), -1)
                        if qty_idx == -1: continue
                        col_idx = next((c for c in col_cols if des_idx < c < qty_idx), -1)
                        data_sets.append((des_idx, col_idx, qty_idx))
                    break
            
            if header_row_idx == -1:
                # fallback assuming format
                header_row_idx = 1
                data_sets = [(1, 2, 3), (5, 6, 7)]
            
            # Identify 'Pages' (blocks of data rows separated by headers/blank lines)
            pages = []
            current_page = []
            
            for i, row in df.iterrows():
                if i <= header_row_idx: continue
                
                # Check if this row is a data row
                is_data = False
                for des_idx, col_idx, qty_idx in data_sets:
                    if qty_idx >= len(row): continue
                    des_val = row.iloc[des_idx]
                    qty_val = row.iloc[qty_idx]
                    if pd.isna(des_val) or pd.isna(qty_val): continue
                    
                    des_str = str(des_val).strip().upper()
                    if not des_str or "DES" in des_str: continue # skip blanks or headers
                    
                    try:
                        float(qty_val)
                        is_data = True
                        break
                    except ValueError:
                        pass
                
                if is_data:
                    current_page.append(row)
                else:
                    if current_page:
                        pages.append(current_page)
                        current_page = []
            
            if current_page:
                pages.append(current_page)
                
            # Now process each page: Left Box completely, then Right Box completely
            for page_rows in pages:
                for des_idx, col_idx, qty_idx in data_sets:
                    for row in page_rows:
                        if qty_idx >= len(row): continue
                        
                        des_val = row.iloc[des_idx]
                        qty_val = row.iloc[qty_idx]
                        if pd.isna(des_val) or pd.isna(qty_val): continue
                        
                        design_no = str(des_val).strip()
                        color_no = str(row.iloc[col_idx]).strip() if col_idx != -1 and not pd.isna(row.iloc[col_idx]) else ""
                        
                        try:
                            meters = float(qty_val)
                        except ValueError:
                            continue
                        
                        if design_no and meters > 0:
                            parsed_items.append({
                                "design_number": design_no,
                                "color_number": color_no,
                                "original_meters": meters
                            })
            
            return Response({"items": parsed_items})
            
        except Exception as e:
            import traceback
            traceback.print_exc()
            return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)

# ═══════════════════════════════════════════════
#  Admin Dashboard Stats
# ═══════════════════════════════════════════════
from django.utils import timezone
from datetime import timedelta
from django.db.models.functions import TruncDate, TruncWeek, TruncYear

class DashboardExportView(APIView):
    permission_classes = [IsOwner]

    def get(self, request):
        export_format = request.query_params.get("export_format", "excel")
        period = request.query_params.get("period", "weekly")
        lang = request.query_params.get("lang", "en")
        
        translations = {
            "en": {
                "title": "TIMI - Admin Dashboard Report",
                "date": "Date",
                "summary": "Summary",
                "total_items": "Total Items",
                "total_meters": "Total Meters",
                "total_assets": "Total Assets (ETB)",
                "top_designs": "Top Designs Out",
                "design": "Design",
                "meters": "Meters Out",
                "chart_title_line": "Items Entered vs Out",
                "chart_title_pie": "Top Designs Going Out",
                "entered": "Entered",
                "out": "Out",
                # Excel history headers
                "history_in": "Items Entered History",
                "history_out": "Items Out History",
                "color": "Color",
                "original_meters": "Original Meters",
                "remaining_meters": "Remaining Meters",
                "warehouse": "Warehouse",
                "entered_by": "Entered By",
                "moved_by": "Moved By",
                "meters_out": "Meters Out",
                "note": "Note",
                "period_label": "Period",
                "daily": "Daily",
                "weekly": "Weekly",
                "yearly": "Yearly",
            },
            "am": {
                "title": "TIMI - የአስተዳዳሪ ዳሽቦርድ ሪፖርት",
                "date": "ቀን",
                "summary": "ማጠቃለያ",
                "total_items": "ጠቅላላ እቃዎች",
                "total_meters": "ጠቅላላ ሜትሮች",
                "total_assets": "ጠቅላላ ንብረት (ብር)",
                "top_designs": "በብዛት የወጡ ዲዛይኖች",
                "design": "ዲዛይን",
                "meters": "ሜትሮች",
                "chart_title_line": "የገቡ እና የወጡ እቃዎች ንፅፅር",
                "chart_title_pie": "በብዛት የወጡ ዲዛይኖች",
                "entered": "የገባ",
                "out": "የወጣ",
                # Excel history headers
                "history_in": "የገቡ እቃዎች ታሪክ",
                "history_out": "የወጡ እቃዎች ታሪክ",
                "color": "ቀለም",
                "original_meters": "ጠቅላላ ሜትር",
                "remaining_meters": "የቀረ ሜትር",
                "warehouse": "መጋዘን",
                "entered_by": "ያስገባ ሰው",
                "moved_by": "ያስወጣ ሰው",
                "meters_out": "የወጣ ሜትር",
                "note": "ማስታወሻ",
                "period_label": "ወቅት",
                "daily": "ዕለታዊ",
                "weekly": "ሳምንታዊ",
                "yearly": "ዓመታዊ",
            }
        }
        
        t = translations.get(lang, translations["en"])

        # 1. Total Assets
        inventories = Inventory.objects.filter(remaining_meters__gt=0)
        total_items = inventories.count()
        total_meters = inventories.aggregate(total=Sum("remaining_meters"))["total"] or Decimal("0.0")

        # Calculate total ETB
        total_birr = Decimal("0.0")
        dns = DesignName.objects.all()
        price_map = {dn.design_number: dn.price_per_meter for dn in dns}
        for inv in inventories:
            price = price_map.get(inv.design_number, Decimal('0.0'))
            total_birr += inv.remaining_meters * price

        # 2. Date range
        now = timezone.now()
        if period == "daily":
            start_date = now - timedelta(days=7)
            trunc_func = TruncDate('created_at')
        elif period == "weekly":
            start_date = now - timedelta(weeks=4)
            trunc_func = TruncWeek('created_at')
        else:
            start_date = now - timedelta(days=365 * 5)
            trunc_func = TruncYear('created_at')
            
        # 3. Chart aggregate data
        entered_agg = Inventory.objects.filter(created_at__gte=start_date)\
            .annotate(date=trunc_func)\
            .values('date')\
            .annotate(total_entered=Sum('original_meters'))\
            .order_by('date')
            
        out_agg = InventoryMovement.objects.filter(created_at__gte=start_date)\
            .annotate(date=trunc_func)\
            .values('date')\
            .annotate(total_out=Sum('meters_out'))\
            .order_by('date')

        chart_data = {}
        for e in entered_agg:
            if e['date']:
                d = e['date'].strftime('%Y-%m-%d')
                chart_data.setdefault(d, {'entered': 0, 'out': 0})['entered'] = float(e['total_entered'])
            
        for o in out_agg:
            if o['date']:
                d = o['date'].strftime('%Y-%m-%d')
                chart_data.setdefault(d, {'entered': 0, 'out': 0})['out'] = float(o['total_out'])

        sorted_chart_data = [{'date': k, 'entered': v['entered'], 'out': v['out']} for k, v in sorted(chart_data.items())]

        top_designs = InventoryMovement.objects.filter(created_at__gte=start_date)\
            .values('inventory__design_number')\
            .annotate(total_out=Sum('meters_out'))\
            .order_by('-total_out')[:10]

        # ══════════════════════════════════════
        #  EXCEL: Detailed History Report
        # ══════════════════════════════════════
        if export_format == "excel":
            try:
                import io
                import pandas as pd
                from django.http import HttpResponse

                period_label = t.get(period, period.capitalize())

                # Sheet 1: Summary
                df_summary = pd.DataFrame([{
                    t["period_label"]: period_label,
                    t["total_items"]: total_items,
                    t["total_meters"]: float(total_meters),
                    t["total_assets"]: float(total_birr),
                }])

                # Sheet 2: Detailed Items Entered History
                items_in = Inventory.objects.filter(created_at__gte=start_date)\
                    .select_related('warehouse', 'created_by')\
                    .order_by('-created_at')
                
                rows_in = []
                for item in items_in:
                    rows_in.append({
                        t["date"]: item.created_at.strftime('%Y-%m-%d %H:%M'),
                        t["design"]: item.design_number,
                        t["color"]: item.color_number,
                        t["original_meters"]: float(item.original_meters),
                        t["remaining_meters"]: float(item.remaining_meters),
                        t["warehouse"]: item.warehouse.name if item.warehouse else "-",
                        t["entered_by"]: item.created_by.full_name if hasattr(item.created_by, 'full_name') else str(item.created_by),
                    })
                df_in = pd.DataFrame(rows_in) if rows_in else pd.DataFrame()

                # Sheet 3: Detailed Items Out History
                movements = InventoryMovement.objects.filter(created_at__gte=start_date)\
                    .select_related('inventory', 'inventory__warehouse', 'moved_by')\
                    .order_by('-created_at')
                
                rows_out = []
                for mv in movements:
                    rows_out.append({
                        t["date"]: mv.created_at.strftime('%Y-%m-%d %H:%M'),
                        t["design"]: mv.inventory.design_number,
                        t["color"]: mv.inventory.color_number,
                        t["meters_out"]: float(mv.meters_out),
                        t["warehouse"]: mv.inventory.warehouse.name if mv.inventory.warehouse else "-",
                        t["moved_by"]: mv.moved_by.full_name if hasattr(mv.moved_by, 'full_name') else str(mv.moved_by),
                        t["note"]: mv.note or "",
                    })
                df_out = pd.DataFrame(rows_out) if rows_out else pd.DataFrame()

                # Sheet 4: Top Designs Out
                df_top = pd.DataFrame([
                    {t["design"]: d['inventory__design_number'], t["meters"]: float(d['total_out'])}
                    for d in top_designs
                ])

                output = io.BytesIO()
                with pd.ExcelWriter(output, engine='openpyxl') as writer:
                    df_summary.to_excel(writer, sheet_name=t['summary'], index=False)
                    if not df_in.empty:
                        df_in.to_excel(writer, sheet_name=t['history_in'][:31], index=False)
                    if not df_out.empty:
                        df_out.to_excel(writer, sheet_name=t['history_out'][:31], index=False)
                    if not df_top.empty:
                        df_top.to_excel(writer, sheet_name=t['top_designs'][:31], index=False)
                
                output.seek(0)
                response = HttpResponse(
                    output, 
                    content_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
                )
                response['Content-Disposition'] = f'attachment; filename="timi_report_{period}.xlsx"'
                return response
            except Exception as e:
                import traceback
                traceback.print_exc()
                return Response({"error": str(e)}, status=400)

        # ══════════════════════════════════════
        #  PDF: Summary + Charts
        # ══════════════════════════════════════
        elif export_format == "pdf":
            try:
                import io
                from django.http import HttpResponse
                from reportlab.pdfgen import canvas
                from reportlab.lib.pagesizes import letter
                from reportlab.lib.utils import ImageReader
                from reportlab.pdfbase.ttfonts import TTFont
                from reportlab.pdfbase import pdfmetrics
                import matplotlib
                matplotlib.use('Agg')
                import matplotlib.pyplot as plt
                import matplotlib.font_manager as fm
                import os
                
                from django.conf import settings
                import logging
                logger = logging.getLogger(__name__)
                
                # Try multiple font locations for Amharic support
                font_candidates = [
                    str(settings.BASE_DIR / "nyala.ttf"),                    # backend/nyala.ttf
                    os.path.join(os.path.dirname(__file__), "nyala.ttf"),    # next to this views.py
                    os.path.join(str(settings.BASE_DIR), "nyala.ttf"),       # explicit str conversion
                    "C:\\Windows\\Fonts\\nyala.ttf",                          # Windows local
                    "/usr/share/fonts/nyala.ttf",                            # Linux system
                ]
                
                font_path = None
                for candidate in font_candidates:
                    logger.info(f"Checking font path: {candidate} -> exists={os.path.exists(candidate)}")
                    if os.path.exists(candidate):
                        font_path = candidate
                        break
                
                has_amharic_font = font_path is not None
                logger.info(f"Amharic font found: {has_amharic_font}, path: {font_path}")
                
                output = io.BytesIO()
                p = canvas.Canvas(output, pagesize=letter)
                
                if has_amharic_font:
                    pdfmetrics.registerFont(TTFont('Nyala', font_path))
                    p.setFont('Nyala', 14)
                    nyala_prop = fm.FontProperties(fname=font_path)
                else:
                    nyala_prop = None
                
                # Title
                p.drawString(50, 750, f"{t['title']} ({period.capitalize()})")
                if has_amharic_font:
                    p.setFont('Nyala', 11)
                p.drawString(50, 730, f"{t['date']}: {now.strftime('%Y-%m-%d %H:%M')}")
                
                # Summary section
                p.drawString(50, 700, f"{'─' * 50}")
                p.drawString(50, 682, f"{t['total_items']}: {total_items}")
                p.drawString(50, 664, f"{t['total_meters']}: {total_meters}")
                p.drawString(50, 646, f"{t['total_assets']}: {total_birr}")
                p.drawString(50, 628, f"{'─' * 50}")
                
                # Line Chart — entered vs out
                if sorted_chart_data:
                    fig, ax = plt.subplots(figsize=(6, 2.8))
                    dates = [x['date'] for x in sorted_chart_data]
                    entered_vals = [float(x['entered']) for x in sorted_chart_data]
                    out_vals = [float(x['out']) for x in sorted_chart_data]
                    
                    ax.plot(dates, entered_vals, label=t['entered'], marker='o', color='#1976D2', linewidth=2)
                    ax.plot(dates, out_vals, label=t['out'], marker='s', color='#D32F2F', linewidth=2)
                    ax.fill_between(dates, entered_vals, alpha=0.1, color='#1976D2')
                    ax.fill_between(dates, out_vals, alpha=0.1, color='#D32F2F')
                    
                    if has_amharic_font and nyala_prop:
                        ax.set_title(t['chart_title_line'], fontproperties=nyala_prop, fontsize=13)
                        ax.legend(prop=nyala_prop)
                    else:
                        ax.set_title(t['chart_title_line'], fontsize=13)
                        ax.legend()
                    ax.grid(True, alpha=0.3)
                    plt.xticks(rotation=30, ha='right', fontsize=8)
                    fig.tight_layout()
                    
                    img_buf = io.BytesIO()
                    plt.savefig(img_buf, format='png', dpi=150, bbox_inches='tight')
                    img_buf.seek(0)
                    plt.close(fig)
                    
                    p.drawImage(ImageReader(img_buf), 40, 390, width=520, height=210)

                # Pie Chart — top designs
                top_list = list(top_designs[:5])
                if top_list:
                    fig, ax = plt.subplots(figsize=(4.5, 3.5))
                    labels = [f"{t['design']} {d['inventory__design_number']}" for d in top_list]
                    sizes = [float(d['total_out']) for d in top_list]
                    colors = ['#1976D2', '#388E3C', '#F57C00', '#D32F2F', '#7B1FA2']
                    
                    if has_amharic_font and nyala_prop:
                        ax.pie(sizes, labels=labels, autopct='%1.1f%%', startangle=90,
                               colors=colors[:len(sizes)],
                               textprops={'fontproperties': nyala_prop, 'fontsize': 9})
                        ax.set_title(t['chart_title_pie'], fontproperties=nyala_prop, fontsize=13)
                    else:
                        ax.pie(sizes, labels=labels, autopct='%1.1f%%', startangle=90,
                               colors=colors[:len(sizes)])
                        ax.set_title(t['chart_title_pie'], fontsize=13)
                    fig.tight_layout()
                    
                    img_buf_pie = io.BytesIO()
                    plt.savefig(img_buf_pie, format='png', dpi=150, bbox_inches='tight')
                    img_buf_pie.seek(0)
                    plt.close(fig)
                    
                    p.drawImage(ImageReader(img_buf_pie), 100, 80, width=300, height=280)
                
                p.showPage()
                p.save()
                
                output.seek(0)
                response = HttpResponse(output, content_type="application/pdf")
                response['Content-Disposition'] = f'attachment; filename="timi_report_{period}.pdf"'
                return response
            except Exception as e:
                import traceback
                traceback.print_exc()
                return Response({"error": str(e)}, status=400)
                
        return Response({"error": "Invalid format"}, status=400)


class DashboardStatsView(APIView):
    permission_classes = [IsOwner]

    def get(self, request):
        period = request.query_params.get("period", "daily") # daily, weekly, yearly

        # 1. Total Assets
        inventories = Inventory.objects.filter(remaining_meters__gt=0)
        total_items = inventories.count()
        total_meters = inventories.aggregate(total=Sum("remaining_meters"))["total"] or Decimal("0.0")

        # Calculate total ETB
        total_birr = Decimal("0.0")
        dns = DesignName.objects.all()
        price_map = {dn.design_number: dn.price_per_meter for dn in dns}

        for inv in inventories:
            price = price_map.get(inv.design_number, Decimal('0.0'))
            total_birr += inv.remaining_meters * price

        # 2. Charts Data
        now = timezone.now()
        if period == "daily":
            start_date = now - timedelta(days=7)
            trunc_func = TruncDate('created_at')
        elif period == "weekly":
            start_date = now - timedelta(weeks=4)
            trunc_func = TruncWeek('created_at')
        else: # yearly
            start_date = now - timedelta(days=365 * 5)
            trunc_func = TruncYear('created_at')

        entered = Inventory.objects.filter(created_at__gte=start_date)\
            .annotate(date=trunc_func)\
            .values('date')\
            .annotate(total_entered=Sum('original_meters'))\
            .order_by('date')
            
        out = InventoryMovement.objects.filter(created_at__gte=start_date)\
            .annotate(date=trunc_func)\
            .values('date')\
            .annotate(total_out=Sum('meters_out'))\
            .order_by('date')

        # 3. Pie Chart: Which design is more going out
        top_designs = InventoryMovement.objects.filter(created_at__gte=start_date)\
            .values('inventory__design_number')\
            .annotate(total_out=Sum('meters_out'))\
            .order_by('-total_out')[:5]

        chart_data = {}
        for e in entered:
            if e['date']:
                d = e['date'].strftime('%Y-%m-%d')
                chart_data.setdefault(d, {'entered': 0, 'out': 0})['entered'] = e['total_entered']
            
        for o in out:
            if o['date']:
                d = o['date'].strftime('%Y-%m-%d')
                chart_data.setdefault(d, {'entered': 0, 'out': 0})['out'] = o['total_out']

        sorted_chart_data = [{'date': k, 'entered': v['entered'], 'out': v['out']} for k, v in sorted(chart_data.items())]

        top_designs_list = [
            {
                "design_number": d['inventory__design_number'],
                "total_out": d['total_out']
            }
            for d in top_designs
        ]

        return Response({
            "total_items": total_items,
            "total_meters": total_meters,
            "total_birr": total_birr,
            "chart_data": sorted_chart_data,
            "top_designs": top_designs_list,
        })

# ═══════════════════════════════════════════════
#  Cart Views
# ═══════════════════════════════════════════════

class CartListView(generics.ListAPIView):
    serializer_class = ReservedInventorySerializer

    def get_queryset(self):
        return ReservedInventory.objects.filter(user=self.request.user).order_by("-created_at")


class CartAddView(APIView):
    @transaction.atomic
    def post(self, request):
        warehouse_id = request.data.get("warehouseId")
        design_number = request.data.get("designNumber")
        move_type = request.data.get("moveType")
        value = Decimal(str(request.data.get("value", "0")))

        if value <= 0:
            return Response({"error": "Value must be positive"}, status=status.HTTP_400_BAD_REQUEST)

        inventories = Inventory.objects.filter(
            warehouse_id=warehouse_id, 
            design_number=design_number, 
            remaining_meters__gt=0
        ).order_by("created_at")

        if move_type == "items":
            if value > inventories.count():
                return Response({"error": "Not enough items"}, status=status.HTTP_400_BAD_REQUEST)

            items_to_use = list(inventories[:int(value)])
            for inv in items_to_use:
                ReservedInventory.objects.create(
                    inventory=inv,
                    user=request.user,
                    meters=inv.remaining_meters,
                    design_number=design_number,
                    move_type=move_type,
                    requested_value=value
                )
                inv.remaining_meters = Decimal("0.0")
                inv.save()
        else:
            total_available = sum(inv.remaining_meters for inv in inventories)
            if value > total_available:
                return Response({"error": "Not enough meters"}, status=status.HTTP_400_BAD_REQUEST)

            remaining_to_reserve = value
            for inv in inventories:
                if remaining_to_reserve <= 0:
                    break
                deduct = min(inv.remaining_meters, remaining_to_reserve)
                ReservedInventory.objects.create(
                    inventory=inv,
                    user=request.user,
                    meters=deduct,
                    design_number=design_number,
                    move_type=move_type,
                    requested_value=value
                )
                inv.remaining_meters -= deduct
                inv.save()
                remaining_to_reserve -= deduct

        return Response({"message": "Added to cart successfully"})


class CartRemoveView(APIView):
    @transaction.atomic
    def post(self, request, pk):
        try:
            reservation = ReservedInventory.objects.get(id=pk, user=request.user)
            inv = reservation.inventory
            inv.remaining_meters += reservation.meters
            inv.save()
            reservation.delete()
            return Response({"message": "Removed from cart"})
        except ReservedInventory.DoesNotExist:
            return Response({"error": "Not found"}, status=status.HTTP_404_NOT_FOUND)


class CartClearView(APIView):
    @transaction.atomic
    def post(self, request):
        reservations = ReservedInventory.objects.filter(user=request.user)
        for res in reservations:
            inv = res.inventory
            inv.remaining_meters += res.meters
            inv.save()
        reservations.delete()
        return Response({"message": "Cart cleared"})


class CartCheckoutView(APIView):
    @transaction.atomic
    def post(self, request):
        reservations = ReservedInventory.objects.filter(user=request.user).order_by("created_at")
        if not reservations.exists():
            return Response({"error": "Cart is empty"}, status=status.HTTP_400_BAD_REQUEST)

        # To keep notes per design, the frontend can send a mapping of design_number -> note
        notes = request.data.get("notes", {})
        
        for res in reservations:
            note = notes.get(res.design_number, "")
            InventoryMovement.objects.create(
                inventory=res.inventory,
                meters_moved=res.meters,
                move_type="OUT",
                user=request.user,
                note=note
            )
        reservations.delete()
        return Response({"message": "Checkout successful"})