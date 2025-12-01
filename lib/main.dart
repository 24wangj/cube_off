import 'package:cube_off/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:awesome_bottom_bar/awesome_bottom_bar.dart';
import 'package:awesome_bottom_bar/widgets/inspired/inspired.dart';
import 'package:provider/provider.dart';

import 'home.dart';
import 'friends.dart';
// timer and results removed from bottom nav; pages still available elsewhere
import 'profile.dart';
import 'app_state.dart';
import 'signup.dart';
import 'login.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState(),
      builder: ((context, child) => const MainApp()),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    var appState = Provider.of<AppState>(context);
    final Color theColor = const Color.fromARGB(255, 255, 45, 59);
    return MaterialApp(
      title: 'Cube Off',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: theColor,
          primary: theColor,
          surface: Colors.grey.shade200,
          surfaceContainer: Colors.white,
          // surface: Colors.white,
          // surfaceContainer: Colors.grey.shade200,
          onPrimary: Colors.black,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: theColor,
          primary: theColor,
          // surface: const Color.fromARGB(255, 33, 34, 50),
          // surfaceContainer: const Color.fromARGB(255, 25, 26, 37),
          surface: const Color.fromARGB(255, 25, 26, 37),
          surfaceContainer: const Color.fromARGB(255, 33, 34, 50),
          onPrimary: Colors.white,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      // home: MainPage(),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/home': (context) => const MainPage(),
      },
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

const List<TabItem> items = [
  TabItem(icon: Icons.home, title: 'Home'),
  TabItem(icon: Icons.people, title: 'Friends'),
  TabItem(icon: Icons.account_box, title: 'Profile'),
];

class _MainPageState extends State<MainPage> {
  var currIndex = 0;

  bool _timerRunning = false;
  // Timer running handler removed (unused) - keep field for potential use.

  @override
  Widget build(BuildContext context) {
    Widget page;

    switch (currIndex) {
      case 0:
        page = HomePage();
        break;
      case 1:
        page = FriendsPage();
        break;
      case 2:
        page = ProfilePage();
        break;
      default:
        throw UnimplementedError('No widget for $currIndex');
    }

    return Scaffold(
      extendBody: true,
      // appBar: _timerRunning
      //     ? null
      //     : AppBar(
      //         title: const Text('Awesome App Bar'),
      //         centerTitle: true,
      //         backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      //         surfaceTintColor:
      //             Colors.transparent, // Prevents dimming/tinting on scroll
      //       ),
      body: Container(
        color: Theme.of(context).colorScheme.surface,
        child: page,
      ),
      bottomNavigationBar: _timerRunning
          ? null
          : BottomBarInspiredOutside(
              items: items,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
              color: Theme.of(context).colorScheme.onPrimary,
              colorSelected: Colors.white,
              indexSelected: currIndex,
              onTap: (int index) => setState(() {
                currIndex = index;
              }),
              // top: -25,
              animated: true,
              itemStyle: ItemStyle.hexagon,
              chipStyle: ChipStyle(
                background: Theme.of(context).colorScheme.primary,
                drawHexagon: true,
              ),
            ),
    );
  }
}
