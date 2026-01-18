// lib/screens/app_shell.dart
// Main app shell with bottom navigation

import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import 'dashboard_screen.dart';
import 'record_screen.dart';
import 'charts_screen.dart';
import 'profile_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  // GlobalKeys to access screen states for refresh
  final _dashboardKey = GlobalKey<DashboardScreenState>();
  final _recordKey = GlobalKey<RecordScreenState>();
  final _chartsKey = GlobalKey<ChartsScreenState>();
  final _profileKey = GlobalKey<ProfileScreenState>();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      DashboardScreen(
        key: _dashboardKey,
        onNavigateToRecord: _navigateToRecord,
      ),
      RecordScreen(key: _recordKey),
      ChartsScreen(key: _chartsKey),
      ProfileScreen(key: _profileKey),
    ];
  }

  /// Navigate to record screen with a specific tab selected
  void _navigateToRecord(int tabIndex) {
    setState(() => _currentIndex = 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recordKey.currentState?.selectTab(tabIndex);
    });
  }

  void _onTabChanged(int newIndex) {
    setState(() => _currentIndex = newIndex);

    // Refresh data after the frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      switch (newIndex) {
        case 0:
          _dashboardKey.currentState?.refresh();
          break;
        case 2:
          _chartsKey.currentState?.refresh();
          break;
        case 3:
          _profileKey.currentState?.refresh();
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryBlue,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_rounded, 'Início', 0),
              _buildNavItem(Icons.add_circle_outline, 'Registrar', 1),
              _buildNavItem(Icons.bar_chart_rounded, 'Gráficos', 2),
              _buildNavItem(Icons.person_rounded, 'Perfil', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => _onTabChanged(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: isSelected ? 28 : 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
