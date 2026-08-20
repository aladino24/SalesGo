class OutletModel {
  OutletModel({
    required this.id,
    required this.name,
    required this.code,
    required this.address,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.salesResponsible,
    required this.status,
    this.ownerName,
    this.contactName,
    this.phone,
  });

  final String id;
  final String name;
  final String code;
  final String address;
  final String type;
  final double latitude;
  final double longitude;
  final String salesResponsible;
  final String status;
  final String? ownerName;
  final String? contactName;
  final String? phone;

  factory OutletModel.fromJson(Map<String, dynamic> json) {
    return OutletModel(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      address: json['address'] as String,
      type: json['type'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      salesResponsible: json['salesResponsible'] as String,
      status: json['status'] as String,
      ownerName: json['ownerName']?.toString(),
      contactName: json['contactName']?.toString(),
      phone: json['phone']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
        'address': address,
        'type': type,
        'latitude': latitude,
        'longitude': longitude,
        'salesResponsible': salesResponsible,
        'status': status,
        if (ownerName != null) 'ownerName': ownerName,
        if (contactName != null) 'contactName': contactName,
        if (phone != null) 'phone': phone,
      };
}
