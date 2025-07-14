import 'package:flutter/material.dart';
import 'package:flutter_js/flutter_js.dart';
import 'package:flutter/services.dart' show rootBundle;

class CubeScramblePage extends StatefulWidget {
  const CubeScramblePage({super.key});

  @override
  State<CubeScramblePage> createState() => _CubeScramblePageState();
}

class _CubeScramblePageState extends State<CubeScramblePage> {
  final JavascriptRuntime jsRuntime = getJavascriptRuntime();
  String scramble = 'Loading...';

  @override
  void initState() {
    super.initState();
    print('Initializing Cube Scramble Page');
    _loadCubeJs();
    // _generateScramble();
  }

  Future<void> _loadCubeJs() async {
    final scrambowJs = await rootBundle.loadString('assets/scrambow.min.js');
    jsRuntime.evaluate(scrambowJs);

    final cubeJsCode = await rootBundle.loadString('assets/scrambler.js');
    jsRuntime.evaluate(cubeJsCode);
    // _generateScramble();
  }

  void _generateScramble() {
    final result = jsRuntime.evaluate('cube.scramble();');
    setState(() {
      scramble = result.stringResult;
    });
  }

  void _generateScramble4() {
    final result = jsRuntime.evaluate('cube.scramble4();');
    setState(() {
      scramble = result.stringResult;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Random Cube Scramble")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              scramble,
              style: const TextStyle(fontSize: 24),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _generateScramble,
              child: const Text("New Scramble"),
            ),
            ElevatedButton(
              onPressed: _generateScramble4,
              child: const Text("New Scramble"),
            ),
          ],
        ),
      ),
    );
  }
}
