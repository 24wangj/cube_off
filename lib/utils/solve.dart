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

class Solve {
  Solve({
    required this.time,
    required this.date,
    required this.penalty,
    required this.scramble,
  });

  final Duration time;
  final DateTime date;
  Penalty penalty;
  final String scramble;
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
