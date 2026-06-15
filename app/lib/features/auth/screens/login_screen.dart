import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.glamGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(flex: 2),
                const Text(
                  '점심어때',
                  style: TextStyle(
                    fontSize: 40, fontWeight: FontWeight.w800,
                    color: Colors.white, letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '인플루언서와 함께하는\n특별한 점심 한 끼',
                  style: TextStyle(fontSize: 17, color: Colors.white.withOpacity(0.9), height: 1.5),
                ),
                const Spacer(flex: 3),
                _KakaoButton(loading: _loading, onTap: _loginKakao),
                const SizedBox(height: 14),
                _PhoneButton(onTap: () => _showPhoneSheet(context)),
                const SizedBox(height: 32),
                Center(
                  child: Text(
                    '가입 시 이용약관 및 개인정보처리방침에 동의하게 됩니다.',
                    style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6)),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loginKakao() async {
    setState(() => _loading = true);
    // TODO: 카카오 SDK 연동 후 access_token 획득 → API 호출
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _loading = false);
    if (mounted) context.go('/feed');
  }

  void _showPhoneSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => const _PhoneLoginSheet(),
    );
  }
}

class _KakaoButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;
  const _KakaoButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: const Color(0xFFFEE500),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: loading
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('카카오로 시작하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF391B1B))),
        ),
      ),
    );
  }
}

class _PhoneButton extends StatelessWidget {
  final VoidCallback onTap;
  const _PhoneButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.4)),
        ),
        child: const Center(
          child: Text('전화번호로 시작하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
        ),
      ),
    );
  }
}

class _PhoneLoginSheet extends StatefulWidget {
  const _PhoneLoginSheet();

  @override
  State<_PhoneLoginSheet> createState() => _PhoneLoginSheetState();
}

class _PhoneLoginSheetState extends State<_PhoneLoginSheet> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _otpSent = false;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('전화번호 로그인', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: '전화번호', hintText: '010-0000-0000'),
          ),
          if (_otpSent) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _otpCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(labelText: '인증번호 6자리'),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _loading ? null : (_otpSent ? _verifyOtp : _sendOtp),
              child: _loading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(_otpSent ? '인증하기' : '인증번호 받기'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendOtp() async {
    setState(() => _loading = true);
    // TODO: API 호출
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() { _loading = false; _otpSent = true; });
  }

  Future<void> _verifyOtp() async {
    setState(() => _loading = true);
    // TODO: API 호출 → 토큰 저장
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() => _loading = false);
    if (mounted) { Navigator.pop(context); context.go('/feed'); }
  }
}
