from django.contrib.auth import authenticate
from rest_framework import serializers
from rest_framework_simplejwt.exceptions import AuthenticationFailed
from rest_framework_simplejwt.tokens import RefreshToken


class PhoneTokenObtainPairSerializer(serializers.Serializer):
    phone_number = serializers.CharField()
    password = serializers.CharField(write_only=True)

    def validate(self, attrs):
        phone_number = attrs.get('phone_number', '').strip()
        password = attrs.get('password', '')
        user = authenticate(
            request=self.context.get('request'),
            username=phone_number,
            password=password,
        )
        if user is None:
            raise AuthenticationFailed('Invalid phone number or password.')
        if not user.is_active:
            raise AuthenticationFailed('User account is disabled.')
        if user.is_blacklisted:
            raise AuthenticationFailed('Your account has been blacklisted.', code='blacklisted')

        refresh = RefreshToken.for_user(user)
        refresh['phone_number'] = user.phone_number
        refresh['is_admin'] = user.is_admin or user.is_staff or user.is_superuser

        return {
            'refresh': str(refresh),
            'access': str(refresh.access_token),
            'user': {
                'id': user.id,
                'phone_number': user.phone_number,
                'first_name': user.first_name,
                'last_name': user.last_name,
                'full_name': user.full_name,
                'is_admin': user.is_admin or user.is_staff or user.is_superuser,
            },
        }
