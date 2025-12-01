import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/solve_record.dart';

class LeaderboardService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Upload a solve record under a daily scramble document.
  Future<String> uploadDailySolve(String dailyId, SolveRecord record) async {
    final ref = await _db
        .collection('daily_scrambles')
        .doc(dailyId)
        .collection('solves')
        .add(record.toMap());
    return ref.id;
  }

  // Fetch top N solves for a daily scramble; sorts by effective time (milliseconds), DNFs come last.
  Future<List<SolveRecord>> fetchDailyLeaderboard(
    String dailyId, {
    int limit = 50,
  }) async {
    final q = await _db
        .collection('daily_scrambles')
        .doc(dailyId)
        .collection('solves')
        .orderBy('milliseconds', descending: false)
        .limit(limit)
        .get();

    return q.docs.map((d) => SolveRecord.fromFirestore(d)).toList();
  }

  // Fetch only solves from a user's friends list (friendIds). If friendIds is empty, return empty list.
  Future<List<SolveRecord>> fetchFriendLeaderboard(
    String dailyId,
    List<String> friendIds,
  ) async {
    if (friendIds.isEmpty) return [];

    // Firestore doesn't support 'where in' with too many elements; limit to first 10 for safety.
    final limited = friendIds.take(10).toList();
    // Avoid requiring a composite Firestore index by fetching matching documents
    // and sorting client-side. This is acceptable for small friend lists.
    final q = await _db
        .collection('daily_scrambles')
        .doc(dailyId)
        .collection('solves')
        .where('userId', whereIn: limited)
        .get();

    final records = q.docs.map((d) => SolveRecord.fromFirestore(d)).toList();
    records.sort((a, b) {
      final am = a.effectiveMilliseconds();
      final bm = b.effectiveMilliseconds();
      if (am == null && bm == null) return 0;
      if (am == null) return 1; // DNFs at the end
      if (bm == null) return -1;
      return am.compareTo(bm);
    });
    return records;
  }

  /// Returns true if the given user already has a submission for [dailyId].
  Future<bool> hasUserSubmitted(String dailyId, String userId) async {
    final q = await _db
        .collection('daily_scrambles')
        .doc(dailyId)
        .collection('solves')
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    return q.docs.isNotEmpty;
  }

  /// Fetch the submission for [userId] on [dailyId], or null if none.
  Future<SolveRecord?> fetchUserSubmission(
    String dailyId,
    String userId,
  ) async {
    final q = await _db
        .collection('daily_scrambles')
        .doc(dailyId)
        .collection('solves')
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    if (q.docs.isEmpty) return null;
    return SolveRecord.fromFirestore(q.docs.first);
  }
}
