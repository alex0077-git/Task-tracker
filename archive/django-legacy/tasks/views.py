from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.models import User
from django.middleware.csrf import get_token
from django.shortcuts import get_object_or_404
from django.utils import timezone
from django.utils.decorators import method_decorator
from django.views.decorators.csrf import ensure_csrf_cookie
from rest_framework import status, viewsets
from rest_framework.authentication import SessionAuthentication, TokenAuthentication
from rest_framework.authtoken.models import Token
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Task, TaskComment
from .permissions import IsManager, is_manager
from .serializers import (
    CreateUserSerializer,
    TaskCommentSerializer,
    TaskSerializer,
    UserSerializer,
)

# Session (CSRF-protected) for browsers; Token for mobile / non-browser clients.
API_AUTHENTICATION_CLASSES = [TokenAuthentication, SessionAuthentication]


def overdue_queryset():
    return Task.objects.filter(
        due_date__lt=timezone.now().date(),
    ).exclude(status=Task.Status.COMPLETED)


@method_decorator(ensure_csrf_cookie, name="dispatch")
class CsrfTokenView(APIView):
    """Issue csrftoken cookie + return token for X-CSRFToken header (Flutter web)."""

    authentication_classes = []
    permission_classes = [AllowAny]

    def get(self, request):
        return Response({"csrfToken": get_token(request)})


class LoginView(APIView):
    authentication_classes = []
    permission_classes = [AllowAny]

    def post(self, request):
        # Browsers must send CSRF (cookie from GET /api/csrf/ + X-CSRFToken).
        # Mobile can omit CSRF and use the returned auth token afterward.
        if "csrftoken" in request.COOKIES or request.META.get("HTTP_X_CSRFTOKEN"):
            SessionAuthentication().enforce_csrf(request)

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
        token, _ = Token.objects.get_or_create(user=user)
        data = UserSerializer(user).data
        data["token"] = token.key
        return Response(data, status=status.HTTP_200_OK)


class LogoutView(APIView):
    authentication_classes = API_AUTHENTICATION_CLASSES

    def post(self, request):
        if isinstance(request.successful_authenticator, TokenAuthentication):
            Token.objects.filter(user=request.user).delete()
        logout(request._request)
        return Response(status=status.HTTP_204_NO_CONTENT)


class TaskViewSet(viewsets.ModelViewSet):
    serializer_class = TaskSerializer
    authentication_classes = API_AUTHENTICATION_CLASSES

    def get_permissions(self):
        if self.action in ("create", "update", "destroy"):
            return [IsAuthenticated(), IsManager()]
        return [IsAuthenticated()]

    def get_queryset(self):
        queryset = Task.objects.all()
        if not is_manager(self.request.user):
            queryset = queryset.filter(assignee=self.request.user)
        if self.request.query_params.get("overdue") == "true":
            queryset = queryset.filter(pk__in=overdue_queryset())
        search = self.request.query_params.get("search")
        if search:
            queryset = queryset.filter(title__istartswith=search)
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
    authentication_classes = API_AUTHENTICATION_CLASSES
    permission_classes = [IsAuthenticated, IsManager]

    def get(self, request):
        users = User.objects.all().order_by("username")
        return Response(UserSerializer(users, many=True).data)

    def post(self, request):
        serializer = CreateUserSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        return Response(UserSerializer(user).data, status=status.HTTP_201_CREATED)


class TaskCommentView(APIView):
    authentication_classes = API_AUTHENTICATION_CLASSES

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
