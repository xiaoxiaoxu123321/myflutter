import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../../core/api_client.dart';
import '../../core/auth_session.dart';

class AssetPageBody extends StatefulWidget {
  const AssetPageBody({super.key});

  @override
  State<AssetPageBody> createState() => _AssetPageBodyState();
}

class _AssetPageBodyState extends State<AssetPageBody> {
  static const _nativeVideoChannel = MethodChannel('dimensional/native_video');

  final _apiClient = ApiClient();
  var _characters = <AssetCharacterData>[];
  final _likedCollectionIds = <int>{};
  var _loading = false;
  var _openingVideo = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCharacters();
  }

  Future<void> _loadCharacters() async {
    final token = AuthSession.token;
    if (token == null || token.isEmpty) {
      setState(() => _errorMessage = '请先登录后查看资产');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final data = await _apiClient.giftCollections(token: token);
      if (!mounted) return;
      setState(() {
        _characters = data
            .map(AssetCharacterData.fromJson)
            .toList(growable: false);
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
                    Text(
                      '(${_characters.length}/20)',
                      style: TextStyle(
                        color: Color(0xFFE5DAFF),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
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
                  child: _buildContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return _AssetEmptyState(
        icon: Icons.lock_outline_rounded,
        message: _errorMessage!,
        onRetry: _loadCharacters,
      );
    }
    if (_characters.isEmpty) {
      return _AssetEmptyState(
        icon: Icons.style_outlined,
        message: '还没有抽到角色',
        onRetry: _loadCharacters,
      );
    }
    return RefreshIndicator(
      onRefresh: _loadCharacters,
      child: GridView.builder(
        padding: EdgeInsets.zero,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.78,
        ),
        itemCount: _characters.length,
        itemBuilder: (context, index) {
          final character = _characters[index];
          return AssetCharacterCard(
            data: character,
            liked: _likedCollectionIds.contains(character.collectionId),
            openingVideo: _openingVideo,
            onTap: () => _openVideo(character),
            onLike: () => _toggleLike(character),
          );
        },
      ),
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
    if (token == null || token.isEmpty) {
      _showMessage('请先登录后播放视频');
      return;
    }
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
            builder: (_) => AssetVideoPage(
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
    required this.onRetry,
  });

  final IconData icon;
  final String message;
  final VoidCallback onRetry;

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
          const SizedBox(height: 12),
          TextButton(
            onPressed: onRetry,
            child: const Text('刷新'),
          ),
        ],
      ),
    );
  }
}

class AssetVideoPage extends StatefulWidget {
  const AssetVideoPage({super.key, required this.title, required this.videoUrl});

  final String title;
  final String videoUrl;

  @override
  State<AssetVideoPage> createState() => _AssetVideoPageState();
}

class _AssetVideoPageState extends State<AssetVideoPage> {
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
    this.collectionId,
    this.name,
    this.series,
    this.accent,
    this.variant,
    this.coverImageUrl,
    this.previewVideoObjectKey,
    this.previewVideoUrl,
    this.sourceType,
  );

  factory AssetCharacterData.fromJson(Map<String, dynamic> json) {
    final name = json['name']?.toString() ?? '未命名角色';
    final rarity = json['rarity']?.toString() ?? 'NORMAL';
    return AssetCharacterData(
      (json['collectionId'] as num?)?.toInt() ?? name.hashCode,
      name,
      rarity,
      _accentForRarity(rarity),
      (json['collectionId'] as num?)?.toInt() ?? name.hashCode,
      json['coverImageUrl']?.toString(),
      json['previewVideoObjectKey']?.toString(),
      json['previewVideoUrl']?.toString(),
      (json['sourceType'] as num?)?.toInt() ?? 1,
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
