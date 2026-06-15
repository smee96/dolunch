import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../feed/providers/feed_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format.dart';

// My applications (as guest)
final myApplicationsProvider = FutureProvider<List<_MyApplication>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get<Map<String, dynamic>>('/api/applications/mine');
  return (res.data!['applications'] as List)
      .map((e) => _MyApplication.fromJson(e as Map<String, dynamic>))
      .toList();
});

class _MyApplication {
  final String id;
  final String roomId;
  final String roomTitle;
  final String placeName;
  final String meetAt;
  final String status;
  final int depositAmount;
  final bool depositPaid;

  const _MyApplication({
    required this.id, required this.roomId, required this.roomTitle,
    required this.placeName, required this.meetAt, required this.status,
    required this.depositAmount, required this.depositPaid,
  });

  factory _MyApplication.fromJson(Map<String, dynamic> j) => _MyApplication(
    id: j['id'] as String, roomId: j['room_id'] as String,
    roomTitle: j['room_title'] as String? ?? '모임',
    placeName: j['place_name'] as String? ?? '',
    meetAt: j['meet_at'] as String,
    status: j['status'] as String,
    depositAmount: j['deposit_amount'] as int? ?? 0,
    depositPaid: j['deposit_payment_key'] != null,
  );
}

class ApplicantsScreen extends ConsumerWidget {
  const ApplicantsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appsAsync = ref.watch(myApplicationsProvider);

    return Scaffold(
      backgroundColor: AppColors.base,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.base,
            expandedHeight: 80,
            flexibleSpace: const FlexibleSpaceBar(
              titlePadding: EdgeInsets.fromLTRB(20, 0, 20, 16),
              title: Text('내 지원 현황', style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink,
              )),
            ),
          ),

          appsAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            ),
            error: (e, _) => SliverFillRemaining(child: Center(child: Text('오류: $e'))),
            data: (apps) {
              if (apps.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.restaurant_outlined, size: 48, color: AppColors.line),
                      const SizedBox(height: 12),
                      const Text('아직 지원한 모임이 없어요', style: TextStyle(color: AppColors.sub, fontSize: 15)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context.go('/feed'),
                        child: const Text('모임 둘러보기'),
                      ),
                    ]),
                  ),
                );
              }

              final pending = apps.where((a) => a.status == 'pending').toList();
              final accepted = apps.where((a) => a.status == 'accepted').toList();
              final others = apps.where((a) => a.status != 'pending' && a.status != 'accepted').toList();

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                sliver: SliverList(delegate: SliverChildListDelegate([
                  if (pending.isNotEmpty) ...[
                    _SectionTitle('대기중', pending.length, AppColors.accent),
                    ...pending.map((a) => _ApplicationCard(app: a)),
                  ],
                  if (accepted.isNotEmpty) ...[
                    _SectionTitle('수락됨', accepted.length, AppColors.success),
                    ...accepted.map((a) => _ApplicationCard(app: a)),
                  ],
                  if (others.isNotEmpty) ...[
                    _SectionTitle('지난 지원', others.length, AppColors.sub),
                    ...others.map((a) => _ApplicationCard(app: a)),
                  ],
                ])),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _SectionTitle(this.label, this.count, this.color);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
    child: Row(children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
      const SizedBox(width: 8),
      Text('$label $count건', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink)),
    ]),
  );
}

class _ApplicationCard extends StatelessWidget {
  final _MyApplication app;
  const _ApplicationCard({required this.app});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/rooms/${app.roomId}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(app.roomTitle,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            )),
            _StatusBadge(status: app.status),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.location_on_outlined, size: 14, color: AppColors.sub),
            const SizedBox(width: 4),
            Expanded(child: Text(app.placeName,
              style: const TextStyle(fontSize: 12, color: AppColors.sub), maxLines: 1, overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.access_time, size: 14, color: AppColors.sub),
            const SizedBox(width: 4),
            Text(kstDateTime(app.meetAt), style: const TextStyle(fontSize: 12, color: AppColors.sub)),
          ]),
          const Divider(height: 16, color: AppColors.line),
          Row(children: [
            const Text('보증금', style: TextStyle(fontSize: 12, color: AppColors.sub)),
            const SizedBox(width: 8),
            Text(wonStr(app.depositAmount), style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary)),
            const Spacer(),
            if (app.depositPaid)
              const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.check_circle, size: 14, color: AppColors.success),
                SizedBox(width: 4),
                Text('결제완료', style: TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w700)),
              ]),
          ]),
        ]),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'pending' => ('대기중', AppColors.accent),
      'accepted' => ('수락', AppColors.success),
      'rejected' => ('거절', AppColors.danger),
      'cancelled' => ('취소', AppColors.sub),
      _ => ('기타', AppColors.sub),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}
