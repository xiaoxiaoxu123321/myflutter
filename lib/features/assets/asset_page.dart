import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:video_player/video_player.dart';
import '../../core/api_client.dart';
import '../../core/auth_session.dart';

int _sortRarity(String a, String b) {
  const order = {'SSR': 0, 'SR': 1, 'R': 2, 'NORMAL': 3, 'CUSTOM': 4};
  return (order[a] ?? 99).compareTo(order[b] ?? 99);
}

String _categoryLabel(String category) {
  return category == 'ALL' ? '全部' : category;
}

String? _jsonString(Object? value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty || text.toLowerCase() == 'null') {
    return null;
  }
  return text;
}

class AssetPageBody extends StatefulWidget {
  const AssetPageBody({super.key});

  @override
  State<AssetPageBody> createState() => _AssetPageBodyState();
}

class _AssetPageBodyState extends State<AssetPageBody> {
  static const _nativeVideoChannel = MethodChannel('dimensional/native_video');

  final _apiClient = ApiClient();
  var _characters = <AssetCharacterData>[];
  var _nfcCards = <AssetNfcCardData>[];
  final _likedCollectionIds = <int>{};
  var _loading = false;
  var _loadingCards = false;
  var _openingVideo = false;
  var _selectedTab = 0;
  var _selectedCharacterCategory = 'ALL';
  String? _errorMessage;

  String? _cardErrorMessage;

  List<AssetCharacterGroup> get _characterGroups => AssetCharacterGroup.group(_characters);

  List<AssetCharacterGroup> get _visibleCharacterGroups {
    final groups = _characterGroups;
    if (_selectedCharacterCategory == 'ALL') return groups;
    return groups
        .where((group) => group.primary.series.toUpperCase() == _selectedCharacterCategory)
        .toList(growable: false);
  }

  List<String> get _characterCategories {
    final values = _characterGroups.map((group) => group.primary.series.toUpperCase()).toSet().toList()
      ..sort(_sortRarity);
    return ['ALL', ...values];
  }

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

  Future<void> _loadNfcCards() async {
    final token = AuthSession.token;
    if (token == null || token.isEmpty) {
      setState(() => _cardErrorMessage = '请先登录后查看 NFC 卡片');
      return;
    }

    setState(() {
      _loadingCards = true;
      _cardErrorMessage = null;
    });

    try {
      final data = await _apiClient.nfcCards(token: token);
      if (!mounted) return;
      setState(() {
        _nfcCards = data.map(AssetNfcCardData.fromJson).toList(growable: false);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _cardErrorMessage = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _loadingCards = false);
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
                AssetSegmentedTabs(
                  selectedIndex: _selectedTab,
                  onSelected: (index) {
                    if (_selectedTab == index) return;
                    setState(() => _selectedTab = index);
                    if (index == 1 && _nfcCards.isEmpty) {
                      _loadNfcCards();
                    }
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Text(
                      _selectedTab == 0 ? '我的角色' : '我的卡片',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _selectedTab == 0 ? '(${_characters.length}/20)' : '(${_nfcCards.length})',
                      style: TextStyle(
                        color: Color(0xFFE5DAFF),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                    const Spacer(),
                    if (_selectedTab == 0)
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
    if (_selectedTab == 1) {
      return _buildNfcCardsContent();
    }
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
    final groups = _visibleCharacterGroups;
    return RefreshIndicator(
      onRefresh: _loadCharacters,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(
            child: AssetCategoryFilter(
              categories: _characterCategories,
              selectedCategory: _selectedCharacterCategory,
              onSelected: (category) => setState(() => _selectedCharacterCategory = category),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 10)),
          SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.78,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final group = groups[index];
                final character = group.primary;
                return AssetCharacterCard(
                  data: character,
                  count: group.count,
                  liked: _likedCollectionIds.contains(character.collectionId),
                  openingVideo: _openingVideo,
                  onTap: () => _openVideo(character),
                  onLike: () => _toggleLike(character),
                );
              },
              childCount: groups.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNfcCardsContent() {
    if (_loadingCards) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_cardErrorMessage != null) {
      return _AssetEmptyState(
        icon: Icons.credit_card_off_rounded,
        message: _cardErrorMessage!,
        onRetry: _loadNfcCards,
      );
    }
    if (_nfcCards.isEmpty) {
      return _AssetEmptyState(
        icon: Icons.credit_card_rounded,
        message: '还没有绑定 NFC 卡片',
        onRetry: _loadNfcCards,
      );
    }
    return RefreshIndicator(
      onRefresh: _loadNfcCards,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        itemCount: _nfcCards.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, index) => AssetNfcCardTile(
          data: _nfcCards[index],
          onTap: () => _openNfcCardDetail(_nfcCards[index]),
        ),
      ),
    );
  }

  Future<void> _openNfcCardDetail(AssetNfcCardData card) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AssetNfcCardManagePage(
          card: card,
          characters: _characters,
          apiClient: _apiClient,
        ),
      ),
    );
    if (changed == true) {
      await _loadNfcCards();
      await _loadCharacters();
    }
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
        await _loadCharacters();
        _showMessage('自定义人物已保存');
      }
    } catch (error) {
      if (!mounted) return;
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
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
    final isCustomCharacter = character.sourceType == 2;
    final audioObjectKey = isCustomCharacter ? character.audioObjectKey : null;
    final fallbackAudioUrl = isCustomCharacter ? character.audioUrl : null;
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
      String? audioUrl;
      if (audioObjectKey != null && audioObjectKey.isNotEmpty) {
        audioUrl = await _apiClient.giftMediaUrl(
          token: token,
          objectKey: audioObjectKey,
        );
      } else if (fallbackAudioUrl != null && fallbackAudioUrl.isNotEmpty) {
        audioUrl = fallbackAudioUrl;
      }
      if (!mounted) return;
      if (audioUrl != null && audioUrl.isNotEmpty) {
        final opened = await _openNativeVideo(videoUrl, character.name, audioUrl: audioUrl);
        if (opened || !mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AssetVideoPage(
              title: character.name,
              videoUrl: videoUrl,
              audioUrl: audioUrl,
            ),
          ),
        );
        return;
      }
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
  const AssetVideoPage({super.key, required this.title, required this.videoUrl, this.audioUrl});

  final String title;
  final String videoUrl;
  final String? audioUrl;

  @override
  State<AssetVideoPage> createState() => _AssetVideoPageState();
}

class _AssetVideoPageState extends State<AssetVideoPage> {
  late final VideoPlayerController _controller;
  VideoPlayerController? _audioController;
  var _ready = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializePlayers();
  }

  Future<void> _initializePlayers() async {
    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await _controller.initialize();

      final audioUrl = widget.audioUrl;
      if (audioUrl != null && audioUrl.isNotEmpty) {
        await _controller.setVolume(0);
        final audioController = VideoPlayerController.networkUrl(Uri.parse(audioUrl));
        _audioController = audioController;
        await audioController.initialize();
      } else {
        await _controller.setVolume(1);
      }

      if (!mounted) return;
      setState(() => _ready = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _playPlayers();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = '视频加载失败：${error.toString()}');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _audioController?.dispose();
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
                                ? _pausePlayers()
                                : _playPlayers();
                          });
                        },
                        child: AspectRatio(
                          aspectRatio: _controller.value.aspectRatio,
                          child: VideoPlayer(_controller),
                        ),
                      )
                    : const _VideoLoadingPanel(),
          ),
        ),
      ),
    );
  }

  void _pausePlayers() {
    _controller.pause();
    _audioController?.pause();
  }

  void _playPlayers() {
    _controller.play();
    _audioController?.play();
  }
}

class _VideoLoadingPanel extends StatelessWidget {
  const _VideoLoadingPanel();

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
  final _recorder = AudioRecorder();
  XFile? _image;
  XFile? _video;
  XFile? _audio;
  Map<String, dynamic>? _uploadedImage;
  Map<String, dynamic>? _uploadedVideo;
  Map<String, dynamic>? _uploadedAudio;
  String? _recordingAudioPath;
  Timer? _recordingTimer;
  Duration _recordingElapsed = Duration.zero;
  Duration _recordedAudioDuration = Duration.zero;
  var _recordingAudio = false;
  var _uploadingImage = false;
  var _uploadingVideo = false;
  var _uploadingAudio = false;
  var _saving = false;
  String? _errorMessage;

  bool get _uploadingMedia => _uploadingImage || _uploadingVideo || _uploadingAudio;

  String get _audioSubtitle {
    if (_recordingAudio) return '录音中 ${_formatDuration(_recordingElapsed)}，再次点击停止';
    if (_uploadingAudio) return '语音上传中...';
    if (_uploadedAudio != null) return '语音已上传 ${_formatDuration(_recordedAudioDuration)}';
    final audio = _audio;
    if (audio != null) return '已录制语音 ${_formatDuration(_recordedAudioDuration)}';
    return '点击开始录音，可选';
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _recordingTimer?.cancel();
    _recorder.dispose();
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
                      subtitle: _uploadingVideo
                          ? '视频上传中...'
                          : (_uploadedVideo != null ? '视频已上传' : (_video?.name ?? '可选，支持 MP4 / MOV / WEBM')),
                      onTap: _pickVideo,
                    ),
                    const SizedBox(height: 10),
                    _fileTile(
                      icon: _recordingAudio ? Icons.stop_circle_outlined : Icons.mic_rounded,
                      title: '人物语音',
                      subtitle: _audioSubtitle,
                      onTap: _toggleAudioRecording,
                      highlighted: true,
                      trailing: Icon(
                        _recordingAudio ? Icons.stop_rounded : Icons.chevron_right_rounded,
                        color: _recordingAudio ? const Color(0xFFFF9BA6) : const Color(0xFFC5A7FF),
                      ),
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
                        onPressed: (_saving || _uploadingMedia) ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF6434C5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _saving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : Text(
                                _uploadingMedia ? '媒体上传中' : '保存',
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                              ),
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
              child: Text(
                _image?.name ?? '上传人物图片',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFFD4C9F1), fontSize: 15, fontWeight: FontWeight.w700),
              ),
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
    Widget? trailing,
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
            trailing ?? const Icon(Icons.chevron_right_rounded, color: Color(0xFF8C86A9)),
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
    if (image == null || !mounted) return;
    setState(() {
      _image = image;
      _uploadedImage = null;
      _uploadingImage = true;
      _errorMessage = null;
    });
    try {
      final uploaded = await _apiClient.uploadCustomCharacterMedia(
        token: widget.token,
        file: image,
        mediaType: 'IMAGE',
      );
      if (!mounted) return;
      setState(() {
        _uploadedImage = uploaded;
        _uploadingImage = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _image = null;
        _uploadedImage = null;
        _uploadingImage = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _pickVideo() async {
    final video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video == null || !mounted) return;
    setState(() {
      _video = video;
      _uploadedVideo = null;
      _uploadingVideo = true;
      _errorMessage = null;
    });
    try {
      await _uploadSelectedVideo();
    } catch (error) {
      if (!mounted) return;
      final message = error.toString().replaceFirst('Exception: ', '');
      setState(() {
        _uploadedVideo = null;
        _uploadingVideo = false;
        _errorMessage = '人物视频上传失败，请重新选择视频：$message';
      });
    }
  }

  Future<void> _uploadSelectedVideo() async {
    final video = _video;
    if (video == null) return;
    if (mounted) {
      setState(() {
        _uploadingVideo = true;
        _errorMessage = null;
      });
    }
    try {
      final uploaded = await _apiClient.uploadCustomCharacterMedia(
        token: widget.token,
        file: video,
        mediaType: 'VIDEO',
      );
      if (!mounted) return;
      setState(() {
        _uploadedVideo = uploaded;
        _uploadingVideo = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _uploadingVideo = false);
      }
      rethrow;
    }
  }

  Future<void> _toggleAudioRecording() async {
    if (_recordingAudio) {
      await _stopAudioRecording();
    } else {
      await _startAudioRecording();
    }
  }

  Future<void> _startAudioRecording() async {
    try {
      final allowed = await _recorder.hasPermission();
      if (!allowed) {
        if (mounted) setState(() => _errorMessage = '需要麦克风权限才能录制语音');
        return;
      }
      final tempDir = await getTemporaryDirectory();
      final recordingPath = '${tempDir.path}${Platform.pathSeparator}voice-${DateTime.now().millisecondsSinceEpoch}.wav';
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 44100,
          numChannels: 1,
          echoCancel: true,
          noiseSuppress: true,
        ),
        path: recordingPath,
      );
      _recordingTimer?.cancel();
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _recordingElapsed += const Duration(seconds: 1));
      });
      if (!mounted) return;
      setState(() {
        _recordingAudio = true;
        _recordingAudioPath = recordingPath;
        _recordingElapsed = Duration.zero;
        _recordedAudioDuration = Duration.zero;
        _audio = null;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _stopAudioRecording() async {
    try {
      final stoppedPath = await _recorder.stop();
      final audioPath = stoppedPath ?? _recordingAudioPath;
      _recordingTimer?.cancel();
      if (!mounted) return;
      if (audioPath == null || !File(audioPath).existsSync() || File(audioPath).lengthSync() == 0) {
        setState(() {
          _recordingAudio = false;
          _recordingAudioPath = null;
          _recordingElapsed = Duration.zero;
          _recordedAudioDuration = Duration.zero;
          _errorMessage = '没有录到语音，请重试';
        });
        return;
      }
      setState(() {
        _recordedAudioDuration = _recordingElapsed;
        _recordingAudio = false;
        _recordingAudioPath = null;
        _recordingElapsed = Duration.zero;
        _audio = XFile(
          audioPath,
          mimeType: 'audio/wav',
          name: audioPath.split(Platform.pathSeparator).last,
        );
        _uploadedAudio = null;
      });
      await _uploadRecordedAudio();
    } catch (error) {
      _recordingTimer?.cancel();
      if (!mounted) return;
      setState(() {
        _recordingAudio = false;
        _recordingAudioPath = null;
        _recordingElapsed = Duration.zero;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _uploadRecordedAudio() async {
    final audio = _audio;
    if (audio == null) return;
    setState(() {
      _uploadingAudio = true;
      _errorMessage = null;
    });
    try {
      final uploaded = await _apiClient.uploadCustomCharacterMedia(
        token: widget.token,
        file: audio,
        mediaType: 'AUDIO',
      );
      if (!mounted) return;
      setState(() {
        _uploadedAudio = uploaded;
        _uploadingAudio = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _audio = null;
        _uploadedAudio = null;
        _uploadingAudio = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _save() async {
    final name = _controllers['name']!.text.trim();
    if (name.isEmpty || _uploadedImage == null) {
      setState(() => _errorMessage = _uploadingImage ? '人物图片还在上传中' : '请填写人物名称并选择图片');
      return;
    }
    if (_recordingAudio) {
      setState(() => _errorMessage = '请先停止录音，等待语音上传完成后再保存');
      return;
    }
    if (_video != null && _uploadedVideo == null) {
      setState(() => _errorMessage = _uploadingVideo ? '人物视频还在上传中' : '人物视频上传失败，请重新选择视频');
      return;
    }
    if (_audio != null && _uploadedAudio == null) {
      setState(() => _errorMessage = _uploadingAudio ? '人物语音还在上传中' : '人物语音上传失败，请重新录制');
      return;
    }
    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    try {
      await _apiClient.saveCustomCharacter(
        token: widget.token,
        fields: {for (final entry in _controllers.entries) entry.key: entry.value.text.trim()},
        image: _uploadedImage!,
        video: _uploadedVideo,
        audio: _uploadedAudio,
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

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
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
          Expanded(
            child: _AssetTabButton(
              label: '我的角色',
              active: selectedIndex == 0,
              onTap: () => onSelected(0),
            ),
          ),
          Expanded(
            child: _AssetTabButton(
              label: '我的卡片',
              active: selectedIndex == 1,
              onTap: () => onSelected(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssetTabButton extends StatelessWidget {
  const _AssetTabButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? const Color(0xFF54389A) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: active
              ? const [
                  BoxShadow(
                    color: Color(0x554F34A6),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : const Color(0xFFB8B2CE),
            fontSize: 12,
            fontWeight: active ? FontWeight.w800 : FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class AssetCategoryFilter extends StatelessWidget {
  const AssetCategoryFilter({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
  });

  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final selected = category == selectedCategory;
          return GestureDetector(
            onTap: () => onSelected(category),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 13),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF54389A) : const Color(0x7711152C),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: selected ? const Color(0xFFD9B7FF) : const Color(0xFF302951)),
              ),
              child: Text(
                _categoryLabel(category),
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFFCFC6E8),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class AssetCharacterCard extends StatelessWidget {
  const AssetCharacterCard({
    super.key,
    required this.data,
    required this.count,
    required this.liked,
    required this.openingVideo,
    required this.onTap,
    required this.onLike,
  });

  final AssetCharacterData data;
  final int count;
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
          if (count > 1)
            Positioned(
              top: 7,
              left: 7,
              child: _CardCountBadge(count: count),
            ),
          if (data.sourceType == 2)
            Positioned(
              top: count > 1 ? 39 : 7,
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
    this.cardResourceId,
    this.name,
    this.series,
    this.accent,
    this.variant,
    this.coverImageUrl,
    this.previewVideoObjectKey,
    this.previewVideoUrl,
    this.audioObjectKey,
    this.audioUrl,
    this.sourceType,
  );

  factory AssetCharacterData.fromJson(Map<String, dynamic> json) {
    final name = json['name']?.toString() ?? '未命名角色';
    final rarity = json['rarity']?.toString() ?? 'NORMAL';
    return AssetCharacterData(
      (json['collectionId'] as num?)?.toInt() ?? name.hashCode,
      (json['cardResourceId'] as num?)?.toInt(),
      name,
      rarity,
      _accentForRarity(rarity),
      (json['collectionId'] as num?)?.toInt() ?? name.hashCode,
      _jsonString(json['coverImageUrl']),
      _jsonString(json['previewVideoObjectKey']),
      _jsonString(json['previewVideoUrl']),
      _jsonString(json['audioObjectKey']),
      _jsonString(json['audioUrl']),
      (json['sourceType'] as num?)?.toInt() ?? 1,
    );
  }

  final int collectionId;
  final int? cardResourceId;
  final String name;
  final String series;
  final Color accent;
  final int variant;
  final String? coverImageUrl;
  final String? previewVideoObjectKey;
  final String? previewVideoUrl;
  final String? audioObjectKey;
  final String? audioUrl;
  final int sourceType;

  String get groupKey {
    if (cardResourceId != null) return 'card:$cardResourceId';
    return 'custom:$sourceType:$name:$coverImageUrl';
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

class AssetCharacterGroup {
  const AssetCharacterGroup(this.primary, this.items);

  final AssetCharacterData primary;
  final List<AssetCharacterData> items;

  int get count => items.length;

  bool containsCollectionId(int? collectionId) {
    if (collectionId == null) return false;
    return items.any((item) => item.collectionId == collectionId);
  }

  static List<AssetCharacterGroup> group(List<AssetCharacterData> characters) {
    final buckets = <String, List<AssetCharacterData>>{};
    for (final character in characters) {
      buckets.putIfAbsent(character.groupKey, () => <AssetCharacterData>[]).add(character);
    }
    final groups = buckets.values
        .map((items) => AssetCharacterGroup(items.first, List.unmodifiable(items)))
        .toList(growable: false);
    return groups;
  }
}

class _CardCountBadge extends StatelessWidget {
  const _CardCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xE60B1024),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD9B7FF)),
      ),
      child: Text(
        'x$count',
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
      ),
    );
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
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 96,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xCC11162C),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF302951)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 54,
                height: 76,
                child: data.coverImageUrl == null || data.coverImageUrl!.isEmpty
                    ? const ColoredBox(
                        color: Color(0xFF17142A),
                        child: Icon(Icons.credit_card_rounded, color: Color(0xFFD9C4FF)),
                      )
                    : Image.network(
                        data.coverImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const ColoredBox(
                          color: Color(0xFF17142A),
                          child: Icon(Icons.credit_card_rounded, color: Color(0xFFD9C4FF)),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.characterName?.isNotEmpty == true ? data.characterName! : data.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    data.rarity?.isNotEmpty == true ? data.rarity! : data.nfcText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFFB8B2CE), fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    data.giftModeEnabled ? '赠送模式已开启' : '赠送模式未开启',
                    style: TextStyle(
                      color: data.giftModeEnabled ? const Color(0xFFFFC35B) : const Color(0xFF8C95B5),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFE7E8F7), size: 22),
          ],
        ),
      ),
    );
  }
}

class AssetNfcCardManagePage extends StatefulWidget {
  const AssetNfcCardManagePage({
    super.key,
    required this.card,
    required this.characters,
    required this.apiClient,
  });

  final AssetNfcCardData card;
  final List<AssetCharacterData> characters;
  final ApiClient apiClient;

  @override
  State<AssetNfcCardManagePage> createState() => _AssetNfcCardManagePageState();
}

class _AssetNfcCardManagePageState extends State<AssetNfcCardManagePage> {
  int? _selectedCollectionId;
  var _selectedCategory = 'ALL';
  late bool _giftModeEnabled;
  var _saving = false;

  List<AssetCharacterGroup> get _characterGroups => AssetCharacterGroup.group(widget.characters);

  List<AssetCharacterGroup> get _visibleGroups {
    final groups = _characterGroups;
    if (_selectedCategory == 'ALL') return groups;
    return groups.where((group) => group.primary.series.toUpperCase() == _selectedCategory).toList(growable: false);
  }

  List<String> get _categories {
    final values = _characterGroups.map((group) => group.primary.series.toUpperCase()).toSet().toList()
      ..sort(_sortRarity);
    return ['ALL', ...values];
  }

  @override
  void initState() {
    super.initState();
    _selectedCollectionId = widget.card.characterCollectionId ??
        (widget.characters.isEmpty ? null : widget.characters.first.collectionId);
    _giftModeEnabled = widget.card.giftModeEnabled;
  }

  AssetCharacterData? get _selectedCharacter {
    for (final character in widget.characters) {
      if (character.collectionId == _selectedCollectionId) return character;
    }
    return null;
  }

  Future<void> _save({required bool giftModeEnabled, bool closeWhenSaved = true}) async {
    final token = AuthSession.token;
    final collectionId = _selectedCollectionId;
    if (token == null || token.isEmpty) {
      _showMessage('请先登录');
      return;
    }
    if (collectionId == null) {
      _showMessage('请选择绑定的角色');
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.apiClient.bindNfcCharacter(
        token: token,
        cardId: widget.card.id,
        characterCollectionId: collectionId,
        giftModeEnabled: giftModeEnabled,
      );
      if (!mounted) return;
      setState(() => _giftModeEnabled = giftModeEnabled);
      _showMessage(giftModeEnabled ? '已开启赠送模式' : '已更新绑定角色');
      if (closeWhenSaved) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (!mounted) return;
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedCharacter;
    final groups = _visibleGroups;
    return Scaffold(
      backgroundColor: const Color(0xFF070A19),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _NfcPageHeader(
                title: '更换绑定角色',
                onBack: () => Navigator.of(context).pop(false),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  _NfcCardCover(data: widget.card, size: 70),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '当前绑定',
                          style: TextStyle(color: Color(0xFF9FA7C4), fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          selected?.name ?? widget.card.characterName ?? '未绑定角色',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    children: [
                      const Text(
                        '赠送模式',
                        style: TextStyle(color: Color(0xFFB8B2CE), fontSize: 11, fontWeight: FontWeight.w800),
                      ),
                      Switch(
                        value: _giftModeEnabled,
                        onChanged: _saving
                            ? null
                            : (value) => _save(giftModeEnabled: value, closeWhenSaved: false),
                        activeThumbColor: const Color(0xFFE7B3FF),
                        activeTrackColor: const Color(0xFF7046D9),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
                  decoration: BoxDecoration(
                    color: const Color(0xCC10142A),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF242B4E)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '选择要绑定的角色',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 12),
                      AssetCategoryFilter(
                        categories: _categories,
                        selectedCategory: _selectedCategory,
                        onSelected: (category) => setState(() => _selectedCategory = category),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: widget.characters.isEmpty
                            ? const Center(
                                child: Text(
                                  '还没有可绑定的角色',
                                  style: TextStyle(color: Color(0xFFEFE8FF), fontSize: 13, fontWeight: FontWeight.w800),
                                ),
                              )
                            : GridView.builder(
                                physics: const BouncingScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  mainAxisSpacing: 10,
                                  crossAxisSpacing: 8,
                                  childAspectRatio: 0.74,
                                ),
                                itemCount: groups.length,
                                itemBuilder: (context, index) {
                                  final group = groups[index];
                                  return _NfcCharacterOption(
                                    data: group.primary,
                                    count: group.count,
                                    selected: group.containsCollectionId(_selectedCollectionId),
                                    onTap: () => setState(() => _selectedCollectionId = group.primary.collectionId),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: FilledButton(
                          onPressed: _saving ? null : () => _save(giftModeEnabled: _giftModeEnabled),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF7046D9),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                          ),
                          child: _saving
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('确定绑定', style: TextStyle(fontWeight: FontWeight.w900)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NfcPageHeader extends StatelessWidget {
  const _NfcPageHeader({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              color: Colors.white,
              padding: EdgeInsets.zero,
            ),
          ),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _NfcCardCover extends StatelessWidget {
  const _NfcCardCover({required this.data, required this.size});

  final AssetNfcCardData data;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: size,
        height: size,
        child: data.coverImageUrl == null || data.coverImageUrl!.isEmpty
            ? const ColoredBox(
                color: Color(0xFF21183E),
                child: Icon(Icons.star_border_rounded, color: Color(0xFFE7B3FF), size: 42),
              )
            : Image.network(data.coverImageUrl!, fit: BoxFit.cover),
      ),
    );
  }
}

class _NfcCharacterOption extends StatelessWidget {
  const _NfcCharacterOption({
    required this.data,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final AssetCharacterData data;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? const Color(0xFFE7B3FF) : const Color(0xFF302951), width: selected ? 2 : 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (data.coverImageUrl == null || data.coverImageUrl!.isEmpty)
                CustomPaint(painter: AssetCharacterPainter(data: data))
              else
                Image.network(data.coverImageUrl!, fit: BoxFit.cover),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xCC080713)],
                  ),
                ),
              ),
              Positioned(
                left: 6,
                right: 6,
                bottom: 6,
                child: Text(
                  data.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                ),
              ),
              if (count > 1)
                Positioned(
                  top: 5,
                  left: 5,
                  child: _CardCountBadge(count: count),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class AssetNfcCardDetailDialog extends StatelessWidget {
  const AssetNfcCardDetailDialog({super.key, required this.data});

  final AssetNfcCardData data;

  @override
  Widget build(BuildContext context) {
    final title = data.characterName?.isNotEmpty == true ? data.characterName! : data.title;
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 0.72,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: data.coverImageUrl == null || data.coverImageUrl!.isEmpty
                    ? const ColoredBox(
                        color: Color(0xFF17142A),
                        child: Icon(Icons.credit_card_rounded, color: Color(0xFFD9C4FF), size: 72),
                      )
                    : Image.network(data.coverImageUrl!, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 14),
            _NfcDetailRow(label: '卡片名称', value: data.title),
            _NfcDetailRow(label: 'NFC 内容', value: data.nfcText.isEmpty ? '-' : data.nfcText),
            _NfcDetailRow(label: '稀有度', value: data.rarity?.isNotEmpty == true ? data.rarity! : '-'),
            _NfcDetailRow(label: '赠送模式', value: data.giftModeEnabled ? '已开启' : '未开启'),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('关闭')),
      ],
    );
  }
}

class _NfcDetailRow extends StatelessWidget {
  const _NfcDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(label, style: const TextStyle(color: Color(0xFF9FA7C4), fontSize: 12)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
class AssetNfcCardData {
  const AssetNfcCardData({
    required this.id,
    required this.nfcText,
    required this.title,
    required this.giftModeEnabled,
    this.characterCollectionId,
    this.characterName,
    this.rarity,
    this.coverImageUrl,
    this.coverImageObjectKey,
    this.previewVideoUrl,
    this.previewVideoObjectKey,
  });

  factory AssetNfcCardData.fromJson(Map<String, dynamic> json) {
    return AssetNfcCardData(
      id: (json['id'] as num?)?.toInt() ?? 0,
      nfcText: json['nfcText']?.toString() ?? '',
      title: json['title']?.toString() ?? 'NFC 卡片',
      giftModeEnabled: json['giftModeEnabled'] == true,
      characterCollectionId: (json['characterCollectionId'] as num?)?.toInt(),
      characterName: json['characterName']?.toString(),
      rarity: json['rarity']?.toString(),
      coverImageUrl: json['coverImageUrl']?.toString(),
      coverImageObjectKey: json['coverImageObjectKey']?.toString(),
      previewVideoUrl: json['previewVideoUrl']?.toString(),
      previewVideoObjectKey: json['previewVideoObjectKey']?.toString(),
    );
  }

  final int id;
  final String nfcText;
  final String title;
  final bool giftModeEnabled;
  final int? characterCollectionId;
  final String? characterName;
  final String? rarity;
  final String? coverImageUrl;
  final String? coverImageObjectKey;
  final String? previewVideoUrl;
  final String? previewVideoObjectKey;
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
