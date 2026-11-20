import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../models/career_companion_model.dart';
import '../providers/career_provider.dart';
import 'career/progress_screen.dart';
import 'home/home_dashboard_screen.dart';
import 'scanner/scanner_screen.dart';
import 'wins/wins_screen.dart';

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

  void _showMilestoneCelebrationToast(CareerBadge badge) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final container = ProviderScope.containerOf(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surfaceElevated,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.accentGold),
          ),
          content: Row(
            children: [
              const Icon(
                Icons.emoji_events_rounded,
                color: AppColors.accentGoldBright,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Milestone Unlocked: ${badge.title}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.white,
                      ),
                    ),
                    Text(
                      badge.description,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
      container.read(careerProvider.notifier).clearPendingToastBadge();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeDashboardScreen(onNavigateTab: _setTab),
      const ScannerScreen(),
      const WinsScreen(),
      ProgressScreen(onNavigateTab: _setTab),
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
        label: 'Wins',
        icon: Icons.emoji_events_outlined,
        activeIcon: Icons.emoji_events_rounded,
      ),
      _NavItemData(
        label: 'Progress',
        icon: Icons.fact_check_outlined,
        activeIcon: Icons.fact_check_rounded,
      ),
    ];

    return Consumer(
      builder: (context, ref, _) {
        ref.listen<CareerBadge?>(
          careerProvider.select((p) => p.pendingToastBadge),
          (prev, next) {
            if (next != null) {
              _showMilestoneCelebrationToast(next);
            }
          },
        );

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
                                fontWeight:
                                    isSelected ? FontWeight.w700 : FontWeight.w500,
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
      },
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
