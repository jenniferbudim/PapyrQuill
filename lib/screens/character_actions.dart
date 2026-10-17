import '../data/app_database.dart';
import '../repository/papyr_repository.dart';

/// The write operations of CharacterViewModel.kt. Reading groups and
/// characters is done with groupsProvider / charactersProvider.
class CharacterActions {
  CharacterActions(this._repo);

  final PapyrRepository _repo;

  /// Creates a group and returns its id, so the screen can open it right away
  /// (Kotlin: lastCreatedGroupId).
  Future<int> createGroup(
    int storyId,
    String name,
    int iconIndex,
    int currentCount,
  ) {
    return _repo.insertGroup(
      CharacterGroup(
        id: 0,
        storyId: storyId,
        name: name,
        iconIndex: iconIndex,
        groupOrder: currentCount,
      ),
    );
  }

  Future<void> deleteGroup(CharacterGroup group) => _repo.deleteGroup(group);

  Future<void> addCharacter({
    required int storyId,
    required int groupId,
    required String name,
    required String description,
    required Map<String, String> attributes,
  }) {
    return _repo.insertCharacter(
      StoryCharacter(
        id: 0,
        storyId: storyId,
        groupId: groupId,
        name: name,
        description: description,
        attributes: attributes,
      ),
    );
  }

  Future<void> updateCharacter(StoryCharacter character) =>
      _repo.updateCharacter(character);

  Future<void> deleteCharacter(StoryCharacter character) =>
      _repo.deleteCharacter(character);
}
