import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../models/workspace_manifest.dart';
import '../models/database_info.dart';
import '../core/constants.dart';
import '../core/utils.dart';

class WorkspaceService {
  Future<WorkspaceManifest?> loadManifest(String workspacePath) async {
    final file = File(p.join(workspacePath, AppConstants.manifestFileName));
    if (!await file.exists()) {
      return null;
    }
    
    final content = await file.readAsString();
    final json = jsonDecode(content) as Map<String, dynamic>;
    return WorkspaceManifest.fromJson(json);
  }

  Future<WorkspaceManifest> createNewWorkspace(String workspacePath) async {
    const uuid = Uuid();
    final defaultDb = DatabaseInfo(
      name: AppConstants.defaultDbName,
      label: AppConstants.defaultDbLabel,
      createdAt: AppUtils.currentTimestamp(),
    );

    final manifest = WorkspaceManifest(
      formatVersion: 1,
      appId: AppConstants.appId,
      workspaceId: uuid.v4(),
      activeDb: defaultDb.name,
      databases: [defaultDb],
      settings: {},
    );

    await saveManifest(workspacePath, manifest);
    return manifest;
  }

  Future<void> saveManifest(String workspacePath, WorkspaceManifest manifest) async {
    final file = File(p.join(workspacePath, AppConstants.manifestFileName));
    final tempFile = File(p.join(workspacePath, '${AppConstants.manifestFileName}.tmp'));
    
    final content = jsonEncode(manifest.toJson());
    await tempFile.writeAsString(content);
    
    if (await file.exists()) {
      await file.delete();
    }
    await tempFile.rename(file.path);
  }
}
