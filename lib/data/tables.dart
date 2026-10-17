import 'package:drift/drift.dart';

import 'converters.dart';

// Port of the Room entities (Story.kt, Chapter.kt, TimelineFrame.kt,
// CharacterGroup.kt, StoryCharacter.kt). Generated row classes keep the same
// names as the Kotlin data classes: Story, Chapter, TimelineFrame,
// CharacterGroup, StoryCharacter.

@DataClassName('Story')
class Stories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();

  /// Short snippet shown in the card list.
  TextColumn get previewText => text().withDefault(const Constant(''))();

  /// Used for "favorites on top" sorting.
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();

  /// Created / last modified time, in milliseconds since epoch.
  IntColumn get timestamp => integer().clientDefault(() => DateTime.now().millisecondsSinceEpoch)();
}

@DataClassName('Chapter')
class Chapters extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get storyId =>
      integer().references(Stories, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text()();
  TextColumn get contentHtml => text().withDefault(const Constant(''))();
  IntColumn get timestamp => integer().clientDefault(() => DateTime.now().millisecondsSinceEpoch)();
  IntColumn get timelineFrameId => integer().nullable()();

  /// Order within a timeline frame, never affected by document reorder.
  IntColumn get timelineOrder => integer().withDefault(const Constant(0))();

  /// Order in the document screen, never affected by timeline reorder.
  IntColumn get documentOrder => integer().withDefault(const Constant(0))();
}

@DataClassName('TimelineFrame')
class TimelineFrames extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get storyId =>
      integer().references(Stories, #id, onDelete: KeyAction.cascade)();

  /// e.g. "Year 1" or "Flashback".
  TextColumn get name => text()();

  /// For drag-and-drop sorting.
  IntColumn get frameOrder => integer()();
}

@DataClassName('CharacterGroup')
class CharacterGroups extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get storyId =>
      integer().references(Stories, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();

  /// 0-5, maps to the character group icon list.
  IntColumn get iconIndex => integer().withDefault(const Constant(0))();
  IntColumn get groupOrder => integer().withDefault(const Constant(0))();
}

@DataClassName('StoryCharacter')
class StoryCharacters extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get storyId =>
      integer().references(Stories, #id, onDelete: KeyAction.cascade)();
  IntColumn get groupId =>
      integer().references(CharacterGroups, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  TextColumn get description => text()();
  TextColumn get attributes => text().map(const StringMapConverter())();
}
