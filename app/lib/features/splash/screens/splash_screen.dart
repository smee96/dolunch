import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// 앱 초기화 동안 보여주는 브랜드 스플래시.
/// 네이티브 스플래시(콜드스타트)와 동일한 글램 그라데이션으로 자연스럽게 이어진다.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.glamGradient),
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 포크/나이프 로고
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: const Icon(Icons.restaurant, color: Colors.white, size: 48),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      '점심어때',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'D O L U N C H',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.85),
                        letterSpacing: 6,
                      ),
                    ),
                  ],
                ),
              ),
              // 하단 카피
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 36),
                  child: Text(
                    '오늘 점심, 누구랑 먹지?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
