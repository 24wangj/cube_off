import 'package:flutter/material.dart';
import '../timer.dart';
import '../results.dart';

// removed unused import
class Practice extends StatefulWidget {
  const Practice({super.key});

  @override
  State<Practice> createState() => _PracticeState();
}

class _PracticeState extends State<Practice> {
  String _view = 'timer';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SegmentedButton<String>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 'timer', label: Text('Timer')),
                ButtonSegment(value: 'results', label: Text('Results')),
              ],
              selected: <String>{_view},
              onSelectionChanged: (Set<String> s) =>
                  setState(() => _view = s.first),
            ),
          ],
        ),
        Expanded(
          child: _view == 'timer'
              ? _buildTimer(context)
              : Container(
                  color: theme.colorScheme.surface,
                  child: const ResultsPage(),
                ),
        ),
      ],
    );
  }

  Widget _buildTimer(BuildContext context) {
    return TimerPage(
      onTimerRunningChanged: (_) {},
      onSolveAdded: (solve) {
        // When practicing, we add solves to global app state (so results update)
        // TimerPage already adds solves when not in dailyMode; this callback
        // can be used for additional UI feedback.
        if (!context.mounted) return;
      },
    );
  }
}
