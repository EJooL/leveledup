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

class _MainNavScreenState extends State<MainNavScreen> {
  int _currentIndex = 0;

  void _setTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeDashboardScreen(onNavigateTab: _setTab),
      const ScannerScreen(),
      const QuestLogScreen(),
      const SkillTreeScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _setTab,
          height: 68,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.space_dashboard_outlined),
              selectedIcon: Icon(Icons.space_dashboard_rounded),
              label: 'Command Hub',
            ),
            NavigationDestination(
              icon: Icon(Icons.radar_outlined),
              selectedIcon: Icon(Icons.radar_rounded),
              label: 'ATS Scanner',
            ),
            NavigationDestination(
              icon: Icon(Icons.assignment_turned_in_outlined),
              selectedIcon: Icon(Icons.assignment_turned_in_rounded),
              label: 'Quest Log',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_tree_outlined),
              selectedIcon: Icon(Icons.account_tree_rounded),
              label: 'Skill Tree',
            ),
          ],
        ),
      ),
    );
  }
}

