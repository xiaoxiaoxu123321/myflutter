import 'dart:math' as math;
import 'dart:async';
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
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiClient = ApiClient();
  var _accepted = true;
  var _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_accepted) return;
    final phone = _usernameController.text.trim();
    final password = _passwordController.text;

    if (phone.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = '请输入手机号和密码');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    var loginSucceeded = false;
    try {
      final data = await _apiClient.login(username: phone, password: password);
      AuthSession.enterUserMode(
        authToken: data['token'] as String?,
        currentUser: data['user'] as Map<String, dynamic>?,
      );
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

  void _openRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const RegisterPage(),
      ),
    ).then((registered) {
      if (registered == true && mounted) {
        Navigator.of(context).pop(true);
      }
    });
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
                              controller: _usernameController,
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 12),
                            LoginInput(
                              icon: Icons.password_rounded,
                              hintText: '请输入密码',
                              controller: _passwordController,
                              keyboardType: TextInputType.visiblePassword,
                              obscureText: true,
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
                                  '登录',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Center(
                              child: TextButton(
                                onPressed: _loading ? null : _openRegister,
                                child: const Text(
                                  '创建新账号',
                                  style: TextStyle(
                                    color: Color(0xFFC47BFF),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
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

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _referralCodeController = TextEditingController();
  final _apiClient = ApiClient();
  var _accepted = true;
  var _loading = false;
  var _sendingCode = false;
  var _codeCountdown = 0;
  Timer? _codeTimer;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _referralCodeController.dispose();
    _codeTimer?.cancel();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _errorMessage = '请输入手机号');
      return;
    }
    if (_sendingCode || _codeCountdown > 0) return;

    setState(() {
      _sendingCode = true;
      _errorMessage = null;
    });

    try {
      await _apiClient.sendRegisterSmsCode(phone: phone);
      if (!mounted) return;
      setState(() => _codeCountdown = 60);
      _codeTimer?.cancel();
      _codeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        if (_codeCountdown <= 1) {
          timer.cancel();
          setState(() => _codeCountdown = 0);
          return;
        }
        setState(() => _codeCountdown -= 1);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _sendingCode = false);
      }
    }
  }

  Future<void> _register() async {
    if (!_accepted) return;
    final phone = _phoneController.text.trim();
    final code = _codeController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final referralCode = _referralCodeController.text.trim();

    if (phone.isEmpty || code.isEmpty || username.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      setState(() => _errorMessage = '请完整填写注册信息');
      return;
    }
    if (password != confirmPassword) {
      setState(() => _errorMessage = '两次输入的密码不一致');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    var registerSucceeded = false;
    try {
      final data = await _apiClient.register(
        phone: phone,
        code: code,
        username: username,
        password: password,
        confirmPassword: confirmPassword,
        referralCode: referralCode.isEmpty ? null : referralCode,
      );
      AuthSession.enterUserMode(
        authToken: data['token'] as String?,
        currentUser: data['user'] as Map<String, dynamic>?,
      );
      registerSucceeded = true;
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted && !registerSucceeded) {
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
            final maxWidth = constraints.maxWidth > 520 ? 420.0 : double.infinity;
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
                              icon: const Icon(Icons.arrow_back_ios_new_rounded),
                              color: Colors.white,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints.tightFor(
                                width: 36,
                                height: 36,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              '创建新账号',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 25,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              '开启你的心象之旅',
                              style: TextStyle(
                                color: Color(0xFFC8BEDF),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0,
                              ),
                            ),
                            const SizedBox(height: 26),
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
                              actionText: _codeCountdown > 0
                                  ? '${_codeCountdown}s'
                                  : (_sendingCode ? '发送中' : '获取验证码'),
                              onAction: _codeCountdown > 0 || _sendingCode ? null : _sendCode,
                              controller: _codeController,
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 12),
                            LoginInput(
                              icon: Icons.person_outline_rounded,
                              hintText: '请输入用户名',
                              controller: _usernameController,
                              keyboardType: TextInputType.text,
                            ),
                            const SizedBox(height: 12),
                            LoginInput(
                              icon: Icons.password_rounded,
                              hintText: '请输入密码',
                              controller: _passwordController,
                              keyboardType: TextInputType.visiblePassword,
                              obscureText: true,
                            ),
                            const SizedBox(height: 12),
                            LoginInput(
                              icon: Icons.verified_user_outlined,
                              hintText: '请再次输入密码',
                              controller: _confirmPasswordController,
                              keyboardType: TextInputType.visiblePassword,
                              obscureText: true,
                            ),
                            const SizedBox(height: 12),
                            LoginInput(
                              icon: Icons.card_giftcard_rounded,
                              hintText: '请输入推荐码（选填）',
                              controller: _referralCodeController,
                              keyboardType: TextInputType.text,
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
                                onPressed: _accepted && !_loading ? _register : null,
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF8350DC),
                                  disabledBackgroundColor: const Color(0xFF3B2E55),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  _loading ? '注册中...' : '注册并登录',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
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
    this.onAction,
    this.obscureText = false,
  });

  final IconData icon;
  final String hintText;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final String? actionText;
  final VoidCallback? onAction;
  final bool obscureText;

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
              obscureText: obscureText,
            ),
          ),
          if (actionText != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                actionText!,
                style: TextStyle(
                  color: onAction == null ? const Color(0xFF7D728E) : const Color(0xFFC47BFF),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
