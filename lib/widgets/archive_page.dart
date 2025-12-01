import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ArchivePage extends StatefulWidget {
  const ArchivePage({super.key});

  @override
  State<ArchivePage> createState() => _ArchivePageState();
}

class _ArchivePageState extends State<ArchivePage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool _loading = true;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final snap = await _db
        .collection('daily_scrambles')
        .orderBy('date', descending: true)
        .limit(200)
        .get();
    final list = snap.docs.map((d) {
      final data = d.data();
      return {
        'id': d.id,
        'date': DateTime.fromMillisecondsSinceEpoch(data['date'] as int),
        'scramble': data['scramble'] as String? ?? '',
      };
    }).toList();
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Archive')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, i) {
                final it = _items[i];
                final date = it['date'] as DateTime;
                return ListTile(
                  title: Text('${date.month}/${date.day}/${date.year}'),
                  subtitle: Text(it['scramble']),
                );
              },
            ),
    );
  }
}
