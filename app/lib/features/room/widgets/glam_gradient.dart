import 'package:flutter/material.dart';

class GlamGradient extends StatelessWidget {
  final int seed;
  const GlamGradient({super.key, required this.seed});

  static const _grads = [
    [Color(0xFFFF8A3D), Color(0xFFF0457E), Color(0xFF7C2A5B)],
    [Color(0xFFF0457E), Color(0xFF9B2F6B), Color(0xFF3A1430)],
    [Color(0xFFFFB23E), Color(0xFFFF6B4A), Color(0xFFC42E6E)],
    [Color(0xFF6A2D7A), Color(0xFFF0457E), Color(0xFFFF8A3D)],
    [Color(0xFFFF6B7E), Color(0xFFB0356E), Color(0xFF2C1024)],
    [Color(0xFFFFA63D), Color(0xFFE03E78), Color(0xFF5C1E4A)],
  ];

  @override
  Widget build(BuildContext context) {
    final g = _grads[seed.abs() % _grads.length];
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: g, begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
    );
  }
}

class SoftGradient extends StatelessWidget {
  final int seed;
  const SoftGradient({super.key, required this.seed});

  static const _soft = [
    [Color(0xFFFFE3D0), Color(0xFFFFC9DA)],
    [Color(0xFFFFD9C2), Color(0xFFF7BBD4)],
    [Color(0xFFFFE9CC), Color(0xFFFFCBBE)],
    [Color(0xFFF6CFE0), Color(0xFFE9C2E8)],
    [Color(0xFFFFD7CE), Color(0xFFF4C7DE)],
    [Color(0xFFFFE6BF), Color(0xFFFFC8C0)],
  ];

  @override
  Widget build(BuildContext context) {
    final g = _soft[seed.abs() % _soft.length];
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: g, begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
    );
  }
}
