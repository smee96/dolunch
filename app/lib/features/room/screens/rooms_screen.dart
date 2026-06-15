import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/room_provider.dart';
import '../widgets/room_card.dart';
import '../../../core/theme/app_theme.dart';

class RoomsScreen extends ConsumerStatefulWidget {
  const RoomsScreen({super.key});

  @override
  ConsumerState<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends ConsumerState<RoomsScreen> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final roomsAsync = ref.watch(myRoomsProvider);

    return Scaffold(
      backgroundColor: AppColors.base,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 96,
            backgroundColor: AppColors.base,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              title: const Text('내 모임', style: TextStyle(
                color: AppColors.ink, fontSize: 22, fontWeight: FontWeight.w800,
              )),
            ),
          ),

          // 요약 카드
          roomsAsync.maybeWhen(
            data: (rooms) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(children: [
                  _SummaryCard(label: '진행중', value: rooms.where((r) => r.status == 'open').length.toString()),
                  const SizedBox(width: 10),
                  _SummaryCard(label: '누적 호스팅', value: rooms.length.toString()),
                ]),
              ),
            ),
            orElse: () => const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ),

          // 필터 칩
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                for (final (key, label) in [('all', '전체'), ('open', '모집중'), ('done', '지난 모임')])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _filter = key),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _filter == key ? AppColors.ink : Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: _filter == key ? AppColors.ink : AppColors.line),
                        ),
                        child: Text(label, style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700,
                          color: _filter == key ? Colors.white : AppColors.ink,
                        )),
                      ),
                    ),
                  ),
              ]),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // 방 목록
          roomsAsync.when(
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppColors.primary))),
            error: (e, _) => SliverFillRemaining(child: Center(child: Text('오류: $e'))),
            data: (rooms) {
              final filtered = _filter == 'all' ? rooms
                  : rooms.where((r) => r.status == _filter).toList();
              if (filtered.isEmpty) {
                return SliverFillRemaining(child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text('아직 모임이 없어요', style: TextStyle(color: AppColors.sub, fontSize: 15)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.push('/rooms/create'),
                      child: const Text('첫 모임 만들기'),
                    ),
                  ]),
                ));
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                sliver: SliverList(delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: RoomCard(room: filtered[i], onTap: () => context.push('/rooms/${filtered[i].id}')),
                  ),
                  childCount: filtered.length,
                )),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label, value;
  const _SummaryCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 24, offset: const Offset(0, 8))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.sub)),
        ]),
      ),
    );
  }
}
