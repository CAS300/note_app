import 'database_info.dart';

class WorkspaceManifest {
  final int formatVersion;
  final String appId;
  final String workspaceId;
  final String? activeDb;
  final List<DatabaseInfo> databases;
  final Map<String, dynamic> settings;

  WorkspaceManifest({
    required this.formatVersion,
    required this.appId,
    required this.workspaceId,
    this.activeDb,
    required this.databases,
    required this.settings,
  });

  factory WorkspaceManifest.fromJson(Map<String, dynamic> json) {
    return WorkspaceManifest(
      formatVersion: json['format_version'] as int? ?? 1,
      appId: json['app_id'] as String? ?? 'com.erensahin.notes',
      workspaceId: json['workspace_id'] as String,
      activeDb: json['active_db'] as String?,
      databases: (json['databases'] as List<dynamic>?)
              ?.map((e) => DatabaseInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      settings: (json['settings'] as Map<String, dynamic>?) ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'format_version': formatVersion,
      'app_id': appId,
      'workspace_id': workspaceId,
      'active_db': activeDb,
      'databases': databases.map((e) => e.toJson()).toList(),
      'settings': settings,
    };
  }

  WorkspaceManifest copyWith({
    int? formatVersion,
    String? appId,
    String? workspaceId,
    String? activeDb,
    List<DatabaseInfo>? databases,
    Map<String, dynamic>? settings,
  }) {
    return WorkspaceManifest(
      formatVersion: formatVersion ?? this.formatVersion,
      appId: appId ?? this.appId,
      workspaceId: workspaceId ?? this.workspaceId,
      activeDb: activeDb ?? this.activeDb,
      databases: databases ?? this.databases,
      settings: settings ?? this.settings,
    );
  }
}
