import 'package:cube_off/utils/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:fl_chart/fl_chart.dart';

import 'app_state.dart';
import 'utils/solve.dart';
import 'utils/string_helpers.dart';

class ResultsPage extends StatefulWidget {
  const ResultsPage({super.key});

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  static var currResult = "solves";
  static var currRecord = "single";

  int? _lastTouchedIndex;

  Future<void> _displayDeleteSolveDialog(
    BuildContext context,
    int index,
  ) async {
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
            'Delete solve ${index + 1}?',
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
                appState.deleteSolveAt(index);
                Navigator.pop(context);
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
    final averageColors = {
      'single': Colors.grey,
      'mo3': Theme.of(context).colorScheme.primary,
      'ao5': Colors.lightBlue,
      'ao12': Colors.green,
    };
    var appState = Provider.of<AppState>(context);

    return Container(
      margin: EdgeInsets.only(left: 10, right: 10),
      child: Center(
        child: SafeArea(
          top: true,
          bottom: false,
          left: false,
          right: false,
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Column(
              children: [
                DropdownButtonHideUnderline(
                  child: DropdownButton2<Event>(
                    isExpanded: true,
                    hint: Text(
                      'Select Item',
                      style: const TextStyle(fontSize: 14, color: Colors.white),
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
                    value: appState.currentEvent,
                    onChanged: (Event? value) {
                      appState.currentEvent = value!;

                      if (appState.eventsFetched[value] == false) {
                        appState.fetchSolvesForEvent(value);
                      }
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
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      offset: const Offset(0, -10),
                    ),
                    selectedItemBuilder: (context) {
                      return events.map((item) {
                        return Container(
                          alignment: AlignmentDirectional.center,
                          child: Text(
                            eventNames[appState.currentEvent]!,
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
                const SizedBox(height: 5),
                SegmentedButton<String>(
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
                  segments: const <ButtonSegment<String>>[
                    ButtonSegment(value: "solves", label: Text('Solves')),
                    ButtonSegment(value: "stats", label: Text('Stats')),
                    ButtonSegment(value: "records", label: Text('Records')),
                  ],
                  selected: <String>{currResult},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      currResult = newSelection.first;
                    });
                  },
                ),
                const SizedBox(height: 10),

                if (currResult == "solves")
                  Expanded(
                    child: ListView.builder(
                      itemCount: appState.solves.length,
                      itemBuilder: (context, index) {
                        var solve = appState.solves.reversed.elementAt(index);
                        return Container(
                          margin: EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: ListTile(
                            title: Text(
                              style: DefaultTextStyle.of(context).style
                                  .copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimary,
                                  ),
                              solve.time.toString(),
                            ),
                            subtitle: Text(
                              solve.scramble,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) {
                                  return DraggableScrollableSheet(
                                    expand: false,
                                    initialChildSize: 0.2,
                                    minChildSize: 0.2,
                                    maxChildSize: 0.7,
                                    builder: (context, scrollController) {
                                      return Container(
                                        decoration: BoxDecoration(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.surface,
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                top: Radius.circular(20),
                                              ),
                                        ),
                                        child: ListView(
                                          physics: ClampingScrollPhysics(),
                                          controller: scrollController,
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.all(
                                                24.0,
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            '${solve.time}',
                                                            style: TextStyle(
                                                              color:
                                                                  Theme.of(
                                                                        context,
                                                                      )
                                                                      .colorScheme
                                                                      .onPrimary,
                                                              fontSize: 30,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                          SizedBox(height: 10),
                                                          Text(
                                                            formatDateWithTime(
                                                              solve.date,
                                                            ),
                                                            style: TextStyle(
                                                              fontSize: 16,
                                                            ),
                                                          ),
                                                        ],
                                                      ),

                                                      CustomElevatedButton(
                                                        text: "Delete",
                                                        onPressed: () {
                                                          _displayDeleteSolveDialog(
                                                            context,
                                                            appState.count -
                                                                index -
                                                                1,
                                                          );
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(height: 30),
                                                  Center(
                                                    child: Text(
                                                      solve.scramble,
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(height: 24),

                                                  Center(
                                                    child: SegmentedButton<Penalty>(
                                                      showSelectedIcon: false,
                                                      style: SegmentedButton.styleFrom(
                                                        side: const BorderSide(
                                                          color: Colors
                                                              .transparent,
                                                        ),
                                                        backgroundColor:
                                                            Theme.of(context)
                                                                .colorScheme
                                                                .surfaceContainer,
                                                        selectedForegroundColor:
                                                            Colors.white,
                                                        selectedBackgroundColor:
                                                            Theme.of(context)
                                                                .colorScheme
                                                                .primary,
                                                      ),
                                                      segments:
                                                          const <
                                                            ButtonSegment<
                                                              Penalty
                                                            >
                                                          >[
                                                            ButtonSegment(
                                                              value: Penalty.ok,
                                                              label: Text('OK'),
                                                            ),
                                                            ButtonSegment(
                                                              value: Penalty
                                                                  .plusTwo,
                                                              label: Text('+2'),
                                                            ),
                                                            ButtonSegment(
                                                              value:
                                                                  Penalty.dnf,
                                                              label: Text(
                                                                'DNF',
                                                              ),
                                                            ),
                                                          ],
                                                      selected: <Penalty>{
                                                        solve.time.penalty,
                                                      },
                                                      onSelectionChanged:
                                                          (
                                                            Set<Penalty>
                                                            newSelection,
                                                          ) {
                                                            setState(() {
                                                              appState.setPenaltyAt(
                                                                newSelection
                                                                    .first,
                                                                appState.count -
                                                                    index -
                                                                    1,
                                                              );
                                                            });
                                                          },
                                                    ),
                                                  ),
                                                  SizedBox(height: 24),
                                                  TwoColumnTable(
                                                    rows: [
                                                      [
                                                        Text('Mo3'),
                                                        Text(
                                                          '${appState.meanOf3(appState.count - index - 1)}',
                                                        ),
                                                      ],
                                                      [
                                                        Text('Ao5'),
                                                        Text(
                                                          '${appState.averageOf5(appState.count - index - 1)}',
                                                        ),
                                                      ],
                                                      [
                                                        Text('Ao12'),
                                                        Text(
                                                          '${appState.averageOf12(appState.count - index - 1)}',
                                                        ),
                                                      ],
                                                      [
                                                        Text('Ao50'),
                                                        Text(
                                                          '${appState.averageOf50(appState.count - index - 1)}',
                                                        ),
                                                      ],
                                                      [
                                                        Text('Ao100'),
                                                        Text(
                                                          '${appState.averageOf100(appState.count - index - 1)}',
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            },
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              child: Text(
                                '${appState.solves.length - index}',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            trailing: Text(formatDate(solve.date)),
                          ),
                        );
                      },
                    ),
                  ),

                if (currResult == "stats")
                  Expanded(
                    child: Center(
                      child: ListView(
                        children: [
                          Center(
                            child: SegmentedButton<String>(
                              showSelectedIcon: false,
                              style: SegmentedButton.styleFrom(
                                side: const BorderSide(
                                  color: Colors.transparent,
                                ),
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainer,
                                selectedForegroundColor: Colors.white,
                                selectedBackgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                              ),
                              segments: const <ButtonSegment<String>>[
                                ButtonSegment(
                                  value: "last12",
                                  label: Text('Last 12'),
                                ),
                                ButtonSegment(
                                  value: "last50",
                                  label: Text('Last 50'),
                                ),
                                ButtonSegment(
                                  value: "last100",
                                  label: Text('Last 100'),
                                ),
                                ButtonSegment(value: "all", label: Text('All')),
                              ],
                              selected: <String>{appState.currLast},
                              onSelectionChanged: (Set<String> newSelection) {
                                setState(() {
                                  appState.currLast = newSelection.first;
                                });
                              },
                            ),
                          ),
                          SizedBox(
                            height: 400,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                top: 16,
                                right: 8,
                                bottom: 24,
                              ),
                              child: LineChart(
                                LineChartData(
                                  minX: appState.getMinX(),
                                  maxX: appState.count - 1,
                                  maxY: appState.getMaxY(),
                                  minY: appState.getMinY(),
                                  clipData: FlClipData.none(),
                                  lineTouchData: LineTouchData(
                                    enabled: true,
                                    touchCallback:
                                        (
                                          FlTouchEvent event,
                                          LineTouchResponse? response,
                                        ) {
                                          if (response != null &&
                                              response.lineBarSpots != null &&
                                              response
                                                  .lineBarSpots!
                                                  .isNotEmpty) {
                                            final touchedIndex = response
                                                .lineBarSpots!
                                                .first
                                                .spotIndex;
                                            if (_lastTouchedIndex !=
                                                touchedIndex) {
                                              _lastTouchedIndex = touchedIndex;
                                              // HapticFeedback.lightImpact();
                                            }
                                          } else {
                                            _lastTouchedIndex = null;
                                          }
                                        },
                                    getTouchedSpotIndicator:
                                        (barData, spotIndexes) {
                                          return spotIndexes.map((index) {
                                            final color =
                                                barData.color ?? Colors.blue;
                                            return TouchedSpotIndicatorData(
                                              FlLine(
                                                color:
                                                    color, // indicator line color
                                                strokeWidth: 2,
                                                dashArray: [
                                                  6,
                                                  3,
                                                ], // dashed line
                                              ),
                                              FlDotData(
                                                show: true,
                                                getDotPainter:
                                                    (
                                                      spot,
                                                      percent,
                                                      bar,
                                                      index,
                                                    ) => FlDotCirclePainter(
                                                      radius: 5,
                                                      color: color,
                                                      strokeWidth: 3,
                                                      strokeColor: color,
                                                    ),
                                              ),
                                            );
                                          }).toList();
                                        },
                                    touchTooltipData: LineTouchTooltipData(
                                      fitInsideHorizontally: true,
                                      fitInsideVertically: true,
                                      tooltipBorderRadius: BorderRadius.all(
                                        Radius.circular(20),
                                      ),
                                      tooltipPadding: EdgeInsets.all(16),
                                      getTooltipColor: (touchedSpots) {
                                        return Theme.of(
                                          context,
                                        ).colorScheme.surfaceContainer;
                                      },
                                      getTooltipItems: (touchedSpots) {
                                        return touchedSpots.map((touchedSpot) {
                                          final color =
                                              touchedSpot.bar.color ??
                                              Colors.blue;
                                          final formatted = formatDouble(
                                            touchedSpot.y,
                                          );
                                          return LineTooltipItem(
                                            formatted,
                                            TextStyle(
                                              color: color,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          );
                                        }).toList();
                                      },
                                    ),
                                  ),
                                  lineBarsData: [
                                    LineChartBarData(
                                      show: appState.averagesShown['single']!,
                                      spots: appState.getRecentSingleList(),
                                      color: averageColors['single']!,
                                      belowBarData: BarAreaData(
                                        show: true,
                                        gradient: LinearGradient(
                                          colors: [
                                            averageColors['single']!.withAlpha(
                                              100,
                                            ),
                                            Colors.transparent,
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                      ),
                                      dotData: FlDotData(show: false),
                                      isCurved: false,
                                    ),

                                    LineChartBarData(
                                      show: appState.averagesShown['mo3']!,
                                      spots: appState.getRecentMo3List(),
                                      color: averageColors['mo3']!,
                                      belowBarData: BarAreaData(
                                        show: true,
                                        gradient: LinearGradient(
                                          colors: [
                                            averageColors['mo3']!.withAlpha(
                                              100,
                                            ),
                                            Colors.transparent,
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                      ),
                                      dotData: FlDotData(show: false),
                                      isCurved: false,
                                    ),

                                    LineChartBarData(
                                      show: appState.averagesShown['ao5']!,
                                      spots: appState.getRecentAo5List(),
                                      color: averageColors['ao5']!,
                                      belowBarData: BarAreaData(
                                        show: true,
                                        gradient: LinearGradient(
                                          colors: [
                                            averageColors['ao5']!.withAlpha(
                                              100,
                                            ),
                                            Colors.transparent,
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                      ),
                                      dotData: FlDotData(show: false),
                                      isCurved: false,
                                    ),

                                    LineChartBarData(
                                      show: appState.averagesShown['ao12']!,
                                      spots: appState.getRecentAo12List(),
                                      color: averageColors['ao12']!,
                                      belowBarData: BarAreaData(
                                        show: true,
                                        gradient: LinearGradient(
                                          colors: [
                                            averageColors['ao12']!.withAlpha(
                                              100,
                                            ),
                                            Colors.transparent,
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                      ),
                                      dotData: FlDotData(show: false),
                                      isCurved: false,
                                    ),
                                  ],
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: false,
                                    drawHorizontalLine: true,
                                    getDrawingHorizontalLine: (value) => FlLine(
                                      color: Colors.grey.withAlpha(50),
                                      strokeWidth: 1,
                                    ),
                                    getDrawingVerticalLine: (value) => FlLine(
                                      color: Colors.grey.withAlpha(50),
                                      strokeWidth: 1,
                                    ),
                                  ),
                                  titlesData: FlTitlesData(
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 40,
                                        getTitlesWidget: (value, meta) {
                                          // Hide the label if it's the topmost (maxY) value
                                          if (value == meta.max ||
                                              value == meta.min) {
                                            return const SizedBox.shrink();
                                          }
                                          return Text(
                                            formatTitle(value),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[700],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: false,
                                        reservedSize: 32,
                                        getTitlesWidget: (value, meta) => Text(
                                          value.toInt().toString(),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ),
                                    ),
                                    rightTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    topTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                  ),
                                  borderData: FlBorderData(
                                    show: false,
                                    border: Border.all(
                                      color: Colors.grey.withAlpha(100),
                                      width: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          Center(
                            child: Wrap(
                              spacing: 8,
                              children: appState.averagesShown.keys.map((avg) {
                                final color = averageColors[avg];
                                return FilterChip(
                                  label: Text(avg),
                                  selected: appState.averagesShown[avg]!,
                                  backgroundColor: color!.withAlpha(50),
                                  selectedColor: color.withAlpha(200),
                                  side: BorderSide(color: Colors.transparent),
                                  onSelected: (selected) {
                                    setState(() {
                                      appState.averagesShown[avg] = selected;
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ),

                          SizedBox(height: 16),

                          TwoColumnTable(
                            rows: [
                              [Text('Best'), Text('${appState.best}')],
                              [Text('Median'), Text('${appState.median}')],
                              [Text('Mean'), Text('${appState.mean}')],
                              [
                                Text('Standard deviation'),
                                Text('${appState.standardDeviation}'),
                              ],
                              [Text('Solves'), Text(appState.numSolves)],
                            ],
                          ),
                          SizedBox(height: 16),
                          TwoColumnTable(
                            title: "Current",
                            rows: [
                              [Text('Mo3'), Text('${appState.currMo3}')],
                              [Text('Ao5'), Text('${appState.currAo5}')],
                              [Text('Ao12'), Text('${appState.currAo12}')],
                              [Text('Ao50'), Text('${appState.currAo50}')],
                              [Text('Ao100'), Text('${appState.currAo100}')],
                            ],
                          ),
                          SizedBox(height: 16),
                          TwoColumnTable(
                            title: "Best",
                            rows: [
                              [
                                Text('Mo3'),
                                Text(
                                  '${appState.bestMo3List.isEmpty ? '--/--' : appState.bestMo3List.last}',
                                ),
                              ],
                              [
                                Text('Ao5'),
                                Text(
                                  '${appState.bestAo5List.isEmpty ? '--/--' : appState.bestAo5List.last}',
                                ),
                              ],
                              [
                                Text('Ao12'),
                                Text(
                                  '${appState.bestAo12List.isEmpty ? '--/--' : appState.bestAo12List.last}',
                                ),
                              ],
                              [
                                Text('Ao50'),
                                Text(
                                  '${appState.bestAo50List.isEmpty ? '--/--' : appState.bestAo50List.last}',
                                ),
                              ],
                              [
                                Text('Ao100'),
                                Text(
                                  '${appState.bestAo100List.isEmpty ? '--/--' : appState.bestAo100List.last}',
                                ),
                              ],
                            ],
                          ),
                          SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),

                if (currResult == "records")
                  Expanded(
                    child: Column(
                      children: [
                        SegmentedButton<String>(
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
                          segments: const <ButtonSegment<String>>[
                            ButtonSegment(value: "single", label: Text('1')),
                            ButtonSegment(value: "mo3", label: Text('3')),
                            ButtonSegment(value: "ao5", label: Text('5')),
                            ButtonSegment(value: "ao12", label: Text('12')),
                            ButtonSegment(value: "ao50", label: Text('50')),
                            ButtonSegment(value: "ao100", label: Text('100')),
                          ],
                          selected: <String>{currRecord},
                          onSelectionChanged: (Set<String> newSelection) {
                            setState(() {
                              currRecord = newSelection.first;
                            });
                          },
                        ),
                        SizedBox(height: 8),
                        Expanded(
                          child: ListView(
                            children: [
                              if (currRecord == "single")
                                TwoColumnTable(
                                  boldLeft: true,
                                  rows: appState.bestSingleList.reversed
                                      .map(
                                        (e) => [
                                          Text(e.toString()),
                                          Text(formatDate(e.date)),
                                        ],
                                      )
                                      .toList(),
                                ),

                              if (currRecord == "mo3")
                                TwoColumnTable(
                                  boldLeft: true,
                                  rows: appState.bestMo3List.reversed
                                      .map(
                                        (e) => [
                                          Text(e.toString()),
                                          Text(formatDate(e.date)),
                                        ],
                                      )
                                      .toList(),
                                ),
                              if (currRecord == "ao5")
                                TwoColumnTable(
                                  boldLeft: true,
                                  rows: appState.bestAo5List.reversed
                                      .map(
                                        (e) => [
                                          Text(e.toString()),
                                          Text(formatDate(e.date)),
                                        ],
                                      )
                                      .toList(),
                                ),
                              if (currRecord == "ao12")
                                TwoColumnTable(
                                  boldLeft: true,
                                  rows: appState.bestAo12List.reversed
                                      .map(
                                        (e) => [
                                          Text(e.toString()),
                                          Text(formatDate(e.date)),
                                        ],
                                      )
                                      .toList(),
                                ),
                              if (currRecord == "ao50")
                                TwoColumnTable(
                                  boldLeft: true,
                                  rows: appState.bestAo50List.reversed
                                      .map(
                                        (e) => [
                                          Text(e.toString()),
                                          Text(formatDate(e.date)),
                                        ],
                                      )
                                      .toList(),
                                ),
                              if (currRecord == "ao100")
                                TwoColumnTable(
                                  boldLeft: true,
                                  rows: appState.bestAo100List.reversed
                                      .map(
                                        (e) => [
                                          Text(e.toString()),
                                          Text(formatDate(e.date)),
                                        ],
                                      )
                                      .toList(),
                                ),
                              SizedBox(height: 10),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
