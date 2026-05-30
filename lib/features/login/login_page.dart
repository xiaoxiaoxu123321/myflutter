import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/auth_session.dart';
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
