import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../home/widgets/practice_bottom_sheet.dart';
import 'learn_repository.dart';
import 'learning_items.dart';
import 'widgets/learn_table_view.dart';
import 'widgets/learn_topic_list_view.dart';

class LearnDetailScreen extends StatefulWidget {
  final String topic;
  const LearnDetailScreen({super.key, required this.topic});

  @override
  State<LearnDetailScreen> createState() => _LearnDetailScreenState();
}

class _LearnDetailScreenState extends State<LearnDetailScreen> {
  late final LearnRepository _repo;
  late List<String> _items;

  bool _loading = true;
  bool _isReviewedToday = false;

  @override
  void initState() {
    super.initState();
    _repo = LearnRepository();
    _prepare();
  }

  Future<void> _prepare() async {
    _items = _generateItems(widget.topic);
    _isReviewedToday = await _repo.reviewedToday(widget.topic);
    setState(() => _loading = false);
  }

  Future<void> _toggleReviewed(bool? value) async {
    if (value == true) await _repo.markReviewed(widget.topic);
    setState(() => _isReviewedToday = value ?? false);
  }

  List<String> _generateItems(String topic) {
    switch (topic.toLowerCase()) {
      case 'tables':
      case 'tables 1-100':
        return LearningItems.tablesUpTo(upto: 100, maxMultiplier: 10);
      case 'squares':
        return LearningItems.squares(to: 100);
      case 'cubes':
        return LearningItems.cubes(to: 100);
      case 'square roots':
        return LearningItems.squareRoots(to: 100);
      case 'cube roots':
        return LearningItems.cubeRoots(to: 100);
      case 'percentage':
        return LearningItems.percentageExamples(from: 1, to: 20);
      default:
        return ['No data available for $topic'];
    }
  }

  void _startPractice(BuildContext context) {
    showPracticeBottomSheet(context, topic: widget.topic);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = AppTheme.adaptiveText(context);
    final accent = AppTheme.adaptiveAccent(context);

    final width = MediaQuery.of(context).size.width;
    final bool isTablet = width >= 900; // breakpoint for split layout
    final bool isSmallTablet = width >= 600 && width < 900;

    final isTableTopic = widget.topic.toLowerCase().contains('table');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.topic,
          style: TextStyle(
            color: textColor,
            fontSize: isTablet ? 24 : 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.adaptiveCard(context),
        iconTheme: IconThemeData(color: textColor),
      ),

      backgroundColor: theme.scaffoldBackgroundColor,

      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(isTablet ? 24 : 12),
              child: isTablet
                  ? _buildTabletLayout(context, isTableTopic, accent, textColor)
                  : _buildMobileLayout(
                      context,
                      isTableTopic,
                      accent,
                      textColor,
                    ),
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // 📱 MOBILE + SMALL TABLET LAYOUT (Single column)
  // ---------------------------------------------------------------------------

  Widget _buildMobileLayout(
    BuildContext context,
    bool isTableTopic,
    Color accent,
    Color textColor,
  ) {
    return Column(
      children: [
        _buildHeader(context, accent, textColor),
        const SizedBox(height: 12),
        Expanded(
          child: isTableTopic
              ? LearnTableView(topic: widget.topic)
              : LearnTopicListView(items: _items),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 🖥️ BIG TABLET LAYOUT (60% / 40% Split)
  // ---------------------------------------------------------------------------

  Widget _buildTabletLayout(
    BuildContext context,
    bool isTableTopic,
    Color accent,
    Color textColor,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LEFT COLUMN (60%) → Overview section
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, accent, textColor),
              const SizedBox(height: 24),

              Text(
                "Understanding the topic",
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              Text(
                "Review the fundamentals and examples. Marking a topic as reviewed helps build daily learning streak.",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: textColor.withOpacity(0.7),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 32),

        // RIGHT COLUMN (40%) → actual content list / tables
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: isTableTopic
                ? LearnTableView(topic: widget.topic)
                : LearnTopicListView(items: _items),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 🔝 Header Section (Review checkbox + Start Practice button)
  // ---------------------------------------------------------------------------

  Widget _buildHeader(BuildContext context, Color accent, Color textColor) {
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= 900;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 20 : 12,
        vertical: isTablet ? 16 : 10,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: isTablet
            ? MainAxisAlignment.spaceBetween
            : MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Checkbox(
                value: _isReviewedToday,
                activeColor: accent,
                onChanged: _toggleReviewed,
              ),
              Text(
                _isReviewedToday ? 'Reviewed today' : 'Mark as reviewed',
                style: TextStyle(
                  color: textColor,
                  fontSize: isTablet ? 17 : 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 20 : 14,
                vertical: isTablet ? 14 : 10,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: Icon(
              Icons.play_arrow_rounded,
              size: isTablet ? 24 : 20,
              color: Colors.white,
            ),
            label: Text(
              "Start Practice",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: isTablet ? 16 : 14,
                color: Colors.white,
              ),
            ),
            onPressed: () => _startPractice(context),
          ),
        ],
      ),
    );
  }
}
