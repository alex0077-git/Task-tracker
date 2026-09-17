import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../models/app_user.dart';
import '../models/task.dart';

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

  final Dio dio = Dio(
    BaseOptions(
      baseUrl: 'http://192.168.0.102:8000/api/',
      headers: const {'Content-Type': 'application/json'},
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      extra: const {'withCredentials': true},
    ),
  );

  Future<bool> login(String username, String password) async {
    try {
      final response = await dio.post(
        'login/',
        data: {
          'username': username,
          'password': password,
        },
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
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

  Future<List<Task>> getTasks() async {
    try {
      final response = await dio.get('tasks/');
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

  Future<bool> createTask(Task task) async {
    try {
      final response = await dio.post('tasks/', data: task.toJson());
      return response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateTask(Task task) async {
    if (task.id == null) {
      return false;
    }
    try {
      final response = await dio.patch('tasks/${task.id}/', data: task.toJson());
      return response.statusCode == 200;
    } catch (_) {
      return false;
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

  Future<bool> reassignTask(int taskId, int newAssigneeId) async {
    try {
      final response = await dio.patch(
        'tasks/$taskId/',
        data: {'assignee': newAssigneeId},
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
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
}
