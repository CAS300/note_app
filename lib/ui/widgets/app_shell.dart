import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../screens/home_screen.dart';
import '../screens/settings_screen.dart';
import '../../providers/workspace_provider.dart';
import '../../providers/database_provider.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final workspaceState = ref.watch(workspaceProvider);
    final dbState = ref.watch(databaseProvider);
    
    final manifest = workspaceState.manifest;
    List<String> dbNames = manifest?.databases.map((e) => e.name).toList() ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Note App'),
        actions: [
          if (manifest != null && dbNames.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: DropdownButton<String>(
                value: dbState.activeDbName ?? manifest.activeDb,
                hint: const Text('DB: '),
                items: dbNames.map((name) {
                  return DropdownMenuItem<String>(
                    value: name,
                    child: Text('DB: \$name'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    ref.read(databaseProvider.notifier).switchDatabase(value);
                  }
                },
              ),
            ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
