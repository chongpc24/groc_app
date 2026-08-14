import 'package:flutter/material.dart';
import 'features/search/explore_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  // Explore/search is done. The other three are placeholders until your
  // teammates build their modules — swap these out for their real screens
  // as they finish, no other code needs to change.
  final List<Widget> _tabs = const [
    ExploreScreen(),
    _PlaceholderTab(label: 'Grocer'),
    _PlaceholderTab(label: 'List'),
    _PlaceholderTab(label: 'Account'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explore'),
          BottomNavigationBarItem(icon: Icon(Icons.storefront), label: 'Grocer'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: 'List'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Account'),
        ],
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  final String label;
  const _PlaceholderTab({required this.label});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(label)),
      body: Center(child: Text('$label screen — coming soon')),
    );
  }
}