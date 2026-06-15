import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format.dart';
import '../../feed/providers/feed_provider.dart';

class DepositSheet extends ConsumerStatefulWidget {
  final Reel reel;
  const DepositSheet({super.key, required this.reel});

  @override
  ConsumerState<DepositSheet> createState() => _DepositSheetState();
}

class _DepositSheetState extends ConsumerState<DepositSheet> {
  bool _done = false;
  bool _loading = false;
  String? _error;

  Future<void> _pay() async {
    setState(() { _loading = true; _error = null; });
    try {
      final dio = ref.read(dioProvider);

      // 1. 지원 생성
      final applyRes = await dio.post<Map<String, dynamic>>(
        '/api/rooms/${widget.reel.roomId}/apply',
      );
      final applicationId = applyRes.data!['applicationId'] as String;

      // 2. 목 결제 확인 (PG 연동 전)
      await dio.post('/api/applications/$applicationId/deposit/mock');

      if (mounted) setState(() { _loading = false; _done = true; });
    } catch (e) {
      final msg = e.toString().contains('Already applied')
          ? '이미 지원한 모임이에요'
          : e.toString().contains('full')
              ? '정원이 마감됐어요'
              : '오류가 발생했어요. 다시 시도해 주세요.';
      if (mounted) setState(() { _loading = false; _error = msg; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 24),
      child: _done
          ? _SuccessView(reel: widget.reel, onClose: () => Navigator.pop(context))
          : _ApplyView(reel: widget.reel, loading: _loading, error: _error, onPay: _pay),
    );
  }
}

class _ApplyView extends StatelessWidget {
  final Reel reel;
  final bool loading;
  final String? error;
  final VoidCallback onPay;
  const _ApplyView({required this.reel, required this.loading, this.error, required this.onPay});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
      const Text('GUEST PREVIEW · 지원', style: TextStyle(
        fontFamily: 'monospace', fontSize: 11, letterSpacing: 2,
        color: AppColors.sub, fontWeight: FontWeight.w600,
      )),
      const SizedBox(height: 8),
      Text(reel.roomTitle ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink)),
      const SizedBox(height: 4),
      Text(reel.roomMeetAt != null ? kstDateTime(reel.roomMeetAt!) : '',
        style: const TextStyle(fontSize: 13, color: AppColors.sub)),
      const SizedBox(height: 20),

      // 보증금 히어로
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFFFF1E8), Color(0xFFFCE3EC)]),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(children: [
          const Text('걸어둘 보증금', style: TextStyle(fontSize: 13, color: AppColors.sub, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(wonStr(reel.depositAmount ?? 0), style: const TextStyle(
            fontSize: 34, fontWeight: FontWeight.w800, color: AppColors.primary,
          )),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('참석하면 전액 환불', style: TextStyle(
              color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 13,
            )),
          ),
        ]),
      ),
      const SizedBox(height: 16),

      // 결제 수단 (표시용)
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(13),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(6)),
            child: const Text('PG', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 10),
          const Expanded(child: Text('카카오페이 · 신한카드', style: TextStyle(fontSize: 14, color: AppColors.ink))),
          const Text('변경 예정', style: TextStyle(fontSize: 12, color: AppColors.sub)),
        ]),
      ),

      if (error != null) ...[
        const SizedBox(height: 10),
        Text(error!, style: const TextStyle(color: AppColors.danger, fontSize: 13, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center),
      ],

      const SizedBox(height: 12),
      const Text('보증금은 안전하게 예치됩니다.\n참석 확인 후 전액 환불됩니다.', textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, color: AppColors.sub, height: 1.5)),
      const SizedBox(height: 20),

      // CTA
      SizedBox(width: double.infinity, height: 56,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.accent, AppColors.primary, AppColors.deep]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.7), blurRadius: 26, offset: const Offset(0, 12))],
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            onPressed: loading ? null : onPay,
            child: loading
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('보증금 걸고 지원하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
        ),
      ),
    ]);
  }
}

class _SuccessView extends StatelessWidget {
  final Reel reel;
  final VoidCallback onClose;
  const _SuccessView({required this.reel, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
      Container(
        width: 72, height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(colors: [AppColors.accent, AppColors.primary]),
          boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.5), blurRadius: 20)],
        ),
        child: const Icon(Icons.check, color: Colors.white, size: 36),
      ),
      const SizedBox(height: 20),
      const Text('지원 완료!', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.ink)),
      const SizedBox(height: 12),
      Text(
        '보증금 ${wonStr(reel.depositAmount ?? 0)}이 예치됐어요\n호스트가 수락하면 알림을 보내드립니다',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 14, color: AppColors.sub, height: 1.6),
      ),
      const SizedBox(height: 28),
      SizedBox(width: double.infinity, height: 52,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.ink,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: onClose,
          child: const Text('확인', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
        ),
      ),
    ]);
  }
}
