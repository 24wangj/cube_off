import 'dart:async';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import 'utils/solve.dart';

import 'models/daily_scramble.dart';
import 'models/solve_record.dart';
import 'services/scramble_service.dart';
import 'services/leaderboard_service.dart';
import 'services/friend_service.dart';

class AppState extends ChangeNotifier {
  AppState() {
    init();
  }

  Map<Event, bool> _eventsFetched = Map.fromIterable(
    Event.values,
    key: (e) => e as Event,
    value: (_) => false,
  );

  Map<Event, bool> get eventsFetched => _eventsFetched;

  StreamSubscription<User?>? _authSubscription;

  Future<void> init() async {
    // Listen for auth state changes so we can clear and reload per-user data
    // when the signed-in user changes (sign-out/sign-in flow).
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((
      User? user,
    ) async {
      if (user == null) {
        // Signed out: clear in-memory solves and mark events as not fetched.
        _solves.clear();
        _eventsFetched = Map.fromIterable(
          Event.values,
          key: (e) => e as Event,
          value: (_) => false,
        );
        notifyListeners();
      } else {
        // Signed in: clear any stale solves then fetch for current event.
        _solves.clear();
        _eventsFetched = Map.fromIterable(
          Event.values,
          key: (e) => e as Event,
          value: (_) => false,
        );
        await fetchSolvesForEvent(_currentEvent);
        updateStats();
      }
    });

    // On initial startup (before any auth event), attempt to fetch solves
    // for the current event if a user is already signed in.
    await fetchSolvesForEvent(_currentEvent);
    updateStats();
  }

  // Services for daily scramble and leaderboards
  final ScrambleService _scrambleService = ScrambleService();
  final LeaderboardService _leaderboardService = LeaderboardService();
  final FriendService _friendService = FriendService();

  DailyScramble? _todayScramble;
  DailyScramble? get todayScramble => _todayScramble;

  Future<void> fetchTodayScramble() async {
    _todayScramble = await _scrambleService.getScrambleForDate(DateTime.now());
    notifyListeners();
  }

  Future<String> submitDailySolve(
    Duration? duration,
    String penalty, {
    String? scramble,
    DateTime? scrambleDate,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Must be logged in to submit');

    final date = scrambleDate ?? DateTime.now();
    final dailyId =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    // Prevent more than one submission per user per scramble (dailyId).
    final alreadySubmitted = await _leaderboardService.hasUserSubmitted(
      dailyId,
      user.uid,
    );
    if (alreadySubmitted) {
      throw Exception('You have already submitted a solve for this scramble.');
    }

    final record = SolveRecord(
      id: '',
      userId: user.uid,
      displayName: user.displayName ?? user.email ?? user.uid,
      date: date,
      milliseconds: duration?.inMilliseconds,
      penalty: penalty,
      scramble: scramble ?? _todayScramble?.scramble ?? '',
    );

    final id = await _leaderboardService.uploadDailySolve(dailyId, record);
    return id;
  }

  Future<List<SolveRecord>> fetchFriendLeaderboardForToday() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final friendIds = await _friendService.getFriendIds(user.uid);
    final now = DateTime.now();
    final dailyId =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    return await _leaderboardService.fetchFriendLeaderboard(dailyId, friendIds);
  }

  Future<List<SolveRecord>> fetchFriendLeaderboardForDate(DateTime date) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final friendIds = await _friendService.getFriendIds(user.uid);
    final dailyId =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    return await _leaderboardService.fetchFriendLeaderboard(dailyId, friendIds);
  }

  Future<void> fetchSolvesForEvent(Event event) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection(event.name)
        .orderBy('date', descending: false)
        .get();

    // Store the fetched solves under the passed-in event (not the
    // possibly-changing _currentEvent) so each event's solves are
    // tracked correctly.
    _solves[event] = querySnapshot.docs.map((doc) {
      final data = doc.data();
      return Solve.fromFirestore(doc.id, data);
    }).toList();

    _eventsFetched[event] = true;

    // If we fetched the currently selected event, recompute stats so
    // the UI shows updated averages/records immediately.
    if (event == _currentEvent) {
      updateStats();
    }
  }

  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  final Map<Event, List<Solve>> _solves = {};
  List<Solve> get solves => _solves[_currentEvent] ?? [];

  Event _currentEvent = Event.threeByThree;
  Event get currentEvent => _currentEvent;

  String _currLast = "last12";
  String get currLast => _currLast;
  set currLast(String value) {
    _currLast = value;
    notifyListeners();
  }

  Map<String, bool> _averagesShown = {
    'single': true,
    'mo3': true,
    'ao5': true,
    'ao12': false,
  };
  Map<String, bool> get averagesShown => _averagesShown;
  set averagesShown(Map<String, bool> value) {
    _averagesShown = value;
    notifyListeners();
  }

  Time _best = Time(null, Penalty.ok);
  Time get best => _best;

  Time _median = Time(null, Penalty.ok);
  Time get median => _median;

  Time _mean = Time(null, Penalty.ok);
  Time get mean => _mean;

  Time _standardDeviation = Time(null, Penalty.ok);
  Time get standardDeviation => _standardDeviation;

  int _count = 0;
  int get count => _count;

  String _numSolves = "--/--";
  String get numSolves => _numSolves;

  Time _currMo3 = Time(null, Penalty.ok);
  Time get currMo3 => _currMo3;

  Time _currAo5 = Time(null, Penalty.ok);
  Time get currAo5 => _currAo5;

  Time _currAo12 = Time(null, Penalty.ok);
  Time get currAo12 => _currAo12;

  Time _curAo50 = Time(null, Penalty.ok);
  Time get currAo50 => _curAo50;

  Time _currAo100 = Time(null, Penalty.ok);
  Time get currAo100 => _currAo100;

  List<TimeWithDate> _bestSingleList = [];
  List<TimeWithDate> get bestSingleList => _bestSingleList;

  List<TimeWithDate> _bestMo3List = [];
  List<TimeWithDate> get bestMo3List => _bestMo3List;

  List<TimeWithDate> _bestAo5List = [];
  List<TimeWithDate> get bestAo5List => _bestAo5List;

  List<TimeWithDate> _bestAo12List = [];
  List<TimeWithDate> get bestAo12List => _bestAo12List;

  List<TimeWithDate> _bestAo50List = [];
  List<TimeWithDate> get bestAo50List => _bestAo50List;

  List<TimeWithDate> _bestAo100List = [];
  List<TimeWithDate> get bestAo100List => _bestAo100List;

  final List<FlSpot> _allSingleList = [];
  List<FlSpot> get allSingleList => _allSingleList;

  final List<FlSpot> _allMo3List = [];
  List<FlSpot> get allMo3List => _allMo3List;

  final List<FlSpot> _allAo5List = [];
  List<FlSpot> get allAo5List => _allAo5List;

  final List<FlSpot> _allAo12List = [];
  List<FlSpot> get allAo12List => _allAo12List;

  void updateStats() {
    final currentSolves = _solves[_currentEvent] ?? [];
    if (currentSolves.isEmpty) {
      _best = Time(null, Penalty.ok);
      _median = Time(null, Penalty.ok);
      _mean = Time(null, Penalty.ok);
      _standardDeviation = Time(null, Penalty.ok);
      _numSolves = "--/--";

      _currMo3 = Time(null, Penalty.ok);
      _currAo5 = Time(null, Penalty.ok);
      _currAo12 = Time(null, Penalty.ok);
      _curAo50 = Time(null, Penalty.ok);
      _currAo100 = Time(null, Penalty.ok);

      _bestSingleList = [];
      _bestMo3List = [];
      _bestAo5List = [];
      _bestAo12List = [];
      _bestAo50List = [];
      _bestAo100List = [];

      _allSingleList.clear();
      _allMo3List.clear();
      _allAo5List.clear();
      _allAo12List.clear();
    } else {
      final sorted = List<Solve>.from(solves)..sort((a, b) => a.compareTo(b));
      _best = sorted.first.time;

      _count = currentSolves.length;
      int validCount = 0;

      if (_count % 2 == 0) {
        final mid1 = sorted[_count ~/ 2 - 1].time;
        final mid2 = sorted[_count ~/ 2].time;

        if (mid1.duration == null || mid2.duration == null) {
          _median = Time(null, Penalty.ok);
        } else if (mid1.penalty == Penalty.dnf || mid2.penalty == Penalty.dnf) {
          _median = Time(null, Penalty.dnf);
        } else {
          _median = Time(
            Duration(
              milliseconds:
                  (mid1.effectiveDuration!.inMilliseconds +
                      mid2.effectiveDuration!.inMilliseconds) ~/
                  2,
            ),
            Penalty.ok,
          );
        }
      } else {
        _median = sorted[_count ~/ 2].time;
      }

      Duration totalDuration = Duration.zero;

      for (var solve in currentSolves) {
        if (solve.time.penalty != Penalty.dnf) {
          validCount++;
          totalDuration += solve.time.effectiveDuration!;
        }
      }

      Duration sumOfSquares = Duration.zero;

      if (validCount > 0) {
        _mean = Time(totalDuration ~/ validCount, Penalty.ok);
        for (var solve in currentSolves) {
          if (solve.time.penalty != Penalty.dnf) {
            final diff =
                solve.time.effectiveDuration! - _mean.effectiveDuration!;
            sumOfSquares += Duration(
              milliseconds: diff.inMilliseconds * diff.inMilliseconds,
            );
          }
        }
        _standardDeviation = Time(
          Duration(
            milliseconds: sqrt(
              (sumOfSquares.inMilliseconds) / validCount,
            ).toInt(),
          ),
          Penalty.ok,
        );
      } else {
        _mean = Time(null, Penalty.ok);
        _standardDeviation = Time(null, Penalty.ok);
      }

      _numSolves = "$validCount/$_count";

      _currMo3 = meanOf3(_count - 1) ?? Time(null, Penalty.ok);
      _currAo5 = averageOf5(_count - 1) ?? Time(null, Penalty.ok);
      _currAo12 = averageOf12(_count - 1) ?? Time(null, Penalty.ok);
      _curAo50 = averageOf50(_count - 1) ?? Time(null, Penalty.ok);
      _currAo100 = averageOf100(_count - 1) ?? Time(null, Penalty.ok);

      _bestSingleList = getBestSingleList();
      _bestMo3List = getBestMo3List();
      _bestAo5List = getBestAo5List();
      _bestAo12List = getBestAo12List();
      _bestAo50List = getBestAo50List();
      _bestAo100List = getBestAo100List();
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  set currentEvent(Event event) {
    _currentEvent = event;
    updateStats();
    notifyListeners();
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void addSolves() {
    for (int i = 0; i < 20; i++) {
      addSolve(
        Solve(
          date: DateTime.now(),
          scramble: 'lmao',
          time: Time(
            Duration(milliseconds: Random().nextInt(3000)),
            Penalty.ok,
          ),
          id: '',
        ),
      );
    }
    notifyListeners();
  }

  Solve? getLastSolve() {
    if (_solves[_currentEvent]?.isNotEmpty ?? false) {
      return _solves[_currentEvent]!.last;
    }
    return null;
  }

  void addSolve(Solve solve) async {
    solve.id = await uploadSolve(solve);

    _solves[_currentEvent] ??= [];
    _solves[_currentEvent]!.add(solve);

    notifyListeners();
    updateStats();
  }

  Future<String> uploadSolve(Solve solve) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Must be logged in');

    final docRef = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection(_currentEvent.name)
        .add({
          'time': solve.time.duration?.inMilliseconds.toDouble(),
          'penalty': solve.time.penalty.name,
          'scramble': solve.scramble,
          'date': solve.date.millisecondsSinceEpoch,
        });

    return docRef.id;
  }

  void deleteLastSolve() {
    if (_solves[_currentEvent]?.isNotEmpty ?? false) {
      deleteSolve(_solves[_currentEvent]!.last.id);

      _solves[_currentEvent]!.removeLast();
      notifyListeners();
      updateStats();
    }
  }

  void deleteSolveAt(int index) {
    if (_solves[_currentEvent]?.isNotEmpty ?? false) {
      deleteSolve(_solves[_currentEvent]!.elementAt(index).id);

      _solves[_currentEvent]!.removeAt(index);

      notifyListeners();
      updateStats();
    }
  }

  Future<void> deleteSolve(String solveId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection(_currentEvent.name)
        .doc(solveId)
        .delete();
  }

  Penalty getCurrentPenalty() {
    if (_solves[_currentEvent]?.isNotEmpty ?? false) {
      return _solves[_currentEvent]!.last.time.penalty;
    }
    return Penalty.ok;
  }

  void setCurrentPenalty(Penalty penalty) {
    if (_solves[_currentEvent]?.isNotEmpty ?? false) {
      updateSolvePenalty(_solves[_currentEvent]!.last.id, penalty);

      _solves[_currentEvent]!.last.time.penalty = penalty;
      notifyListeners();
      updateStats();
    }
  }

  void setPenaltyAt(Penalty penalty, int index) {
    if (_solves[_currentEvent]?.isNotEmpty ?? false) {
      updateSolvePenalty(_solves[_currentEvent]!.elementAt(index).id, penalty);

      _solves[_currentEvent]!.elementAt(index).time.penalty = penalty;
      notifyListeners();
      updateStats();
    }
  }

  Future<void> updateSolvePenalty(String solveId, Penalty penalty) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection(_currentEvent.name)
        .doc(solveId)
        .update({'penalty': penalty.name});
  }

  Time? rawAverage(List<Solve> theSolves) {
    if (theSolves.isEmpty) {
      return Time(null, Penalty.ok);
    }

    Duration sum = Duration.zero;

    for (var solve in theSolves) {
      if (solve.time.penalty == Penalty.dnf) {
        return Time(null, Penalty.dnf);
      } else {
        sum += solve.time.effectiveDuration!;
      }
    }

    return Time(sum ~/ theSolves.length, Penalty.ok);
  }

  Time? meanOf3(int index) {
    final last3 = _solves[_currentEvent]?.takeLast(3, index) ?? [];
    if (last3.length < 3) {
      return Time(null, Penalty.ok);
    }

    return rawAverage(last3);
  }

  Time? averageOf5(int index) {
    final last5 = _solves[_currentEvent]?.takeLast(5, index) ?? [];

    if (last5.length < 5) {
      return Time(null, Penalty.ok);
    }

    final mid3 = removeFastestAndSlowest(last5, 1);

    return rawAverage(mid3);
  }

  Time? averageOf12(int index) {
    final last12 = _solves[_currentEvent]?.takeLast(12, index) ?? [];

    if (last12.length < 12) {
      return Time(null, Penalty.ok);
    }

    final mid10 = removeFastestAndSlowest(last12, 1);

    return rawAverage(mid10);
  }

  Time? averageOf50(int index) {
    final last50 = _solves[_currentEvent]?.takeLast(50, index) ?? [];

    if (last50.length < 50) {
      return Time(null, Penalty.ok);
    }

    final mid44 = removeFastestAndSlowest(last50, 3);

    return rawAverage(mid44);
  }

  Time? averageOf100(int index) {
    final last100 = _solves[_currentEvent]?.takeLast(100, index) ?? [];

    if (last100.length < 100) {
      return Time(null, Penalty.ok);
    }

    final mid90 = removeFastestAndSlowest(last100, 5);

    return rawAverage(mid90);
  }

  List<TimeWithDate> getBestSingleList() {
    final currentSolves = _solves[_currentEvent] ?? [];

    if (_count < 1) {
      return [];
    }

    List<TimeWithDate> bestSingleList = [];
    allSingleList.clear();

    for (int i = 0; i < _count; i++) {
      final Time single = currentSolves[i].time;
      if (single.penalty != Penalty.dnf) {
        allSingleList.add(
          FlSpot(
            i.toDouble(),
            single.effectiveDuration!.inMilliseconds.toDouble() / 1000.0,
          ),
        );
      }
      if (bestSingleList.isEmpty || single.compareTo(bestSingleList.last) < 0) {
        bestSingleList.add(
          TimeWithDate(single.duration, single.penalty, currentSolves[i].date),
        );
      }
    }

    notifyListeners();

    return bestSingleList;
  }

  List<TimeWithDate> getBestMo3List() {
    final currentSolves = _solves[_currentEvent] ?? [];

    if (_count < 3) {
      return [];
    }

    List<TimeWithDate> bestMo3List = [];
    allMo3List.clear();

    for (int i = 2; i < _count; i++) {
      final Time? mo3 = meanOf3(i);
      if (mo3 != null) {
        if (mo3.penalty != Penalty.dnf) {
          allMo3List.add(
            FlSpot(
              i.toDouble(),
              (mo3.effectiveDuration?.inMilliseconds.toDouble() ?? 0.0) /
                  1000.0,
            ),
          );
        }
        if (bestMo3List.isEmpty || mo3.compareTo(bestMo3List.last) < 0) {
          bestMo3List.add(
            TimeWithDate(mo3.duration, mo3.penalty, currentSolves[i].date),
          );
        }
      }
    }

    notifyListeners();

    return bestMo3List;
  }

  List<TimeWithDate> getBestAo5List() {
    final currentSolves = _solves[_currentEvent] ?? [];

    if (_count < 5) {
      return [];
    }

    List<TimeWithDate> bestAo5List = [];
    allAo5List.clear();

    for (int i = 4; i < _count; i++) {
      final Time? ao5 = averageOf5(i);
      if (ao5 != null) {
        if (ao5.penalty != Penalty.dnf) {
          allAo5List.add(
            FlSpot(
              i.toDouble(),
              (ao5.effectiveDuration?.inMilliseconds.toDouble() ?? 0.0) /
                  1000.0,
            ),
          );
        }
        if (bestAo5List.isEmpty || ao5.compareTo(bestAo5List.last) < 0) {
          bestAo5List.add(
            TimeWithDate(ao5.duration, ao5.penalty, currentSolves[i].date),
          );
        }
      }
    }

    return bestAo5List;
  }

  List<TimeWithDate> getBestAo12List() {
    final currentSolves = _solves[_currentEvent] ?? [];

    if (_count < 12) {
      return [];
    }

    List<TimeWithDate> bestAo12List = [];
    allAo12List.clear();

    for (int i = 11; i < _count; i++) {
      final Time? ao12 = averageOf12(i);
      if (ao12 != null) {
        if (ao12.penalty != Penalty.dnf) {
          allAo12List.add(
            FlSpot(
              i.toDouble(),
              (ao12.effectiveDuration?.inMilliseconds.toDouble() ?? 0.0) /
                  1000.0,
            ),
          );
        }
        if (bestAo12List.isEmpty || ao12.compareTo(bestAo12List.last) < 0) {
          bestAo12List.add(
            TimeWithDate(ao12.duration, ao12.penalty, currentSolves[i].date),
          );
        }
      }
    }

    return bestAo12List;
  }

  List<TimeWithDate> getBestAo50List() {
    final currentSolves = _solves[_currentEvent] ?? [];

    if (_count < 50) {
      return [];
    }

    List<TimeWithDate> bestAo50List = [];

    for (int i = 49; i < _count; i++) {
      final Time? ao50 = averageOf50(i);
      if (bestAo50List.isEmpty ||
          (ao50 != null && ao50.compareTo(bestAo50List.last) < 0)) {
        bestAo50List.add(
          TimeWithDate(ao50!.duration, ao50.penalty, currentSolves[i].date),
        );
      }
    }

    return bestAo50List;
  }

  List<TimeWithDate> getBestAo100List() {
    final currentSolves = _solves[_currentEvent] ?? [];

    if (_count < 100) {
      return [];
    }

    List<TimeWithDate> bestAo100List = [];

    for (int i = 99; i < _count; i++) {
      final Time? ao100 = averageOf100(i);
      if (bestAo100List.isEmpty ||
          (ao100 != null && ao100.compareTo(bestAo100List.last) < 0)) {
        bestAo100List.add(
          TimeWithDate(ao100!.duration, ao100.penalty, currentSolves[i].date),
        );
      }
    }

    return bestAo100List;
  }

  List<FlSpot> getRecentSingleList() {
    switch (_currLast) {
      case "last12":
        return allSingleList.takeLast(12, count - 12);
      case "last50":
        return allSingleList.takeLast(50, count - 50);
      case "last100":
        return allSingleList.takeLast(100, count - 100);
      case "all":
      default:
        return allSingleList;
    }
  }

  List<FlSpot> getRecentMo3List() {
    switch (_currLast) {
      case "last12":
        return allMo3List.takeLast(12, count - 12);
      case "last50":
        return allMo3List.takeLast(50, count - 50);
      case "last100":
        return allMo3List.takeLast(100, count - 100);
      case "all":
      default:
        return allMo3List;
    }
  }

  List<FlSpot> getRecentAo5List() {
    switch (_currLast) {
      case "last12":
        return allAo5List.takeLast(12, count - 12);
      case "last50":
        return allAo5List.takeLast(50, count - 50);
      case "last100":
        return allAo5List.takeLast(100, count - 100);
      case "all":
      default:
        return allAo5List;
    }
  }

  List<FlSpot> getRecentAo12List() {
    switch (_currLast) {
      case "last12":
        return allAo12List.takeLast(12, count - 12);
      case "last50":
        return allAo12List.takeLast(50, count - 50);
      case "last100":
        return allAo12List.takeLast(100, count - 100);
      case "all":
      default:
        return allAo12List;
    }
  }

  double getMinX() {
    switch (_currLast) {
      case "last12":
        return count - 12 < 0 ? 0 : count - 12;
      case "last50":
        return count - 50 < 0 ? 0 : count - 50;
      case "last100":
        return count - 100 < 0 ? 0 : count - 100;
      case "all":
      default:
        return 0;
    }
  }

  double getMinY() {
    double minY = double.infinity;

    List<FlSpot> spots = [];

    if (_averagesShown["single"] ?? false) {
      spots.addAll(getRecentSingleList());
    }
    if (_averagesShown["mo3"] ?? false) {
      spots.addAll(getRecentMo3List());
    }
    if (_averagesShown["ao5"] ?? false) {
      spots.addAll(getRecentAo5List());
    }
    if (averagesShown["ao12"] ?? false) {
      spots.addAll(getRecentAo12List());
    }

    for (var spot in spots) {
      if (spot.y < minY) {
        minY = spot.y;
      }
    }

    if (minY == double.infinity) {
      minY = 0.0;
    }

    return minY - 0.5 < 0 ? 0 : minY - 0.5;
  }

  double getMaxY() {
    double maxY = double.negativeInfinity;

    List<FlSpot> spots = [];

    if (_averagesShown["single"] ?? false) {
      spots.addAll(getRecentSingleList());
    }
    if (_averagesShown["mo3"] ?? false) {
      spots.addAll(getRecentMo3List());
    }
    if (_averagesShown["ao5"] ?? false) {
      spots.addAll(getRecentAo5List());
    }
    if (averagesShown["ao12"] ?? false) {
      spots.addAll(getRecentAo12List());
    }

    for (var spot in spots) {
      if (spot.y > maxY) {
        maxY = spot.y;
      }
    }

    if (maxY == double.negativeInfinity) {
      maxY = 1.0;
    }

    return maxY + 0.5;
  }
}

extension on List<Solve> {
  List<Solve> takeLast(int i, int index) {
    if (i <= 0 || index < 0) return [];
    return sublist(
      length - i <= 0 || index - i < 0 ? 0 : index + 1 - i,
      index + 1,
    );
  }
}

extension on List<FlSpot> {
  List<FlSpot> takeLast(int i, int count) {
    if (i <= 0) return [];
    List<FlSpot> list = sublist(length - i < 0 ? 0 : length - i);
    for (int i = 0; i < list.length; i++) {
      if (list[i].x < count) {
        list.removeAt(i);
        i--;
      }
    }
    return list;
  }
}

List<Solve> removeFastestAndSlowest(
  List<Solve> solves,
  int numRemovalsOnEachSide,
) {
  if (solves.length <= 2 * numRemovalsOnEachSide) return [];

  final sorted = List<Solve>.from(solves)..sort((a, b) => a.compareTo(b));

  // for (var solve in sorted) {
  //   print(solve.time.toString());
  // }

  // print("---");

  return sorted.sublist(
    numRemovalsOnEachSide,
    sorted.length - numRemovalsOnEachSide,
  );
}
