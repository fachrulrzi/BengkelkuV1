import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/mekanik_dashboard_viewmodel.dart';
import 'mekanik_dashboard_screen.dart';
import 'mekanik_tasks_screen.dart';
import 'mekanik_history_screen.dart';

class MekanikMainScreen extends StatefulWidget {
  const MekanikMainScreen({super.key});

  @override
  State<MekanikMainScreen> createState() => _MekanikMainScreenState();
}

class _MekanikMainScreenState extends State<MekanikMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    MekanikDashboardScreen(),
    MekanikTasksScreen(),
    MekanikHistoryScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MekanikDashboardViewModel>().fetchData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MekanikDashboardViewModel>();
    final newTaskCount = vm.newTasks.length;

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: const Color(0xFF1B3A5E),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 12,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.assignment_outlined),
                if (newTaskCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$newTaskCount',
                        style: const TextStyle(color: Colors.white, fontSize: 9),
                      ),
                    ),
                  ),
              ],
            ),
            activeIcon: const Icon(Icons.assignment),
            label: 'Tugas',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'Riwayat',
          ),
        ],
      ),
    );
  }
}
