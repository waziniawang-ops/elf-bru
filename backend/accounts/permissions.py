from rest_framework.permissions import BasePermission, SAFE_METHODS


class IsAdminUser(BasePermission):
    def has_permission(self, request, view):
        return (
            request.user
            and request.user.is_authenticated
            and (request.user.is_admin or request.user.is_staff or request.user.is_superuser)
        )


class IsNotBlacklisted(BasePermission):
    message = 'Your account has been blacklisted. Please contact support.'

    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return True
        return not request.user.is_blacklisted


class IsAdminOrReadOnly(BasePermission):
    def has_permission(self, request, view):
        if request.method in SAFE_METHODS:
            return request.user and request.user.is_authenticated and not request.user.is_blacklisted
        return (
            request.user
            and request.user.is_authenticated
            and not request.user.is_blacklisted
            and (request.user.is_admin or request.user.is_staff or request.user.is_superuser)
        )
