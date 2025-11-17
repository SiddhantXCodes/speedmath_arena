//lib/features/learn_daily/learn_tile.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'learn_repository.dart';

class LearnTile extends StatefulWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const LearnTile({
    super.key,
    required this.title,
    required this.onTap,
    this.subtitle = '',
  });

  @override
  State<LearnTile> createState() => _LearnTileState();
}

class _LearnTileState extends State<LearnTile> {
  final _repo = LearnRepository();
  bool _reviewedToday = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final v = await _repo.reviewedToday(widget.title);
    if (mounted) setState(() => _reviewedToday = v);
  }

  @override
  Widget build(BuildContext context) {
    final textColor = AppTheme.adaptiveText(context);
    final accent = AppTheme.adaptiveAccent(context);

    return ListTile(
      onTap: widget.onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      tileColor: AppTheme.adaptiveCard(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: CircleAvatar(
        backgroundColor: accent.withOpacity(0.18),
        child: Icon(Icons.auto_stories, color: accent),
      ),
      title: Text(
        widget.title,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
      ),
      subtitle: widget.subtitle.isEmpty
          ? null
          : Text(
              widget.subtitle,
              style: TextStyle(color: textColor.withOpacity(0.7)),
            ),
      trailing: _reviewedToday
          ? Chip(
              label: Text(
                'Done',
                style: TextStyle(color: AppTheme.adaptiveText(context)),
              ),
              backgroundColor: accent.withOpacity(0.12),
            )
          : Chip(
              label: Text(
                'Pending',
                style: TextStyle(color: AppTheme.adaptiveText(context)),
              ),
              backgroundColor: Colors.orange.withOpacity(0.12),
            ),
    );
  }
}
