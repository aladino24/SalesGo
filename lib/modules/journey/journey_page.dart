import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/sync/sync_manager.dart';
import '../../data/datasources/local/visit_local_data_source.dart';
import '../../data/models/visit_model.dart';

class JourneyPage extends StatelessWidget {
  const JourneyPage({super.key});

  Future<void> _createJourney(BuildContext context, bool outOfTown) async {
    final box = Hive.isBoxOpen('journeys') ? Hive.box('journeys') : await Hive.openBox('journeys');
    const uuid = Uuid();
    final id = uuid.v4();
    final payload = {'id': id, 'type': outOfTown ? 'out_of_town' : 'in_city', 'status': 'Planned', 'createdAt': DateTime.now().toIso8601String()};
    await box.put(id, payload);
    await Get.find<SyncManager>().queueItem(type: 'journey_create', endpoint: '/journeys', method: 'POST', payload: payload, uuid: id, idempotencyKey: uuid.v4());
    Get.snackbar('Perjalanan dibuat', 'Perjalanan tersimpan lokal dan menunggu sync.');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Perjalanan Sales', style: TextStyle(fontWeight: FontWeight.w800))),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      const _RouteProgressCard(),
      const SizedBox(height: 20),
      const Text('Buat Perjalanan', style: TextStyle(fontWeight: FontWeight.w800)),
      const SizedBox(height: 10),
      FilledButton.icon(onPressed: () => _createJourney(context, false), icon: const Icon(Icons.location_city_rounded), label: const Text('Perjalanan Dalam Kota')),
      const SizedBox(height: 10),
      OutlinedButton.icon(onPressed: () => _createJourney(context, true), icon: const Icon(Icons.luggage_rounded), label: const Text('Perjalanan Luar Kota')),
    ]),
  );
}

class _RouteProgressCard extends StatelessWidget {
  const _RouteProgressCard();

  @override
  Widget build(BuildContext context) => FutureBuilder<List<VisitModel>>(
    future: VisitLocalDataSource().getVisits(),
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Card(child: ListTile(leading: CircleAvatar(child: Icon(Icons.route_rounded)), title: Text('Memuat progres rute...')));
      }
      final today = DateTime.now();
      final visits = (snapshot.data ?? []).where((visit) {
        final date = visit.createdAt.toLocal();
        return date.year == today.year && date.month == today.month && date.day == today.day;
      }).toList();
      final total = visits.length;
      final visited = visits.where((visit) => visit.status == 'Completed').length;
      final progress = total == 0 ? 0 : (visited / total * 100).round();
      return Card(child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.route_rounded)),
        title: const Text('Rute hari ini', style: TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(total == 0 ? 'Belum ada outlet pada rute hari ini' : '$total outlet • $visited dikunjungi'),
        trailing: Text('$progress%', style: const TextStyle(fontWeight: FontWeight.w800)),
      ));
    },
  );
}
