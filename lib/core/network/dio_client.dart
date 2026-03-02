import 'package:dio/dio.dart';

import '../constants/api_constants.dart';

/// Shared Dio client cho toàn app
class DioClient {
  DioClient._internal()
      : _dio = Dio(
          BaseOptions(
            baseUrl: ApiConstants.baseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
          ),
        );

  static final DioClient _instance = DioClient._internal();
  static DioClient get I => _instance;

  final Dio _dio;

  Dio get client => _dio;
}

