import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/theme/app_theme.dart';

const _kOnboardingKey = 'onboarding_done';
const _storage = FlutterSecureStorage();

final onboardingDoneProvider = FutureProvider<bool>((ref) async {
  final v = await _storage.read(key: _kOnboardingKey);
  return v == 'true';
});

Future<void> markOnboardingDone() async {
  await _storage.write(key: _kOnboardingKey, value: 'true');
}

// ─── 온보딩 데이터 ────────────────────────────────────────────────────────────
const _pages = [
  _OnboardingPage(
    icon: Icons.restaurant,
    gradient: AppColors.glamGradient,
    title: '특별한 점심 한 끼',
    subtitle: '영향력 있는 호스트가 여는\n프라이빗 식사 자리에 초대받으세요.',
  ),
  _OnboardingPage(
    icon: Icons.people_alt_outlined,
    gradient: LinearGradient(
      colors: [Color(0xFFFF8A3D), Color(0xFFFF5F7E)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    title: '의미있는 대화',
    subtitle: '적은 인원, 깊은 대화.\n동료, 멘토, 새로운 친구를 만나세요.',
  ),
  _OnboardingPage(
    icon: Icons.verified_outlined,
    gradient: LinearGradient(
      colors: [Color(0xFF9B2F6B), Color(0xFF6A2150)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    title: '신뢰할 수 있는 모임',
    subtitle: '보증금 시스템으로 노쇼를 방지하고\n모두가 책임감 있는 모임을 만들어요.',
  ),
];

class _OnboardingPage {
  final IconData icon;
  final Gradient gradient;
  final String title;
  final String subtitle;
  const _OnboardingPage({
    required this.icon, required this.gradient,
    required this.title, required this.subtitle,
  });
}

// ─── 화면 ─────────────────────────────────────────────────────────────────────
class OnboardingScreen extends ConsumerStatefulWidget {
  final VoidCallback onDone;
  const OnboardingScreen({super.key, required this.onDone});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _pages.length - 1;

    return Scaffold(
      body: Stack(children: [
        // 배경 그라디언트 (현재 페이지)
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: Container(
            key: ValueKey(_page),
            decoration: BoxDecoration(gradient: _pages[_page].gradient),
          ),
        ),

        // 장식 원형
        Positioned(top: -60, right: -80,
          child: Container(width: 240, height: 240,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.07)))),
        Positioned(bottom: 120, left: -60,
          child: Container(width: 200, height: 200,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.05)))),

        SafeArea(
          child: Column(children: [
            const SizedBox(height: 16),

            // 스킵 버튼
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finish,
                child: Text('건너뛰기', style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7), fontSize: 14, fontWeight: FontWeight.w600,
                )),
              ),
            ),

            // 페이지 뷰
            Expanded(
              child: PageView.builder(
                controller: _ctrl,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _pages.length,
                itemBuilder: (_, i) => _PageContent(page: _pages[i]),
              ),
            ),

            // 인디케이터 + 버튼
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
              child: Column(children: [
                // 도트 인디케이터
                Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(
                  _pages.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _page ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _page ? Colors.white : Colors.white.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                )),
                const SizedBox(height: 32),

                // 버튼
                SizedBox(
                  width: double.infinity, height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'Pretendard'),
                    ),
                    onPressed: isLast ? _finish : _next,
                    child: Text(isLast ? '시작하기' : '다음'),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }

  void _next() {
    _ctrl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  Future<void> _finish() async {
    await markOnboardingDone();
    widget.onDone();
  }
}

class _PageContent extends StatelessWidget {
  final _OnboardingPage page;
  const _PageContent({required this.page});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 40),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      // 아이콘
      Container(
        width: 120, height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
        ),
        child: Icon(page.icon, size: 56, color: Colors.white),
      ),
      const SizedBox(height: 40),

      // 제목
      Text(page.title, style: const TextStyle(
        fontSize: 30, fontWeight: FontWeight.w800,
        color: Colors.white, height: 1.2, letterSpacing: -0.5,
      ), textAlign: TextAlign.center),
      const SizedBox(height: 16),

      // 설명
      Text(page.subtitle, style: TextStyle(
        fontSize: 16, color: Colors.white.withValues(alpha: 0.85),
        height: 1.6,
      ), textAlign: TextAlign.center),
    ]),
  );
}
