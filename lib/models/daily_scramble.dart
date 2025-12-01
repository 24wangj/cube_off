import 'package:cloud_firestore/cloud_firestore.dart';

class DailyScramble {
  final String id; // YYYY-MM-DD or Firestore id
  final DateTime date;
  final String scramble;

  DailyScramble({required this.id, required this.date, required this.scramble});

  factory DailyScramble.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DailyScramble(
      id: doc.id,
      date: DateTime.fromMillisecondsSinceEpoch(data['date'] as int),
      scramble: data['scramble'] as String,
    );
  }

  Map<String, dynamic> toMap() => {
    'date': date.millisecondsSinceEpoch,
    'scramble': scramble,
  };
}
