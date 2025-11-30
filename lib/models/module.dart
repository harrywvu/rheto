enum ModuleType { criticalThinking, memory, creativity, aiLaboratory }

enum ActivityType {
  memoryRecall,
  ideaGeneration,
  logicalReasoning,
  patternRecognition,
  sequenceMemory,
  brainstorming,
  refinement,
  contradictionHunter,
  consequenceEngine,
  conceptCartographer,
}

class Module {
  final ModuleType type;
  final String name;
  final String description;
  final String icon;
  final List<Activity> activities;
  final int dailyTarget; // Number of activities to complete for streak

  Module({
    required this.type,
    required this.name,
    required this.description,
    required this.icon,
    required this.activities,
    this.dailyTarget = 1,
  });

  factory Module.criticalThinking() {
    return Module(
      type: ModuleType.criticalThinking,
      name: 'Critical Thinking',
      description: 'Enhance logical reasoning and analytical skills',
      icon: 'gears',
      activities: [
        Activity(
          id: 'ct_contradiction_hunter',
          type: ActivityType.contradictionHunter,
          name: 'Contradiction Hunter',
          description:
              'Detect logical conflicts hidden in micro-stories\n\nMetrics: Accuracy, Bias Detection, Cognitive Reflection, Justification Quality',
          difficulty: 'Medium',
          estimatedTime: 6,
          baseReward: 60,
        ),
        Activity(
          id: 'ct_logical_reasoning',
          type: ActivityType.logicalReasoning,
          name: 'Logical Reasoning',
          description:
              'Solve logic puzzles and deductive reasoning challenges\n\nMetrics: Logical Structure, Reasoning Accuracy, Problem-Solving Speed',
          difficulty: 'Medium',
          estimatedTime: 5,
          baseReward: 50,
        ),
      ],
    );
  }

  factory Module.memory() {
    return Module(
      type: ModuleType.memory,
      name: 'Memory',
      description: 'Improve recall accuracy and retention',
      icon: 'lightbulb',
      activities: [
        Activity(
          id: 'mem_recall',
          type: ActivityType.memoryRecall,
          name: 'Memory Recall',
          description:
              'Remember and recall a sequence of items\n\nMetrics: Accuracy Rate, Retention, Recall Speed',
          difficulty: 'Medium',
          estimatedTime: 4,
          baseReward: 50,
        ),
        Activity(
          id: 'mem_pattern',
          type: ActivityType.patternRecognition,
          name: 'Pattern Recognition',
          description:
              'Identify patterns in sequences and visual arrangements\n\nMetrics: Pattern Detection Accuracy, Speed, Complexity Recognition',
          difficulty: 'Medium',
          estimatedTime: 6,
          baseReward: 60,
        ),
        Activity(
          id: 'mem_sequence',
          type: ActivityType.sequenceMemory,
          name: 'Sequence Memory',
          description:
              'Reorder story events in the correct sequence\n\nMetrics: Recall Accuracy, Recall Latency, Retention Curve, Item Mastery',
          difficulty: 'Medium',
          estimatedTime: 5,
          baseReward: 55,
        ),
      ],
    );
  }

  factory Module.creativity() {
    return Module(
      type: ModuleType.creativity,
      name: 'Creativity',
      description: 'Develop divergent thinking and originality',
      icon: 'squareShareNodes',
      activities: [
        Activity(
          id: 'cr_idea_gen',
          type: ActivityType.ideaGeneration,
          name: 'Idea Generation',
          description:
              'Generate creative uses for everyday objects\n\nMetrics: Fluency, Flexibility, Originality, Refinement Quality',
          difficulty: 'Medium',
          estimatedTime: 5,
          baseReward: 50,
        ),
        Activity(
          id: 'cr_consequence_engine',
          type: ActivityType.consequenceEngine,
          name: 'Consequence Engine',
          description:
              'Trace cascading consequences across domains from absurd premises\n\nMetrics: Fluency, Flexibility, Originality, Refinement Gain',
          difficulty: 'Hard',
          estimatedTime: 8,
          baseReward: 75,
        ),
        Activity(
          id: 'cr_brainstorm',
          type: ActivityType.brainstorming,
          name: 'Brainstorming',
          description:
              'Collaborate on innovative solutions to real-world problems\n\nMetrics: Idea Quantity, Idea Quality, Innovation Index, Team Collaboration',
          difficulty: 'Medium',
          estimatedTime: 7,
          baseReward: 65,
        ),
      ],
    );
  }

  factory Module.aiLaboratory() {
    return Module(
      type: ModuleType.aiLaboratory,
      name: 'AI Laboratory',
      description: 'Explore advanced learning through AI-powered activities',
      icon: 'flask',
      activities: [
        Activity(
          id: 'ai_concept_cartographer',
          type: ActivityType.conceptCartographer,
          name: 'Concept Cartographer',
          description:
              'Build knowledge maps by assembling concept pieces, drawing connections, and teaching back\n\nMetrics: Conceptual Understanding, Connection Quality, Metacognitive Awareness',
          difficulty: 'Medium',
          estimatedTime: 12,
          baseReward: 0,
        ),
      ],
    );
  }
}

class Activity {
  final String id;
  final ActivityType type;
  final String name;
  final String description;
  final String difficulty;
  final int estimatedTime; // in minutes
  final int baseReward; // base currency reward

  Activity({
    required this.id,
    required this.type,
    required this.name,
    required this.description,
    required this.difficulty,
    required this.estimatedTime,
    required this.baseReward,
  });
}

class ActivityResult {
  final String activityId;
  final DateTime completedAt;
  final double score; // 0-100
  final int currencyEarned;
  final Map<String, dynamic> metrics; // Activity-specific metrics

  ActivityResult({
    required this.activityId,
    required this.completedAt,
    required this.score,
    required this.currencyEarned,
    required this.metrics,
  });

  Map<String, dynamic> toJson() {
    return {
      'activityId': activityId,
      'completedAt': completedAt.toIso8601String(),
      'score': score,
      'currencyEarned': currencyEarned,
      'metrics': metrics,
    };
  }

  factory ActivityResult.fromJson(Map<String, dynamic> json) {
    return ActivityResult(
      activityId: json['activityId'] as String,
      completedAt: DateTime.parse(json['completedAt'] as String),
      score: (json['score'] as num).toDouble(),
      currencyEarned: json['currencyEarned'] as int,
      metrics: json['metrics'] as Map<String, dynamic>,
    );
  }
}

class UserProgress {
  final int totalCoins;
  final int currentStreak;
  final DateTime lastActivityDate;
  final List<ActivityResult> completedActivities;
  final Map<String, int> modulesCompletedToday; // moduleType -> count
  final Map<String, Map<String, double>>
  baselineMetrics; // domain -> metric name -> value

  UserProgress({
    required this.totalCoins,
    required this.currentStreak,
    required this.lastActivityDate,
    required this.completedActivities,
    required this.modulesCompletedToday,
    this.baselineMetrics = const {
      'criticalThinking': {},
      'memory': {},
      'creativity': {},
    },
  });

  bool canIncreaseStreak() {
    // Check if user completed at least one activity from each of the 3 modules today
    return modulesCompletedToday.values.every((count) => count > 0);
  }

  Map<String, dynamic> toJson() {
    return {
      'totalCoins': totalCoins,
      'currentStreak': currentStreak,
      'lastActivityDate': lastActivityDate.toIso8601String(),
      'completedActivities': completedActivities
          .map((a) => a.toJson())
          .toList(),
      'modulesCompletedToday': modulesCompletedToday,
      'baselineMetrics': baselineMetrics.map(
        (domain, metrics) =>
            MapEntry(domain, metrics.map((k, v) => MapEntry(k, v))),
      ),
    };
  }

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    Map<String, Map<String, double>> _parseBaselineMetrics(
      Map<String, dynamic>? metricsJson,
    ) {
      if (metricsJson == null) {
        return {'criticalThinking': {}, 'memory': {}, 'creativity': {}};
      }
      return metricsJson.map(
        (domain, metrics) => MapEntry(
          domain,
          Map<String, double>.from(
            (metrics as Map).map((k, v) => MapEntry(k, (v as num).toDouble())),
          ),
        ),
      );
    }

    return UserProgress(
      totalCoins: json['totalCoins'] as int,
      currentStreak: json['currentStreak'] as int,
      lastActivityDate: DateTime.parse(json['lastActivityDate'] as String),
      completedActivities: (json['completedActivities'] as List)
          .map((a) => ActivityResult.fromJson(a as Map<String, dynamic>))
          .toList(),
      modulesCompletedToday: Map<String, int>.from(
        json['modulesCompletedToday'] as Map,
      ),
      baselineMetrics: _parseBaselineMetrics(
        json['baselineMetrics'] as Map<String, dynamic>?,
      ),
    );
  }
}
