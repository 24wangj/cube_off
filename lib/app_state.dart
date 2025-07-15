import 'package:flutter/material.dart';

import 'utils/solve.dart';

class AppState extends ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  final List<Solve> _solves = [];
  List<Solve> get solves => _solves;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  Solve? getLastSolve() {
    if (_solves.isNotEmpty) {
      return _solves.last;
    }
    return null;
  }

  void addSolve(Solve solve) {
    _solves.add(solve);
    notifyListeners();
  }

  void deleteLastSolve() {
    if (_solves.isNotEmpty) {
      _solves.removeLast();
      notifyListeners();
    }
  }

  Penalty getCurrentPenalty() {
    if (_solves.isNotEmpty) {
      return _solves.last.time.penalty;
    }
    return Penalty.ok;
  }

  void setCurrentPenalty(Penalty penalty) {
    if (_solves.isNotEmpty) {
      _solves.last.time.penalty = penalty;
      notifyListeners();
    }
  }

  Time? meanOf3() {
    final last3 = _solves.takeLast(3);
    if (last3.length < 3) {
      return Time(null, Penalty.ok);
    }

    Duration sum = Duration.zero;

    for (var solve in last3) {
      if (solve.time.penalty == Penalty.dnf) {
        return Time(null, Penalty.dnf);
      } else if (solve.time.penalty == Penalty.plusTwo) {
        sum += solve.time.duration! + const Duration(seconds: 2);
      } else {
        sum += solve.time.duration!;
      }
    }

    return Time(sum ~/ 3, Penalty.ok);
  }

  Time? rawAverage(List<Solve> theSolves) {
    if (theSolves.isEmpty) {
      return Time(null, Penalty.ok);
    }

    Duration sum = Duration.zero;

    for (var solve in theSolves) {
      if (solve.time.penalty == Penalty.dnf) {
        return Time(null, Penalty.dnf);
      } else if (solve.time.penalty == Penalty.plusTwo) {
        sum += solve.time.duration! + const Duration(seconds: 2);
      } else {
        sum += solve.time.duration!;
      }
    }

    return Time(sum ~/ theSolves.length, Penalty.ok);
  }

  Time? averageOf5() {
    final last5 = _solves.takeLast(5);

    if (last5.length < 5) {
      return Time(null, Penalty.ok);
    }

    final mid3 = removeFastestAndSlowest(last5);

    return rawAverage(mid3);
  }

  Time? averageOf12() {
    final last12 = _solves.takeLast(12);

    if (last12.length < 12) {
      return Time(null, Penalty.ok);
    }

    final mid10 = removeFastestAndSlowest(last12);

    return rawAverage(mid10);
  }
}

extension on List<Solve> {
  List<Solve> takeLast(int i) {
    if (i <= 0) return [];
    return sublist(length - i < 0 ? 0 : length - i);
  }
}

List<Solve> removeFastestAndSlowest(List<Solve> solves) {
  if (solves.length <= 2) return [];

  final sorted = List<Solve>.from(solves)
    ..sort((a, b) => a.time.duration!.compareTo(b.time.duration!));

  return sorted.sublist(1, sorted.length - 1);
}
