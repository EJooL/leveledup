import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import 'career/quest_log_screen.dart';
import 'career/skill_tree_screen.dart';
import 'home/home_dashboard_screen.dart';
import 'scanner/scanner_screen.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  double _slideDirection = 1.0;
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      value: 1.0,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _setTab(int index) {
    if (index == _currentIndex) return;
    setState(() {
      _slideDirection = index > _currentIndex ? 1.0 : -1.0;
      _currentIndex = index;
    });
    _animController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeDashboardScreen(onNavigateTab: _setTab),
      const ScannerScreen(),
      const QuestLogScreen(),
      const SkillTreeScreen(),
    ];

    const navItems = [
      _NavItemData(
        label: 'Home',
        icon: Icons.grid_view_outlined,
        activeIcon: Icons.grid_view_rounded,
      ),
      _NavItemData(
        label: 'Scanner',
        icon: Icons.document_scanner_outlined,
        activeIcon: Icons.document_scanner_rounded,
      ),
      _NavItemData(
        label: 'Quests',
        icon: Icons.fact_check_outlined,
        activeIcon: Icons.fact_check_rounded,
      ),
      _NavItemData(
        label: 'Skills',
        icon: Icons.workspace_premium_outlined,
        activeIcon: Icons.workspace_premium_rounded,
      ),
    ];

    return Scaffold(
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          final dx = (1.0 - _fadeAnimation.value) * 0.05 * _slideDirection;
          return Opacity(
            opacity: _fadeAnimation.value.clamp(0.0, 1.0),
            child: FractionalTranslation(
              translation: Offset(dx, 0),
              child: child,
            ),
          );
        },
        child: IndexedStack(
          index: _currentIndex,
          children: screens,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 66,
            child: Row(
              children: List.generate(navItems.length, (index) {
                final item = navItems[index];
                final isSelected = index == _currentIndex;

                return Expanded(
                  child: InkWell(
                    onTap: () => _setTab(index),
                    splashColor: AppColors.terracotta.withValues(alpha: 0.1),
                    highlightColor: Colors.transparent,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.terracotta.withValues(alpha: 0.18)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Icon(
                            isSelected ? item.activeIcon : item.icon,
                            size: 22,
                            color: isSelected
                                ? AppColors.terracottaBright
                                : AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? AppColors.white
                                : AppColors.textMuted,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _NavItemData({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}
