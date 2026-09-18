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
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_authToken != null && _authToken!.isNotEmpty) {
            options.headers['Authorization'] = 'Token $_authToken';
          }
          if (kIsWeb &&
              _csrfToken != null &&
              _csrfToken!.isNotEmpty &&
              options.method.toUpperCase() != 'GET' &&
              options.method.toUpperCase() != 'HEAD' &&
              options.method.toUpperCase() != 'OPTIONS') {
            options.headers['X-CSRFToken'] = _csrfToken;
          }
          handler.next(options);
        },
      ),
    );
  }

  static final ApiService instance = ApiService._();

  final CookieJar cookieJar = CookieJar();
  AppUser? currentUser;
  String? _authToken;
  String? _csrfToken;

  // Override at build/run time, e.g.:
  // flutter run --dart-define=API_BASE_URL=http://192.168.0.102:8000/api/
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000/api/',
  );

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

  Future<void> _ensureCsrfToken() async {
    if (!kIsWeb) {
      return;
    }
    final response = await dio.get('csrf/');
    if (response.statusCode == 200 && response.data is Map) {
      final token = response.data['csrfToken'];
      if (token is String && token.isNotEmpty) {
        _csrfToken = token;
      }
    }
  }

  Future<AppUser?> login(String username, String password) async {
    try {
      if (kIsWeb) {
        await _ensureCsrfToken();
      }
      final response = await dio.post(
        'login/',
        data: {
          'username': username,
          'password': password,
        },
      );
      if (response.statusCode != 200 || response.data is! Map) {
        currentUser = null;
        _authToken = null;
        return null;
      }
      final data = Map<String, dynamic>.from(response.data as Map);
      final token = data['token'];
      if (!kIsWeb && token is String && token.isNotEmpty) {
        _authToken = token;
      }
      currentUser = AppUser.fromJson(data);
      return currentUser;
    } catch (_) {
      currentUser = null;
      _authToken = null;
      return null;
    }
  }

  Future<void> logout() async {
    try {
      if (kIsWeb) {
        await _ensureCsrfToken();
      }
      await dio.post('logout/');
    } catch (_) {
      // Session/token cleared locally even if the server call fails.
    }
    currentUser = null;
    _authToken = null;
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
      if (kIsWeb) {
        await _ensureCsrfToken();
      }
      final response = await dio.post(
        'users/',
        data: {
          'username': username,
          'password': password,
          'is_manager': isStaff,
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

  Future<List<Task>> getTasks({
    bool overdueOnly = false,
    String? searchQuery,
    String? statusFilter,
    String? priorityFilter,
    int? assigneeFilter,
  }) async {
    try {
      final trimmedSearch = searchQuery?.trim();
      final response = await dio.get(
        'tasks/',
        queryParameters: {
          if (overdueOnly) 'overdue': 'true',
          if (trimmedSearch != null && trimmedSearch.isNotEmpty)
            'search': trimmedSearch,
          if (statusFilter != null && statusFilter.isNotEmpty)
            'status': statusFilter,
          if (priorityFilter != null && priorityFilter.isNotEmpty)
            'priority': priorityFilter,
          'assignee': ?assigneeFilter,
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
      if (kIsWeb) {
        await _ensureCsrfToken();
      }
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
      if (kIsWeb) {
        await _ensureCsrfToken();
      }
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
      if (kIsWeb) {
        await _ensureCsrfToken();
      }
      final response = await dio.delete('tasks/$taskId/');
      return response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  Future<String?> reassignTask(int taskId, int newAssigneeId) async {
    try {
      if (kIsWeb) {
        await _ensureCsrfToken();
      }
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
      if (kIsWeb) {
        await _ensureCsrfToken();
      }
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
      if (kIsWeb) {
        await _ensureCsrfToken();
      }
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
      if (kIsWeb) {
        await _ensureCsrfToken();
      }
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
