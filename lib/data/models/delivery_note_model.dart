class DeliveryNoteModel {
  const DeliveryNoteModel({required this.id, required this.number, required this.destination, required this.items, required this.status, required this.approvalStatus, required this.createdAt});
  final String id, number, destination, status, approvalStatus;
  final List<Map<String, dynamic>> items;
  final DateTime createdAt;
  factory DeliveryNoteModel.fromJson(Map<String, dynamic> json) => DeliveryNoteModel(id: json['id'].toString(), number: json['number']?.toString() ?? '-', destination: json['destination']?.toString() ?? '-', items: (json['items'] as List? ?? []).whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList(), status: json['status']?.toString() ?? 'Draft', approvalStatus: json['approvalStatus']?.toString() ?? 'Waiting Approval', createdAt: DateTime.parse(json['createdAt'].toString()));
  Map<String, dynamic> toJson() => {'id': id, 'number': number, 'destination': destination, 'items': items, 'status': status, 'approvalStatus': approvalStatus, 'createdAt': createdAt.toIso8601String()};
  DeliveryNoteModel copyWith({String? status, String? approvalStatus}) => DeliveryNoteModel(id: id, number: number, destination: destination, items: items, status: status ?? this.status, approvalStatus: approvalStatus ?? this.approvalStatus, createdAt: createdAt);
}
