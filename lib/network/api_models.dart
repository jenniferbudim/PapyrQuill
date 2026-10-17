// Port of ApiModels.kt: data transfer objects for the PHP/MySQL backend.
//
// Every PHP response looks like {"success":true,"data":{...}}.
// PHP/MySQL often returns numbers as strings and booleans as 0/1, so the
// parsing helpers below accept either form.

int _int(dynamic v) => v is int ? v : int.parse(v.toString());

int? _intOrNull(dynamic v) => v == null ? null : _int(v);

bool _bool(dynamic v) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  final s = v.toString().toLowerCase();
  return s == '1' || s == 'true';
}

String _str(dynamic v) => v?.toString() ?? '';

Map<String, String> _stringMap(dynamic v) {
  if (v is Map) {
    return v.map((k, val) => MapEntry(k.toString(), val.toString()));
  }
  return <String, String>{};
}

int _now() => DateTime.now().millisecondsSinceEpoch;

/// Drops null entries, so unchanged fields are omitted from update requests
/// (the Kotlin side relied on Gson skipping nulls).
Map<String, dynamic> _compact(Map<String, dynamic> m) =>
    m..removeWhere((_, v) => v == null);

// ── Story ────────────────────────────────────────────────────────────────────

class StoryDto {
  StoryDto({
    required this.id,
    required this.title,
    required this.previewText,
    required this.isFavorite,
    required this.timestamp,
    required this.updatedAt,
  });

  final int id;
  final String title;
  final String previewText;
  final bool isFavorite;
  final int timestamp;
  final int updatedAt;

  factory StoryDto.fromJson(Map<String, dynamic> j) => StoryDto(
        id: _int(j['id']),
        title: _str(j['title']),
        previewText: _str(j['previewText']),
        isFavorite: _bool(j['isFavorite'] ?? false),
        timestamp: _int(j['timestamp']),
        updatedAt: _int(j['updatedAt'] ?? j['timestamp']),
      );
}

class CreateStoryRequest {
  CreateStoryRequest({
    required this.title,
    this.previewText = '',
    this.isFavorite = 0,
    int? timestamp,
  }) : timestamp = timestamp ?? _now();

  final String title;
  final String previewText;
  final int isFavorite;
  final int timestamp;

  Map<String, dynamic> toJson() => {
        'title': title,
        'previewText': previewText,
        'isFavorite': isFavorite,
        'timestamp': timestamp,
      };
}

class UpdateStoryRequest {
  UpdateStoryRequest({this.title, this.previewText, this.isFavorite, int? updatedAt})
      : updatedAt = updatedAt ?? _now();

  final String? title;
  final String? previewText;
  final int? isFavorite;
  final int updatedAt;

  Map<String, dynamic> toJson() => _compact({
        'title': title,
        'previewText': previewText,
        'isFavorite': isFavorite,
        'updatedAt': updatedAt,
      });
}

// ── Chapter ──────────────────────────────────────────────────────────────────

class ChapterDto {
  ChapterDto({
    required this.id,
    required this.storyId,
    required this.title,
    required this.contentHtml,
    required this.timestamp,
    required this.updatedAt,
    required this.timelineFrameId,
    required this.timelineOrder,
    required this.documentOrder,
  });

  final int id;
  final int storyId;
  final String title;

  /// Null in list responses: the server omits it for performance. Use
  /// GET chapters.php?id=X to get the full content.
  final String? contentHtml;
  final int timestamp;
  final int updatedAt;
  final int? timelineFrameId;
  final int timelineOrder;
  final int documentOrder;

  factory ChapterDto.fromJson(Map<String, dynamic> j) => ChapterDto(
        id: _int(j['id']),
        storyId: _int(j['storyId']),
        title: _str(j['title']),
        contentHtml: j['contentHtml']?.toString(),
        timestamp: _int(j['timestamp']),
        updatedAt: _int(j['updatedAt'] ?? j['timestamp']),
        timelineFrameId: _intOrNull(j['timelineFrameId']),
        timelineOrder: _int(j['timelineOrder'] ?? 0),
        documentOrder: _int(j['documentOrder'] ?? 0),
      );
}

class CreateChapterRequest {
  CreateChapterRequest({
    required this.storyId,
    required this.title,
    this.contentHtml = '',
    this.timelineOrder = 0,
    this.documentOrder = 0,
    int? timestamp,
  }) : timestamp = timestamp ?? _now();

  final int storyId;
  final String title;
  final String contentHtml;
  final int timelineOrder;
  final int documentOrder;
  final int timestamp;

  Map<String, dynamic> toJson() => {
        'storyId': storyId,
        'title': title,
        'contentHtml': contentHtml,
        'timelineOrder': timelineOrder,
        'documentOrder': documentOrder,
        'timestamp': timestamp,
      };
}

class UpdateChapterRequest {
  UpdateChapterRequest({
    this.title,
    this.contentHtml,
    this.timelineFrameId,
    this.timelineOrder,
    this.documentOrder,
    int? updatedAt,
  }) : updatedAt = updatedAt ?? _now();

  final String? title;
  final String? contentHtml;
  final int? timelineFrameId;
  final int? timelineOrder;
  final int? documentOrder;
  final int updatedAt;

  Map<String, dynamic> toJson() => _compact({
        'title': title,
        'contentHtml': contentHtml,
        'timelineFrameId': timelineFrameId,
        'timelineOrder': timelineOrder,
        'documentOrder': documentOrder,
        'updatedAt': updatedAt,
      });
}

// ── Character group ──────────────────────────────────────────────────────────

class CharacterGroupDto {
  CharacterGroupDto({
    required this.id,
    required this.storyId,
    required this.name,
    required this.iconIndex,
    required this.groupOrder,
  });

  final int id;
  final int storyId;
  final String name;
  final int iconIndex;
  final int groupOrder;

  factory CharacterGroupDto.fromJson(Map<String, dynamic> j) => CharacterGroupDto(
        id: _int(j['id']),
        storyId: _int(j['storyId']),
        name: _str(j['name']),
        iconIndex: _int(j['iconIndex'] ?? 0),
        groupOrder: _int(j['groupOrder'] ?? 0),
      );
}

class CreateGroupRequest {
  CreateGroupRequest({
    required this.storyId,
    required this.name,
    this.iconIndex = 0,
    this.groupOrder = 0,
  });

  final int storyId;
  final String name;
  final int iconIndex;
  final int groupOrder;

  Map<String, dynamic> toJson() => {
        'storyId': storyId,
        'name': name,
        'iconIndex': iconIndex,
        'groupOrder': groupOrder,
      };
}

class UpdateGroupRequest {
  UpdateGroupRequest({this.name, this.iconIndex, this.groupOrder});

  final String? name;
  final int? iconIndex;
  final int? groupOrder;

  Map<String, dynamic> toJson() => _compact({
        'name': name,
        'iconIndex': iconIndex,
        'groupOrder': groupOrder,
      });
}

// ── Story character ──────────────────────────────────────────────────────────

class CharacterDto {
  CharacterDto({
    required this.id,
    required this.storyId,
    required this.groupId,
    required this.name,
    required this.description,
    required this.attributes,
  });

  final int id;
  final int storyId;
  final int groupId;
  final String name;
  final String description;
  final Map<String, String> attributes;

  factory CharacterDto.fromJson(Map<String, dynamic> j) => CharacterDto(
        id: _int(j['id']),
        storyId: _int(j['storyId']),
        groupId: _int(j['groupId']),
        name: _str(j['name']),
        description: _str(j['description']),
        attributes: _stringMap(j['attributes']),
      );
}

class CreateCharacterRequest {
  CreateCharacterRequest({
    required this.storyId,
    required this.groupId,
    required this.name,
    this.description = '',
    this.attributes = const {},
  });

  final int storyId;
  final int groupId;
  final String name;
  final String description;
  final Map<String, String> attributes;

  Map<String, dynamic> toJson() => {
        'storyId': storyId,
        'groupId': groupId,
        'name': name,
        'description': description,
        'attributes': attributes,
      };
}

class UpdateCharacterRequest {
  UpdateCharacterRequest({this.groupId, this.name, this.description, this.attributes});

  final int? groupId;
  final String? name;
  final String? description;
  final Map<String, String>? attributes;

  Map<String, dynamic> toJson() => _compact({
        'groupId': groupId,
        'name': name,
        'description': description,
        'attributes': attributes,
      });
}

// ── Timeline frame ───────────────────────────────────────────────────────────

class TimelineFrameDto {
  TimelineFrameDto({
    required this.id,
    required this.storyId,
    required this.name,
    required this.frameOrder,
  });

  final int id;
  final int storyId;
  final String name;
  final int frameOrder;

  factory TimelineFrameDto.fromJson(Map<String, dynamic> j) => TimelineFrameDto(
        id: _int(j['id']),
        storyId: _int(j['storyId']),
        name: _str(j['name']),
        frameOrder: _int(j['frameOrder'] ?? 0),
      );
}

class CreateFrameRequest {
  CreateFrameRequest({required this.storyId, required this.name, this.frameOrder = 0});

  final int storyId;
  final String name;
  final int frameOrder;

  Map<String, dynamic> toJson() => {
        'storyId': storyId,
        'name': name,
        'frameOrder': frameOrder,
      };
}

// ── Bulk sync ────────────────────────────────────────────────────────────────

class SyncStoryDto {
  SyncStoryDto({
    required this.id,
    required this.title,
    required this.previewText,
    required this.isFavorite,
    required this.timestamp,
    required this.updatedAt,
  });

  final int id;
  final String title;
  final String previewText;
  final int isFavorite;
  final int timestamp;
  final int updatedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'previewText': previewText,
        'isFavorite': isFavorite,
        'timestamp': timestamp,
        'updatedAt': updatedAt,
      };
}

class SyncChapterDto {
  SyncChapterDto({
    required this.id,
    required this.storyId,
    required this.title,
    required this.contentHtml,
    required this.timestamp,
    required this.updatedAt,
    required this.timelineFrameId,
    required this.timelineOrder,
    required this.documentOrder,
  });

  final int id;
  final int storyId;
  final String title;
  final String contentHtml;
  final int timestamp;
  final int updatedAt;
  final int? timelineFrameId;
  final int timelineOrder;
  final int documentOrder;

  // timelineFrameId is left out when unset.
  Map<String, dynamic> toJson() => {
        'id': id,
        'storyId': storyId,
        'title': title,
        'contentHtml': contentHtml,
        'timestamp': timestamp,
        'updatedAt': updatedAt,
        if (timelineFrameId != null) 'timelineFrameId': timelineFrameId,
        'timelineOrder': timelineOrder,
        'documentOrder': documentOrder,
      };
}

class SyncGroupDto {
  SyncGroupDto({
    required this.id,
    required this.storyId,
    required this.name,
    required this.iconIndex,
    required this.groupOrder,
  });

  final int id;
  final int storyId;
  final String name;
  final int iconIndex;
  final int groupOrder;

  Map<String, dynamic> toJson() => {
        'id': id,
        'storyId': storyId,
        'name': name,
        'iconIndex': iconIndex,
        'groupOrder': groupOrder,
      };
}

class SyncCharacterDto {
  SyncCharacterDto({
    required this.id,
    required this.storyId,
    required this.groupId,
    required this.name,
    required this.description,
    required this.attributes,
  });

  final int id;
  final int storyId;
  final int groupId;
  final String name;
  final String description;
  final Map<String, String> attributes;

  Map<String, dynamic> toJson() => {
        'id': id,
        'storyId': storyId,
        'groupId': groupId,
        'name': name,
        'description': description,
        'attributes': attributes,
      };
}

class SyncFrameDto {
  SyncFrameDto({
    required this.id,
    required this.storyId,
    required this.name,
    required this.frameOrder,
  });

  final int id;
  final int storyId;
  final String name;
  final int frameOrder;

  Map<String, dynamic> toJson() => {
        'id': id,
        'storyId': storyId,
        'name': name,
        'frameOrder': frameOrder,
      };
}

class SyncRequest {
  SyncRequest({
    this.stories = const [],
    this.chapters = const [],
    this.groups = const [],
    this.characters = const [],
    this.frames = const [],
  });

  final List<SyncStoryDto> stories;
  final List<SyncChapterDto> chapters;
  final List<SyncGroupDto> groups;
  final List<SyncCharacterDto> characters;
  final List<SyncFrameDto> frames;

  Map<String, dynamic> toJson() => {
        'stories': stories.map((e) => e.toJson()).toList(),
        'chapters': chapters.map((e) => e.toJson()).toList(),
        'groups': groups.map((e) => e.toJson()).toList(),
        'characters': characters.map((e) => e.toJson()).toList(),
        'frames': frames.map((e) => e.toJson()).toList(),
      };
}

class SyncCounts {
  SyncCounts({
    required this.stories,
    required this.chapters,
    required this.groups,
    required this.characters,
    required this.frames,
  });

  final int stories;
  final int chapters;
  final int groups;
  final int characters;
  final int frames;

  factory SyncCounts.fromJson(Map<String, dynamic> j) => SyncCounts(
        stories: _int(j['stories'] ?? 0),
        chapters: _int(j['chapters'] ?? 0),
        groups: _int(j['groups'] ?? 0),
        characters: _int(j['characters'] ?? 0),
        frames: _int(j['frames'] ?? 0),
      );
}

class SyncResult {
  SyncResult({required this.message, required this.synced, required this.syncedAt});

  final String message;
  final SyncCounts synced;
  final int syncedAt;

  factory SyncResult.fromJson(Map<String, dynamic> j) => SyncResult(
        message: _str(j['message']),
        synced: SyncCounts.fromJson((j['synced'] as Map).cast<String, dynamic>()),
        syncedAt: _int(j['syncedAt'] ?? 0),
      );
}

class MutationResult {
  MutationResult({this.id, this.updated, this.deleted});

  final int? id;
  final bool? updated;
  final bool? deleted;

  /// The PHP endpoints answer {"id": 12}; a bare number is accepted as well.
  factory MutationResult.parse(dynamic data) {
    if (data is Map) {
      return MutationResult.fromJson(data.cast<String, dynamic>());
    }
    if (data is num || data is String) {
      return MutationResult(id: _intOrNull(data));
    }
    return MutationResult();
  }

  factory MutationResult.fromJson(Map<String, dynamic> j) => MutationResult(
        id: _intOrNull(j['id']),
        updated: j['updated'] == null ? null : _bool(j['updated']),
        deleted: j['deleted'] == null ? null : _bool(j['deleted']),
      );
}
