import 'dart:math' as math;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../../core/api_client.dart';
import '../../core/auth_session.dart';
import '../../core/media_cache.dart';

class GiftPageBody extends StatefulWidget {
  const GiftPageBody({super.key});

  @override
  State<GiftPageBody> createState() => _GiftPageBodyState();
}

class _GiftPageBodyState extends State<GiftPageBody> {
  final _apiClient = ApiClient();
  var _loading = false;
  var _checkingIn = false;
  var _availableDrawCount = 0;
  var _checkedInToday = false;
  String? _errorMessage;

  static const _characters = [
    GiftCharacterData('月海型 · 缇', '限定', Color(0xFF8E62FF), 0),
    GiftCharacterData('狐影型 · 光', '限定', Color(0xFFFF8A73), 1),
    GiftCharacterData('梦魇型 · 琉璃', '隐藏款', Color(0xFFFF5E93), 2),
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
        _checkedInToday = false;
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
        _checkedInToday = data['checkedInToday'] == true;
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

  Future<void> _checkIn() async {
    final token = AuthSession.token;
    if (token == null || token.isEmpty) {
      setState(() => _errorMessage = '请先登录后打卡');
      return;
    }
    if (_checkingIn || _checkedInToday) return;

    setState(() {
      _checkingIn = true;
      _errorMessage = null;
    });
    try {
      final data = await _apiClient.giftCheckIn(token: token);
      if (!mounted) return;
      setState(() {
        _availableDrawCount =
            int.tryParse(data['availableDrawCount']?.toString() ?? '') ?? 0;
        _checkedInToday = data['checkedInToday'] == true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('打卡成功，已赠送 3 次抽卡机会')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
      _loadSummary();
    } finally {
      if (mounted) {
        setState(() => _checkingIn = false);
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
                  height: 46,
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
                            '获取角色',
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
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: FilledButton.icon(
                    onPressed: !_checkedInToday && !_checkingIn && !_loading
                        ? _checkIn
                        : null,
                    icon: Icon(
                      _checkedInToday
                          ? Icons.check_circle_rounded
                          : Icons.calendar_month_rounded,
                      size: 17,
                    ),
                    label: Text(
                      _checkedInToday
                          ? '今日已打卡'
                          : (_checkingIn ? '打卡中...' : '今日打卡 +3 次'),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2B7A68),
                      disabledBackgroundColor: const Color(0xFF303342),
                      foregroundColor: Colors.white,
                      disabledForegroundColor: const Color(0xFF9EA3B8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
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
                    child: const Text('立即获取角色'),
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
        videoUrl = await _apiClient.giftMediaUrl(
          token: token,
          objectKey: objectKey,
        );
      }
      final cachedVideoPath = await MediaCache.cachedMediaPath(
        url: videoUrl,
        cacheKey: objectKey?.isNotEmpty == true ? objectKey! : videoUrl,
        extensionHint: 'mp4',
      );
      if (!mounted) return;
      final opened = await _openNativeVideo(MediaCache.fileUri(cachedVideoPath));
      if (!opened && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GiftVideoPage(
              title: widget.result.name,
              videoPath: cachedVideoPath,
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
                                _revealed ? '抽中了！' : '获取角色中.....',
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
  const GiftVideoPage({super.key, required this.title, required this.videoPath});

  final String title;
  final String videoPath;

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
    _controller = VideoPlayerController.file(File(widget.videoPath))
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _ready = true);
        _controller.play();
      }).catchError((error) {
        if (!mounted) return;
        setState(() => _errorMessage = '视频加载失败：$error');
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
                    : const _GiftVideoLoadingPanel(),
          ),
        ),
      ),
    );
  }
}

class _GiftVideoLoadingPanel extends StatelessWidget {
  const _GiftVideoLoadingPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: const Color(0xDD10101E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x667B5CFF)),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(minHeight: 5),
          SizedBox(height: 12),
          Text(
            '正在加载视频...',
            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
          ),
        ],
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
            '当前可获取角色次数',
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
                    errorMessage ?? '首次登录奖励 x 10',
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
          '概率 UP',
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

