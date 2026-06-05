import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'api_config.dart';
class ApiClient {
  static const String baseUrl = ApiConfig.baseUrl;

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

  Future<Map<String, dynamic>> scanNfcText({
    required String token,
    required String text,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/assets/nfc/scan'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'text': text}),
    );

    final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300 || body['success'] != true) {
      throw Exception(body['message'] ?? '读取 NFC 卡片失败');
    }
    return body['data'] as Map<String, dynamic>;
  }

  Future<void> claimNfcCard({required String token, required int cardId}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/assets/nfc/$cardId/claim'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300 || body['success'] != true) {
      throw Exception(body['message'] ?? '领取 NFC 卡片失败');
    }
  }

  Future<List<Map<String, dynamic>>> nfcCards({required String token}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/assets/nfc'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300 || body['success'] != true) {
      throw Exception(body['message'] ?? '获取 NFC 卡片失败');
    }
    final data = body['data'] as List<dynamic>? ?? const [];
    return data.whereType<Map<String, dynamic>>().toList(growable: false);
  }

  Future<void> bindNfcCharacter({
    required String token,
    required int cardId,
    required int characterCollectionId,
    required bool giftModeEnabled,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/api/assets/nfc/$cardId/character'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'characterCollectionId': characterCollectionId,
        'giftModeEnabled': giftModeEnabled,
      }),
    );

    final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300 || body['success'] != true) {
      throw Exception(body['message'] ?? '绑定 NFC 角色失败');
    }
  }

  Future<Map<String, dynamic>> customCharacterQuota({required String token}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/custom-characters/quota'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300 || body['success'] != true) {
      throw Exception(body['message'] ?? '获取上传额度失败');
    }
    return body['data'] as Map<String, dynamic>;
  }

  Future<void> uploadCustomCharacter({
    required String token,
    required Map<String, String> fields,
    required XFile image,
    XFile? video,
    XFile? audio,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/custom-characters'))
      ..headers['Authorization'] = 'Bearer $token'
      ..fields.addAll(fields)
      ..files.add(await _multipartFile('image', image));
    if (video != null) {
      request.files.add(await _multipartFile('video', video));
    }
    if (audio != null) {
      request.files.add(await _multipartFile('audio', audio));
    }

    final response = await http.Response.fromStream(await request.send());
    final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300 || body['success'] != true) {
      throw Exception(body['message'] ?? '上传自定义人物失败');
    }
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

  Future<http.MultipartFile> _multipartFile(String field, XFile file) async {
    return http.MultipartFile.fromBytes(
      field,
      await file.readAsBytes(),
      filename: file.name,
      contentType: _mediaTypeFor(field, file),
    );
  }

  MediaType? _mediaTypeFor(String field, XFile file) {
    final explicit = file.mimeType;
    if (explicit != null && explicit.isNotEmpty) {
      return MediaType.parse(explicit);
    }
    final name = file.name.toLowerCase();
    if (field == 'audio') {
      if (name.endsWith('.mp3')) return MediaType('audio', 'mpeg');
      if (name.endsWith('.wav')) return MediaType('audio', 'wav');
      if (name.endsWith('.m4a')) return MediaType('audio', 'mp4');
      if (name.endsWith('.aac')) return MediaType('audio', 'aac');
      if (name.endsWith('.ogg') || name.endsWith('.opus')) return MediaType('audio', 'ogg');
      if (name.endsWith('.webm')) return MediaType('audio', 'webm');
    }
    if (name.endsWith('.jpg') || name.endsWith('.jpeg')) return MediaType('image', 'jpeg');
    if (name.endsWith('.png')) return MediaType('image', 'png');
    if (name.endsWith('.webp')) return MediaType('image', 'webp');
    if (name.endsWith('.gif')) return MediaType('image', 'gif');
    if (name.endsWith('.mp4')) return MediaType('video', 'mp4');
    if (name.endsWith('.mov')) return MediaType('video', 'quicktime');
    if (name.endsWith('.m4v')) return MediaType('video', 'x-m4v');
    if (name.endsWith('.webm')) return MediaType('video', 'webm');
    return null;
  }

  Future<Map<String, dynamic>> giftDrawSummary({required String token}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/gifts/summary'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300 || body['success'] != true) {
      throw Exception(body['message'] ?? '获取抽奖次数失败');
    }
    return body['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> giftDraw({required String token}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/gifts/draw'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300 || body['success'] != true) {
      throw Exception(body['message'] ?? '抽奖失败');
    }
    return body['data'] as Map<String, dynamic>;
  }

  Future<String> giftMediaUrl({
    required String token,
    required String objectKey,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/gifts/media-url?objectKey=${Uri.encodeComponent(objectKey)}'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300 || body['success'] != true) {
      throw Exception(body['message'] ?? '获取媒体地址失败');
    }
    final data = body['data'] as Map<String, dynamic>;
    final path = data['url']?.toString() ?? '';
    if (path.startsWith('http')) return path;
    return '$baseUrl$path';
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
