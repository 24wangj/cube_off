import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'utils/widgets.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    var appState = Provider.of<AppState>(context);
    return Center(
      child: CustomElevatedButton(
        text: 'Toggle Dark Mode',
        onPressed: () {
          // Toggle dark mode
          appState.toggleTheme();
        },
      ),
    );
  }
}
