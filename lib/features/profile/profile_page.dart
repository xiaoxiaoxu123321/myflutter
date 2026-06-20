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
  final ApiClient _apiClient = ApiClient();
  bool _loadingUser = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final token = AuthSession.token;
    if (token == null || AuthSession.isGuest) return;
    setState(() {
      _loadingUser = true;
      _errorMessage = null;
    });
    try {
      final user = await _apiClient.currentUser(token: token);
      await AuthSession.updateUser(user);
    } catch (error) {
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => _loadingUser = false);
    }
  }

  Future<void> _openLogin() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginPage(nfcDataLines: [])));
    if (!mounted) return;
    setState(() {});
    await _loadUser();
  }

  Future<void> _enterGuestMode() async {
    await AuthSession.enterGuestMode();
    if (!mounted) return;
    setState(() => _errorMessage = null);
    _showMessage('已进入游客模式');
  }

  Future<void> _editNickname() async {
    final token = AuthSession.token;
    if (token == null || AuthSession.isGuest) {
      _showMessage('请先登录后修改昵称');
      return;
    }
    final controller = TextEditingController(text: AuthSession.user?['nickname']?.toString() ?? '');
    final nickname = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF15182D),
        title: const Text('修改昵称', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          maxLength: 16,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: '请输入昵称',
            counterText: '',
            hintStyle: TextStyle(color: Color(0xFF7E86A9)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('保存')),
        ],
      ),
    );
    controller.dispose();
    if (nickname == null || nickname.isEmpty) return;
    setState(() {
      _loadingUser = true;
      _errorMessage = null;
    });
    try {
      final user = await _apiClient.updateNickname(token: token, nickname: nickname);
      await AuthSession.updateUser(user);
      if (!mounted) return;
      setState(() {});
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loadingUser = false);
    }
  }

  Future<void> _logout() async {
    await AuthSession.clear();
    if (!mounted) return;
    setState(() {
      _errorMessage = null;
      _loadingUser = false;
    });
    _showMessage('已退出登录');
  }

  Future<void> _openPasswordReset() async {
    await showDialog<void>(context: context, builder: (_) => PasswordResetDialog(apiClient: _apiClient));
  }

  void _sharePublicId() {
    final publicId = AuthSession.user?['publicId']?.toString() ?? '';
    if (publicId.isEmpty) {
      _showMessage('请先登录后分享ID');
      return;
    }
    Clipboard.setData(ClipboardData(text: publicId));
    _showMessage('已复制分享ID：$publicId');
  }

  Future<void> _deactivateAccount() async {
    final token = AuthSession.token;
    if (token == null || AuthSession.isGuest) {
      _showMessage('请先登录后注销账号');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const DeactivateAccountDialog(),
    );
    if (confirmed != true) return;
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;
    setState(() => _loadingUser = true);
    try {
      await _apiClient.deactivateAccount(token: token);
      if (!mounted) return;
      await AuthSession.clear();
      if (!mounted) return;
      setState(() => _errorMessage = null);
      _showMessage('账号已注销');
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loadingUser = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthSession.user;
    final isLoggedIn = AuthSession.isLoggedIn && AuthSession.token != null;
    final isGuest = AuthSession.isGuest;
    final name = isGuest ? '游客' : user?['nickname']?.toString() ?? (_loadingUser ? '加载中' : '请先登录');
    final publicId = user?['publicId']?.toString();
    final idText = publicId == null || publicId.isEmpty ? 'ID：-' : 'ID：$publicId';
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF070817),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF2C3153)),
        boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 24, offset: Offset(0, 12))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF090A19), Color(0xFF0D1027), Color(0xFF060712)]),
              ),
            ),
            const CustomPaint(painter: ProfileGlowPainter()),
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 28, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProfileHeader(name: name, idText: idText, errorMessage: _errorMessage, loading: _loadingUser, isLoggedIn: isLoggedIn, isGuest: isGuest, onLogin: _openLogin, onGuest: _enterGuestMode, onEdit: _editNickname),
                  const SizedBox(height: 26),
                  ProfileMenuGroup(
                    title: '关于',
                    items: [
                      ProfileMenuItemData(icon: Icons.person_outline_rounded, label: '个人资料', onTap: isLoggedIn ? _editNickname : _openLogin),
                      ProfileMenuItemData(icon: Icons.workspace_premium_outlined, label: '我的权益', onTap: () => _showMessage(isLoggedIn ? '权益功能即将开放' : '请先登录')),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ProfileMenuGroup(
                    title: '协议与说明',
                    items: [
                      ProfileMenuItemData(icon: Icons.description_outlined, label: '用户协议', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UserAgreementPage()))),
                      ProfileMenuItemData(icon: Icons.privacy_tip_outlined, label: '隐私政策', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()))),
                      ProfileMenuItemData(icon: Icons.gavel_outlined, label: '免责声明', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DisclaimerPage()))),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ProfileMenuGroup(
                    title: '其他',
                    items: [
                      ProfileMenuItemData(icon: Icons.lock_reset_rounded, label: '修改密码', onTap: _openPasswordReset),
                      ProfileMenuItemData(icon: Icons.ios_share_rounded, label: '分享ID', onTap: _sharePublicId),
                      ProfileMenuItemData(icon: Icons.support_agent_rounded, label: '联系我们', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UpdatedContactUsPage()))),
                      ProfileMenuItemData(icon: Icons.info_outline_rounded, label: '版本信息', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const VersionInfoPage()))),
                      ProfileMenuItemData(icon: Icons.no_accounts_outlined, label: '注销账号', onTap: _deactivateAccount),
                    ],
                  ),
                  if (isLoggedIn) ...[
                    const SizedBox(height: 20),
                    ProfileLogoutButton(onPressed: _logout),
                  ],
                  const SizedBox(height: 16),
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
    final status = isLoggedIn ? '已登录' : isGuest ? '游客访问' : '未登录';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF343A64)),
        gradient: const LinearGradient(colors: [Color(0xFF171A32), Color(0xFF0E1124)]),
      ),
      child: Row(
        children: [
          const ProfileAvatar(size: 66),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800))),
                    if (loading) ...[
                      const SizedBox(width: 8),
                      const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE6D5FF))),
                    ],
                  ],
                ),
                const SizedBox(height: 7),
                Text(idText, style: const TextStyle(color: Color(0xFFB8B3DB), fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 7),
                Text(errorMessage ?? status, style: TextStyle(color: errorMessage == null ? const Color(0xFF7E86A9) : const Color(0xFFFF8A8A), fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              if (isLoggedIn)
                IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_rounded), color: const Color(0xFFE6D5FF), tooltip: '修改昵称')
              else ...[
                FilledButton(onPressed: onLogin, style: FilledButton.styleFrom(backgroundColor: const Color(0xFF7E70FF), foregroundColor: Colors.white), child: const Text('登录')),
                const SizedBox(height: 8),
                TextButton(onPressed: onGuest, child: const Text('游客访问')),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class DeactivateAccountDialog extends StatelessWidget {
  const DeactivateAccountDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF15182D),
      title: const Text('注销账号', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('注销后会删除当前账号及相关角色、卡片、签到、抽卡记录，且无法恢复。', style: TextStyle(color: Color(0xFFD6D8EA), height: 1.6)),
          const SizedBox(height: 10),
          const Text('请确认是否继续注销。', style: TextStyle(color: Color(0xFFFFA0B2), fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('取消')),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFF5C7A), foregroundColor: Colors.white),
          child: const Text('确认注销'),
        ),
      ],
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
  final _confirmController = TextEditingController();
  Timer? _timer;
  bool _sending = false;
  bool _saving = false;
  int _countdown = 0;
  String? _errorMessage;

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _errorMessage = '请输入手机号');
      return;
    }
    setState(() {
      _sending = true;
      _errorMessage = null;
    });
    try {
      await widget.apiClient.sendPasswordResetSmsCode(phone: phone);
      _startCountdown();
    } catch (error) {
      setState(() => _errorMessage = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _countdown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_countdown <= 1) {
        timer.cancel();
        setState(() => _countdown = 0);
      } else {
        setState(() => _countdown -= 1);
      }
    });
  }

  Future<void> _save() async {
    final phone = _phoneController.text.trim();
    final code = _codeController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();
    if ([phone, code, password, confirm].any((value) => value.isEmpty)) {
      setState(() => _errorMessage = '请完整填写信息');
      return;
    }
    if (password != confirm) {
      setState(() => _errorMessage = '两次输入的密码不一致');
      return;
    }
    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    try {
      await widget.apiClient.resetPassword(phone: phone, code: code, password: password, confirmPassword: confirm);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('密码已修改，请重新登录')));
    } catch (error) {
      if (mounted) setState(() => _errorMessage = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSend = !_sending && _countdown == 0;
    return AlertDialog(
      backgroundColor: const Color(0xFF15182D),
      title: const Text('修改密码', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ResetField(controller: _phoneController, hintText: '手机号', keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _ResetField(controller: _codeController, hintText: '验证码', keyboardType: TextInputType.number)),
                const SizedBox(width: 10),
                SizedBox(
                  width: 110,
                  child: OutlinedButton(
                    onPressed: canSend ? _sendCode : null,
                    style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFE6D5FF), side: const BorderSide(color: Color(0xFF6D5CFF))),
                    child: Text(_sending ? '发送中' : _countdown > 0 ? '${_countdown}s' : '获取验证码'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ResetField(controller: _passwordController, hintText: '新密码', obscureText: true),
            const SizedBox(height: 12),
            _ResetField(controller: _confirmController, hintText: '确认新密码', obscureText: true),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(_errorMessage!, style: const TextStyle(color: Color(0xFFFF8A8A), fontSize: 12)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.of(context).pop(), child: const Text('取消')),
        FilledButton(onPressed: _saving ? null : _save, style: FilledButton.styleFrom(backgroundColor: const Color(0xFF7E70FF)), child: Text(_saving ? '保存中' : '保存')),
      ],
    );
  }
}

class _ResetField extends StatelessWidget {
  const _ResetField({required this.controller, required this.hintText, this.keyboardType, this.obscureText = false});

  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Color(0xFF7E86A9)),
        filled: true,
        fillColor: const Color(0xFF0E1124),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF343A64))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF7E70FF))),
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
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.logout_rounded),
        label: const Text('退出登录'),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFFF8A8A),
          side: const BorderSide(color: Color(0x66FF8A8A)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

class ProfileMenuGroup extends StatelessWidget {
  const ProfileMenuGroup({super.key, required this.title, required this.items});

  final String title;
  final List<ProfileMenuItemData> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title, style: const TextStyle(color: Color(0xFF8F98C3), fontSize: 12, fontWeight: FontWeight.w700)),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xCC111428),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2C3153)),
          ),
          child: Column(
            children: [
              for (var index = 0; index < items.length; index++)
                ProfileMenuRow(item: items[index], showDivider: index < items.length - 1),
            ],
          ),
        ),
      ],
    );
  }
}

class ProfileMenuRow extends StatelessWidget {
  const ProfileMenuRow({super.key, required this.item, required this.showDivider});

  final ProfileMenuItemData item;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Icon(item.icon, color: const Color(0xFFE6D5FF), size: 22),
                const SizedBox(width: 12),
                Expanded(child: Text(item.label, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600))),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFF6E7598)),
              ],
            ),
          ),
          if (showDivider) const Divider(height: 1, thickness: 1, indent: 48, endIndent: 14, color: Color(0xFF272C4C)),
        ],
      ),
    );
  }
}

class ProfileMenuItemData {
  const ProfileMenuItemData({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalShell(title: '隐私政策', child: UpdatedPrivacyPolicyContent());
  }
}

class UserAgreementPage extends StatelessWidget {
  const UserAgreementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalShell(title: '用户协议', child: UpdatedUserAgreementContent());
  }
}

class DisclaimerPage extends StatelessWidget {
  const DisclaimerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalShell(title: '免责声明', child: UpdatedDisclaimerContent());
  }
}

class VersionInfoPage extends StatelessWidget {
  const VersionInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalShell(title: '版本信息', child: VersionInfoContent());
  }
}

class UpdatedContactUsPage extends StatelessWidget {
  const UpdatedContactUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalShell(title: '联系我们', child: ContactUsContent());
  }
}

class PrivacyPolicyContent extends StatelessWidget {
  const PrivacyPolicyContent({super.key});

  @override
  Widget build(BuildContext context) => const UpdatedPrivacyPolicyContent();
}

class UserAgreementContent extends StatelessWidget {
  const UserAgreementContent({super.key});

  @override
  Widget build(BuildContext context) => const UpdatedUserAgreementContent();
}

class DisclaimerContent extends StatelessWidget {
  const DisclaimerContent({super.key});

  @override
  Widget build(BuildContext context) => const UpdatedDisclaimerContent();
}

class LegalShell extends StatelessWidget {
  const LegalShell({super.key, required this.title, required this.child, this.bottom, this.showBottomPadding = true});

  final String title;
  final Widget child;
  final Widget? bottom;
  final bool showBottomPadding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070817),
      appBar: AppBar(
        backgroundColor: const Color(0xFF090A19),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: PrivacyPolicyGlowPainter())),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(18, 18, 18, showBottomPadding ? 28 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  child,
                  if (bottom != null) ...[
                    const SizedBox(height: 18),
                    bottom!,
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class UpdatedPrivacyPolicyContent extends StatelessWidget {
  const UpdatedPrivacyPolicyContent({super.key});

  static const sections = [
    LegalSectionData('一、我们收集的信息', '为完成登录、注册、NFC 识别、角色绑定、抽卡、签到、推荐奖励等功能，我们可能收集手机号、昵称、用户ID、设备信息、操作记录以及你主动上传的图片、视频或音频素材。'),
    LegalSectionData('二、信息的使用', '我们仅在提供服务、保障账号安全、排查故障、优化体验和履行法律义务的范围内使用你的信息。未经你的同意，我们不会将个人信息用于无关用途。'),
    LegalSectionData('三、信息的存储与保护', '我们会采取合理的技术和管理措施保护数据安全。因互联网环境并非绝对安全，请你妥善保管账号、验证码和密码。'),
    LegalSectionData('四、第三方服务', '部分短信、存储、媒体播放或支付能力可能由第三方服务提供。我们会要求第三方在必要范围内处理信息，并遵守相应的安全要求。'),
    LegalSectionData('五、你的权利', '你可以在应用内查看或修改昵称、退出登录，也可以通过联系我们申请查询、更正或删除相关个人信息。'),
    LegalSectionData('六、政策更新', '我们可能根据产品功能或法律要求更新本政策。更新后会在应用内展示新的版本内容。'),
  ];

  @override
  Widget build(BuildContext context) {
    return const _PolicySectionList(sections: sections, footer: '更新日期：2026年6月20日');
  }
}

class UpdatedUserAgreementContent extends StatelessWidget {
  const UpdatedUserAgreementContent({super.key});

  static const sections = [
    LegalSectionData('一、服务说明', '本应用提供账号注册登录、游客访问、NFC 识别、角色展示、抽卡、签到、推荐奖励以及自定义人物素材上传等功能。'),
    LegalSectionData('二、账号使用', '你应保证注册信息真实有效，并妥善保管账号、密码和验证码。因自行泄露或授权他人使用导致的损失，由你自行承担。'),
    LegalSectionData('三、内容规范', '你上传或使用的图片、视频、音频、昵称等内容不得侵犯他人合法权益，不得包含违法、侵权、欺诈、低俗或恶意内容。'),
    LegalSectionData('四、游客模式', '游客模式可访问部分功能，例如识别 NFC 并播放已关联人物视频，但不会进行绑定、领取、抽卡等需要账号的数据操作。'),
    LegalSectionData('五、服务变更', '我们可能根据运营情况调整功能、规则或界面，并会尽量保持核心体验稳定。'),
    LegalSectionData('六、违约处理', '如发现异常注册、恶意刷取奖励、攻击系统或上传违规内容，我们有权限制功能、冻结账号或删除相关内容。'),
  ];

  @override
  Widget build(BuildContext context) {
    return const _PolicySectionList(sections: sections, footer: '生效日期：2026年6月20日');
  }
}

class UpdatedDisclaimerContent extends StatelessWidget {
  const UpdatedDisclaimerContent({super.key});

  static const sections = [
    LegalSectionData('一、内容展示', '应用内角色、图片、视频、音频和互动效果仅用于产品体验展示，不构成任何承诺、保证或专业建议。'),
    LegalSectionData('二、用户上传内容', '用户应对自行上传、绑定或分享的内容负责。若相关内容侵犯第三方权益或违反法律法规，责任由上传者自行承担。'),
    LegalSectionData('三、NFC 使用', 'NFC 识别结果受设备能力、卡片状态、网络环境和绑定关系影响。游客模式下仅播放已关联人物视频，不会执行领取、绑定或资产变更。'),
    LegalSectionData('四、服务可用性', '我们会努力保障服务稳定，但因网络、设备、第三方服务、系统维护等原因可能出现中断、延迟或失败。'),
    LegalSectionData('五、奖励规则', '抽卡次数、签到奖励、推荐奖励等以系统实际记录为准。异常刷取、作弊或利用漏洞获得的奖励，我们有权进行更正。'),
  ];

  @override
  Widget build(BuildContext context) {
    return const _PolicySectionList(sections: sections, footer: '更新日期：2026年6月20日');
  }
}

class VersionInfoContent extends StatelessWidget {
  const VersionInfoContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(child: ProfileAvatar(size: 76)),
        SizedBox(height: 18),
        Center(child: Text('次元 NFC', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900))),
        SizedBox(height: 8),
        Center(child: Text('当前版本：1.0.0', style: TextStyle(color: Color(0xFFB8B3DB), fontSize: 13))),
        SizedBox(height: 22),
        LegalText('本版本支持手机号注册登录、游客访问、NFC 识别播放、角色资产管理、抽卡、签到、推荐奖励、自定义人物上传和协议查看。'),
        SizedBox(height: 14),
        LegalText('更新日期：2026年6月20日'),
      ],
    );
  }
}

class ContactUsContent extends StatelessWidget {
  const ContactUsContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const LegalText('如果你在使用过程中遇到问题，可以通过手机号或扫码添加客服联系我们。'),
        const SizedBox(height: 18),
        const ContactRow(icon: Icons.phone_iphone_rounded, label: '商务合作', value: '13761318177'),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xCC111428),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2C3153)),
          ),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/images/customer-wechat-qr.png',
                  width: 210,
                  height: 210,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 12),
              const Text('扫码添加客服', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ],
    );
  }
}

class _PolicySectionList extends StatelessWidget {
  const _PolicySectionList({required this.sections, required this.footer});

  final List<LegalSectionData> sections;
  final String footer;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final section in sections) ...[
          _PolicySection(section: section),
          const SizedBox(height: 16),
        ],
        Text(footer, style: const TextStyle(color: Color(0xFF8F98C3), fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class LegalSectionData {
  const LegalSectionData(this.title, this.body);

  final String title;
  final String body;
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({required this.section});

  final LegalSectionData section;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xCC111428),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2C3153)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(section.title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          LegalText(section.body),
        ],
      ),
    );
  }
}

class LegalText extends StatelessWidget {
  const LegalText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(color: Color(0xFFD6D8EA), fontSize: 14, height: 1.7));
  }
}

class ContactRow extends StatelessWidget {
  const ContactRow({super.key, required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xCC111428),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2C3153)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFE6D5FF)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Color(0xFF8F98C3), fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GradientReturnButton extends StatelessWidget {
  const GradientReturnButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(backgroundColor: const Color(0xFF7E70FF), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }
}

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFD36E), Color(0xFF8E6CFF), Color(0xFF49D5FF)]),
        boxShadow: const [BoxShadow(color: Color(0x665B6CFF), blurRadius: 18, offset: Offset(0, 8))],
      ),
      child: Center(
        child: Icon(Icons.auto_awesome_rounded, color: Colors.white, size: size * 0.45),
      ),
    );
  }
}

class ProfileGlowPainter extends CustomPainter {
  const ProfileGlowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 42);
    paint.color = const Color(0x665B6CFF);
    canvas.drawCircle(Offset(size.width * 0.18, size.height * 0.12), math.min(size.width, size.height) * 0.18, paint);
    paint.color = const Color(0x4449D5FF);
    canvas.drawCircle(Offset(size.width * 0.86, size.height * 0.22), math.min(size.width, size.height) * 0.16, paint);
    paint.color = const Color(0x33FFD36E);
    canvas.drawCircle(Offset(size.width * 0.62, size.height * 0.88), math.min(size.width, size.height) * 0.2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PrivacyPolicyGlowPainter extends CustomPainter {
  const PrivacyPolicyGlowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 54);
    paint.color = const Color(0x554D7CFF);
    canvas.drawCircle(Offset(size.width * 0.12, size.height * 0.16), math.min(size.width, size.height) * 0.22, paint);
    paint.color = const Color(0x335BE4FF);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.34), math.min(size.width, size.height) * 0.2, paint);
    paint.color = const Color(0x228E6CFF);
    canvas.drawCircle(Offset(size.width * 0.45, size.height * 0.92), math.min(size.width, size.height) * 0.26, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
