import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rheto/models/module.dart';
import 'package:rheto/services/progress_service.dart';

class ModulesHubScreen extends StatefulWidget {
  const ModulesHubScreen({super.key});

  @override
  State<ModulesHubScreen> createState() => _ModulesHubScreenState();
}

class _ModulesHubScreenState extends State<ModulesHubScreen> {
  late Future<UserProgress> _progressFuture;
  final List<Module> modules = [
    Module.criticalThinking(),
    Module.memory(),
    Module.creativity(),
  ];

  @override
  void initState() {
    super.initState();
    _progressFuture = _loadProgress();
  }

  Future<UserProgress> _loadProgress() async {
    await ProgressService.resetDailyActivities();
    return ProgressService.getProgress();
  }

  IconData _getModuleIcon(String iconName) {
    switch (iconName) {
      case 'gears':
        return FontAwesomeIcons.gears;
      case 'lightbulb':
        return FontAwesomeIcons.lightbulb;
      case 'squareShareNodes':
        return FontAwesomeIcons.squareShareNodes;
      default:
        return FontAwesomeIcons.star;
    }
  }

  Color _getModuleColor(ModuleType type) {
    switch (type) {
      case ModuleType.criticalThinking:
        return Color(0xFF74C0FC);
      case ModuleType.memory:
        return Color(0xFFFFD43B);
      case ModuleType.creativity:
        return Color(0xFF63E6BE);
    }
  }

  String _getModuleTypeKey(ModuleType type) {
    switch (type) {
      case ModuleType.criticalThinking:
        return 'criticalThinking';
      case ModuleType.memory:
        return 'memory';
      case ModuleType.creativity:
        return 'creativity';
    }
  }

  void _navigateToActivity(Activity activity, Module module) {
    // Activity navigation to be implemented
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<UserProgress>(
        future: _progressFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFDA77F2)),
              ),
            );
          }

          if (!snapshot.hasData) {
            return Center(child: Text('Error loading progress'));
          }

          final progress = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 70),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      spacing: 16,
                      children: modules
                          .map(
                            (module) =>
                                _buildModuleCard(context, module, progress),
                          )
                          .toList(),
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

  Widget _buildModuleCard(
    BuildContext context,
    Module module,
    UserProgress progress,
  ) {
    final color = _getModuleColor(module.type);
    final moduleTypeKey = _getModuleTypeKey(module.type);
    final completedToday = progress.modulesCompletedToday[moduleTypeKey] ?? 0;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.6), width: 1.5),
        borderRadius: BorderRadius.circular(12),
        color: color.withOpacity(0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: FaIcon(
                      _getModuleIcon(module.icon),
                      color: color,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        module.name,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontFamily: 'Ntype82-R',
                          color: color,
                        ),
                      ),
                      Text(
                        module.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'Lettera',
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (completedToday > 0)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '✓ Done',
                    style: TextStyle(
                      color: color,
                      fontFamily: 'Lettera',
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 16),

          // Activities
          ...module.activities.map(
            (activity) => _buildActivityTile(context, activity, module, color),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTile(
    BuildContext context,
    Activity activity,
    Module module,
    Color color,
  ) {
    return GestureDetector(
      onTap: () => _navigateToActivity(activity, module),
      child: Container(
        padding: EdgeInsets.all(12),
        margin: EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[700]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.name,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(fontFamily: 'Ntype82-R'),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '⏱ ${activity.estimatedTime}min',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'Lettera',
                          color: Colors.grey[500],
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        '💰 +${activity.baseReward}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'Lettera',
                          color: Color(0xFFFFD43B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            FaIcon(FontAwesomeIcons.chevronRight, color: color, size: 16),
          ],
        ),
      ),
    );
  }
}
