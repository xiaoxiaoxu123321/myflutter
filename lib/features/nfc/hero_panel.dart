import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:nfc_manager/nfc_manager_ios.dart';
import '../../core/api_client.dart';
import '../../core/auth_session.dart';
import '../login/login_page.dart';
class _NfcReadResult {
  const _NfcReadResult({required this.lines, this.text});

  final List<String> lines;
  final String? text;
}

class HeroPanel extends StatefulWidget {
  const HeroPanel({super.key});

  @override
  State<HeroPanel> createState() => _HeroPanelState();
}

class _HeroPanelState extends State<HeroPanel> with WidgetsBindingObserver {
  final _apiClient = ApiClient();
  var _flashTrigger = 0;
  var _nfcMessage = '请将卡片贴近';
  var _nfcSubMessage = '手机NFC感应区';
  var _nfcDataLines = <String>['NFC 已准备，等待卡片靠近'];
  DateTime? _lastDiscoveryAt;
  var _nfcSessionStarted = false;
  var _nfcSessionStarting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startNfcSession();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    NfcManager.instance.stopSession().catchError((_) {});
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_nfcSessionStarted) {
      _startNfcSession();
    }
  }

  Future<void> _startNfcSession() async {
    if (_nfcSessionStarting || _nfcSessionStarted) return;
    _nfcSessionStarting = true;
    try {
      final availability = await NfcManager.instance.checkAvailability();
      if (!mounted) return;

      if (availability != NfcAvailability.enabled) {
        setState(() {
          _nfcMessage = 'NFC暂不可用';
          _nfcSubMessage = _nfcUnavailableMessage(availability);
          _nfcDataLines = ['NFC 状态：${availability.name}'];
        });
        _nfcSessionStarting = false;
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
        onSessionErrorIos: (error) {
          _nfcSessionStarted = false;
          if (!mounted) return;
          final message = _iosNfcSessionMessage(error);
          setState(() {
            _nfcMessage = message.title;
            _nfcSubMessage = message.subtitle;
            _nfcDataLines = [
              'iOS NFC 状态：${error.code.name}',
              '系统信息：${error.message}',
            ];
          });
        },
      );
      _nfcSessionStarted = true;
    } catch (error) {
      _nfcSessionStarted = false;
      if (!mounted) return;
      setState(() {
        _nfcMessage = 'NFC监听未启动';
        _nfcSubMessage = '请确认设备支持NFC';
        _nfcDataLines = ['监听启动失败：${error.runtimeType}'];
      });
    } finally {
      _nfcSessionStarting = false;
    }
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
        subtitle: '请查看下方 iOS 错误信息',
      ),
    };
  }

  Future<_NfcReadResult> _readTagData(NfcTag tag) async {
    final lines = <String>['读取时间：${_timeText(DateTime.now())}'];
    String? nfcText;
    final androidTag = NfcTagAndroid.from(tag);

    final androidNdef = NdefAndroid.from(tag);
    final iosNdef = NdefIos.from(tag);
    final message = androidNdef != null
        ? await androidNdef.getNdefMessage()
        : await iosNdef?.readNdef();

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
          const Positioned.fill(child: CharacterArt()),
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
