import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/room_provider.dart';
import '../../../core/models/models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format.dart';
import '../../feed/providers/feed_provider.dart';

class RoomApplicantsScreen extends ConsumerWidget {
  final String roomId;
  const RoomApplicantsScreen({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicantsAsync = ref.watch(applicantsProvider(roomId));
    final roomAsync = ref.watch(roomDetailProvider(roomId));
    final roomIsDone = roomAsync.valueOrNull?.status == 'done';

    return Scaffold(
      backgroundColor: AppColors.base,
      appBar: AppBar(
        title: Text(
          roomIsDone ? '출석 확인' : '지원자',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink),
        ),
        backgroundColor: AppColors.base,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => context.pop()),
      ),
      body: applicantsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Text('아직 지원자가 없어요', style: TextStyle(color: AppColors.sub, fontSize: 15)),
            );
          }
          final pending = list.where((a) => a.status == 'pending').toList();
          final accepted = list.where((a) => a.status == 'accepted').toList();
          final rejected = list.where((a) => a.status == 'rejected').toList();

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(applicantsProvider(roomId));
              ref.invalidate(roomDetailProvider(roomId));
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: [
                if (roomIsDone && accepted.isNotEmpty) ...[
                  const _AttendanceBanner(),
                  const SizedBox(height: 8),
                ],
                if (pending.isNotEmpty) ...[
                  _SectionHeader(label: '대기중', count: pending.length, color: AppColors.accent),
                  ...pending.map((a) => _ApplicantCard(applicant: a, roomId: roomId, roomIsDone: false)),
                ],
                if (accepted.isNotEmpty) ...[
                  _SectionHeader(label: '수락됨', count: accepted.length, color: AppColors.success),
                  ...accepted.map((a) => _ApplicantCard(applicant: a, roomId: roomId, roomIsDone: roomIsDone)),
                ],
                if (rejected.isNotEmpty) ...[
                  _SectionHeader(label: '거절됨', count: rejected.length, color: AppColors.sub),
                  ...rejected.map((a) => _ApplicantCard(applicant: a, roomId: roomId, roomIsDone: false)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AttendanceBanner extends StatelessWidget {
  const _AttendanceBanner();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: AppColors.primary.withOpacity(0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.primary.withOpacity(0.25)),
    ),
    child: const Row(children: [
      Icon(Icons.info_outline, size: 16, color: AppColors.primary),
      SizedBox(width: 8),
      Expanded(child: Text(
        '모임이 종료됐어요. 출석 여부를 확인해 주세요.\n출석 시 보증금 환불, 노쇼 시 보증금 차감됩니다.',
        style: TextStyle(fontSize: 12, color: AppColors.primary, height: 1.5),
      )),
    ]),
  );
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _SectionHeader({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
    child: Row(children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
      const SizedBox(width: 8),
      Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink)),
      const SizedBox(width: 6),
      Text('$count명', style: const TextStyle(fontSize: 13, color: AppColors.sub)),
    ]),
  );
}

class _ApplicantCard extends ConsumerWidget {
  final Applicant applicant;
  final String roomId;
  final bool roomIsDone;
  const _ApplicantCard({required this.applicant, required this.roomId, required this.roomIsDone});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPending = applicant.status == 'pending';
    final isAccepted = applicant.status == 'accepted';
    final attendanceRecorded = applicant.attended != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _Avatar(url: applicant.avatar, name: applicant.name),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(applicant.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink)),
            const SizedBox(height: 2),
            Text('@${applicant.handle}', style: const TextStyle(fontSize: 12, color: AppColors.sub)),
          ])),
          if (roomIsDone && isAccepted && attendanceRecorded)
            _AttendanceBadge(attended: applicant.attended!)
          else
            _StatusBadge(status: applicant.status),
        ]),

        const SizedBox(height: 12),
        Row(children: [
          _MetaChip(Icons.star, '${applicant.rating.toStringAsFixed(1)}점'),
          const SizedBox(width: 8),
          _MetaChip(Icons.restaurant, '호스팅 ${applicant.hostingCount}회'),
          const SizedBox(width: 8),
          _MetaChip(Icons.account_balance_wallet_outlined, wonStr(applicant.depositAmount)),
        ]),

        if (isPending) ...[
          const Divider(height: 20, color: AppColors.line),
          Row(children: [
            Expanded(child: _OutlineBtn(
              label: '거절',
              color: AppColors.danger,
              onTap: () => _decide(context, ref, 'reject'),
            )),
            const SizedBox(width: 10),
            Expanded(child: _FilledBtn(
              label: '수락',
              onTap: () => _decide(context, ref, 'accept'),
            )),
          ]),
        ] else if (roomIsDone && isAccepted && !attendanceRecorded) ...[
          const Divider(height: 20, color: AppColors.line),
          Row(children: [
            Expanded(child: _OutlineBtn(
              label: '노쇼',
              color: AppColors.danger,
              onTap: () => _markAttendance(context, ref, 0),
            )),
            const SizedBox(width: 10),
            Expanded(child: _FilledBtn(
              label: '출석',
              onTap: () => _markAttendance(context, ref, 1),
            )),
          ]),
        ],
      ]),
    );
  }

  Future<void> _decide(BuildContext context, WidgetRef ref, String action) async {
    final dio = ref.read(dioProvider);
    try {
      await dio.patch('/api/applications/${applicant.id}/decide', data: {'action': action});
      ref.invalidate(applicantsProvider(roomId));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _markAttendance(BuildContext context, WidgetRef ref, int attended) async {
    final dio = ref.read(dioProvider);
    try {
      await dio.patch('/api/applications/${applicant.id}/attendance', data: {'attended': attended});
      ref.invalidate(applicantsProvider(roomId));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }
}

class _AttendanceBadge extends StatelessWidget {
  final int attended;
  const _AttendanceBadge({required this.attended});

  @override
  Widget build(BuildContext context) {
    final (label, color) = attended == 1
        ? ('출석', AppColors.success)
        : ('노쇼', AppColors.danger);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? url;
  final String name;
  const _Avatar({this.url, required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.glamGradient,
      ),
      child: url != null
          ? ClipOval(child: Image.network(url!, fit: BoxFit.cover))
          : Center(child: Text(
              name.isNotEmpty ? name[0] : '?',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
            )),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'pending' => ('대기', AppColors.accent),
      'accepted' => ('수락', AppColors.success),
      'rejected' => ('거절', AppColors.sub),
      _ => ('취소', AppColors.danger),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 13, color: AppColors.sub),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(fontSize: 12, color: AppColors.sub, fontWeight: FontWeight.w600)),
  ]);
}

class _OutlineBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _OutlineBtn({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Center(child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color))),
    ),
  );
}

class _FilledBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _FilledBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: AppColors.glamGradient,
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Center(child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white))),
    ),
  );
}
