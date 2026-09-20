from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import (
    CsrfTokenView,
    LoginView,
    LogoutView,
    TaskCommentView,
    TaskViewSet,
    UserListView,
)

router = DefaultRouter()
router.register("tasks", TaskViewSet, basename="task")

urlpatterns = [
    path("csrf/", CsrfTokenView.as_view(), name="csrf"),
    path("login/", LoginView.as_view(), name="login"),
    path("logout/", LogoutView.as_view(), name="logout"),
    path("users/", UserListView.as_view(), name="user-list"),
    path(
        "tasks/<int:task_id>/comments/",
        TaskCommentView.as_view(),
        name="task-comments",
    ),
    path("", include(router.urls)),
]
