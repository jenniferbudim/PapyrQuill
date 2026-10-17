// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $StoriesTable extends Stories with TableInfo<$StoriesTable, Story> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _previewTextMeta =
      const VerificationMeta('previewText');
  @override
  late final GeneratedColumn<String> previewText = GeneratedColumn<String>(
      'preview_text', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _isFavoriteMeta =
      const VerificationMeta('isFavorite');
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
      'is_favorite', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_favorite" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<int> timestamp = GeneratedColumn<int>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      clientDefault: () => DateTime.now().millisecondsSinceEpoch);
  @override
  List<GeneratedColumn> get $columns =>
      [id, title, previewText, isFavorite, timestamp];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stories';
  @override
  VerificationContext validateIntegrity(Insertable<Story> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('preview_text')) {
      context.handle(
          _previewTextMeta,
          previewText.isAcceptableOrUnknown(
              data['preview_text']!, _previewTextMeta));
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
          _isFavoriteMeta,
          isFavorite.isAcceptableOrUnknown(
              data['is_favorite']!, _isFavoriteMeta));
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Story map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Story(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      previewText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}preview_text'])!,
      isFavorite: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_favorite'])!,
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}timestamp'])!,
    );
  }

  @override
  $StoriesTable createAlias(String alias) {
    return $StoriesTable(attachedDatabase, alias);
  }
}

class Story extends DataClass implements Insertable<Story> {
  final int id;
  final String title;

  /// Short snippet shown in the card list.
  final String previewText;

  /// Used for "favorites on top" sorting.
  final bool isFavorite;

  /// Created / last modified time, in milliseconds since epoch.
  final int timestamp;
  const Story(
      {required this.id,
      required this.title,
      required this.previewText,
      required this.isFavorite,
      required this.timestamp});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['preview_text'] = Variable<String>(previewText);
    map['is_favorite'] = Variable<bool>(isFavorite);
    map['timestamp'] = Variable<int>(timestamp);
    return map;
  }

  StoriesCompanion toCompanion(bool nullToAbsent) {
    return StoriesCompanion(
      id: Value(id),
      title: Value(title),
      previewText: Value(previewText),
      isFavorite: Value(isFavorite),
      timestamp: Value(timestamp),
    );
  }

  factory Story.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Story(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      previewText: serializer.fromJson<String>(json['previewText']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      timestamp: serializer.fromJson<int>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'previewText': serializer.toJson<String>(previewText),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'timestamp': serializer.toJson<int>(timestamp),
    };
  }

  Story copyWith(
          {int? id,
          String? title,
          String? previewText,
          bool? isFavorite,
          int? timestamp}) =>
      Story(
        id: id ?? this.id,
        title: title ?? this.title,
        previewText: previewText ?? this.previewText,
        isFavorite: isFavorite ?? this.isFavorite,
        timestamp: timestamp ?? this.timestamp,
      );
  Story copyWithCompanion(StoriesCompanion data) {
    return Story(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      previewText:
          data.previewText.present ? data.previewText.value : this.previewText,
      isFavorite:
          data.isFavorite.present ? data.isFavorite.value : this.isFavorite,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Story(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('previewText: $previewText, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, title, previewText, isFavorite, timestamp);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Story &&
          other.id == this.id &&
          other.title == this.title &&
          other.previewText == this.previewText &&
          other.isFavorite == this.isFavorite &&
          other.timestamp == this.timestamp);
}

class StoriesCompanion extends UpdateCompanion<Story> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> previewText;
  final Value<bool> isFavorite;
  final Value<int> timestamp;
  const StoriesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.previewText = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.timestamp = const Value.absent(),
  });
  StoriesCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.previewText = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.timestamp = const Value.absent(),
  }) : title = Value(title);
  static Insertable<Story> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? previewText,
    Expression<bool>? isFavorite,
    Expression<int>? timestamp,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (previewText != null) 'preview_text': previewText,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (timestamp != null) 'timestamp': timestamp,
    });
  }

  StoriesCompanion copyWith(
      {Value<int>? id,
      Value<String>? title,
      Value<String>? previewText,
      Value<bool>? isFavorite,
      Value<int>? timestamp}) {
    return StoriesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      previewText: previewText ?? this.previewText,
      isFavorite: isFavorite ?? this.isFavorite,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (previewText.present) {
      map['preview_text'] = Variable<String>(previewText.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<int>(timestamp.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoriesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('previewText: $previewText, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }
}

class $ChaptersTable extends Chapters with TableInfo<$ChaptersTable, Chapter> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChaptersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _storyIdMeta =
      const VerificationMeta('storyId');
  @override
  late final GeneratedColumn<int> storyId = GeneratedColumn<int>(
      'story_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _contentHtmlMeta =
      const VerificationMeta('contentHtml');
  @override
  late final GeneratedColumn<String> contentHtml = GeneratedColumn<String>(
      'content_html', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<int> timestamp = GeneratedColumn<int>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      clientDefault: () => DateTime.now().millisecondsSinceEpoch);
  static const VerificationMeta _timelineFrameIdMeta =
      const VerificationMeta('timelineFrameId');
  @override
  late final GeneratedColumn<int> timelineFrameId = GeneratedColumn<int>(
      'timeline_frame_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _timelineOrderMeta =
      const VerificationMeta('timelineOrder');
  @override
  late final GeneratedColumn<int> timelineOrder = GeneratedColumn<int>(
      'timeline_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _documentOrderMeta =
      const VerificationMeta('documentOrder');
  @override
  late final GeneratedColumn<int> documentOrder = GeneratedColumn<int>(
      'document_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        storyId,
        title,
        contentHtml,
        timestamp,
        timelineFrameId,
        timelineOrder,
        documentOrder
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chapters';
  @override
  VerificationContext validateIntegrity(Insertable<Chapter> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('story_id')) {
      context.handle(_storyIdMeta,
          storyId.isAcceptableOrUnknown(data['story_id']!, _storyIdMeta));
    } else if (isInserting) {
      context.missing(_storyIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('content_html')) {
      context.handle(
          _contentHtmlMeta,
          contentHtml.isAcceptableOrUnknown(
              data['content_html']!, _contentHtmlMeta));
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    }
    if (data.containsKey('timeline_frame_id')) {
      context.handle(
          _timelineFrameIdMeta,
          timelineFrameId.isAcceptableOrUnknown(
              data['timeline_frame_id']!, _timelineFrameIdMeta));
    }
    if (data.containsKey('timeline_order')) {
      context.handle(
          _timelineOrderMeta,
          timelineOrder.isAcceptableOrUnknown(
              data['timeline_order']!, _timelineOrderMeta));
    }
    if (data.containsKey('document_order')) {
      context.handle(
          _documentOrderMeta,
          documentOrder.isAcceptableOrUnknown(
              data['document_order']!, _documentOrderMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Chapter map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Chapter(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      storyId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}story_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      contentHtml: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content_html'])!,
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}timestamp'])!,
      timelineFrameId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}timeline_frame_id']),
      timelineOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}timeline_order'])!,
      documentOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}document_order'])!,
    );
  }

  @override
  $ChaptersTable createAlias(String alias) {
    return $ChaptersTable(attachedDatabase, alias);
  }
}

class Chapter extends DataClass implements Insertable<Chapter> {
  final int id;
  final int storyId;
  final String title;
  final String contentHtml;
  final int timestamp;
  final int? timelineFrameId;

  /// Order within a timeline frame, never affected by document reorder.
  final int timelineOrder;

  /// Order in the document screen, never affected by timeline reorder.
  final int documentOrder;
  const Chapter(
      {required this.id,
      required this.storyId,
      required this.title,
      required this.contentHtml,
      required this.timestamp,
      this.timelineFrameId,
      required this.timelineOrder,
      required this.documentOrder});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['story_id'] = Variable<int>(storyId);
    map['title'] = Variable<String>(title);
    map['content_html'] = Variable<String>(contentHtml);
    map['timestamp'] = Variable<int>(timestamp);
    if (!nullToAbsent || timelineFrameId != null) {
      map['timeline_frame_id'] = Variable<int>(timelineFrameId);
    }
    map['timeline_order'] = Variable<int>(timelineOrder);
    map['document_order'] = Variable<int>(documentOrder);
    return map;
  }

  ChaptersCompanion toCompanion(bool nullToAbsent) {
    return ChaptersCompanion(
      id: Value(id),
      storyId: Value(storyId),
      title: Value(title),
      contentHtml: Value(contentHtml),
      timestamp: Value(timestamp),
      timelineFrameId: timelineFrameId == null && nullToAbsent
          ? const Value.absent()
          : Value(timelineFrameId),
      timelineOrder: Value(timelineOrder),
      documentOrder: Value(documentOrder),
    );
  }

  factory Chapter.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Chapter(
      id: serializer.fromJson<int>(json['id']),
      storyId: serializer.fromJson<int>(json['storyId']),
      title: serializer.fromJson<String>(json['title']),
      contentHtml: serializer.fromJson<String>(json['contentHtml']),
      timestamp: serializer.fromJson<int>(json['timestamp']),
      timelineFrameId: serializer.fromJson<int?>(json['timelineFrameId']),
      timelineOrder: serializer.fromJson<int>(json['timelineOrder']),
      documentOrder: serializer.fromJson<int>(json['documentOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'storyId': serializer.toJson<int>(storyId),
      'title': serializer.toJson<String>(title),
      'contentHtml': serializer.toJson<String>(contentHtml),
      'timestamp': serializer.toJson<int>(timestamp),
      'timelineFrameId': serializer.toJson<int?>(timelineFrameId),
      'timelineOrder': serializer.toJson<int>(timelineOrder),
      'documentOrder': serializer.toJson<int>(documentOrder),
    };
  }

  Chapter copyWith(
          {int? id,
          int? storyId,
          String? title,
          String? contentHtml,
          int? timestamp,
          Value<int?> timelineFrameId = const Value.absent(),
          int? timelineOrder,
          int? documentOrder}) =>
      Chapter(
        id: id ?? this.id,
        storyId: storyId ?? this.storyId,
        title: title ?? this.title,
        contentHtml: contentHtml ?? this.contentHtml,
        timestamp: timestamp ?? this.timestamp,
        timelineFrameId: timelineFrameId.present
            ? timelineFrameId.value
            : this.timelineFrameId,
        timelineOrder: timelineOrder ?? this.timelineOrder,
        documentOrder: documentOrder ?? this.documentOrder,
      );
  Chapter copyWithCompanion(ChaptersCompanion data) {
    return Chapter(
      id: data.id.present ? data.id.value : this.id,
      storyId: data.storyId.present ? data.storyId.value : this.storyId,
      title: data.title.present ? data.title.value : this.title,
      contentHtml:
          data.contentHtml.present ? data.contentHtml.value : this.contentHtml,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      timelineFrameId: data.timelineFrameId.present
          ? data.timelineFrameId.value
          : this.timelineFrameId,
      timelineOrder: data.timelineOrder.present
          ? data.timelineOrder.value
          : this.timelineOrder,
      documentOrder: data.documentOrder.present
          ? data.documentOrder.value
          : this.documentOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Chapter(')
          ..write('id: $id, ')
          ..write('storyId: $storyId, ')
          ..write('title: $title, ')
          ..write('contentHtml: $contentHtml, ')
          ..write('timestamp: $timestamp, ')
          ..write('timelineFrameId: $timelineFrameId, ')
          ..write('timelineOrder: $timelineOrder, ')
          ..write('documentOrder: $documentOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, storyId, title, contentHtml, timestamp,
      timelineFrameId, timelineOrder, documentOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Chapter &&
          other.id == this.id &&
          other.storyId == this.storyId &&
          other.title == this.title &&
          other.contentHtml == this.contentHtml &&
          other.timestamp == this.timestamp &&
          other.timelineFrameId == this.timelineFrameId &&
          other.timelineOrder == this.timelineOrder &&
          other.documentOrder == this.documentOrder);
}

class ChaptersCompanion extends UpdateCompanion<Chapter> {
  final Value<int> id;
  final Value<int> storyId;
  final Value<String> title;
  final Value<String> contentHtml;
  final Value<int> timestamp;
  final Value<int?> timelineFrameId;
  final Value<int> timelineOrder;
  final Value<int> documentOrder;
  const ChaptersCompanion({
    this.id = const Value.absent(),
    this.storyId = const Value.absent(),
    this.title = const Value.absent(),
    this.contentHtml = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.timelineFrameId = const Value.absent(),
    this.timelineOrder = const Value.absent(),
    this.documentOrder = const Value.absent(),
  });
  ChaptersCompanion.insert({
    this.id = const Value.absent(),
    required int storyId,
    required String title,
    this.contentHtml = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.timelineFrameId = const Value.absent(),
    this.timelineOrder = const Value.absent(),
    this.documentOrder = const Value.absent(),
  })  : storyId = Value(storyId),
        title = Value(title);
  static Insertable<Chapter> custom({
    Expression<int>? id,
    Expression<int>? storyId,
    Expression<String>? title,
    Expression<String>? contentHtml,
    Expression<int>? timestamp,
    Expression<int>? timelineFrameId,
    Expression<int>? timelineOrder,
    Expression<int>? documentOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (storyId != null) 'story_id': storyId,
      if (title != null) 'title': title,
      if (contentHtml != null) 'content_html': contentHtml,
      if (timestamp != null) 'timestamp': timestamp,
      if (timelineFrameId != null) 'timeline_frame_id': timelineFrameId,
      if (timelineOrder != null) 'timeline_order': timelineOrder,
      if (documentOrder != null) 'document_order': documentOrder,
    });
  }

  ChaptersCompanion copyWith(
      {Value<int>? id,
      Value<int>? storyId,
      Value<String>? title,
      Value<String>? contentHtml,
      Value<int>? timestamp,
      Value<int?>? timelineFrameId,
      Value<int>? timelineOrder,
      Value<int>? documentOrder}) {
    return ChaptersCompanion(
      id: id ?? this.id,
      storyId: storyId ?? this.storyId,
      title: title ?? this.title,
      contentHtml: contentHtml ?? this.contentHtml,
      timestamp: timestamp ?? this.timestamp,
      timelineFrameId: timelineFrameId ?? this.timelineFrameId,
      timelineOrder: timelineOrder ?? this.timelineOrder,
      documentOrder: documentOrder ?? this.documentOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (storyId.present) {
      map['story_id'] = Variable<int>(storyId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (contentHtml.present) {
      map['content_html'] = Variable<String>(contentHtml.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<int>(timestamp.value);
    }
    if (timelineFrameId.present) {
      map['timeline_frame_id'] = Variable<int>(timelineFrameId.value);
    }
    if (timelineOrder.present) {
      map['timeline_order'] = Variable<int>(timelineOrder.value);
    }
    if (documentOrder.present) {
      map['document_order'] = Variable<int>(documentOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChaptersCompanion(')
          ..write('id: $id, ')
          ..write('storyId: $storyId, ')
          ..write('title: $title, ')
          ..write('contentHtml: $contentHtml, ')
          ..write('timestamp: $timestamp, ')
          ..write('timelineFrameId: $timelineFrameId, ')
          ..write('timelineOrder: $timelineOrder, ')
          ..write('documentOrder: $documentOrder')
          ..write(')'))
        .toString();
  }
}

class $TimelineFramesTable extends TimelineFrames
    with TableInfo<$TimelineFramesTable, TimelineFrame> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TimelineFramesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _storyIdMeta =
      const VerificationMeta('storyId');
  @override
  late final GeneratedColumn<int> storyId = GeneratedColumn<int>(
      'story_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _frameOrderMeta =
      const VerificationMeta('frameOrder');
  @override
  late final GeneratedColumn<int> frameOrder = GeneratedColumn<int>(
      'frame_order', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, storyId, name, frameOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'timeline_frames';
  @override
  VerificationContext validateIntegrity(Insertable<TimelineFrame> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('story_id')) {
      context.handle(_storyIdMeta,
          storyId.isAcceptableOrUnknown(data['story_id']!, _storyIdMeta));
    } else if (isInserting) {
      context.missing(_storyIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('frame_order')) {
      context.handle(
          _frameOrderMeta,
          frameOrder.isAcceptableOrUnknown(
              data['frame_order']!, _frameOrderMeta));
    } else if (isInserting) {
      context.missing(_frameOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TimelineFrame map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TimelineFrame(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      storyId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}story_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      frameOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}frame_order'])!,
    );
  }

  @override
  $TimelineFramesTable createAlias(String alias) {
    return $TimelineFramesTable(attachedDatabase, alias);
  }
}

class TimelineFrame extends DataClass implements Insertable<TimelineFrame> {
  final int id;
  final int storyId;

  /// e.g. "Year 1" or "Flashback".
  final String name;

  /// For drag-and-drop sorting.
  final int frameOrder;
  const TimelineFrame(
      {required this.id,
      required this.storyId,
      required this.name,
      required this.frameOrder});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['story_id'] = Variable<int>(storyId);
    map['name'] = Variable<String>(name);
    map['frame_order'] = Variable<int>(frameOrder);
    return map;
  }

  TimelineFramesCompanion toCompanion(bool nullToAbsent) {
    return TimelineFramesCompanion(
      id: Value(id),
      storyId: Value(storyId),
      name: Value(name),
      frameOrder: Value(frameOrder),
    );
  }

  factory TimelineFrame.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TimelineFrame(
      id: serializer.fromJson<int>(json['id']),
      storyId: serializer.fromJson<int>(json['storyId']),
      name: serializer.fromJson<String>(json['name']),
      frameOrder: serializer.fromJson<int>(json['frameOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'storyId': serializer.toJson<int>(storyId),
      'name': serializer.toJson<String>(name),
      'frameOrder': serializer.toJson<int>(frameOrder),
    };
  }

  TimelineFrame copyWith(
          {int? id, int? storyId, String? name, int? frameOrder}) =>
      TimelineFrame(
        id: id ?? this.id,
        storyId: storyId ?? this.storyId,
        name: name ?? this.name,
        frameOrder: frameOrder ?? this.frameOrder,
      );
  TimelineFrame copyWithCompanion(TimelineFramesCompanion data) {
    return TimelineFrame(
      id: data.id.present ? data.id.value : this.id,
      storyId: data.storyId.present ? data.storyId.value : this.storyId,
      name: data.name.present ? data.name.value : this.name,
      frameOrder:
          data.frameOrder.present ? data.frameOrder.value : this.frameOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TimelineFrame(')
          ..write('id: $id, ')
          ..write('storyId: $storyId, ')
          ..write('name: $name, ')
          ..write('frameOrder: $frameOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, storyId, name, frameOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TimelineFrame &&
          other.id == this.id &&
          other.storyId == this.storyId &&
          other.name == this.name &&
          other.frameOrder == this.frameOrder);
}

class TimelineFramesCompanion extends UpdateCompanion<TimelineFrame> {
  final Value<int> id;
  final Value<int> storyId;
  final Value<String> name;
  final Value<int> frameOrder;
  const TimelineFramesCompanion({
    this.id = const Value.absent(),
    this.storyId = const Value.absent(),
    this.name = const Value.absent(),
    this.frameOrder = const Value.absent(),
  });
  TimelineFramesCompanion.insert({
    this.id = const Value.absent(),
    required int storyId,
    required String name,
    required int frameOrder,
  })  : storyId = Value(storyId),
        name = Value(name),
        frameOrder = Value(frameOrder);
  static Insertable<TimelineFrame> custom({
    Expression<int>? id,
    Expression<int>? storyId,
    Expression<String>? name,
    Expression<int>? frameOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (storyId != null) 'story_id': storyId,
      if (name != null) 'name': name,
      if (frameOrder != null) 'frame_order': frameOrder,
    });
  }

  TimelineFramesCompanion copyWith(
      {Value<int>? id,
      Value<int>? storyId,
      Value<String>? name,
      Value<int>? frameOrder}) {
    return TimelineFramesCompanion(
      id: id ?? this.id,
      storyId: storyId ?? this.storyId,
      name: name ?? this.name,
      frameOrder: frameOrder ?? this.frameOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (storyId.present) {
      map['story_id'] = Variable<int>(storyId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (frameOrder.present) {
      map['frame_order'] = Variable<int>(frameOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TimelineFramesCompanion(')
          ..write('id: $id, ')
          ..write('storyId: $storyId, ')
          ..write('name: $name, ')
          ..write('frameOrder: $frameOrder')
          ..write(')'))
        .toString();
  }
}

class $CharacterGroupsTable extends CharacterGroups
    with TableInfo<$CharacterGroupsTable, CharacterGroup> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CharacterGroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _storyIdMeta =
      const VerificationMeta('storyId');
  @override
  late final GeneratedColumn<int> storyId = GeneratedColumn<int>(
      'story_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _iconIndexMeta =
      const VerificationMeta('iconIndex');
  @override
  late final GeneratedColumn<int> iconIndex = GeneratedColumn<int>(
      'icon_index', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _groupOrderMeta =
      const VerificationMeta('groupOrder');
  @override
  late final GeneratedColumn<int> groupOrder = GeneratedColumn<int>(
      'group_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns =>
      [id, storyId, name, iconIndex, groupOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'character_groups';
  @override
  VerificationContext validateIntegrity(Insertable<CharacterGroup> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('story_id')) {
      context.handle(_storyIdMeta,
          storyId.isAcceptableOrUnknown(data['story_id']!, _storyIdMeta));
    } else if (isInserting) {
      context.missing(_storyIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('icon_index')) {
      context.handle(_iconIndexMeta,
          iconIndex.isAcceptableOrUnknown(data['icon_index']!, _iconIndexMeta));
    }
    if (data.containsKey('group_order')) {
      context.handle(
          _groupOrderMeta,
          groupOrder.isAcceptableOrUnknown(
              data['group_order']!, _groupOrderMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CharacterGroup map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CharacterGroup(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      storyId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}story_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      iconIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}icon_index'])!,
      groupOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}group_order'])!,
    );
  }

  @override
  $CharacterGroupsTable createAlias(String alias) {
    return $CharacterGroupsTable(attachedDatabase, alias);
  }
}

class CharacterGroup extends DataClass implements Insertable<CharacterGroup> {
  final int id;
  final int storyId;
  final String name;

  /// 0-5, maps to the character group icon list.
  final int iconIndex;
  final int groupOrder;
  const CharacterGroup(
      {required this.id,
      required this.storyId,
      required this.name,
      required this.iconIndex,
      required this.groupOrder});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['story_id'] = Variable<int>(storyId);
    map['name'] = Variable<String>(name);
    map['icon_index'] = Variable<int>(iconIndex);
    map['group_order'] = Variable<int>(groupOrder);
    return map;
  }

  CharacterGroupsCompanion toCompanion(bool nullToAbsent) {
    return CharacterGroupsCompanion(
      id: Value(id),
      storyId: Value(storyId),
      name: Value(name),
      iconIndex: Value(iconIndex),
      groupOrder: Value(groupOrder),
    );
  }

  factory CharacterGroup.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CharacterGroup(
      id: serializer.fromJson<int>(json['id']),
      storyId: serializer.fromJson<int>(json['storyId']),
      name: serializer.fromJson<String>(json['name']),
      iconIndex: serializer.fromJson<int>(json['iconIndex']),
      groupOrder: serializer.fromJson<int>(json['groupOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'storyId': serializer.toJson<int>(storyId),
      'name': serializer.toJson<String>(name),
      'iconIndex': serializer.toJson<int>(iconIndex),
      'groupOrder': serializer.toJson<int>(groupOrder),
    };
  }

  CharacterGroup copyWith(
          {int? id,
          int? storyId,
          String? name,
          int? iconIndex,
          int? groupOrder}) =>
      CharacterGroup(
        id: id ?? this.id,
        storyId: storyId ?? this.storyId,
        name: name ?? this.name,
        iconIndex: iconIndex ?? this.iconIndex,
        groupOrder: groupOrder ?? this.groupOrder,
      );
  CharacterGroup copyWithCompanion(CharacterGroupsCompanion data) {
    return CharacterGroup(
      id: data.id.present ? data.id.value : this.id,
      storyId: data.storyId.present ? data.storyId.value : this.storyId,
      name: data.name.present ? data.name.value : this.name,
      iconIndex: data.iconIndex.present ? data.iconIndex.value : this.iconIndex,
      groupOrder:
          data.groupOrder.present ? data.groupOrder.value : this.groupOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CharacterGroup(')
          ..write('id: $id, ')
          ..write('storyId: $storyId, ')
          ..write('name: $name, ')
          ..write('iconIndex: $iconIndex, ')
          ..write('groupOrder: $groupOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, storyId, name, iconIndex, groupOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CharacterGroup &&
          other.id == this.id &&
          other.storyId == this.storyId &&
          other.name == this.name &&
          other.iconIndex == this.iconIndex &&
          other.groupOrder == this.groupOrder);
}

class CharacterGroupsCompanion extends UpdateCompanion<CharacterGroup> {
  final Value<int> id;
  final Value<int> storyId;
  final Value<String> name;
  final Value<int> iconIndex;
  final Value<int> groupOrder;
  const CharacterGroupsCompanion({
    this.id = const Value.absent(),
    this.storyId = const Value.absent(),
    this.name = const Value.absent(),
    this.iconIndex = const Value.absent(),
    this.groupOrder = const Value.absent(),
  });
  CharacterGroupsCompanion.insert({
    this.id = const Value.absent(),
    required int storyId,
    required String name,
    this.iconIndex = const Value.absent(),
    this.groupOrder = const Value.absent(),
  })  : storyId = Value(storyId),
        name = Value(name);
  static Insertable<CharacterGroup> custom({
    Expression<int>? id,
    Expression<int>? storyId,
    Expression<String>? name,
    Expression<int>? iconIndex,
    Expression<int>? groupOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (storyId != null) 'story_id': storyId,
      if (name != null) 'name': name,
      if (iconIndex != null) 'icon_index': iconIndex,
      if (groupOrder != null) 'group_order': groupOrder,
    });
  }

  CharacterGroupsCompanion copyWith(
      {Value<int>? id,
      Value<int>? storyId,
      Value<String>? name,
      Value<int>? iconIndex,
      Value<int>? groupOrder}) {
    return CharacterGroupsCompanion(
      id: id ?? this.id,
      storyId: storyId ?? this.storyId,
      name: name ?? this.name,
      iconIndex: iconIndex ?? this.iconIndex,
      groupOrder: groupOrder ?? this.groupOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (storyId.present) {
      map['story_id'] = Variable<int>(storyId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (iconIndex.present) {
      map['icon_index'] = Variable<int>(iconIndex.value);
    }
    if (groupOrder.present) {
      map['group_order'] = Variable<int>(groupOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CharacterGroupsCompanion(')
          ..write('id: $id, ')
          ..write('storyId: $storyId, ')
          ..write('name: $name, ')
          ..write('iconIndex: $iconIndex, ')
          ..write('groupOrder: $groupOrder')
          ..write(')'))
        .toString();
  }
}

class $StoryCharactersTable extends StoryCharacters
    with TableInfo<$StoryCharactersTable, StoryCharacter> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoryCharactersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _storyIdMeta =
      const VerificationMeta('storyId');
  @override
  late final GeneratedColumn<int> storyId = GeneratedColumn<int>(
      'story_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _groupIdMeta =
      const VerificationMeta('groupId');
  @override
  late final GeneratedColumn<int> groupId = GeneratedColumn<int>(
      'group_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<Map<String, String>, String>
      attributes = GeneratedColumn<String>('attributes', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<Map<String, String>>(
              $StoryCharactersTable.$converterattributes);
  @override
  List<GeneratedColumn> get $columns =>
      [id, storyId, groupId, name, description, attributes];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'story_characters';
  @override
  VerificationContext validateIntegrity(Insertable<StoryCharacter> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('story_id')) {
      context.handle(_storyIdMeta,
          storyId.isAcceptableOrUnknown(data['story_id']!, _storyIdMeta));
    } else if (isInserting) {
      context.missing(_storyIdMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(_groupIdMeta,
          groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta));
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StoryCharacter map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoryCharacter(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      storyId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}story_id'])!,
      groupId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}group_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      attributes: $StoryCharactersTable.$converterattributes.fromSql(
          attachedDatabase.typeMapping.read(
              DriftSqlType.string, data['${effectivePrefix}attributes'])!),
    );
  }

  @override
  $StoryCharactersTable createAlias(String alias) {
    return $StoryCharactersTable(attachedDatabase, alias);
  }

  static TypeConverter<Map<String, String>, String> $converterattributes =
      const StringMapConverter();
}

class StoryCharacter extends DataClass implements Insertable<StoryCharacter> {
  final int id;
  final int storyId;
  final int groupId;
  final String name;
  final String description;
  final Map<String, String> attributes;
  const StoryCharacter(
      {required this.id,
      required this.storyId,
      required this.groupId,
      required this.name,
      required this.description,
      required this.attributes});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['story_id'] = Variable<int>(storyId);
    map['group_id'] = Variable<int>(groupId);
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    {
      map['attributes'] = Variable<String>(
          $StoryCharactersTable.$converterattributes.toSql(attributes));
    }
    return map;
  }

  StoryCharactersCompanion toCompanion(bool nullToAbsent) {
    return StoryCharactersCompanion(
      id: Value(id),
      storyId: Value(storyId),
      groupId: Value(groupId),
      name: Value(name),
      description: Value(description),
      attributes: Value(attributes),
    );
  }

  factory StoryCharacter.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoryCharacter(
      id: serializer.fromJson<int>(json['id']),
      storyId: serializer.fromJson<int>(json['storyId']),
      groupId: serializer.fromJson<int>(json['groupId']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      attributes: serializer.fromJson<Map<String, String>>(json['attributes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'storyId': serializer.toJson<int>(storyId),
      'groupId': serializer.toJson<int>(groupId),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'attributes': serializer.toJson<Map<String, String>>(attributes),
    };
  }

  StoryCharacter copyWith(
          {int? id,
          int? storyId,
          int? groupId,
          String? name,
          String? description,
          Map<String, String>? attributes}) =>
      StoryCharacter(
        id: id ?? this.id,
        storyId: storyId ?? this.storyId,
        groupId: groupId ?? this.groupId,
        name: name ?? this.name,
        description: description ?? this.description,
        attributes: attributes ?? this.attributes,
      );
  StoryCharacter copyWithCompanion(StoryCharactersCompanion data) {
    return StoryCharacter(
      id: data.id.present ? data.id.value : this.id,
      storyId: data.storyId.present ? data.storyId.value : this.storyId,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      name: data.name.present ? data.name.value : this.name,
      description:
          data.description.present ? data.description.value : this.description,
      attributes:
          data.attributes.present ? data.attributes.value : this.attributes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoryCharacter(')
          ..write('id: $id, ')
          ..write('storyId: $storyId, ')
          ..write('groupId: $groupId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('attributes: $attributes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, storyId, groupId, name, description, attributes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoryCharacter &&
          other.id == this.id &&
          other.storyId == this.storyId &&
          other.groupId == this.groupId &&
          other.name == this.name &&
          other.description == this.description &&
          other.attributes == this.attributes);
}

class StoryCharactersCompanion extends UpdateCompanion<StoryCharacter> {
  final Value<int> id;
  final Value<int> storyId;
  final Value<int> groupId;
  final Value<String> name;
  final Value<String> description;
  final Value<Map<String, String>> attributes;
  const StoryCharactersCompanion({
    this.id = const Value.absent(),
    this.storyId = const Value.absent(),
    this.groupId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.attributes = const Value.absent(),
  });
  StoryCharactersCompanion.insert({
    this.id = const Value.absent(),
    required int storyId,
    required int groupId,
    required String name,
    required String description,
    required Map<String, String> attributes,
  })  : storyId = Value(storyId),
        groupId = Value(groupId),
        name = Value(name),
        description = Value(description),
        attributes = Value(attributes);
  static Insertable<StoryCharacter> custom({
    Expression<int>? id,
    Expression<int>? storyId,
    Expression<int>? groupId,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? attributes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (storyId != null) 'story_id': storyId,
      if (groupId != null) 'group_id': groupId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (attributes != null) 'attributes': attributes,
    });
  }

  StoryCharactersCompanion copyWith(
      {Value<int>? id,
      Value<int>? storyId,
      Value<int>? groupId,
      Value<String>? name,
      Value<String>? description,
      Value<Map<String, String>>? attributes}) {
    return StoryCharactersCompanion(
      id: id ?? this.id,
      storyId: storyId ?? this.storyId,
      groupId: groupId ?? this.groupId,
      name: name ?? this.name,
      description: description ?? this.description,
      attributes: attributes ?? this.attributes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (storyId.present) {
      map['story_id'] = Variable<int>(storyId.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<int>(groupId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (attributes.present) {
      map['attributes'] = Variable<String>(
          $StoryCharactersTable.$converterattributes.toSql(attributes.value));
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoryCharactersCompanion(')
          ..write('id: $id, ')
          ..write('storyId: $storyId, ')
          ..write('groupId: $groupId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('attributes: $attributes')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $StoriesTable stories = $StoriesTable(this);
  late final $ChaptersTable chapters = $ChaptersTable(this);
  late final $TimelineFramesTable timelineFrames = $TimelineFramesTable(this);
  late final $CharacterGroupsTable characterGroups =
      $CharacterGroupsTable(this);
  late final $StoryCharactersTable storyCharacters =
      $StoryCharactersTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [stories, chapters, timelineFrames, characterGroups, storyCharacters];
}

typedef $$StoriesTableCreateCompanionBuilder = StoriesCompanion Function({
  Value<int> id,
  required String title,
  Value<String> previewText,
  Value<bool> isFavorite,
  Value<int> timestamp,
});
typedef $$StoriesTableUpdateCompanionBuilder = StoriesCompanion Function({
  Value<int> id,
  Value<String> title,
  Value<String> previewText,
  Value<bool> isFavorite,
  Value<int> timestamp,
});

class $$StoriesTableFilterComposer
    extends Composer<_$AppDatabase, $StoriesTable> {
  $$StoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get previewText => $composableBuilder(
      column: $table.previewText, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnFilters(column));
}

class $$StoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $StoriesTable> {
  $$StoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get previewText => $composableBuilder(
      column: $table.previewText, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnOrderings(column));
}

class $$StoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $StoriesTable> {
  $$StoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get previewText => $composableBuilder(
      column: $table.previewText, builder: (column) => column);

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => column);

  GeneratedColumn<int> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);
}

class $$StoriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $StoriesTable,
    Story,
    $$StoriesTableFilterComposer,
    $$StoriesTableOrderingComposer,
    $$StoriesTableAnnotationComposer,
    $$StoriesTableCreateCompanionBuilder,
    $$StoriesTableUpdateCompanionBuilder,
    (Story, BaseReferences<_$AppDatabase, $StoriesTable, Story>),
    Story,
    PrefetchHooks Function()> {
  $$StoriesTableTableManager(_$AppDatabase db, $StoriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> previewText = const Value.absent(),
            Value<bool> isFavorite = const Value.absent(),
            Value<int> timestamp = const Value.absent(),
          }) =>
              StoriesCompanion(
            id: id,
            title: title,
            previewText: previewText,
            isFavorite: isFavorite,
            timestamp: timestamp,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String title,
            Value<String> previewText = const Value.absent(),
            Value<bool> isFavorite = const Value.absent(),
            Value<int> timestamp = const Value.absent(),
          }) =>
              StoriesCompanion.insert(
            id: id,
            title: title,
            previewText: previewText,
            isFavorite: isFavorite,
            timestamp: timestamp,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$StoriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $StoriesTable,
    Story,
    $$StoriesTableFilterComposer,
    $$StoriesTableOrderingComposer,
    $$StoriesTableAnnotationComposer,
    $$StoriesTableCreateCompanionBuilder,
    $$StoriesTableUpdateCompanionBuilder,
    (Story, BaseReferences<_$AppDatabase, $StoriesTable, Story>),
    Story,
    PrefetchHooks Function()>;
typedef $$ChaptersTableCreateCompanionBuilder = ChaptersCompanion Function({
  Value<int> id,
  required int storyId,
  required String title,
  Value<String> contentHtml,
  Value<int> timestamp,
  Value<int?> timelineFrameId,
  Value<int> timelineOrder,
  Value<int> documentOrder,
});
typedef $$ChaptersTableUpdateCompanionBuilder = ChaptersCompanion Function({
  Value<int> id,
  Value<int> storyId,
  Value<String> title,
  Value<String> contentHtml,
  Value<int> timestamp,
  Value<int?> timelineFrameId,
  Value<int> timelineOrder,
  Value<int> documentOrder,
});

class $$ChaptersTableFilterComposer
    extends Composer<_$AppDatabase, $ChaptersTable> {
  $$ChaptersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get storyId => $composableBuilder(
      column: $table.storyId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get contentHtml => $composableBuilder(
      column: $table.contentHtml, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get timelineFrameId => $composableBuilder(
      column: $table.timelineFrameId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get timelineOrder => $composableBuilder(
      column: $table.timelineOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get documentOrder => $composableBuilder(
      column: $table.documentOrder, builder: (column) => ColumnFilters(column));
}

class $$ChaptersTableOrderingComposer
    extends Composer<_$AppDatabase, $ChaptersTable> {
  $$ChaptersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get storyId => $composableBuilder(
      column: $table.storyId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get contentHtml => $composableBuilder(
      column: $table.contentHtml, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get timelineFrameId => $composableBuilder(
      column: $table.timelineFrameId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get timelineOrder => $composableBuilder(
      column: $table.timelineOrder,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get documentOrder => $composableBuilder(
      column: $table.documentOrder,
      builder: (column) => ColumnOrderings(column));
}

class $$ChaptersTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChaptersTable> {
  $$ChaptersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get storyId =>
      $composableBuilder(column: $table.storyId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get contentHtml => $composableBuilder(
      column: $table.contentHtml, builder: (column) => column);

  GeneratedColumn<int> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<int> get timelineFrameId => $composableBuilder(
      column: $table.timelineFrameId, builder: (column) => column);

  GeneratedColumn<int> get timelineOrder => $composableBuilder(
      column: $table.timelineOrder, builder: (column) => column);

  GeneratedColumn<int> get documentOrder => $composableBuilder(
      column: $table.documentOrder, builder: (column) => column);
}

class $$ChaptersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ChaptersTable,
    Chapter,
    $$ChaptersTableFilterComposer,
    $$ChaptersTableOrderingComposer,
    $$ChaptersTableAnnotationComposer,
    $$ChaptersTableCreateCompanionBuilder,
    $$ChaptersTableUpdateCompanionBuilder,
    (Chapter, BaseReferences<_$AppDatabase, $ChaptersTable, Chapter>),
    Chapter,
    PrefetchHooks Function()> {
  $$ChaptersTableTableManager(_$AppDatabase db, $ChaptersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChaptersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChaptersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChaptersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> storyId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> contentHtml = const Value.absent(),
            Value<int> timestamp = const Value.absent(),
            Value<int?> timelineFrameId = const Value.absent(),
            Value<int> timelineOrder = const Value.absent(),
            Value<int> documentOrder = const Value.absent(),
          }) =>
              ChaptersCompanion(
            id: id,
            storyId: storyId,
            title: title,
            contentHtml: contentHtml,
            timestamp: timestamp,
            timelineFrameId: timelineFrameId,
            timelineOrder: timelineOrder,
            documentOrder: documentOrder,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int storyId,
            required String title,
            Value<String> contentHtml = const Value.absent(),
            Value<int> timestamp = const Value.absent(),
            Value<int?> timelineFrameId = const Value.absent(),
            Value<int> timelineOrder = const Value.absent(),
            Value<int> documentOrder = const Value.absent(),
          }) =>
              ChaptersCompanion.insert(
            id: id,
            storyId: storyId,
            title: title,
            contentHtml: contentHtml,
            timestamp: timestamp,
            timelineFrameId: timelineFrameId,
            timelineOrder: timelineOrder,
            documentOrder: documentOrder,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ChaptersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ChaptersTable,
    Chapter,
    $$ChaptersTableFilterComposer,
    $$ChaptersTableOrderingComposer,
    $$ChaptersTableAnnotationComposer,
    $$ChaptersTableCreateCompanionBuilder,
    $$ChaptersTableUpdateCompanionBuilder,
    (Chapter, BaseReferences<_$AppDatabase, $ChaptersTable, Chapter>),
    Chapter,
    PrefetchHooks Function()>;
typedef $$TimelineFramesTableCreateCompanionBuilder = TimelineFramesCompanion
    Function({
  Value<int> id,
  required int storyId,
  required String name,
  required int frameOrder,
});
typedef $$TimelineFramesTableUpdateCompanionBuilder = TimelineFramesCompanion
    Function({
  Value<int> id,
  Value<int> storyId,
  Value<String> name,
  Value<int> frameOrder,
});

class $$TimelineFramesTableFilterComposer
    extends Composer<_$AppDatabase, $TimelineFramesTable> {
  $$TimelineFramesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get storyId => $composableBuilder(
      column: $table.storyId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get frameOrder => $composableBuilder(
      column: $table.frameOrder, builder: (column) => ColumnFilters(column));
}

class $$TimelineFramesTableOrderingComposer
    extends Composer<_$AppDatabase, $TimelineFramesTable> {
  $$TimelineFramesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get storyId => $composableBuilder(
      column: $table.storyId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get frameOrder => $composableBuilder(
      column: $table.frameOrder, builder: (column) => ColumnOrderings(column));
}

class $$TimelineFramesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TimelineFramesTable> {
  $$TimelineFramesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get storyId =>
      $composableBuilder(column: $table.storyId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get frameOrder => $composableBuilder(
      column: $table.frameOrder, builder: (column) => column);
}

class $$TimelineFramesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TimelineFramesTable,
    TimelineFrame,
    $$TimelineFramesTableFilterComposer,
    $$TimelineFramesTableOrderingComposer,
    $$TimelineFramesTableAnnotationComposer,
    $$TimelineFramesTableCreateCompanionBuilder,
    $$TimelineFramesTableUpdateCompanionBuilder,
    (
      TimelineFrame,
      BaseReferences<_$AppDatabase, $TimelineFramesTable, TimelineFrame>
    ),
    TimelineFrame,
    PrefetchHooks Function()> {
  $$TimelineFramesTableTableManager(
      _$AppDatabase db, $TimelineFramesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TimelineFramesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TimelineFramesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TimelineFramesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> storyId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> frameOrder = const Value.absent(),
          }) =>
              TimelineFramesCompanion(
            id: id,
            storyId: storyId,
            name: name,
            frameOrder: frameOrder,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int storyId,
            required String name,
            required int frameOrder,
          }) =>
              TimelineFramesCompanion.insert(
            id: id,
            storyId: storyId,
            name: name,
            frameOrder: frameOrder,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TimelineFramesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TimelineFramesTable,
    TimelineFrame,
    $$TimelineFramesTableFilterComposer,
    $$TimelineFramesTableOrderingComposer,
    $$TimelineFramesTableAnnotationComposer,
    $$TimelineFramesTableCreateCompanionBuilder,
    $$TimelineFramesTableUpdateCompanionBuilder,
    (
      TimelineFrame,
      BaseReferences<_$AppDatabase, $TimelineFramesTable, TimelineFrame>
    ),
    TimelineFrame,
    PrefetchHooks Function()>;
typedef $$CharacterGroupsTableCreateCompanionBuilder = CharacterGroupsCompanion
    Function({
  Value<int> id,
  required int storyId,
  required String name,
  Value<int> iconIndex,
  Value<int> groupOrder,
});
typedef $$CharacterGroupsTableUpdateCompanionBuilder = CharacterGroupsCompanion
    Function({
  Value<int> id,
  Value<int> storyId,
  Value<String> name,
  Value<int> iconIndex,
  Value<int> groupOrder,
});

class $$CharacterGroupsTableFilterComposer
    extends Composer<_$AppDatabase, $CharacterGroupsTable> {
  $$CharacterGroupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get storyId => $composableBuilder(
      column: $table.storyId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get iconIndex => $composableBuilder(
      column: $table.iconIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get groupOrder => $composableBuilder(
      column: $table.groupOrder, builder: (column) => ColumnFilters(column));
}

class $$CharacterGroupsTableOrderingComposer
    extends Composer<_$AppDatabase, $CharacterGroupsTable> {
  $$CharacterGroupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get storyId => $composableBuilder(
      column: $table.storyId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get iconIndex => $composableBuilder(
      column: $table.iconIndex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get groupOrder => $composableBuilder(
      column: $table.groupOrder, builder: (column) => ColumnOrderings(column));
}

class $$CharacterGroupsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CharacterGroupsTable> {
  $$CharacterGroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get storyId =>
      $composableBuilder(column: $table.storyId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get iconIndex =>
      $composableBuilder(column: $table.iconIndex, builder: (column) => column);

  GeneratedColumn<int> get groupOrder => $composableBuilder(
      column: $table.groupOrder, builder: (column) => column);
}

class $$CharacterGroupsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CharacterGroupsTable,
    CharacterGroup,
    $$CharacterGroupsTableFilterComposer,
    $$CharacterGroupsTableOrderingComposer,
    $$CharacterGroupsTableAnnotationComposer,
    $$CharacterGroupsTableCreateCompanionBuilder,
    $$CharacterGroupsTableUpdateCompanionBuilder,
    (
      CharacterGroup,
      BaseReferences<_$AppDatabase, $CharacterGroupsTable, CharacterGroup>
    ),
    CharacterGroup,
    PrefetchHooks Function()> {
  $$CharacterGroupsTableTableManager(
      _$AppDatabase db, $CharacterGroupsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CharacterGroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CharacterGroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CharacterGroupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> storyId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> iconIndex = const Value.absent(),
            Value<int> groupOrder = const Value.absent(),
          }) =>
              CharacterGroupsCompanion(
            id: id,
            storyId: storyId,
            name: name,
            iconIndex: iconIndex,
            groupOrder: groupOrder,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int storyId,
            required String name,
            Value<int> iconIndex = const Value.absent(),
            Value<int> groupOrder = const Value.absent(),
          }) =>
              CharacterGroupsCompanion.insert(
            id: id,
            storyId: storyId,
            name: name,
            iconIndex: iconIndex,
            groupOrder: groupOrder,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CharacterGroupsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CharacterGroupsTable,
    CharacterGroup,
    $$CharacterGroupsTableFilterComposer,
    $$CharacterGroupsTableOrderingComposer,
    $$CharacterGroupsTableAnnotationComposer,
    $$CharacterGroupsTableCreateCompanionBuilder,
    $$CharacterGroupsTableUpdateCompanionBuilder,
    (
      CharacterGroup,
      BaseReferences<_$AppDatabase, $CharacterGroupsTable, CharacterGroup>
    ),
    CharacterGroup,
    PrefetchHooks Function()>;
typedef $$StoryCharactersTableCreateCompanionBuilder = StoryCharactersCompanion
    Function({
  Value<int> id,
  required int storyId,
  required int groupId,
  required String name,
  required String description,
  required Map<String, String> attributes,
});
typedef $$StoryCharactersTableUpdateCompanionBuilder = StoryCharactersCompanion
    Function({
  Value<int> id,
  Value<int> storyId,
  Value<int> groupId,
  Value<String> name,
  Value<String> description,
  Value<Map<String, String>> attributes,
});

class $$StoryCharactersTableFilterComposer
    extends Composer<_$AppDatabase, $StoryCharactersTable> {
  $$StoryCharactersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get storyId => $composableBuilder(
      column: $table.storyId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get groupId => $composableBuilder(
      column: $table.groupId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<Map<String, String>, Map<String, String>,
          String>
      get attributes => $composableBuilder(
          column: $table.attributes,
          builder: (column) => ColumnWithTypeConverterFilters(column));
}

class $$StoryCharactersTableOrderingComposer
    extends Composer<_$AppDatabase, $StoryCharactersTable> {
  $$StoryCharactersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get storyId => $composableBuilder(
      column: $table.storyId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get groupId => $composableBuilder(
      column: $table.groupId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get attributes => $composableBuilder(
      column: $table.attributes, builder: (column) => ColumnOrderings(column));
}

class $$StoryCharactersTableAnnotationComposer
    extends Composer<_$AppDatabase, $StoryCharactersTable> {
  $$StoryCharactersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get storyId =>
      $composableBuilder(column: $table.storyId, builder: (column) => column);

  GeneratedColumn<int> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Map<String, String>, String>
      get attributes => $composableBuilder(
          column: $table.attributes, builder: (column) => column);
}

class $$StoryCharactersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $StoryCharactersTable,
    StoryCharacter,
    $$StoryCharactersTableFilterComposer,
    $$StoryCharactersTableOrderingComposer,
    $$StoryCharactersTableAnnotationComposer,
    $$StoryCharactersTableCreateCompanionBuilder,
    $$StoryCharactersTableUpdateCompanionBuilder,
    (
      StoryCharacter,
      BaseReferences<_$AppDatabase, $StoryCharactersTable, StoryCharacter>
    ),
    StoryCharacter,
    PrefetchHooks Function()> {
  $$StoryCharactersTableTableManager(
      _$AppDatabase db, $StoryCharactersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StoryCharactersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StoryCharactersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StoryCharactersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> storyId = const Value.absent(),
            Value<int> groupId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<Map<String, String>> attributes = const Value.absent(),
          }) =>
              StoryCharactersCompanion(
            id: id,
            storyId: storyId,
            groupId: groupId,
            name: name,
            description: description,
            attributes: attributes,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int storyId,
            required int groupId,
            required String name,
            required String description,
            required Map<String, String> attributes,
          }) =>
              StoryCharactersCompanion.insert(
            id: id,
            storyId: storyId,
            groupId: groupId,
            name: name,
            description: description,
            attributes: attributes,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$StoryCharactersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $StoryCharactersTable,
    StoryCharacter,
    $$StoryCharactersTableFilterComposer,
    $$StoryCharactersTableOrderingComposer,
    $$StoryCharactersTableAnnotationComposer,
    $$StoryCharactersTableCreateCompanionBuilder,
    $$StoryCharactersTableUpdateCompanionBuilder,
    (
      StoryCharacter,
      BaseReferences<_$AppDatabase, $StoryCharactersTable, StoryCharacter>
    ),
    StoryCharacter,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$StoriesTableTableManager get stories =>
      $$StoriesTableTableManager(_db, _db.stories);
  $$ChaptersTableTableManager get chapters =>
      $$ChaptersTableTableManager(_db, _db.chapters);
  $$TimelineFramesTableTableManager get timelineFrames =>
      $$TimelineFramesTableTableManager(_db, _db.timelineFrames);
  $$CharacterGroupsTableTableManager get characterGroups =>
      $$CharacterGroupsTableTableManager(_db, _db.characterGroups);
  $$StoryCharactersTableTableManager get storyCharacters =>
      $$StoryCharactersTableTableManager(_db, _db.storyCharacters);
}
