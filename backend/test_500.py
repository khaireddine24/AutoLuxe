import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'setting.settings')
django.setup()

from Account.views import register_view
from rest_framework.test import APIRequestFactory

factory = APIRequestFactory()
request = factory.post('/api/register/', {
    "email": "test500@test.com",
    "password": "Pass123!@",
    "passwordConfirm": "Pass123!@",
    "user_type": "client"
}, format='json')

try:
    response = register_view(request)
    print("Test with passwordConfirm - Status:", response.status_code)
    print("Test with passwordConfirm - Data:", response.data)
except Exception as e:
    import traceback
    traceback.print_exc()

# Test without passwordConfirm
request2 = factory.post('/api/register/', {
    "email": "test501@test.com",
    "password": "Pass123!@",
    "user_type": "client"
}, format='json')

try:
    response2 = register_view(request2)
    print("Test without passwordConfirm - Status:", response2.status_code)
    print("Test without passwordConfirm - Data:", getattr(response2, 'data', None))
except Exception as e:
    print("Test without passwordConfirm - TRACEBACK:")
    import traceback
    traceback.print_exc()

# Test with all fields but missing user_type
request3 = factory.post('/api/register/', {
    "email": "test502@test.com",
    "password": "Pass123!@",
    "passwordConfirm": "Pass123!@"
}, format='json')

try:
    response3 = register_view(request3)
    print("Test without user_type - Status:", response3.status_code)
except Exception as e:
    print("Test without user_type - TRACEBACK:")
    import traceback
    traceback.print_exc()
