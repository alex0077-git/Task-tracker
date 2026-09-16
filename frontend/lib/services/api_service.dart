import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

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
      baseUrl: 'http://localhost:8000/api/',
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
}
