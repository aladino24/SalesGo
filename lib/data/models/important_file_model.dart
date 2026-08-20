class ImportantFileModel {
  const ImportantFileModel({
    required this.id,
    required this.name,
    required this.type,
    required this.size,
    required this.version,
    required this.updatedAt,
    this.cachePath,
    this.cachedAt,
  });

  final String id;
  final String name;
  final String type;
  final int size;
  final String version;
  final DateTime updatedAt;
  final String? cachePath;
  final DateTime? cachedAt;

  bool get isCached => cachePath != null && cachePath!.isNotEmpty;

  factory ImportantFileModel.fromJson(Map<String, dynamic> json) => ImportantFileModel(
        id: json['id'].toString(),
        name: json['name']?.toString() ?? 'Tanpa nama',
        type: json['type']?.toString() ?? 'file',
        size: (json['size'] as num?)?.toInt() ?? 0,
        version: json['version']?.toString() ?? '-',
        updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
        cachePath: json['cachePath']?.toString(),
        cachedAt: DateTime.tryParse(json['cachedAt']?.toString() ?? ''),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'size': size,
        'version': version,
        'updatedAt': updatedAt.toIso8601String(),
        if (cachePath != null) 'cachePath': cachePath,
        if (cachedAt != null) 'cachedAt': cachedAt!.toIso8601String(),
      };

  ImportantFileModel copyWith({String? cachePath, DateTime? cachedAt}) => ImportantFileModel(
        id: id,
        name: name,
        type: type,
        size: size,
        version: version,
        updatedAt: updatedAt,
        cachePath: cachePath ?? this.cachePath,
        cachedAt: cachedAt ?? this.cachedAt,
      );
}
