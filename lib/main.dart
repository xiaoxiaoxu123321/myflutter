import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:nfc_manager/nfc_manager_ios.dart';
import 'package:video_player/video_player.dart';
import 'features/plaza/plaza_page.dart';

void main() {
  runApp(const DimensionalApp());
}

class AuthSession {
  static bool isLoggedIn = false;
  static String? token;
  static Map<String, dynamic>? user;
}

class ApiClient {
  static const String baseUrl = 'http://192.168.3.60:8080';

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
      throw Exception(body['message'] ?? '绑定角色失败');
    }
  }

  Future<Map<String, dynamic>> giftDrawSummary({required String token}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/gifts/summary'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final body =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        body['success'] != true) {
      throw Exception(body['message'] ?? '获取抽奖次数失败');
    }
    return body['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> giftDraw({required String token}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/gifts/draw'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final body =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        body['success'] != true) {
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

    final body =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        body['success'] != true) {
      throw Exception(body['message'] ?? '获取视频地址失败');
    }
    final data = body['data'] as Map<String, dynamic>;
    return data['url']?.toString() ?? '';
  }

  Future<String> giftVideoProxyUrl({
    required String token,
    required String objectKey,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/gifts/video-proxy-url?objectKey=${Uri.encodeComponent(objectKey)}'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final body =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        body['success'] != true) {
      throw Exception(body['message'] ?? '获取视频地址失败');
    }
    final data = body['data'] as Map<String, dynamic>;
    final path = data['url']?.toString() ?? '';
    if (path.startsWith('http')) return path;
    return '$baseUrl$path';
  }

  Future<List<Map<String, dynamic>>> giftCollections({
    required String token,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/gifts/collections'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final body =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        body['success'] != true) {
      throw Exception(body['message'] ?? '鑾峰彇璧勪骇澶辫触');
    }
    final data = body['data'] as List<dynamic>? ?? const [];
    return data.whereType<Map<String, dynamic>>().toList(growable: false);
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
      ..files.add(http.MultipartFile.fromBytes('image', await image.readAsBytes(), filename: image.name));
    if (video != null) {
      request.files.add(http.MultipartFile.fromBytes('video', await video.readAsBytes(), filename: video.name));
    }
    if (audio != null) {
      request.files.add(http.MultipartFile.fromBytes('audio', await audio.readAsBytes(), filename: audio.name));
    }
    final response = await http.Response.fromStream(await request.send());
    final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300 || body['success'] != true) {
      throw Exception(body['message'] ?? '上传自定义人物失败');
    }
  }
}

class _NfcReadResult {
  const _NfcReadResult({required this.lines, this.text});

  final List<String> lines;
  final String? text;
}

class DimensionalApp extends StatelessWidget {
  const DimensionalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dimensional',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8D56FF),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF080613),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SafeArea(child: HomeShell()));
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  var _selectedIndex = 0;
  var _assetInitialTab = 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth > 520 ? 420.0 : double.infinity;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: Column(
                children: [
                  Expanded(
                    child: switch (_selectedIndex) {
                      1 => AssetPageBody(initialTab: _assetInitialTab),
                      2 => const GiftPageBody(),
                      3 => PlazaPageBody(
                        onOpenGift: () => setState(() => _selectedIndex = 2),
                      ),
                      4 => const ProfilePageBody(),
                      _ => HeroPanel(
                        onOpenMyCards: () => setState(() {
                          _assetInitialTab = 1;
                          _selectedIndex = 1;
                        }),
                      ),
                    },
                  ),
                  if (_selectedIndex == 0) ...[
                    const SizedBox(height: 10),
                    const TrackCard(),
                  ],
                  const SizedBox(height: 10),
                  BottomTabs(
                    selectedIndex: _selectedIndex,
                    onSelected: (index) => setState(() {
                      if (index == 1) _assetInitialTab = 0;
                      _selectedIndex = index;
                    }),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class HeroPanel extends StatefulWidget {
  const HeroPanel({super.key, required this.onOpenMyCards});

  final VoidCallback onOpenMyCards;

  @override
  State<HeroPanel> createState() => _HeroPanelState();
}

class _HeroPanelState extends State<HeroPanel> with WidgetsBindingObserver {
  final _apiClient = ApiClient();
  var _flashTrigger = 0;
  var _nfcMessage = '点击开始读取';
  var _nfcSubMessage = '点击后将卡片贴近手机NFC感应区';
  DateTime? _lastDiscoveryAt;
  var _nfcSessionStarted = false;
  var _nfcSessionStarting = false;
  var _iosTagReadCompleted = false;
  final _nfcTrace = <String>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    NfcManager.instance.stopSession().catchError((_) {});
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {}

  Future<void> _startNfcSession() async {
    if (_nfcSessionStarting || _nfcSessionStarted) return;
    _nfcSessionStarting = true;
    _resetNfcTrace('开始请求 NFC 会话');
    try {
      final availability = await NfcManager.instance.checkAvailability();
      _addNfcTrace('NFC 可用性：${availability.name}');
      if (!mounted) return;

      if (availability != NfcAvailability.enabled) {
        setState(() {
          _nfcMessage = 'NFC暂不可用';
          _nfcSubMessage = _nfcUnavailableMessage(availability);
        });
        _nfcSessionStarting = false;
        return;
      }

      setState(() {
        _nfcMessage = '请将卡片贴近';
        _nfcSubMessage = '手机NFC感应区';
      });
      _iosTagReadCompleted = false;

      await NfcManager.instance.startSession(
        pollingOptions: {
          NfcPollingOption.iso14443,
          if (defaultTargetPlatform != TargetPlatform.iOS)
            NfcPollingOption.iso15693,
        },
        onDiscovered: (tag) async {
          _addNfcTrace('系统已发现 NFC 标签');
          final now = DateTime.now();
          if (_lastDiscoveryAt != null &&
              now.difference(_lastDiscoveryAt!) <
                  const Duration(milliseconds: 900)) {
            return;
          }
          _lastDiscoveryAt = now;

          late final _NfcReadResult readResult;
          try {
            readResult = await _readTagData(tag);
            _addNfcTrace('NDEF 解析完成');
          } catch (error) {
            _addNfcTrace('NDEF 解析失败：$error');
            if (!mounted) return;
            setState(() {
              _nfcMessage = 'NFC标签解析失败';
              _nfcSubMessage = '请查看下方诊断信息';
            });
            return;
          }
          final dataLines = [...readResult.lines];
          dataLines.addAll(_nfcTrace);
          await _clearNfcSession(alertMessageIos: '读取成功');
          if (AuthSession.isLoggedIn && readResult.text != null) {
            await _bindNfcText(readResult.text!, dataLines);
          }
          if (!mounted) return;

          setState(() {
            _flashTrigger++;
            _nfcMessage = '已感应到卡片';
            _nfcSubMessage = AuthSession.isLoggedIn ? '数据已读取' : '请先登录';
          });
          _iosTagReadCompleted = true;
          _goLoginIfNeeded(dataLines, readResult.text);
        },
        onSessionErrorIos: (error) {
          _nfcSessionStarted = false;
          _clearIosNfcSession();
          if (_iosTagReadCompleted) return;
          _addNfcTrace('iOS 会话结束：${error.code.name}');
          if (!mounted) return;
          final message = _iosNfcSessionMessage(error);
          setState(() {
            _nfcMessage = message.title;
            _nfcSubMessage = message.subtitle;
          });
        },
        alertMessageIos: '请将 NFC 标签靠近 iPhone 顶部。',
        invalidateAfterFirstReadIos: false,
      );
      _nfcSessionStarted = true;
      _addNfcTrace('NFC 会话已提交，等待系统发现标签');
    } catch (error) {
      _nfcSessionStarted = false;
      if (!mounted) return;
      setState(() {
        _nfcMessage = 'NFC监听未启动';
        _nfcSubMessage = '请确认设备支持NFC';
      });
    } finally {
      _nfcSessionStarting = false;
    }
  }

  void _resetNfcTrace(String message) {
    _nfcTrace
      ..clear()
      ..add('${_timeText(DateTime.now())} $message');
  }

  void _addNfcTrace(String message) {
    _nfcTrace.add('${_timeText(DateTime.now())} $message');
  }

  Future<void> _clearIosNfcSession({String? alertMessageIos}) async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
    await _clearNfcSession(alertMessageIos: alertMessageIos);
  }

  Future<void> _clearNfcSession({String? alertMessageIos}) async {
    try {
      await NfcManager.instance.stopSession(alertMessageIos: alertMessageIos);
    } catch (_) {}
    _nfcSessionStarted = false;
    _nfcSessionStarting = false;
  }

  String _nfcUnavailableMessage(NfcAvailability availability) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'iPhone 无 NFC 开关，请检查机型和签名权限';
    }
    if (availability == NfcAvailability.disabled) {
      return '请在系统设置中开启 NFC 后返回应用';
    }
    return '当前设备不支持 NFC 读取';
  }

  ({String title, String subtitle}) _iosNfcSessionMessage(
    NfcReaderSessionErrorIos error,
  ) {
    return switch (error.code) {
      NfcReaderErrorCodeIos.readerSessionInvalidationErrorFirstNDEFTagRead => (
        title: 'NFC读取完成',
        subtitle: '已读取标签内容',
      ),
      NfcReaderErrorCodeIos.readerSessionInvalidationErrorUserCanceled => (
        title: 'NFC读取已取消',
        subtitle: '需要读取时请重新进入页面',
      ),
      NfcReaderErrorCodeIos.readerSessionInvalidationErrorSessionTimeout => (
        title: 'NFC读取已超时',
        subtitle: '请重新进入页面后再试',
      ),
      _ => (
        title: 'NFC读取异常',
        subtitle: '请点击中间 NFC 图标重试',
      ),
    };
  }

  Future<_NfcReadResult> _readTagData(NfcTag tag) async {
    final lines = <String>['读取时间：${_timeText(DateTime.now())}'];
    String? nfcText;
    final isIos = defaultTargetPlatform == TargetPlatform.iOS;
    final androidTag = isIos ? null : NfcTagAndroid.from(tag);
    final androidNdef = isIos ? null : NdefAndroid.from(tag);
    final iosNdef = isIos ? NdefIos.from(tag) : null;
    final message = androidNdef != null
        ? await androidNdef.getNdefMessage()
        : iosNdef?.cachedNdefMessage ?? await iosNdef?.readNdef();

    if (androidTag != null) {
      lines.add('Tag ID：${_hex(androidTag.id)}');
      lines.add('Tech：${androidTag.techList.join(', ')}');
    } else {
      lines.add('已发现 iOS NFC 标签');
    }

    if (androidNdef == null && iosNdef == null) {
      lines.add('NDEF：不支持或没有 NDEF 数据');
      return _NfcReadResult(lines: lines);
    }

    if (androidNdef != null) {
      lines.add('NDEF 类型：${androidNdef.type}');
      lines.add('可写入：${androidNdef.isWritable ? '是' : '否'}');
      lines.add('最大容量：${androidNdef.maxSize} bytes');
    } else {
      lines.add('NDEF 状态：${iosNdef!.status.name}');
      lines.add('最大容量：${iosNdef.capacity} bytes');
    }

    final records = message?.records ?? const [];
    lines.add('记录数量：${records.length}');

    for (var i = 0; i < records.length; i++) {
      final record = records[i];
      lines.add('Record ${i + 1}');
      lines.add('  TNF：${record.typeNameFormat.name}');
      lines.add('  Type：${_asciiOrHex(record.type)}');
      lines.add('  Payload(hex)：${_hex(record.payload)}');
      final text = _decodeNdefPayload(record.type, record.payload);
      if (text.isNotEmpty) {
        nfcText ??= text.trim();
        lines.add('  Payload(text)：$text');
      }
    }

    return _NfcReadResult(lines: lines, text: nfcText);
  }

  String _timeText(DateTime value) {
    return '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}:'
        '${value.second.toString().padLeft(2, '0')}';
  }

  String _hex(Uint8List bytes) {
    if (bytes.isEmpty) return '-';
    return bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join(' ');
  }

  String _asciiOrHex(Uint8List bytes) {
    if (bytes.isEmpty) return '-';
    final text = ascii.decode(bytes, allowInvalid: true);
    final readable = text.runes.every((rune) => rune >= 32 && rune <= 126);
    return readable ? text : _hex(bytes);
  }

  String _decodeNdefPayload(Uint8List type, Uint8List payload) {
    if (payload.isEmpty) return '';

    final typeText = ascii.decode(type, allowInvalid: true);
    if (typeText == 'T' && payload.length >= 2) {
      final languageLength = payload.first & 0x3F;
      final textStart = 1 + languageLength;
      if (textStart < payload.length) {
        return utf8.decode(payload.sublist(textStart), allowMalformed: true);
      }
    }

    if (typeText == 'U' && payload.length >= 2) {
      const prefixes = [
        '',
        'http://www.',
        'https://www.',
        'http://',
        'https://',
      ];
      final prefix = payload.first < prefixes.length
          ? prefixes[payload.first]
          : '';
      return prefix + utf8.decode(payload.sublist(1), allowMalformed: true);
    }

    return utf8.decode(payload, allowMalformed: true).trim();
  }

  Future<void> _bindNfcText(String text, List<String> lines) async {
    final token = AuthSession.token;
    if (token == null || token.isEmpty) {
      lines.add('资产绑定：请先登录');
      return;
    }

    try {
      final scan = await _apiClient.scanNfcText(token: token, text: text);
      if (scan['status'] == 'AVAILABLE') {
        final asset = await _apiClient.bindNfcText(token: token, text: text);
        final title = asset['title']?.toString() ?? text;
        lines.add('资产绑定成功：$title');
        if (mounted) await _showNfcBindSuccess(title);
        return;
      }
      lines.add('已读取已绑定 NFC 卡片');
      if (mounted) await _showOwnedNfcCard(scan, token);
    } catch (error) {
      lines.add('NFC 处理失败：${error.toString().replaceFirst('Exception: ', '')}');
    }
  }

  Future<void> _showNfcBindSuccess(String title) async {
    final openCards = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('绑卡成功'),
        content: Text('“$title”已绑定到你的账户。'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('知道了')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('查看我的卡片')),
        ],
      ),
    );
    if (openCards == true && mounted) widget.onOpenMyCards();
  }

  Future<void> _showOwnedNfcCard(Map<String, dynamic> card, String token) async {
    final cardId = (card['cardId'] as num?)?.toInt();
    final title = card['title']?.toString() ?? 'NFC 卡片';
    final characterName = card['characterName']?.toString();
    final rarity = card['rarity']?.toString();
    final imageUrl = card['coverImageUrl']?.toString();
    final ownedByCurrentUser = card['ownedByCurrentUser'] == true;
    final giftModeEnabled = card['giftModeEnabled'] == true;
    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 150,
                height: 190,
                decoration: BoxDecoration(
                  color: const Color(0xFF17142A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF7045C9)),
                  image: imageUrl == null || imageUrl.isEmpty
                      ? null
                      : DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover),
                ),
                child: imageUrl == null || imageUrl.isEmpty
                    ? const Icon(Icons.star_border_rounded, size: 76, color: Color(0xFFD9C4FF))
                    : null,
              ),
              const SizedBox(height: 14),
              Text(characterName == null || characterName.isEmpty ? '该卡片暂未绑定角色' : characterName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
              if (rarity != null && rarity.isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(rarity, style: const TextStyle(color: Color(0xFFC5A7FF))),
              ],
              const SizedBox(height: 9),
              Text(
                ownedByCurrentUser
                    ? '这是你已经绑定的卡片'
                    : giftModeEnabled
                        ? '原持有者已开启赠送模式，可以领取该卡片'
                        : '该卡片已被其他用户绑定',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFB8B2CE), fontSize: 13),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('关闭')),
          if (ownedByCurrentUser)
            FilledButton(onPressed: () => Navigator.of(context).pop('cards'), child: const Text('查看我的卡片')),
          if (!ownedByCurrentUser && giftModeEnabled && cardId != null)
            FilledButton(onPressed: () => Navigator.of(context).pop('claim'), child: const Text('领取卡片')),
        ],
      ),
    );
    if (!mounted) return;
    if (action == 'cards') {
      widget.onOpenMyCards();
      return;
    }
    if (action == 'claim' && cardId != null) {
      try {
        await _apiClient.claimNfcCard(token: token, cardId: cardId);
        if (!mounted) return;
        await _showNfcBindSuccess(title);
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _handleNfcOrbTap() async {
    if (_nfcSessionStarted || _nfcSessionStarting) return;
    await _clearNfcSession();
    await _startNfcSession();
  }

  void _goLoginIfNeeded(List<String> nfcDataLines, String? nfcText) {
    if (AuthSession.isLoggedIn) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LoginPage(
          nfcDataLines: nfcDataLines,
          nfcText: nfcText,
        ),
      ),
    ).then((loggedIn) async {
      if (loggedIn != true || nfcText == null || nfcText.isEmpty) return;
      await _bindNfcText(nfcText, nfcDataLines);
      if (!mounted) return;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0A0920),
                  Color(0xFF171039),
                  Color(0xFF160C2F),
                  Color(0xFF080613),
                ],
              ),
            ),
          ),
          const CustomPaint(painter: StarfieldPainter()),
          Positioned.fill(
            child: Image.asset(
              'assets/images/backages.png',
              fit: BoxFit.cover,
            ),
          ),
          const Positioned.fill(child: VignetteLayer()),
          const Positioned(top: 10, left: 12, right: 12, child: TopBar()),
          const Positioned(top: 56, left: 0, right: 0, child: TitleBlock()),
          Positioned(
            left: 0,
            right: 0,
            bottom: 86,
            child: Center(
              child: NfcOrb(flashTrigger: _flashTrigger, onTap: _handleNfcOrbTap),
            ),
          ),
          Positioned(
            left: 22,
            right: 22,
            bottom: 18,
            child: HintText(message: _nfcMessage, subMessage: _nfcSubMessage),
          ),
        ],
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.nfcDataLines,
    this.nfcText,
  });

  final List<String> nfcDataLines;
  final String? nfcText;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController(text: '123456');
  final _apiClient = ApiClient();
  var _accepted = true;
  var _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_accepted) return;
    final phone = _phoneController.text.trim();
    final code = _codeController.text.trim();

    if (phone.isEmpty || code.isEmpty) {
      setState(() => _errorMessage = '请输入手机号和验证码');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    var loginSucceeded = false;
    try {
      final data = await _apiClient.login(phone: phone, code: code);
      AuthSession.isLoggedIn = true;
      AuthSession.token = data['token'] as String?;
      AuthSession.user = data['user'] as Map<String, dynamic>?;
      loginSucceeded = true;
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted && !loginSucceeded) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth > 520
                ? 420.0
                : double.infinity;
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Stack(
                  children: [
                    const Positioned.fill(child: LoginBackground()),
                    SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - 24,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                              ),
                              color: Colors.white,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints.tightFor(
                                width: 36,
                                height: 36,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              '欢迎回来',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 25,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              '与专属人格再次相遇',
                              style: TextStyle(
                                color: Color(0xFFC8BEDF),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0,
                              ),
                            ),
                            const SizedBox(height: 36),
                            const Center(child: PlanetMark()),
                            const SizedBox(height: 30),
                            LoginInput(
                              icon: Icons.phone_iphone_rounded,
                              hintText: '请输入手机号',
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 12),
                            LoginInput(
                              icon: Icons.lock_outline_rounded,
                              hintText: '请输入验证码',
                              actionText: '固定验证码 123456',
                              controller: _codeController,
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 17),
                            if (_errorMessage != null) ...[
                              Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: Color(0xFFFF9BA6),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: FilledButton(
                                onPressed: _accepted && !_loading ? _login : null,
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF8350DC),
                                  disabledBackgroundColor: const Color(
                                    0xFF3B2E55,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  '登录 / 注册',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),
                            const DividerWithText(text: '其他方式登录'),
                            const SizedBox(height: 18),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SocialLoginButton(
                                  icon: Icons.wechat_rounded,
                                  label: '微信',
                                ),
                                SizedBox(width: 42),
                                SocialLoginButton(
                                  icon: Icons.apple_rounded,
                                  label: 'Apple',
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: _accepted,
                                    onChanged: (value) => setState(
                                      () => _accepted = value ?? false,
                                    ),
                                    activeColor: const Color(0xFF8E5AFF),
                                    side: const BorderSide(
                                      color: Color(0xFF8E79C7),
                                    ),
                                    shape: const CircleBorder(),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Expanded(
                                  child: Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(text: '我已阅读并同意 '),
                                        TextSpan(
                                          text: '《用户协议》',
                                          style: TextStyle(
                                            color: Color(0xFFC47BFF),
                                          ),
                                        ),
                                        TextSpan(text: ' 和 '),
                                        TextSpan(
                                          text: '《隐私政策》',
                                          style: TextStyle(
                                            color: Color(0xFFC47BFF),
                                          ),
                                        ),
                                      ],
                                    ),
                                    style: TextStyle(
                                      color: Color(0xFFBEB0D8),
                                      fontSize: 11,
                                      height: 1.35,
                                      letterSpacing: 0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class LoginBackground extends StatelessWidget {
  const LoginBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A0820), Color(0xFF151031), Color(0xFF0B0919)],
        ),
      ),
      child: CustomPaint(painter: LoginBackgroundPainter()),
    );
  }
}

class LoginBackgroundPainter extends CustomPainter {
  const LoginBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeWidth = 1.2;
    final points = <Offset>[];
    for (var i = 0; i < 34; i++) {
      final x = (math.sin(i * 19.3) * 10000).abs() % size.width;
      final y = (math.cos(i * 33.7) * 10000).abs() % (size.height * 0.48);
      points.add(Offset(x, y));
    }

    paint.color = const Color(0x553666B8);
    for (var i = 0; i < points.length - 1; i += 3) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }

    for (final point in points) {
      canvas.drawCircle(point, 1.8, Paint()..color = const Color(0xFF805CFF));
    }

    final cityPaint = Paint()..color = const Color(0x221B2F68);
    for (var i = 0; i < 18; i++) {
      final width = 12 + (i % 4) * 6.0;
      final height = 54 + (i % 5) * 18.0;
      canvas.drawRect(
        Rect.fromLTWH(i * size.width / 17, size.height * 0.28, width, height),
        cityPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PlanetMark extends StatelessWidget {
  const PlanetMark({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 124,
      height: 94,
      child: CustomPaint(painter: PlanetPainter()),
    );
  }
}

class PlanetPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.48);
    final star = Path()
      ..moveTo(center.dx, 8)
      ..lineTo(center.dx + 11, center.dy - 8)
      ..lineTo(size.width - 10, center.dy - 1)
      ..lineTo(center.dx + 15, center.dy + 11)
      ..lineTo(center.dx + 21, size.height - 9)
      ..lineTo(center.dx, center.dy + 18)
      ..lineTo(center.dx - 21, size.height - 9)
      ..lineTo(center.dx - 15, center.dy + 11)
      ..lineTo(10, center.dy - 1)
      ..lineTo(center.dx - 11, center.dy - 8)
      ..close();

    canvas.drawPath(star, Paint()..color = const Color(0xFFF4ECFF));
    canvas.drawArc(
      Rect.fromCenter(
        center: center,
        width: size.width * 0.95,
        height: size.height * 0.42,
      ),
      -0.24,
      math.pi * 1.25,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..color = const Color(0x995D3FD1),
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: center,
        width: size.width * 0.86,
        height: size.height * 0.34,
      ),
      -3.0,
      math.pi * 1.5,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFF5EFFF),
    );
    canvas.drawLine(
      Offset(size.width * 0.76, size.height * 0.72),
      Offset(size.width * 0.84, size.height * 0.82),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LoginInput extends StatelessWidget {
  const LoginInput({
    super.key,
    required this.icon,
    required this.hintText,
    required this.controller,
    required this.keyboardType,
    this.actionText,
  });

  final IconData icon;
  final String hintText;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final String? actionText;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 47,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        color: const Color(0xC1111025),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF31284A)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFB6A9D5), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: hintText,
                hintStyle: const TextStyle(
                  color: Color(0xFF7D728E),
                  fontSize: 13,
                ),
              ),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              keyboardType: keyboardType,
            ),
          ),
          if (actionText != null)
            Text(
              actionText!,
              style: const TextStyle(
                color: Color(0xFFC47BFF),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}

class DividerWithText extends StatelessWidget {
  const DividerWithText({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFF2C2443))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            text,
            style: const TextStyle(color: Color(0xFF8E82A4), fontSize: 12),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFF2C2443))),
      ],
    );
  }
}

class SocialLoginButton extends StatelessWidget {
  const SocialLoginButton({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: Color(0xFF222038),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 7),
        Text(
          label,
          style: const TextStyle(color: Color(0xFFD6CDE8), fontSize: 12),
        ),
      ],
    );
  }
}

class TopBar extends StatelessWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _IconBadge(icon: Icons.home_rounded),
        const Spacer(),
        _SignalBar(width: 4, height: 7),
        const SizedBox(width: 3),
        _SignalBar(width: 4, height: 10),
        const SizedBox(width: 3),
        _SignalBar(width: 4, height: 13),
        const SizedBox(width: 8),
        const Icon(Icons.wifi_rounded, size: 16, color: Colors.white),
        const SizedBox(width: 8),
        Container(
          width: 22,
          height: 11,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 1.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 15,
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class TitleBlock extends StatelessWidget {
  const TitleBlock({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text(
          '去碰一下',
          style: TextStyle(
            color: Color(0xFFC990FF),
            fontSize: 29,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
            shadows: [Shadow(color: Color(0xFF9F4DFF), blurRadius: 18)],
          ),
        ),
        SizedBox(height: 3),
        Text(
          '遇见你的专属人格',
          style: TextStyle(
            color: Color(0xFFEAE2FF),
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class CharacterArt extends StatelessWidget {
  const CharacterArt({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: CharacterPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class NfcOrb extends StatefulWidget {
  const NfcOrb({super.key, required this.flashTrigger, required this.onTap});

  final int flashTrigger;
  final VoidCallback onTap;

  @override
  State<NfcOrb> createState() => _NfcOrbState();
}

class _NfcOrbState extends State<NfcOrb> with SingleTickerProviderStateMixin {
  late final AnimationController _flashController;

  @override
  void initState() {
    super.initState();
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    );
  }

  @override
  void dispose() {
    _flashController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant NfcOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.flashTrigger != oldWidget.flashTrigger) {
      _flashController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        widget.onTap();
        _flashController.forward(from: 0);
      },
      child: SizedBox(
        width: 178,
        height: 178,
        child: AnimatedBuilder(
          animation: _flashController,
          builder: (context, child) {
            final flash = Curves.easeOutCubic.transform(_flashController.value);
            final pulse = math.sin(_flashController.value * math.pi);

            return Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size.square(178),
                  painter: _NfcFlashPainter(progress: flash, pulse: pulse),
                ),
                Transform.scale(
                  scale: 1 + pulse * 0.08,
                  child: Container(
                    width: 128,
                    height: 128,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Color.lerp(
                            const Color(0xFF3A1B66),
                            Colors.white,
                            pulse * 0.22,
                          )!,
                          Color.lerp(
                            const Color(0xFF7A2CFA),
                            const Color(0xFFE3A8FF),
                            pulse * 0.38,
                          )!,
                          const Color(0xFF150B2D),
                        ],
                        stops: const [0, 0.64, 1],
                      ),
                      border: Border.all(
                        color: Color.lerp(
                          const Color(0xFFD994FF),
                          Colors.white,
                          pulse,
                        )!,
                        width: 2 + pulse * 1.6,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color.lerp(
                            const Color(0xAA9E4DFF),
                            Colors.white,
                            pulse * 0.55,
                          )!,
                          blurRadius: 34 + pulse * 30,
                          spreadRadius: 3 + pulse * 7,
                        ),
                        BoxShadow(
                          color: const Color(
                            0xAAE599FF,
                          ).withValues(alpha: 0.45 + pulse * 0.45),
                          blurRadius: 10 + pulse * 18,
                          spreadRadius: -2 + pulse * 4,
                        ),
                      ],
                    ),
                    child: child,
                  ),
                ),
              ],
            );
          },
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_rounded, color: Colors.white, size: 35),
              SizedBox(height: 4),
              Text(
                'NFC',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '碰一下',
                style: TextStyle(
                  color: Color(0xFFF1E8FF),
                  fontSize: 12,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NfcFlashPainter extends CustomPainter {
  const _NfcFlashPainter({required this.progress, required this.pulse});

  final double progress;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    for (var i = 0; i < 3; i++) {
      final offsetProgress = (progress - i * 0.13).clamp(0.0, 1.0);
      final opacity = (1 - offsetProgress).clamp(0.0, 1.0);
      if (offsetProgress <= 0 || opacity <= 0) continue;

      canvas.drawCircle(
        center,
        58 + offsetProgress * (58 + i * 12),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2 - i * 0.35
          ..color = const Color(0xFFEFC6FF).withValues(alpha: opacity * 0.72),
      );
    }

    final fade = (1 - progress).clamp(0.0, 1.0);
    final flashPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFFFEFFF).withValues(alpha: fade * 0.95);

    final sparkles = [
      (angle: -math.pi / 2, distance: 64.0, radius: 12.0),
      (angle: -0.22, distance: 76.0, radius: 15.0),
      (angle: math.pi * 0.72, distance: 72.0, radius: 10.0),
      (angle: math.pi * 1.18, distance: 68.0, radius: 9.0),
    ];

    for (final sparkle in sparkles) {
      final distance = sparkle.distance + progress * 18;
      final point = Offset(
        center.dx + math.cos(sparkle.angle) * distance,
        center.dy + math.sin(sparkle.angle) * distance,
      );
      final radius = sparkle.radius * (0.5 + pulse * 0.7);
      canvas.drawLine(
        point.translate(-radius, 0),
        point.translate(radius, 0),
        flashPaint,
      );
      canvas.drawLine(
        point.translate(0, -radius),
        point.translate(0, radius),
        flashPaint,
      );
    }

    final beamPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFFFFFFF).withValues(alpha: fade * 0.42);

    for (var i = 0; i < 12; i++) {
      final angle = i * math.pi / 6 + progress * 0.3;
      final inner = 46 + progress * 18;
      final outer = 78 + progress * 28;
      canvas.drawLine(
        Offset(
          center.dx + math.cos(angle) * inner,
          center.dy + math.sin(angle) * inner,
        ),
        Offset(
          center.dx + math.cos(angle) * outer,
          center.dy + math.sin(angle) * outer,
        ),
        beamPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _NfcFlashPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.pulse != pulse;
  }
}

class HintText extends StatelessWidget {
  const HintText({super.key, required this.message, required this.subMessage});

  final String message;
  final String subMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFE6D4FF),
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subMessage,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFE6D4FF),
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class TrackCard extends StatelessWidget {
  const TrackCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFF17142B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF362960)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const CoverThumb(),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '月海型 · 缪',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  '心象频率系列',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFFB6A8DA),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF211B3A),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: const Color(0xFF625086)),
            ),
            child: const Icon(
              Icons.favorite_border_rounded,
              color: Color(0xFFF6ECFF),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class GiftPageBody extends StatefulWidget {
  const GiftPageBody({super.key});

  @override
  State<GiftPageBody> createState() => _GiftPageBodyState();
}

class _GiftPageBodyState extends State<GiftPageBody> {
  final _apiClient = ApiClient();
  var _loading = false;
  var _availableDrawCount = 0;
  String? _errorMessage;

  static const _characters = [
    GiftCharacterData('月海型 · 缪', '限定', Color(0xFF8E62FF), 0),
    GiftCharacterData('狐影型 · 光', '限定', Color(0xFFFF8A73), 1),
    GiftCharacterData('梦魇型 · 璃夜', '隐藏款', Color(0xFFFF5E93), 2),
  ];

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    final token = AuthSession.token;
    if (token == null || token.isEmpty) {
      setState(() {
        _availableDrawCount = 0;
        _errorMessage = '请先登录后查看抽奖次数';
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final data = await _apiClient.giftDrawSummary(token: token);
      if (!mounted) return;
      setState(() {
        _availableDrawCount =
            int.tryParse(data['availableDrawCount']?.toString() ?? '') ?? 0;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _drawGift() async {
    final token = AuthSession.token;
    if (token == null || token.isEmpty) {
      setState(() => _errorMessage = '请先登录后再抽奖');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final data = await _apiClient.giftDraw(token: token);
      if (!mounted) return;
      setState(() {
        _availableDrawCount =
            int.tryParse(data['availableDrawCount']?.toString() ?? '') ?? 0;
      });
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => GiftDrawAnimationPage(result: GiftDrawResult.fromJson(data)),
        ),
      );
      if (mounted) {
        _loadSummary();
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF101534),
                  Color(0xFF0A0E24),
                  Color(0xFF080713),
                ],
              ),
            ),
          ),
          const CustomPaint(painter: GiftPageBackgroundPainter()),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 11, 14, 14),
            child: Column(
              children: [
                SizedBox(
                  height: 34,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.arrow_back_ios_new_rounded),
                          color: Colors.white,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints.tightFor(
                            width: 32,
                            height: 32,
                          ),
                        ),
                      ),
                      const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '开盲盒 ✨',
                            style: TextStyle(
                              color: Color(0xFFE9C4FF),
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                              shadows: [
                                Shadow(
                                  color: Color(0xFF9F4DFF),
                                  blurRadius: 16,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 1),
                          Text(
                            '遇见你的专属人格',
                            style: TextStyle(
                              color: Color(0xFFEDE5FF),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                GiftDrawCountCard(
                  availableDrawCount: _availableDrawCount,
                  loading: _loading,
                  errorMessage: _errorMessage,
                  onRefresh: _loadSummary,
                ),
                const SizedBox(height: 14),
                const GiftSectionHeader(),
                const SizedBox(height: 8),
                SizedBox(
                  height: 180,
                  child: Row(
                    children: [
                      for (var i = 0; i < _characters.length; i++) ...[
                        Expanded(
                          child: GiftCharacterCard(data: _characters[i]),
                        ),
                        if (i != _characters.length - 1)
                          const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed:
                        _availableDrawCount > 0 && !_loading ? _drawGift : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF7B43DB),
                      disabledBackgroundColor: const Color(0xFF35244F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    child: const Text('立即开盲盒'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GiftDrawResult {
  const GiftDrawResult({
    required this.name,
    required this.rarity,
    required this.coverImageUrl,
    this.coverImageObjectKey,
    this.previewVideoUrl,
    this.previewVideoObjectKey,
    this.description,
  });

  final String name;
  final String rarity;
  final String coverImageUrl;
  final String? coverImageObjectKey;
  final String? previewVideoUrl;
  final String? previewVideoObjectKey;
  final String? description;

  factory GiftDrawResult.fromJson(Map<String, dynamic> json) {
    return GiftDrawResult(
      name: json['name']?.toString() ?? '',
      rarity: json['rarity']?.toString() ?? '',
      description: json['description']?.toString(),
      coverImageUrl: json['coverImageUrl']?.toString() ?? '',
      coverImageObjectKey: json['coverImageObjectKey']?.toString(),
      previewVideoUrl: json['previewVideoUrl']?.toString(),
      previewVideoObjectKey: json['previewVideoObjectKey']?.toString(),
    );
  }
}

class GiftDrawAnimationPage extends StatefulWidget {
  const GiftDrawAnimationPage({super.key, required this.result});

  final GiftDrawResult result;

  @override
  State<GiftDrawAnimationPage> createState() => _GiftDrawAnimationPageState();
}

class _GiftDrawAnimationPageState extends State<GiftDrawAnimationPage>
    with SingleTickerProviderStateMixin {
  static const _nativeVideoChannel = MethodChannel('dimensional/native_video');

  late final AnimationController _controller;
  final _apiClient = ApiClient();
  var _revealed = false;
  var _loadingVideo = false;
  String? _videoErrorMessage;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    Future.delayed(const Duration(milliseconds: 2600), () {
      if (!mounted) return;
      _controller.stop();
      setState(() => _revealed = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openVideo() async {
    if (!_revealed || _loadingVideo) return;
    final objectKey = widget.result.previewVideoObjectKey;
    final fallbackUrl = widget.result.previewVideoUrl;
    if ((objectKey == null || objectKey.isEmpty) &&
        (fallbackUrl == null || fallbackUrl.isEmpty)) {
      setState(() => _videoErrorMessage = '暂无可播放视频');
      return;
    }

    setState(() {
      _loadingVideo = true;
      _videoErrorMessage = null;
    });

    try {
      var videoUrl = fallbackUrl ?? '';
      final token = AuthSession.token;
      if (objectKey != null && objectKey.isNotEmpty && token != null) {
        videoUrl = await _apiClient.giftVideoProxyUrl(
          token: token,
          objectKey: objectKey,
        );
      }
      if (!mounted) return;
      final opened = await _openNativeVideo(videoUrl);
      if (!opened && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GiftVideoPage(
              title: widget.result.name,
              videoUrl: videoUrl,
            ),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _videoErrorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _loadingVideo = false);
      }
    }
  }

  Future<bool> _openNativeVideo(String videoUrl) async {
    try {
      final opened = await _nativeVideoChannel.invokeMethod<bool>(
        'openVideo',
        {
          'url': videoUrl,
          'title': widget.result.name,
        },
      );
      return opened == true;
    } on MissingPluginException {
      return false;
    } on PlatformException catch (error) {
      if (mounted) {
        setState(() => _videoErrorMessage = error.message ?? '原生播放器打开失败');
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth > 520 ? 420.0 : double.infinity;
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xFF0D1028),
                                Color(0xFF090A1B),
                                Color(0xFF060612),
                              ],
                            ),
                          ),
                        ),
                        const CustomPaint(painter: GiftPageBackgroundPainter()),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_back_ios_new_rounded),
                            color: Colors.white,
                          ),
                        ),
                        Positioned(
                          top: 38,
                          left: 0,
                          right: 0,
                          child: Column(
                            children: [
                              Text(
                                _revealed ? '抽中了！' : '抽奖中...',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _revealed
                                    ? '${widget.result.rarity} · ${widget.result.name}'
                                    : '正在为你匹配最适合的人格',
                                style: const TextStyle(
                                  color: Color(0xFFDCCFFF),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Center(
                          child: AnimatedBuilder(
                            animation: _controller,
                            builder: (context, child) {
                              final sway = math.sin(_controller.value * math.pi * 2);
                              final flip = math.sin(_controller.value * math.pi * 2.2);
                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  CustomPaint(
                                    size: const Size(280, 360),
                                    painter: GiftDrawMagicPainter(
                                      progress: _controller.value,
                                      revealed: _revealed,
                                    ),
                                  ),
                                  Transform.translate(
                                    offset: Offset(0, _revealed ? 0 : sway * 9),
                                    child: Transform(
                                      alignment: Alignment.center,
                                      transform: Matrix4.identity()
                                        ..setEntry(3, 2, 0.0016)
                                        ..rotateY(_revealed ? 0 : flip * 0.72)
                                        ..rotateZ(_revealed ? 0 : sway * 0.08),
                                      child: child,
                                    ),
                                  ),
                                ],
                              );
                            },
                            child: GestureDetector(
                              onTap: _openVideo,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 500),
                                width: _revealed ? 276 : 132,
                                height: _revealed ? 491 : 180,
                                padding: EdgeInsets.all(_revealed ? 0 : 5),
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.circular(_revealed ? 0 : 16),
                                  gradient: _revealed
                                      ? null
                                      : const LinearGradient(
                                          colors: [
                                            Color(0xFFF1C8FF),
                                            Color(0xFF8E4DFF),
                                            Color(0xFF221444),
                                          ],
                                        ),
                                  boxShadow: _revealed
                                      ? null
                                      : const [
                                          BoxShadow(
                                            color: Color(0xEEB76CFF),
                                            blurRadius: 34,
                                            spreadRadius: 6,
                                          ),
                                          BoxShadow(
                                            color: Color(0xCC7D45FF),
                                            blurRadius: 70,
                                            spreadRadius: 14,
                                          ),
                                        ],
                                ),
                                child: ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(_revealed ? 0 : 12),
                                  child: _revealed
                                      ? Image.network(
                                          widget.result.coverImageUrl,
                                          fit: BoxFit.cover,
                                        )
                                      : const DecoratedBox(
                                          decoration: BoxDecoration(
                                            gradient: RadialGradient(
                                              colors: [
                                                Color(0xFFE7C5FF),
                                                Color(0xFF7B43DB),
                                                Color(0xFF150B2D),
                                              ],
                                            ),
                                          ),
                                          child: Center(
                                            child: Icon(
                                              Icons.auto_awesome_rounded,
                                              color: Colors.white,
                                              size: 48,
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 34,
                          child: Text(
                            _videoErrorMessage ??
                                (_loadingVideo
                                    ? '正在获取视频...'
                                    : _revealed
                                        ? '点击图片播放视频'
                                        : '请稍候...'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFEFE8FF),
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class GiftVideoPage extends StatefulWidget {
  const GiftVideoPage({super.key, required this.title, required this.videoUrl});

  final String title;
  final String videoUrl;

  @override
  State<GiftVideoPage> createState() => _GiftVideoPageState();
}

class _GiftVideoPageState extends State<GiftVideoPage> {
  late final VideoPlayerController _controller;
  var _ready = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _ready = true);
        _controller.play();
      }).catchError((error) {
        if (!mounted) return;
        setState(() => _errorMessage = '视频加载失败：${error.toString()}');
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).pop(),
        child: SafeArea(
          child: Center(
            child: _errorMessage != null
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                  )
                : _ready
                    ? GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          setState(() {
                            _controller.value.isPlaying
                                ? _controller.pause()
                                : _controller.play();
                          });
                        },
                        child: AspectRatio(
                          aspectRatio: _controller.value.aspectRatio,
                          child: VideoPlayer(_controller),
                        ),
                      )
                    : const CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }
}

class GiftDrawMagicPainter extends CustomPainter {
  const GiftDrawMagicPainter({
    required this.progress,
    required this.revealed,
  });

  final double progress;
  final bool revealed;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.68);
    final pulse = revealed ? 0.75 : 0.55 + math.sin(progress * math.pi * 2) * 0.18;

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Color(0xFFECC8FF).withValues(alpha: 0.7 * pulse),
          Color(0xFF9C50FF).withValues(alpha: 0.35 * pulse),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.42));
    canvas.drawCircle(center, size.width * 0.42, glowPaint);

    final beamPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          Color(0xFFEED0FF).withValues(alpha: 0.76 * pulse),
          Color(0xFF9D5CFF).withValues(alpha: 0.28 * pulse),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromLTWH(size.width * 0.34, size.height * 0.18, size.width * 0.32, size.height * 0.55),
      );
    final beam = Path()
      ..moveTo(size.width * 0.38, size.height * 0.7)
      ..lineTo(size.width * 0.46, size.height * 0.22)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.16, size.width * 0.54, size.height * 0.22)
      ..lineTo(size.width * 0.62, size.height * 0.7)
      ..close();
    canvas.drawPath(beam, beamPaint);

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.3
      ..color = const Color(0xFFC98BFF).withValues(alpha: 0.72);
    for (var i = 0; i < 4; i++) {
      final radiusX = size.width * (0.22 + i * 0.07);
      final radiusY = 12.0 + i * 8;
      final rect = Rect.fromCenter(
        center: center.translate(0, i * 2),
        width: radiusX * 2,
        height: radiusY * 2,
      );
      canvas.drawArc(
        rect,
        progress * math.pi * 2 + i * 0.7,
        math.pi * 1.55,
        false,
        ringPaint..strokeWidth = 1.1 + i * 0.18,
      );
    }

    final sparkPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFF3C8FF);
    for (var i = 0; i < 12; i++) {
      final angle = progress * math.pi * 2 + i * math.pi / 6;
      final radius = size.width * (0.18 + (i % 4) * 0.05);
      final point = Offset(
        size.width / 2 + math.cos(angle) * radius,
        size.height * 0.4 + math.sin(angle * 1.4) * size.height * 0.24,
      );
      final length = i % 3 == 0 ? 7.0 : 4.5;
      canvas.drawLine(point.translate(-length, 0), point.translate(length, 0), sparkPaint);
      canvas.drawLine(point.translate(0, -length), point.translate(0, length), sparkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant GiftDrawMagicPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.revealed != revealed;
  }
}

class GiftDrawCountCard extends StatelessWidget {
  const GiftDrawCountCard({
    super.key,
    required this.availableDrawCount,
    required this.loading,
    required this.onRefresh,
    this.errorMessage,
  });

  final int availableDrawCount;
  final bool loading;
  final VoidCallback onRefresh;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 112,
      padding: const EdgeInsets.fromLTRB(15, 12, 13, 12),
      decoration: BoxDecoration(
        color: const Color(0xAA2B1855),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF9352F3), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x663B16A4),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '当前可抽奖次数',
            style: TextStyle(
              color: Color(0xFFECE5FF),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                loading ? '-' : availableDrawCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  height: 0.9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(width: 5),
              const Padding(
                padding: EdgeInsets.only(bottom: 3),
                child: Text(
                  '次',
                  style: TextStyle(
                    color: Color(0xFFE9DCFF),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(
                    errorMessage ?? '首次下载奖励 x 1',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: errorMessage == null
                          ? const Color(0xFFCFC1EA)
                          : const Color(0xFFFFA4B2),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: onRefresh,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFD780FF),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  textStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                child: const Text('获取更多 >'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class GiftSectionHeader extends StatelessWidget {
  const GiftSectionHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Text(
          '当前角色池',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        Spacer(),
        Text(
          '概率 UP ✨',
          style: TextStyle(
            color: Color(0xFFFFC46A),
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class GiftCharacterCard extends StatelessWidget {
  const GiftCharacterCard({super.key, required this.data});

  final GiftCharacterData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF17142A),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: data.accent.withValues(alpha: 0.86)),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: GiftCharacterPainter(data: data)),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  const Color(0x33080713),
                  const Color(0xEE080713),
                ],
                stops: const [0, 0.54, 1],
              ),
            ),
          ),
          const Positioned(
            left: 7,
            top: 6,
            child: Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 13),
          ),
          Positioned(
            left: 7,
            right: 7,
            bottom: 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data.tag,
                  style: TextStyle(
                    color: data.accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GiftCharacterData {
  const GiftCharacterData(this.name, this.tag, this.accent, this.variant);

  final String name;
  final String tag;
  final Color accent;
  final int variant;
}

class GiftPageBackgroundPainter extends CustomPainter {
  const GiftPageBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0x997947FF),
          const Color(0x227947FF),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.5, size.height * 0.2),
          radius: size.width * 0.62,
        ),
      );
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.2), size.width * 0.62, glow);

    final dotPaint = Paint()..color = const Color(0xFF9C70FF);
    for (var i = 0; i < 38; i++) {
      final x = (math.sin(i * 13.7) * 30000).abs() % size.width;
      final y = (math.cos(i * 17.9) * 30000).abs() % (size.height * 0.68);
      canvas.drawCircle(Offset(x, y), i % 7 == 0 ? 2 : 1, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GiftCharacterPainter extends CustomPainter {
  const GiftCharacterPainter({required this.data});

  final GiftCharacterData data;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          data.accent.withValues(alpha: 0.78),
          const Color(0xFF211335),
          const Color(0xFF070713),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    final center = Offset(size.width * (0.5 + math.sin(data.variant) * 0.05), size.height * 0.43);
    final hair = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.9),
          data.accent.withValues(alpha: 0.88),
          const Color(0xFF1D102C),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.52));
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: size.width * 0.72,
        height: size.height * 0.72,
      ),
      hair,
    );

    final face = Paint()..color = Color.lerp(const Color(0xFFFFDDEB), data.accent, 0.15)!;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, size.height * 0.46),
        width: size.width * 0.42,
        height: size.height * 0.34,
      ),
      face,
    );

    final eye = Paint()..color = const Color(0xFF2C1748);
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx - size.width * 0.09, size.height * 0.45), width: 5, height: 8), eye);
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx + size.width * 0.09, size.height * 0.45), width: 5, height: 8), eye);

    final body = Path()
      ..moveTo(size.width * 0.12, size.height)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.58, size.width * 0.88, size.height)
      ..close();
    canvas.drawPath(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [data.accent.withValues(alpha: 0.72), const Color(0xFF120B1E)],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant GiftCharacterPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}

class AssetPageBody extends StatefulWidget {
  const AssetPageBody({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<AssetPageBody> createState() => _AssetPageBodyState();
}

class _AssetPageBodyState extends State<AssetPageBody> {
  final _apiClient = ApiClient();
  var _refreshVersion = 0;
  late var _selectedTab = widget.initialTab;

  static const _characters = [
    AssetCharacterData('月璃型 · 澪', '心象频率系列', Color(0xFF9970FF), 0),
    AssetCharacterData('王权型 · 卿音', '心象频率系列', Color(0xFFFF617F), 1),
    AssetCharacterData('星跃型 · 光', '心象频率系列', Color(0xFFFFA36F), 2),
    AssetCharacterData('静眠型 · 雾', '心象频率系列', Color(0xFF7DB0FF), 3),
    AssetCharacterData('梦魇型 · 夜', '心象频率系列', Color(0xFFE45BBA), 4),
    AssetCharacterData('肆光型 · 湛', '心象频率系列', Color(0xFFF4B5CA), 5),
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF10122B),
                  Color(0xFF0B0E21),
                  Color(0xFF080713),
                ],
              ),
            ),
          ),
          const CustomPaint(painter: AssetPageBackgroundPainter()),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              children: [
                SizedBox(
                  height: 34,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.arrow_back_ios_new_rounded),
                          color: Colors.white,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints.tightFor(
                            width: 32,
                            height: 32,
                          ),
                        ),
                      ),
                      const Text(
                        '资产',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                AssetSegmentedTabs(
                  selectedIndex: _selectedTab,
                  onSelected: (index) => setState(() => _selectedTab = index),
                ),
                const SizedBox(height: 14),
                if (_selectedTab == 0) Row(
                  children: [
                    const Text(
                      '我的角色',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: AuthSession.token == null
                          ? null
                          : ApiClient().giftCollections(token: AuthSession.token!),
                      builder: (context, snapshot) {
                        final count = snapshot.data?.length ?? 0;
                        return Text(
                          '($count/20)',
                          style: const TextStyle(
                            color: Color(0xFFE5DAFF),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0,
                          ),
                        );
                      },
                    ),
                    const Spacer(),
                    SizedBox(
                      height: 28,
                      child: FilledButton.icon(
                        onPressed: _openCustomCharacterUpload,
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('上传自定义人物'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF33235F),
                          foregroundColor: const Color(0xFFF4E8FF),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          textStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(color: Color(0xFF5E47A1)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: _selectedTab == 0
                      ? AssetCharacterGrid(
                          key: ValueKey(_refreshVersion),
                          fallbackCharacters: _characters,
                        )
                      : const AssetNfcCardList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openCustomCharacterUpload() async {
    final token = AuthSession.token;
    if (token == null || token.isEmpty) {
      _showMessage('请先登录后上传自定义人物');
      return;
    }
    try {
      final quota = await _apiClient.customCharacterQuota(token: token);
      final remaining = (quota['remaining'] as num?)?.toInt() ?? 0;
      if (remaining <= 0) {
        _showMessage('本月最多上传 10 个自定义人物');
        return;
      }
      if (!mounted) return;
      final saved = await showDialog<bool>(
        context: context,
        builder: (_) => CustomCharacterUploadDialog(
          token: token,
          remaining: remaining,
        ),
      );
      if (saved == true && mounted) {
        setState(() => _refreshVersion++);
        _showMessage('自定义人物已保存');
      }
    } catch (error) {
      if (!mounted) return;
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class CustomCharacterUploadDialog extends StatefulWidget {
  const CustomCharacterUploadDialog({
    super.key,
    required this.token,
    required this.remaining,
  });

  final String token;
  final int remaining;

  @override
  State<CustomCharacterUploadDialog> createState() => _CustomCharacterUploadDialogState();
}

class _CustomCharacterUploadDialogState extends State<CustomCharacterUploadDialog> {
  final _apiClient = ApiClient();
  final _picker = ImagePicker();
  final _controllers = <String, TextEditingController>{
    'name': TextEditingController(),
    'remark': TextEditingController(),
    'characterProfile': TextEditingController(),
    'personality': TextEditingController(),
    'likes': TextEditingController(),
    'dislikes': TextEditingController(),
    'catchphrases': TextEditingController(),
  };
  XFile? _image;
  XFile? _video;
  XFile? _audio;
  var _saving = false;
  String? _errorMessage;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.92;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      backgroundColor: Colors.transparent,
      child: Container(
        width: 440,
        height: height,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF10132C), Color(0xFF080D20), Color(0xFF070B19)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF292C59)),
          boxShadow: const [BoxShadow(color: Color(0xAA000000), blurRadius: 30, offset: Offset(0, 16))],
        ),
        child: Column(
          children: [
            _header(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
                child: Column(
                  children: [
                    _heroUpload(),
                    const SizedBox(height: 12),
                    _fileTile(
                      icon: Icons.video_library_outlined,
                      title: '人物视频',
                      subtitle: _video?.name ?? '可选，支持 MP4 / MOV / WEBM',
                      onTap: _pickVideo,
                    ),
                    const SizedBox(height: 10),
                    _fileTile(
                      icon: Icons.graphic_eq_rounded,
                      title: '人物声音 MP3',
                      subtitle: _audio?.name ?? '可选，上传人物配音或语音样本',
                      onTap: _pickAudio,
                      highlighted: true,
                    ),
                    const SizedBox(height: 14),
                    _field('人物名称', 'name', hint: '给你的角色起一个名字', required: true),
                    _field('角色描述', 'characterProfile', hint: '描述角色背景、经历、能力、特点等...', maxLines: 3, maxLength: 500, required: true),
                    _field('性格', 'personality', hint: '例如：温柔、傲娇、毒舌、内向、活泼等...', maxLines: 2, maxLength: 200),
                    _field('喜欢', 'likes', hint: '例如：星空、音乐、甜点、动物等...', maxLines: 2, maxLength: 200),
                    _field('讨厌', 'dislikes', hint: '例如：噪音、背叛、虚伪、孤独等...', maxLines: 2, maxLength: 200),
                    _field('口头禅', 'catchphrases', hint: '例如：“这一次，我不会再把你弄丢了。”', maxLines: 2, maxLength: 100),
                    _field('备注', 'remark', hint: '其他补充信息', maxLines: 2, maxLength: 500),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2, bottom: 10),
                        child: Text(_errorMessage!, style: const TextStyle(color: Color(0xFFFF9BA6))),
                      ),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: _saving ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF6434C5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _saving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('保存', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 18, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(false),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
          ),
          const Expanded(child: Text('上传自定义人物', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900))),
          Text('本月剩余 ${widget.remaining}', style: const TextStyle(color: Color(0xFFC8B9EF), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _heroUpload() {
    return InkWell(
      onTap: _saving ? null : _pickImage,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 178,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF121630),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF39366D)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF28205E)),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Text(_image?.name ?? '上传人物图片', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFD4C9F1), fontSize: 15, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 5),
            const Text('支持 JPG / PNG / WEBP（必填，建议 9:16）', style: TextStyle(color: Color(0xFF9791B8), fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _fileTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool highlighted = false,
  }) {
    return InkWell(
      onTap: _saving ? null : onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: const Color(0xFF12162D),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: highlighted ? const Color(0xFF55448E) : const Color(0xFF282D52)),
        ),
        child: Row(
          children: [
            Icon(icon, color: highlighted ? const Color(0xFFC5A7FF) : const Color(0xFFA9A5C8)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF9590B1), fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF8C86A9)),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, String key, {String? hint, int maxLines = 1, int? maxLength, bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF11162C),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF252B50)),
        ),
        child: TextField(
          controller: _controllers[key],
          maxLines: maxLines,
          maxLength: maxLength,
          decoration: InputDecoration(
            labelText: required ? '$label · 必填' : '$label · 选填',
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF77728F), fontSize: 13),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null && mounted) setState(() => _image = image);
  }

  Future<void> _pickVideo() async {
    final video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null && mounted) setState(() => _video = video);
  }

  Future<void> _pickAudio() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['mp3'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty && result.files.first.bytes != null && mounted) {
      final file = result.files.first;
      setState(() => _audio = XFile.fromData(file.bytes!, name: file.name, mimeType: 'audio/mpeg'));
    }
  }

  Future<void> _save() async {
    final name = _controllers['name']!.text.trim();
    if (name.isEmpty || _image == null) {
      setState(() => _errorMessage = '请填写人物名称并选择图片');
      return;
    }
    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    try {
      await _apiClient.uploadCustomCharacter(
        token: widget.token,
        fields: {for (final entry in _controllers.entries) entry.key: entry.value.text.trim()},
        image: _image!,
        video: _video,
        audio: _audio,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }
}

class AssetCharacterGrid extends StatefulWidget {
  const AssetCharacterGrid({super.key, required this.fallbackCharacters});

  final List<AssetCharacterData> fallbackCharacters;

  @override
  State<AssetCharacterGrid> createState() => _AssetCharacterGridState();
}

class _AssetCharacterGridState extends State<AssetCharacterGrid> {
  static const _nativeVideoChannel = MethodChannel('dimensional/native_video');

  final _apiClient = ApiClient();
  final _likedCollectionIds = <int>{};
  var _openingVideo = false;

  @override
  Widget build(BuildContext context) {
    final token = AuthSession.token;
    if (token == null || token.isEmpty) {
      return const _AssetEmptyState(
        icon: Icons.lock_outline_rounded,
        message: '请先登录后查看资产',
      );
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: ApiClient().giftCollections(token: token),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _AssetEmptyState(
            icon: Icons.error_outline_rounded,
            message: snapshot.error.toString().replaceFirst('Exception: ', ''),
          );
        }

        final characters = _groupAssetCharacters(
          (snapshot.data ?? const []).map(AssetCharacterData.fromJson),
        );
        if (characters.isEmpty) {
          return const _AssetEmptyState(
            icon: Icons.style_outlined,
            message: '还没有抽到角色',
          );
        }

        return GridView.builder(
          padding: EdgeInsets.zero,
          physics: const BouncingScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.78,
          ),
          itemCount: characters.length,
          itemBuilder: (context, index) {
            final character = characters[index];
            return AssetCharacterCard(
              data: character,
              liked: _likedCollectionIds.contains(character.collectionId),
              openingVideo: _openingVideo,
              onTap: () => _openVideo(character),
              onLike: () => _toggleLike(character),
            );
          },
        );
      },
    );
  }

  void _toggleLike(AssetCharacterData character) {
    setState(() {
      if (!_likedCollectionIds.add(character.collectionId)) {
        _likedCollectionIds.remove(character.collectionId);
      }
    });
  }

  Future<void> _openVideo(AssetCharacterData character) async {
    if (_openingVideo) return;
    final token = AuthSession.token;
    final objectKey = character.previewVideoObjectKey;
    final fallbackUrl = character.previewVideoUrl;
    if (token == null || token.isEmpty) return;
    if ((objectKey == null || objectKey.isEmpty) &&
        (fallbackUrl == null || fallbackUrl.isEmpty)) {
      _showMessage('暂无可播放视频');
      return;
    }

    setState(() => _openingVideo = true);
    try {
      var videoUrl = fallbackUrl ?? '';
      if (objectKey != null && objectKey.isNotEmpty) {
        videoUrl = await _apiClient.giftVideoProxyUrl(
          token: token,
          objectKey: objectKey,
        );
      }
      if (!mounted) return;
      final opened = await _openNativeVideo(videoUrl, character.name);
      if (!opened && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GiftVideoPage(
              title: character.name,
              videoUrl: videoUrl,
            ),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _openingVideo = false);
      }
    }
  }

  Future<bool> _openNativeVideo(String videoUrl, String title) async {
    try {
      final opened = await _nativeVideoChannel.invokeMethod<bool>(
        'openVideo',
        {
          'url': videoUrl,
          'title': title,
        },
      );
      return opened == true;
    } on MissingPluginException {
      return false;
    } on PlatformException catch (error) {
      _showMessage(error.message ?? '原生播放器打开失败');
      return false;
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _AssetEmptyState extends StatelessWidget {
  const _AssetEmptyState({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFDCCFFF), size: 34),
          const SizedBox(height: 10),
          Text(
            message,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFEFE8FF),
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class AssetNfcCardList extends StatefulWidget {
  const AssetNfcCardList({super.key});

  @override
  State<AssetNfcCardList> createState() => _AssetNfcCardListState();
}

class _AssetNfcCardListState extends State<AssetNfcCardList> {
  final _apiClient = ApiClient();
  var _refreshVersion = 0;

  @override
  Widget build(BuildContext context) {
    final token = AuthSession.token;
    if (token == null || token.isEmpty) {
      return const _AssetEmptyState(
        icon: Icons.lock_outline_rounded,
        message: '请先登录后查看 NFC 卡片',
      );
    }
    return FutureBuilder<List<Map<String, dynamic>>>(
      key: ValueKey(_refreshVersion),
      future: _apiClient.nfcCards(token: token),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _AssetEmptyState(
            icon: Icons.error_outline_rounded,
            message: 'NFC 卡片加载失败，请稍后重试',
          );
        }
        final cards = (snapshot.data ?? const [])
            .map(AssetNfcCardData.fromJson)
            .toList(growable: false);
        if (cards.isEmpty) {
          return const _AssetEmptyState(
            icon: Icons.nfc_rounded,
            message: '还没有绑定 NFC 卡片',
          );
        }
        return ListView.separated(
          padding: EdgeInsets.zero,
          physics: const BouncingScrollPhysics(),
          itemCount: cards.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (_, index) => AssetNfcCardTile(
            data: cards[index],
            onTap: () => _selectCharacter(cards[index], token),
          ),
        );
      },
    );
  }

  Future<void> _selectCharacter(AssetNfcCardData card, String token) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => NfcCharacterBindingPage(card: card, token: token),
      ),
    );
    if (saved == true && mounted) {
      setState(() => _refreshVersion++);
      _showMessage('角色已绑定');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class NfcCharacterBindingPage extends StatefulWidget {
  const NfcCharacterBindingPage({super.key, required this.card, required this.token});

  final AssetNfcCardData card;
  final String token;

  @override
  State<NfcCharacterBindingPage> createState() => _NfcCharacterBindingPageState();
}

class _NfcCharacterBindingPageState extends State<NfcCharacterBindingPage> {
  final _apiClient = ApiClient();
  var _characters = <AssetCharacterData>[];
  int? _selectedCollectionId;
  var _loading = true;
  var _saving = false;
  late var _giftMode = widget.card.giftModeEnabled;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCharacters();
  }

  Future<void> _loadCharacters() async {
    try {
      final data = await _apiClient.giftCollections(token: widget.token);
      if (!mounted) return;
      setState(() {
        _characters = _groupAssetCharacters(data.map(AssetCharacterData.fromJson));
        _selectedCollectionId = _characters.isEmpty ? null : _characters.first.collectionId;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final selectedIndex = _characters.indexWhere(
      (character) => character.collectionId == _selectedCollectionId,
    );
    if (selectedIndex < 0) return;
    final selectedCharacter = _characters[selectedIndex];
    final collectionIds = selectedCharacter.collectionIds;
    final collectionId = collectionIds[math.Random().nextInt(collectionIds.length)];
    setState(() => _saving = true);
    try {
      await _apiClient.bindNfcCharacter(
        token: widget.token,
        cardId: widget.card.id,
        characterCollectionId: collectionId,
        giftModeEnabled: _giftMode,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B19),
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(18, 6, 18, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _currentBinding(),
                          const SizedBox(height: 22),
                          const _BindingSectionTitle('1. 我的角色'),
                          const SizedBox(height: 12),
                          _characterGrid(),
                          const SizedBox(height: 22),
                          const _BindingSectionTitle('2. 卡片设置'),
                          const SizedBox(height: 12),
                          _giftModeSetting(),
                          if (_errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(_errorMessage!, style: const TextStyle(color: Color(0xFFFF9BA6))),
                            ),
                        ],
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: _saving || _selectedCollectionId == null ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6434C5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('确定绑定', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 14, 10),
      child: Row(
        children: [
          IconButton(onPressed: () => Navigator.of(context).pop(false), icon: const Icon(Icons.arrow_back_ios_new_rounded)),
          const Expanded(child: Text('更换绑定角色', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900))),
          const Icon(Icons.help_outline_rounded, color: Color(0xFFE5DEFF)),
        ],
      ),
    );
  }

  Widget _currentBinding() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xCC11162D),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF292F54)),
      ),
      child: Row(
        children: [
          _BindingCardCover(accent: widget.card.accent, imageUrl: widget.card.coverImageUrl, size: 92),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('当前绑定', style: TextStyle(color: Color(0xFFA9A2C5), fontSize: 13)),
                const SizedBox(height: 8),
                Text(
                  widget.card.hasCharacter ? widget.card.characterName! : '暂未绑定角色',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 9),
                Text(widget.card.title, style: const TextStyle(color: Color(0xFFC6B2FF), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _characterGrid() {
    if (_characters.isEmpty) {
      return const _AssetEmptyState(icon: Icons.person_add_alt_1_outlined, message: '请先获取或上传角色');
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.72,
      ),
      itemCount: _characters.length,
      itemBuilder: (_, index) {
        final character = _characters[index];
        final selected = character.collectionId == _selectedCollectionId;
        return GestureDetector(
          onTap: () => setState(() => _selectedCollectionId = character.collectionId),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFF12162D),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: selected ? const Color(0xFF934CFF) : const Color(0xFF343956), width: selected ? 2 : 1),
              boxShadow: selected ? const [BoxShadow(color: Color(0x665B2CCE), blurRadius: 14)] : null,
            ),
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (character.coverImageUrl == null || character.coverImageUrl!.isEmpty)
                        CustomPaint(painter: AssetCharacterPainter(data: character))
                      else
                        Image.network(character.coverImageUrl!, fit: BoxFit.cover),
                      if (selected)
                        const Positioned(
                          top: 6,
                          right: 6,
                          child: CircleAvatar(radius: 11, backgroundColor: Color(0xFF7138E2), child: Icon(Icons.check_rounded, size: 15, color: Colors.white)),
                        ),
                      if (character.quantity > 1)
                        Positioned(
                          top: 6,
                          left: 6,
                          child: _CharacterQuantityBadge(quantity: character.quantity),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
                  child: Text(character.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _giftModeSetting() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xCC11162D),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF292F54)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('卡片允许进入赠送模式', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                SizedBox(height: 6),
                Text('开启后，这张卡片可以被赠送给其他人。', style: TextStyle(color: Color(0xFF918BA9), fontSize: 12)),
              ],
            ),
          ),
          Switch(value: _giftMode, onChanged: (value) => setState(() => _giftMode = value)),
        ],
      ),
    );
  }
}

class _BindingSectionTitle extends StatelessWidget {
  const _BindingSectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900));
}

class _BindingCardCover extends StatelessWidget {
  const _BindingCardCover({required this.accent, required this.imageUrl, required this.size});
  final Color accent;
  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size * 1.18,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [accent.withValues(alpha: 0.85), const Color(0xFF17122B)]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent),
        image: imageUrl == null || imageUrl!.isEmpty ? null : DecorationImage(image: NetworkImage(imageUrl!), fit: BoxFit.cover),
      ),
      child: imageUrl == null || imageUrl!.isEmpty ? const Icon(Icons.star_border_rounded, color: Colors.white, size: 48) : null,
    );
  }
}

class AssetNfcCardData {
  const AssetNfcCardData({
    required this.id,
    required this.title,
    required this.characterName,
    required this.rarity,
    required this.coverImageUrl,
    required this.giftModeEnabled,
  });

  factory AssetNfcCardData.fromJson(Map<String, dynamic> json) {
    return AssetNfcCardData(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? 'NFC 卡片',
      characterName: json['characterName']?.toString(),
      rarity: json['rarity']?.toString(),
      coverImageUrl: json['coverImageUrl']?.toString(),
      giftModeEnabled: json['giftModeEnabled'] == true,
    );
  }

  final int id;
  final String title;
  final String? characterName;
  final String? rarity;
  final String? coverImageUrl;
  final bool giftModeEnabled;

  bool get hasCharacter => characterName != null && characterName!.isNotEmpty;
  Color get accent {
    const colors = [
      Color(0xFF8E64FF),
      Color(0xFFFFB45E),
      Color(0xFFFF906C),
      Color(0xFF7798FF),
    ];
    return colors[id.abs() % colors.length];
  }
}

class AssetNfcCardTile extends StatelessWidget {
  const AssetNfcCardTile({super.key, required this.data, required this.onTap});

  final AssetNfcCardData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 118,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xCC11162D),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2D335B)),
        ),
        child: Row(
        children: [
          Container(
            width: 78,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [data.accent.withValues(alpha: 0.78), const Color(0xFF16122A)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: data.accent.withValues(alpha: 0.75)),
              image: data.coverImageUrl == null || data.coverImageUrl!.isEmpty
                  ? null
                  : DecorationImage(image: NetworkImage(data.coverImageUrl!), fit: BoxFit.cover),
            ),
            child: data.coverImageUrl == null || data.coverImageUrl!.isEmpty
                ? Icon(Icons.star_border_rounded, color: Colors.white.withValues(alpha: 0.9), size: 46)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.hasCharacter ? '绑定角色' : data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFFB6B1CD), fontSize: 12, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  data.hasCharacter ? data.characterName! : '请绑定角色',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: data.hasCharacter ? Colors.white : const Color(0xFFD9C4FF),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (data.hasCharacter && data.rarity != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    '${data.rarity!} · ${data.giftModeEnabled ? '赠送模式已开启' : '赠送模式未开启'}',
                    style: TextStyle(color: data.accent, fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFFC9C5DA), size: 28),
        ],
        ),
      ),
    );
  }
}

class AssetSegmentedTabs extends StatelessWidget {
  const AssetSegmentedTabs({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: const Color(0xFF151731),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3A3162)),
      ),
      child: Row(
        children: [
          Expanded(child: _AssetTabButton(label: '我的角色', active: selectedIndex == 0, onTap: () => onSelected(0))),
          Expanded(child: _AssetTabButton(label: '我的卡片', active: selectedIndex == 1, onTap: () => onSelected(1))),
        ],
      ),
    );
  }
}

class _AssetTabButton extends StatelessWidget {
  const _AssetTabButton({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? const Color(0xFF54389A) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: active
              ? const [BoxShadow(color: Color(0x554F34A6), blurRadius: 12, offset: Offset(0, 4))]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : const Color(0xFFB8B2CE),
            fontSize: 12,
            fontWeight: active ? FontWeight.w800 : FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class AssetCharacterCard extends StatelessWidget {
  const AssetCharacterCard({
    super.key,
    required this.data,
    required this.liked,
    required this.openingVideo,
    required this.onTap,
    required this.onLike,
  });

  final AssetCharacterData data;
  final bool liked;
  final bool openingVideo;
  final VoidCallback onTap;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF17142A),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFF55437D)),
        boxShadow: [
          BoxShadow(
            color: data.accent.withValues(alpha: 0.24),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (data.coverImageUrl == null || data.coverImageUrl!.isEmpty)
            CustomPaint(painter: AssetCharacterPainter(data: data))
          else
            Image.network(
              data.coverImageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return CustomPaint(painter: AssetCharacterPainter(data: data));
              },
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  const Color(0xFF080713).withValues(alpha: 0.1),
                  const Color(0xE6080713),
                ],
                stops: const [0, 0.52, 1],
              ),
            ),
          ),
          Positioned(
            top: 7,
            right: 7,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onLike,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: liked
                      ? const Color(0xDDFE4E7B)
                      : const Color(0x77100D20),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: liked
                        ? const Color(0xFFFFB6C9)
                        : const Color(0x99FFFFFF),
                  ),
                ),
                child: Icon(
                  liked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: Colors.white,
                  size: 17,
                ),
              ),
            ),
          ),
          if (data.sourceType == 2)
            Positioned(
              top: 7,
              left: 7,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xCC563594),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFD9B7FF)),
                ),
                child: const Icon(Icons.cloud_upload_outlined, color: Colors.white, size: 16),
              ),
            ),
          if (data.quantity > 1)
            Positioned(
              top: 7,
              left: 7,
              child: _CharacterQuantityBadge(quantity: data.quantity),
            ),
          if (openingVideo)
            const Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          Positioned(
            left: 9,
            right: 8,
            bottom: 9,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.local_fire_department_outlined,
                      color: data.accent.withValues(alpha: 0.86),
                      size: 12,
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        data.series,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFCFC6E8),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class AssetCharacterData {
  const AssetCharacterData(
    this.name,
    this.series,
    this.accent,
    this.variant,
    {
      this.coverImageUrl,
      this.previewVideoObjectKey,
      this.previewVideoUrl,
      int? collectionId,
      this.sourceType = 1,
      this.cardResourceId,
      this.groupedCollectionIds,
    }
  ) : collectionId = collectionId ?? variant;

  factory AssetCharacterData.fromJson(Map<String, dynamic> json) {
    final name = json['name']?.toString() ?? '未命名角色';
    final rarity = json['rarity']?.toString() ?? 'NORMAL';
    return AssetCharacterData(
      name,
      rarity,
      _accentForRarity(rarity),
      (json['collectionId'] as num?)?.toInt() ?? name.hashCode,
      coverImageUrl: json['coverImageUrl']?.toString(),
      previewVideoObjectKey: json['previewVideoObjectKey']?.toString(),
      previewVideoUrl: json['previewVideoUrl']?.toString(),
      collectionId: (json['collectionId'] as num?)?.toInt() ?? name.hashCode,
      sourceType: (json['sourceType'] as num?)?.toInt() ?? 1,
      cardResourceId: (json['cardResourceId'] as num?)?.toInt(),
    );
  }

  final int collectionId;
  final String name;
  final String series;
  final Color accent;
  final int variant;
  final String? coverImageUrl;
  final String? previewVideoObjectKey;
  final String? previewVideoUrl;
  final int sourceType;
  final int? cardResourceId;
  final List<int>? groupedCollectionIds;

  List<int> get collectionIds => groupedCollectionIds ?? [collectionId];
  int get quantity => collectionIds.length;
  String get groupingKey => sourceType == 1 && cardResourceId != null
      ? 'resource:$cardResourceId'
      : 'collection:$collectionId';

  AssetCharacterData withCollectionIds(List<int> ids) {
    return AssetCharacterData(
      name,
      series,
      accent,
      variant,
      coverImageUrl: coverImageUrl,
      previewVideoObjectKey: previewVideoObjectKey,
      previewVideoUrl: previewVideoUrl,
      collectionId: collectionId,
      sourceType: sourceType,
      cardResourceId: cardResourceId,
      groupedCollectionIds: List.unmodifiable(ids),
    );
  }

  static Color _accentForRarity(String rarity) {
    return switch (rarity.toUpperCase()) {
      'SSR' => const Color(0xFFFFC35B),
      'SR' => const Color(0xFFE45BBA),
      'R' => const Color(0xFF7DB0FF),
      _ => const Color(0xFF9970FF),
    };
  }
}

List<AssetCharacterData> _groupAssetCharacters(
  Iterable<AssetCharacterData> characters,
) {
  final grouped = <String, AssetCharacterData>{};
  final collectionIds = <String, List<int>>{};
  for (final character in characters) {
    final key = character.groupingKey;
    grouped.putIfAbsent(key, () => character);
    collectionIds.putIfAbsent(key, () => []).add(character.collectionId);
  }
  return [
    for (final entry in grouped.entries)
      entry.value.withCollectionIds(collectionIds[entry.key]!),
  ];
}

class _CharacterQuantityBadge extends StatelessWidget {
  const _CharacterQuantityBadge({required this.quantity});

  final int quantity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xDD5D32B6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD9B7FF)),
      ),
      child: Text(
        'x$quantity',
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class AssetPageBackgroundPainter extends CustomPainter {
  const AssetPageBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0x88704BFF),
          const Color(0x1F704BFF),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.52, size.height * 0.05),
          radius: size.width * 0.58,
        ),
      );
    canvas.drawCircle(
      Offset(size.width * 0.52, size.height * 0.05),
      size.width * 0.58,
      glow,
    );

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0x223E58FF);
    for (var i = 0; i < 8; i++) {
      final x = size.width * (0.08 + i * 0.13);
      canvas.drawLine(Offset(x, 0), Offset(x + 18, size.height), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AssetCharacterPainter extends CustomPainter {
  const AssetCharacterPainter({required this.data});

  final AssetCharacterData data;

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          data.accent.withValues(alpha: 0.78),
          const Color(0xFF19152F),
          const Color(0xFF090713),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bgPaint);

    final rayPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = Colors.white.withValues(alpha: 0.18);
    for (var i = 0; i < 9; i++) {
      final start = Offset(size.width * (i / 8), 0);
      final end = Offset(size.width * (0.2 + i / 12), size.height * 0.72);
      canvas.drawLine(start, end, rayPaint);
    }

    final center = Offset(
      size.width * (0.5 + math.sin(data.variant) * 0.05),
      size.height * 0.44,
    );
    final hairPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.88),
          data.accent.withValues(alpha: 0.92),
          const Color(0xFF241334),
        ],
      ).createShader(
        Rect.fromCircle(center: center, radius: size.width * 0.45),
      );
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: size.width * 0.62,
        height: size.height * 0.72,
      ),
      hairPaint,
    );

    final facePaint = Paint()
      ..color = Color.lerp(const Color(0xFFFFD6E8), data.accent, 0.18)!;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, size.height * 0.47),
        width: size.width * 0.38,
        height: size.height * 0.34,
      ),
      facePaint,
    );

    final eyePaint = Paint()
      ..color = data.variant.isEven
          ? const Color(0xFF422062)
          : const Color(0xFF1B1938);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx - size.width * 0.08, size.height * 0.47),
        width: 5,
        height: 8,
      ),
      eyePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx + size.width * 0.08, size.height * 0.47),
        width: 5,
        height: 8,
      ),
      eyePaint,
    );

    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          data.accent.withValues(alpha: 0.78),
          const Color(0xFF191225),
        ],
      ).createShader(Offset.zero & size);
    final body = Path()
      ..moveTo(size.width * 0.18, size.height)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.58,
        size.width * 0.82,
        size.height,
      )
      ..close();
    canvas.drawPath(body, bodyPaint);

    final strandPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.62);
    for (var i = 0; i < 8; i++) {
      final x = size.width * (0.3 + i * 0.06);
      final path = Path()
        ..moveTo(x, size.height * 0.18)
        ..quadraticBezierTo(
          x - size.width * 0.06,
          size.height * 0.42,
          x + size.width * 0.02,
          size.height * 0.72,
        );
      canvas.drawPath(path, strandPaint);
    }

    final sparklePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.72);
    for (final p in [
      Offset(size.width * 0.18, size.height * 0.18),
      Offset(size.width * 0.74, size.height * 0.28),
      Offset(size.width * 0.28, size.height * 0.68),
    ]) {
      canvas.drawLine(p.translate(-5, 0), p.translate(5, 0), sparklePaint);
      canvas.drawLine(p.translate(0, -5), p.translate(0, 5), sparklePaint);
    }
  }

  @override
  bool shouldRepaint(covariant AssetCharacterPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}

class ProfilePageBody extends StatefulWidget {
  const ProfilePageBody({super.key});

  @override
  State<ProfilePageBody> createState() => _ProfilePageBodyState();
}

class _ProfilePageBodyState extends State<ProfilePageBody> {
  final _apiClient = ApiClient();
  var _loadingUser = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final token = AuthSession.token;
    if (token == null || token.isEmpty) return;
    setState(() {
      _loadingUser = true;
      _errorMessage = null;
    });
    try {
      final user = await _apiClient.currentUser(token: token);
      AuthSession.user = user;
      AuthSession.isLoggedIn = true;
      if (!mounted) return;
      setState(() {});
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _loadingUser = false);
      }
    }
  }

  void _openLogin() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LoginPage(
          nfcDataLines: const [],
        ),
      ),
    ).then((loggedIn) {
      if (loggedIn == true) {
        _loadUser();
      }
    });
  }

  Future<void> _editNickname() async {
    final token = AuthSession.token;
    if (token == null || token.isEmpty) {
      _openLogin();
      return;
    }

    final controller = TextEditingController(
      text: AuthSession.user?['nickname']?.toString() ?? '',
    );
    final nickname = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF15162C),
          title: const Text('修改昵称'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 64,
            decoration: const InputDecoration(
              hintText: '请输入昵称',
              counterText: '',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (nickname == null || nickname.isEmpty) return;
    setState(() {
      _loadingUser = true;
      _errorMessage = null;
    });
    try {
      final user = await _apiClient.updateNickname(token: token, nickname: nickname);
      AuthSession.user = user;
      if (!mounted) return;
      setState(() {});
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _loadingUser = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthSession.user;
    final isLoggedIn = AuthSession.isLoggedIn && AuthSession.token != null;
    final phone = user?['phone']?.toString();
    final name = user?['nickname']?.toString() ?? (_loadingUser ? '加载中' : '请先登录');
    final level = user?['level']?.toString() ?? '16';
    final idText = phone == null || phone.length < 4
        ? 'ID：100023847'
        : 'ID：${phone.substring(phone.length - 4).padLeft(9, '0')}';

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF11132B),
                  Color(0xFF090D21),
                  Color(0xFF080713),
                ],
              ),
            ),
          ),
          const CustomPaint(painter: ProfileGlowPainter()),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  color: Colors.white,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 32,
                    height: 32,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const ProfileAvatar(),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: isLoggedIn ? null : _openLogin,
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 3),
                                    child: Text(
                                      name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              SizedBox(
                                width: 28,
                                height: 28,
                                child: IconButton(
                                  onPressed: _loadingUser ? null : _editNickname,
                                  icon: const Icon(Icons.edit_rounded),
                                  iconSize: 15,
                                  color: const Color(0xFFE7C6FF),
                                  padding: EdgeInsets.zero,
                                  tooltip: '修改昵称',
                                ),
                              ),
                            ],
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              _errorMessage!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFFFF9BA6),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0,
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            idText,
                            style: const TextStyle(
                              color: Color(0xFFD5D7EE),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 22,
                            padding: const EdgeInsets.symmetric(horizontal: 9),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8D5CFF),
                              borderRadius: BorderRadius.circular(7),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x668D5CFF),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Lv.$level',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const ProfileMenuPanel(
                  items: [
                    ProfileMenuItemData(
                      icon: Icons.info_outline_rounded,
                      title: '关于我们',
                      subtitle: '了解心象频率',
                    ),
                    ProfileMenuItemData(
                      icon: Icons.info_outline_rounded,
                      title: '企业愿景',
                      subtitle: '我们想让陪伴更有温度',
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const ProfileMenuPanel(
                  items: [
                    ProfileMenuItemData(
                      icon: Icons.article_outlined,
                      title: '用户协议',
                    ),
                    ProfileMenuItemData(
                      icon: Icons.policy_outlined,
                      title: '隐私政策',
                    ),
                    ProfileMenuItemData(
                      icon: Icons.settings_outlined,
                      title: '设置',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileMenuPanel extends StatelessWidget {
  const ProfileMenuPanel({super.key, required this.items});

  final List<ProfileMenuItemData> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xCC11162C),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF242B4B)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            ProfileMenuRow(item: items[i]),
            if (i != items.length - 1)
              const Divider(
                height: 1,
                thickness: 1,
                indent: 14,
                endIndent: 14,
                color: Color(0x332C365B),
              ),
          ],
        ],
      ),
    );
  }
}

class ProfileMenuRow extends StatelessWidget {
  const ProfileMenuRow({super.key, required this.item});

  final ProfileMenuItemData item;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: item.subtitle == null ? 58 : 70,
      child: Row(
        children: [
          const SizedBox(width: 14),
          Icon(item.icon, color: const Color(0xFFE7E8F7), size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                if (item.subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF8C95B5),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFFF1F2FF),
            size: 22,
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }
}

class ProfileMenuItemData {
  const ProfileMenuItemData({
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
}

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 74,
      height: 74,
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFB777FF), Color(0xFF4337A8)],
        ),
      ),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF17142A),
        ),
        child: const ClipOval(child: CustomPaint(painter: ProfileAvatarPainter())),
      ),
    );
  }
}

class ProfileGlowPainter extends CustomPainter {
  const ProfileGlowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xAA7C45FF),
          const Color(0x227C45FF),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.82, size.height * 0.08),
          radius: size.width * 0.48,
        ),
      );
    canvas.drawCircle(
      Offset(size.width * 0.82, size.height * 0.08),
      size.width * 0.48,
      glowPaint,
    );

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0x443B5BFF);

    for (var i = 0; i < 7; i++) {
      final x = size.width * (0.58 + i * 0.055);
      canvas.drawLine(
        Offset(x, size.height * 0.02),
        Offset(x + 18, size.height * 0.24),
        linePaint,
      );
    }

    final dotPaint = Paint()..color = const Color(0xAA8C65FF);
    for (var i = 0; i < 18; i++) {
      final x = size.width * (0.55 + (math.sin(i * 3.1).abs() * 0.42));
      final y = size.height * (0.02 + (math.cos(i * 1.7).abs() * 0.2));
      canvas.drawCircle(Offset(x, y), i % 4 == 0 ? 2.2 : 1.2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ProfileAvatarPainter extends CustomPainter {
  const ProfileAvatarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF37205B), Color(0xFF121735), Color(0xFF7041B7)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    final hairPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFE4D5FF), Color(0xFF8D66D9), Color(0xFF4D347F)],
      ).createShader(Offset.zero & size);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.48),
        width: size.width * 0.58,
        height: size.height * 0.68,
      ),
      hairPaint,
    );

    final facePaint = Paint()..color = const Color(0xFFE7C3E3);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.52),
        width: size.width * 0.42,
        height: size.height * 0.48,
      ),
      facePaint,
    );

    final eyePaint = Paint()..color = const Color(0xFF4E246F);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.42, size.height * 0.52),
        width: 5,
        height: 8,
      ),
      eyePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.58, size.height * 0.52),
        width: 5,
        height: 8,
      ),
      eyePaint,
    );

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFF2E8FF);
    for (var i = 0; i < 7; i++) {
      final startX = size.width * (0.28 + i * 0.07);
      final path = Path()
        ..moveTo(startX, size.height * 0.18)
        ..quadraticBezierTo(
          startX - size.width * 0.05,
          size.height * 0.45,
          startX + size.width * 0.02,
          size.height * 0.72,
        );
      canvas.drawPath(path, stroke);
    }

    final sparkle = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFFFD9FF);
    canvas.drawLine(
      Offset(size.width * 0.75, size.height * 0.2),
      Offset(size.width * 0.9, size.height * 0.2),
      sparkle,
    );
    canvas.drawLine(
      Offset(size.width * 0.825, size.height * 0.12),
      Offset(size.width * 0.825, size.height * 0.28),
      sparkle,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CoverThumb extends StatelessWidget {
  const CoverThumb({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 55,
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFAA7BFF), Color(0xFF31225E), Color(0xFFFFA5D7)],
        ),
        border: Border.all(color: const Color(0xFFD9B6FF), width: 1.2),
      ),
      child: const Stack(
        children: [
          Positioned(
            left: 9,
            top: 9,
            child: Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
          Positioned(
            right: 8,
            bottom: 8,
            child: CircleAvatar(
              radius: 14,
              backgroundColor: Color(0xCCEEE4FF),
              child: Icon(
                Icons.person_rounded,
                color: Color(0xFF7952D6),
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BottomTabs extends StatelessWidget {
  const BottomTabs({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    const items = [
      _TabItem('首页', Icons.home_outlined),
      _TabItem('资产', Icons.widgets_outlined),
      _TabItem('礼物', Icons.card_giftcard_rounded),
      _TabItem('广场', Icons.favorite_border_rounded),
      _TabItem('我的', Icons.person_outline_rounded),
    ];

    return SizedBox(
      height: 76,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xEE121027),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF322653)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x99000000),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _TabButton(
                    item: items[0],
                    active: selectedIndex == 0,
                    onTap: () => onSelected(0),
                  ),
                ),
                Expanded(
                  child: _TabButton(
                    item: items[1],
                    active: selectedIndex == 1,
                    onTap: () => onSelected(1),
                  ),
                ),
                const SizedBox(width: 68),
                Expanded(
                  child: _TabButton(
                    item: items[3],
                    active: selectedIndex == 3,
                    onTap: () => onSelected(3),
                  ),
                ),
                Expanded(
                  child: _TabButton(
                    item: items[4],
                    active: selectedIndex == 4,
                    onTap: () => onSelected(4),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            child: _CenterGiftButton(
              active: selectedIndex == 2,
              item: items[2],
              onTap: () => onSelected(2),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.item,
    required this.active,
    required this.onTap,
  });

  final _TabItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFFE9C6FF) : const Color(0xFFB7B1CA);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(item.icon, color: color, size: 18),
          const SizedBox(height: 2),
          Text(
            item.label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _CenterGiftButton extends StatelessWidget {
  const _CenterGiftButton({
    required this.active,
    required this.item,
    required this.onTap,
  });

  final bool active;
  final _TabItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        height: 72,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFC65CFF).withValues(
                      alpha: active ? 0.8 : 0.55,
                    ),
                    blurRadius: active ? 26 : 20,
                    spreadRadius: active ? 3 : 1,
                  ),
                ],
              ),
            ),
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [
                    Color(0xFFFBECFF),
                    Color(0xFFC55CFF),
                    Color(0xFF6B2FE8),
                    Color(0xFF24103E),
                  ],
                  stops: [0.0, 0.34, 0.7, 1.0],
                ),
                border: Border.all(color: const Color(0xFFF3C8FF), width: 1.8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item.icon, color: Colors.white, size: 23),
                  const SizedBox(height: 1),
                  Text(
                    item.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StarfieldPainter extends CustomPainter {
  const StarfieldPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeWidth = 1;
    final points = <Offset>[];

    for (var i = 0; i < 52; i++) {
      final x = (math.sin(i * 12.9898) * 43758.5453).abs() % size.width;
      final y = (math.cos(i * 78.233) * 24634.6345).abs() % size.height;
      points.add(Offset(x, y));
    }

    paint.color = const Color(0x552E64FF);
    for (var i = 0; i < points.length - 1; i += 4) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }

    for (var i = 0; i < points.length; i++) {
      final radius = i % 9 == 0 ? 2.1 : 1.2;
      paint.color = i % 5 == 0
          ? const Color(0xFFEFB6FF)
          : const Color(0xFF8B66FF);
      canvas.drawCircle(points[i], radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CharacterPainter extends CustomPainter {
  const CharacterPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.52, size.height * 0.55);
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..shader =
          const SweepGradient(
            colors: [
              Color(0x00FFFFFF),
              Color(0xFFEFB6FF),
              Color(0xFF8A4DFF),
              Color(0x00FFFFFF),
            ],
          ).createShader(
            Rect.fromCircle(center: center, radius: size.width * 0.44),
          );

    canvas.drawCircle(center, size.width * 0.43, ringPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: size.width * 0.5),
      -2.5,
      4.1,
      false,
      ringPaint..strokeWidth = 1.4,
    );

    final glow = Paint()
      ..shader =
          const RadialGradient(
            colors: [Color(0xAA8D54FF), Color(0x00110925)],
          ).createShader(
            Rect.fromCircle(center: center, radius: size.width * 0.55),
          );
    canvas.drawCircle(center, size.width * 0.55, glow);

    final body = Path()
      ..moveTo(size.width * 0.16, size.height * 0.9)
      ..quadraticBezierTo(
        size.width * 0.38,
        size.height * 0.58,
        size.width * 0.51,
        size.height * 0.67,
      )
      ..quadraticBezierTo(
        size.width * 0.76,
        size.height * 0.79,
        size.width * 0.83,
        size.height * 0.96,
      )
      ..lineTo(size.width * 0.16, size.height * 0.96)
      ..close();
    canvas.drawPath(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFEDE8FF), Color(0xFF7B73A0), Color(0xFF211A38)],
        ).createShader(Offset.zero & size),
    );

    final hair = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF1E9FF), Color(0xFFB5A3E8), Color(0xFF6F5CB2)],
      ).createShader(Offset.zero & size);
    final head = Rect.fromCenter(
      center: Offset(size.width * 0.49, size.height * 0.48),
      width: size.width * 0.36,
      height: size.width * 0.42,
    );
    canvas.drawOval(head, hair);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.49, size.height * 0.51),
        width: size.width * 0.25,
        height: size.width * 0.29,
      ),
      Paint()..color = const Color(0xFFF3D6EA),
    );

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFEDE7FF);
    for (var i = 0; i < 12; i++) {
      final startX = size.width * (0.34 + i * 0.026);
      final path = Path()
        ..moveTo(startX, size.height * 0.34)
        ..quadraticBezierTo(
          startX - size.width * 0.04,
          size.height * 0.48,
          startX + size.width * 0.02,
          size.height * 0.68,
        );
      canvas.drawPath(path, stroke);
    }

    final eyePaint = Paint()..color = const Color(0xFF7B4FE4);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.43, size.height * 0.51),
        width: 11,
        height: 16,
      ),
      eyePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.55, size.height * 0.5),
        width: 11,
        height: 16,
      ),
      eyePaint,
    );

    final headset = Paint()..color = const Color(0xFF151527);
    canvas.drawCircle(
      Offset(size.width * 0.66, size.height * 0.43),
      27,
      headset,
    );
    canvas.drawCircle(
      Offset(size.width * 0.66, size.height * 0.43),
      17,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF8F75FF),
    );
    canvas.drawLine(
      Offset(size.width * 0.62, size.height * 0.4),
      Offset(size.width * 0.54, size.height * 0.31),
      Paint()
        ..color = const Color(0xFF10101D)
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );

    final sparkle = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFFFFB3FF);
    _drawSpark(
      canvas,
      Offset(size.width * 0.77, size.height * 0.24),
      16,
      sparkle,
    );
    _drawSpark(
      canvas,
      Offset(size.width * 0.15, size.height * 0.4),
      12,
      sparkle,
    );
  }

  void _drawSpark(Canvas canvas, Offset center, double radius, Paint paint) {
    canvas.drawLine(
      center.translate(-radius, 0),
      center.translate(radius, 0),
      paint,
    );
    canvas.drawLine(
      center.translate(0, -radius),
      center.translate(0, radius),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class VignetteLayer extends StatelessWidget {
  const VignetteLayer({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.1),
            Colors.transparent,
            Colors.black.withValues(alpha: 0.5),
            Colors.black.withValues(alpha: 0.88),
          ],
          stops: const [0, 0.36, 0.72, 1],
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 17),
    );
  }
}

class _SignalBar extends StatelessWidget {
  const _SignalBar({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

class _TabItem {
  const _TabItem(this.label, this.icon);

  final String label;
  final IconData icon;
}
