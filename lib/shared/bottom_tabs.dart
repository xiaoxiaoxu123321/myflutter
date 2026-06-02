import 'package:flutter/material.dart';

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

class _TabItem {
  const _TabItem(this.label, this.icon);

  final String label;
  final IconData icon;
}
