import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/models/models.dart';
import '../../../core/network/dio_client.dart';

final dioProvider = Provider<Dio>((ref) => buildDio(ref));

final feedProvider = AsyncNotifierProvider<FeedNotifier, List<Reel>>(FeedNotifier.new);

class FeedNotifier extends AsyncNotifier<List<Reel>> {
  int _offset = 0;
  bool _hasMore = true;
  String _type = 'explore';

  @override
  Future<List<Reel>> build() async {
    _offset = 0;
    _hasMore = true;
    return _fetch();
  }

  Future<List<Reel>> _fetch() async {
    final dio = ref.read(dioProvider);
    final res = await dio.get<Map<String, dynamic>>(
      '/api/reels/feed',
      queryParameters: {'type': _type, 'limit': 10, 'offset': _offset},
    );
    final list = (res.data!['reels'] as List)
        .map((e) => Reel.fromJson(e as Map<String, dynamic>))
        .toList();
    _offset += list.length;
    if (list.length < 10) _hasMore = false;
    return list;
  }

  Future<void> loadMore() async {
    if (!_hasMore) return;
    final current = state.valueOrNull ?? [];
    final more = await _fetch();
    state = AsyncData([...current, ...more]);
  }

  Future<void> switchType(String type) async {
    if (_type == type) return;
    _type = type;
    _offset = 0;
    _hasMore = true;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<bool> toggleLike(String reelId) async {
    final dio = ref.read(dioProvider);
    final res = await dio.post<Map<String, dynamic>>('/api/reels/$reelId/like');
    return res.data!['liked'] as bool;
  }
}
