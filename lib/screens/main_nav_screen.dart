import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../widgets/youtube_app_bar.dart';
import 'home_screen.dart';
import 'privacy_screen.dart';
import 'search_screen.dart';
import 'subscriptions_screen.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _currentIndex = 0;

  void _onSearchTap() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SearchScreen()),
    );
  }

  void _onSettingsTap() {
    setState(() {
      _currentIndex = 2; // Jump to Privacy/Settings
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: YouTubeAppBar(
        onSearchTap: _onSearchTap,
        onSettingsTap: _onSettingsTap,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const HomeScreen(),
          SubscriptionsScreen(
            onExploreTap: () {
              setState(() {
                _currentIndex = 0;
              });
            },
          ),
          const PrivacyScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: YouTubeTheme.ytBorder, width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.subscriptions_outlined),
              activeIcon: Icon(Icons.subscriptions),
              label: 'Subscriptions',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.privacy_tip_outlined),
              activeIcon: Icon(Icons.privacy_tip),
              label: 'Privacy',
            ),
          ],
        ),
      ),
    );
  }
}
