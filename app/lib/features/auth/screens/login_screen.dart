import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/api.dart';
import '../../../core/auth/auth_provider.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(fit: StackFit.expand, children: [
        // 배경 그라디언트
        Container(decoration: const BoxDecoration(gradient: AppColors.glamGradient)),

        // 장식 원형
        Positioned(top: -80, right: -60,
          child: Container(width: 260, height: 260,
            decoration: BoxDecoration(shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.07)))),
        Positioned(bottom: 100, left: -80,
          child: Container(width: 320, height: 320,
            decoration: BoxDecoration(shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.05)))),

        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(flex: 2),

                // 브랜드 태그
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: const Text('Do Lunch', style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w800,
                    color: Colors.white, letterSpacing: 3,
                  )),
                ),
                const SizedBox(height: 28),

                // 앱 이름
                const Text(
                  '점심어때?',
                  style: TextStyle(
                    fontSize: 52, fontWeight: FontWeight.w800,
                    color: Colors.white, height: 1.1, letterSpacing: -1.5,
                  ),
                ),

                const Spacer(flex: 2),

                // 가치 키워드 3개
                Row(children: [
                  _Keyword('의미있는 대화'),
                  const SizedBox(width: 8),
                  _Keyword('특별한 경험'),
                  const SizedBox(width: 8),
                  _Keyword('가치있는 한 끼'),
                ]),

                const Spacer(flex: 3),

                // 시작하기 버튼
                SizedBox(
                  width: double.infinity, height: 58,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, fontFamily: 'Pretendard'),
                    ),
                    onPressed: () => _showAuthSheet(context),
                    child: const Text('시작하기'),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    '가입 시 이용약관 · 개인정보처리방침에 동의합니다',
                    style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.5)),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  void _showAuthSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AuthSheet(),
    );
  }
}

class _Keyword extends StatelessWidget {
  final String label;
  const _Keyword(this.label);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.13),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
    ),
    child: Text(label, style: TextStyle(
      fontSize: 12, fontWeight: FontWeight.w600,
      color: Colors.white.withValues(alpha: 0.9),
    )),
  );
}

// ─── 로그인 선택 바텀시트 ────────────────────────────────────────────────────
class _AuthSheet extends StatefulWidget {
  const _AuthSheet();

  @override
  State<_AuthSheet> createState() => _AuthSheetState();
}

class _AuthSheetState extends State<_AuthSheet> {
  bool _showPhone = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(context).padding.bottom + 32),
      child: _showPhone
          ? _PhoneFlow(onBack: () => setState(() => _showPhone = false))
          : _ProviderList(onPhoneTap: () => setState(() => _showPhone = true)),
    );
  }
}

class _ProviderList extends ConsumerWidget {
  final VoidCallback onPhoneTap;
  const _ProviderList({required this.onPhoneTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      // 핸들 바
      Center(child: Container(
        width: 36, height: 4, margin: const EdgeInsets.only(bottom: 28),
        decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(2)),
      )),

      const Text('시작하는 방법을 선택하세요', style: TextStyle(
        fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink,
      )),
      const SizedBox(height: 6),
      const Text('가입과 로그인이 한 번에', style: TextStyle(fontSize: 14, color: AppColors.sub)),
      const SizedBox(height: 32),

      // 카카오
      _SocialBtn(
        label: '카카오로 계속하기',
        bg: const Color(0xFFFEE500),
        fg: const Color(0xFF391B1B),
        icon: _KakaoIcon(),
        onTap: () => _mockLogin(context, ref),
      ),
      const SizedBox(height: 12),

      // 네이버
      _SocialBtn(
        label: '네이버로 계속하기',
        bg: const Color(0xFF03C75A),
        fg: Colors.white,
        icon: const _NaverIcon(),
        onTap: () => _mockLogin(context, ref),
      ),
      const SizedBox(height: 12),

      // 전화번호
      _SocialBtn(
        label: '전화번호로 계속하기',
        bg: AppColors.base,
        fg: AppColors.ink,
        icon: const Icon(Icons.phone_outlined, size: 20, color: AppColors.sub),
        onTap: onPhoneTap,
        bordered: true,
      ),
    ]);
  }

  Future<void> _mockLogin(BuildContext context, WidgetRef ref) async {
    try {
      final dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
      final res = await dio.post<Map<String, dynamic>>('/auth/dev-login');
      final token = res.data!['token'] as String;
      await ref.read(authNotifierProvider).login(token);
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그인 실패: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }
}

class _SocialBtn extends StatelessWidget {
  final String label;
  final Color bg, fg;
  final Widget icon;
  final VoidCallback onTap;
  final bool bordered;
  const _SocialBtn({
    required this.label, required this.bg, required this.fg,
    required this.icon, required this.onTap, this.bordered = false,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 54,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: bordered ? Border.all(color: AppColors.line, width: 1.5) : null,
      ),
      child: Row(children: [
        const SizedBox(width: 20),
        SizedBox(width: 24, child: icon),
        Expanded(child: Center(child: Text(label, style: TextStyle(
          fontSize: 15, fontWeight: FontWeight.w700, color: fg,
        )))),
        const SizedBox(width: 44),
      ]),
    ),
  );
}

class _KakaoIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Text('K', style: TextStyle(
    fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF391B1B),
  ));
}

class _NaverIcon extends StatelessWidget {
  const _NaverIcon();

  @override
  Widget build(BuildContext context) => const Text('N', style: TextStyle(
    fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white,
  ));
}

// ─── 전화번호 플로우 ──────────────────────────────────────────────────────────
class _PhoneFlow extends ConsumerStatefulWidget {
  final VoidCallback onBack;
  const _PhoneFlow({required this.onBack});

  @override
  ConsumerState<_PhoneFlow> createState() => _PhoneFlowState();
}

class _PhoneFlowState extends ConsumerState<_PhoneFlow> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _otpSent = false;
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        GestureDetector(
          onTap: widget.onBack,
          child: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.ink),
        ),
        const SizedBox(width: 12),
        const Text('전화번호로 계속하기', style: TextStyle(
          fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink,
        )),
      ]),
      const SizedBox(height: 24),

      TextField(
        controller: _phoneCtrl,
        keyboardType: TextInputType.phone,
        enabled: !_otpSent,
        decoration: const InputDecoration(hintText: '010-0000-0000', prefixText: '+82 '),
      ),
      if (_otpSent) ...[
        const SizedBox(height: 12),
        TextField(
          controller: _otpCtrl,
          keyboardType: TextInputType.number,
          maxLength: 6,
          autofocus: true,
          decoration: const InputDecoration(hintText: '인증번호 6자리', counterText: ''),
        ),
      ],
      if (_error != null) ...[
        const SizedBox(height: 8),
        Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
      ],
      const SizedBox(height: 20),
      SizedBox(
        width: double.infinity, height: 54,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppColors.glamGradient,
            borderRadius: BorderRadius.circular(14),
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _loading ? null : (_otpSent ? _verify : _send),
            child: _loading
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(_otpSent ? '인증하기' : '인증번호 받기',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
        ),
      ),
    ]);
  }

  Future<void> _send() async {
    setState(() { _loading = true; _error = null; });
    await Future.delayed(const Duration(milliseconds: 400));
    setState(() { _loading = false; _otpSent = true; });
  }

  Future<void> _verify() async {
    setState(() { _loading = true; _error = null; });
    try {
      final dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
      final res = await dio.post<Map<String, dynamic>>('/auth/dev-login');
      final token = res.data!['token'] as String;
      await ref.read(authNotifierProvider).login(token);
      setState(() => _loading = false);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() { _loading = false; _error = '로그인 실패. 다시 시도해 주세요.'; });
    }
  }
}
