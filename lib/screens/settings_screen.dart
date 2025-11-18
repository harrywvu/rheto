import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = true;
  bool _soundEnabled = true;
  int _currentNavIndex = 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: _buildBottomNavBar(context),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 70),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Settings',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(fontFamily: 'Ntype82-R'),
            ),
            SizedBox(height: 32),

            // Settings Sections
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Notifications Section
                    Text(
                      'Notifications',
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(fontFamily: 'Ntype82-R'),
                    ),
                    SizedBox(height: 16),
                    _buildSettingItem(
                      context,
                      icon: FontAwesomeIcons.bell,
                      title: 'Enable Notifications',
                      value: _notificationsEnabled,
                      onChanged: (value) {
                        setState(() {
                          _notificationsEnabled = value;
                        });
                      },
                    ),
                    SizedBox(height: 32),

                    // Display Section
                    Text(
                      'Display',
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(fontFamily: 'Ntype82-R'),
                    ),
                    SizedBox(height: 16),
                    _buildSettingItem(
                      context,
                      icon: FontAwesomeIcons.moon,
                      title: 'Dark Mode',
                      value: _darkModeEnabled,
                      onChanged: (value) {
                        setState(() {
                          _darkModeEnabled = value;
                        });
                      },
                    ),
                    SizedBox(height: 32),

                    // Sound Section
                    Text(
                      'Audio',
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(fontFamily: 'Ntype82-R'),
                    ),
                    SizedBox(height: 16),
                    _buildSettingItem(
                      context,
                      icon: FontAwesomeIcons.volumeHigh,
                      title: 'Sound Effects',
                      value: _soundEnabled,
                      onChanged: (value) {
                        setState(() {
                          _soundEnabled = value;
                        });
                      },
                    ),
                    SizedBox(height: 32),

                    // About Section
                    Text(
                      'About',
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(fontFamily: 'Ntype82-R'),
                    ),
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[700]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'App Version',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontFamily: 'Lettera',
                                  color: Colors.grey[500],
                                ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '1.0.0',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontFamily: 'NType82-R',
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[700]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              FaIcon(
                icon,
                color: Colors.grey[400],
                size: 20,
              ),
              SizedBox(width: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: 'Ntype82-R',
                    ),
              ),
            ],
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Color(0xFF63E6BE),
          ),
        ],
      ),
    );
  }

  PageRoute _createSlideTransition(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        
        var secondaryBegin = const Offset(0.0, 0.0);
        var secondaryEnd = const Offset(-1.0, 0.0);
        var secondaryTween = Tween(begin: secondaryBegin, end: secondaryEnd)
            .chain(CurveTween(curve: curve));
        
        return SlideTransition(
          position: animation.drive(tween),
          child: SlideTransition(
            position: secondaryAnimation.drive(secondaryTween),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[800]!, width: 1),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Home Tab
            GestureDetector(
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  _createSlideTransition(const HomeScreen()),
                  (route) => false,
                );
              },
              child: Padding(
                padding: EdgeInsets.all(12),
                child: FaIcon(
                  FontAwesomeIcons.house,
                  color: _currentNavIndex == 0 ? Color(0xFF63E6BE) : Colors.grey[400],
                  size: 24,
                ),
              ),
            ),
            // Profile Tab
            GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  _createSlideTransition(const ProfileScreen()),
                );
              },
              child: Padding(
                padding: EdgeInsets.all(12),
                child: FaIcon(
                  FontAwesomeIcons.circleUser,
                  color: _currentNavIndex == 1 ? Color(0xFF74C0FC) : Colors.grey[400],
                  size: 24,
                ),
              ),
            ),
            // Settings Tab
            GestureDetector(
              onTap: () {
                setState(() {
                  _currentNavIndex = 2;
                });
              },
              child: Padding(
                padding: EdgeInsets.all(12),
                child: FaIcon(
                  FontAwesomeIcons.gear,
                  color: _currentNavIndex == 2 ? Color(0xFFFFD43B) : Colors.grey[400],
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
