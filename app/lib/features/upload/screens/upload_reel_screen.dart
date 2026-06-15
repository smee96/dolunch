import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:dio/dio.dart';
import '../../feed/providers/feed_provider.dart';
import '../../room/providers/room_provider.dart';
import '../../../core/theme/app_theme.dart';

class UploadReelScreen extends ConsumerStatefulWidget {
  const UploadReelScreen({super.key});

  @override
  ConsumerState<UploadReelScreen> createState() => _UploadReelScreenState();
}

class _UploadReelScreenState extends ConsumerState<UploadReelScreen> {
  File? _videoFile;
  VideoPlayerController? _controller;
  final _captionCtrl = TextEditingController();
  String? _selectedRoomId;
  bool _uploading = false;
  double _progress = 0;
  String? _error;

  @override
  void dispose() {
    _controller?.dispose();
    _captionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final xfile = await picker.pickVideo(source: ImageSource.gallery, maxDuration: const Duration(seconds: 15));
    if (xfile == null) return;

    final file = File(xfile.path);
    final ctrl = VideoPlayerController.file(file);
    await ctrl.initialize();

    setState(() {
      _videoFile = file;
      _controller?.dispose();
      _controller = ctrl;
      _error = null;
    });
    ctrl.setLooping(true);
    ctrl.play();
  }

  Future<void> _upload() async {
    if (_videoFile == null) return;
    setState(() { _uploading = true; _progress = 0; _error = null; });

    try {
      final dio = ref.read(dioProvider);

      // 1. Presigned URL 요청
      final ext = _videoFile!.path.split('.').last;
      final presignRes = await dio.post<Map<String, dynamic>>('/api/media/presign', data: {
        'key': 'reels/${DateTime.now().millisecondsSinceEpoch}.$ext',
        'content_type': 'video/${ext == 'mov' ? 'quicktime' : ext}',
      });
      final uploadUrl = presignRes.data!['url'] as String;
      final key = presignRes.data!['key'] as String;

      // 2. R2에 직접 업로드
      final bytes = await _videoFile!.readAsBytes();
      await Dio().put(uploadUrl,
        data: Stream.fromIterable(bytes.map((b) => [b])),
        options: Options(
          headers: {
            'Content-Type': 'video/${ext == 'mov' ? 'quicktime' : ext}',
            'Content-Length': bytes.length,
          },
          sendTimeout: const Duration(seconds: 120),
          receiveTimeout: const Duration(seconds: 120),
        ),
        onSendProgress: (sent, total) {
          if (total > 0) setState(() => _progress = sent / total);
        },
      );

      // 3. Reel 등록
      await dio.post('/api/reels', data: {
        'video_url': key,
        'caption': _captionCtrl.text.trim(),
        if (_selectedRoomId != null) 'room_id': _selectedRoomId,
      });

      ref.invalidate(feedProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('숏츠가 업로드됐어요!'), backgroundColor: AppColors.success),
        );
        context.pop();
      }
    } catch (e) {
      setState(() { _error = '업로드 실패: $e'; _uploading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkBg,
        foregroundColor: Colors.white,
        title: const Text('숏츠 올리기', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(children: [
          // 비디오 미리보기
          Expanded(
            flex: 3,
            child: _videoFile == null
                ? GestureDetector(
                    onTap: _picking,
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A1020),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.5),
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Container(
                          width: 72, height: 72,
                          decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppColors.glamGradient),
                          child: const Icon(Icons.video_camera_back_outlined, color: Colors.white, size: 32),
                        ),
                        const SizedBox(height: 16),
                        const Text('영상을 선택하세요', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        const Text('최대 15초', style: TextStyle(color: AppColors.sub, fontSize: 13)),
                      ]),
                    ),
                  )
                : _VideoPreview(controller: _controller!, onRetake: _pickVideo),
          ),

          // 캡션 + 모임 선택
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SizedBox(height: 12),
                TextField(
                  controller: _captionCtrl,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: '모임 분위기를 소개해 보세요...',
                    hintStyle: const TextStyle(color: AppColors.sub),
                    filled: true,
                    fillColor: const Color(0xFF2A1020),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF3A2030)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF3A2030)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _RoomPicker(selectedId: _selectedRoomId, onSelect: (id) => setState(() => _selectedRoomId = id)),

                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
                ],
              ]),
            ),
          ),

          // 업로드 버튼
          Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).padding.bottom + 12),
            child: _uploading
                ? Column(children: [
                    LinearProgressIndicator(value: _progress, color: AppColors.primary, backgroundColor: const Color(0xFF3A2030)),
                    const SizedBox(height: 8),
                    Text('${(_progress * 100).toInt()}% 업로드 중...', style: const TextStyle(color: AppColors.sub, fontSize: 13)),
                  ])
                : SizedBox(
                    width: double.infinity, height: 54,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: _videoFile != null ? AppColors.glamGradient : null,
                        color: _videoFile == null ? const Color(0xFF3A2030) : null,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: _videoFile != null ? [BoxShadow(
                          color: AppColors.primary.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 8),
                        )] : null,
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _videoFile != null ? _upload : null,
                        child: const Text('숏츠 올리기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                      ),
                    ),
                  ),
          ),
        ]),
      ),
    );
  }

  Future<void> _picking() async {
    await _pickVideo();
  }
}

class _VideoPreview extends StatelessWidget {
  final VideoPlayerController controller;
  final VoidCallback onRetake;
  const _VideoPreview({required this.controller, required this.onRetake});

  @override
  Widget build(BuildContext context) {
    return Stack(fit: StackFit.expand, children: [
      ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(0)),
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: controller.value.size.width,
            height: controller.value.size.height,
            child: VideoPlayer(controller),
          ),
        ),
      ),
      Positioned(
        top: 12, right: 12,
        child: GestureDetector(
          onTap: onRetake,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black54, borderRadius: BorderRadius.circular(999),
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.refresh, size: 14, color: Colors.white),
              SizedBox(width: 4),
              Text('다시 선택', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      ),
    ]);
  }
}

class _RoomPicker extends ConsumerWidget {
  final String? selectedId;
  final ValueChanged<String?> onSelect;
  const _RoomPicker({this.selectedId, required this.onSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(myRoomsProvider);

    return roomsAsync.maybeWhen(
      data: (rooms) {
        final open = rooms.where((r) => r.status == 'open').toList();
        if (open.isEmpty) return const SizedBox.shrink();
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('연결할 모임 (선택)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.sub)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _RoomChip(label: '없음', selected: selectedId == null, onTap: () => onSelect(null)),
              const SizedBox(width: 8),
              ...open.map((r) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _RoomChip(
                  label: r.title, selected: selectedId == r.id,
                  onTap: () => onSelect(r.id),
                ),
              )),
            ]),
          ),
        ]);
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _RoomChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _RoomChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : const Color(0xFF2A1020),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: selected ? AppColors.primary : const Color(0xFF3A2030)),
      ),
      child: Text(label, style: TextStyle(
        fontSize: 13, fontWeight: FontWeight.w700,
        color: selected ? Colors.white : AppColors.sub,
      ), maxLines: 1, overflow: TextOverflow.ellipsis),
    ),
  );
}
