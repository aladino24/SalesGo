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
      // API Laravel dapat mengirim primary key sebagai integer, sementara
      // identitas pada aplikasi/offline queue memakai String. Normalisasi ini
      // tidak mengubah nilainya (contoh 12 menjadi "12"), hanya membuat
      // kontrak mobile aman untuk payload JSON yang valid.
      id: _string(json['id']),
      name: _string(json['name']),
      code: _string(json['code']),
      address: _string(json['address']),
      type: _string(json['type']),
      latitude: _double(json['latitude']),
      longitude: _double(json['longitude']),
      // Outlet yang belum ditugaskan ke sales memang dikirim server sebagai
      // null. Master snapshot tetap harus dapat diunduh dalam kondisi itu.
      salesResponsible: json['salesResponsible']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Active',
      ownerName: json['ownerName']?.toString(),
      contactName: json['contactName']?.toString(),
      phone: json['phone']?.toString(),
    );
  }

  static String _string(dynamic value, {String fallback = ''}) =>
      value?.toString() ?? fallback;

  static double _double(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
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
