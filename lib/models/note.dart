class Note {
  final int? id;
  final String title;
  final String content;
  final int? groupId;
  final int createdAt;
  final int updatedAt;
  final bool isDeleted;
  final int sortOrder;

  Note({
    this.id,
    required this.title,
    required this.content,
    this.groupId,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    this.sortOrder = 0,
  });

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as int,
      title: map['title'] as String,
      content: map['content'] as String,
      groupId: map['group_id'] as int?,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
      isDeleted: (map['is_deleted'] as int) == 1,
      sortOrder: (map['sort_order'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'content': content,
      'group_id': groupId,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'is_deleted': isDeleted ? 1 : 0,
      'sort_order': sortOrder,
    };
  }

  Note copyWith({
    int? id,
    String? title,
    String? content,
    int? groupId,
    int? createdAt,
    int? updatedAt,
    bool? isDeleted,
    int? sortOrder,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      groupId: groupId ?? this.groupId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
