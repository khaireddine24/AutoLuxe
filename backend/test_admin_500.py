import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'setting.settings')
django.setup()

from django.test import Client

client = Client()
try:
    response = client.get('/admin/login/')
    print("Status:", response.status_code)
except Exception as e:
    import traceback
    traceback.print_exc()
