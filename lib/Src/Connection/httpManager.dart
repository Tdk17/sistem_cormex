import 'package:sistem_cormex/Src/Config/appConfig.dart';
import 'package:sistem_cormex/Src/Connection/apiException.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

abstract final class HttpMethod {
  static const get = 'GET';
  static const post = 'POST';
  static const put = 'PUT';
  static const delete = 'DELETE';
  static const patch = 'PATCH';
}

class HttpManager {
  HttpManager(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> restRequest({
    required String url,
    required String method,
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    String? sessionToken,
  }) async {
    final requestHeaders = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-Parse-Application-Id': AppConfig.parseApplicationId,
      ...?headers,
    };

    if (kIsWeb) {
      requestHeaders['X-Parse-JavaScript-Key'] =
          AppConfig.parseJavaScriptKey;
    } else {
      requestHeaders['X-Parse-REST-API-Key'] = AppConfig.parseRestApiKey;
    }

    if (sessionToken != null && sessionToken.isNotEmpty) {
      requestHeaders['X-Parse-Session-Token'] = sessionToken;
    }

    try {
      AppConfig.ensureDatabaseConfigured(isWeb: kIsWeb);
      final response = await _dio.request<Map<String, dynamic>>(
        url,
        data: body,
        queryParameters: queryParameters,
        options: Options(method: method, headers: requestHeaders),
      );

      return response.data ?? <String, dynamic>{};
    } on DioException catch (error) {
      final responseData = error.response?.data;
      final data = responseData is Map
          ? Map<String, dynamic>.from(responseData)
          : <String, dynamic>{};

      throw ApiException(
        message: data['error']?.toString() ??
            error.message ??
            'Não foi possível se conectar ao servidor.',
        code: _asInt(data['code']),
        statusCode: error.response?.statusCode,
      );
    } on FormatException catch (error) {
      throw ApiException(message: error.message.toString());
    } catch (_) {
      throw const ApiException(
        message: 'Ocorreu um erro inesperado ao acessar o servidor.',
      );
    }
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }
}
