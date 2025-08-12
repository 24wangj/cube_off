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
          return Container(
            margin: EdgeInsets.only(left: 10, right: 10, bottom: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: ListTile(
              title: Text(solve.time.toString()),
              subtitle: Text(solve.scramble, overflow: TextOverflow.ellipsis),
              onTap: () => {
                showModalBottomSheet(
                  context: context,
                  builder: (BuildContext context) => SizedBox(
                    height: MediaQuery.of(context).size.height * 0.1,
                    // return Container(
                    //   child: Center(child: Text(solve.time.toString())),
                    // );
                    child: DraggableScrollableSheet(
                      initialChildSize: 1,
                      builder: (context, scrollController) {
                        return Container(height: 3020, child: Text("sds"));
                      },
                    ),
                  ),
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainer,
                  showDragHandle: true,
                  isScrollControlled: true,
                ),
              },
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
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
    );
  }
}
