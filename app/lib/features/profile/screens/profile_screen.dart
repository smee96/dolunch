import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/profile_provider.dart';
import '../../feed/providers/feed_provider.dart';
import '../../../core/models/models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format.dart';

class ProfileScreen extends ConsumerWidget {
  final String? userId;
  const ProfileScreen({super.key, this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = userId != null
        ? ref.watch(userProfileProvider(userId!))
        : ref.watch(myProfileProvider);

    return profileAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary))),
      error: (e, _) => Scaffold(body: Center(child: Text('오류: $e'))),
      data: (profile) => _ProfileBody(profile: profile, isMe: userId == null),
    );
  }
}

class _ProfileBody extends ConsumerStatefulWidget {
  final UserProfile profile;
  final bool isMe;
  const _ProfileBody({required this.profile, required this.isMe});

  @override
  ConsumerState<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends ConsumerState<_ProfileBody> with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;

    return Scaffold(
      backgroundColor: Colors.white,
      body: NestedScrollView(
        headerSliverBuilder: (_, inner) => [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: Colors.white,
            leading: widget.isMe
                ? null
                : IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => context.pop()),
            actions: widget.isMe ? [
              IconButton(icon: const Icon(Icons.settings_outlined, size: 22), onPressed: () {}),
            ] : [],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(fit: StackFit.expand, children: [
                Container(decoration: const BoxDecoration(gradient: AppColors.profileCoverGradient)),
                Positioned(bottom: 0, left: 0, right: 0,
                  child: Container(height: 60, decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.white.withOpacity(0.8)]),
                  ))),
              ]),
            ),
          ),

          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // 아바타 + 팔로우
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                _AvatarRing(url: p.avatarUrl, name: p.name),
                const Spacer(),
                if (!widget.isMe)
                  _FollowButton(userId: p.id)
                else
                  _EditButton(),
              ]),
              const SizedBox(height: 12),

              // 이름/handle
              Text(p.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink)),
              const SizedBox(height: 2),
              Text('@${p.handle}', style: const TextStyle(fontSize: 13, color: AppColors.sub)),

              if (p.bio.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(p.bio, style: const TextStyle(fontSize: 14, color: AppColors.sub, height: 1.6)),
              ],

              const SizedBox(height: 16),
              Row(children: [
                _StatItem(value: p.followerCount.toString(), label: '팔로워'),
                const SizedBox(width: 24),
                _StatItem(value: p.hostingCount.toString(), label: '호스팅'),
                const SizedBox(width: 24),
                _StatItem(value: p.rating.toStringAsFixed(1), label: '평점'),
              ]),
              const SizedBox(height: 16),
            ]),
          )),

          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabs,
                labelColor: AppColors.ink,
                unselectedLabelColor: AppColors.sub,
                labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                indicatorColor: AppColors.primary,
                indicatorWeight: 2.5,
                tabs: const [Tab(text: '숏츠'), Tab(text: '모임')],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabs,
          children: [
            _ReelsGrid(hostId: p.id),
            _RoomsList(hostId: p.id),
          ],
        ),
      ),
    );
  }
}

class _AvatarRing extends StatelessWidget {
  final String? url;
  final String name;
  const _AvatarRing({this.url, required this.name});

  @override
  Widget build(BuildContext context) => Container(
    width: 78, height: 78,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: AppColors.glamGradient,
      border: Border.all(color: Colors.white, width: 3),
    ),
    child: Padding(
      padding: const EdgeInsets.all(2),
      child: url != null
          ? ClipOval(child: Image.network(url!, fit: BoxFit.cover))
          : Center(child: Text(
              name.isNotEmpty ? name[0] : '?',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 28),
            )),
    ),
  );
}

class _FollowButton extends ConsumerWidget {
  final String userId;
  const _FollowButton({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFollowing = ref.watch(followProvider((userId, false)));
    final notifier = ref.read(followProvider((userId, false)).notifier);

    return GestureDetector(
      onTap: notifier.toggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: isFollowing ? null : AppColors.glamGradient,
          color: isFollowing ? AppColors.line : null,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(isFollowing ? '팔로잉' : '팔로우',
          style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w800,
            color: isFollowing ? AppColors.sub : Colors.white,
          )),
      ),
    );
  }
}

class _EditButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () {},
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.line,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text('프로필 편집',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
    ),
  );
}

class _StatItem extends StatelessWidget {
  final String value, label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink)),
    Text(label, style: const TextStyle(fontSize: 12, color: AppColors.sub)),
  ]);
}

// ─── 숏츠 그리드 ──────────────────────────────────────────────────────────────
class _ReelsGrid extends ConsumerWidget {
  final String hostId;
  const _ReelsGrid({required this.hostId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reelsAsync = ref.watch(_hostReelsProvider(hostId));
    return reelsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(child: Text('오류: $e')),
      data: (reels) {
        if (reels.isEmpty) {
          return const Center(child: Text('아직 숏츠가 없어요', style: TextStyle(color: AppColors.sub)));
        }
        return GridView.builder(
          padding: const EdgeInsets.all(2),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, crossAxisSpacing: 2, mainAxisSpacing: 2, childAspectRatio: 9 / 16,
          ),
          itemCount: reels.length,
          itemBuilder: (_, i) => _ReelThumb(reel: reels[i]),
        );
      },
    );
  }
}

class _ReelThumb extends StatelessWidget {
  final Reel reel;
  const _ReelThumb({required this.reel});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () {},
    child: Stack(fit: StackFit.expand, children: [
      reel.thumbUrl != null
          ? Image.network(reel.thumbUrl!, fit: BoxFit.cover)
          : Container(decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.accent.withOpacity(0.6), AppColors.deep.withOpacity(0.9)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
            )),
      Positioned(bottom: 6, left: 6, child: Row(children: [
        const Icon(Icons.favorite, size: 12, color: Colors.white),
        const SizedBox(width: 3),
        Text('${reel.likeCount}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
      ])),
    ]),
  );
}

final _hostReelsProvider = FutureProvider.family<List<Reel>, String>((ref, hostId) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get<Map<String, dynamic>>('/api/reels/feed', queryParameters: {'host_id': hostId});
  return (res.data!['reels'] as List).map((e) => Reel.fromJson(e as Map<String, dynamic>)).toList();
});

// ─── 모임 목록 ────────────────────────────────────────────────────────────────
class _RoomsList extends ConsumerWidget {
  final String hostId;
  const _RoomsList({required this.hostId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(_hostRoomsProvider(hostId));
    return roomsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(child: Text('오류: $e')),
      data: (rooms) {
        if (rooms.isEmpty) {
          return const Center(child: Text('아직 모임이 없어요', style: TextStyle(color: AppColors.sub)));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: rooms.length,
          separatorBuilder: (_, i) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _RoomRow(room: rooms[i]),
        );
      },
    );
  }
}

class _RoomRow extends StatelessWidget {
  final Room room;
  const _RoomRow({required this.room});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => context.push('/rooms/${room.id}'),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.base, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(room.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink),
            maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(kstDate(room.meetAt), style: const TextStyle(fontSize: 12, color: AppColors.sub)),
        ]),
        const Spacer(),
        _RoomStatusDot(status: room.status),
      ]),
    ),
  );
}

class _RoomStatusDot extends StatelessWidget {
  final String status;
  const _RoomStatusDot({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'open' => ('모집중', AppColors.primary),
      'full' => ('정원마감', AppColors.accent),
      'done' => ('완료', AppColors.sub),
      _ => ('취소', AppColors.danger),
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

final _hostRoomsProvider = FutureProvider.family<List<Room>, String>((ref, hostId) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get<Map<String, dynamic>>('/api/rooms', queryParameters: {'host_id': hostId});
  return (res.data!['rooms'] as List).map((e) => Room.fromJson(e as Map<String, dynamic>)).toList();
});

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext ctx, double shrink, bool overlap) => Container(color: Colors.white, child: tabBar);

  @override
  bool shouldRebuild(covariant _TabBarDelegate old) => old.tabBar != tabBar;
}
