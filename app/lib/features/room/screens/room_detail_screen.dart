import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/room_provider.dart';
import '../widgets/glam_gradient.dart';
import '../../feed/providers/feed_provider.dart';
import '../../../core/models/models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/api.dart';
import '../../../core/utils/format.dart';

class RoomDetailScreen extends ConsumerWidget {
  final String roomId;
  const RoomDetailScreen({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomAsync = ref.watch(roomDetailProvider(roomId));
    return roomAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary))),
      error: (e, _) => Scaffold(body: Center(child: Text('오류: $e'))),
      data: (room) => _DetailBody(room: room),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  final Room room;
  const _DetailBody({required this.room});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deposit = ApiConstants.calcDeposit(room.pricePerPerson);

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(fit: StackFit.expand, children: [
                SoftGradient(seed: room.id.hashCode),
                Container(decoration: BoxDecoration(gradient: LinearGradient(
                  begin: Alignment.bottomCenter, end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.45), Colors.transparent],
                ))),
                Positioned(bottom: 16, left: 20, right: 20, child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _StatusPill(status: room.status),
                    const SizedBox(height: 8),
                    Text(room.title, style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5,
                    )),
                  ],
                )),
              ]),
            ),
          ),

          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _InfoSection(room: room),
              const SizedBox(height: 24),
              _PriceCard(room: room, deposit: deposit),
              const SizedBox(height: 24),
              if (room.description.isNotEmpty) ...[
                const Text('모임 소개', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink)),
                const SizedBox(height: 10),
                Text(room.description, style: const TextStyle(fontSize: 14, color: AppColors.sub, height: 1.7)),
                const SizedBox(height: 24),
              ],
              _ApplicantsRow(roomId: room.id, count: room.joinedCount),
              const SizedBox(height: 120),
            ]),
          )),
        ],
      ),

      bottomNavigationBar: _ActionBar(room: room, deposit: deposit),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, bg) = switch (status) {
      'open' => ('모집중', AppColors.primary),
      'full' => ('정원마감', AppColors.sub),
      'done' => ('완료', AppColors.ink),
      _ => ('취소됨', AppColors.danger),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg.withOpacity(0.88), borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final Room room;
  const _InfoSection({required this.room});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.base, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.line),
    ),
    child: Column(children: [
      _InfoRow(Icons.location_on_outlined, '장소', room.placeName),
      const Divider(height: 20, color: AppColors.line),
      _InfoRow(Icons.restaurant_menu_outlined, '메뉴', room.menu),
      const Divider(height: 20, color: AppColors.line),
      _InfoRow(Icons.access_time, '일시', kstDateTime(room.meetAt)),
      const Divider(height: 20, color: AppColors.line),
      _InfoRow(Icons.people_outline, '인원', '${room.joinedCount} / ${room.capacity}명'),
    ]),
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 18, color: AppColors.primary),
    const SizedBox(width: 12),
    Text(label, style: const TextStyle(fontSize: 13, color: AppColors.sub, fontWeight: FontWeight.w600)),
    const SizedBox(width: 8),
    Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: AppColors.ink, fontWeight: FontWeight.w700),
      textAlign: TextAlign.right, maxLines: 1, overflow: TextOverflow.ellipsis)),
  ]);
}

class _PriceCard extends StatelessWidget {
  final Room room;
  final int deposit;
  const _PriceCard({required this.room, required this.deposit});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [Color(0xFFFFF6F0), Color(0xFFFFF0F5)]),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.line),
    ),
    child: Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('1인 금액', style: TextStyle(fontSize: 14, color: AppColors.sub)),
        Text(wonStr(room.pricePerPerson),
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink)),
      ]),
      const Divider(height: 20, color: AppColors.line),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('지원 시 보증금 (20%)', style: TextStyle(fontSize: 13, color: AppColors.sub)),
        Text(wonStr(deposit),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primary)),
      ]),
      const SizedBox(height: 6),
      const Align(
        alignment: Alignment.centerLeft,
        child: Text('정상 참석 시 전액 환불', style: TextStyle(fontSize: 12, color: AppColors.sub)),
      ),
    ]),
  );
}

class _ApplicantsRow extends StatelessWidget {
  final String roomId;
  final int count;
  const _ApplicantsRow({required this.roomId, required this.count});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => context.push('/rooms/$roomId/applicants'),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        const Icon(Icons.people_alt_outlined, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Text('지원자 $count명 보기', style: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink,
        )),
        const Spacer(),
        const Icon(Icons.chevron_right, color: AppColors.sub, size: 20),
      ]),
    ),
  );
}

class _ActionBar extends ConsumerWidget {
  final Room room;
  final int deposit;
  const _ActionBar({required this.room, required this.deposit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOpen = room.status == 'open';
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.line.withOpacity(0.6))),
      ),
      child: isOpen
          ? SizedBox(
              height: 54,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppColors.glamGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(
                    color: AppColors.primary.withOpacity(0.5),
                    blurRadius: 20, offset: const Offset(0, 8),
                  )],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => _showDepositSheet(context),
                  child: Text('보증금 ${wonStr(deposit)} 결제하고 지원하기',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ),
            )
          : SizedBox(
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.line,
                  foregroundColor: AppColors.sub,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: null,
                child: Text(
                  switch (room.status) {
                    'full' => '정원 마감',
                    'done' => '종료된 모임',
                    _ => '모집 취소됨',
                  },
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
    );
  }

  void _showDepositSheet(BuildContext context) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DepositSheet(room: room, deposit: deposit),
    );
  }
}

class _DepositSheet extends ConsumerStatefulWidget {
  final Room room;
  final int deposit;
  const _DepositSheet({required this.room, required this.deposit});

  @override
  ConsumerState<_DepositSheet> createState() => _DepositSheetState();
}

class _DepositSheetState extends ConsumerState<_DepositSheet> {
  bool _loading = false;
  bool _done = false;
  String? _error;

  Future<void> _pay() async {
    setState(() { _loading = true; _error = null; });
    try {
      final dio = ref.read(dioProvider);
      final applyRes = await dio.post<Map<String, dynamic>>('/api/rooms/${widget.room.id}/apply');
      final applicationId = applyRes.data!['applicationId'] as String;
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
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: _done ? _DoneView(deposit: widget.deposit, onClose: () => Navigator.pop(context))
          : Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('지원 확인', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFFFF6F0), Color(0xFFFFF0F5)]),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('보증금', style: TextStyle(color: AppColors.sub, fontSize: 14)),
              Text(wonStr(widget.deposit), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary)),
            ]),
            const SizedBox(height: 8),
            const Text('참석 시 전액 환불 · 노쇼 시 차감',
              style: TextStyle(fontSize: 12, color: AppColors.sub)),
          ]),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13),
            textAlign: TextAlign.center),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity, height: 54,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppColors.glamGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.5), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _loading ? null : _pay,
              child: _loading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('보증금 결제하고 지원하기',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
          ),
        ),
      ]),
    );
  }
}

class _DoneView extends StatelessWidget {
  final int deposit;
  final VoidCallback onClose;
  const _DoneView({required this.deposit, required this.onClose});

  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
    Container(
      width: 64, height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(colors: [AppColors.accent, AppColors.primary]),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 16)],
      ),
      child: const Icon(Icons.check, color: Colors.white, size: 32),
    ),
    const SizedBox(height: 16),
    const Text('지원 완료!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink)),
    const SizedBox(height: 8),
    Text('보증금 ${wonStr(deposit)}이 예치됐어요\n호스트 수락 후 알림을 드립니다',
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 14, color: AppColors.sub, height: 1.6)),
    const SizedBox(height: 24),
    SizedBox(width: double.infinity, height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.ink,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: onClose,
        child: const Text('확인', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
      )),
  ]);
}
