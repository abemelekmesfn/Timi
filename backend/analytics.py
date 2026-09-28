import urllib.request
import urllib.error
import json
import os
import uuid
import time
import datetime
import logging
import threading
from pathlib import Path
from typing import Dict, Any, Optional

logger = logging.getLogger("nexus")


def _load_env_file():
    """Load .env from Timi's backend directory if python-dotenv isn't available."""
    env_path = Path(__file__).resolve().parent / ".env"
    if not env_path.exists():
        return
    with open(env_path, "r") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, _, value = line.partition("=")
            key, value = key.strip(), value.strip()
            if key and key not in os.environ:
                os.environ[key] = value


# Load .env automatically so the keys are available even outside Django
_load_env_file()


class Nexus:
    """
    Nexus Analytics Python SDK.
    Drop this file directly into your Python backend (like TIMI) to send data to your private Nexus server.

    Usage:
        # The pre-configured singleton is available at module level:
        from analytics import nexus

        nexus.track_feature("user_logged_in", device_id="abc123")
        nexus.track_revenue(amount_cents=4999, kind="payment")
    """

    MAX_RETRIES = 3
    RETRY_BACKOFF = 0.5  # seconds; doubles each retry

    def __init__(self, api_url: str, api_key: str):
        """
        Args:
            api_url: The Nexus API base URL (e.g. "http://localhost:8000/api").
            api_key: A valid Nexus API key starting with "nx_sk_".
        """
        if not api_key:
            raise ValueError(
                "Nexus API key is required. Set the NEXUS_API_KEY environment variable "
                "in backend/.env or pass it directly."
            )
        self.api_url = api_url.rstrip("/")
        self.api_key = api_key
        # Generate a distinct anonymous device ID for the server if not provided
        self.server_device_id = str(uuid.uuid4())
        self._connected = None  # lazy: True / False / None (untested)

    # --- Internal Helpers ---

    def _build_headers(self) -> dict:
        return {
            "Authorization": f"ApiKey {self.api_key}",
            "Content-Type": "application/json",
        }

    def _post(self, endpoint: str, payload: dict, retries: int = 0) -> bool:
        """Synchronous POST with retry. Returns True on success."""
        url = f"{self.api_url}/ingest/{endpoint}/"
        if "device_id" not in payload:
            payload["device_id"] = self.server_device_id

        data = json.dumps(payload).encode("utf-8")
        req = urllib.request.Request(
            url, data=data, headers=self._build_headers(), method="POST"
        )

        try:
            urllib.request.urlopen(req, timeout=10)
            return True
        except urllib.error.HTTPError as e:
            body = e.read().decode("utf-8", errors="replace")
            if e.code == 401:
                logger.error("[Nexus] Authentication failed (401). Check your NEXUS_API_KEY.")
                return False
            if e.code >= 500 and retries < self.MAX_RETRIES:
                wait = self.RETRY_BACKOFF * (2 ** retries)
                logger.warning(f"[Nexus] Server error {e.code} on {endpoint}, retrying in {wait:.1f}s...")
                time.sleep(wait)
                return self._post(endpoint, payload, retries + 1)
            logger.error(f"[Nexus] HTTP {e.code} on {endpoint}: {body[:200]}")
            return False
        except urllib.error.URLError as e:
            if retries < self.MAX_RETRIES:
                wait = self.RETRY_BACKOFF * (2 ** retries)
                logger.warning(f"[Nexus] Connection error on {endpoint}, retrying in {wait:.1f}s...")
                time.sleep(wait)
                return self._post(endpoint, payload, retries + 1)
            logger.error(f"[Nexus] Connection failed for {endpoint}: {e.reason}")
            return False
        except Exception as e:
            logger.error(f"[Nexus] Unexpected error sending to {endpoint}: {e}")
            return False

    def _post_async(self, endpoint: str, payload: dict):
        """Sends events asynchronously so it doesn't block your main app."""
        threading.Thread(
            target=self._post, args=(endpoint, payload), daemon=True
        ).start()

    def verify_connection(self) -> bool:
        """
        Test that the Nexus server is reachable and the API key is valid.
        Caches the result after the first successful call.
        """
        if self._connected is True:
            return True
        try:
            url = f"{self.api_url}/health/"
            req = urllib.request.Request(url, headers=self._build_headers(), method="GET")
            urllib.request.urlopen(req, timeout=5)
            self._connected = True
            logger.info(f"[Nexus] Connected to {self.api_url}")
            return True
        except Exception as e:
            self._connected = False
            logger.warning(f"[Nexus] Cannot reach {self.api_url}: {e}")
            return False

    # --- Core Tracking Methods ---

    def track_install(self, device_id: str, kind: str = "first_install", country: str = ""):
        """kind: 'first_install', 'reinstall', 'update'"""
        self._post_async("install", {
            "device_id": device_id,
            "kind": kind,
            "country": country
        })

    def track_session(self, device_id: str, started_at: datetime.datetime, duration_seconds: int = None, returning: bool = True):
        self._post_async("session", {
            "device_id": device_id,
            "started_at": started_at.isoformat(),
            "duration_seconds": duration_seconds,
            "is_returning_user": returning
        })

    def track_feature(self, event_name: str, device_id: Optional[str] = None, metadata: Dict[str, Any] = None):
        """Track feature usage. e.g. event_name='generated_report'"""
        self._post_async("feature-event", {
            "device_id": device_id or self.server_device_id,
            "event_name": event_name,
            "metadata": metadata or {}
        })

    def track_subscription(self, event_type: str, device_id: str, plan_name: str = "Premium"):
        """event_type: 'activated', 'renewed', 'expired', 'cancelled'"""
        self._post_async("subscription", {
            "device_id": device_id,
            "event_type": event_type,
            "plan_name": plan_name
        })

    def track_revenue(self, amount_cents: int, kind: str = "payment", currency: str = "USD"):
        """kind: 'payment', 'refund', 'failed'"""
        self._post_async("revenue", {
            "amount_cents": amount_cents,
            "kind": kind,
            "currency": currency
        })

    def track_health(self, error_count: int, cpu_usage_pct: float, ram_usage_pct: float, response_time_ms: float):
        """Send infrastructure snapshots to track server health."""
        self._post_async("health-metric", {
            "error_count": error_count,
            "cpu_usage_pct": cpu_usage_pct,
            "ram_usage_pct": ram_usage_pct,
            "api_response_time_ms": response_time_ms
        })

    def track_crash(self, message: str, stack_trace: str = "", app_version: str = "", device_id: Optional[str] = None):
        self._post_async("crash", {
            "device_id": device_id or self.server_device_id,
            "message": message,
            "stack_trace": stack_trace,
            "app_version": app_version
        })

    # --- Convenience: Django Middleware ---

    @staticmethod
    def django_middleware_class():
        """
        Returns a Django middleware class that automatically tracks:
          - Every request as a feature event
          - Server errors (5xx) as crash reports
          - Request timing as health metrics

        Add to MIDDLEWARE in settings.py:
            MIDDLEWARE = [
                ...
                'analytics.NexusMiddleware',
            ]
        """
        from backend.analytics import nexus as _nexus

        class NexusMiddleware:
            def __init__(self, get_response):
                self.get_response = get_response
                # Verify on startup (non-blocking)
                threading.Thread(target=_nexus.verify_connection, daemon=True).start()

            def __call__(self, request):
                start = time.time()
                response = self.get_response(request)
                duration_ms = (time.time() - start) * 1000

                # Track the API call as a feature event
                _nexus.track_feature(
                    event_name=f"{request.method} {request.path}",
                    metadata={
                        "status_code": response.status_code,
                        "duration_ms": round(duration_ms, 2),
                    }
                )

                # Track server errors as crashes
                if response.status_code >= 500:
                    _nexus.track_crash(
                        message=f"HTTP {response.status_code} on {request.method} {request.path}",
                        app_version="timi-backend",
                    )

                return response

        return NexusMiddleware


# ---------------------------------------------------------------------------
# Module-level singleton — ready to import anywhere in Timi
# ---------------------------------------------------------------------------
NEXUS_API_URL = os.environ.get("NEXUS_API_URL", "http://localhost:8000/api")
NEXUS_API_KEY = os.environ.get("NEXUS_API_KEY", "")

nexus = Nexus(api_url=NEXUS_API_URL, api_key=NEXUS_API_KEY)

# Also expose the middleware class at module level for Django convenience
NexusMiddleware = Nexus.django_middleware_class()
