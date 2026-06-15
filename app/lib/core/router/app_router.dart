import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/shell/main_shell.dart';
import '../../features/feed/screens/feed_screen.dart';
import '../../features/room/screens/rooms_screen.dart';
import '../../features/room/screens/room_detail_screen.dart';
import '../../features/room/screens/create_room_screen.dart';
import '../../features/room/screens/applicants_screen.dart';
import '../../features/applicant/screens/applicants_screen.dart' as my_apps;
import '../../features/profile/screens/profile_screen.dart';
import '../../features/upload/screens/upload_reel_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/feed',
    redirect: (context, state) async {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');
      final isAuth = token != null;
      final isLoginRoute = state.matchedLocation == '/login';

      if (!isAuth && !isLoginRoute) return '/login';
      if (isAuth && isLoginRoute) return '/feed';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/feed', builder: (c, s) => const FeedScreen()),
          GoRoute(path: '/rooms', builder: (c, s) => const RoomsScreen()),
          GoRoute(path: '/applicants', builder: (c, s) => const my_apps.ApplicantsScreen()),
          GoRoute(path: '/profile', builder: (c, s) => const ProfileScreen()),
        ],
      ),
      GoRoute(
        path: '/rooms/create',
        builder: (c, s) => const CreateRoomScreen(),
      ),
      GoRoute(
        path: '/rooms/:id',
        builder: (c, s) => RoomDetailScreen(roomId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/rooms/:id/applicants',
        builder: (c, s) => RoomApplicantsScreen(roomId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/profile/:id',
        builder: (c, s) => ProfileScreen(userId: s.pathParameters['id']),
      ),
      GoRoute(
        path: '/upload/reel',
        builder: (c, s) => const UploadReelScreen(),
      ),
    ],
  );
});
