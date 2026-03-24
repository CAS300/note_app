import '../../models/group.dart';
import '../../services/groups_service.dart';

/// Thin wrapper over GroupsService.
class GroupsRepository {
  final GroupsService _service;

  GroupsRepository(this._service);

  List<Group> getAll() => _service.fetchAll();
  Group? getById(int id) => _service.fetchById(id);
  Group create({required String name, required String color}) =>
      _service.create(name: name, color: color);
  void rename(int id, String newName) => _service.rename(id, newName);
  void updateColor(int id, String newColor) =>
      _service.updateColor(id, newColor);
  void delete(int id) => _service.delete(id);
}
