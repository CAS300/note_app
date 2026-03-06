import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workspace_manifest.dart';
import '../services/workspace_service.dart';

final workspaceServiceProvider = Provider((ref) => WorkspaceService());

class WorkspaceState {
  final String? path;
  final WorkspaceManifest? manifest;

  WorkspaceState({this.path, this.manifest});

  WorkspaceState copyWith({
    String? path,
    WorkspaceManifest? manifest,
  }) {
    return WorkspaceState(
      path: path ?? this.path,
      manifest: manifest ?? this.manifest,
    );
  }
}

class WorkspaceNotifier extends StateNotifier<WorkspaceState> {
  final WorkspaceService _service;

  WorkspaceNotifier(this._service) : super(WorkspaceState());

  Future<void> loadWorkspace(String path) async {
    final manifest = await _service.loadManifest(path);
    if (manifest != null) {
      state = state.copyWith(path: path, manifest: manifest);
    } else {
      final newManifest = await _service.createNewWorkspace(path);
      state = state.copyWith(path: path, manifest: newManifest);
    }
  }

  Future<void> updateManifest(WorkspaceManifest newManifest) async {
    if (state.path != null) {
      await _service.saveManifest(state.path!, newManifest);
      state = state.copyWith(manifest: newManifest);
    }
  }

  void clearWorkspace() {
    state = WorkspaceState();
  }
}

final workspaceProvider =
    StateNotifierProvider<WorkspaceNotifier, WorkspaceState>((ref) {
  final service = ref.watch(workspaceServiceProvider);
  return WorkspaceNotifier(service);
});
