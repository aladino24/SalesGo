import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/network/api_endpoints.dart';
import '../../data/models/outlet_model.dart';
import '../../data/repositories/visit_action_repository.dart';
import '../../data/datasources/local/visit_local_data_source.dart';
import '../../app/widgets/sfa_feedback_dialog.dart';

enum VisitActionType { defer, cancel, approval }

extension VisitActionTypeX on VisitActionType {
  String get title => switch (this) {
    VisitActionType.defer => 'Tunda Kunjungan',
    VisitActionType.cancel => 'Batalkan Kunjungan',
    VisitActionType.approval => 'Ajukan Approval Visit',
  };
  String get endpoint => switch (this) {
    VisitActionType.defer => ApiEndpoints.deferVisit,
    VisitActionType.cancel => ApiEndpoints.cancelVisit,
    VisitActionType.approval => ApiEndpoints.visitApprovals,
  };
  String get type => switch (this) {
    VisitActionType.defer => 'defer',
    VisitActionType.cancel => 'cancel',
    VisitActionType.approval => 'approval_request',
  };
}

class VisitActionPage extends StatefulWidget {
  const VisitActionPage({
    super.key,
    required this.outlet,
    required this.action,
    required this.visitId,
  });
  final OutletModel outlet;
  final VisitActionType action;
  final String visitId;
  @override
  State<VisitActionPage> createState() => _VisitActionPageState();
}

class _VisitActionPageState extends State<VisitActionPage> {
  final _reason = TextEditingController();
  final _repository = VisitActionRepository();
  final _localVisits = VisitLocalDataSource();
  DateTime? _followUp;
  bool _saving = false;
  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_reason.text.trim().isEmpty) {
      SfaFeedbackDialog.show(
        type: SfaFeedbackType.warning,
        title: 'Alasan wajib',
        message: 'Tuliskan alasan untuk melanjutkan.',
      );
      return;
    }
    if (widget.action == VisitActionType.defer && _followUp == null) {
      SfaFeedbackDialog.show(
        type: SfaFeedbackType.warning,
        title: 'Tanggal wajib',
        message: 'Pilih jadwal kunjungan berikutnya.',
      );
      return;
    }
    setState(() => _saving = true);
    await _repository.submit(
      type: widget.action.type,
      endpoint: widget.action.endpoint,
      outletId: widget.outlet.id,
      visitId: widget.visitId,
      reason: _reason.text.trim(),
      followUpAt: _followUp?.toIso8601String(),
    );
    await _localVisits.updateStatus(
      widget.visitId,
      widget.action == VisitActionType.defer ? 'Deferred' : 'Cancelled',
    );
    if (!mounted) return;
    setState(() => _saving = false);
    Get.back(result: true);
    await SfaFeedbackDialog.show(
      type: SfaFeedbackType.success,
      title: 'Terkirim',
      message: '${widget.action.title} tersimpan dan menunggu sync.',
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.action.title,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.storefront_rounded),
            title: Text(widget.outlet.name),
            subtitle: Text(widget.outlet.address),
          ),
        ),
        const SizedBox(height: 18),
        if (widget.action == VisitActionType.defer)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Jadwal kunjungan berikutnya'),
            subtitle: Text(
              _followUp == null
                  ? 'Belum dipilih'
                  : '${_followUp!.day}/${_followUp!.month}/${_followUp!.year}',
            ),
            trailing: const Icon(Icons.calendar_today_outlined),
            onTap: () async {
              final selected = await showDatePicker(
                context: context,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (selected != null) setState(() => _followUp = selected);
            },
          ),
        TextField(
          controller: _reason,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Alasan',
            hintText: 'Tuliskan alasan dengan jelas',
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Kirim'),
        ),
      ],
    ),
  );
}
