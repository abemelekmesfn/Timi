#!/usr/bin/env bash
set -o errexit

pip install -r requirements.txt

# Verify Amharic font is available
echo "=== Checking nyala.ttf font ==="
echo "PWD: $(pwd)"
ls -la nyala.ttf 2>/dev/null && echo "FOUND: nyala.ttf in project root" || echo "NOT FOUND: nyala.ttf in project root"
ls -la apps/inventory/nyala.ttf 2>/dev/null && echo "FOUND: nyala.ttf in apps/inventory" || echo "NOT FOUND: nyala.ttf in apps/inventory"
echo "=== End font check ==="

python manage.py collectstatic --noinput

python manage.py migrate

python manage.py setup_initial_owner