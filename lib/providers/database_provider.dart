import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_service.dart';
import '../services/notes_service.dart';
import '../services/groups_service.dart';
import 'workspace_provider.dart';
import '../core/utils.dart';
import '../models/database_info.dart';

final databaseServiceProvider = Provider((ref) => DatabaseService());

class DatabaseState {
  final bool isConnected;
  final String? activeDbName;
  final NotesService? notesService;
  final GroupsService? groupsService;

  DatabaseState({
    this.isConnected = false,
    this.activeDbName,
    this.notesService,
    this.groupsService,
  });
}

class DatabaseNotifier extends StateNotifier<DatabaseState> {
  final DatabaseService _dbService;
  final Ref _ref;

  DatabaseNotifier(this._dbService, this._ref) : super(DatabaseState());

  void connect(String workspacePath, String dbName) {
    _dbService.openDatabase(workspacePath, dbName);
    final db = _dbService.db;
    final ns = db != null ? NotesService(db) : null;
    final gs = db != null ? GroupsService(db) : null;
    state = DatabaseState(
      isConnected: true,
      activeDbName: dbName,
      notesService: ns,
      groupsService: gs,
    );
  }

  void disconnect() {
    _dbService.closeDatabase();
    state = DatabaseState(
      isConnected: false,
      activeDbName: null,
      notesService: null,
      groupsService: null,
    );
  }

  Future<void> switchDatabase(String dbName) async {
    final workspaceState = _ref.read(workspaceProvider);
    if (workspaceState.path == null || workspaceState.manifest == null) return;

    connect(workspaceState.path!, dbName);

    final updatedManifest = workspaceState.manifest!.copyWith(activeDb: dbName);
    await _ref.read(workspaceProvider.notifier).updateManifest(updatedManifest);
  }

  Future<String?> createNewDatabase(String label) async {
    final workspaceState = _ref.read(workspaceProvider);
    if (workspaceState.path == null || workspaceState.manifest == null) {
      return "No workspace active";
    }

    final safeName = label.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_');
    final fullDbName = "$safeName.db";

    final exists =
        await _dbService.databaseExists(workspaceState.path!, fullDbName);
    if (exists) {
      return "Database file already exists";
    }

    final newDbInfo = DatabaseInfo(
      name: fullDbName,
      label: label,
      createdAt: AppUtils.currentTimestamp(),
    );

    final updatedDatabases =
        List<DatabaseInfo>.from(workspaceState.manifest!.databases)
          ..add(newDbInfo);
    final updatedManifest =
        workspaceState.manifest!.copyWith(databases: updatedDatabases);

    await _ref.read(workspaceProvider.notifier).updateManifest(updatedManifest);
    return null;
  }

  Future<String?> addExistingDatabase(String fileDbName) async {
    final workspaceState = _ref.read(workspaceProvider);
    if (workspaceState.path == null || workspaceState.manifest == null) {
      return "No workspace";
    }

    final exists =
        await _dbService.databaseExists(workspaceState.path!, fileDbName);
    if (!exists) {
      return "This database file was not found in workspace";
    }

    final alreadyInManifest =
        workspaceState.manifest!.databases.any((db) => db.name == fileDbName);
    if (alreadyInManifest) {
      return "Database already in workspace";
    }

    final newDbInfo = DatabaseInfo(
      name: fileDbName,
      label: fileDbName.replaceAll('.db', ''),
      createdAt: AppUtils.currentTimestamp(),
    );

    final updatedDatabases =
        List<DatabaseInfo>.from(workspaceState.manifest!.databases)
          ..add(newDbInfo);
    final updatedManifest =
        workspaceState.manifest!.copyWith(databases: updatedDatabases);

    await _ref.read(workspaceProvider.notifier).updateManifest(updatedManifest);
    return null;
  }
}

final databaseProvider =
    StateNotifierProvider<DatabaseNotifier, DatabaseState>((ref) {
  final service = ref.watch(databaseServiceProvider);
  return DatabaseNotifier(service, ref);
});
