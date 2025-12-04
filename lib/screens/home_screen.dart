import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rheto/services/score_storage_service.dart';
import 'package:rheto/services/progress_service.dart';
import 'package:rheto/models/module.dart';
import 'domain_detail_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'activities_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late Future<Map<String, dynamic>> _dashboardDataFuture;
  late PageController _pageController;
  int _currentNavIndex = 0;
  int _refreshKey = 0; // Used to force child widgets to rebuild

  @override
  void initState() {
    super.initState();
    _dashboardDataFuture = _loadDashboardData();
    _pageController = PageController();
    _pageController.addListener(_onPageChanged);
    WidgetsBinding.instance.addObserver(this);
  }

  void _onPageChanged() {
    setState(() {
      _currentNavIndex = _pageController.page?.round() ?? 0;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh dashboard data when app resumes (e.g., returning from background)
      _refreshDashboard();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.removeListener(_onPageChanged);
    _pageController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _loadDashboardData() async {
    final scores = await ScoreStorageService.getScores();
    final progress = await ProgressService.getProgress();
    return {'scores': scores, 'progress': progress};
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
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentNavIndex = index;
          });
          // Refresh dashboard when switching back to it
          if (index == 0) {
            _refreshDashboard();
          }
        },
        children: [
          _buildDashboardPage(),
          const ProfileScreen(),
          const SettingsScreen(),
        ],
      ),
    );
  }

  Widget _buildDashboardPage() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _dashboardDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFDA77F2)),
            ),
          );
        }

        if (!snapshot.hasData) {
          return Center(child: Text('Error loading dashboard'));
        }

        final data = snapshot.data!;
        final scores = data['scores'] as Map<String, double>;
        final progress = data['progress'] as UserProgress;

        final criticalThinking = scores['criticalThinking'] ?? 0.0;
        final memory = scores['memory'] ?? 0.0;
        final creativity = scores['creativity'] ?? 0.0;
        final average = (criticalThinking + memory + creativity) / 3;

        return SingleChildScrollView(
          child: Padding(
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
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(fontFamily: 'Ntype82-R'),
                    ),
                    Row(
                      children: [
                        // Streak Counter
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Color(0xFFFF922B).withOpacity(0.6),
                              width: 1.5,
                            ),
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
                                '${progress.currentStreak}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
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
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Color(0xFFFFD43B).withOpacity(0.6),
                              width: 1.5,
                            ),
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
                                '${progress.totalCoins}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
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

                // Domain Stats Navbar - Tappable (uses key to force rebuild on refresh)
                DomainStatsNavbar(key: ValueKey(_refreshKey)),

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
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  fontFamily: 'Lettera',
                                  color: Colors.grey[400],
                                  letterSpacing: 0.5,
                                ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            _getScoreLevel(average),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  fontFamily: 'Lettera',
                                  color: _getScoreColor(average),
                                  letterSpacing: 0.5,
                                ),
                          ),
                        ],
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: _getScoreColor(average).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${average.toStringAsFixed(1)}/100',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
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

                // Daily Goal Display
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
                        'Today\'s Goal',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'Lettera',
                          color: Colors.grey[500],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Complete one activity from each module to increase your streak',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(fontFamily: 'Lettera'),
                      ),
                      SizedBox(height: 16),
                      // Progress indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildProgressIndicator(
                            context,
                            'Critical',
                            progress.modulesCompletedToday['criticalThinking'] ??
                                0,
                            Color(0xFF74C0FC),
                          ),
                          _buildProgressIndicator(
                            context,
                            'Memory',
                            progress.modulesCompletedToday['memory'] ?? 0,
                            Color(0xFFFFD43B),
                          ),
                          _buildProgressIndicator(
                            context,
                            'Creativity',
                            progress.modulesCompletedToday['creativity'] ?? 0,
                            Color(0xFF63E6BE),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 32),

                // Cognitive Enhancement Modules Grid
                Column(
                  children: [
                    // First Row
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                _navigateToModule(ModuleType.criticalThinking),
                            child: _buildModuleContainer(
                              context,
                              title: 'Critical Thinking',
                              icon: FontAwesomeIcons.gears,
                              borderColor: Color(0xFF74C0FC),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _navigateToModule(ModuleType.memory),
                            child: _buildModuleContainer(
                              context,
                              title: 'Memory',
                              icon: FontAwesomeIcons.lightbulb,
                              borderColor: Color(0xFFFFD43B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    // Second Row
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                _navigateToModule(ModuleType.creativity),
                            child: _buildModuleContainer(
                              context,
                              title: 'Creativity',
                              icon: FontAwesomeIcons.squareShareNodes,
                              borderColor: Color(0xFF63E6BE),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                _navigateToModule(ModuleType.aiLaboratory),
                            child: _buildModuleContainer(
                              context,
                              title: 'AI Laboratory',
                              icon: FontAwesomeIcons.flask,
                              borderColor: Color(0xFFA78BFA),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateToModule(ModuleType moduleType) {
    final modules = [
      Module.criticalThinking(),
      Module.memory(),
      Module.creativity(),
      Module.aiLaboratory(),
    ];

    final module = modules.firstWhere((m) => m.type == moduleType);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ActivitiesScreen(module: module)),
    ).then((_) {
      // Refresh dashboard data when returning from activities
      _refreshDashboard();
    });
  }

  /// Public method to refresh dashboard data - can be called from anywhere
  void _refreshDashboard() {
    setState(() {
      _refreshKey++; // Increment to force DomainStatsNavbar rebuild
      _dashboardDataFuture = _loadDashboardData();
    });
  }

  Widget _buildProgressIndicator(
    BuildContext context,
    String label,
    int completed,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
            color: completed > 0 ? color.withOpacity(0.2) : Colors.transparent,
          ),
          child: Center(
            child: Text(
              completed > 0 ? '✓' : '○',
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(height: 8),
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
          border: Border.all(color: borderColor.withOpacity(0.6), width: 1.5),
          borderRadius: BorderRadius.circular(12),
          color: borderColor.withOpacity(0.05),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(icon, color: borderColor, size: 32),
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

  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[800]!, width: 1)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Home Tab
            GestureDetector(
              onTap: () {
                if (_currentNavIndex == 0) {
                  // Already on home, just refresh
                  _refreshDashboard();
                } else {
                  _pageController.animateToPage(
                    0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
              child: Padding(
                padding: EdgeInsets.all(12),
                child: FaIcon(
                  FontAwesomeIcons.house,
                  color: _currentNavIndex == 0
                      ? Color(0xFF63E6BE)
                      : Colors.grey[400],
                  size: 24,
                ),
              ),
            ),
            // Profile Tab
            GestureDetector(
              onTap: () {
                _pageController.animateToPage(
                  1,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: Padding(
                padding: EdgeInsets.all(12),
                child: FaIcon(
                  FontAwesomeIcons.circleUser,
                  color: _currentNavIndex == 1
                      ? Color(0xFF74C0FC)
                      : Colors.grey[400],
                  size: 24,
                ),
              ),
            ),
            // Settings Tab
            GestureDetector(
              onTap: () {
                _pageController.animateToPage(
                  2,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: Padding(
                padding: EdgeInsets.all(12),
                child: FaIcon(
                  FontAwesomeIcons.gear,
                  color: _currentNavIndex == 2
                      ? Color(0xFFFFD43B)
                      : Colors.grey[400],
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

/// Separate widget for domain stats navbar that refreshes independently
class DomainStatsNavbar extends StatefulWidget {
  const DomainStatsNavbar({super.key});

  @override
  State<DomainStatsNavbar> createState() => _DomainStatsNavbarState();
}

class _DomainStatsNavbarState extends State<DomainStatsNavbar> {
  late Future<Map<String, double>> _scoresFuture;

  @override
  void initState() {
    super.initState();
    _scoresFuture = ScoreStorageService.getScores();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh scores whenever dependencies change
    _scoresFuture = ScoreStorageService.getScores();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, double>>(
      future: _scoresFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox(height: 60);
        }

        final scores = snapshot.data!;
        final criticalThinking = scores['criticalThinking'] ?? 0.0;
        final memory = scores['memory'] ?? 0.0;
        final creativity = scores['creativity'] ?? 0.0;

        return Container(
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
                  ).then((_) {
                    // Refresh when returning from domain detail
                    setState(() {
                      _scoresFuture = ScoreStorageService.getScores();
                    });
                  });
                },
                child: _buildStatItem(
                  context,
                  icon: FontAwesomeIcons.gears,
                  iconColor: Color(0xFF74C0FC),
                  label: 'Critical',
                  score: criticalThinking,
                ),
              ),
              Container(width: 1, height: 40, color: Colors.grey[700]),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          DomainDetailScreen(domain: 'memory'),
                    ),
                  ).then((_) {
                    setState(() {
                      _scoresFuture = ScoreStorageService.getScores();
                    });
                  });
                },
                child: _buildStatItem(
                  context,
                  icon: FontAwesomeIcons.lightbulb,
                  iconColor: Color(0xFFFFD43B),
                  label: 'Memory',
                  score: memory,
                ),
              ),
              Container(width: 1, height: 40, color: Colors.grey[700]),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          DomainDetailScreen(domain: 'creativity'),
                    ),
                  ).then((_) {
                    setState(() {
                      _scoresFuture = ScoreStorageService.getScores();
                    });
                  });
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
        );
      },
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
        FaIcon(icon, color: iconColor, size: 20),
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

  Color _getScoreColor(double score) {
    if (score >= 80) return Color(0xFF63E6BE); // Green
    if (score >= 60) return Color(0xFFFFD43B); // Yellow
    if (score >= 40) return Color(0xFFFF922B); // Orange
    return Color(0xFFFF6B6B); // Red
  }
}
