import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/models.dart';
import '../../feed/providers/feed_provider.dart';

final myRoomsProvider = FutureProvider<List<Room>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get<Map<String, dynamic>>('/api/rooms/mine');
  return (res.data!['rooms'] as List)
      .map((e) => Room.fromJson(e as Map<String, dynamic>))
      .toList();
});

final roomDetailProvider = FutureProvider.family<Room, String>((ref, id) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get<Map<String, dynamic>>('/api/rooms/$id');
  return Room.fromJson(res.data!['room'] as Map<String, dynamic>);
});

final applicantsProvider = FutureProvider.family<List<Applicant>, String>((ref, roomId) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get<Map<String, dynamic>>('/api/applications/rooms/$roomId/applicants');
  return (res.data!['applicants'] as List)
      .map((e) => Applicant.fromJson(e as Map<String, dynamic>))
      .toList();
});

class CreateRoomNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  CreateRoomNotifier(this._ref) : super(const AsyncData(null));

  Future<String?> create({
    required String title, required String description, required String menu,
    required String placeName, required String meetAt,
    required int capacity, required int pricePerPerson, String? reelId,
  }) async {
    state = const AsyncLoading();
    try {
      final dio = _ref.read(dioProvider);
      final res = await dio.post<Map<String, dynamic>>('/api/rooms', data: {
        'title': title, 'description': description, 'menu': menu,
        'place_name': placeName, 'meet_at': meetAt,
        'capacity': capacity, 'price_per_person': pricePerPerson,
        if (reelId != null) 'reel_id': reelId,
      });
      state = const AsyncData(null);
      _ref.invalidate(myRoomsProvider);
      return res.data!['id'] as String;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }
}

final createRoomProvider = StateNotifierProvider<CreateRoomNotifier, AsyncValue<void>>(
  (ref) => CreateRoomNotifier(ref),
);
