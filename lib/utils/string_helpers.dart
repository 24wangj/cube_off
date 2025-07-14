import 'solve.dart';

String formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes % 60;
  final seconds = duration.inSeconds % 60;
  final milliseconds = duration.inMilliseconds % 1000;

  if (hours > 0) {
    return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${milliseconds.toString().padLeft(3, '0')}';
  } else if (minutes > 0) {
    return '$minutes:${seconds.toString().padLeft(2, '0')}.${milliseconds.toString().padLeft(3, '0')}';
  } else {
    return '$seconds.${milliseconds.toString().padLeft(3, '0')}';
  }
}

String displaySolveTime(Duration time, Penalty penalty) {
  if (penalty == Penalty.dnf) {
    return 'DNF';
  } else if (penalty == Penalty.plusTwo) {
    return '${formatDuration(time + const Duration(seconds: 2))}+';
  } else {
    return formatDuration(time);
  }
}

String formatDate(DateTime date) {
  return '${date.day}/${date.month}/${date.year}';
}

Duration? parseDuration(String input) {
  final regexWithHours = RegExp(
    r'^(\d{1,2}):(\d{2}):(\d{2})\.(\d{1,3})$',
  ); // hh:mm:ss.SSS
  final regexNoHours = RegExp(r'^(\d{1,2}):(\d{2})\.(\d{1,3})$'); // mm:ss.SSS

  final trimmed = input.trim();

  final matchWithHours = regexWithHours.firstMatch(trimmed);
  if (matchWithHours != null) {
    final hours = int.parse(matchWithHours.group(1)!);
    final minutes = int.parse(matchWithHours.group(2)!);
    final seconds = int.parse(matchWithHours.group(3)!);
    final milliseconds = int.parse(matchWithHours.group(4)!.padRight(3, '0'));
    return Duration(
      hours: hours,
      minutes: minutes,
      seconds: seconds,
      milliseconds: milliseconds,
    );
  }

  final matchNoHours = regexNoHours.firstMatch(trimmed);
  if (matchNoHours != null) {
    final minutes = int.parse(matchNoHours.group(1)!);
    final seconds = int.parse(matchNoHours.group(2)!);
    final milliseconds = int.parse(matchNoHours.group(3)!.padRight(3, '0'));
    return Duration(
      minutes: minutes,
      seconds: seconds,
      milliseconds: milliseconds,
    );
  }

  return null; // Invalid format
}
