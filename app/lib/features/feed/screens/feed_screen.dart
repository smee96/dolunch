import 'package:flutter/material.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF15090F),
      body: Center(child: Text('숏츠 피드 — 구현 중', style: TextStyle(color: Colors.white))),
    );
  }
}
