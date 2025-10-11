import 'string_helpers.dart';

enum Penalty { ok, plusTwo, dnf }

enum Event {
  threeByThree,
  twoByTwo,
  fourByFour,
  fiveByFive,
  sixBySix,
  sevenBySeven,
  megaminx,
  pyraminx,
  squareOne,
  skewb,
  clock,
}

class Time {
  Time(this.duration, this.penalty);

  final Duration? duration;
  Penalty penalty;

  @override
  String toString() {
    if (penalty == Penalty.dnf) {
      return 'DNF';
    } else if (penalty == Penalty.plusTwo) {
      return '${formatDuration(effectiveDuration)}+';
    } else {
      return formatDuration(effectiveDuration);
    }
  }

  Duration? get effectiveDuration {
    if (duration == null) return null;
    if (penalty == Penalty.dnf) return null;
    if (penalty == Penalty.plusTwo) {
      return duration! + const Duration(seconds: 2);
    }
    return duration;
  }

  int compareTo(Time other) {
    var a = effectiveDuration;
    var b = other.effectiveDuration;

    if ((a == null && b == null) ||
        (penalty == Penalty.dnf && other.penalty == Penalty.dnf)) {
      return 0;
    }

    if (a == null || penalty == Penalty.dnf) return 1;
    if (b == null || other.penalty == Penalty.dnf) return -1;

    return a.compareTo(b);
  }
}

class TimeWithDate extends Time {
  TimeWithDate(super.duration, super.penalty, this.date);

  final DateTime date;
}

class Solve {
  Solve({
    required this.time,
    required this.date,
    required this.scramble,
    required this.id,
  });

  final Time time;
  final DateTime date;
  final String scramble;
  String id;

  int compareTo(Solve other) {
    return time.compareTo(other.time);
  }

  factory Solve.fromFirestore(String id, Map<String, dynamic> data) {
    return Solve(
      id: id,
      scramble: data['scramble'] ?? '',
      date: DateTime.fromMillisecondsSinceEpoch(data['date']),
      time: Time(
        Duration(milliseconds: (data['time'] as num).toInt()),
        Penalty.values.byName(data['penalty']),
      ),
    );
  }
}

final Map<Event, String> eventNames = {
  Event.threeByThree: "3x3",
  Event.twoByTwo: "2x2",
  Event.fourByFour: "4x4",
  Event.fiveByFive: "5x5",
  Event.sixBySix: "6x6",
  Event.sevenBySeven: "7x7",
  Event.megaminx: "Megaminx",
  Event.pyraminx: "Pyraminx",
  Event.squareOne: "Square-1",
  Event.skewb: "Skewb",
  Event.clock: "Clock",
};

final Map<Event, double> eventScrambleFontSizes = {
  Event.sixBySix: 17,
  Event.sevenBySeven: 15,
  Event.megaminx: 16,
  Event.skewb: 18,
  Event.clock: 18,
};

final Map<Event, String> eventIDs = {
  Event.threeByThree: "333",
  Event.twoByTwo: "222",
  Event.fourByFour: "444",
  Event.fiveByFive: "555",
  Event.sixBySix: "666",
  Event.sevenBySeven: "777",
  Event.megaminx: "minx",
  Event.pyraminx: "pyram",
  Event.squareOne: "sq1",
  Event.skewb: "skewb",
  Event.clock: "clock",
};

final List<Event> events = [
  Event.threeByThree,
  Event.twoByTwo,
  Event.fourByFour,
  Event.fiveByFive,
  Event.sixBySix,
  Event.sevenBySeven,
  Event.megaminx,
  Event.pyraminx,
  Event.squareOne,
  Event.skewb,
  Event.clock,
];
