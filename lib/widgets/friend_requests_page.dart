import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/friend_service.dart';

class FriendRequestsPage extends StatefulWidget {
  const FriendRequestsPage({super.key});

  @override
  State<FriendRequestsPage> createState() => _FriendRequestsPageState();
}

class _FriendRequestsPageState extends State<FriendRequestsPage> {
  final FriendService _friendService = FriendService();
  List<Map<String, dynamic>> _incoming = [];
  bool _loading = true;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // We need the firebase user id; get from FirebaseAuth.
    final firebaseUid = FirebaseAuth.instance.currentUser?.uid;
    if (firebaseUid == null) {
      setState(() {
        _incoming = [];
        _loading = false;
      });
      return;
    }

    final list = await _friendService.getIncomingRequests(firebaseUid);
    final enriched = <Map<String, dynamic>>[];
    for (final id in list) {
      try {
        final doc = await _db.collection('users').doc(id).get();
        final data = doc.data();
        String? display;
        String? email;
        if (data != null) {
          if (data['displayName'] is String) {
            display = data['displayName'] as String;
          }
          if (data['email'] is String) {
            email = data['email'] as String;
          }
        }
        enriched.add({'id': id, 'displayName': display, 'email': email});
      } catch (_) {
        enriched.add({'id': id, 'displayName': null});
      }
    }
    if (!mounted) return;
    setState(() {
      _incoming = enriched;
      _loading = false;
    });
  }

  Future<void> _accept(String fromId) async {
    final firebaseUid = FirebaseAuth.instance.currentUser?.uid;
    if (firebaseUid == null) return;
    await _friendService.acceptFriendRequest(firebaseUid, fromId);
    await _load();
  }

  Future<void> _reject(String fromId) async {
    final firebaseUid = FirebaseAuth.instance.currentUser?.uid;
    if (firebaseUid == null) return;
    await _friendService.rejectFriendRequest(firebaseUid, fromId);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Friend Requests')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _incoming.isEmpty
          ? const Center(child: Text('No incoming friend requests'))
          : ListView.builder(
              itemCount: _incoming.length,
              itemBuilder: (context, i) {
                final item = _incoming[i];
                final id = item['id'] as String;
                final display = (item['displayName'] as String?) ?? id;
                final email = (item['email'] as String?) ?? id;
                return ListTile(
                  title: Text(display),
                  subtitle: Text(email),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check),
                        onPressed: () => _accept(id),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => _reject(id),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
