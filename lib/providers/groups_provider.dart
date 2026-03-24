import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/group.dart';
import '../data/repositories/groups_repository.dart';
import 'database_provider.dart';

/// State for groups + active group filter.
class GroupsState {
  final List<Group> groups;

  /// null = show all notes; non-null = filter by this group ID.
  final int? activeGroupId;

  GroupsState({this.groups = const [], this.activeGroupId});

  GroupsState copyWith(
      {List<Group>? groups, int? activeGroupId, bool clearFilter = false}) {
    return GroupsState(
      groups: groups ?? this.groups,
      activeGroupId: clearFilter ? null : (activeGroupId ?? this.activeGroupId),
    );
  }

  /// Find group by ID from current list.
  Group? groupById(int? id) {
    if (id == null) return null;
    try {
      return groups.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }
}

class GroupsNotifier extends StateNotifier<GroupsState> {
  GroupsRepository? _repo;

  GroupsNotifier() : super(GroupsState());

  void attach(GroupsRepository repo) {
    _repo = repo;
    reload();
  }

  void detach() {
    _repo = null;
    state = GroupsState();
  }

  void reload() {
    if (_repo == null) return;
    final all = _repo!.getAll();
    // If active filter group was deleted, reset filter.
    final stillExists = state.activeGroupId != null &&
        all.any((g) => g.id == state.activeGroupId);
    state = GroupsState(
      groups: all,
      activeGroupId: stillExists ? state.activeGroupId : null,
    );
  }

  void setFilter(int? groupId) {
    state =
        state.copyWith(activeGroupId: groupId, clearFilter: groupId == null);
  }

  void createGroup(String name, String color) {
    if (_repo == null) return;
    _repo!.create(name: name, color: color);
    reload();
  }

  void renameGroup(int id, String newName) {
    if (_repo == null) return;
    _repo!.rename(id, newName);
    reload();
  }

  void updateGroupColor(int id, String newColor) {
    if (_repo == null) return;
    _repo!.updateColor(id, newColor);
    reload();
  }

  void deleteGroup(int id) {
    if (_repo == null) return;
    _repo!.delete(id);
    reload();
  }
}

final groupsProvider =
    StateNotifierProvider<GroupsNotifier, GroupsState>((ref) {
  final notifier = GroupsNotifier();

  ref.listen<DatabaseState>(databaseProvider, (prev, next) {
    if (next.isConnected && next.groupsService != null) {
      notifier.attach(GroupsRepository(next.groupsService!));
    } else {
      notifier.detach();
    }
  });

  final dbState = ref.read(databaseProvider);
  if (dbState.isConnected && dbState.groupsService != null) {
    notifier.attach(GroupsRepository(dbState.groupsService!));
  }

  return notifier;
});
