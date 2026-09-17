import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../models/app_user.dart';
import '../models/task.dart';
import '../models/task_comment.dart';

class ApiService {
  ApiService._() {
    // cookie_jar cannot set the Cookie header in a browser. On web, the
    // browser stores session cookies when withCredentials is true.
    if (!kIsWeb) {
      dio.interceptors.add(CookieManager(cookieJar));
    }
  }

  static final ApiService instance = ApiService._();

  final CookieJar cookieJar = CookieJar();
  AppUser? currentUser;

  // Phone and Chrome must hit the SAME Django process. Chrome runs at
  // http://localhost:<port>, so it must call localhost (same-site cookies).
  // The phone cannot use localhost (that would be the phone itself), so it
  // uses this machine's LAN address instead.
  static String get _baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000/api/';
    }
    return 'http://192.168.0.102:8000/api/';
  }

  final Dio dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      headers: const {'Content-Type': 'application/json'},
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      extra: const {'withCredentials': true},
    ),
  );

  bool get isManager => currentUser?.isManager ?? false;

  Future<AppUser?> login(String username, String password) async {
    try {
      final response = await dio.post(
        'login/',
        data: {
          'username': username,
          'password': password,
        },
      );
      if (response.statusCode != 200 || response.data is! Map) {
        currentUser = null;
        return null;
      }
      currentUser = AppUser.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
      return currentUser;
    } catch (_) {
      currentUser = null;
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await dio.post('logout/');
    } catch (_) {
      // Session is cleared locally even if the server call fails.
    }
    currentUser = null;
  }

  Future<List<AppUser>> getUsers() async {
    try {
      final response = await dio.get('users/');
      if (response.statusCode != 200 || response.data is! List) {
        return [];
      }
      return (response.data as List)
          .map((item) => AppUser.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<String?> createUser({
    required String username,
    required String password,
    required bool isStaff,
  }) async {
    try {
      final response = await dio.post(
        'users/',
        data: {
          'username': username,
          'password': password,
          'is_staff': isStaff,
        },
      );
      if (response.statusCode == 201) {
        return null;
      }
      return 'Could not create user';
    } on DioException catch (error) {
      return _messageFromError(error);
    }
  }

  Future<List<Task>> getTasks({bool overdueOnly = false}) async {
    try {
      final response = await dio.get(
        'tasks/',
        queryParameters: {
          if (overdueOnly) 'overdue': 'true',
        },
      );
      if (response.statusCode != 200 || response.data is! List) {
        return [];
      }
      return (response.data as List)
          .map((item) => Task.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<String?> createTask(Task task) async {
    try {
      final response = await dio.post('tasks/', data: task.toJson());
      if (response.statusCode == 201) {
        return null;
      }
      return 'Could not save task';
    } on DioException catch (error) {
      return _messageFromError(error);
    }
  }

  Future<String?> updateTask(Task task) async {
    if (task.id == null) {
      return 'Task is missing an id';
    }
    try {
      final response = await dio.patch('tasks/${task.id}/', data: task.toJson());
      if (response.statusCode == 200) {
        return null;
      }
      return 'Could not save task';
    } on DioException catch (error) {
      return _messageFromError(error);
    }
  }

  Future<bool> deleteTask(int taskId) async {
    try {
      final response = await dio.delete('tasks/$taskId/');
      return response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getUserWorkload() async {
    try {
      final response = await dio.get('users/workload/');
      if (response.statusCode != 200 || response.data is! List) {
        return [];
      }
      return (response.data as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<String?> reassignTask(int taskId, int newAssigneeId) async {
    try {
      final response = await dio.patch(
        'tasks/$taskId/',
        data: {'assignee': newAssigneeId},
      );
      if (response.statusCode == 200) {
        return null;
      }
      return 'Could not reassign task';
    } on DioException catch (error) {
      return _messageFromError(error);
    }
  }

  Future<bool> updateTaskStatus(int taskId, String newStatus) async {
    try {
      final response = await dio.patch(
        'tasks/$taskId/',
        data: {'status': newStatus},
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateTaskPriority(int taskId, String newPriority) async {
    try {
      final response = await dio.patch(
        'tasks/$taskId/',
        data: {'priority': newPriority},
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<List<TaskComment>> getComments(int taskId) async {
    try {
      final response = await dio.get('tasks/$taskId/comments/');
      if (response.statusCode != 200 || response.data is! List) {
        return [];
      }
      return (response.data as List)
          .map((item) => TaskComment.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<String?> addComment(int taskId, String body) async {
    try {
      final response = await dio.post(
        'tasks/$taskId/comments/',
        data: {'body': body},
      );
      if (response.statusCode == 201) {
        return null;
      }
      return 'Could not add comment';
    } on DioException catch (error) {
      return _messageFromError(error);
    }
  }

  Future<Map<String, dynamic>> getDashboardCounts() async {
    try {
      final response = await dio.get('dashboard/');
      if (response.statusCode != 200 || response.data is! Map) {
        return {};
      }
      return Map<String, dynamic>.from(response.data as Map);
    } catch (_) {
      return {};
    }
  }

  String _messageFromError(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      if (data['detail'] is String) {
        return data['detail'] as String;
      }
      if (data['error'] is String) {
        return data['error'] as String;
      }
      final messages = <String>[];
      for (final value in data.values) {
        if (value is String) {
          messages.add(value);
        } else if (value is List && value.isNotEmpty) {
          messages.add(value.first.toString());
        }
      }
      if (messages.isNotEmpty) {
        return messages.join(' ');
      }
    }
    return 'Request failed';
  }
}
