import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/feed_provider.dart';
import '../widgets/reel_slide.dart';
import '../widgets/deposit_sheet.dart';
import '../../../core/models/models.dart';
import '../../../core/theme/app_theme.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final _pageCtrl = PageController();
  int _current = 0;
  String _tab = 'explore';
  final _liked = <String, bool>{};

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _onPageChanged(int idx, List<Reel> reels) {
    setState(() => _current = idx);
    if (idx >= reels.length - 2) {
      ref.read(feedProvider.notifier).loadMore();
    }
  }

  void _showDeposit(Reel reel) {
    if (reel.roomId == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DepositSheet(reel: reel),
    );
  }

  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(feedProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Stack(
        children: [
          feedAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (e, _) => Center(child: Text('오류: $e', style: const TextStyle(color: Colors.white))),
            data: (reels) => reels.isEmpty
                ? const Center(child: Text('숏츠가 없습니다', style: TextStyle(color: Colors.white54)))
                : PageView.builder(
                    controller: _pageCtrl,
                    scrollDirection: Axis.vertical,
                    itemCount: reels.length,
                    onPageChanged: (i) => _onPageChanged(i, reels),
                    itemBuilder: (_, i) => ReelSlide(
                      reel: reels[i],
                      liked: _liked[reels[i].id] ?? false,
                      onLike: () async {
                        final liked = await ref.read(feedProvider.notifier).toggleLike(reels[i].id);
                        setState(() => _liked[reels[i].id] = liked);
                      },
                      onApply: () => _showDeposit(reels[i]),
                    ),
                  ),
          ),

          // 상단 탭 (팔로잉 / 둘러보기) + 검색
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
              child: Row(children: [
                // 검색 버튼
                GestureDetector(
                  onTap: () => context.push('/search'),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    child: const Icon(Icons.search, color: Colors.white, size: 20),
                  ),
                ),
                // 탭
                Expanded(
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    _TabBtn(label: '팔로잉', active: _tab == 'following',
                      onTap: () { setState(() => _tab = 'following'); ref.read(feedProvider.notifier).switchType('following'); }),
                    const SizedBox(width: 22),
                    _TabBtn(label: '둘러보기', active: _tab == 'explore',
                      onTap: () { setState(() => _tab = 'explore'); ref.read(feedProvider.notifier).switchType('explore'); }),
                  ]),
                ),
                const SizedBox(width: 36), // 균형
              ]),
            ),
          ),

          // 진행 핍
          feedAsync.maybeWhen(
            data: (reels) => SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 48),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(reels.length.clamp(0, 8), (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: i == _current ? 16 : 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: i == _current ? Colors.white : Colors.white.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    )),
                  ),
                ),
              ),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _TabBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _TabBtn({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(
            fontSize: 15, fontWeight: active ? FontWeight.w800 : FontWeight.w600,
            color: active ? Colors.white : Colors.white.withOpacity(0.6),
            shadows: [const Shadow(blurRadius: 4, color: Colors.black45)],
          )),
          if (active) Container(
            margin: const EdgeInsets.only(top: 4),
            width: 22, height: 3,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.accent, AppColors.primary]),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
