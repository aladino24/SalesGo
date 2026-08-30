import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/theme/app_colors.dart';
import '../../core/auth/session_service.dart';
import '../../data/models/outlet_model.dart';

class OutletSalesScheduleCard extends StatelessWidget {
  const OutletSalesScheduleCard({super.key, required this.schedules});
  final List<OutletSalesSchedule> schedules;

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionService>();
    const days = ['', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [Icon(Icons.groups_rounded, color: AppColors.primary), SizedBox(width: 8), Text('Jadwal Sales ke Outlet', style: TextStyle(fontWeight: FontWeight.w800))]),
          const SizedBox(height: 10),
          ...schedules.map((schedule) {
            final mine = schedule.salesId == session.userId.value || (schedule.employeeCode.isNotEmpty && schedule.employeeCode == session.employeeCode.value);
            final day = schedule.dayOfWeek >= 1 && schedule.dayOfWeek <= 7 ? days[schedule.dayOfWeek] : 'Hari -';
            return Container(
              margin: const EdgeInsets.only(bottom: 7),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(color: mine ? AppColors.primarySoft : const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: mine ? AppColors.primary : const Color(0xFFE5EAF2))),
              child: Row(children: [
                CircleAvatar(radius: 15, backgroundColor: mine ? AppColors.primary : Colors.white, child: Icon(Icons.person_rounded, size: 17, color: mine ? Colors.white : AppColors.textSecondary)),
                const SizedBox(width: 9),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(schedule.name, style: TextStyle(fontWeight: FontWeight.w800, color: mine ? AppColors.primary : null)), Text('$day • Minggu ke-${schedule.weekOfMonth}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))])),
                if (mine) const Chip(label: Text('Anda', style: TextStyle(fontSize: 10)), visualDensity: VisualDensity.compact),
              ]),
            );
          }),
        ]),
      ),
    );
  }
}
