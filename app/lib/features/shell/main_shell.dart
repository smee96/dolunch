import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  int _locationToIndex(String location) {
    if (location.startsWith('/rooms')) return 1;
    if (location.startsWith('/applicants')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0; // /feed
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _locationToIndex(location);
    final isDark = currentIndex == 0; // 피드 탭 = 다크

    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: _BottomNav(
        currentIndex: currentIndex,
        isDark: isDark,
        onTap: (i) {
          switch (i) {
            case 0: context.go('/feed');
            case 1: context.go('/rooms');
            case 2: context.push('/rooms/create');
            case 3: context.go('/applicants');
            case 4: context.go('/profile');
          }
        },
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final bool isDark;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final activeColor = isDark ? Colors.white : AppColors.primary;
    final inactiveColor = isDark ? Colors.white.withOpacity(0.55) : const Color(0xFFC3B2B8);
    final bgColor = isDark
        ? Colors.black.withOpacity(0.55)
        : Colors.white.withOpacity(0.92);
    // 시스템 내비게이션(제스처/3버튼) 영역만큼 하단 여백을 둬 아이콘이 잘리지 않게 함
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return ClipRect(
      child: Container(
        height: 86 + bottomInset,
        padding: EdgeInsets.only(bottom: bottomInset),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1), width: 0.5)),
        ),
        child: Row(
          children: [
            _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, index: 0, currentIndex: currentIndex, activeColor: activeColor, inactiveColor: inactiveColor, onTap: onTap),
            _NavItem(icon: Icons.grid_view_outlined, activeIcon: Icons.grid_view, index: 1, currentIndex: currentIndex, activeColor: activeColor, inactiveColor: inactiveColor, onTap: onTap),
            // 중앙 + FAB
            Expanded(
              child: GestureDetector(
                onTap: () => onTap(2),
                child: Center(
                  child: Container(
                    width: 54, height: 54,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.accent, AppColors.primary, AppColors.deep],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.7), blurRadius: 22, offset: const Offset(0, 10))],
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 26),
                  ),
                ),
              ),
            ),
            _NavItem(icon: Icons.notifications_outlined, activeIcon: Icons.notifications, index: 3, currentIndex: currentIndex, activeColor: activeColor, inactiveColor: inactiveColor, onTap: onTap),
            _NavItem(icon: Icons.person_outline, activeIcon: Icons.person, index: 4, currentIndex: currentIndex, activeColor: activeColor, inactiveColor: inactiveColor, onTap: onTap),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon, activeIcon;
  final int index, currentIndex;
  final Color activeColor, inactiveColor;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon, required this.activeIcon, required this.index,
    required this.currentIndex, required this.activeColor,
    required this.inactiveColor, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == currentIndex;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Icon(isActive ? activeIcon : icon, color: isActive ? activeColor : inactiveColor, size: 26),
        ),
      ),
    );
  }
}
