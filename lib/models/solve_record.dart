import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/string_helpers.dart';

class SolveRecord {
  String id;
  final String userId;
  final String displayName;
  final DateTime date;
  final int? milliseconds; // null for DNF or missing
  final String penalty; // e.g. 'ok' or 'dnf' or '+2'
  final String scramble;

  SolveRecord({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.date,
    required this.milliseconds,
    required this.penalty,
    required this.scramble,
  });

  factory SolveRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SolveRecord(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      date: DateTime.fromMillisecondsSinceEpoch(data['date'] as int),
      milliseconds: data['milliseconds'] as int?,
      penalty: data['penalty'] as String? ?? 'ok',
      scramble: data['scramble'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'displayName': displayName,
    'date': date.millisecondsSinceEpoch,
    'milliseconds': milliseconds,
    'penalty': penalty,
    'scramble': scramble,
  };

  /// Returns the effective milliseconds considering penalty (+2 added),
  /// or null for DNF / missing time.
  int? effectiveMilliseconds() {
    final p = penalty.toLowerCase();
    if (p.contains('dnf')) return null;
    if (milliseconds == null) return null;
    final base = milliseconds!;
    // Accept several representations for +2: '+2', 'plustwo', 'plusTwo', etc.
    if (p.contains('+2') || p.contains('plus')) return base + 2000;
    return base;
  }

  /// Returns a human-readable time string, considering penalties and DNF.
  String formattedTime() {
    final eff = effectiveMilliseconds();
    if (eff == null) return 'DNF';
    final p = penalty.toLowerCase();
    // For +2 display the base time and a (+2) marker, e.g. "5.123 (+2)".
    if ((p.contains('+2') || p.contains('plus')) && milliseconds != null) {
      return '${formatDuration(Duration(milliseconds: milliseconds!) + Duration(milliseconds: 2000))}+';
    }

    return formatDuration(Duration(milliseconds: eff));
  }
}
