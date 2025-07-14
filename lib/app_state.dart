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
      return _solves.last.penalty;
    }
    return Penalty.ok;
  }

  void setCurrentPenalty(Penalty penalty) {
    if (_solves.isNotEmpty) {
      _solves.last.penalty = penalty;
      notifyListeners();
    }
  }
}
