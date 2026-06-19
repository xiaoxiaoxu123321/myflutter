import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:nfc_manager/nfc_manager_ios.dart';
import 'package:video_player/video_player.dart';
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
  static const _nativeVideoChannel = MethodChannel('dimensional/native_video');

  final _apiClient = ApiClient();
  var _flashTrigger = 0;
  var _nfcMessage = '请将卡片贴近';
  var _nfcSubMessage = '手机NFC感应区';
  var _nfcDataLines = <String>['NFC 已准备，等待卡片靠近'];
  DateTime? _lastDiscoveryAt;
  var _nfcSessionStarted = false;
  var _nfcSessionStarting = false;
  var _iosTagReadCompleted = false;
  final _nfcTrace = <String>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      _nfcMessage = '点击开始读取';
      _nfcSubMessage = '将卡片靠近 iPhone 顶部';
      _nfcDataLines = ['点击中间 NFC 图标开始扫描'];
    } else {
      _startNfcSession();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    NfcManager.instance.stopSession().catchError((_) {});
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (defaultTargetPlatform != TargetPlatform.iOS &&
        state == AppLifecycleState.resumed &&
        !_nfcSessionStarted) {
      _startNfcSession();
    }
  }

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
              _nfcDataLines = [..._nfcTrace];
            });
            return;
          }
          final dataLines = [...readResult.lines];
          dataLines.addAll(_nfcTrace);
          if (defaultTargetPlatform == TargetPlatform.iOS) {
            _iosTagReadCompleted = true;
            await _clearIosNfcSession(alertMessageIos: '读取成功');
          }
          if (AuthSession.isLoggedIn && readResult.text != null) {
            await _bindNfcText(readResult.text!, dataLines);
          } else if (AuthSession.isGuest && readResult.text != null) {
            await _playGuestNfcText(readResult.text!, dataLines);
          }
          if (!mounted) return;

          setState(() {
            _flashTrigger++;
            _nfcMessage = '已感应到卡片';
            _nfcSubMessage = AuthSession.isLoggedIn || AuthSession.isGuest ? '数据已读取' : '请先登录';
            _nfcDataLines = dataLines;
          });
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
            _nfcDataLines = [
              ..._nfcTrace,
              'iOS NFC 状态：${error.code.name}',
              '系统信息：${error.message}',
            ];
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
        _nfcDataLines = ['监听启动失败：${error.runtimeType}'];
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
    if (!mounted) return;
    setState(() {
      _nfcDataLines = [..._nfcTrace];
    });
  }

  Future<void> _clearIosNfcSession({String? alertMessageIos}) async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
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
        final phone = asset['boundUserPhone']?.toString() ?? '';
        lines.add('资产绑定：$title');
        if (phone.isNotEmpty) {
          lines.add('关联用户：$phone');
        }
        return;
      }
      lines.add('已读取已绑定 NFC 卡片');
      if (mounted) await _handleScannedNfcCard(scan, token);
    } catch (error) {
      lines.add('NFC 处理失败：${error.toString().replaceFirst('Exception: ', '')}');
    }
  }

  Future<void> _playGuestNfcText(String text, List<String> lines) async {
    try {
      final scan = await _apiClient.publicScanNfcText(text: text);
      final status = scan['status']?.toString() ?? '';
      if (status == 'AVAILABLE') {
        lines.add('游客访问：该 NFC 卡片尚未绑定人物');
        return;
      }
      if (status == 'NOT_FOUND') {
        lines.add('游客访问：未找到该 NFC 卡片');
        return;
      }
      final hasCharacter = scan['characterCollectionId'] != null;
      final videoUrl = scan['previewVideoUrl']?.toString() ?? '';
      final objectKey = scan['previewVideoObjectKey']?.toString() ?? '';
      if (!hasCharacter || (videoUrl.isEmpty && objectKey.isEmpty)) {
        lines.add('游客访问：该 NFC 卡片未关联可播放人物');
        return;
      }
      lines.add('游客访问：播放关联人物视频');
      if (mounted) await _openNfcCardVideoDialog(scan, null);
    } catch (error) {
      lines.add('游客访问失败：${error.toString().replaceFirst('Exception: ', '')}');
    }
  }

  Future<void> _handleScannedNfcCard(Map<String, dynamic> card, String token) async {
    final ownedByCurrentUser = card['ownedByCurrentUser'] == true;
    final giftModeEnabled = card['giftModeEnabled'] == true;
    if (ownedByCurrentUser || !giftModeEnabled) {
      await _openNfcCardVideoDialog(card, token);
      return;
    }
    await _showGiftCardAcceptDialog(card, token);
  }

  Future<void> _showGiftCardAcceptDialog(Map<String, dynamic> card, String token) async {
    final imageUrl = card['coverImageUrl']?.toString();
    final title = _nfcCardTitle(card);
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 260,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(
                aspectRatio: 0.72,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: imageUrl == null || imageUrl.isEmpty
                      ? const ColoredBox(
                          color: Color(0xFF17142A),
                          child: Icon(Icons.star_border_rounded, size: 70, color: Color(0xFFD9C4FF)),
                        )
                      : Image.network(imageUrl, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 12),
              const Text('该卡片已开启赠送模式，接受后播放视频。', textAlign: TextAlign.center),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('接受')),
        ],
      ),
    );
    if (accepted != true || !mounted) return;
    final cardId = (card['cardId'] as num?)?.toInt();
    if (cardId == null) return;
    try {
      await _apiClient.claimNfcCard(token: token, cardId: cardId);
      if (!mounted) return;
      await _openNfcCardVideoDialog(card, token);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _openNfcCardVideoDialog(Map<String, dynamic> card, String? token) async {
    final objectKey = card['previewVideoObjectKey']?.toString();
    final fallbackUrl = card['previewVideoUrl']?.toString();
    final audioObjectKey = card['audioObjectKey']?.toString();
    final fallbackAudioUrl = card['audioUrl']?.toString();
    final canProxyVideo = token != null && token.isNotEmpty && objectKey != null && objectKey.isNotEmpty;
    final canUseDirectVideo = fallbackUrl != null && fallbackUrl.isNotEmpty;
    if (!canProxyVideo && !canUseDirectVideo) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('暂无可播放视频')),
      );
      return;
    }

    var loadingVisible = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const NfcVideoLoadingDialog(),
    );

    try {
      final videoUrl = canProxyVideo
          ? await _apiClient.giftVideoProxyUrl(token: token, objectKey: objectKey!)
          : (fallbackUrl ?? '');
      String? audioUrl;
      if (audioObjectKey != null && audioObjectKey.isNotEmpty && token != null && token.isNotEmpty) {
        audioUrl = await _apiClient.giftMediaUrl(token: token, objectKey: audioObjectKey);
      } else if (fallbackAudioUrl != null && fallbackAudioUrl.isNotEmpty) {
        audioUrl = fallbackAudioUrl;
      }
      if (!mounted) return;

      if (defaultTargetPlatform == TargetPlatform.android) {
        Navigator.of(context, rootNavigator: true).pop();
        loadingVisible = false;
        final opened = await _openNativeVideo(videoUrl, _nfcCardTitle(card), audioUrl: audioUrl);
        if (opened || !mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('视频播放器打开失败，请稍后重试')),
        );
        return;
      }

      final prepared = await _prepareNfcVideo(videoUrl: videoUrl, audioUrl: audioUrl);
      if (!mounted) {
        prepared.dispose();
        return;
      }
      Navigator.of(context, rootNavigator: true).pop();
      loadingVisible = false;

      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (_) => NfcVideoDialog(
          title: _nfcCardTitle(card),
          prepared: prepared,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      if (loadingVisible) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<_PreparedNfcVideo> _prepareNfcVideo({required String videoUrl, String? audioUrl}) async {
    final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
    VideoPlayerController? audioController;
    try {
      await controller.initialize();
      if (audioUrl != null && audioUrl.isNotEmpty) {
        await controller.setVolume(0);
        audioController = VideoPlayerController.networkUrl(Uri.parse(audioUrl));
        await audioController.initialize();
      } else {
        await controller.setVolume(1);
      }
      await controller.setLooping(true);
      await audioController?.setLooping(true);
      await controller.play();
      await audioController?.play();
      await _waitForVideoPlaybackStart(controller);
      return _PreparedNfcVideo(video: controller, audio: audioController);
    } catch (_) {
      await controller.dispose();
      await audioController?.dispose();
      rethrow;
    }
  }

  Future<void> _waitForVideoPlaybackStart(VideoPlayerController controller) async {
    const timeout = Duration(seconds: 12);
    const interval = Duration(milliseconds: 120);
    final startedAt = DateTime.now();
    while (DateTime.now().difference(startedAt) < timeout) {
      final value = controller.value;
      if (value.hasError) {
        throw Exception(value.errorDescription ?? '视频加载失败');
      }
      if (value.isPlaying && !value.isBuffering) {
        return;
      }
      await Future<void>.delayed(interval);
    }
  }

  Future<bool> _openNativeVideo(String videoUrl, String title, {String? audioUrl}) async {
    try {
      final opened = await _nativeVideoChannel.invokeMethod<bool>(
        'openVideo',
        {
          'url': videoUrl,
          'title': title,
          if (audioUrl != null && audioUrl.isNotEmpty) 'audioUrl': audioUrl,
        },
      );
      return opened == true;
    } on MissingPluginException {
      return false;
    } on PlatformException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message ?? '原生播放器打开失败')),
        );
      }
      return false;
    }
  }

  String _nfcCardTitle(Map<String, dynamic> card) {
    final characterName = card['characterName']?.toString();
    if (characterName != null && characterName.isNotEmpty) return characterName;
    return card['title']?.toString() ?? 'NFC 卡片';
  }

  Future<void> _handleNfcOrbTap() async {
    if (_nfcSessionStarted || _nfcSessionStarting) return;
    await _clearIosNfcSession();
    await _startNfcSession();
  }

  void _goLoginIfNeeded(List<String> nfcDataLines, String? nfcText) {
    if (AuthSession.isLoggedIn || AuthSession.isGuest) return;
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
                  Color(0x660A0920),
                  Color(0x55171039),
                  Color(0x66160C2F),
                  Color(0xAA080613),
                ],
              ),
            ),
          ),
          const CustomPaint(painter: StarfieldPainter()),
          const Positioned.fill(child: VignetteLayer()),
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

class _PreparedNfcVideo {
  const _PreparedNfcVideo({required this.video, this.audio});

  final VideoPlayerController video;
  final VideoPlayerController? audio;

  void dispose() {
    video.dispose();
    audio?.dispose();
  }
}

class NfcVideoDialog extends StatefulWidget {
  const NfcVideoDialog({super.key, required this.title, required this.prepared});

  final String title;
  final _PreparedNfcVideo prepared;

  @override
  State<NfcVideoDialog> createState() => _NfcVideoDialogState();
}

class NfcVideoLoadingDialog extends StatelessWidget {
  const NfcVideoLoadingDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            LinearProgressIndicator(minHeight: 5),
            SizedBox(height: 14),
            Text(
              '正在加载视频...',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _NfcVideoDialogState extends State<NfcVideoDialog> {
  late final VideoPlayerController _controller;
  VideoPlayerController? _audioController;

  @override
  void initState() {
    super.initState();
    _controller = widget.prepared.video;
    _audioController = widget.prepared.audio;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_controller.value.isPlaying) {
        _controller.play();
      }
      _audioController?.play();
    });
  }

  @override
  void dispose() {
    widget.prepared.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: AspectRatio(
        aspectRatio: 9 / 16,
        child: Stack(
          fit: StackFit.expand,
          children: [
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
                color: Colors.white,
                tooltip: '关闭',
              ),
            ),
            Positioned(
              left: 14,
              right: 54,
              top: 14,
              child: Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
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
