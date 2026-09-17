from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.models import User
from django.db.models import Count, Q
from django.utils import timezone
from rest_framework import status, viewsets
from rest_framework.authentication import SessionAuthentication
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Task
from .serializers import TaskSerializer, UserSerializer


class CsrfExemptSessionAuthentication(SessionAuthentication):
    """Session auth without CSRF, for non-browser API clients such as Flutter."""

    def enforce_csrf(self, request):
        return


class LoginView(APIView):
    authentication_classes = [CsrfExemptSessionAuthentication]
    permission_classes = [AllowAny]

    def post(self, request):
        username = request.data.get("username")
        password = request.data.get("password")
        user = authenticate(
            request=request._request,
            username=username,
            password=password,
        )
        if user is None:
            return Response(
                {"error": "Invalid username or password"},
                status=status.HTTP_401_UNAUTHORIZED,
            )

        login(request._request, user)
        return Response(UserSerializer(user).data, status=status.HTTP_200_OK)


class LogoutView(APIView):
    authentication_classes = [CsrfExemptSessionAuthentication]

    def post(self, request):
        logout(request._request)
        return Response(status=status.HTTP_204_NO_CONTENT)


class TaskViewSet(viewsets.ModelViewSet):
    serializer_class = TaskSerializer
    authentication_classes = [CsrfExemptSessionAuthentication]

    def get_queryset(self):
        queryset = Task.objects.all().order_by("-created_at")
        if self.request.query_params.get("overdue") == "true":
            queryset = queryset.filter(
                due_date__lt=timezone.now().date(),
            ).exclude(status=Task.Status.COMPLETED)
        return queryset


class UserListView(APIView):
    authentication_classes = [CsrfExemptSessionAuthentication]

    def get(self, request):
        users = User.objects.all().order_by("username")
        return Response(UserSerializer(users, many=True).data)


class UserWorkloadView(APIView):
    authentication_classes = [CsrfExemptSessionAuthentication]

    def get(self, request):
        users = User.objects.annotate(
            total_tasks=Count("tasks"),
            completed=Count(
                "tasks",
                filter=Q(tasks__status=Task.Status.COMPLETED),
            ),
            pending=Count(
                "tasks",
                filter=~Q(tasks__status=Task.Status.COMPLETED),
            ),
        ).order_by("username")

        workload = [
            {
                "id": user.id,
                "username": user.username,
                "total_tasks": user.total_tasks,
                "completed": user.completed,
                "pending": user.pending,
            }
            for user in users
        ]
        return Response(workload)
