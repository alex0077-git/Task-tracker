from rest_framework.permissions import BasePermission


def is_manager(user):
    """App manager role — independent of Django is_staff / admin access."""
    if not user or not user.is_authenticated:
        return False
    if user.is_superuser:
        return True
    profile = getattr(user, "profile", None)
    if profile is not None:
        return bool(profile.is_manager)
    return False


class IsManager(BasePermission):
    """DRF permission: app managers only (not Django is_staff)."""

    message = "Only managers can perform this action."

    def has_permission(self, request, view):
        return is_manager(request.user)
