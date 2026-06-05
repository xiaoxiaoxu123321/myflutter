import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/api_client.dart';

class PlazaPageBody extends StatefulWidget {
  const PlazaPageBody({super.key, required this.onOpenGift});

  final VoidCallback onOpenGift;

  @override
  State<PlazaPageBody> createState() => _PlazaPageBodyState();
}

class _PlazaPageBodyState extends State<PlazaPageBody> {
  final _apiClient = ApiClient();
  List<_PlazaSeries> _series = const [];
  List<_PlazaCharacter> _characters = const [];
  var _catalogLoading = true;
  String? _catalogError;
  int? _selectedSeriesId;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    try {
      final data = await _apiClient.plazaCatalog();
      final series = (data['series'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map((item) => _PlazaSeries(item['id'] as int, item['name']?.toString() ?? ''))
          .toList(growable: false);
      final characters = (data['cards'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(
            (item) => _PlazaCharacter(
              item['seriesId'] as int,
              item['name']?.toString() ?? '',
              item['rarity']?.toString() ?? '',
              item['imageUrl']?.toString() ?? '',
            ),
          )
          .toList(growable: false);
      if (!mounted) return;
      setState(() {
        _series = series;
        _characters = characters;
        _catalogLoading = false;
        _catalogError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _catalogLoading = false;
        _catalogError = '图鉴加载失败，请检查后端服务';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleCharacters = _selectedSeriesId == null
        ? _characters
        : _characters.where((item) => item.seriesId == _selectedSeriesId).toList();

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF080A23),
                    Color(0xFF090B20),
                    Color(0xFF060713),
                  ],
                ),
              ),
            ),
          ),
          const Positioned.fill(child: CustomPaint(painter: _PlazaBackgroundPainter())),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 18),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const _PlazaHeader(),
                    const SizedBox(height: 12),
                    _FeaturedBanner(onOpenGift: widget.onOpenGift),
                    const SizedBox(height: 16),
                    _SectionTitle(title: '全系列图鉴', action: '全部系列 >'),
                    const SizedBox(height: 8),
                    _FilterBar(
                      series: _series,
                      selectedSeriesId: _selectedSeriesId,
                      onSelected: (value) => setState(() => _selectedSeriesId = value),
                    ),
                    const SizedBox(height: 9),
                    if (_catalogLoading)
                      const _CatalogMessage(message: '正在加载全系列图鉴...')
                    else if (_catalogError != null)
                      _CatalogMessage(message: _catalogError!)
                    else if (visibleCharacters.isEmpty)
                      const _CatalogMessage(message: '当前系列暂无卡片')
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: visibleCharacters.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 0.72,
                        ),
                        itemBuilder: (_, index) => _CharacterCard(
                          character: visibleCharacters[index],
                        ),
                      ),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlazaHeader extends StatelessWidget {
  const _PlazaHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF5D50BA)),
            gradient: const RadialGradient(
              colors: [Color(0xFF2D2360), Color(0xFF101334)],
            ),
          ),
          child: const Icon(Icons.bubble_chart_rounded, color: Color(0xFFC697FF)),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '心象广场',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 2),
              Text(
                '发现新的心象人格，解锁属于你的故事',
                style: TextStyle(color: Color(0xFFB8B3DB), fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            color: const Color(0x551B1744),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF51468B)),
          ),
          child: const Icon(Icons.card_giftcard_rounded, color: Color(0xFFE6D5FF), size: 23),
        ),
      ],
    );
  }
}

class _FeaturedBanner extends StatefulWidget {
  const _FeaturedBanner({required this.onOpenGift});

  final VoidCallback onOpenGift;

  @override
  State<_FeaturedBanner> createState() => _FeaturedBannerState();
}

class _FeaturedBannerState extends State<_FeaturedBanner> {
  final _apiClient = ApiClient();
  final _pageController = PageController();
  Timer? _timer;
  List<_FeaturedSlide> _slides = const [];
  String? _loadError;
  var _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadSlides();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_pageController.hasClients || _slides.isEmpty) return;
      final nextPage = (_currentPage + 1) % _slides.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _loadSlides() async {
    try {
      final data = await _apiClient.plazaFeaturedBanners();
      final slides = data
          .map(
            (item) => _FeaturedSlide(
              item['title']?.toString() ?? '月海系列新角色',
              item['characterName']?.toString() ?? '',
              item['subtitle']?.toString() ?? '限时概率UP ↑',
              item['imageUrl']?.toString() ?? '',
            ),
          )
          .where((slide) => slide.imageUrl.isNotEmpty)
          .toList(growable: false);
      if (!mounted) return;
      setState(() {
        _slides = slides;
        _loadError = slides.isEmpty ? '后端暂未配置广场轮播数据' : null;
        _currentPage = 0;
      });
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadError = '广场轮播加载失败，请检查后端服务');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 158,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFF9B49FF)),
        boxShadow: const [BoxShadow(color: Color(0x665A23DF), blurRadius: 18)],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_slides.isEmpty)
            _BannerError(message: _loadError ?? '正在加载广场轮播...')
          else ...[
          PageView.builder(
            controller: _pageController,
            itemCount: _slides.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (_, index) => Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  _slides[index].imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const _BannerError(message: 'OSS 图片加载失败'),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xE72A0B58), Color(0x55320A62), Color(0x14000000)],
                      stops: [0, 0.48, 1],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 15, 12, 13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(_slides[_currentPage].title, style: const TextStyle(color: Color(0xFFD9C4FF), fontSize: 17, fontWeight: FontWeight.w900)),
                    ),
                    Text('${_currentPage + 1}/${_slides.length}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 5),
                Text(_slides[_currentPage].name, style: const TextStyle(color: Color(0xFFFFB4FF), fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 5),
                Text(_slides[_currentPage].subtitle, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: 78,
                      height: 31,
                      child: FilledButton(
                        onPressed: widget.onOpenGift,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF7937DD),
                          padding: EdgeInsets.zero,
                        ),
                        child: const Text('去抽取', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: List.generate(
                        _slides.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: index == _currentPage ? 14 : 5,
                          height: 5,
                          margin: const EdgeInsets.only(left: 4),
                          decoration: BoxDecoration(
                            color: index == _currentPage ? Colors.white : const Color(0x88FFFFFF),
                            borderRadius: BorderRadius.circular(9),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ],
        ],
      ),
    );
  }
}

class _FeaturedSlide {
  const _FeaturedSlide(this.title, this.name, this.subtitle, this.imageUrl);

  final String title;
  final String name;
  final String subtitle;
  final String imageUrl;
}

class _BannerError extends StatelessWidget {
  const _BannerError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF15112E),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: Color(0xFFD9C4FF), fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.action});

  final String title;
  final String action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900)),
        const Spacer(),
        Text(action, style: const TextStyle(color: Color(0xFF9F8ED6), fontSize: 10, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.series,
    required this.selectedSeriesId,
    required this.onSelected,
  });

  final List<_PlazaSeries> series;
  final int? selectedSeriesId;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) {
    final filters = [const _PlazaSeries(null, '全部'), ...series];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final active = filter.id == selectedSeriesId;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: InkWell(
              onTap: () => onSelected(filter.id),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: active ? const Color(0xFF51308F) : const Color(0xFF12152F),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: active ? const Color(0xFFC16CFF) : const Color(0xFF37345D)),
                ),
                child: Text(filter.name, style: TextStyle(color: active ? Colors.white : const Color(0xFFB7B3D2), fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CharacterCard extends StatelessWidget {
  const _CharacterCard({required this.character});

  final _PlazaCharacter character;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF11142A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF7251BA)),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (character.imageUrl.isEmpty)
            const _CatalogMessage(message: '未配置图片')
          else
            Image.network(
              character.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const _CatalogMessage(message: 'OSS 图片加载失败'),
            ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0x10000000), Color(0xE8070819)],
                stops: [0, 0.57, 1],
              ),
            ),
          ),
          Positioned(
            left: 6,
            top: 5,
            child: Text(character.rarity, style: const TextStyle(color: Color(0xFFD69AFF), fontSize: 11, fontWeight: FontWeight.w900)),
          ),
          Positioned(
            left: 7,
            right: 7,
            bottom: 7,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(character.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogMessage extends StatelessWidget {
  const _CatalogMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(18),
      color: const Color(0xFF15112E),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Color(0xFFD9C4FF), fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _PlazaBackgroundPainter extends CustomPainter {
  const _PlazaBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(13);
    for (var i = 0; i < 65; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = i % 11 == 0 ? 1.5 : 0.7;
      canvas.drawCircle(Offset(x, y), radius, Paint()..color = const Color(0x887E70FF));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PlazaSeries {
  const _PlazaSeries(this.id, this.name);

  final int? id;
  final String name;
}

class _PlazaCharacter {
  const _PlazaCharacter(this.seriesId, this.name, this.rarity, this.imageUrl);

  final int seriesId;
  final String name;
  final String rarity;
  final String imageUrl;
}
