import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/theme/app_colors.dart';
import '../../app/widgets/sfa_feedback_dialog.dart';
import '../../app/widgets/sfa_ui.dart';
import '../../core/localization/app_locale.dart';
import '../../data/models/meeting_model.dart';
import 'meeting_controller.dart';

class MeetingPage extends GetView<MeetingController> {
  const MeetingPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        'Meeting Online',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => _schedule(context),
      icon: const Icon(Icons.add),
      label: const Text('Jadwalkan'),
    ),
    body: Obx(() {
      if (controller.isLoading.value && controller.meetings.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      final today = controller.today;
      return RefreshIndicator(
        onRefresh: controller.load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _HeroCard(
              count: today.length,
              onJoinByCode: () => _joinByCode(context),
            ),
            const SizedBox(height: 22),
            SfaSectionTitle(
              title: 'Meeting Hari Ini',
              actionLabel: today.isEmpty ? null : '${today.length} meeting',
            ),
            const SizedBox(height: 8),
            if (today.isEmpty)
              const _InlineEmpty(
                'Tidak ada meeting hari ini. Jadwalkan meeting baru atau tunggu undangan dari host.',
              )
            else
              ...today.map(
                (item) => _MeetingCard(
                  item: item,
                  onTap: () => Get.toNamed('/meetings/${item.id}'),
                ),
              ),
            const SizedBox(height: 18),
            const SfaSectionTitle(title: 'Mendatang'),
            const SizedBox(height: 8),
            ...controller.meetings
                .where((item) => !today.contains(item) && !item.isCompleted)
                .map(
                  (item) => _MeetingCard(
                    item: item,
                    onTap: () => Get.toNamed('/meetings/${item.id}'),
                  ),
                ),
            if (controller.meetings
                .where((item) => !today.contains(item) && !item.isCompleted)
                .isEmpty)
              const _InlineEmpty('Belum ada jadwal meeting mendatang.'),
            const SizedBox(height: 18),
            const SfaSectionTitle(title: 'Riwayat Meeting'),
            const SizedBox(height: 8),
            ...controller.meetings
                .where((item) => item.isCompleted)
                .map(
                  (item) => _MeetingCard(
                    item: item,
                    onTap: () => Get.toNamed('/meetings/${item.id}'),
                  ),
                ),
            if (controller.meetings.where((item) => item.isCompleted).isEmpty)
              const _InlineEmpty(
                'Riwayat meeting akan tampil setelah meeting selesai.',
              ),
            const SizedBox(height: 18),
            const _MeetingTips(),
          ],
        ),
      );
    }),
  );

  Future<void> _schedule(BuildContext context) async {
    final title = TextEditingController();
    final description = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 9, minute: 0);
    final saved = await Get.dialog<bool>(
      StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Jadwalkan Meeting'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: title,
                  decoration: const InputDecoration(labelText: 'Judul meeting'),
                ),
                TextField(
                  controller: description,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi / agenda',
                  ),
                ),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: Text(
                    AppLocale.date('EEEE, d MMMM y').format(selectedDate),
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      initialDate: selectedDate,
                    );
                    if (date != null) setState(() => selectedDate = date);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.schedule_outlined),
                  title: Text(selectedTime.format(context)),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (time != null) setState(() => selectedTime = time);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Get.back(result: true),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
    if (saved == true && title.text.trim().isNotEmpty) {
      await controller.schedule(
        title: title.text.trim(),
        description: description.text.trim(),
        startsAt: DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          selectedTime.hour,
          selectedTime.minute,
        ),
        duration: const Duration(hours: 1),
      );
      await SfaFeedbackDialog.show(
        type: SfaFeedbackType.success,
        title: 'Meeting dijadwalkan',
        message:
            'Jadwal tersimpan di perangkat dan akan disinkronkan ke server.',
      );
    }
    title.dispose();
    description.dispose();
  }

  Future<void> _joinByCode(BuildContext context) async {
    final code = TextEditingController();
    final joined = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Gabung dengan Meeting ID'),
        content: TextField(
          controller: code,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Meeting ID',
            hintText: 'Contoh: 123 456 7890',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Gabung'),
          ),
        ],
      ),
    );
    if (joined == true && code.text.trim().isNotEmpty) {
      final error = await controller.joinByCode(code.text.trim());
      if (error != null) {
        await SfaFeedbackDialog.show(
          type: SfaFeedbackType.warning,
          title: 'Tidak dapat bergabung',
          message: error,
        );
      }
    }
    code.dispose();
  }
}

class MeetingDetailPage extends GetView<MeetingController> {
  const MeetingDetailPage({super.key});
  @override
  Widget build(BuildContext context) {
    final item = controller.byId(Get.parameters['id'] ?? '');
    if (item == null) {
      return const Scaffold(
        body: SfaEmptyState(
          icon: Icons.videocam_off_outlined,
          title: 'Meeting tidak ditemukan',
          description:
              'Perbarui daftar meeting atau buka kembali dari notifikasi.',
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detail Meeting',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFF5C8DFF)],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.video_call_rounded,
                    color: AppColors.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  item.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                SfaStatusChip(
                  label: _statusText(item.status),
                  color: Colors.white,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _info(Icons.person_outline_rounded, 'Host', item.hostName),
                  _info(
                    Icons.calendar_today_outlined,
                    'Waktu',
                    '${AppLocale.date('EEE, d MMM yyyy').format(item.startsAt)} • ${AppLocale.date('HH:mm').format(item.startsAt)}–${AppLocale.date('HH:mm').format(item.endsAt)}',
                  ),
                  _info(
                    Icons.groups_outlined,
                    'Peserta',
                    '${item.participantCount} peserta',
                  ),
                  if (item.provider.isNotEmpty)
                    _info(
                      Icons.video_settings_outlined,
                      'Provider',
                      item.provider,
                    ),
                ],
              ),
            ),
          ),
          if (item.description.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'Deskripsi',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(item.description),
          ],
          if (item.agenda.isNotEmpty) ...[
            const SizedBox(height: 18),
            const Text('Agenda', style: TextStyle(fontWeight: FontWeight.w800)),
            ...item.agenda.map(
              (agenda) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppColors.primary,
                ),
                title: Text(agenda['title']?.toString() ?? 'Agenda meeting'),
                subtitle: Text(agenda['time']?.toString() ?? ''),
              ),
            ),
          ],
          const SizedBox(height: 24),
          if (item.canJoin)
            FilledButton.icon(
              onPressed: () => _join(item),
              icon: const Icon(Icons.videocam_rounded),
              label: const Text('Gabung Meeting'),
            )
          else
            const SfaStatusChip(
              label: 'Meeting telah selesai',
              color: AppColors.success,
            ),
        ],
      ),
    );
  }

  Widget _info(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 13),
    child: Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 10),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w700)),
        Expanded(child: Text(value)),
      ],
    ),
  );
  Future<void> _join(MeetingModel item) async {
    final error = await controller.join(item);
    if (error != null) {
      await SfaFeedbackDialog.show(
        type: SfaFeedbackType.warning,
        title: 'Tidak dapat bergabung',
        message: error,
      );
    }
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.count, required this.onJoinByCode});
  final int count;
  final VoidCallback onJoinByCode;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF174EBA), AppColors.primary],
      ),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white24,
              child: Icon(
                Icons.videocam_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tetap terhubung',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    count == 0
                        ? 'Tidak ada meeting hari ini'
                        : '$count meeting dijadwalkan hari ini',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: onJoinByCode,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white54),
          ),
          icon: const Icon(Icons.key_rounded),
          label: const Text('Gabung dengan ID'),
        ),
      ],
    ),
  );
}

class _MeetingCard extends StatelessWidget {
  const _MeetingCard({required this.item, required this.onTap});
  final MeetingModel item;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.all(12),
      leading: Container(
        width: 52,
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              DateFormat.Hm().format(item.startsAt),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            const Text(
              'WIB',
              style: TextStyle(fontSize: 9, color: AppColors.primary),
            ),
          ],
        ),
      ),
      title: Text(
        item.title,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text('${item.hostName} • ${item.participantCount} peserta'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SfaStatusChip(
            label: _statusText(item.status),
            color: _statusColor(item.status),
          ),
          const SizedBox(height: 5),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    ),
  );
}

class _InlineEmpty extends StatelessWidget {
  const _InlineEmpty(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        text,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
    ),
  );
}

class _MeetingTips extends StatelessWidget {
  const _MeetingTips();
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Tips Meeting Online',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 10),
          Text('• Pastikan koneksi internet stabil.'),
          SizedBox(height: 6),
          Text('• Gunakan headset bila tersedia.'),
          SizedBox(height: 6),
          Text('• Bergabung beberapa menit sebelum dimulai.'),
        ],
      ),
    ),
  );
}

String _statusText(String status) {
  switch (status.toLowerCase()) {
    case 'ongoing':
      return 'Berlangsung';
    case 'completed':
      return 'Selesai';
    case 'cancelled':
      return 'Dibatalkan';
    default:
      return 'Akan Datang';
  }
}

Color _statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'ongoing':
      return AppColors.success;
    case 'completed':
      return AppColors.textSecondary;
    case 'cancelled':
      return AppColors.danger;
    default:
      return AppColors.warning;
  }
}
