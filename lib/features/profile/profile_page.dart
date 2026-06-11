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

  void _openVersionInfo() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const VersionInfoPage()),
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
                    name: name,
                    idText: idText,
                    errorMessage: _errorMessage,
                    loading: _loadingUser,
                    isLoggedIn: isLoggedIn,
                    onLogin: _openLogin,
                    onEdit: _editNickname,
                  ),
                  const SizedBox(height: 26),
                  const ProfileMenuGroup(
                    title: '关于',
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
                  const SizedBox(height: 10),
                  ProfileMenuGroup(
                    title: '协议与说明',
                    items: [
                      ProfileMenuItemData(
                        icon: Icons.article_outlined,
                        title: '用户协议',
                        subtitle: '使用规则与权益说明',
                        onTap: _openUserAgreement,
                      ),
                      ProfileMenuItemData(
                        icon: Icons.lock_outline_rounded,
                        title: '隐私政策',
                        subtitle: '了解我们如何保护您的信息',
                        onTap: _openPrivacyPolicy,
                      ),
                      ProfileMenuItemData(
                        icon: Icons.fact_check_outlined,
                        title: '免责声明',
                        subtitle: '使用前请阅读重要说明',
                        onTap: _openDisclaimer,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ProfileMenuGroup(
                    title: '其他',
                    items: [
                      ProfileMenuItemData(
                        icon: Icons.chat_bubble_outline_rounded,
                        title: '联系我们',
                        subtitle: '意见反馈与客服支持',
                        onTap: _openContactUs,
                      ),
                      ProfileMenuItemData(
                        icon: Icons.add_circle_outline_rounded,
                        title: '版本信息',
                        subtitle: '当前版本 1.0.0',
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
    required this.onLogin,
    required this.onEdit,
  });

  final String name;
  final String idText;
  final String? errorMessage;
  final bool loading;
  final bool isLoggedIn;
  final VoidCallback onLogin;
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
                        onTap: isLoggedIn ? null : onLogin,
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
                    SizedBox(
                      width: 30,
                      height: 30,
                      child: IconButton(
                        onPressed: loading ? null : onEdit,
                        icon: const Icon(Icons.edit_rounded),
                        iconSize: 16,
                        color: const Color(0xFFDCA6FF),
                        padding: EdgeInsets.zero,
                        tooltip: '修改昵称',
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
                                  tooltip: '返回',
                                ),
                              ),
                              const Text(
                                '隐私政策',
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
                              child: const Text('同意并返回'),
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
            '心象频率隐私政策',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.35,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: 12),
          Text('更新日期：2024年05月20日'),
          SizedBox(height: 2),
          Text('生效日期：2024年05月20日'),
          SizedBox(height: 22),
          Text('我们非常重视您的个人信息保护，并致力于保护您的隐私安全。'),
          SizedBox(height: 20),
          _PolicySection(
            title: '1. 我们收集的信息',
            paragraphs: [
              '1.1 账号信息：包括用户ID、昵称、头像、性别、生日等。',
              '1.2 设备信息：包括设备型号、操作系统版本、应用版本、设备标识符等。',
              '1.3 使用信息：包括拍卡记录、角色收藏记录、NFC绑定记录、互动记录、浏览记录等。',
              '1.4 用户上传内容：包括头像、语音、自定义角色形象、用户反馈信息等。',
            ],
          ),
          SizedBox(height: 20),
          _PolicySection(
            title: '2. 我们如何使用信息',
            paragraphs: [
              '用于登录认证、账号安全、服务展示、资产绑定、礼物互动、客户支持与产品体验优化。',
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
            '心象频率隐私政策',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.35,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: 12),
          Text('更新日期：2026年6月6日'),
          SizedBox(height: 2),
          Text('生效日期：2026年6月6日'),
          SizedBox(height: 22),
          Text('我们非常重视您的个人信息保护。'),
          SizedBox(height: 20),
          _PolicySection(
            title: '我们收集的信息',
            paragraphs: [
              '账号信息',
              '用户ID',
              '昵称',
              '头像',
              '设备信息',
              '设备型号',
              '操作系统版本',
              '应用版本',
              '使用信息',
              '抽卡记录',
              '角色收藏记录',
              'NFC绑定记录',
              '互动记录',
              '用户上传内容',
              '头像',
              '自定义语音',
              '用户反馈信息',
            ],
          ),
          SizedBox(height: 20),
          _PolicySection(
            title: '我们如何使用信息',
            paragraphs: [
              '用于：',
              '提供服务',
              '保存角色数据',
              '提升产品体验',
              '风险控制',
            ],
          ),
          SizedBox(height: 20),
          _PolicySection(
            title: '权限说明',
            paragraphs: [
              '可能申请以下权限：',
              '麦克风权限',
              '用于录制角色互动语音。',
              '相册权限',
              '用于上传头像图片。',
              '相机权限',
              '用于拍摄头像或上传照片。',
              'NFC权限',
              '用于识别和绑定实体角色贴纸。',
            ],
          ),
          SizedBox(height: 20),
          _PolicySection(
            title: '信息存储',
            paragraphs: [
              '用户数据将通过加密方式进行存储。',
              '未经用户同意不会向第三方出售个人信息。',
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
                                  tooltip: '返回',
                                ),
                              ),
                              const Text(
                                '用户协议',
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
                              child: const Text('同意并返回'),
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
            '心象频率用户协议',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.35,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: 12),
          Text('更新日期：2024年05月20日'),
          SizedBox(height: 2),
          Text('生效日期：2024年05月20日'),
          SizedBox(height: 22),
          Text('欢迎使用心象频率！'),
          SizedBox(height: 8),
          Text('当您注册、登录或使用本应用时，即视为已阅读并同意本协议的全部内容。'),
          SizedBox(height: 20),
          _PolicySection(
            title: '1. 账号规则',
            paragraphs: [
              '1.1 用户应保证注册信息真实、准确、合法有效。',
              '1.2 用户不得以任何方式冒充他人或虚构身份进行注册。',
              '1.3 用户不得利用本应用从事违法违规、侵害他人权益或干扰平台正常运营的行为。',
            ],
          ),
          SizedBox(height: 20),
          _PolicySection(
            title: '2. 虚拟内容说明',
            paragraphs: [
              '2.1 应用内的角色、道具、影像、贴纸等均为虚拟数字内容，用户获得的是使用权而非所有权。',
              '2.2 平台有权在法律允许的范围内对虚拟内容进行调整、更新下线。',
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
            '心象频率用户协议',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.35,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: 12),
          Text('更新日期：2026年6月6日'),
          SizedBox(height: 2),
          Text('生效日期：2026年6月6日'),
          SizedBox(height: 22),
          Text('欢迎使用心象频率。'),
          SizedBox(height: 12),
          Text('当您注册、登录或使用本应用时，即视为已阅读并同意本协议。'),
          SizedBox(height: 20),
          _PolicySection(
            title: '账号规则',
            paragraphs: [
              '用户应保证注册信息真实合法。',
              '不得：',
              '冒充他人',
              '发布违法内容',
              '利用系统进行骚扰',
            ],
          ),
          SizedBox(height: 20),
          _PolicySection(
            title: '虚拟内容',
            paragraphs: [
              '应用内角色、道具、抽卡奖励等均属于虚拟数字内容。',
              '用户获得的是使用权而非所有权。',
            ],
          ),
          SizedBox(height: 20),
          _PolicySection(
            title: '抽卡规则',
            paragraphs: [
              '抽卡结果由概率机制随机生成。',
              '用户理解并接受随机结果。',
              '运营方不会承诺获得指定角色。',
            ],
          ),
          SizedBox(height: 20),
          _PolicySection(
            title: '用户生成内容',
            paragraphs: [
              '用户上传的头像、昵称、语音等内容应合法合规。',
              '用户应保证拥有相关内容使用权。',
            ],
          ),
          SizedBox(height: 20),
          _PolicySection(
            title: '服务变更',
            paragraphs: [
              '运营方有权根据业务发展调整功能、活动和运营规则。',
            ],
          ),
          SizedBox(height: 20),
          _PolicySection(
            title: '协议修改',
            paragraphs: [
              '运营方有权对本协议进行更新。',
              '更新后继续使用即视为同意。',
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
      title: '免责声明',
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
            '心象频率免责声明',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.35,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: 12),
          Text('更新日期：2024年05月20日'),
          SizedBox(height: 2),
          Text('生效日期：2024年05月20日'),
          SizedBox(height: 22),
          Text('请您在使用本应用前，仔细阅读本免责声明。'),
          SizedBox(height: 20),
          _PolicySection(
            title: '1. AI内容说明',
            paragraphs: [
              '本应用所有展示的对话、建议、测试结果及角色互动内容均由AI智能生成，相关内容仅供参考，不代表专业意见。',
            ],
          ),
          SizedBox(height: 20),
          _PolicySection(
            title: '2. 非专业服务声明',
            paragraphs: [
              '本应用不提供以下服务：医疗服务、心理咨询服务、法律服务、投资理财服务，用户不应依赖本应用内容作出重大决策。',
            ],
          ),
          SizedBox(height: 20),
          _PolicySection(
            title: '3. 测试结果说明',
            paragraphs: [
              '应用中的人格测试、恋爱测试、性格测试等功能仅供娱乐参考，测试结果不构成心理诊断依据。',
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
            '心象频率免责声明',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.35,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: 12),
          Text('更新日期：2026年6月6日'),
          SizedBox(height: 2),
          Text('生效日期：2026年6月6日'),
          SizedBox(height: 22),
          Text('欢迎使用心象频率。'),
          SizedBox(height: 12),
          Text(
            '本应用中的角色形象、对话内容、互动视频、抽卡测试、人格测试等内容均由系统生成或整理，仅供娱乐、陪伴及社交体验使用。',
          ),
          SizedBox(height: 20),
          _PolicySection(
            title: 'AI内容说明',
            paragraphs: [
              '本应用所展示的对话、建议、测试结果及角色互动内容均由人工智能生成。',
              '相关内容仅供参考，不代表专业意见。',
            ],
          ),
          SizedBox(height: 20),
          _PolicySection(
            title: '非专业服务声明',
            paragraphs: [
              '本应用不提供：',
              '医疗服务',
              '心理咨询服务',
              '法律服务',
              '投资理财服务',
              '用户不应依据应用内容作出重大决策。',
            ],
          ),
          SizedBox(height: 20),
          _PolicySection(
            title: '测试结果说明',
            paragraphs: [
              '应用中的人格测试、恋爱测试、性格测试等功能仅供娱乐参考。',
              '测试结果不构成心理诊断依据。',
            ],
          ),
          SizedBox(height: 20),
          _PolicySection(
            title: '虚拟角色说明',
            paragraphs: [
              '应用中的角色均为虚拟角色。',
              '其言论、行为和观点不代表运营方立场。',
            ],
          ),
          SizedBox(height: 20),
          _PolicySection(
            title: '用户责任',
            paragraphs: [
              '用户应自行判断并承担使用本应用产生的相关风险和后果。',
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
      title: '版本信息',
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
              'Copyright © 2026 心象频率\n保留所有权利',
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
                      '心象频率',
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
                '当前已是最新版本',
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
            label: '当前版本',
            value: 'v1.0.0',
          ),
          Divider(height: 32, color: Color(0x332C365B)),
          VersionInfoRow(
            icon: Icons.calendar_month_outlined,
            label: '更新日期',
            value: '2026-06-02',
          ),
          Divider(height: 32, color: Color(0x332C365B)),
          Text(
            '更新内容',
            style: TextStyle(
              color: Color(0xFFE9EAFF),
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: 22),
          Text(
            'v1.0.0  首次上线\n\n'
            '• 支持角色抽取\n\n'
            '• 支持NFC角色绑定\n\n'
            '• 支持互动视频\n\n'
            '• 支持人格测试\n\n'
            '• 优化用户体验，修复已知问题',
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
      title: '联系我们',
      showBottomPadding: false,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ContactHeroCard(),
          SizedBox(height: 12),
          ContactMethodCard(
            icon: Icons.headset_mic_outlined,
            title: '客服电话',
            value: 'tgxe123@126.com',
            subtitle: '工作日 9:00–18:00',
          ),
          SizedBox(height: 8),
          ContactMethodCard(
            icon: Icons.mail_outline_rounded,
            title: '客服邮箱',
            value: 'tgxe123@126.com',
            subtitle: '24小时内回复',
          ),
          SizedBox(height: 8),
          ContactMethodCard(
            icon: Icons.business_center_outlined,
            title: '商务合作',
            value: 'tgxe123@126.com',
            subtitle: '欢迎合作洽谈',
          ),
          SizedBox(height: 72),
          Center(
            child: Text(
              '感谢您的支持与信任 ♡',
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
      title: '联系我们',
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
            title: '商务合作',
            value: '13761318177',
            subtitle: '欢迎合作洽谈',
          ),
          SizedBox(height: 72),
          Center(
            child: Text(
              '感谢您的支持与信任',
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
                '客服微信',
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
                      '请添加客服微信二维码图片',
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
                  '有问题？联系我们',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  '我们会尽快为您处理',
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
                                  tooltip: '返回',
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
          '同意并返回',
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
