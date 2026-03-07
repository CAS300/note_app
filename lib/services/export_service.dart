import 'dart:io';
import 'package:path/path.dart' as p;

class ExportResult {
  final bool success;
  final String? error;

  ExportResult.success()
      : success = true,
        error = null;

  ExportResult.failure(this.error) : success = false;
}

/// Simple service to export/copy the active database and workspace manifest
/// to a user-selected local directory.
class ExportService {
  /// Exports the workspace data to the specified [targetDirPath].
  ///
  /// Requires the [workspacePath] to locate the manifest (`.notes_workspace.json`),
  /// and the [activeDbName] to locate the active database file (e.g. `work.db`).
  Future<ExportResult> exportToLocalDrive({
    required String targetDirPath,
    required String workspacePath,
    required String activeDbName,
  }) async {
    try {
      final targetDir = Directory(targetDirPath);
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      final sourceDbPath = p.join(workspacePath, activeDbName);
      final sourceDbFile = File(sourceDbPath);

      final sourceManifestPath = p.join(workspacePath, '.notes_workspace.json');
      final sourceManifestFile = File(sourceManifestPath);

      if (!await sourceDbFile.exists()) {
        return ExportResult.failure(
            'Aktif veritabanı dosyası bulunamadı ($sourceDbPath).');
      }

      // Copy Database
      final targetDbPath = p.join(targetDir.path, activeDbName);
      await sourceDbFile.copy(targetDbPath);

      // Copy Manifest if exists
      if (await sourceManifestFile.exists()) {
        final targetManifestPath =
            p.join(targetDir.path, '.notes_workspace.json');
        await sourceManifestFile.copy(targetManifestPath);
      }

      return ExportResult.success();
    } catch (e) {
      return ExportResult.failure('Dışa aktarma sırasında hata oluştu: $e');
    }
  }
}
