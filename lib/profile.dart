import 'package:firebase_auth/firebase_auth.dart';
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text('${FirebaseAuth.instance.currentUser?.email}'),
          CustomElevatedButton(
            text: 'Toggle Dark Mode',
            onPressed: () {
              // Toggle dark mode
              appState.toggleTheme();
            },
          ),
          CustomElevatedButton(
            text: 'Add Solves',
            onPressed: () {
              // Add solves
              appState.addSolves();
            },
          ),

          CustomElevatedButton(
            text: 'Sign Out',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
    );
  }
}
