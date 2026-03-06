/// Represents a note group / folder.
class Group {
  final int? id;
  final String name;
  final String color; // hex string, e.g. '#2563EB'
  final int createdAt;

  Group({
    this.id,
    required this.name,
    required this.color,
    required this.createdAt,
  });

  factory Group.fromMap(Map<String, dynamic> map) {
    return Group(
      id: map['id'] as int,
      name: map['name'] as String,
      color: map['color'] as String,
      createdAt: map['created_at'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'color': color,
      'created_at': createdAt,
    };
  }

  Group copyWith({int? id, String? name, String? color, int? createdAt}) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Curated color palette for groups.
class GroupColors {
  GroupColors._();

  static const List<String> palette = [
    '#2563EB', // blue
    '#7C3AED', // purple
    '#DB2777', // pink
    '#DC2626', // red
    '#F97316', // orange
    '#EAB308', // yellow
    '#22C55E', // green
    '#06B6D4', // cyan
    '#6366F1', // indigo
    '#84CC16', // lime
  ];

  static const String defaultColor = '#2563EB';
}
