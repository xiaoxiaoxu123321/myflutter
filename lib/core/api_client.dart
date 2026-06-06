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
      throw Exception(body['message'] ?? 'Login failed');
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
      throw Exception(body['message'] ?? 'Failed to get user info');
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
      throw Exception(body['message'] ?? 'Failed to update nickname');
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
      throw Exception(body['message'] ?? 'Failed to bind asset');
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
      throw Exception(body['message'] ?? 'Failed to read NFC card');
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
      throw Exception(body['message'] ?? 'Failed to claim NFC card');
    }
  }

  Future<List<Map<String, dynamic>>> nfcCards({required String token}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/assets/nfc'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to load NFC cards');
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
      throw Exception(body['message'] ?? 'Failed to bind NFC character');
    }
  }

  Future<Map<String, dynamic>> customCharacterQuota({required String token}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/custom-characters/quota'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to load upload quota');
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
    final body = _decodeResponse(response, fallbackMessage: 'Upload custom character failed');
    if (response.statusCode < 200 || response.statusCode >= 300 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Upload custom character failed');
    }
  }

  Future<Map<String, dynamic>> uploadCustomCharacterMedia({
    required String token,
    required XFile file,
    required String mediaType,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/custom-characters/media'))
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['mediaType'] = mediaType
      ..files.add(await _multipartFile('file', file));

    final response = await http.Response.fromStream(await request.send());
    final body = _decodeResponse(response, fallbackMessage: 'Upload custom character media failed');
    if (response.statusCode < 200 || response.statusCode >= 300 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Upload custom character media failed');
    }
    final data = body['data'] as Map<String, dynamic>;
    final url = data['url']?.toString() ?? '';
    final objectKey = data['objectKey']?.toString() ?? '';
    if (url.isEmpty || objectKey.isEmpty) {
      throw Exception('Upload custom character media failed: missing media url');
    }
    return data;
  }

  Future<void> saveCustomCharacter({
    required String token,
    required Map<String, String> fields,
    required Map<String, dynamic> image,
    Map<String, dynamic>? video,
    Map<String, dynamic>? audio,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/custom-characters/save'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        ...fields,
        'imageUrl': image['url']?.toString() ?? '',
        'imageObjectKey': image['objectKey']?.toString() ?? '',
        if (video != null) ...{
          'videoUrl': video['url']?.toString() ?? '',
          'videoObjectKey': video['objectKey']?.toString() ?? '',
        },
        if (audio != null) ...{
          'audioUrl': audio['url']?.toString() ?? '',
          'audioObjectKey': audio['objectKey']?.toString() ?? '',
        },
      }),
    );

    final body = _decodeResponse(response, fallbackMessage: 'Save custom character failed');
    if (response.statusCode < 200 || response.statusCode >= 300 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Save custom character failed');
    }
  }

  Map<String, dynamic> _decodeResponse(http.Response response, {required String fallbackMessage}) {
    final text = utf8.decode(response.bodyBytes, allowMalformed: true).trim();
    if (text.isEmpty) {
      throw Exception('$fallbackMessage: empty response (HTTP ${response.statusCode})');
    }
    if (text.startsWith('<')) {
      final lower = text.toLowerCase();
      final message = lower.contains('413') || lower.contains('request entity too large')
          ? 'Upload file is too large. Increase Nginx client_max_body_size for the domain proxy.'
          : '$fallbackMessage: server returned an HTML error page (HTTP ${response.statusCode}). Check /api proxy routing.';
      throw Exception(message);
    }
    try {
      return jsonDecode(text) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('$fallbackMessage: non-JSON response (HTTP ${response.statusCode})');
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
      throw Exception(body['message'] ?? 'Failed to load assets');
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
      throw Exception(body['message'] ?? 'Failed to load draw count');
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
      throw Exception(body['message'] ?? 'Draw failed');
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
      throw Exception(body['message'] ?? 'Failed to load media url');
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
      throw Exception(body['message'] ?? 'Failed to load plaza banners');
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
      throw Exception(body['message'] ?? 'Failed to load plaza catalog');
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
      throw Exception(body['message'] ?? 'Failed to load video url');
    }
    final data = body['data'] as Map<String, dynamic>;
    final path = data['url']?.toString() ?? '';
    if (path.startsWith('http')) return path;
    return '$baseUrl$path';
  }
}
