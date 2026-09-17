from django.contrib.auth.models import User
from rest_framework import serializers

from .models import Task


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ["id", "username"]


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
