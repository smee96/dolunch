import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/models.dart';
import '../../../core/utils/format.dart';
import '../../feed/providers/feed_provider.dart';

// ─── 모델 ─────────────────────────────────────────────────────────────────────
class SearchResult {
  final List<Room> rooms;
  final List<UserProfile> hosts;
  const SearchResult({required this.rooms, required this.hosts});
}

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultProvider = FutureProvider.family<SearchResult, String>((ref, q) async {
  if (q.trim().isEmpty) return const SearchResult(rooms: [], hosts: []);
  final dio = ref.read(dioProvider);
  final res = await dio.get<Map<String, dynamic>>('/api/search', queryParameters: {'q': q});
  final rooms = (res.data!['rooms'] as List).map((e) => Room.fromJson(e as Map<String, dynamic>)).toList();
  final hosts = (res.data!['hosts'] as List).map((e) => UserProfile.fromJson(e as Map<String, dynamic>)).toList();
  return SearchResult(rooms: rooms, hosts: hosts);
});

// ─── 화면 ─────────────────────────────────────────────────────────────────────
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> with SingleTickerProviderStateMixin {
  final _ctrl = TextEditingController();
  late final TabController _tabs;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _tabs.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    setState(() => _query = v.trim());
  }

  @override
  Widget build(BuildContext context) {
    final resultAsync = ref.watch(searchResultProvider(_query));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: AppColors.ink),
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          onChanged: _onChanged,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink),
          decoration: InputDecoration(
            hintText: '모임, 호스트 검색',
            hintStyle: const TextStyle(color: AppColors.sub, fontSize: 15),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 14),
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, color: AppColors.sub, size: 18),
                    onPressed: () { _ctrl.clear(); setState(() => _query = ''); },
                  )
                : null,
          ),
        ),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.ink,
          unselectedLabelColor: AppColors.sub,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          indicatorColor: AppColors.primary,
          indicatorWeight: 2.5,
          tabs: const [Tab(text: '모임'), Tab(text: '호스트')],
        ),
      ),
      body: _query.isEmpty
          ? const _EmptyHint()
          : resultAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (e, _) => Center(child: Text('오류: $e')),
              data: (result) => TabBarView(
                controller: _tabs,
                children: [
                  _RoomResults(rooms: result.rooms, query: _query),
                  _HostResults(hosts: result.hosts, query: _query),
                ],
              ),
            ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.search, size: 60, color: AppColors.line),
      const SizedBox(height: 16),
      const Text('모임 이름, 메뉴, 호스트를 검색해 보세요',
          style: TextStyle(fontSize: 14, color: AppColors.sub)),
    ]),
  );
}

// ─── 모임 결과 ────────────────────────────────────────────────────────────────
class _RoomResults extends StatelessWidget {
  final List<Room> rooms;
  final String query;
  const _RoomResults({required this.rooms, required this.query});

  @override
  Widget build(BuildContext context) {
    if (rooms.isEmpty) {
      return Center(
        child: Text('"$query"에 해당하는 모임이 없어요',
            style: const TextStyle(color: AppColors.sub)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: rooms.length,
      separatorBuilder: (_, i) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _RoomCard(room: rooms[i]),
    );
  }
}

class _RoomCard extends StatelessWidget {
  final Room room;
  const _RoomCard({required this.room});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => context.push('/rooms/${room.id}'),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        // 색상 썸네일
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            gradient: AppColors.glamGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.restaurant, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(room.title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.location_on_outlined, size: 12, color: AppColors.sub),
            const SizedBox(width: 3),
            Text(room.placeName, style: const TextStyle(fontSize: 12, color: AppColors.sub)),
            const SizedBox(width: 10),
            const Icon(Icons.access_time, size: 12, color: AppColors.sub),
            const SizedBox(width: 3),
            Text(kstDate(room.meetAt), style: const TextStyle(fontSize: 12, color: AppColors.sub)),
          ]),
          const SizedBox(height: 4),
          Text(wonStr(room.pricePerPerson),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
        ])),
        _StatusDot(status: room.status),
      ]),
    ),
  );
}

class _StatusDot extends StatelessWidget {
  final String status;
  const _StatusDot({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'open' => ('모집중', AppColors.primary),
      'full' => ('마감', AppColors.accent),
      _ => ('종료', AppColors.sub),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

// ─── 호스트 결과 ──────────────────────────────────────────────────────────────
class _HostResults extends StatelessWidget {
  final List<UserProfile> hosts;
  final String query;
  const _HostResults({required this.hosts, required this.query});

  @override
  Widget build(BuildContext context) {
    if (hosts.isEmpty) {
      return Center(
        child: Text('"$query"에 해당하는 호스트가 없어요',
            style: const TextStyle(color: AppColors.sub)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: hosts.length,
      separatorBuilder: (_, i) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _HostCard(host: hosts[i]),
    );
  }
}

class _HostCard extends StatelessWidget {
  final UserProfile host;
  const _HostCard({required this.host});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => context.push('/profile/${host.id}'),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        _Avatar(url: host.avatarUrl, name: host.name),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(host.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink)),
          const SizedBox(height: 2),
          Text('@${host.handle}', style: const TextStyle(fontSize: 12, color: AppColors.sub)),
          if (host.bio.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(host.bio,
                style: const TextStyle(fontSize: 12, color: AppColors.sub),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ])),
        Column(children: [
          Text('${host.followerCount}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink)),
          const Text('팔로워', style: TextStyle(fontSize: 11, color: AppColors.sub)),
        ]),
      ]),
    ),
  );
}

class _Avatar extends StatelessWidget {
  final String? url;
  final String name;
  const _Avatar({this.url, required this.name});

  @override
  Widget build(BuildContext context) => Container(
    width: 48, height: 48,
    decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.glamGradient),
    child: ClipOval(
      child: url != null
          ? Image.network(url!, fit: BoxFit.cover)
          : Center(child: Text(
              name.isNotEmpty ? name[0] : '?',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20),
            )),
    ),
  );
}
