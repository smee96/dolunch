class Reel {
  final String id;
  final String hostId;
  final String hostName;
  final String hostHandle;
  final String? hostAvatar;
  final int hostFollowers;
  final String videoUrl;
  final String? thumbUrl;
  final String caption;
  final int likeCount;
  final int commentCount;
  final String? roomId;
  final String? roomTitle;
  final String? roomMeetAt;
  final int? roomSpots;
  final int? depositAmount;
  final String? roomStatus;
  final String createdAt;

  const Reel({
    required this.id, required this.hostId, required this.hostName,
    required this.hostHandle, this.hostAvatar, required this.hostFollowers,
    required this.videoUrl, this.thumbUrl, required this.caption,
    required this.likeCount, required this.commentCount,
    this.roomId, this.roomTitle, this.roomMeetAt, this.roomSpots,
    this.depositAmount, this.roomStatus, required this.createdAt,
  });

  factory Reel.fromJson(Map<String, dynamic> j) => Reel(
    id: j['id'] as String, hostId: j['host_id'] as String,
    hostName: j['host_name'] as String, hostHandle: j['host_handle'] as String,
    hostAvatar: j['host_avatar'] as String?, hostFollowers: j['host_followers'] as int? ?? 0,
    videoUrl: j['video_url'] as String, thumbUrl: j['thumb_url'] as String?,
    caption: j['caption'] as String? ?? '',
    likeCount: j['like_count'] as int? ?? 0, commentCount: j['comment_count'] as int? ?? 0,
    roomId: j['room_id'] as String?, roomTitle: j['room_title'] as String?,
    roomMeetAt: j['room_meet_at'] as String?, roomSpots: j['room_spots'] as int?,
    depositAmount: j['deposit_amount'] as int?, roomStatus: j['room_status'] as String?,
    createdAt: j['created_at'] as String,
  );
}

class Room {
  final String id;
  final String hostId;
  final String? hostName;
  final String? hostHandle;
  final String? hostAvatar;
  final double? hostRating;
  final String? reelId;
  final String title;
  final String description;
  final String menu;
  final String placeName;
  final String? placeAddress;
  final String meetAt;
  final int capacity;
  final int joinedCount;
  final int pricePerPerson;
  final int depositAmount;
  final int platformFee;
  final int hostRevenue;
  final String status;
  final String createdAt;

  const Room({
    required this.id, required this.hostId, this.hostName, this.hostHandle,
    this.hostAvatar, this.hostRating, this.reelId,
    required this.title, required this.description, required this.menu,
    required this.placeName, this.placeAddress, required this.meetAt,
    required this.capacity, required this.joinedCount,
    required this.pricePerPerson, required this.depositAmount,
    required this.platformFee, required this.hostRevenue,
    required this.status, required this.createdAt,
  });

  factory Room.fromJson(Map<String, dynamic> j) => Room(
    id: j['id'] as String, hostId: j['host_id'] as String,
    hostName: j['host_name'] as String?, hostHandle: j['host_handle'] as String?,
    hostAvatar: j['host_avatar'] as String?,
    hostRating: (j['host_rating'] as num?)?.toDouble(),
    reelId: j['reel_id'] as String?,
    title: j['title'] as String, description: j['description'] as String? ?? '',
    menu: j['menu'] as String, placeName: j['place_name'] as String,
    placeAddress: j['place_address'] as String?, meetAt: j['meet_at'] as String,
    capacity: j['capacity'] as int, joinedCount: j['joined_count'] as int? ?? 0,
    pricePerPerson: j['price_per_person'] as int,
    depositAmount: j['deposit_amount'] as int,
    platformFee: j['platform_fee'] as int, hostRevenue: j['host_revenue'] as int,
    status: j['status'] as String, createdAt: j['created_at'] as String,
  );

  int get spotsLeft => capacity - joinedCount;
  bool get isOpen => status == 'open';
}

class Applicant {
  final String id;
  final String roomId;
  final String guestId;
  final String name;
  final String handle;
  final String? avatar;
  final double rating;
  final int hostingCount;
  final String status;
  final int depositAmount;
  final int mainAmount;
  final bool depositPaid;
  final int? attended;
  final String createdAt;

  const Applicant({
    required this.id, required this.roomId, required this.guestId,
    required this.name, required this.handle, this.avatar,
    required this.rating, required this.hostingCount,
    required this.status, required this.depositAmount, required this.mainAmount,
    required this.depositPaid, this.attended, required this.createdAt,
  });

  factory Applicant.fromJson(Map<String, dynamic> j) => Applicant(
    id: j['id'] as String, roomId: j['room_id'] as String,
    guestId: j['guest_id'] as String, name: j['name'] as String,
    handle: j['handle'] as String, avatar: j['avatar_url'] as String?,
    rating: (j['rating'] as num?)?.toDouble() ?? 0.0,
    hostingCount: j['hosting_count'] as int? ?? 0,
    status: j['status'] as String,
    depositAmount: j['deposit_amount'] as int, mainAmount: j['main_amount'] as int,
    depositPaid: j['deposit_payment_key'] != null,
    attended: j['attended'] as int?, createdAt: j['created_at'] as String,
  );
}

class UserProfile {
  final String id;
  final String name;
  final String handle;
  final String bio;
  final String? avatarUrl;
  final int followerCount;
  final int hostingCount;
  final double rating;
  final bool isBusiness;

  const UserProfile({
    required this.id, required this.name, required this.handle,
    required this.bio, this.avatarUrl, required this.followerCount,
    required this.hostingCount, required this.rating, required this.isBusiness,
  });

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
    id: j['id'] as String, name: j['name'] as String,
    handle: j['handle'] as String, bio: j['bio'] as String? ?? '',
    avatarUrl: j['avatar_url'] as String?,
    followerCount: j['follower_count'] as int? ?? 0,
    hostingCount: j['hosting_count'] as int? ?? 0,
    rating: (j['rating'] as num?)?.toDouble() ?? 0.0,
    isBusiness: (j['is_business'] as int? ?? 0) == 1,
  );
}
