import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

import 'app_state.dart';
import 'utils/solve.dart';
import 'utils/string_helpers.dart';
import 'utils/widgets.dart';
import 'utils/scrambler.dart';

class TimerPage extends StatefulWidget {
  final void Function(bool) onTimerRunningChanged;
  final void Function(Solve)? onSolveAdded;

  // If `dailyMode` is true the timer is used specifically for the Daily
  // Scramble flow: it will show the provided scramble (if any), disable
  // event selection, use a local penalty state, and will not add solves to
  // the global results list (it will instead call `onSolveAdded`).
  final bool dailyMode;
  final String? providedScramble;
  final DateTime? providedScrambleDate;

  const TimerPage({
    required this.onTimerRunningChanged,
    this.onSolveAdded,
    this.dailyMode = false,
    this.providedScramble,
    this.providedScrambleDate,
    super.key,
  });

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
  bool _timerRunning = false;
  late Color _timerColor;
  bool _readyToStart = false;
  late DateTime _startTime;
  static Duration _elapsed = Duration.zero;
  Timer? _timer;
  Timer? _holdTimer;
  late Color _onPrimaryColor;
  String scramble = "Loading...";
  late Penalty _localSelectedPenalty;

  @override
  void initState() {
    super.initState();
    _initAndGenerate();
  }

  Future<void> _initAndGenerate() async {
    await Scrambler().ensureInitialized();
    if (widget.dailyMode && widget.providedScramble != null) {
      if (!mounted) return;
      setState(() {
        scramble = widget.providedScramble!;
        // Daily timer should start with display time at 0.
        _elapsed = Duration.zero;
      });
    } else {
      _generateScramble();
    }
  }

  void _generateScramble() {
    if (widget.dailyMode) return;
    if (!mounted) return;
    final appState = Provider.of<AppState>(context, listen: false);
    final evId = eventIDs[appState.currentEvent] ?? '333';
    final jsCall = "cube.scramble('$evId');";
    final result = Scrambler().jsRuntime.evaluate(jsCall);
    setState(() {
      scramble = result.stringResult;
    });
  }

  void _startTimer() {
    setState(() {
      _timerRunning = true;
      widget.onTimerRunningChanged(true);
      _readyToStart = false;
      _startTime = DateTime.now();
      _elapsed = Duration.zero;
    });
    _timer = Timer.periodic(const Duration(milliseconds: 24), (_) {
      setState(() {
        _elapsed = DateTime.now().difference(_startTime);
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();

    final penalty = widget.dailyMode
        ? _localSelectedPenalty
        : Provider.of<AppState>(context, listen: false).getCurrentPenalty();

    final solve = Solve(
      time: Time(_elapsed, penalty),
      date: widget.providedScrambleDate ?? DateTime.now(),
      scramble: scramble,
      id: '',
    );

    if (widget.dailyMode) {
      widget.onSolveAdded?.call(solve);
    } else {
      Provider.of<AppState>(context, listen: false).addSolve(solve);
      widget.onSolveAdded?.call(solve);
    }

    if (!widget.dailyMode) _generateScramble();

    setState(() {
      _timerRunning = false;
      widget.onTimerRunningChanged(false);
    });
  }

  void _onTapDown(TapDownDetails details) {
    if (_timerRunning) {
      _stopTimer();
      return;
    }

    if (!mounted) return;

    setState(() {
      _timerColor = Theme.of(context).colorScheme.primary;
    });

    _readyToStart = false;
    _holdTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {
        _timerColor = const Color.fromARGB(255, 79, 191, 83);
        _readyToStart = true;
      });
    });
  }

  void _onTapUp(TapUpDetails details) {
    _holdTimer?.cancel();

    if (!mounted) return;

    setState(() {
      _timerColor = Theme.of(context).colorScheme.onPrimary;
    });
    if (!_timerRunning && _readyToStart) {
      _startTimer();
    }
  }

  void _onTapCancel() {
    _holdTimer?.cancel();
    _readyToStart = false;

    if (!mounted) return;

    setState(() {
      _timerColor = _onPrimaryColor;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _onPrimaryColor = Theme.of(context).colorScheme.onPrimary;
    _timerColor = Theme.of(context).colorScheme.onPrimary;
    // initialize local penalty to the app state's current penalty
    _localSelectedPenalty = widget.dailyMode
        ? Penalty.ok
        : Provider.of<AppState>(context, listen: false).getCurrentPenalty();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _holdTimer?.cancel();
    super.dispose();
  }

  final TextEditingController _timeInputController = TextEditingController();

  Future<void> _displayTimeInputDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(
            'Input time',
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
          ),
          content: TextField(
            controller: _timeInputController,
            decoration: InputDecoration(hintText: "00:00.000"),
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
          ),
          actions: <Widget>[
            CustomElevatedButton(
              text: 'Cancel',
              backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
              textColor: Theme.of(context).colorScheme.onPrimary,
              onPressed: () {
                _timeInputController.clear();
                Navigator.pop(context);
              },
            ),
            CustomElevatedButton(
              text: 'Done',
              onPressed: () {
                final duration = parseDuration(_timeInputController.text);
                if (duration != null) {
                  final penalty = widget.dailyMode
                      ? _localSelectedPenalty
                      : Provider.of<AppState>(
                          context,
                          listen: false,
                        ).getCurrentPenalty();
                  final solve = Solve(
                    time: Time(duration, penalty),
                    date: widget.providedScrambleDate ?? DateTime.now(),
                    scramble: scramble,
                    id: '',
                  );
                  if (widget.dailyMode) {
                    widget.onSolveAdded?.call(solve);
                  } else {
                    Provider.of<AppState>(
                      context,
                      listen: false,
                    ).addSolve(solve);
                    widget.onSolveAdded?.call(solve);
                  }

                  _generateScramble();

                  setState(() {
                    _elapsed = duration;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Time added: ${formatDuration(duration)}'),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Invalid time format')),
                  );
                }
                _timeInputController.clear();
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _displayDeleteSolveDialog(BuildContext context) async {
    var appState = Provider.of<AppState>(context, listen: false);
    if (appState.getLastSolve() == null) {
      return;
    }
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(
            'Delete last solve?',
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
          ),

          actions: <Widget>[
            CustomElevatedButton(
              text: 'Cancel',
              backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
              textColor: Theme.of(context).colorScheme.onPrimary,
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            CustomElevatedButton(
              text: 'OK',
              onPressed: () {
                appState.deleteLastSolve();
                _elapsed =
                    appState.getLastSolve()?.time.duration ?? Duration.zero;
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var appState = Provider.of<AppState>(context);
    Penalty selectedPenalty = _timerRunning
        ? Penalty.ok
        : (widget.dailyMode
              ? _localSelectedPenalty
              : appState.getCurrentPenalty());

    return Stack(
      children: [
        Align(
          alignment: Alignment.center,
          child: SizedBox(
            child: Text(
              softWrap: false,
              displaySolveTime(_elapsed, selectedPenalty),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 50,
                fontWeight: FontWeight.bold,
                color: _timerColor,
              ),
            ),
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
        ),
        if (!_timerRunning)
          Align(
            alignment: Alignment.topCenter,
            child: SafeArea(
              top: true,
              bottom: false,
              left: false,
              right: false,
              child: Padding(
                padding: const EdgeInsets.only(top: 10, right: 30, left: 30),
                child: Column(
                  children: [
                    DropdownButtonHideUnderline(
                      child: DropdownButton2<Event>(
                        isExpanded: true,
                        hint: Text(
                          'Select Item',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                        items: events
                            .map(
                              (Event item) => DropdownMenuItem<Event>(
                                value: item,
                                child: Center(
                                  child: Text(
                                    eventNames[item]!,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        value: widget.dailyMode
                            ? Event.threeByThree
                            : appState.currentEvent,
                        onChanged: widget.dailyMode
                            ? null
                            : (Event? value) {
                                setState(() {
                                  appState.currentEvent = value!;
                                  _elapsed =
                                      appState.getLastSolve()?.time.duration ??
                                      Duration.zero;
                                  _generateScramble();

                                  if (appState.eventsFetched[value] == false) {
                                    appState.fetchSolvesForEvent(value);
                                  }
                                });
                              },
                        buttonStyleData: ButtonStyleData(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          height: 40,
                          width: 140,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        iconStyleData: const IconStyleData(
                          iconEnabledColor: Colors.white,
                        ),
                        menuItemStyleData: const MenuItemStyleData(height: 40),
                        dropdownStyleData: DropdownStyleData(
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          offset: const Offset(0, -10),
                        ),
                        selectedItemBuilder: (context) {
                          final displayEvent = widget.dailyMode
                              ? Event.threeByThree
                              : appState.currentEvent;
                          return events.map((item) {
                            return Container(
                              alignment: AlignmentDirectional.center,
                              child: Text(
                                eventNames[displayEvent]!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  overflow: TextOverflow.ellipsis,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                    SizedBox(height: 20),
                    Container(
                      // decoration: BoxDecoration(
                      //   color: Theme.of(context).colorScheme.surfaceContainer,
                      //   borderRadius: BorderRadius.circular(20),
                      // ),
                      padding: const EdgeInsets.only(top: 20, bottom: 20),
                      child: Text(
                        scramble,
                        style: TextStyle(
                          fontSize: widget.dailyMode
                              ? 18
                              : eventScrambleFontSizes[appState.currentEvent] ??
                                    18,
                          color: Theme.of(context).colorScheme.onPrimary,
                          overflow: TextOverflow.visible,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        if (!_timerRunning)
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.only(top: 160),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.keyboard),
                    tooltip: 'Input time',
                    style: IconButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    onPressed: () {
                      _displayTimeInputDialog(context);
                    },
                  ),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 8)),
                  if (!widget.dailyMode)
                    SegmentedButton<Penalty>(
                      showSelectedIcon: false,
                      style: SegmentedButton.styleFrom(
                        side: const BorderSide(color: Colors.transparent),
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainer,
                        selectedForegroundColor: Colors.white,
                        selectedBackgroundColor: Theme.of(
                          context,
                        ).colorScheme.primary,
                      ),
                      segments: const <ButtonSegment<Penalty>>[
                        ButtonSegment(
                          value: Penalty.ok,
                          label: Text('OK'),
                          // icon: Icon(Icons.check_circle_outline),
                        ),
                        ButtonSegment(
                          value: Penalty.plusTwo,
                          label: Text('+2'),
                          // icon: Icon(Icons.add_circle_outline),
                        ),
                        ButtonSegment(
                          value: Penalty.dnf,
                          label: Text('DNF'),
                          // icon: Icon(Icons.cancel_outlined),
                        ),
                      ],
                      selected: <Penalty>{selectedPenalty},
                      onSelectionChanged: (Set<Penalty> newSelection) {
                        setState(() {
                          if (widget.dailyMode) {
                            _localSelectedPenalty = newSelection.first;
                          } else {
                            appState.setCurrentPenalty(newSelection.first);
                          }
                          selectedPenalty = newSelection.first;
                        });
                      },
                    ),
                  if (!widget.dailyMode) ...[
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 8)),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      tooltip: 'Delete last solve',
                      style: IconButton.styleFrom(
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                      ),
                      onPressed: () {
                        _displayDeleteSolveDialog(context);
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        if (!_timerRunning && !widget.dailyMode)
          IgnorePointer(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                top: false,
                bottom: true,
                left: false,
                right: false,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 50),
                  child: Text(
                    'Mo3: ${appState.currMo3}\nAo5: ${appState.currAo5}\nAo12: ${appState.currAo12}',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
