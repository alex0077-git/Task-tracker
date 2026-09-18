from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.models import User
from django.db.models import Count, Q
from django.shortcuts import get_object_or_404
from django.utils import timezone
from rest_framework import status, viewsets
from rest_framework.authentication import SessionAuthentication
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Task, TaskComment
from .permissions import is_manager
from .serializers import (
    CreateUserSerializer,
    TaskCommentSerializer,
    TaskSerializer,
    UserSerializer,
)


def overdue_queryset():
    return Task.objects.filter(
        due_date__lt=timezone.now().date(),
    ).exclude(status=Task.Status.COMPLETED)


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


class MeView(APIView):
    authentication_classes = [CsrfExemptSessionAuthentication]

    def get(self, request):
        return Response(UserSerializer(request.user).data)


class TaskViewSet(viewsets.ModelViewSet):
    serializer_class = TaskSerializer
    authentication_classes = [CsrfExemptSessionAuthentication]

    def get_queryset(self):
        queryset = Task.objects.all()
        if not is_manager(self.request.user):
            queryset = queryset.filter(assignee=self.request.user)
        if self.request.query_params.get("overdue") == "true":
            queryset = queryset.filter(
                due_date__lt=timezone.now().date(),
            ).exclude(status=Task.Status.COMPLETED)
        search = self.request.query_params.get("search")
        if search:
            queryset = queryset.filter(title__icontains=search)
        status_value = self.request.query_params.get("status")
        if status_value:
            queryset = queryset.filter(status=status_value)
        priority_value = self.request.query_params.get("priority")
        if priority_value:
            queryset = queryset.filter(priority=priority_value)
        assignee_value = self.request.query_params.get("assignee")
        if assignee_value:
            queryset = queryset.filter(assignee_id=assignee_value)
        return queryset.order_by("-created_at")

    def create(self, request, *args, **kwargs):
        if not is_manager(request.user):
            return Response(
                {"detail": "Only managers can create tasks."},
                status=status.HTTP_403_FORBIDDEN,
            )
        return super().create(request, *args, **kwargs)

    def update(self, request, *args, **kwargs):
        if not is_manager(request.user):
            return Response(
                {"detail": "Only managers can update task details."},
                status=status.HTTP_403_FORBIDDEN,
            )
        return super().update(request, *args, **kwargs)

    def destroy(self, request, *args, **kwargs):
        if not is_manager(request.user):
            return Response(
                {"detail": "Only managers can delete tasks."},
                status=status.HTTP_403_FORBIDDEN,
            )
        return super().destroy(request, *args, **kwargs)

    def partial_update(self, request, *args, **kwargs):
        if not is_manager(request.user):
            allowed_fields = set(request.data.keys()) <= {"status"}
            if not allowed_fields:
                return Response(
                    {"detail": "Employees can only update task status."},
                    status=status.HTTP_403_FORBIDDEN,
                )
        return super().partial_update(request, *args, **kwargs)


class UserListView(APIView):
    authentication_classes = [CsrfExemptSessionAuthentication]

    def get(self, request):
        if not is_manager(request.user):
            return Response(
                {"detail": "Only managers can manage users."},
                status=status.HTTP_403_FORBIDDEN,
            )
        users = User.objects.all().order_by("username")
        return Response(UserSerializer(users, many=True).data)

    def post(self, request):
        if not is_manager(request.user):
            return Response(
                {"detail": "Only managers can manage users."},
                status=status.HTTP_403_FORBIDDEN,
            )
        serializer = CreateUserSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        return Response(UserSerializer(user).data, status=status.HTTP_201_CREATED)


class UserWorkloadView(APIView):
    authentication_classes = [CsrfExemptSessionAuthentication]

    def get(self, request):
        if not is_manager(request.user):
            return Response(
                {"detail": "Only managers can view employee workload."},
                status=status.HTTP_403_FORBIDDEN,
            )
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


class DashboardView(APIView):
    authentication_classes = [CsrfExemptSessionAuthentication]

    def get(self, request):
        if not is_manager(request.user):
            tasks = Task.objects.filter(assignee=request.user)
        else:
            tasks = Task.objects.all()
        return Response(
            {
                "total": tasks.count(),
                "pending": tasks.filter(status=Task.Status.TO_DO).count(),
                "in_progress": tasks.filter(status=Task.Status.IN_PROGRESS).count(),
                "completed": tasks.filter(status=Task.Status.COMPLETED).count(),
                "overdue": overdue_queryset().filter(
                    pk__in=tasks.values("pk"),
                ).count(),
            }
        )


class TaskCommentView(APIView):
    authentication_classes = [CsrfExemptSessionAuthentication]

    def _get_task(self, request, task_id):
        queryset = Task.objects.all()
        if not is_manager(request.user):
            queryset = queryset.filter(assignee=request.user)
        return get_object_or_404(queryset, pk=task_id)

    def get(self, request, task_id):
        task = self._get_task(request, task_id)
        comments = task.comments.select_related("author").order_by("created_at")
        return Response(TaskCommentSerializer(comments, many=True).data)

    def post(self, request, task_id):
        task = self._get_task(request, task_id)
        serializer = TaskCommentSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        comment = serializer.save(task=task, author=request.user)
        return Response(
            TaskCommentSerializer(comment).data,
            status=status.HTTP_201_CREATED,
        )
