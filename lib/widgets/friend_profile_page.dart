import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/friend_service.dart';
import '../services/leaderboard_service.dart';
import '../models/solve_record.dart';

class FriendProfilePage extends StatefulWidget {
  final String uid;
  const FriendProfilePage({super.key, required this.uid});

  @override
  State<FriendProfilePage> createState() => _FriendProfilePageState();
}

class _FriendProfilePageState extends State<FriendProfilePage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FriendService _friendService = FriendService();
  final LeaderboardService _leaderboardService = LeaderboardService();

  String? _displayName;
  String? _email;
  SolveRecord? _todaySolve;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final doc = await _db.collection('users').doc(widget.uid).get();
      final data = doc.data();
      if (data != null) {
        _displayName = data['displayName'] as String? ?? widget.uid;
        _email = data['email'] as String?;
      }

      final now = DateTime.now();
      final dailyId =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      _todaySolve = await _leaderboardService.fetchUserSubmission(
        dailyId,
        widget.uid,
      );
    } catch (_) {
      // ignore
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _unfriend() async {
    final me = FirebaseAuth.instance.currentUser?.uid;
    if (me == null) return;
    if (me == widget.uid) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unfriend'),
        content: Text(
          'Remove ${_displayName ?? widget.uid} from your friends?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Unfriend'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _loading = true);
    try {
      await _friendService.removeFriend(me, widget.uid);
      await _friendService.removeFriend(widget.uid, me);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unfriended')));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: $e')));
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeText = _todaySolve == null
        ? 'No submission'
        : (_todaySolve!.milliseconds == null
              ? 'DNF'
              : _todaySolve!.formattedTime());

    // Render as bottom sheet content so this widget can be used inside
    // `showModalBottomSheet(isScrollControlled: true)`.
    return SafeArea(
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _displayName ?? 'Profile',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _loading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Name: ${_displayName ?? widget.uid}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text('Email: ${_email ?? "(none)"}'),
                        const SizedBox(height: 16),
                        Text('Today: $timeText'),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _unfriend,
                          child: const Text('Unfriend'),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
