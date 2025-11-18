import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rheto/services/score_storage_service.dart';
import 'domain_detail_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<Map<String, double>> _scoresFuture;
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _scoresFuture = ScoreStorageService.getScores();
  }

  String _getScoreLevel(double score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    return 'Needs Improvement';
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Color(0xFF63E6BE); // Green
    if (score >= 60) return Color(0xFFFFD43B); // Yellow
    if (score >= 40) return Color(0xFFFF922B); // Orange
    return Color(0xFFFF6B6B); // Red
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: _buildBottomNavBar(context),
      body: FutureBuilder<Map<String, double>>(
        future: _scoresFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return Center(child: Text('Error loading scores'));
          }

          final scores = snapshot.data!;
          final criticalThinking = scores['criticalThinking'] ?? 0.0;
          final memory = scores['memory'] ?? 0.0;
          final creativity = scores['creativity'] ?? 0.0;
          final average = (criticalThinking + memory + creativity) / 3;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 70),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Streak and Coins
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your Dashboard',
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(fontFamily: 'Ntype82-R'),
                    ),
                    Row(
                      children: [
                        // Streak Counter
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Color(0xFFFF922B).withOpacity(0.6), width: 1.5),
                            borderRadius: BorderRadius.circular(8),
                            color: Color(0xFFFF922B).withOpacity(0.1),
                          ),
                          child: Row(
                            children: [
                              FaIcon(
                                FontAwesomeIcons.fire,
                                color: Color(0xFFFF922B),
                                size: 16,
                              ),
                              SizedBox(width: 6),
                              Text(
                                '12',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontFamily: 'NType82-R',
                                      color: Color(0xFFFF922B),
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 12),
                        // Coin Counter
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Color(0xFFFFD43B).withOpacity(0.6), width: 1.5),
                            borderRadius: BorderRadius.circular(8),
                            color: Color(0xFFFFD43B).withOpacity(0.1),
                          ),
                          child: Row(
                            children: [
                              FaIcon(
                                FontAwesomeIcons.coins,
                                color: Color(0xFFFFD43B),
                                size: 16,
                              ),
                              SizedBox(width: 6),
                              Text(
                                '245',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontFamily: 'NType82-R',
                                      color: Color(0xFFFFD43B),
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 24),

                // Domain Stats Navbar - Tappable
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[700]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DomainDetailScreen(domain: 'critical_thinking'),
                            ),
                          );
                        },
                        child: _buildStatItem(
                          context,
                          icon: FontAwesomeIcons.gears,
                          iconColor: Color(0xFF74C0FC),
                          label: 'Critical',
                          score: criticalThinking,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.grey[700],
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DomainDetailScreen(domain: 'memory'),
                            ),
                          );
                        },
                        child: _buildStatItem(
                          context,
                          icon: FontAwesomeIcons.lightbulb,
                          iconColor: Color(0xFFFFD43B),
                          label: 'Memory',
                          score: memory,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.grey[700],
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DomainDetailScreen(domain: 'creativity'),
                            ),
                          );
                        },
                        child: _buildStatItem(
                          context,
                          icon: FontAwesomeIcons.squareShareNodes,
                          iconColor: Color(0xFF63E6BE),
                          label: 'Creativity',
                          score: creativity,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 32),

                // Overall Score - Enhanced
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _getScoreColor(average).withOpacity(0.15),
                        _getScoreColor(average).withOpacity(0.05),
                      ],
                    ),
                    border: Border.all(
                      color: _getScoreColor(average).withOpacity(0.5),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Overall Baseline Score',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontFamily: 'Lettera',
                                  color: Colors.grey[400],
                                  letterSpacing: 0.5,
                                ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            _getScoreLevel(average),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontFamily: 'Lettera',
                                  color: _getScoreColor(average),
                                  letterSpacing: 0.5,
                                ),
                          ),
                        ],
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: _getScoreColor(average).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${average.toStringAsFixed(1)}/100',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontFamily: 'NType82-R',
                                color: _getScoreColor(average),
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 32),

                // Cognitive Enhancement Modules Grid
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // First Row
                        Row(
                          children: [
                            Expanded(
                              child: _buildModuleContainer(
                                context,
                                title: 'Critical Thinking Index',
                                icon: FontAwesomeIcons.gears,
                                borderColor: Color(0xFF74C0FC),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _buildModuleContainer(
                                context,
                                title: 'Memory Efficiency Engine',
                                icon: FontAwesomeIcons.lightbulb,
                                borderColor: Color(0xFFFFD43B),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        // Second Row
                        Row(
                          children: [
                            Expanded(
                              child: _buildModuleContainer(
                                context,
                                title: 'Creativity Studio',
                                icon: FontAwesomeIcons.squareShareNodes,
                                borderColor: Color(0xFF63E6BE),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _buildModuleContainer(
                                context,
                                title: 'AI Laboratory',
                                icon: FontAwesomeIcons.flask,
                                borderColor: Color(0xFFA78BFA),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildModuleContainer(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color borderColor,
  }) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: borderColor.withOpacity(0.6),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
          color: borderColor.withOpacity(0.05),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              icon,
              color: borderColor,
              size: 32,
            ),
            SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontFamily: 'Ntype82-R',
                    color: borderColor,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required double score,
  }) {
    return Column(
      children: [
        FaIcon(
          icon,
          color: iconColor,
          size: 20,
        ),
        SizedBox(height: 8),
        Text(
          '${score.toStringAsFixed(0)}',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontFamily: 'NType82-R',
                color: _getScoreColor(score),
              ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: 'Lettera',
                color: Colors.grey[500],
              ),
        ),
      ],
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
                setState(() {
                  _currentNavIndex = 0;
                });
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
                Navigator.push(
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
                Navigator.push(
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
