import 'package:flutter/material.dart';

import '../core/format.dart';
import '../models/medication.dart';
import '../services/patient_store.dart';

/// Historial de tomas (mockup 15, RF-15): confirmadas u omitidas,
/// agrupadas por día, de la más reciente a la más antigua.
class HistoryScreen extends StatefulWidget {
  final PatientStore store;

  const HistoryScreen({super.key, required this.store});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

enum _Filter { all, taken, missed }

class _HistoryScreenState extends State<HistoryScreen> {
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial de tomas')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.store,
          builder: (context, _) {
            final now = DateTime.now();
            final all = widget.store.history(now);
            final entries = all.where((e) {
              switch (_filter) {
                case _Filter.all:
                  return true;
                case _Filter.taken:
                  return e.status == DoseStatus.taken;
                case _Filter.missed:
                  return e.status == DoseStatus.missed;
              }
            }).toList();

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SegmentedButton<_Filter>(
                    segments: const [
                      ButtonSegment(value: _Filter.all, label: Text('Todas')),
                      ButtonSegment(
                          value: _Filter.taken, label: Text('Confirmadas')),
                      ButtonSegment(
                          value: _Filter.missed, label: Text('Omitidas')),
                    ],
                    selected: {_filter},
                    onSelectionChanged: (s) =>
                        setState(() => _filter = s.first),
                  ),
                ),
                Expanded(
                  child: entries.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Todavía no hay tomas en el historial',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                        )
                      : _list(entries, now),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _list(List<HistoryEntry> entries, DateTime now) {
    final children = <Widget>[];
    String? lastDay;
    for (final e in entries) {
      final day = dayLabel(e.scheduled, now);
      if (day != lastDay) {
        children.add(Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
          child: Text(day,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ));
        lastDay = day;
      }
      final taken = e.status == DoseStatus.taken;
      children.add(Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey[300]!),
        ),
        child: ListTile(
          leading: Icon(
            taken ? Icons.check_circle : Icons.cancel_outlined,
            color: taken ? Colors.green : Colors.orange[800],
          ),
          title: Text('${e.medicationName} · ${e.dose}'),
          subtitle: Text(taken ? 'Confirmada' : 'Omitida'),
          trailing: Text(formatTime12(e.scheduled.hour, e.scheduled.minute)),
        ),
      ));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: children,
    );
  }
}
