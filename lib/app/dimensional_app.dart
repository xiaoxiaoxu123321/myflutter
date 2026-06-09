import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../features/home/home_page.dart';
import '../features/profile/profile_page.dart';

class DimensionalApp extends StatelessWidget {
  const DimensionalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dimensional',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8D56FF),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF080613),
      ),
      home: const AppConsentGate(),
    );
  }
}

class AppConsentGate extends StatefulWidget {
  const AppConsentGate({super.key});

  @override
  State<AppConsentGate> createState() => _AppConsentGateState();
}

class _AppConsentGateState extends State<AppConsentGate> {
  var _accepted = false;

  @override
  Widget build(BuildContext context) {
    if (_accepted) {
      return const HomePage();
    }

    return ConsentPage(
      onAccepted: () => setState(() => _accepted = true),
      onRejected: () => SystemNavigator.pop(),
    );
  }
}

class ConsentPage extends StatefulWidget {
  const ConsentPage({
    super.key,
    required this.onAccepted,
    required this.onRejected,
  });

  final VoidCallback onAccepted;
  final VoidCallback onRejected;

  @override
  State<ConsentPage> createState() => _ConsentPageState();
}

class _ConsentPageState extends State<ConsentPage> {
  var _agreementChecked = false;
  var _privacyChecked = false;
  var _disclaimerChecked = false;

  bool get _allChecked =>
      _agreementChecked && _privacyChecked && _disclaimerChecked;

  void _openAgreement() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const UserAgreementPage()),
    );
  }

  void _openPrivacy() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
    );
  }

  void _openDisclaimer() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DisclaimerPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF060817),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF253154)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(17),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF070A19),
                            Color(0xFF090C1D),
                            Color(0xFF050613),
                          ],
                        ),
                      ),
                    ),
                    const CustomPaint(painter: ConsentGlowPainter()),
                    Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 24,
                        ),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                          decoration: BoxDecoration(
                            color: const Color(0xB00E132B),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF26345B)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x66000000),
                                blurRadius: 24,
                                offset: Offset(0, 14),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 146,
                                height: 116,
                                child: CustomPaint(
                                  painter: ConsentShieldPainter(),
                                ),
                              ),
                              const SizedBox(height: 18),
                              const Text(
                                '欢迎使用心象频率',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                '为了更好地为您提供服务，请您在使用前\n仔细阅读并同意以下协议',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFFC0C4DD),
                                  fontSize: 13,
                                  height: 1.7,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0,
                                ),
                              ),
                              const SizedBox(height: 22),
                              ConsentCheckRow(
                                checked: _agreementChecked,
                                text: '我已阅读并同意',
                                linkText: '《用户协议》',
                                onChanged: (value) {
                                  setState(() => _agreementChecked = value);
                                },
                                onOpen: _openAgreement,
                              ),
                              const SizedBox(height: 14),
                              ConsentCheckRow(
                                checked: _privacyChecked,
                                text: '我已阅读并同意',
                                linkText: '《隐私政策》',
                                onChanged: (value) {
                                  setState(() => _privacyChecked = value);
                                },
                                onOpen: _openPrivacy,
                              ),
                              const SizedBox(height: 14),
                              ConsentCheckRow(
                                checked: _disclaimerChecked,
                                text: '我已阅读并同意',
                                linkText: '《免责声明》',
                                onChanged: (value) {
                                  setState(() => _disclaimerChecked = value);
                                },
                                onOpen: _openDisclaimer,
                              ),
                              const SizedBox(height: 28),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: FilledButton(
                                  onPressed: _allChecked ? widget.onAccepted : null,
                                  style: FilledButton.styleFrom(
                                    disabledBackgroundColor:
                                        const Color(0x663B2678),
                                    disabledForegroundColor:
                                        const Color(0x88FFFFFF),
                                    backgroundColor: const Color(0xFF741CFF),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0,
                                    ),
                                  ),
                                  child: const Text('同意并继续'),
                                ),
                              ),
                              const SizedBox(height: 18),
                              TextButton(
                                onPressed: widget.onRejected,
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFFC694FF),
                                  textStyle: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0,
                                  ),
                                ),
                                child: const Text('不同意并退出'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ConsentCheckRow extends StatelessWidget {
  const ConsentCheckRow({
    super.key,
    required this.checked,
    required this.text,
    required this.linkText,
    required this.onChanged,
    required this.onOpen,
  });

  final bool checked;
  final String text;
  final String linkText;
  final ValueChanged<bool> onChanged;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => onChanged(!checked),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: checked ? const Color(0xFF7D33FF) : Colors.transparent,
              border: Border.all(
                color: checked ? const Color(0xFFD8C2FF) : const Color(0xFF7E789D),
                width: 1.4,
              ),
              boxShadow: checked
                  ? [
                      BoxShadow(
                        color: const Color(0xFF8B39FF).withValues(alpha: 0.55),
                        blurRadius: 10,
                      ),
                    ]
                  : null,
            ),
            child: checked
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFFD6D8EA),
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        Flexible(
          child: GestureDetector(
            onTap: onOpen,
            child: Text(
              linkText,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFC28CFF),
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ConsentGlowPainter extends CustomPainter {
  const ConsentGlowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0x995D22FF),
          const Color(0x225D22FF),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.64, size.height * 0.2),
          radius: size.width * 0.42,
        ),
      );
    canvas.drawCircle(
      Offset(size.width * 0.64, size.height * 0.2),
      size.width * 0.42,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ConsentShieldPainter extends CustomPainter {
  const ConsentShieldPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xAA8B3DFF),
          const Color(0x228B3DFF),
          Colors.transparent,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawOval(Offset.zero & size, glow);

    final shield = Path()
      ..moveTo(size.width * 0.5, size.height * 0.12)
      ..cubicTo(
        size.width * 0.64,
        size.height * 0.22,
        size.width * 0.76,
        size.height * 0.24,
        size.width * 0.84,
        size.height * 0.28,
      )
      ..cubicTo(
        size.width * 0.82,
        size.height * 0.62,
        size.width * 0.68,
        size.height * 0.8,
        size.width * 0.5,
        size.height * 0.9,
      )
      ..cubicTo(
        size.width * 0.32,
        size.height * 0.8,
        size.width * 0.18,
        size.height * 0.62,
        size.width * 0.16,
        size.height * 0.28,
      )
      ..cubicTo(
        size.width * 0.24,
        size.height * 0.24,
        size.width * 0.36,
        size.height * 0.22,
        size.width * 0.5,
        size.height * 0.12,
      )
      ..close();
    final shieldPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFE2C6FF), Color(0xFF8A3DFF), Color(0xFF4B1DBA)],
      ).createShader(Offset.zero & size);
    canvas.drawPath(shield, shieldPaint);

    final check = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 6
      ..color = Colors.white;
    final checkPath = Path()
      ..moveTo(size.width * 0.36, size.height * 0.5)
      ..lineTo(size.width * 0.47, size.height * 0.61)
      ..lineTo(size.width * 0.68, size.height * 0.39);
    canvas.drawPath(checkPath, check);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
