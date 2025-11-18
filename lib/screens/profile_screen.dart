import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'home_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _currentNavIndex = 1;

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
              'Profile',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(fontFamily: 'Ntype82-R'),
            ),
            SizedBox(height: 32),

            // Profile Card
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[700]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xFF74C0FC).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: FaIcon(
                      FontAwesomeIcons.circleUser,
                      color: Color(0xFF74C0FC),
                      size: 48,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'User Profile',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontFamily: 'Ntype82-R',
                        ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'user@example.com',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'Lettera',
                          color: Colors.grey[500],
                        ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 32),

            // Profile Stats
            Text(
              'Statistics',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(fontFamily: 'Ntype82-R'),
            ),
            SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[700]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Assessments',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontFamily: 'Lettera',
                                color: Colors.grey[500],
                              ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '1',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontFamily: 'NType82-R',
                                color: Color(0xFF63E6BE),
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[700]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Streak',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontFamily: 'Lettera',
                                color: Colors.grey[500],
                              ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '12',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontFamily: 'NType82-R',
                                color: Color(0xFFFF922B),
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 32),

            // Placeholder content
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  'Profile details coming soon...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontFamily: 'Lettera',
                        color: Colors.grey[500],
                      ),
                ),
              ),
            ),
          ],
        ),
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
                setState(() {
                  _currentNavIndex = 1;
                });
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
                Navigator.pushReplacement(
                  context,
                  _createSlideTransition(const SettingsScreen()),
                );
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
