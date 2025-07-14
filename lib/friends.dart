import 'package:flutter/material.dart';

class FriendsPage extends StatelessWidget {
  const FriendsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // return Center(child: Text('Your friends will appear here.'));
    return ListView(
      children: List.generate(
        20,
        (index) => ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text('F${index + 1}', style: TextStyle(color: Colors.white)),
          ),
          title: Text('Friend ${index + 1}'),
          subtitle: Text('This is friend number ${index + 1}.'),
        ),
      ),
    );
  }
}
