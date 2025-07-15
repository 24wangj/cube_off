import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'utils/string_helpers.dart';

class ResultsPage extends StatelessWidget {
  const ResultsPage({super.key});

  @override
  Widget build(BuildContext context) {
    var appState = Provider.of<AppState>(context);
    return Center(
      child: ListView.builder(
        itemCount: appState.solves.length,
        itemBuilder: (context, index) {
          var solve = appState.solves.reversed.elementAt(index);
          return ListTile(
            title: Text(solve.time.toString()),
            subtitle: Text(solve.scramble),
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                '${index + 1}',
                style: TextStyle(color: Colors.white),
              ),
            ),
            trailing: Text(formatDate(solve.date)),
          );
        },
      ),
    );
  }
}
