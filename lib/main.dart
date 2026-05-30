import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(const DimensionalApp());
}

class AuthSession {
  static bool isLoggedIn = false;
  static String? token;
  static Map<String, dynamic>? user;
}

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
                      1 => const AssetPageBody(),
                      2 => const GiftPageBody(),
                      4 => const ProfilePageBody(),
                      _ => const HeroPanel(),
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
  const HeroPanel({super.key});

  @override
  State<HeroPanel> createState() => _HeroPanelState();
}

class _HeroPanelState extends State<HeroPanel> {
  final _apiClient = ApiClient();
  var _flashTrigger = 0;
  var _nfcMessage = '请将卡片贴近';
  var _nfcSubMessage = '手机NFC感应区';
  var _nfcDataLines = <String>['NFC 已准备，等待卡片靠近'];
  DateTime? _lastDiscoveryAt;

  @override
  void initState() {
    super.initState();
    _startNfcSession();
  }

  @override
  void dispose() {
    NfcManager.instance.stopSession().catchError((_) {});
    super.dispose();
  }

  Future<void> _startNfcSession() async {
    try {
      final availability = await NfcManager.instance.checkAvailability();
      if (!mounted) return;

      if (availability != NfcAvailability.enabled) {
        setState(() {
          _nfcMessage = 'NFC暂不可用';
          _nfcSubMessage = '请确认系统 NFC 已开启';
          _nfcDataLines = ['NFC 状态：${availability.name}'];
        });
        return;
      }

      setState(() {
        _nfcMessage = '请将卡片贴近';
        _nfcSubMessage = '手机NFC感应区';
        _nfcDataLines = ['NFC 已开启，等待卡片靠近'];
      });

      await NfcManager.instance.startSession(
        pollingOptions: {
          NfcPollingOption.iso14443,
          NfcPollingOption.iso15693,
          NfcPollingOption.iso18092,
        },
        onDiscovered: (tag) async {
          final now = DateTime.now();
          if (_lastDiscoveryAt != null &&
              now.difference(_lastDiscoveryAt!) <
                  const Duration(milliseconds: 900)) {
            return;
          }
          _lastDiscoveryAt = now;

          final readResult = await _readTagData(tag);
          final dataLines = [...readResult.lines];
          if (AuthSession.isLoggedIn && readResult.text != null) {
            await _bindNfcText(readResult.text!, dataLines);
          }
          if (!mounted) return;

          setState(() {
            _flashTrigger++;
            _nfcMessage = '已感应到卡片';
            _nfcSubMessage = AuthSession.isLoggedIn ? '数据已读取' : '请先登录';
            _nfcDataLines = dataLines;
          });
          _goLoginIfNeeded(dataLines, readResult.text);
        },
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _nfcMessage = 'NFC监听未启动';
        _nfcSubMessage = '请确认设备支持NFC';
        _nfcDataLines = ['监听启动失败：${error.runtimeType}'];
      });
    }
  }

  Future<_NfcReadResult> _readTagData(NfcTag tag) async {
    final lines = <String>['读取时间：${_timeText(DateTime.now())}'];
    String? nfcText;
    final androidTag = NfcTagAndroid.from(tag);

    if (androidTag == null) {
      lines.add('已发现 NFC 标签');
      lines.add('原始平台数据不可解析为 Android Tag');
      return _NfcReadResult(lines: lines);
    }

    lines.add('Tag ID：${_hex(androidTag.id)}');
    lines.add('Tech：${androidTag.techList.join(', ')}');

    final ndef = NdefAndroid.from(tag);
    if (ndef == null) {
      lines.add('NDEF：不支持或没有 NDEF 数据');
      return _NfcReadResult(lines: lines);
    }

    lines.add('NDEF 类型：${ndef.type}');
    lines.add('可写入：${ndef.isWritable ? '是' : '否'}');
    lines.add('最大容量：${ndef.maxSize} bytes');

    final message = await ndef.getNdefMessage();
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
      final asset = await _apiClient.bindNfcText(token: token, text: text);
      final title = asset['title']?.toString() ?? text;
      final phone = asset['boundUserPhone']?.toString() ?? '';
      lines.add('资产绑定：$title');
      if (phone.isNotEmpty) {
        lines.add('关联用户：$phone');
      }
    } catch (error) {
      lines.add('资产绑定失败：${error.toString().replaceFirst('Exception: ', '')}');
    }
  }

  Future<void> _simulateRead() async {
    final dataLines = [
      '读取时间：${_timeText(DateTime.now())}',
      'Tag ID：04 a2 b3 c4 d5 66 80',
      'Tech：android.nfc.tech.NfcA, android.nfc.tech.Ndef',
      'NDEF 类型：org.nfcforum.ndef.type2',
      '记录数量：1',
      'Record 1',
      '  TNF：wellKnown',
      '  Type：T',
      '  Payload(text)：123456',
    ];

    if (AuthSession.isLoggedIn) {
      await _bindNfcText('123456', dataLines);
    }
    if (!mounted) return;

    setState(() {
      _flashTrigger++;
      _nfcMessage = '已模拟感应';
      _nfcSubMessage = AuthSession.isLoggedIn ? '数据已读取' : '请先登录';
      _nfcDataLines = dataLines;
    });
    _goLoginIfNeeded(dataLines, '123456');
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
      setState(() {
        _nfcDataLines = [...nfcDataLines];
      });
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
            left: 18,
            right: 18,
            top: 122,
            child: NfcDataPanel(lines: _nfcDataLines),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 86,
            child: Center(
              child: NfcOrb(flashTrigger: _flashTrigger, onTap: _simulateRead),
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

class NfcDataPanel extends StatelessWidget {
  const NfcDataPanel({super.key, required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 132,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xCC120F24),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x886F55AD)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x88000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.nfc_rounded, color: Color(0xFFE5B8FF), size: 17),
              SizedBox(width: 6),
              Text(
                'NFC读取结果',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                lines.join('\n'),
                style: const TextStyle(
                  color: Color(0xFFE8DFFF),
                  fontSize: 10.5,
                  height: 1.25,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ],
      ),
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

class AssetPageBody extends StatelessWidget {
  const AssetPageBody({super.key});

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
                const AssetSegmentedTabs(),
                const SizedBox(height: 14),
                Row(
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
                        onPressed: () {},
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
                  child: AssetCharacterGrid(fallbackCharacters: _characters),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

        final characters = (snapshot.data ?? const [])
            .map(AssetCharacterData.fromJson)
            .toList(growable: false);
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

class AssetSegmentedTabs extends StatelessWidget {
  const AssetSegmentedTabs({super.key});

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
          Expanded(
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF54389A),
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x554F34A6),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Text(
                '我的角色',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                '我的卡片',
                style: TextStyle(
                  color: Color(0xFFB8B2CE),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ],
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

  static Color _accentForRarity(String rarity) {
    return switch (rarity.toUpperCase()) {
      'SSR' => const Color(0xFFFFC35B),
      'SR' => const Color(0xFFE45BBA),
      'R' => const Color(0xFF7DB0FF),
      _ => const Color(0xFF9970FF),
    };
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
      _TabItem('互动', Icons.favorite_border_rounded),
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
