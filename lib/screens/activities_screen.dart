import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rheto/models/module.dart';
import 'package:rheto/screens/contradiction_hunter_screen.dart';
import 'package:rheto/screens/sequence_memory_screen.dart';
import 'package:rheto/screens/consequence_engine_screen.dart';
import 'package:rheto/screens/concept_cartographer_screen.dart';
import 'package:rheto/services/progress_service.dart';

class ActivitiesScreen extends StatefulWidget {
  final Module module;

  const ActivitiesScreen({super.key, required this.module});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.module.name),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Module Header
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[700]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.module.name,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(fontFamily: 'Ntype82-R'),
                  ),
                  SizedBox(height: 8),
                  Text(
                    widget.module.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: 'Lettera',
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),

            // Activities Section
            Text(
              'Activities',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontFamily: 'Ntype82-R'),
            ),
            SizedBox(height: 16),

            // Activity List
            ...List.generate(
              widget.module.activities.length,
              (index) =>
                  _buildActivityCard(context, widget.module.activities[index]),
            ),

            SizedBox(height: 24),

            // More Activities Coming Soon
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey[600]!,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[900]?.withOpacity(0.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FaIcon(
                    FontAwesomeIcons.ellipsis,
                    color: Colors.grey[500],
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'More activities coming soon',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: 'Lettera',
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(BuildContext context, Activity activity) {
    final color = _getActivityColor(activity.difficulty);

    return GestureDetector(
      onTap: () => _showActivityModal(context, activity),
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.6), width: 1.5),
          borderRadius: BorderRadius.circular(12),
          color: color.withOpacity(0.08),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.name,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontFamily: 'Ntype82-R',
                          color: color,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        activity.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'Lettera',
                          color: Colors.grey[400],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12),
                FaIcon(FontAwesomeIcons.chevronRight, color: color, size: 20),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    activity.difficulty,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: 'Lettera',
                      color: color,
                      fontSize: 11,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                FaIcon(
                  FontAwesomeIcons.clock,
                  color: Colors.grey[500],
                  size: 14,
                ),
                SizedBox(width: 4),
                Text(
                  '${activity.estimatedTime} min',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'Lettera',
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showActivityModal(BuildContext context, Activity activity) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) =>
            _buildActivityModal(context, activity, setModalState),
      ),
    );
  }

  Widget _buildActivityModal(
    BuildContext context,
    Activity activity,
    StateSetter setModalState,
  ) {
    final color = _getActivityColor(activity.difficulty);
    final minReward = activity.baseReward;
    final maxReward = (activity.baseReward * 1.5).toInt();
    final cost = activity.type == ActivityType.conceptCartographer ? 15.0 : 0.0;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.name,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontFamily: 'Ntype82-R',
                          fontSize: 24,
                          color: color,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        activity.difficulty,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'Lettera',
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: FaIcon(
                    FontAwesomeIcons.xmark,
                    color: Colors.grey[400],
                    size: 24,
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),

            // Description Section
            _buildModalSection(
              context,
              icon: FontAwesomeIcons.bookOpen,
              title: 'About',
              content: activity.description,
              color: color,
            ),
            SizedBox(height: 20),

            // How to Play Section
            _buildModalSection(
              context,
              icon: FontAwesomeIcons.gamepad,
              title: 'How to Play',
              content: _getHowToPlayText(activity),
              color: color,
            ),
            SizedBox(height: 20),

            // Purpose Section
            _buildModalSection(
              context,
              icon: FontAwesomeIcons.bullseye,
              title: 'Purpose',
              content: _getPurposeText(activity),
              color: color,
            ),
            SizedBox(height: 20),

            // Cost Section (if applicable)
            if (cost > 0)
              _buildCostSection(context, cost)
            else
              const SizedBox.shrink(),

            if (cost > 0) const SizedBox(height: 20),

            // Rewards Section (only show if baseReward > 0)
            if (activity.baseReward > 0)
              Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Color(0xFFFFD43B).withOpacity(0.6),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: Color(0xFFFFD43B).withOpacity(0.08),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            FaIcon(
                              FontAwesomeIcons.coins,
                              color: Color(0xFFFFD43B),
                              size: 18,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'In-App Currency Reward',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    fontFamily: 'Ntype82-R',
                                    color: Color(0xFFFFD43B),
                                  ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Minimum',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          fontFamily: 'Lettera',
                                          color: Colors.grey[500],
                                        ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '$minReward',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          fontFamily: 'NType82-R',
                                          color: Color(0xFFFFD43B),
                                        ),
                                  ),
                                ],
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: Colors.grey[700],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Maximum',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          fontFamily: 'Lettera',
                                          color: Colors.grey[500],
                                        ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '$maxReward',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          fontFamily: 'NType82-R',
                                          color: Color(0xFFFFD43B),
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Earn more by performing better!',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontFamily: 'Lettera',
                                color: Colors.grey[500],
                                fontSize: 11,
                              ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                ],
              )
            else
              const SizedBox.shrink(),

            // Play Button
            if (cost > 0)
              FutureBuilder<UserProgress>(
                future: ProgressService.getProgress(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFFDA77F2),
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error loading balance'));
                  }

                  // Use ProgressService for balance check (single source of truth)
                  if (!snapshot.hasData) {
                    return Center(child: Text('Loading balance...'));
                  }
                  final progress = snapshot.data!;
                  final hasEnough = progress.totalCoins >= cost;

                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: hasEnough
                          ? () async {
                              // Deduct currency from ProgressService (single source of truth)
                              final updatedProgress = UserProgress(
                                totalCoins: progress.totalCoins - cost.round(),
                                currentStreak: progress.currentStreak,
                                lastActivityDate: progress.lastActivityDate,
                                completedActivities:
                                    progress.completedActivities,
                                modulesCompletedToday:
                                    progress.modulesCompletedToday,
                                baselineMetrics: progress.baselineMetrics,
                              );
                              await ProgressService.saveProgress(
                                updatedProgress,
                              );

                              Navigator.pop(context);
                              _navigateToActivity(activity);
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasEnough ? color : Colors.grey[700],
                        disabledBackgroundColor: Colors.grey[700],
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FaIcon(
                            hasEnough
                                ? FontAwesomeIcons.play
                                : FontAwesomeIcons.lock,
                            color: hasEnough ? Colors.black : Colors.grey[500],
                            size: 16,
                          ),
                          SizedBox(width: 12),
                          Text(
                            hasEnough ? 'Play Activity' : 'Insufficient Coins',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontFamily: 'Ntype82-R',
                                  color: hasEnough
                                      ? Colors.black
                                      : Colors.grey[500],
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    // Free activity - just navigate
                    Navigator.pop(context);
                    _navigateToActivity(activity);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FaIcon(
                        FontAwesomeIcons.play,
                        color: Colors.black,
                        size: 16,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Play Activity',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontFamily: 'Ntype82-R',
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
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

  Widget _buildCostSection(BuildContext context, double cost) {
    return FutureBuilder<UserProgress>(
      future: ProgressService.getProgress(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFDA77F2)),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error loading balance'));
        }

        // Use ProgressService for balance display (single source of truth)
        if (!snapshot.hasData) {
          return Center(child: Text('Loading balance...'));
        }
        final progress = snapshot.data!;
        final hasEnough = progress.totalCoins >= cost;
        final themeColor = hasEnough ? Color(0xFF63E6BE) : Colors.red;

        return Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: themeColor.withOpacity(0.6), width: 1.5),
            borderRadius: BorderRadius.circular(12),
            color: themeColor.withOpacity(0.08),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  FaIcon(FontAwesomeIcons.coins, color: themeColor, size: 18),
                  SizedBox(width: 12),
                  Text(
                    'Cost to Play',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: 'Ntype82-R',
                      color: themeColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Required',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'Lettera',
                        color: Colors.grey[500],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${cost.toInt()}',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontFamily: 'NType82-R',
                            color: themeColor,
                          ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8),
              Text(
                hasEnough
                    ? 'You have enough coins to play!'
                    : 'Insufficient coins! Complete other activities to earn more.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'Lettera',
                  color: hasEnough ? Color(0xFF63E6BE) : Colors.red,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModalSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            FaIcon(icon, color: color, size: 18),
            SizedBox(width: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamily: 'Ntype82-R',
                color: color,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            content,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontFamily: 'Lettera',
              color: Colors.grey[300],
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Color _getActivityColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Color(0xFF63E6BE);
      case 'medium':
        return Color(0xFF74C0FC);
      case 'hard':
        return Color(0xFFFF922B);
      default:
        return Color(0xFF74C0FC);
    }
  }

  String _getHowToPlayText(Activity activity) {
    switch (activity.type) {
      case ActivityType.contradictionHunter:
        return 'Read a short story carefully. Identify all the logical contradictions hidden within it. Select the contradictions you found and write a detailed justification explaining why they are contradictions.';
      case ActivityType.sequenceMemory:
        return 'Reorder story events in the correct sequence. Drag and drop event cards to arrange them chronologically, then submit to see your recall accuracy.';
      case ActivityType.consequenceEngine:
        return 'Given an absurd premise, trace 4 levels of cascading consequences across domains: Personal → Social → Economic → Ecological. Each consequence must logically flow from the previous level. Complete 2 full chains to finish. You can also remix from any level to explore alternate paths.';
      case ActivityType.conceptCartographer:
        return 'Build a knowledge map through 4 phases: (1) Share what you know about a topic, (2) Arrange concept pieces and draw connections, (3) Test your model with a scenario, (4) Teach back the concept in your own words. AI provides feedback at each step.';
      default:
        return 'Complete the activity by following the on-screen instructions.';
    }
  }

  String _getPurposeText(Activity activity) {
    switch (activity.type) {
      case ActivityType.contradictionHunter:
        return 'Strengthen your ability to detect logical inconsistencies and hidden contradictions. This activates your brain\'s error-monitoring system and improves critical reasoning.';
      case ActivityType.sequenceMemory:
        return 'Strengthen sequential memory and temporal reasoning through event ordering. This enhances hippocampal activity and supports memory consolidation.';
      case ActivityType.consequenceEngine:
        return 'Develop causal imagination and cross-domain thinking. This activates your Default Mode Network for mental simulation and strengthens DMN-FPN coupling for creative evaluation. Learn to trace complex consequences and think beyond obvious implications.';
      case ActivityType.conceptCartographer:
        return 'Develop deep conceptual understanding through active knowledge construction. Retrieval practice activates prior knowledge, generative learning builds mental models, and metacognitive monitoring strengthens awareness of understanding gaps. This enhances long-term retention and transfer of knowledge.';
      default:
        return 'Enhance your cognitive abilities in this domain.';
    }
  }

  void _navigateToActivity(Activity activity) {
    switch (activity.type) {
      case ActivityType.contradictionHunter:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ContradictionHunterScreen(
              activity: activity,
              module: widget.module,
              onComplete: () {
                Navigator.pop(context);
              },
            ),
          ),
        );
        break;
      case ActivityType.sequenceMemory:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SequenceMemoryScreen(
              activity: activity,
              module: widget.module,
              onComplete: () {
                Navigator.pop(context);
              },
            ),
          ),
        );
        break;
      case ActivityType.consequenceEngine:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConsequenceEngineScreen(
              activity: activity,
              module: widget.module,
              onComplete: () {
                Navigator.pop(context);
              },
            ),
          ),
        );
        break;
      case ActivityType.conceptCartographer:
        _handleConceptCartographerNavigation(activity);
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${activity.name} coming soon!')),
        );
    }
  }

  Future<void> _handleConceptCartographerNavigation(Activity activity) async {
    const requiredCoins = 15;
    final progress = await ProgressService.getProgress();

    if (progress.totalCoins < requiredCoins) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Insufficient coins! You need $requiredCoins coins to play this activity.',
            ),
            backgroundColor: Colors.red[700],
          ),
        );
      }
      return;
    }

    // Deduct coins using ProgressService (single source of truth)
    final updatedProgress = UserProgress(
      totalCoins: progress.totalCoins - requiredCoins,
      currentStreak: progress.currentStreak,
      lastActivityDate: progress.lastActivityDate,
      completedActivities: progress.completedActivities,
      modulesCompletedToday: progress.modulesCompletedToday,
      baselineMetrics: progress.baselineMetrics,
    );
    await ProgressService.saveProgress(updatedProgress);

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ConceptCartographerScreen(
            activity: activity,
            module: widget.module,
            onComplete: () {
              Navigator.pop(context);
            },
          ),
        ),
      );
    }
  }
}
