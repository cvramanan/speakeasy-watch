import 'package:flutter/material.dart';
import '../services/history_service.dart';
import '../services/tts_service.dart';
import '../widgets/watch_scaffold.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await HistoryService.instance.getRecent();
    if (mounted) setState(() => _items = items);
  }

  @override
  Widget build(BuildContext context) {
    return WatchScaffold(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: _items.isEmpty
          ? const Center(
              child: Text('No history yet',
                  style: TextStyle(fontSize: 11, color: Colors.white38)))
          : ListView.separated(
              itemCount: _items.length,
              separatorBuilder: (_, __) =>
                  Divider(color: Colors.grey.shade800, height: 8),
              itemBuilder: (context, i) {
                final item = _items[i];
                return GestureDetector(
                  onTap: () =>
                      TtsService.instance.speak(item['japanese'] as String),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['japanese'] as String,
                        style: const TextStyle(
                            fontSize: 13, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        item['transcript'] as String,
                        style: TextStyle(
                            fontSize: 9, color: Colors.grey.shade500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
