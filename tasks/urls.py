from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import (
    DashboardView,
    LoginView,
    LogoutView,
    MeView,
    TaskCommentView,
    TaskViewSet,
    UserListView,
    UserWorkloadView,
)

router = DefaultRouter()
router.register("tasks", TaskViewSet, basename="task")

urlpatterns = [
    path("login/", LoginView.as_view(), name="login"),
    path("logout/", LogoutView.as_view(), name="logout"),
    path("me/", MeView.as_view(), name="me"),
    path("dashboard/", DashboardView.as_view(), name="dashboard"),
    path("users/workload/", UserWorkloadView.as_view(), name="user-workload"),
    path("users/", UserListView.as_view(), name="user-list"),
    path(
        "tasks/<int:task_id>/comments/",
        TaskCommentView.as_view(),
        name="task-comments",
    ),
    path("", include(router.urls)),
]
