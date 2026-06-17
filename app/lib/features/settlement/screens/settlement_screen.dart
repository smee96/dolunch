import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format.dart';
import '../../feed/providers/feed_provider.dart';

// ─── 데이터 모델 ──────────────────────────────────────────────────────────────
class Settlement {
  final String id;
  final String roomId;
  final String roomTitle;
  final int totalAmount;
  final int hostAmount;
  final String status; // pending / requested / paid
  final String? receiptUrl;
  final DateTime? requestedAt;
  final DateTime? paidAt;

  const Settlement({
    required this.id,
    required this.roomId,
    required this.roomTitle,
    required this.totalAmount,
    required this.hostAmount,
    required this.status,
    this.receiptUrl,
    this.requestedAt,
    this.paidAt,
  });

  factory Settlement.fromJson(Map<String, dynamic> j) => Settlement(
    id: j['id'] as String,
    roomId: j['room_id'] as String,
    roomTitle: j['room_title'] as String? ?? '모임',
    totalAmount: j['total_amount'] as int,
    hostAmount: j['host_amount'] as int,
    status: j['status'] as String,
    receiptUrl: j['receipt_url'] as String?,
    requestedAt: j['requested_at'] != null
        ? DateTime.parse(j['requested_at'] as String).toLocal()
        : null,
    paidAt: j['paid_at'] != null
        ? DateTime.parse(j['paid_at'] as String).toLocal()
        : null,
  );
}

final settlementsProvider = FutureProvider<List<Settlement>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get<Map<String, dynamic>>('/api/settlements/mine');
  return (res.data!['settlements'] as List)
      .map((e) => Settlement.fromJson(e as Map<String, dynamic>))
      .toList();
});

// ─── 화면 ─────────────────────────────────────────────────────────────────────
class SettlementScreen extends ConsumerWidget {
  const SettlementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settlementsAsync = ref.watch(settlementsProvider);

    return Scaffold(
      backgroundColor: AppColors.base,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: AppColors.ink),
        title: const Text('정산 내역',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink)),
        centerTitle: true,
      ),
      body: settlementsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류가 발생했습니다: $e')),
        data: (settlements) {
          if (settlements.isEmpty) {
            return const Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.sub),
                SizedBox(height: 16),
                Text('정산 내역이 없습니다', style: TextStyle(fontSize: 16, color: AppColors.sub)),
              ]),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(settlementsProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: settlements.length,
              separatorBuilder: (_, _x) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _SettlementCard(settlement: settlements[i], ref: ref),
            ),
          );
        },
      ),
    );
  }
}

// ─── 정산 카드 ────────────────────────────────────────────────────────────────
class _SettlementCard extends StatelessWidget {
  final Settlement settlement;
  final WidgetRef ref;
  const _SettlementCard({required this.settlement, required this.ref});

  @override
  Widget build(BuildContext context) {
    final s = settlement;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(s.roomTitle,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          _StatusChip(status: s.status),
        ]),
        const SizedBox(height: 12),
        _Row('총 매출', wonStr(s.totalAmount)),
        const SizedBox(height: 4),
        _Row('정산 예정액', wonStr(s.hostAmount),
            valueStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primary)),
        if (s.requestedAt != null) ...[
          const SizedBox(height: 4),
          _Row('요청일', kstDate(s.requestedAt!.toIso8601String())),
        ],
        if (s.paidAt != null) ...[
          const SizedBox(height: 4),
          _Row('지급일', kstDate(s.paidAt!.toIso8601String())),
        ],
        if (s.status == 'pending') ...[
          const SizedBox(height: 16),
          _RequestBtn(settlement: s, ref: ref),
        ],
      ]),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;
  const _Row(this.label, this.value, {this.valueStyle});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(fontSize: 13, color: AppColors.sub)),
      Text(value, style: valueStyle ?? const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
    ],
  );
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      'pending' => ('정산 대기', const Color(0xFFFFF3E0), const Color(0xFFE65100)),
      'requested' => ('검토 중', const Color(0xFFE3F2FD), AppColors.primary),
      'paid' => ('지급 완료', const Color(0xFFE8F5E9), const Color(0xFF2E7D32)),
      _ => (status, AppColors.base, AppColors.sub),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

// ─── 정산 요청 버튼 (영수증 업로드 → API 요청) ──────────────────────────────
class _RequestBtn extends ConsumerStatefulWidget {
  final Settlement settlement;
  final WidgetRef ref;
  const _RequestBtn({required this.settlement, required this.ref});

  @override
  ConsumerState<_RequestBtn> createState() => _RequestBtnState();
}

class _RequestBtnState extends ConsumerState<_RequestBtn> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity, height: 48,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        onPressed: _loading ? null : _request,
        icon: _loading
            ? const SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.upload_outlined, size: 18),
        label: Text(_loading ? '요청 중...' : '정산 요청하기',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Future<void> _request() async {
    setState(() => _loading = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post<void>('/api/settlements/${widget.settlement.id}/request');
      ref.invalidate(settlementsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('정산 요청이 완료되었습니다'), backgroundColor: AppColors.primary),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('요청 실패: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
