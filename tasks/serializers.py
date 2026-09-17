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
            "priority": {
                "error_messages": {
                    "invalid_choice": "Priority must be one of: Low, Medium, High.",
                }
            },
            "status": {
                "error_messages": {
                    "invalid_choice": "Status must be one of: To Do, In Progress, Completed.",
                }
            },
        }
