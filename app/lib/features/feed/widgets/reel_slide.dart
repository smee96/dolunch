import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../core/models/models.dart';
import '../../../core/theme/app_theme.dart';
import '../../room/widgets/glam_gradient.dart';

class ReelSlide extends StatefulWidget {
  final Reel reel;
  final bool liked;
  final VoidCallback onLike;
  final VoidCallback onApply;

  const ReelSlide({
    super.key, required this.reel, required this.liked,
    required this.onLike, required this.onApply,
  });

  @override
  State<ReelSlide> createState() => _ReelSlideState();
}

class _ReelSlideState extends State<ReelSlide> {
  VideoPlayerController? _ctrl;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    _ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.reel.videoUrl))
      ..setLooping(true)
      ..setVolume(0);
    await _ctrl!.initialize();
    if (mounted) {
      setState(() => _initialized = true);
      _ctrl!.play();
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_ctrl == null) return;
        _ctrl!.value.isPlaying ? _ctrl!.pause() : _ctrl!.play();
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 배경 (영상 or 그라데이션 플레이스홀더)
          if (_initialized && _ctrl != null)
            FittedBox(fit: BoxFit.cover, child: SizedBox(
              width: _ctrl!.value.size.width, height: _ctrl!.value.size.height,
              child: VideoPlayer(_ctrl!),
            ))
          else
            GlamGradient(seed: widget.reel.id.hashCode),

          // 상/하단 스크림
          Container(decoration: const BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment(0, -0.3),
            colors: [Color(0x8C0A0407), Colors.transparent],
          ))),
          Container(decoration: const BoxDecoration(gradient: LinearGradient(
            begin: Alignment.bottomCenter, end: Alignment(0, -0.1),
            colors: [Color(0xD00A0407), Colors.transparent],
          ))),

          // HOST REEL 라벨
          const Positioned(top: 64, left: 20,
            child: Text('HOST REEL', style: TextStyle(
              fontFamily: 'monospace', fontSize: 11, letterSpacing: 3,
              color: Color(0xB3FFFFFF), fontWeight: FontWeight.w600,
            )),
          ),

          // 우측 레일
          Positioned(
            right: 14, bottom: 188,
            child: Column(children: [
              // 호스트 아바타
              Stack(children: [
                Container(width: 50, height: 50, decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: glamGradientForSeed(widget.reel.id.hashCode),
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 12)],
                )),
                Positioned(bottom: -4, left: 0, right: 0, child: Center(
                  child: Container(width: 20, height: 20, decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [AppColors.accent, AppColors.primary]),
                    border: Border.all(color: Colors.white, width: 2),
                  ), child: const Icon(Icons.add, size: 12, color: Colors.white)),
                )),
              ]),
              const SizedBox(height: 24),
              _RailBtn(
                icon: widget.liked ? Icons.favorite : Icons.favorite_border,
                label: _formatCount(widget.reel.likeCount + (widget.liked ? 1 : 0)),
                active: widget.liked, onTap: widget.onLike,
              ),
              const SizedBox(height: 20),
              _RailBtn(icon: Icons.chat_bubble_outline, label: _formatCount(widget.reel.commentCount)),
              const SizedBox(height: 20),
              _RailBtn(icon: Icons.share_outlined, label: '공유'),
            ]),
          ),

          // 하단 콘텐츠
          Positioned(
            left: 18, right: 84, bottom: 104,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(widget.reel.hostHandle, style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16,
                  shadows: [Shadow(blurRadius: 6, color: Colors.black54)],
                )),
                const SizedBox(width: 9),
                Text('팔로워 ${_formatCount(widget.reel.hostFollowers)}',
                  style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12)),
              ]),
              const SizedBox(height: 11),
              Text(widget.reel.caption, style: const TextStyle(
                color: Colors.white, fontSize: 14, height: 1.45,
                shadows: [Shadow(blurRadius: 6, color: Colors.black54)],
              )),
              if (widget.reel.roomId != null && widget.reel.roomStatus == 'open') ...[
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: widget.onApply,
                  child: Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withOpacity(0.22)),
                    ),
                    child: Row(children: [
                      Container(width: 42, height: 42, decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: glamGradientForSeed(widget.reel.id.hashCode + 2),
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(widget.reel.roomTitle ?? '', style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14,
                        ), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.reel.roomMeetAt ?? ''} · ${widget.reel.roomSpots ?? 0}자리 남음',
                          style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11.5),
                        ),
                      ])),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [AppColors.accent, AppColors.primary, AppColors.deep]),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.7), blurRadius: 18, offset: const Offset(0, 8))],
                        ),
                        child: const Text('지원하기', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13.5)),
                      ),
                    ]),
                  ),
                ),
              ],
            ]),
          ),
        ],
      ),
    );
  }
}

class _RailBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;
  const _RailBtn({required this.icon, required this.label, this.active = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: active ? const LinearGradient(colors: [AppColors.accent, AppColors.primary]) : null,
            color: active ? null : Colors.white.withOpacity(0.16),
            boxShadow: active ? [BoxShadow(color: AppColors.primary.withOpacity(0.8), blurRadius: 18, offset: const Offset(0, 8))] : null,
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(
          color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700,
          shadows: [Shadow(blurRadius: 4, color: Colors.black45)],
        )),
      ]),
    );
  }
}

String _formatCount(int n) {
  if (n >= 10000) return '${(n / 1000).toStringAsFixed(1)}k';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
  return n.toString();
}

LinearGradient glamGradientForSeed(int seed) {
  final grads = [
    [const Color(0xFFFF8A3D), const Color(0xFFF0457E), const Color(0xFF7C2A5B)],
    [const Color(0xFFF0457E), const Color(0xFF9B2F6B), const Color(0xFF3A1430)],
    [const Color(0xFFFFB23E), const Color(0xFFFF6B4A), const Color(0xFFC42E6E)],
    [const Color(0xFF6A2D7A), const Color(0xFFF0457E), const Color(0xFFFF8A3D)],
  ];
  final g = grads[seed.abs() % grads.length];
  return LinearGradient(colors: g, begin: Alignment.topLeft, end: Alignment.bottomRight);
}
