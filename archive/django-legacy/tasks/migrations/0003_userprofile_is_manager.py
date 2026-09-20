import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


def forwards_create_profiles(apps, schema_editor):
    User = apps.get_model("auth", "User")
    UserProfile = apps.get_model("tasks", "UserProfile")
    for user in User.objects.all():
        is_manager = bool(user.is_staff or user.is_superuser)
        UserProfile.objects.update_or_create(
            user=user,
            defaults={"is_manager": is_manager},
        )
        # Decouple Django admin from app managers: keep is_staff only for superusers.
        if user.is_staff and not user.is_superuser:
            user.is_staff = False
            user.save(update_fields=["is_staff"])


def backwards_noop(apps, schema_editor):
    pass


class Migration(migrations.Migration):
    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
        ("tasks", "0002_taskcomment"),
    ]

    operations = [
        migrations.CreateModel(
            name="UserProfile",
            fields=[
                (
                    "id",
                    models.BigAutoField(
                        auto_created=True,
                        primary_key=True,
                        serialize=False,
                        verbose_name="ID",
                    ),
                ),
                ("is_manager", models.BooleanField(default=False)),
                (
                    "user",
                    models.OneToOneField(
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="profile",
                        to=settings.AUTH_USER_MODEL,
                    ),
                ),
            ],
        ),
        migrations.RunPython(forwards_create_profiles, backwards_noop),
    ]
