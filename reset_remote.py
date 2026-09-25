import requests

# The URL of your live Render API
URL = "https://timi-api-9kbw.onrender.com/api/auth/reset-demo-data/"

# The secret key to prevent strangers from resetting your data
SECRET_KEY = "konjit_demo_reset_2026"

print("Sending reset request to live server...")
try:
    response = requests.post(URL, json={"secret": SECRET_KEY})
    if response.status_code == 200:
        print("✅ SUCCESS: All demo data wiped from live server!")
    else:
        print(f"❌ FAILED: {response.status_code} - {response.text}")
except Exception as e:
    print(f"❌ ERROR: {e}")
