from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import LoginView, LogoutView, TaskViewSet, UserListView, UserWorkloadView

router = DefaultRouter()
router.register("tasks", TaskViewSet, basename="task")

urlpatterns = [
    path("login/", LoginView.as_view(), name="login"),
    path("logout/", LogoutView.as_view(), name="logout"),
    path("users/workload/", UserWorkloadView.as_view(), name="user-workload"),
    path("users/", UserListView.as_view(), name="user-list"),
    path("", include(router.urls)),
]
