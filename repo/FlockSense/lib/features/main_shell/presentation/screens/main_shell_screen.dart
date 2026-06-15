import 'package:flutter/material.dart';
import 'package:flock_sense/features/home/presentation/screens/home_screen.dart';
import 'package:flock_sense/features/more/presentation/screens/more_screen.dart';
import 'package:flock_sense/features/profile/presentation/screens/profile_screen.dart';
import 'package:flock_sense/features/farms/presentation/screens/farm_list_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _currentIndex = 0;

  static const List<Widget> _screens = <Widget>[
    HomeScreen(),
    FarmListScreen(),
    MoreScreen(),
    ProfileScreen(),
  ];

  static const List<BottomNavigationBarItem> _items = [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
    BottomNavigationBarItem(icon: Icon(Icons.agriculture), label: 'My Farms'),
    BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'More'),
    BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        items: _items,
        selectedItemColor: Colors.green.shade700,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
