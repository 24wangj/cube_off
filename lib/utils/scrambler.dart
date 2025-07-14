import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_js/flutter_js.dart';

class Scrambler {
  static final Scrambler _instance = Scrambler._internal();
  factory Scrambler() => _instance;
  Scrambler._internal();

  final JavascriptRuntime jsRuntime = getJavascriptRuntime();
  bool _initialized = false;

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    final scrambowJs = await rootBundle.loadString('assets/scrambow.min.js');
    jsRuntime.evaluate(scrambowJs);

    final cubeJsCode = await rootBundle.loadString('assets/scrambler.js');
    jsRuntime.evaluate(cubeJsCode);

    _initialized = true;
  }
}
