from django.contrib.auth.models import User
from rest_framework import serializers

from .models import Task, TaskComment
from .permissions import is_manager


class UserSerializer(serializers.ModelSerializer):
    role = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = ["id", "username", "email", "is_staff", "role"]

    def get_role(self, user):
        return "admin" if is_manager(user) else "employee"


class CreateUserSerializer(serializers.Serializer):
    username = serializers.CharField(max_length=150)
    password = serializers.CharField(write_only=True, min_length=8)
    is_staff = serializers.BooleanField(default=False)

    def validate_username(self, value):
        username = value.strip()
        if User.objects.filter(username=username).exists():
            raise serializers.ValidationError("A user with that username already exists.")
        return username

    def create(self, validated_data):
        return User.objects.create_user(
            username=validated_data["username"],
            password=validated_data["password"],
            is_staff=validated_data.get("is_staff", False),
        )


class TaskCommentSerializer(serializers.ModelSerializer):
    author_name = serializers.CharField(source="author.username", read_only=True)

    class Meta:
        model = TaskComment
        fields = ["id", "body", "author", "author_name", "created_at"]
        read_only_fields = ["author", "created_at"]

    def validate_body(self, value):
        body = value.strip()
        if not body:
            raise serializers.ValidationError("Comment cannot be empty.")
        return body


class TaskSerializer(serializers.ModelSerializer):
    assignee_name = serializers.CharField(source="assignee.username", read_only=True)
    is_overdue = serializers.BooleanField(read_only=True)
    status = serializers.CharField()
    priority = serializers.CharField()

    class Meta:
        model = Task
        fields = [
            "id",
            "title",
            "description",
            "priority",
            "status",
            "due_date",
            "assignee",
            "assignee_name",
            "is_overdue",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["created_at", "updated_at"]
        extra_kwargs = {
            "due_date": {
                "error_messages": {
                    "invalid": "Enter a valid date in YYYY-MM-DD format.",
                    "required": "Due date is required.",
                }
            },
        }

    def validate_status(self, value):
        valid_statuses = {
            Task.Status.TO_DO,
            Task.Status.IN_PROGRESS,
            Task.Status.COMPLETED,
        }
        if value not in valid_statuses:
            raise serializers.ValidationError("Invalid status value")
        return value

    def validate_priority(self, value):
        valid_priorities = {
            Task.Priority.LOW,
            Task.Priority.MEDIUM,
            Task.Priority.HIGH,
        }
        if value not in valid_priorities:
            raise serializers.ValidationError("Invalid priority value")
        return value

    def validate(self, attrs):
        attrs = super().validate(attrs)
        self._validate_assignment_conflict(attrs)
        return attrs

    def _validate_assignment_conflict(self, attrs):
        assignee = attrs.get("assignee", getattr(self.instance, "assignee", None))
        due_date = attrs.get("due_date", getattr(self.instance, "due_date", None))
        status_value = attrs.get("status", getattr(self.instance, "status", None))

        if assignee is None or due_date is None:
            return
        if status_value == Task.Status.COMPLETED:
            return
        if self.instance is not None:
            assignee_changed = "assignee" in attrs and attrs["assignee"] != self.instance.assignee
            due_changed = "due_date" in attrs and attrs["due_date"] != self.instance.due_date
            if not assignee_changed and not due_changed:
                return

        conflicts = Task.objects.filter(
            assignee=assignee,
            due_date=due_date,
        ).exclude(status=Task.Status.COMPLETED)
        if self.instance is not None:
            conflicts = conflicts.exclude(pk=self.instance.pk)
        if conflicts.exists():
            raise serializers.ValidationError(
                "This employee already has an incomplete task due on that date."
            )
