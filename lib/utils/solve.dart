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
  Event.megaminx: 17,
  Event.skewb: 18,
  Event.clock: 18,
};

String getScrambleForEvent(Event event) {
  switch (event) {
    case Event.threeByThree:
      return "B' R2 U2 B2 U2 F' D2 R2 U2 R2 B D2 R B2 F U L' D' F' D'";
    case Event.twoByTwo:
      return "R U R' U' R U R' U'";
    case Event.fourByFour:
      return "D' F L2 D2 L2 U2 R U2 D2 F2 R2 U2 D' F' R L F U R2 F2 Rw2 U B Rw2 U' R2 U' B U2 Uw2 Fw2 R' L2 Rw D F' Uw2 L2 D2 Rw B' Uw B R' Uw2";
    case Event.fiveByFive:
      return "U2 Lw Uw2 L' Bw Lw' F2 Rw B' L' D' Rw D' B2 D' Dw2 Rw Fw' Rw' B2 L Fw Lw' U' B Uw' U' Rw' L Bw B' D2 L' Uw2 Fw' Dw2 U' Rw Dw' F Uw Dw' B Bw' Uw' F' Uw2 R' Uw' F' Rw2 R Lw' Fw Dw' U2 F2 U Uw Lw";
    case Event.sixBySix:
      return "Uw2 3Rw' R2 Lw2 U Rw' 3Fw' Dw2 R' B2 Rw' Bw' D B2 U2 Uw2 R' Uw2 Fw' 3Rw2 L' R2 3Fw' Rw' L' F' Uw2 U Lw F2 Lw2 Dw B2 Dw' F' 3Uw 3Rw B' R L Fw U2 Bw2 Fw U' Dw' Bw' R' 3Rw B' 3Rw' U2 F2 Dw2 F Uw Dw2 U2 3Fw2 Lw 3Rw2 Uw Bw2 Uw Bw B' U R' Rw' Bw' Uw2 3Rw2 Fw Dw2 R2 Fw2 U2 L' B' D2";
    case Event.sevenBySeven:
      return "3Rw Rw2 Dw' Fw 3Rw' Rw' 3Dw 3Rw2 Fw' Lw 3Lw 3Uw' Rw' 3Fw2 U D' 3Dw' 3Bw2 Fw' Lw' 3Lw' Fw2 B2 3Rw Bw2 B2 3Rw Uw R2 F 3Uw2 3Lw2 Uw2 F2 Lw 3Uw 3Dw B2 3Rw2 B' F2 Dw 3Uw 3Bw' 3Dw Fw' 3Rw2 3Bw2 D2 3Lw2 Bw' 3Lw' Bw2 Lw U2 B Rw' Fw2 3Uw2 R 3Lw' 3Bw B' Lw2 3Dw 3Uw2 R2 3Dw2 Bw2 B' 3Fw Dw Bw' 3Lw 3Rw' L' Uw2 D2 U 3Dw2 3Lw' 3Bw2 U 3Lw2 D' 3Bw' Rw' Lw2 3Bw2 D2 U' Bw Rw' B 3Rw 3Bw 3Fw 3Dw' Rw2 3Fw2";
    case Event.megaminx:
      return "R++ D-- R++ D++ R++ D-- R++ D++ R-- D++ U R-- D-- R++ D++ R-- D-- R-- D-- R-- D++ U R++ D++ R-- D++ R++ D-- R-- D++ R++ D++ U R++ D++ R++ D++ R++ D-- R++ D-- R-- D++ U R++ D++ R++ D++ R++ D++ R++ D++ R++ D-- U' R-- D-- R++ D-- R-- D-- R++ D-- R-- D++ U R++ D++ R++ D++ R++ D-- R++ D-- R++ D-- U'";
    case Event.pyraminx:
      return "B' R' L R B U' L R l b u";
    case Event.squareOne:
      return "(-2,0)/ (-4,2)/ (4,-5)/ (-4,-4)/ (0,-3)/ (-5,-3)/ (-3,-3)/ (-5,0)/ (4,0)/ (-2,-2)/ (-4,-2)/";
    case Event.skewb:
      return "L' R' U' B U' L' R' L R";
    case Event.clock:
      return "UR4+ DR4- DL3+ UL3+ U4- R2+ D3- L4+ ALL3- y2 U3+ R5- D6+ L2+ ALL1-";
  }
}
