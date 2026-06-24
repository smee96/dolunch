import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/models.dart';
import '../providers/profile_provider.dart';
import '../../feed/providers/feed_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final UserProfile profile;
  const EditProfileScreen({super.key, required this.profile});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _handleCtrl;
  late final TextEditingController _bioCtrl;

  File? _pickedImage;
  String? _newAvatarUrl;
  bool _uploading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.profile.name);
    _handleCtrl = TextEditingController(text: widget.profile.handle);
    _bioCtrl = TextEditingController(text: widget.profile.bio);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _handleCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: AppColors.ink),
        title: const Text('프로필 편집',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? '저장 중...' : '저장',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primary)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // 아바타
          Center(
            child: GestureDetector(
              onTap: _picking ? null : _pickAvatar,
              child: Stack(children: [
                _AvatarPreview(
                  file: _pickedImage,
                  url: widget.profile.avatarUrl,
                  name: widget.profile.name,
                ),
                Positioned(bottom: 0, right: 0,
                  child: Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: _uploading
                        ? const Padding(padding: EdgeInsets.all(4),
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                  )),
              ]),
            ),
          ),
          const SizedBox(height: 32),

          _Label('이름'),
          const SizedBox(height: 8),
          _Field(controller: _nameCtrl, hint: '이름을 입력하세요'),
          const SizedBox(height: 20),

          _Label('핸들 (@)'),
          const SizedBox(height: 8),
          _Field(
            controller: _handleCtrl,
            hint: 'username',
            prefix: const Text('@', style: TextStyle(color: AppColors.sub, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 20),

          _Label('소개'),
          const SizedBox(height: 8),
          TextField(
            controller: _bioCtrl,
            maxLines: 4,
            maxLength: 150,
            decoration: InputDecoration(
              hintText: '나를 소개해 보세요',
              hintStyle: const TextStyle(color: AppColors.sub, fontSize: 14),
              filled: true,
              fillColor: AppColors.base,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.line),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ]),
      ),
    );
  }

  bool get _picking => _uploading;

  Future<ImageSource?> _showSourcePicker() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 36, height: 4, margin: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(2)),
          ),
          const Text('프로필 사진 변경', style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink,
          )),
          const SizedBox(height: 8),
          ListTile(
            leading: Container(
              width: 40, height: 40,
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.glamGradient),
              child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 20),
            ),
            title: const Text('카메라로 촬영', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
            subtitle: const Text('지금 바로 찍기', style: TextStyle(fontSize: 12, color: AppColors.sub)),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: Container(
              width: 40, height: 40,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.line),
              child: const Icon(Icons.photo_library_outlined, color: AppColors.ink, size: 20),
            ),
            title: const Text('갤러리에서 선택', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
            subtitle: const Text('내 앨범에서 고르기', style: TextStyle(fontSize: 12, color: AppColors.sub)),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
          const SizedBox(height: 12),
        ]),
      ),
    );
  }

  Future<void> _pickAvatar() async {
    final source = await _showSourcePicker();
    if (source == null) return;

    final picker = ImagePicker();
    final xf = await picker.pickImage(source: source, imageQuality: 80, maxWidth: 800);
    if (xf == null) return;

    final file = File(xf.path);
    setState(() { _pickedImage = file; _uploading = true; });

    try {
      final dio = ref.read(dioProvider);
      final ext = xf.path.split('.').last.toLowerCase();
      final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';
      final bytes = await file.readAsBytes();

      // Presign (백엔드 계약: { type, ext } → { uploadUrl, key, publicUrl? })
      final presignRes = await dio.post<Map<String, dynamic>>('/api/media/presign', data: {
        'type': 'avatar',
        'ext': ext,
      });
      final data = presignRes.data!;
      final uploadUrl = data['uploadUrl'] as String;
      final key = data['key'] as String?;
      String? publicUrl = data['publicUrl'] as String?;

      if (uploadUrl.startsWith('http')) {
        // R2 presigned 절대 URL → 인증 없는 순수 PUT
        await Dio().put(uploadUrl, data: bytes,
          options: Options(headers: {Headers.contentTypeHeader: mimeType}));
        publicUrl ??= (key != null) ? 'https://media.dolunch.app/$key' : null;
      } else {
        // 로컬/fallback 상대 경로 → 인증된 dio로 업로드, 응답의 url 사용
        final upRes = await dio.put<Map<String, dynamic>>(uploadUrl, data: bytes,
          options: Options(headers: {Headers.contentTypeHeader: mimeType}));
        publicUrl = (upRes.data?['url'] as String?) ?? publicUrl;
      }

      if (publicUrl == null) {
        throw Exception('업로드 응답에 URL이 없습니다');
      }
      setState(() { _newAvatarUrl = publicUrl; _uploading = false; });
    } catch (e) {
      setState(() => _uploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 업로드 실패: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final handle = _handleCtrl.text.trim();
    final bio = _bioCtrl.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이름을 입력해 주세요'), backgroundColor: AppColors.danger),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final dio = ref.read(dioProvider);
      final body = <String, dynamic>{'name': name, 'bio': bio};
      if (handle.isNotEmpty) body['handle'] = handle;
      if (_newAvatarUrl != null) body['avatar_url'] = _newAvatarUrl;

      await dio.patch('/api/users/me', data: body);
      ref.invalidate(myProfileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('프로필이 저장됐어요'), backgroundColor: AppColors.success),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _AvatarPreview extends StatelessWidget {
  final File? file;
  final String? url;
  final String name;
  const _AvatarPreview({this.file, this.url, required this.name});

  @override
  Widget build(BuildContext context) => Container(
    width: 88, height: 88,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: AppColors.glamGradient,
      border: Border.all(color: Colors.white, width: 3),
    ),
    child: ClipOval(
      child: file != null
          ? Image.file(file!, fit: BoxFit.cover)
          : url != null
              ? Image.network(url!, fit: BoxFit.cover)
              : Center(child: Text(
                  name.isNotEmpty ? name[0] : '?',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 32),
                )),
    ),
  );
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.sub));
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final Widget? prefix;
  const _Field({required this.controller, required this.hint, this.prefix});

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    decoration: InputDecoration(
      hintText: hint,
      prefixIcon: prefix != null ? Padding(padding: const EdgeInsets.only(left: 16, right: 8), child: prefix) : null,
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      hintStyle: const TextStyle(color: AppColors.sub, fontSize: 14),
      filled: true,
      fillColor: AppColors.base,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.line)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.line)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}
