import 'package:flutter/material.dart';
import '../screens/feature_detail_screen.dart';

class FeaturesSection extends StatelessWidget {
  final bool isDarkMode;

  const FeaturesSection({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final bgColor = isDarkMode ? Colors.grey[900] : Colors.grey[100];
    final cardColor = isDarkMode ? Colors.grey[850]! : Colors.white;

    final smartPractice = [
      {
        'icon': Icons.emoji_events_rounded,
        'title': 'Daily Ranked Quiz',
        'subtitle': 'Compete globally in 5 min',
        'color': Colors.amberAccent.withOpacity(0.25),
      },
      {
        'icon': Icons.loop_rounded,
        'title': 'Mixed Practice',
        'subtitle': 'Variety of random math sets',
        'color': Colors.lightBlueAccent.withOpacity(0.25),
      },
      {
        'icon': Icons.bar_chart_rounded,
        'title': 'Performance',
        'subtitle': 'Detailed progress insights',
        'color': Colors.greenAccent.withOpacity(0.25),
      },
      {
        'icon': Icons.lightbulb_rounded,
        'title': 'Tips & Tricks',
        'subtitle': 'Speed math shortcuts',
        'color': Colors.purpleAccent.withOpacity(0.25),
      },
      {
        'icon': Icons.local_fire_department_rounded,
        'title': 'Streak Challenge',
        'subtitle': 'Maintain daily practice',
        'color': Colors.deepOrangeAccent.withOpacity(0.25),
      },
    ];

    final basics = [
      {'icon': Icons.add, 'title': 'Addition'},
      {'icon': Icons.remove, 'title': 'Subtraction'},
      {'icon': Icons.clear, 'title': 'Multiplication'},
      {'icon': Icons.percent, 'title': 'Division'},
      {'icon': Icons.calculate, 'title': 'Percentage'},
      {'icon': Icons.show_chart, 'title': 'Average'},
      {'icon': Icons.square_foot, 'title': 'Square'},
      {'icon': Icons.widgets_outlined, 'title': 'Cube'},
      {'icon': Icons.square_outlined, 'title': 'Square Root'},
      {'icon': Icons.data_exploration, 'title': 'Cube Root'},
      {'icon': Icons.terrain, 'title': 'Trigonometry'},
      {'icon': Icons.table_chart, 'title': 'Tables'},
      {'icon': Icons.insights, 'title': 'Data Interpretation'},
      {'icon': Icons.category_rounded, 'title': 'Mixed Questions'},
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Smart Practice',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.4,
            children: smartPractice.map((item) {
              return _smartCard(
                context,
                item['icon'] as IconData,
                item['title'] as String,
                item['subtitle'] as String,
                cardColor,
                item['color'] as Color,
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Text(
            'Master Basics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 10),
          _buildGrid(context, basics, bgColor),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // -----------------------------------------------
  // ✅ Bottom sheet for number range & question count
  // -----------------------------------------------
  void _showPracticeDialog(BuildContext context, String topic) {
    final TextEditingController minCtrl = TextEditingController(text: '0');
    final TextEditingController maxCtrl = TextEditingController(text: '100');
    double questionCount = 10;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 24,
          ),
          child: StatefulBuilder(
            builder: (context, setState) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Practice $topic',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),

                // Range input fields
                // 🔹 Range input fields (Dark/Light mode adaptive)
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: minCtrl,
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Min number',
                          labelStyle: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                          filled: true,
                          fillColor: isDarkMode
                              ? Colors.grey[850]
                              : Colors.grey[200], // ✅ adaptive
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDarkMode
                                  ? Colors.white24
                                  : Colors.black26,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDarkMode
                                  ? Colors.orangeAccent
                                  : Colors.blueAccent,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: maxCtrl,
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Max number',
                          labelStyle: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                          filled: true,
                          fillColor: isDarkMode
                              ? Colors.grey[850]
                              : Colors.grey[200], // ✅ adaptive
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDarkMode
                                  ? Colors.white24
                                  : Colors.black26,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDarkMode
                                  ? Colors.orangeAccent
                                  : Colors.blueAccent,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Question count slider
                Text(
                  'Number of Questions: ${questionCount.toInt()}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                Slider(
                  value: questionCount,
                  min: 5,
                  max: 30,
                  divisions: 5,
                  activeColor: isDarkMode
                      ? Colors.orangeAccent
                      : Colors.blueAccent,
                  onChanged: (value) {
                    setState(() => questionCount = value);
                  },
                ),

                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode
                          ? Colors.orangeAccent
                          : Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      // 🔹 Use these values in your generator logic
                      final int min = int.tryParse(minCtrl.text) ?? 0;
                      final int max = int.tryParse(maxCtrl.text) ?? 100;
                      final int count = questionCount.toInt();

                      // Pass to your question generator screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FeatureDetailScreen(
                            title: "$topic ($min-$max, $count questions)",
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      'Start Practice',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  // -----------------------------------------------
  // ✅ Grid for Master Basics with dialog trigger
  // -----------------------------------------------
  Widget _buildGrid(
    BuildContext context,
    List<Map<String, dynamic>> items,
    Color? bgColor,
  ) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: items.map((item) {
        return _featureTile(
          context,
          item['icon'] as IconData,
          item['title'] as String,
          bgColor,
        );
      }).toList(),
    );
  }

  Widget _featureTile(
    BuildContext context,
    IconData icon,
    String title,
    Color? bgColor,
  ) {
    return InkWell(
      onTap: () {
        _showPracticeDialog(context, title);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 26,
              color: isDarkMode ? Colors.orangeAccent : Colors.blueAccent,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // smart cards stay same
  Widget _smartCard(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Color baseColor,
    Color accentColor,
  ) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => FeatureDetailScreen(title: title)),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [accentColor, baseColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(
              icon,
              size: 28,
              color: isDarkMode ? Colors.orangeAccent : Colors.blueAccent,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode
                          ? Colors.white70
                          : Colors.black.withOpacity(0.6),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
