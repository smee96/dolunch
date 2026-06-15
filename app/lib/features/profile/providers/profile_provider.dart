import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/models.dart';
import '../../feed/providers/feed_provider.dart';

// My profile
final myProfileProvider = FutureProvider<UserProfile>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get<Map<String, dynamic>>('/api/users/me');
  return UserProfile.fromJson(res.data!['user'] as Map<String, dynamic>);
});

// Other user's profile
final userProfileProvider = FutureProvider.family<UserProfile, String>((ref, userId) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get<Map<String, dynamic>>('/api/users/$userId');
  return UserProfile.fromJson(res.data!['user'] as Map<String, dynamic>);
});

// Follow toggle
class FollowNotifier extends StateNotifier<bool> {
  final Ref _ref;
  final String userId;
  FollowNotifier(this._ref, this.userId, bool isFollowing) : super(isFollowing);

  Future<void> toggle() async {
    final dio = _ref.read(dioProvider);
    final wasFollowing = state;
    state = !wasFollowing;
    try {
      await dio.post('/api/users/$userId/follow');
    } catch (_) {
      state = wasFollowing;
    }
  }
}

final followProvider = StateNotifierProvider.family<FollowNotifier, bool, (String, bool)>(
  (ref, args) => FollowNotifier(ref, args.$1, args.$2),
);
