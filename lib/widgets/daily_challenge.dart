import 'dart:async';
import 'dart:math';

import 'package:cube_off/utils/solve.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../app_state.dart';
import '../utils/string_helpers.dart';
import '../services/leaderboard_service.dart';
import '../models/solve_record.dart';
import '../services/scramble_service.dart';
import '../timer.dart';
import 'archive_page.dart';
import 'practice_tile.dart';
// removed unused import

class DailyChallenge extends StatefulWidget {
  const DailyChallenge({super.key});

  @override
  State<DailyChallenge> createState() => _DailyChallengeState();
}

class _DailyChallengeState extends State<DailyChallenge> {
  Timer? _timer;
  Timer? _holdTimer;

  final LeaderboardService _leaderboard = LeaderboardService();
  List<SolveRecord> _topSolves = [];
  bool _loadingLeaderboard = false;
  final ScrambleService _scrambleService = ScrambleService();
  Map<String, SolveRecord?> _mySubmissions = {};
  PageController? _pageController;
  List<DateTime> _weekDates = [];
  Map<String, String> _scrambles = {};

  @override
  void initState() {
    super.initState();
    _weekDates = List.generate(
      7,
      (i) => DateTime.now().subtract(Duration(days: i)),
    );
    _pageController = PageController(viewportFraction: 0.92);
    _loadWeekScrambles();
    _refreshLeaderboard();
    _loadMySubmissions();
  }

  Future<void> _refreshLeaderboard() async {
    if (!mounted) return;
    setState(() => _loadingLeaderboard = true);
    final now = DateTime.now();
    final id =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    try {
      final list = await _leaderboard.fetchDailyLeaderboard(id, limit: 5);
      if (!mounted) return;
      setState(() => _topSolves = list);
    } catch (_) {}
    if (mounted) setState(() => _loadingLeaderboard = false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _holdTimer?.cancel();
    _pageController?.dispose();
    super.dispose();
  }

  Future<void> _loadWeekScrambles() async {
    final Map<String, String> m = {};
    for (final d in _weekDates) {
      try {
        final s = await _scrambleService.getScrambleForDate(d);
        final id =
            '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        if (s != null) m[id] = s.scramble;
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _scrambles = m;
    });
  }

  Future<void> _loadMySubmissions() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      if (!mounted) return;
      setState(() => _mySubmissions = {});
      return;
    }

    final Map<String, SolveRecord?> found = {};
    for (final d in _weekDates) {
      final id =
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      try {
        final rec = await _leaderboard.fetchUserSubmission(id, userId);
        found[id] = rec;
      } catch (_) {
        found[id] = null;
      }
    }

    if (!mounted) return;
    setState(() => _mySubmissions = found);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good ${_greeting()}.',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Welcome to your new place to solve.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          SizedBox(
            height: 200,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final viewportWidth = constraints.maxWidth;
                // using viewportWidth directly for slot calculations
                const innerPad = 6.0;

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _weekDates.length,
                  itemBuilder: (context, i) {
                    final d = _weekDates[i];
                    final id =
                        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
                    final scramble = _scrambles[id] ?? '';

                    // Determine sizes relative to viewport so there are no giant gaps.
                    final recentSlot = (viewportWidth * 0.8).clamp(
                      0.0,
                      viewportWidth,
                    );
                    final pastSlot = (viewportWidth * 0.45).clamp(
                      0.0,
                      viewportWidth,
                    );
                    final itemSlotWidth = i == 0 ? recentSlot : pastSlot;
                    final rawContentWidth = (itemSlotWidth - (innerPad * 2))
                        .clamp(0.0, viewportWidth);
                    final maxSlotHeight = constraints.maxHeight;
                    // recent card takes full available height; past cards are square but not taller than the slot
                    final contentWidth = rawContentWidth;
                    final contentHeight = i == 0
                        ? maxSlotHeight
                        : min(contentWidth, maxSlotHeight);

                    final mySubmission = _mySubmissions[id];
                    return SizedBox(
                      width: itemSlotWidth,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: innerPad,
                        ),
                        child: GestureDetector(
                          onTap: () => _openReadyScreen(d, scramble),
                          child: Center(
                            child: SizedBox(
                              width: contentWidth,
                              height: contentHeight,
                              child: Stack(
                                children: [
                                  _buildCardContent(context, d, scramble),
                                  if (mySubmission != null)
                                    Positioned(
                                      right: 6,
                                      top: 6,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          mySubmission.formattedTime(),
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                onPressed: () {
                  // Packs placeholder
                },
                child: const Text('Packs'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ArchivePage()),
                  );
                },
                child: const Text('Archive'),
              ),
            ],
          ),

          // Practice tile (opens full timer/results page)
          const SizedBox(height: 12),
          const PracticeTile(),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildCardContent(BuildContext context, DateTime d, String scramble) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withAlpha(242),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Daily Scramble',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.grid_on, color: Colors.black),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Flexible(
            child: Text(
              scramble,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              overflow: TextOverflow.ellipsis,
              maxLines: 4,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  formatDate(d),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }

  void _openReadyScreen(DateTime date, String scramble) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bg = Theme.of(context).colorScheme.primary;
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.98,
          child: Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16,
                ),
                child: Column(
                  children: [
                    // Back arrow
                    Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        color: Colors.white,
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ),
                    const Spacer(),
                    // Icon
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.grid_on,
                        size: 30,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Daily Scramble',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                    ),
                    const SizedBox(height: 24),
                    // Scramble preview
                    SizedBox(
                      width: double.infinity,
                      child: SelectableText(
                        scramble,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Play button
                    SizedBox(
                      width: 140,
                      height: 40,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: const StadiumBorder(),
                        ),
                        onPressed: () async {
                          // Before starting, check if the user already submitted for this date.
                          final now = date;
                          final id =
                              '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
                          bool already = false;
                          try {
                            already = await _leaderboard.hasUserSubmitted(
                              id,
                              FirebaseAuth.instance.currentUser?.uid ?? '',
                            );
                          } catch (_) {
                            // ignore errors here; fall back to letting the user try to submit.
                          }

                          if (already) {
                            if (!mounted) return;
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'You already submitted a solve for this day.',
                                ),
                              ),
                            );
                            return;
                          }

                          Navigator.pop(ctx);
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => TimerLauncherPage(
                                scramble: scramble,
                                scrambleDate: date,
                              ),
                            ),
                          );

                          _refreshLeaderboard();
                          _loadMySubmissions();
                        },
                        child: const Text('Solve'),
                      ),
                    ),

                    const SizedBox(height: 28),
                    // Date and byline
                    Text(
                      formatDate(date),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(flex: 2),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class TimerLauncherPage extends StatelessWidget {
  final String scramble;
  final DateTime scrambleDate;
  const TimerLauncherPage({
    required this.scramble,
    required this.scrambleDate,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daily Scramble')),
      body: TimerPage(
        onTimerRunningChanged: (_) {},
        dailyMode: true,
        providedScramble: scramble,
        providedScrambleDate: scrambleDate,
        onSolveAdded: (solve) async {
          // Open a confirmation screen where user can adjust penalty and confirm submission.
          if (!context.mounted) return;
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DailySolveConfirmPage(solve: solve),
            ),
          );
          // After the confirmation page completes, the confirmation page itself
          // will handle submission and pop back to the appropriate screen.
        },
      ),
    );
  }
}

class DailySolveConfirmPage extends StatefulWidget {
  final Solve solve;
  const DailySolveConfirmPage({required this.solve, super.key});

  @override
  State<DailySolveConfirmPage> createState() => _DailySolveConfirmPageState();
}

class _DailySolveConfirmPageState extends State<DailySolveConfirmPage> {
  late Penalty _selectedPenalty;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // Default confirmation penalty to OK for daily submissions.
    _selectedPenalty = Penalty.ok;
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final appState = Provider.of<AppState>(context, listen: false);
    try {
      await appState.submitDailySolve(
        widget.solve.time.duration,
        _selectedPenalty.name,
        scramble: widget.solve.scramble,
        scrambleDate: widget.solve.date,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Daily solve submitted: ${formatDuration(widget.solve.time.duration)}',
          ),
        ),
      );
      // Pop confirmation page and the timer page (two levels)
      Navigator.of(context).pop();
      Navigator.of(context).pop();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit daily solve: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Daily Solve')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Scramble', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SelectableText(
              widget.solve.scramble,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
            const SizedBox(height: 16),
            Text('Time', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              formatDuration(widget.solve.time.duration),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text('Penalty', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<Penalty>(
              showSelectedIcon: false,
              segments: const <ButtonSegment<Penalty>>[
                ButtonSegment(value: Penalty.ok, label: Text('OK')),
                ButtonSegment(value: Penalty.plusTwo, label: Text('+2')),
                ButtonSegment(value: Penalty.dnf, label: Text('DNF')),
              ],
              selected: <Penalty>{_selectedPenalty},
              onSelectionChanged: (Set<Penalty> newSel) {
                setState(() => _selectedPenalty = newSel.first);
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Confirm & Submit'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _submitting ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
