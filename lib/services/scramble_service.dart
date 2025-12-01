import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/daily_scramble.dart';
import '../utils/scrambler.dart';

class ScrambleService {
  final CollectionReference _daily = FirebaseFirestore.instance.collection(
    'daily_scrambles',
  );

  // Fetch today's scramble (document id as YYYY-MM-DD). If missing, optionally create one.
  Future<DailyScramble?> getScrambleForDate(
    DateTime date, {
    bool createIfMissing = true,
  }) async {
    final id = _idFromDate(date);
    final doc = await _daily.doc(id).get();
    if (doc.exists) return DailyScramble.fromFirestore(doc);

    if (!createIfMissing) return null;
    final scramble = await _generateRandomScramble();
    final ds = DailyScramble(id: id, date: date, scramble: scramble);
    await _daily.doc(id).set(ds.toMap());
    return ds;
  }

  Future<DailyScramble?> fetchScrambleById(String id) async {
    final doc = await _daily.doc(id).get();
    if (!doc.exists) return null;
    return DailyScramble.fromFirestore(doc);
  }

  String _idFromDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<String> _generateRandomScramble({int length = 25}) async {
    try {
      await Scrambler().ensureInitialized();
      // Use the same event id used elsewhere for 3x3
      final result = Scrambler().jsRuntime.evaluate("cube.scramble('333');");
      if (result.isError) throw Exception('scrambler error');
      return result.stringResult;
    } catch (_) {
      const moves = [
        'R',
        "R'",
        'R2',
        'L',
        "L'",
        'L2',
        'U',
        "U'",
        'U2',
        'D',
        "D'",
        'D2',
        'F',
        "F'",
        'F2',
        'B',
        "B'",
        'B2',
      ];
      final rand = Random();
      final out = <String>[];
      for (var i = 0; i < length; i++) {
        out.add(moves[rand.nextInt(moves.length)]);
      }
      // return out.join(' ');
      return "Scramble not available";
    }
  }
}
