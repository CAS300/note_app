class Note {
  final int? id;
  final String title;
  final String content;
  final List<int> groupIds;
  final int createdAt;
  final int updatedAt;
  final bool isDeleted;
  final int sortOrder;
  final bool isShortcut;

  Note({
    this.id,
    required this.title,
    required this.content,
    this.groupIds = const [],
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    this.sortOrder = 0,
    this.isShortcut = false,
  });

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as int,
      title: map['title'] as String,
      content: map['content'] as String,
      groupIds: _parseGroupIds(map['groups_concat'] as String?),
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
      isDeleted: (map['is_deleted'] as int) == 1,
      sortOrder: (map['sort_order'] as int?) ?? 0,
      isShortcut: ((map['is_shortcut'] as int?) ?? 0) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'content': content,
      // groupIds is managed separately in NoteGroups table, but can be left here to avoid breaking callers not ready yet.
      'created_at': createdAt,
      'updated_at': updatedAt,
      'is_deleted': isDeleted ? 1 : 0,
      'sort_order': sortOrder,
      'is_shortcut': isShortcut ? 1 : 0,
    };
  }

  Note copyWith({
    int? id,
    String? title,
    String? content,
    List<int>? groupIds,
    int? createdAt,
    int? updatedAt,
    bool? isDeleted,
    int? sortOrder,
    bool? isShortcut,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      groupIds: groupIds ?? this.groupIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      sortOrder: sortOrder ?? this.sortOrder,
      isShortcut: isShortcut ?? this.isShortcut,
    );
  }

  static List<int> _parseGroupIds(String? groupsConcat) {
    if (groupsConcat == null || groupsConcat.isEmpty) return [];
    return groupsConcat.split(',').map((e) => int.tryParse(e)).where((e) => e != null).cast<int>().toList();
  }
}
