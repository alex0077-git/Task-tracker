from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as DjangoUserAdmin
from django.contrib.auth.models import User

from .models import Task, TaskComment, UserProfile


def _superuser_admin_permission(request):
    return bool(
        request.user
        and request.user.is_active
        and request.user.is_superuser
    )


admin.site.has_permission = _superuser_admin_permission


class UserProfileInline(admin.StackedInline):
    model = UserProfile
    can_delete = False


class UserAdmin(DjangoUserAdmin):
    inlines = [UserProfileInline]


admin.site.unregister(User)
admin.site.register(User, UserAdmin)


@admin.register(Task)
class TaskAdmin(admin.ModelAdmin):
    list_display = (
        "title",
        "priority",
        "status",
        "due_date",
        "assignee",
        "is_overdue",
    )
    list_filter = ("priority", "status", "due_date")
    search_fields = ("title",)


@admin.register(TaskComment)
class TaskCommentAdmin(admin.ModelAdmin):
    list_display = ("task", "author", "created_at")
    search_fields = ("body", "author__username", "task__title")
