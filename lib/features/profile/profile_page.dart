import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
      AuthSession.enterUserMode(authToken: token, currentUser: user);
      if (!mounted) return;
      setState(() {});
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _errorMessage = error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => _loadingUser = false);
      }
    }
  }

  void _openLogin() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => LoginPage(
              nfcDataLines: const [],
            ),
          ),
        )
        .then((loggedIn) {
      if (loggedIn == true) {
        _loadUser();
      }
    });
  }

  void _enterGuestMode() {
    setState(() {
      AuthSession.enterGuestMode();
      _errorMessage = null;
      _loadingUser = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('提示')),
    );
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
          title: const Text('淇敼鏄电О'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 64,
            decoration: const InputDecoration(
              hintText: '璇疯緭鍏ユ樀绉?,
              counterText: '',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('鍙栨秷'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: const Text('淇濆瓨'),
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
      final user = await _apiClient.updateNickname(
        token: token,
        nickname: nickname,
      );
      AuthSession.user = user;
      if (!mounted) return;
      setState(() {});
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _errorMessage = error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => _loadingUser = false);
      }
    }
  }

  void _logout() {
    setState(() {
      AuthSession.clear();
      _errorMessage = null;
      _loadingUser = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('提示')),
    );
  }

  void _openPrivacyPolicy() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
    );
  }

  void _openUserAgreement() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const UserAgreementPage()),
    );
  }

  void _openDisclaimer() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DisclaimerPage()),
    );
  }

  void _openContactUs() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const UpdatedContactUsPage()),
    );
  }

  Future<void> _openPasswordReset() async {
    await showDialog<void>(
      context: context,
      builder: (_) => PasswordResetDialog(apiClient: _apiClient),
    );
  }

  void _sharePublicId() {
    final publicId = AuthSession.user?['publicId']?.toString() ?? '';
    if (publicId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('璇峰厛鐧诲綍鍚庡垎浜獻D')),
      );
      return;
    }
    Clipboard.setData(ClipboardData(text: publicId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('宸插鍒跺垎浜獻D锛?publicId')),
    );
  }

  void _openVersionInfo() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const VersionInfoPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthSession.user;
    final isLoggedIn = AuthSession.isLoggedIn && AuthSession.token != null;
    final isGuest = AuthSession.isGuest;
    final name = user?['nickname']?.toString() ?? (_loadingUser ? '加载中' : '请先登录');
    final publicId = user?['publicId']?.toString();
    final idText = publicId == null || publicId.isEmpty ? 'ID：-' : 'ID：$publicId';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF070817),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF2C3153)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x99000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF090A19),
                    Color(0xFF0D1027),
                    Color(0xFF060712),
                  ],
                ),
              ),
            ),
            const CustomPaint(painter: ProfileGlowPainter()),
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 28, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProfileHeader(
                    name: isGuest ? '娓稿' : name,
                    idText: idText,
                    errorMessage: _errorMessage,
                    loading: _loadingUser,
                    isLoggedIn: isLoggedIn,
                    isGuest: isGuest,
                    onLogin: _openLogin,
                    onGuest: _enterGuestMode,
                    onEdit: _editNickname,
                  ),
                  const SizedBox(height: 26),
                  const ProfileMenuGroup(
                    title: '鍏充簬',
                    items: [
                      ProfileMenuItemData(
                        icon: Icons.info_outline_rounded,
                        title: '鍏充簬鎴戜滑',
                        subtitle: '浜嗚В蹇冭薄棰戠巼',
                      ),
                      ProfileMenuItemData(
                        icon: Icons.info_outline_rounded,
                        title: '浼佷笟鎰挎櫙',
                        subtitle: '鎴戜滑鎯宠闄即鏇存湁娓╁害',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ProfileMenuGroup(
                    title: '说明',
                    items: [
                      ProfileMenuItemData(
                        icon: Icons.article_outlined,
                        title: '鐢ㄦ埛鍗忚',
                        subtitle: '说明',
                        onTap: _openUserAgreement,
                      ),
                      ProfileMenuItemData(
                        icon: Icons.lock_outline_rounded,
                        title: '闅愮鏀跨瓥',
                        subtitle: '浜嗚В鎴戜滑濡備綍淇濇姢鎮ㄧ殑淇℃伅',
                        onTap: _openPrivacyPolicy,
                      ),
                      ProfileMenuItemData(
                        icon: Icons.fact_check_outlined,
                        title: '鍏嶈矗澹版槑',
                        subtitle: '浣跨敤鍓嶈闃呰閲嶈璇存槑',
                        onTap: _openDisclaimer,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ProfileMenuGroup(
                    title: '鍏朵粬',
                    items: [
                      ProfileMenuItemData(
                        icon: Icons.password_rounded,
                        title: '淇敼瀵嗙爜',
                        subtitle: '閫氳繃鎵嬫満鍙烽獙璇佺爜閲嶇疆',
                        onTap: _openPasswordReset,
                      ),
                      ProfileMenuItemData(
                        icon: Icons.ios_share_rounded,
                        title: '分享ID',
                        subtitle: '复制推荐码，好友注册后奖励10次抽卡',
                        onTap: _sharePublicId,
                      ),
                      ProfileMenuItemData(
                        icon: Icons.chat_bubble_outline_rounded,
                        title: '鑱旂郴鎴戜滑',
                        subtitle: '说明',
                        onTap: _openContactUs,
                      ),
                      ProfileMenuItemData(
                        icon: Icons.add_circle_outline_rounded,
                        title: '鐗堟湰淇℃伅',
                        subtitle: '褰撳墠鐗堟湰 1.0.0',
                        onTap: _openVersionInfo,
                      ),
                    ],
                  ),
                  if (isLoggedIn) ...[
                    const SizedBox(height: 12),
                    ProfileLogoutButton(onPressed: _logout),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.name,
    required this.idText,
    required this.errorMessage,
    required this.loading,
    required this.isLoggedIn,
    required this.isGuest,
    required this.onLogin,
    required this.onGuest,
    required this.onEdit,
  });

  final String name;
  final String idText;
  final String? errorMessage;
  final bool loading;
  final bool isLoggedIn;
  final bool isGuest;
  final VoidCallback onLogin;
  final VoidCallback onGuest;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 116,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const ProfileAvatar(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: isLoggedIn || isGuest ? null : onLogin,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (!isLoggedIn && !isGuest) ...[
                      const SizedBox(width: 10),
                      TextButton(
                        onPressed: loading ? null : onGuest,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFC47BFF),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: const Size(0, 30),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0,
                          ),
                        ),
                        child: const Text('娓稿璁块棶'),
                      ),
                    ],
                    if (isGuest) ...[
                      const SizedBox(width: 10),
                      TextButton(
                        onPressed: loading ? null : onLogin,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFC47BFF),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: const Size(0, 30),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0,
                          ),
                        ),
                        child: const Text('鐧诲綍璐﹀彿'),
                      ),
                    ],
                    if (isLoggedIn)
                      SizedBox(
                      width: 30,
                      height: 30,
                      child: IconButton(
                        onPressed: loading ? null : onEdit,
                        icon: const Icon(Icons.edit_rounded),
                        iconSize: 16,
                        color: const Color(0xFFDCA6FF),
                        padding: EdgeInsets.zero,
                        tooltip: '淇敼鏄电О',
                      ),
                    ),
                  ],
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    errorMessage!,
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
                const SizedBox(height: 7),
                Text(
                  idText,
                  style: const TextStyle(
                    color: Color(0xFFE9EAFF),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
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

class PasswordResetDialog extends StatefulWidget {
  const PasswordResetDialog({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<PasswordResetDialog> createState() => _PasswordResetDialogState();
}

class _PasswordResetDialogState extends State<PasswordResetDialog> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  Timer? _timer;
  var _countdown = 0;
  var _sendingCode = false;
  var _saving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _errorMessage = '请输入手机号');
      return;
    }
    if (_sendingCode || _countdown > 0) return;

    setState(() {
      _sendingCode = true;
      _errorMessage = null;
    });
    try {
      await widget.apiClient.sendPasswordResetSmsCode(phone: phone);
      if (!mounted) return;
      setState(() => _countdown = 60);
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        if (_countdown <= 1) {
          timer.cancel();
          setState(() => _countdown = 0);
          return;
        }
        setState(() => _countdown -= 1);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _sendingCode = false);
    }
  }

  Future<void> _resetPassword() async {
    final phone = _phoneController.text.trim();
    final code = _codeController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    if (phone.isEmpty || code.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      setState(() => _errorMessage = '请完整填写信息');
      return;
    }
    if (password != confirmPassword) {
      setState(() => _errorMessage = '两次输入的密码不一致');
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    try {
      await widget.apiClient.resetPassword(
        phone: phone,
        code: code,
        password: password,
        confirmPassword: confirmPassword,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('密码已修改，请使用新密码登录')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF15162C),
      title: const Text('修改密码', style: TextStyle(color: Colors.white)),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: '手机号'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '验证码'),
                  ),
                ),
                const SizedBox(width: 10),
                TextButton(
                  onPressed: _sendingCode || _countdown > 0 ? null : _sendCode,
                  child: Text(
                    _countdown > 0 ? '${_countdown}s' : (_sendingCode ? '发送中' : '获取验证码'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: '新密码'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: '确认新密码'),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Color(0xFFFF9BA6), fontSize: 12),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _saving ? null : _resetPassword,
          child: Text(_saving ? '保存中' : '保存'),
        ),
      ],
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

class ProfileMenuGroup extends StatelessWidget {
  const ProfileMenuGroup({
    super.key,
    required this.title,
    required this.items,
  });

  final String title;
  final List<ProfileMenuItemData> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 12, 6, 6),
      decoration: BoxDecoration(
        color: const Color(0xA80D1023),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF232A4A)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8),
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFFC5C6E4),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ),
          for (var i = 0; i < items.length; i++) ...[
            ProfileMenuRow(item: items[i]),
            if (i != items.length - 1)
              const Divider(
                height: 1,
                thickness: 1,
                indent: 12,
                endIndent: 12,
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
    return Container(
      height: item.subtitle == null ? 56 : 60,
      decoration: BoxDecoration(
        color: const Color(0x73161A31),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: item.onTap,
          borderRadius: BorderRadius.circular(8),
          child: Row(
            children: [
              const SizedBox(width: 14),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFB995FF), width: 1.4),
                ),
                child: Icon(item.icon, color: const Color(0xFFDDBEFF), size: 15),
              ),
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
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    if (item.subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        item.subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF9CA4C6),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFE8E0FF),
                size: 26,
              ),
              const SizedBox(width: 10),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileMenuItemData {
  const ProfileMenuItemData({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
}

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

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
                    const CustomPaint(painter: PrivacyPolicyGlowPainter()),
                    Column(
                      children: [
                        SizedBox(
                          height: 60,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: IconButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  icon: const Icon(
                                    Icons.chevron_left_rounded,
                                    size: 34,
                                  ),
                                  color: Colors.white,
                                  tooltip: '杩斿洖',
                                ),
                              ),
                              const Text(
                                '闅愮鏀跨瓥',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Expanded(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.fromLTRB(28, 14, 28, 22),
                            child: UpdatedPrivacyPolicyContent(),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(28, 10, 28, 20),
                          child: SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: FilledButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF761CFF),
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
                              child: const Text('确认'),
                            ),
                          ),
                        ),
                      ],
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

class PrivacyPolicyContent extends StatelessWidget {
  const PrivacyPolicyContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTextStyle(
      style: TextStyle(
        color: Color(0xFFC9CEE3),
        fontSize: 13,
        height: 1.55,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '蹇冭薄棰戠巼闅愮鏀跨瓥',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.35,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: 12),
          Text('内容说明'),
          SizedBox(height: 2),
          Text('内容说明'),
          SizedBox(height: 22),
          Text('内容说明'),
          SizedBox(height: 20),
          _PolicySection(
            title: '说明',
            paragraphs: [
              '内容说明。',
              '内容说明。',
              '内容说明。',
              '内容说明。',
            ],
          ),
          SizedBox(height: 20),
          _PolicySection(
            title: '2. 鎴戜滑濡備綍浣跨敤淇℃伅',
            paragraphs: [
              '内容说明。',
            ],
          ),
        ],
      ),
    );
  }
}

class UpdatedPrivacyPolicyContent extends StatelessWidget {
  const UpdatedPrivacyPolicyContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTextStyle(
      style: TextStyle(
        color: Color(0xFFC9CEE3),
        fontSize: 13,
        height: 1.55,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '蹇冭薄棰戠巼闅愮鏀跨瓥',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.35,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: 12),
          Text('内容说明'),
          SizedBox(height: 2),
          Text('内容说明'),
          SizedBox(height: 22),
          Text('内容说明'),
          SizedBox(height: 20),
          _PolicySection(
            title: '说明',
            paragraphs: [
              '璐﹀彿淇℃伅',
              '鐢ㄦ埛ID',
              '鏄电О',
              '澶村儚',
              '璁惧淇℃伅',
              '璁惧鍨嬪彿',
              '鎿嶄綔绯荤粺鐗堟湰',
              '搴旂敤鐗堟湰',
              '浣跨敤淇℃伅',
              '鎶藉崱璁板綍',
              '瑙掕壊鏀惰棌璁板綍',
              'NFC缁戝畾璁板綍',
              '浜掑姩璁板綍',
              '鐢ㄦ埛涓婁紶鍐呭',
              '澶村儚',
              '内容说明。',
              '鐢ㄦ埛鍙嶉淇℃伅',
            ],
          ),
          SizedBox(height: 20),
          _PolicySection(
            title: '鎴戜滑濡備綍浣跨敤淇℃伅',
            paragraphs: [
              '内容说明。',
              '鎻愪緵鏈嶅姟',
              '淇濆瓨瑙掕壊鏁版嵁',
              '鎻愬崌浜у搧浣撻獙',
              '椋庨櫓鎺у埗',
            ],
          ),
          SizedBox(height: 20),
          _PolicySection(
            title: '鏉冮檺璇存槑',
            paragraphs: [
              '内容说明。',
              '内容说明。',
              '内容说明。',
              '鐩稿唽鏉冮檺',
              '内容说明。',
              '鐩告満鏉冮檺',
              '内容说明。',
              'NFC鏉冮檺',
              '内容说明。',
            ],
          ),
          SizedBox(height: 20),
          _PolicySection(
            title: '淇℃伅瀛樺偍',
            paragraphs: [
              '内容说明。',
              '内容说明。',
            ],
          ),
        ],
      ),
    );
  }
}

class UserAgreementPage extends StatelessWidget {
  const UserAgreementPage({super.key});

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
                    const CustomPaint(painter: PrivacyPolicyGlowPainter()),
                    Column(
                      children: [
                        SizedBox(
                          height: 60,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: IconButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  icon: const Icon(
                                    Icons.chevron_left_rounded,
                                    size: 34,
                                  ),
                                  color: Colors.white,
                                  tooltip: '杩斿洖',
                                ),
                              ),
                              const Text(
                                '鐢ㄦ埛鍗忚',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Expanded(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.fromLTRB(28, 14, 28, 22),
                            child: UpdatedUserAgreementContent(),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(28, 10, 28, 20),
                          child: SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: FilledButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF761CFF),
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
                              child: const Text('确认'),
                            ),
                          ),
                        ),
                      ],
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

class UserAgreementContent extends StatelessWidget {
  const UserAgreementContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTextStyle(
      style: TextStyle(
        color: Color(0xFFC9CEE3),
        fontSize: 13,
        height: 1.55,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '蹇冭薄棰戠巼鐢ㄦ埛鍗忚',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.35,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: 12),
          Text('内容说明'),
          SizedBox(height: 2),
          Text('内容说明'),
          SizedBox(height: 22),
          Text('内容说明'),
          SizedBox(height: 8),
          Text('内容说明'),
          SizedBox(height: 20),
          _PolicySection(
            title: '1. 璐﹀彿瑙勫垯',
            paragraphs: [
              '内容说明。',
              '内容说明。',
              '内容说明。',
            ],
          ),
          SizedBox(height: 20),
          _PolicySection(
            title: '2. 铏氭嫙鍐呭璇存槑',
            paragraphs: [
              '内容说明。',
              '内容说明。',
            ],
          ),
        ],
      ),
    );
  }
}

class UpdatedUserAgreementContent extends StatelessWidget {
  const UpdatedUserAgreementContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTextStyle(
      style: TextStyle(
        color: Color(0xFFC9CEE3),
        fontSize: 13,
        height: 1.55,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '蹇冭薄棰戠巼鐢ㄦ埛鍗忚',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.35,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: 12),
          Text('内容说明'),
          SizedBox(height: 2),
          Text('内容说明'),
          SizedBox(height: 22),
          Text('内容说明'),
          SizedBox(height: 12),
          Text('内容说明'),
          SizedBox(height: 20),
          _PolicySection(
            title: '璐﹀彿瑙勫垯',
            paragraphs: [
              '内容说明。',
              '内容说明。',
              '鍐掑厖浠栦汉',
              '鍙戝竷杩濇硶鍐呭',
              '鍒╃敤绯荤粺杩涜楠氭壈',
            ],
          ),
          SizedBox(height: 20),
          _PolicySection(
            title: '铏氭嫙鍐呭',
            paragraphs: [
              '内容说明。',
              '内容说明。',
            ],
          ),
          SizedBox(height: 20),
          _PolicySection(
            title: '鎶藉崱瑙勫垯',
            paragraphs: [
              '内容说明。',
              '内容说明。',
              '内容说明。',
            ],
          ),
          SizedBox(height: 20),
          _PolicySection(
            title: '鐢ㄦ埛鐢熸垚鍐呭',
            paragraphs: [
              '内容说明。',
              '内容说明。',
            ],
          ),
          SizedBox(height: 20),
          _PolicySection(
            title: '鏈嶅姟鍙樻洿',
            paragraphs: [
              '内容说明。',
            ],
          ),
          SizedBox(height: 20),
          _PolicySection(
            title: '鍗忚淇敼',
            paragraphs: [
              '内容说明。',
              '内容说明。',
            ],
          ),
        ],
      ),
    );
  }
}

class DisclaimerPage extends StatelessWidget {
  const DisclaimerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LegalShell(
      title: '鍏嶈矗澹版槑',
      bottom: GradientReturnButton(onPressed: () => Navigator.of(context).pop()),
      child: const UpdatedDisclaimerContent(),
    );
  }
}

class DisclaimerContent extends StatelessWidget {
  const DisclaimerContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTextStyle(
      style: TextStyle(
        color: Color(0xFFC9CEE3),
        fontSize: 13,
        height: 1.55,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '蹇冭薄棰戠巼鍏嶈矗澹版槑',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.35,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: 12),
          Text('内容说明'),
          SizedBox(height: 2),
          Text('内容说明'),
          SizedBox(height: 22),
          Text('内容说明'),
          SizedBox(height: 20),
          _PolicySection(
            title: '1. AI鍐呭璇存槑',
            paragraphs: [
              '内容说明。',
            ],
          ),
          SizedBox(height: 20),
          _PolicySection(
            title: '说明',
            paragraphs: [
              '内容说明。',
            ],
          ),
          SizedBox(height: 20),
          _PolicySection(
            title: '3. 娴嬭瘯缁撴灉璇存槑',
            paragraphs: [
              '内容说明。',
            ],
          ),
        ],
      ),
    );
  }
}

class UpdatedDisclaimerContent extends StatelessWidget {
  const UpdatedDisclaimerContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTextStyle(
      style: TextStyle(
        color: Color(0xFFC9CEE3),
        fontSize: 13,
        height: 1.55,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '蹇冭薄棰戠巼鍏嶈矗澹版槑',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.35,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: 12),
          Text('内容说明'),
          SizedBox(height: 2),
          Text('内容说明'),
          SizedBox(height: 22),
          Text('内容说明'),
          SizedBox(height: 12),
          Text(
            '内容说明。',
          ),
          SizedBox(height: 20),
          _PolicySection(
            title: 'AI鍐呭璇存槑',
            paragraphs: [
              '内容说明。',
              '内容说明。',
            ],
          ),
          SizedBox(height: 20),
          _PolicySection(
            title: '说明',
            paragraphs: [
              '内容说明。',
              '鍖荤枟鏈嶅姟',
              '蹇冪悊鍜ㄨ鏈嶅姟',
              '娉曞緥鏈嶅姟',
              '鎶曡祫鐞嗚储鏈嶅姟',
              '内容说明。',
            ],
          ),
          SizedBox(height: 20),
          _PolicySection(
            title: '娴嬭瘯缁撴灉璇存槑',
            paragraphs: [
              '内容说明。',
              '内容说明。',
            ],
          ),
          SizedBox(height: 20),
          _PolicySection(
            title: '铏氭嫙瑙掕壊璇存槑',
            paragraphs: [
              '内容说明。',
              '内容说明。',
            ],
          ),
          SizedBox(height: 20),
          _PolicySection(
            title: '鐢ㄦ埛璐ｄ换',
            paragraphs: [
              '内容说明。',
            ],
          ),
        ],
      ),
    );
  }
}

class VersionInfoPage extends StatelessWidget {
  const VersionInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LegalShell(
      title: '鐗堟湰淇℃伅',
      showBottomPadding: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          VersionHero(),
          SizedBox(height: 30),
          VersionInfoCard(),
          SizedBox(height: 150),
          Center(
            child: Text(
              '内容说明。',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF8E91B4),
                fontSize: 14,
                height: 1.8,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class VersionHero extends StatelessWidget {
  const VersionHero({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const ProfileAvatar(),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Flexible(
                    child: Text(
                      '蹇冭薄棰戠巼',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7044D6),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Text(
                      'v1.0.0',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                '内容说明。',
                style: TextStyle(
                  color: Color(0xFFC4C7E1),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class VersionInfoCard extends StatelessWidget {
  const VersionInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        color: const Color(0x73101A33),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF28375D)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VersionInfoRow(
            icon: Icons.workspace_premium_outlined,
            label: '褰撳墠鐗堟湰',
            value: 'v1.0.0',
          ),
          Divider(height: 32, color: Color(0x332C365B)),
          VersionInfoRow(
            icon: Icons.calendar_month_outlined,
            label: '鏇存柊鏃ユ湡',
            value: '2026-06-02',
          ),
          Divider(height: 32, color: Color(0x332C365B)),
          Text(
            '鏇存柊鍐呭',
            style: TextStyle(
              color: Color(0xFFE9EAFF),
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: 22),
          Text(
            'v1.0.0  棣栨涓婄嚎\n\n'
            '鈥?鏀寔瑙掕壊鎶藉彇\n\n'
            '鈥?鏀寔NFC瑙掕壊缁戝畾\n\n'
            '鈥?鏀寔浜掑姩瑙嗛\n\n'
            '鈥?鏀寔浜烘牸娴嬭瘯\n\n'
            '内容说明。',
            style: TextStyle(
              color: Color(0xFFD9DCF2),
              fontSize: 15,
              height: 1.28,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class VersionInfoRow extends StatelessWidget {
  const VersionInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFC9A6FF), size: 22),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class ContactUsPage extends StatelessWidget {
  const ContactUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LegalShell(
      title: '鑱旂郴鎴戜滑',
      showBottomPadding: false,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ContactHeroCard(),
          SizedBox(height: 12),
          ContactMethodCard(
            icon: Icons.headset_mic_outlined,
            title: '瀹㈡湇鐢佃瘽',
            value: 'tgxe123@126.com',
            subtitle: '宸ヤ綔鏃?9:00鈥?8:00',
          ),
          SizedBox(height: 8),
          ContactMethodCard(
            icon: Icons.mail_outline_rounded,
            title: '瀹㈡湇閭',
            value: 'tgxe123@126.com',
            subtitle: '说明',
          ),
          SizedBox(height: 8),
          ContactMethodCard(
            icon: Icons.business_center_outlined,
            title: '鍟嗗姟鍚堜綔',
            value: 'tgxe123@126.com',
            subtitle: '娆㈣繋鍚堜綔娲借皥',
          ),
          SizedBox(height: 72),
          Center(
            child: Text(
              '内容说明。',
              style: TextStyle(
                color: Color(0xFF979ABC),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class UpdatedContactUsPage extends StatelessWidget {
  const UpdatedContactUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LegalShell(
      title: '鑱旂郴鎴戜滑',
      showBottomPadding: false,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ContactHeroCard(),
          SizedBox(height: 12),
          CustomerWechatCard(),
          SizedBox(height: 8),
          ContactMethodCard(
            icon: Icons.business_center_outlined,
            title: '鍟嗗姟鍚堜綔',
            value: '13761318177',
            subtitle: '娆㈣繋鍚堜綔娲借皥',
          ),
          SizedBox(height: 72),
          Center(
            child: Text(
              '内容说明。',
              style: TextStyle(
                color: Color(0xFF979ABC),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomerWechatCard extends StatelessWidget {
  const CustomerWechatCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: const Color(0x73101A33),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF28375D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.qr_code_2_rounded, color: Color(0xFFC9A6FF), size: 24),
              SizedBox(width: 12),
              Text(
                '瀹㈡湇寰俊',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/images/customer-wechat-qr.png',
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox(
                  height: 260,
                  child: Center(
                    child: Text(
                      '璇锋坊鍔犲鏈嶅井淇′簩缁寸爜鍥剧墖',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF9CA4C6),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ContactHeroCard extends StatelessWidget {
  const ContactHeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 142,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0x77131B38),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF392A73)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '鏈夐棶棰橈紵鑱旂郴鎴戜滑',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  '内容说明。',
                  style: TextStyle(
                    color: Color(0xFFD2D1E9),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 116,
            height: 104,
            child: CustomPaint(painter: ContactIllustrationPainter()),
          ),
        ],
      ),
    );
  }
}

class ContactMethodCard extends StatelessWidget {
  const ContactMethodCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 118,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0x73101A33),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF28375D)),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF39236F),
            ),
            child: Icon(icon, color: const Color(0xFFC9A6FF), size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFA778FF),
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFFA4A7C4),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
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

class LegalShell extends StatelessWidget {
  const LegalShell({
    super.key,
    required this.title,
    required this.child,
    this.bottom,
    this.showBottomPadding = true,
  });

  final String title;
  final Widget child;
  final Widget? bottom;
  final bool showBottomPadding;

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
                    const CustomPaint(painter: PrivacyPolicyGlowPainter()),
                    Column(
                      children: [
                        SizedBox(
                          height: 60,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: IconButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  icon: const Icon(
                                    Icons.chevron_left_rounded,
                                    size: 34,
                                  ),
                                  color: Colors.white,
                                  tooltip: '杩斿洖',
                                ),
                              ),
                              Text(
                                title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(28, 24, 28, 22),
                            child: child,
                          ),
                        ),
                        if (bottom != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(28, 10, 28, 20),
                            child: bottom,
                          )
                        else if (showBottomPadding)
                          const SizedBox(height: 20),
                      ],
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

class GradientReturnButton extends StatelessWidget {
  const GradientReturnButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: const LinearGradient(
            colors: [Color(0xFF7E2BFF), Color(0xFF5E18E8)],
          ),
        ),
        child: const Text(
          '内容说明。',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class ContactIllustrationPainter extends CustomPainter {
  const ContactIllustrationPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0x887D36FF),
          const Color(0x227D36FF),
          Colors.transparent,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawOval(Offset.zero & size, glow);

    final envelope = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.14, size.height * 0.24, size.width * 0.62, size.height * 0.5),
      const Radius.circular(8),
    );
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFD9B8FF), Color(0xFF7B34FF), Color(0xFF45209E)],
      ).createShader(envelope.outerRect);
    canvas.drawRRect(envelope, paint);

    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFE9D8FF);
    final path = Path()
      ..moveTo(size.width * 0.16, size.height * 0.28)
      ..lineTo(size.width * 0.45, size.height * 0.52)
      ..lineTo(size.width * 0.74, size.height * 0.28);
    canvas.drawPath(path, line);

    final bubblePaint = Paint()..color = const Color(0xFF8E59FF);
    canvas.drawOval(
      Rect.fromLTWH(size.width * 0.68, size.height * 0.54, size.width * 0.28, size.height * 0.22),
      bubblePaint,
    );
    final dot = Paint()..color = const Color(0xFFD8C3FF);
    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(
        Offset(size.width * (0.76 + i * 0.07), size.height * 0.65),
        2.5,
        dot,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({
    required this.title,
    required this.paragraphs,
  });

  final String title;
  final List<String> paragraphs;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            height: 1.45,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 10),
        for (final paragraph in paragraphs) ...[
          Text(paragraph),
          const SizedBox(height: 3),
        ],
      ],
    );
  }
}

class PrivacyPolicyGlowPainter extends CustomPainter {
  const PrivacyPolicyGlowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final topPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0x885526FF),
          const Color(0x225526FF),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.68, size.height * 0.02),
          radius: size.width * 0.44,
        ),
      );
    canvas.drawCircle(
      Offset(size.width * 0.68, size.height * 0.02),
      size.width * 0.44,
      topPaint,
    );

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..color = const Color(0x373C57FF);

    for (var i = 0; i < 8; i++) {
      final x = size.width * (0.58 + i * 0.046);
      canvas.drawLine(
        Offset(x, size.height * 0.02),
        Offset(x + 14, size.height * 0.18),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      height: 78,
      padding: const EdgeInsets.all(2.2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFB777FF), Color(0xFF4337A8)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC15CFF).withValues(alpha: 0.55),
            blurRadius: 22,
            spreadRadius: 1,
          ),
        ],
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
    final topGlowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xCC7138FF),
          const Color(0x355727C8),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.8, size.height * 0.05),
          radius: size.width * 0.42,
        ),
      );
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.05),
      size.width * 0.42,
      topGlowPaint,
    );

    final bottomGlowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xAAE15CFF),
          const Color(0x33A33BFF),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.52, size.height * 0.96),
          radius: size.width * 0.34,
        ),
      );
    canvas.drawCircle(
      Offset(size.width * 0.52, size.height * 0.96),
      size.width * 0.34,
      bottomGlowPaint,
    );

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = const Color(0x663C57FF);

    for (var i = 0; i < 9; i++) {
      final x = size.width * (0.58 + i * 0.045);
      canvas.drawLine(
        Offset(x, size.height * 0.03),
        Offset(x + 14, size.height * 0.23),
        linePaint,
      );
    }

    final dotPaint = Paint()..color = const Color(0xAA8C65FF);
    for (var i = 0; i < 22; i++) {
      final x = size.width * (0.56 + (math.sin(i * 3.1).abs() * 0.38));
      final y = size.height * (0.03 + (math.cos(i * 1.7).abs() * 0.18));
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
