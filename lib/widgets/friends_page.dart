import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// app_state not required in this file
import '../services/friend_service.dart';
import '../services/leaderboard_service.dart';
import '../models/solve_record.dart';
import 'friend_requests_page.dart';
import 'friend_profile_page.dart';
import '../utils/string_helpers.dart';

class FriendsPageWidget extends StatefulWidget {
  const FriendsPageWidget({super.key});

  @override
  State<FriendsPageWidget> createState() => _FriendsPageState();
}

class _FriendEntry {
  final String uid;
  final String displayName;
  final String? email;
  final SolveRecord? solve;
  int? rank; // 1-based rank for entries with numeric times

  _FriendEntry({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.solve,
    this.rank,
  });
}

class _FriendsPageState extends State<FriendsPageWidget> {
  bool _loading = true;
  List<_FriendEntry> _friendTimes = [];
  DateTime _selectedDate = DateTime.now();
  final FriendService _friendService = FriendService();
  final TextEditingController _addController = TextEditingController();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final LeaderboardService _leaderboardService = LeaderboardService();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() {
        _friendTimes = [];
        _loading = false;
      });
      return;
    }

    final friendIds = await _friendService.getFriendIds(uid);

    final ids = <String>{};
    ids.add(uid);
    ids.addAll(friendIds);

    final d = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final dailyId =
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    final entries = <_FriendEntry>[];

    for (final id in ids) {
      String display = id;
      String? email;
      try {
        final doc = await _db.collection('users').doc(id).get();
        final data = doc.data();
        if (data != null) {
          if (data['displayName'] is String) {
            display = data['displayName'] as String;
          }
          if (data['email'] is String) {
            email = data['email'] as String;
          }
        }
      } catch (_) {}

      SolveRecord? solve;
      try {
        solve = await _leaderboardService.fetchUserSubmission(dailyId, id);
      } catch (_) {
        solve = null;
      }

      entries.add(
        _FriendEntry(uid: id, displayName: display, email: email, solve: solve),
      );
    }

    // Build ranking: those with numeric times first (ascending), then DNFs and
    // then users with no submission. Use `effectiveMilliseconds()` so DNFs are
    // correctly detected even when `milliseconds` is present (some clients
    // store the raw time alongside a 'dnf' penalty).
    final timed =
        entries
            .where(
              (e) =>
                  e.solve != null && e.solve!.effectiveMilliseconds() != null,
            )
            .toList()
          ..sort(
            (a, b) => a.solve!.effectiveMilliseconds()!.compareTo(
              b.solve!.effectiveMilliseconds()!,
            ),
          );
    for (int i = 0; i < timed.length; i++) {
      timed[i].rank = i + 1;
    }

    final others = entries
        .where(
          (e) => e.solve == null || e.solve!.effectiveMilliseconds() == null,
        )
        .toList();

    final ordered = <_FriendEntry>[];
    ordered.addAll(timed);
    ordered.addAll(others);

    if (!mounted) return;
    setState(() {
      _friendTimes = ordered;
      _loading = false;
    });
  }

  void _changeDateBy(int days) {
    final today = DateTime.now();
    final candidate = _selectedDate.add(Duration(days: days));
    final candidateDate = DateTime(
      candidate.year,
      candidate.month,
      candidate.day,
    );
    final todayDate = DateTime(today.year, today.month, today.day);
    DateTime newDate = candidateDate;
    if (candidateDate.isAfter(todayDate)) newDate = todayDate;

    setState(() {
      _selectedDate = newDate;
      _loading = true;
    });
    _load();
  }

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(today.year - 2),
      lastDate: today,
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _loading = true;
      });
      _load();
    }
  }

  Future<void> _sendRequest() async {
    final input = _addController.text.trim();
    final fromId = FirebaseAuth.instance.currentUser?.uid;
    if (input.isEmpty || fromId == null) return;

    String? toId;
    if (input.contains('@')) {
      // treat as email: resolve to user id
      final snap = await _db
          .collection('users')
          .where('email', isEqualTo: input)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No user found with that email')),
        );
        return;
      }
      toId = snap.docs.first.id;
    } else {
      toId = input;
    }

    try {
      await _friendService.sendFriendRequest(fromId, toId);
      _addController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Friend request sent')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send friend request: $e')),
      );
    }
  }

  @override
  void dispose() {
    _addController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _addController,
                      decoration: const InputDecoration(
                        hintText: 'Enter user id or email to add',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _sendRequest,
                    child: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const FriendRequestsPage(),
                    ),
                  );
                },
                child: const Text('View Requests'),
              ),
              // Date selector for leaderboard — allows clicking or swiping through days.
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => _changeDateBy(-1),
                      tooltip: 'Previous day',
                    ),
                    TextButton(
                      onPressed: _pickDate,
                      child: Text(
                        formatDate(_selectedDate),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {
                        // only allow moving forward up to today
                        final today = DateTime.now();
                        final selectedDateOnly = DateTime(
                          _selectedDate.year,
                          _selectedDate.month,
                          _selectedDate.day,
                        );
                        final todayOnly = DateTime(
                          today.year,
                          today.month,
                          today.day,
                        );
                        if (selectedDateOnly.isBefore(todayOnly)) {
                          _changeDateBy(1);
                        }
                      },
                      tooltip: 'Next day',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onHorizontalDragEnd: (details) {
                    final v = details.primaryVelocity ?? 0;
                    if (v > 0) {
                      // swipe right -> go to previous (older) day
                      _changeDateBy(-1);
                    } else if (v < 0) {
                      // swipe left -> go to next (newer) day
                      final today = DateTime.now();
                      final selectedDateOnly = DateTime(
                        _selectedDate.year,
                        _selectedDate.month,
                        _selectedDate.day,
                      );
                      final todayOnly = DateTime(
                        today.year,
                        today.month,
                        today.day,
                      );
                      if (selectedDateOnly.isBefore(todayOnly)) {
                        _changeDateBy(1);
                      }
                    }
                  },
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _friendTimes.isEmpty
                      ? const Center(child: Text('No friends yet'))
                      : ListView.builder(
                          itemCount: _friendTimes.length,
                          itemBuilder: (context, i) {
                            final item = _friendTimes[i];
                            final eff = item.solve?.effectiveMilliseconds();
                            final hasSubmission = item.solve != null;
                            final isDnf = hasSubmission && eff == null;

                            final timeText = !hasSubmission
                                ? 'No submission'
                                : (isDnf ? 'DNF' : item.solve!.formattedTime());

                            final rankText = item.rank != null
                                ? '${item.rank}'
                                : '';

                            // Treat DNFs as submissions so they remain visible.
                            final textColor = !hasSubmission
                                ? Theme.of(context).disabledColor
                                : null;
                            final timeColor = isDnf
                                ? Theme.of(context).colorScheme.error
                                : null;

                            return ListTile(
                              onTap: () async {
                                final changed =
                                    await showModalBottomSheet<bool>(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Theme.of(
                                        context,
                                      ).colorScheme.surface,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(16),
                                        ),
                                      ),
                                      builder: (ctx) => FractionallySizedBox(
                                        heightFactor: 0.75,
                                        child: FriendProfilePage(uid: item.uid),
                                      ),
                                    );
                                if (changed == true) {
                                  _load();
                                }
                              },
                              leading: item.rank != null
                                  ? CircleAvatar(child: Text(rankText))
                                  : const SizedBox(width: 40),
                              title: Text(
                                item.displayName,
                                style: TextStyle(color: textColor),
                              ),
                              subtitle: Text(
                                item.email ?? item.uid,
                                style: TextStyle(color: textColor),
                              ),
                              trailing: Text(
                                timeText,
                                style: TextStyle(
                                  color: timeColor ?? textColor,
                                  fontWeight:
                                      item.uid ==
                                          FirebaseAuth.instance.currentUser?.uid
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
