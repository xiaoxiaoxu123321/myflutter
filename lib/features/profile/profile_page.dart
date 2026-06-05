import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/auth_session.dart';
import '../login/login_page.dart';
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

  void _logout() {
    setState(() {
      AuthSession.isLoggedIn = false;
      AuthSession.token = null;
      AuthSession.user = null;
      _errorMessage = null;
      _loadingUser = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已退出登录')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthSession.user;
    final isLoggedIn = AuthSession.isLoggedIn && AuthSession.token != null;
    final phone = user?['phone']?.toString();
    final name = user?['nickname']?.toString() ?? (_loadingUser ? '加载中' : '请先登录');
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
                if (isLoggedIn) ...[
                  const SizedBox(height: 10),
                  ProfileLogoutButton(onPressed: _logout),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileLogoutButton extends StatelessWidget {
  const ProfileLogoutButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: const Text('退出登录'),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFFFA0A8),
          side: const BorderSide(color: Color(0x66FFA0A8)),
          backgroundColor: const Color(0x331F1020),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
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
