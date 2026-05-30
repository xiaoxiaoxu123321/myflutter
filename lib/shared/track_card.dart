import 'package:flutter/material.dart';
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
