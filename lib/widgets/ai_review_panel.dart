import 'package:flutter/material.dart';

class AIReviewItem {
  final String title;
  final String content;
  final IconData icon;
  final Color iconColor;

  AIReviewItem({
    required this.title,
    required this.content,
    required this.icon,
    this.iconColor = const Color(0xFF74C0FC),
  });
}

class AIReviewPanel extends StatefulWidget {
  final String activityName;
  final String overallInsight;
  final List<AIReviewItem> reviewItems;
  final VoidCallback onClose;

  const AIReviewPanel({
    Key? key,
    required this.activityName,
    required this.overallInsight,
    required this.reviewItems,
    required this.onClose,
  }) : super(key: key);

  @override
  State<AIReviewPanel> createState() => _AIReviewPanelState();
}

class _AIReviewPanelState extends State<AIReviewPanel> {
  final Map<int, bool> _expandedItems = {};

  @override
  void initState() {
    super.initState();
    // Initialize all items as collapsed
    for (int i = 0; i < widget.reviewItems.length; i++) {
      _expandedItems[i] = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Color(0xFF74C0FC), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[700]!),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  color: Color(0xFF74C0FC),
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'AI Review & Coaching',
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(
                                        fontFamily: 'Ntype82-R',
                                        color: Color(0xFF74C0FC),
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.activityName,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    fontFamily: 'Lettera',
                                    color: Colors.grey[400],
                                  ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: widget.onClose,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.close,
                            color: Colors.grey[400],
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Overall Insight
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[700]!),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Overall Insights',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontFamily: 'Ntype82-R',
                          color: Colors.grey[400],
                          fontSize: 12,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xFF74C0FC).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Color(0xFF74C0FC).withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          widget.overallInsight,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontFamily: 'Lettera',
                                color: Colors.grey[200],
                                height: 1.6,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Collapsible Review Items
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detailed Feedback',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontFamily: 'Ntype82-R',
                          color: Colors.grey[400],
                          fontSize: 12,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...List.generate(
                        widget.reviewItems.length,
                        (index) => _buildReviewItem(context, index),
                      ),
                    ],
                  ),
                ),

                // Close Button
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: widget.onClose,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF74C0FC),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Back to Activities',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.black,
                          fontFamily: 'Ntype82-R',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewItem(BuildContext context, int index) {
    final item = widget.reviewItems[index];
    final isExpanded = _expandedItems[index] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[800]?.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _expandedItems[index] = !isExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: item.iconColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(item.icon, color: item.iconColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontFamily: 'Ntype82-R',
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[700]!)),
              ),
              child: Text(
                item.content,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'Lettera',
                  color: Colors.grey[300],
                  height: 1.6,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
