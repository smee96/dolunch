import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _storage = FlutterSecureStorage();

// GoRouter refreshListenable용 ChangeNotifier
class AuthNotifier extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  Future<void> init() async {
    final token = await _storage.read(key: 'auth_token');
    _isLoggedIn = token != null;
  }

  Future<void> login(String token) async {
    await _storage.write(key: 'auth_token', value: token);
    _isLoggedIn = true;
    notifyListeners();
  }

  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
    _isLoggedIn = false;
    notifyListeners();
  }

  // 401 수신 시 Dio 인터셉터에서 호출
  Future<void> onUnauthorized() async {
    await _storage.delete(key: 'auth_token');
    _isLoggedIn = false;
    notifyListeners();
  }
}

final authNotifierProvider = ChangeNotifierProvider<AuthNotifier>((ref) {
  return AuthNotifier();
});

// 현재 로그인 유저 ID (JWT payload에서 파싱)
final currentUserIdProvider = FutureProvider<String?>((ref) async {
  final token = await _storage.read(key: 'auth_token');
  if (token == null) return null;
  try {
    final parts = token.split('.');
    if (parts.length < 2) return null;
    final payload = String.fromCharCodes(
      base64DecodeUnpadded(parts[1]),
    );
    final json = _jsonDecode(payload);
    return json['sub'] as String?;
  } catch (_) {
    return null;
  }
});

// base64 padding 없이 디코드
List<int> base64DecodeUnpadded(String s) {
  final padded = s.padRight((s.length + 3) ~/ 4 * 4, '=');
  return _base64Decode(padded);
}

List<int> _base64Decode(String s) {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
  final lookup = <int, int>{};
  for (int i = 0; i < chars.length; i++) lookup[chars.codeUnitAt(i)] = i;
  lookup['='.codeUnitAt(0)] = 0;

  final bytes = <int>[];
  for (int i = 0; i < s.length; i += 4) {
    final a = lookup[s.codeUnitAt(i)] ?? 0;
    final b = lookup[s.codeUnitAt(i + 1)] ?? 0;
    final c = lookup[s.codeUnitAt(i + 2)] ?? 0;
    final d = lookup[s.codeUnitAt(i + 3)] ?? 0;
    bytes.add((a << 2) | (b >> 4));
    if (s[i + 2] != '=') bytes.add(((b & 0xF) << 4) | (c >> 2));
    if (s[i + 3] != '=') bytes.add(((c & 0x3) << 6) | d);
  }
  return bytes;
}

// 간단 JSON 파서 (sub 필드만 추출)
Map<String, dynamic> _jsonDecode(String s) {
  final result = <String, dynamic>{};
  final inner = s.trim().replaceFirst('{', '').replaceFirst(RegExp(r'}$'), '');
  for (final pair in inner.split(',')) {
    final kv = pair.trim().split(':');
    if (kv.length < 2) continue;
    final key = kv[0].trim().replaceAll('"', '');
    final val = kv.sublist(1).join(':').trim().replaceAll('"', '');
    result[key] = val;
  }
  return result;
}
