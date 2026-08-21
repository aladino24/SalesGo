class MeetingModel {
  const MeetingModel({
    required this.id,
    required this.title,
    required this.startsAt,
    required this.endsAt,
    required this.status,
    required this.hostName,
    required this.participantCount,
    this.description = '',
    this.provider = '',
    this.joinUrl = '',
    this.agenda = const [],
  });

  final String id;
  final String title;
  final DateTime startsAt;
  final DateTime endsAt;
  final String status;
  final String hostName;
  final int participantCount;
  final String description;
  final String provider;
  final String joinUrl;
  final List<Map<String, dynamic>> agenda;

  bool get canJoin => status.toLowerCase() == 'ongoing' || status.toLowerCase() == 'upcoming';
  bool get isCompleted => status.toLowerCase() == 'completed';

  factory MeetingModel.fromJson(Map<String, dynamic> json) {
    DateTime date(String key, DateTime fallback) => DateTime.tryParse(json[key]?.toString() ?? '') ?? fallback;
    final now = DateTime.now();
    return MeetingModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Meeting tanpa judul',
      startsAt: date('startsAt', now),
      endsAt: date('endsAt', now.add(const Duration(hours: 1))),
      status: json['status']?.toString() ?? 'Upcoming',
      hostName: json['hostName']?.toString() ?? json['host']?.toString() ?? 'Belum ditentukan',
      participantCount: int.tryParse(json['participantCount']?.toString() ?? '') ?? ((json['participants'] as List?)?.length ?? 0),
      description: json['description']?.toString() ?? '',
      provider: json['provider']?.toString() ?? '',
      joinUrl: json['joinUrl']?.toString() ?? '',
      agenda: (json['agenda'] as List? ?? const []).whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'startsAt': startsAt.toIso8601String(),
        'endsAt': endsAt.toIso8601String(),
        'status': status,
        'hostName': hostName,
        'participantCount': participantCount,
        'description': description,
        'provider': provider,
        'joinUrl': joinUrl,
        'agenda': agenda,
      };
}
