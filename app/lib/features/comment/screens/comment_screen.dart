import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format.dart';
import '../../feed/providers/feed_provider.dart';

// ─── 모델 ─────────────────────────────────────────────────────────────────────
class Comment {
  final String id;
  final String body;
  final String userId;
  final String userName;
  final String userHandle;
  final String? userAvatar;
  final String createdAt;

  const Comment({
    required this.id, required this.body, required this.userId,
    required this.userName, required this.userHandle,
    this.userAvatar, required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> j) => Comment(
    id: j['id'] as String,
    body: j['body'] as String,
    userId: j['user_id'] as String,
    userName: j['name'] as String,
    userHandle: j['handle'] as String,
    userAvatar: j['avatar_url'] as String?,
    createdAt: j['created_at'] as String,
  );
}

final commentsProvider = FutureProvider.family<List<Comment>, String>((ref, reelId) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get<Map<String, dynamic>>('/api/reels/$reelId/comments');
  return (res.data!['comments'] as List)
      .map((e) => Comment.fromJson(e as Map<String, dynamic>))
      .toList();
});

// ─── 댓글 바텀시트 ────────────────────────────────────────────────────────────
Future<void> showCommentSheet(BuildContext context, String reelId) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => CommentSheet(reelId: reelId),
  );
}

class CommentSheet extends ConsumerStatefulWidget {
  final String reelId;
  const CommentSheet({super.key, required this.reelId});

  @override
  ConsumerState<CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends ConsumerState<CommentSheet> {
  final _ctrl = TextEditingController();
  final _focusNode = FocusNode();
  bool _sending = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(commentsProvider(widget.reelId));
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(children: [
          // 핸들
          Container(width: 36, height: 4, margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(2))),

          const Text('댓글', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColors.line),

          Expanded(
            child: commentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (e, _) => Center(child: Text('오류: $e')),
              data: (comments) {
                if (comments.isEmpty) {
                  return const Center(child: Text('첫 댓글을 남겨보세요!',
                      style: TextStyle(color: AppColors.sub, fontSize: 14)));
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: comments.length,
                  itemBuilder: (_, i) => _CommentTile(
                    comment: comments[i],
                    onDelete: () => _delete(comments[i].id),
                  ),
                );
              },
            ),
          ),

          // 입력창
          const Divider(height: 1, color: AppColors.line),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  focusNode: _focusNode,
                  maxLines: null,
                  maxLength: 500,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: '댓글을 입력하세요...',
                    hintStyle: const TextStyle(color: AppColors.sub, fontSize: 14),
                    filled: true,
                    fillColor: AppColors.base,
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _sending ? null : _send,
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: _ctrl.text.trim().isNotEmpty ? AppColors.glamGradient : null,
                    color: _ctrl.text.trim().isEmpty ? AppColors.line : null,
                  ),
                  child: _sending
                      ? const Padding(padding: EdgeInsets.all(10),
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Icon(Icons.send_rounded,
                          color: _ctrl.text.trim().isNotEmpty ? Colors.white : AppColors.sub, size: 18),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Future<void> _send() async {
    final body = _ctrl.text.trim();
    if (body.isEmpty) return;

    setState(() => _sending = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/api/reels/${widget.reelId}/comments', data: {'body': body});
      _ctrl.clear();
      ref.invalidate(commentsProvider(widget.reelId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('전송 실패: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _delete(String commentId) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.delete('/api/comments/$commentId');
      ref.invalidate(commentsProvider(widget.reelId));
    } catch (_) {}
  }
}

class _CommentTile extends StatelessWidget {
  final Comment comment;
  final VoidCallback onDelete;
  const _CommentTile({required this.comment, required this.onDelete});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _Avatar(url: comment.userAvatar, name: comment.userName),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(comment.userName,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink)),
          const SizedBox(width: 6),
          Text('@${comment.userHandle}',
              style: const TextStyle(fontSize: 11, color: AppColors.sub)),
          const Spacer(),
          Text(kstDate(comment.createdAt),
              style: const TextStyle(fontSize: 11, color: AppColors.sub)),
        ]),
        const SizedBox(height: 4),
        Text(comment.body, style: const TextStyle(fontSize: 14, color: AppColors.ink, height: 1.5)),
      ])),
      GestureDetector(
        onTap: () => _confirmDelete(context),
        child: const Padding(
          padding: EdgeInsets.only(left: 8),
          child: Icon(Icons.more_horiz, size: 18, color: AppColors.sub),
        ),
      ),
    ]),
  );

  void _confirmDelete(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4, margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(2))),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: AppColors.danger),
            title: const Text('삭제', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600)),
            onTap: () { Navigator.pop(context); onDelete(); },
          ),
          ListTile(
            leading: const Icon(Icons.close, color: AppColors.sub),
            title: const Text('취소', style: TextStyle(color: AppColors.sub)),
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? url;
  final String name;
  const _Avatar({this.url, required this.name});

  @override
  Widget build(BuildContext context) => Container(
    width: 34, height: 34,
    decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.glamGradient),
    child: ClipOval(
      child: url != null
          ? Image.network(url!, fit: BoxFit.cover)
          : Center(child: Text(
              name.isNotEmpty ? name[0] : '?',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
            )),
    ),
  );
}
