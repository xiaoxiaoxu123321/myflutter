import 'dart:convert';
import 'package:http/http.dart' as http;
class ApiClient {
  static const String baseUrl = 'https://www.myguanzhu.com';

  Future<Map<String, dynamic>> login({
    required String phone,
    required String code,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'code': code}),
    );

    final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300 || body['success'] != true) {
      throw Exception(body['message'] ?? '登录失败');
    }
    return body['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> currentUser({required String token}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/auth/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300 || body['success'] != true) {
      throw Exception(body['message'] ?? '获取用户信息失败');
    }
    return body['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateNickname({
    required String token,
    required String nickname,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/api/auth/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'nickname': nickname}),
    );

    final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300 || body['success'] != true) {
      throw Exception(body['message'] ?? '修改昵称失败');
    }
    return body['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> bindNfcText({
    required String token,
    required String text,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/assets/nfc/bind'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'text': text}),
    );

    final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300 || body['success'] != true) {
      throw Exception(body['message'] ?? '资产绑定失败');
    }
    return body['data'] as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> giftCollections({
    required String token,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/gifts/collections'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300 || body['success'] != true) {
      throw Exception(body['message'] ?? '获取资产失败');
    }
    final data = body['data'] as List<dynamic>? ?? const [];
    return data
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> plazaFeaturedBanners() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/plaza/featured-banners'),
    );

    final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300 || body['success'] != true) {
      throw Exception(body['message'] ?? '获取广场轮播图失败');
    }
    final data = body['data'] as List<dynamic>? ?? const [];
    return data
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> plazaCatalog() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/plaza/catalog'),
    );

    final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300 || body['success'] != true) {
      throw Exception(body['message'] ?? '获取全系列图鉴失败');
    }
    return body['data'] as Map<String, dynamic>;
  }

  Future<String> giftVideoProxyUrl({
    required String token,
    required String objectKey,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/gifts/video-proxy-url?objectKey=${Uri.encodeComponent(objectKey)}'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300 || body['success'] != true) {
      throw Exception(body['message'] ?? '获取视频地址失败');
    }
    final data = body['data'] as Map<String, dynamic>;
    final path = data['url']?.toString() ?? '';
    if (path.startsWith('http')) return path;
    return '$baseUrl$path';
  }
}
