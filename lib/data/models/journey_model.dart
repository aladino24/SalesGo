class JourneyModel {
  const JourneyModel({required this.id, required this.type, required this.destination, required this.startAt, required this.endAt, required this.status, required this.createdAt, this.salesName = 'Sales', this.approvalStatus = 'Not Required'});
  final String id, type, destination, status, salesName, approvalStatus;
  final DateTime startAt, endAt, createdAt;
  factory JourneyModel.fromJson(Map<String, dynamic> json) => JourneyModel(id: json['id'].toString(), type: json['type']?.toString() ?? 'in_city', destination: json['destination']?.toString() ?? '-', startAt: DateTime.parse(json['startAt']?.toString() ?? json['createdAt'].toString()), endAt: DateTime.parse(json['endAt']?.toString() ?? json['createdAt'].toString()), status: json['status']?.toString() ?? 'Planned', salesName: json['salesName']?.toString() ?? 'Sales', approvalStatus: json['approvalStatus']?.toString() ?? 'Not Required', createdAt: DateTime.parse(json['createdAt'].toString()));
  Map<String, dynamic> toJson() => {'id': id, 'type': type, 'destination': destination, 'startAt': startAt.toIso8601String(), 'endAt': endAt.toIso8601String(), 'status': status, 'salesName': salesName, 'approvalStatus': approvalStatus, 'createdAt': createdAt.toIso8601String()};
  JourneyModel copyWith({String? status, String? approvalStatus}) => JourneyModel(id: id, type: type, destination: destination, startAt: startAt, endAt: endAt, status: status ?? this.status, salesName: salesName, approvalStatus: approvalStatus ?? this.approvalStatus, createdAt: createdAt);
}
