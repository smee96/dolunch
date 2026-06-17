import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/auth/auth_provider.dart';

final _appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return '${info.version} (${info.buildNumber})';
});

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versionAsync = ref.watch(_appVersionProvider);

    return Scaffold(
      backgroundColor: AppColors.base,
      appBar: AppBar(
        backgroundColor: AppColors.base,
        elevation: 0,
        leading: const BackButton(color: AppColors.ink),
        title: const Text('설정',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── 계정 ──────────────────────────────────────────────────────────
          _SectionHeader('계정'),
          _SettingsCard(children: [
            _Tile(
              icon: Icons.receipt_long_outlined,
              label: '정산 내역',
              onTap: () => context.push('/settlements'),
            ),
            _Divider(),
            _Tile(
              icon: Icons.person_outline,
              label: '계정 정보',
              onTap: () => context.push('/settings/account'),
            ),
          ]),
          const SizedBox(height: 20),

          // ── 알림 ──────────────────────────────────────────────────────────
          _SectionHeader('알림'),
          _SettingsCard(children: [
            _SwitchTile(
              icon: Icons.notifications_outlined,
              label: '새 지원자 알림',
              prefKey: 'notif_applicant',
            ),
            _Divider(),
            _SwitchTile(
              icon: Icons.check_circle_outline,
              label: '수락/거절 알림',
              prefKey: 'notif_decision',
            ),
            _Divider(),
            _SwitchTile(
              icon: Icons.people_alt_outlined,
              label: '팔로우 알림',
              prefKey: 'notif_follow',
            ),
            _Divider(),
            _SwitchTile(
              icon: Icons.chat_bubble_outline,
              label: '댓글 알림',
              prefKey: 'notif_comment',
            ),
          ]),
          const SizedBox(height: 20),

          // ── 앱 정보 ────────────────────────────────────────────────────────
          _SectionHeader('앱 정보'),
          _SettingsCard(children: [
            _Tile(
              icon: Icons.info_outline,
              label: '앱 버전',
              trailing: versionAsync.when(
                data: (v) => Text(v, style: const TextStyle(fontSize: 13, color: AppColors.sub)),
                loading: () => const SizedBox(width: 60, child: LinearProgressIndicator()),
                error: (_, __) => const Text('-', style: TextStyle(color: AppColors.sub)),
              ),
            ),
            _Divider(),
            _Tile(
              icon: Icons.description_outlined,
              label: '이용약관',
              onTap: () {},
            ),
            _Divider(),
            _Tile(
              icon: Icons.lock_outline,
              label: '개인정보처리방침',
              onTap: () {},
            ),
          ]),
          const SizedBox(height: 20),

          // ── 계정 관리 ──────────────────────────────────────────────────────
          _SectionHeader('계정 관리'),
          _SettingsCard(children: [
            _Tile(
              icon: Icons.logout,
              label: '로그아웃',
              labelColor: AppColors.danger,
              onTap: () => _logout(context, ref),
            ),
            _Divider(),
            _Tile(
              icon: Icons.person_remove_outlined,
              label: '회원탈퇴',
              labelColor: AppColors.danger,
              onTap: () => _deleteAccount(context, ref),
            ),
          ]),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('로그아웃 하시겠어요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('로그아웃', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authNotifierProvider).logout();
    }
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('회원탈퇴'),
        content: const Text('탈퇴하면 모든 데이터가 삭제돼요.\n정말 탈퇴하시겠어요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('탈퇴', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('계정 삭제 기능은 준비 중이에요')),
      );
    }
  }
}

// ─── 공통 위젯 ─────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader(this.label);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.sub, letterSpacing: 0.5)),
  );
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 2))],
    ),
    child: Column(children: children),
  );
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? labelColor;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _Tile({required this.icon, required this.label, this.labelColor, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: labelColor ?? AppColors.ink, size: 22),
    title: Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: labelColor ?? AppColors.ink)),
    trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right, color: AppColors.sub, size: 20) : null),
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
  );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 16),
    child: Divider(height: 1, color: AppColors.line),
  );
}

// 알림 설정 스위치 (앱 내 상태만 관리, FCM 연동 시 교체)
final _notifPrefsProvider = StateProvider<Map<String, bool>>((ref) => {
  'notif_applicant': true,
  'notif_decision': true,
  'notif_follow': true,
  'notif_comment': false,
});

class _SwitchTile extends ConsumerWidget {
  final IconData icon;
  final String label;
  final String prefKey;
  const _SwitchTile({required this.icon, required this.label, required this.prefKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(_notifPrefsProvider);
    final enabled = prefs[prefKey] ?? false;

    return ListTile(
      leading: Icon(icon, color: AppColors.ink, size: 22),
      title: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink)),
      trailing: Switch(
        value: enabled,
        onChanged: (v) => ref.read(_notifPrefsProvider.notifier).update((s) => {...s, prefKey: v}),
        activeColor: AppColors.primary,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}
