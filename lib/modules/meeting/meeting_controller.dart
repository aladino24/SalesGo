import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../core/auth/session_service.dart';
import '../../core/network/network_info.dart';
import '../../data/models/meeting_model.dart';
import '../../data/repositories/meeting_repository.dart';

class MeetingController extends GetxController {
  MeetingController({MeetingRepository? repository, NetworkInfo? networkInfo, SessionService? session})
      : _repository = repository ?? MeetingRepository(),
        _networkInfo = networkInfo ?? Get.find<NetworkInfo>(),
        _session = session ?? Get.find<SessionService>();

  final MeetingRepository _repository;
  final NetworkInfo _networkInfo;
  final SessionService _session;
  final meetings = <MeetingModel>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      meetings.assignAll(await _repository.getMeetings(online: await _networkInfo.isConnected));
    } finally {
      isLoading.value = false;
    }
  }

  List<MeetingModel> get today {
    final now = DateTime.now();
    return meetings.where((item) => item.startsAt.year == now.year && item.startsAt.month == now.month && item.startsAt.day == now.day).toList();
  }

  MeetingModel? byId(String id) {
    for (final item in meetings) {
      if (item.id == id) return item;
    }
    return null;
  }

  Future<void> schedule({required String title, required String description, required DateTime startsAt, required Duration duration}) async {
    const uuid = Uuid();
    final item = MeetingModel(
      id: uuid.v4(), title: title, description: description, startsAt: startsAt, endsAt: startsAt.add(duration),
      status: 'Upcoming', hostName: _session.userName.value.isEmpty ? 'Saya' : _session.userName.value, participantCount: 0,
    );
    await _repository.schedule(item);
    meetings.add(item);
    meetings.sort((a, b) => a.startsAt.compareTo(b.startsAt));
    meetings.refresh();
  }

  Future<String?> join(MeetingModel item) async {
    final url = await _repository.join(item, online: await _networkInfo.isConnected);
    return _openJoinUrl(url);
  }

  Future<String?> joinByCode(String meetingId) async {
    if (!await _networkInfo.isConnected) return 'Gabung dengan Meeting ID memerlukan koneksi internet.';
    final url = await _repository.joinByCode(meetingId);
    return _openJoinUrl(url);
  }

  Future<String?> _openJoinUrl(String url) async {
    if (url.isEmpty) return 'Tautan meeting belum tersedia. Hubungi host atau coba lagi saat online.';
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.scheme == 'https' || uri.scheme == 'http' || uri.scheme == 'zoomus' || uri.scheme == 'msteams')) return 'Tautan meeting tidak valid.';
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) return 'Aplikasi meeting tidak dapat dibuka pada perangkat ini.';
    return null;
  }
}
