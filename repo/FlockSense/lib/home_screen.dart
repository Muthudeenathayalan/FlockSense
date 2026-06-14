import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flock_sense/features/feed/presentation/screens/feed_inventory_screen.dart';
import 'package:flock_sense/screens/home_tab.dart';
import 'package:flock_sense/screens/more_screen.dart';
import 'package:flock_sense/screens/flocks_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const List<String> _tabTitles = [
    'Dashboard',
    'Flocks',
    'Feed',
    'More',
  ];

  final List<Widget> _pages = const [
    HomeTab(),
    FlocksScreen(),
    FeedInventoryScreen(),
    MoreScreen(),
  ];

  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_tabTitles[_selectedIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey.shade600,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Flocks'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Feed'),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'More'),
        ],
      ),
    );
  }
}
