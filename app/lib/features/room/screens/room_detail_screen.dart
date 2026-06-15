import 'package:flutter/material.dart';

class RoomDetailScreen extends StatelessWidget {
  final String roomId;
  const RoomDetailScreen({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('방 상세')),
      body: Center(child: Text('방 ID: $roomId — 구현 중')),
    );
  }
}
