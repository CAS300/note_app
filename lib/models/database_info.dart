class DatabaseInfo {
  final String name;
  final String label;
  final int createdAt;

  DatabaseInfo({
    required this.name,
    required this.label,
    required this.createdAt,
  });

  factory DatabaseInfo.fromJson(Map<String, dynamic> json) {
    return DatabaseInfo(
      name: json['name'] as String,
      label: json['label'] as String,
      createdAt: json['created_at'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'label': label,
      'created_at': createdAt,
    };
  }
}
