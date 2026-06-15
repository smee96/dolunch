import 'package:flutter/material.dart';
import '../../../core/models/models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format.dart';
import 'glam_gradient.dart';

class RoomCard extends StatelessWidget {
  final Room room;
  final VoidCallback? onTap;
  const RoomCard({super.key, required this.room, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 24, offset: const Offset(0, 8))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // 배너
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: SizedBox(height: 96, child: Stack(fit: StackFit.expand, children: [
              SoftGradient(seed: room.id.hashCode),
              Container(decoration: BoxDecoration(gradient: LinearGradient(
                begin: Alignment.bottomLeft, end: Alignment.topRight,
                colors: [Colors.black.withOpacity(0.15), Colors.transparent],
              ))),
              Positioned(top: 10, left: 12, child: _StatusBadge(status: room.status)),
              Positioned(bottom: 10, right: 12, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Text('${room.joinedCount}/${room.capacity}명',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
              )),
            ])),
          ),

          // 내용
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(room.title, style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink, letterSpacing: -0.3,
              )),
              const SizedBox(height: 8),
              _MetaRow(Icons.location_on_outlined, room.placeName),
              const SizedBox(height: 4),
              _MetaRow(Icons.restaurant_menu_outlined, room.menu),
              const SizedBox(height: 4),
              _MetaRow(Icons.access_time, kstDateTime(room.meetAt)),
              const Divider(height: 20, color: AppColors.line),
              Row(children: [
                Text('지원자 ${room.joinedCount}명',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13)),
                const Spacer(),
                Text('보증금 ${wonStr(room.depositAmount)}',
                  style: const TextStyle(color: AppColors.sub, fontSize: 12)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 15, color: const Color(0xFFC99999)),
      const SizedBox(width: 6),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: Color(0xFF6A565F)), maxLines: 1, overflow: TextOverflow.ellipsis)),
    ]);
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      'open' => ('모집중', const LinearGradient(colors: [AppColors.accent, AppColors.primary]), const Color(0xFFFFFFFF)),
      'full' => ('정원마감', const LinearGradient(colors: [Color(0xFFE7D8DD), Color(0xFFE7D8DD)]), const Color(0xFF7A5E68)),
      'done' => ('완료', const LinearGradient(colors: [AppColors.ink, AppColors.ink]), const Color(0xFFFFFFFF)),
      _ => ('취소됨', const LinearGradient(colors: [Colors.grey, Colors.grey]), const Color(0xFFFFFFFF)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(gradient: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}
