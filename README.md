# PapyrQuill (Flutter)

Flutter port of the Android PapyrQuill app, targeting Android and Windows.

## Status

| Area | Status |
| --- | --- |
| Database (Room -> Drift) | Done |
| Repository | Done |
| API models, remote data source, sync manager (Retrofit -> Dio) | Done |
| Server address setting | Done (gear icon on the home screen) |
| Ids and duplicates | Done: rows adopt the server's id; offline rows are sent later (see "How new rows get their ids") |
| Home screen | Done: search, story cards, add, favorite, delete (long-press or right-click), pull to refresh, server address |
| Editor screen (flutter_quill) | Done: autosave, undo/redo, bold/italic/underline/strike, alignment, bullets |
| HTML <-> editor conversion | Done, with unit tests (`test/html_codec_test.dart`) |
| Document screen | Done: editable title and description, chapter list, add, delete, drag to reorder, share |
| .docx export | Done: one chapter (from the editor) or the whole story (from the Document screen) |
| Character Groups and Characters screens | Done: group grid, create group, character cards, add/edit/delete, group tabs |
| Timeline screen | Done: frames, add/move/reorder chapters, reorder and delete frames |
| Splash screen | Done: logo for one second, then Home |

## First-time setup

This folder has only the Dart code, so generate the platform folders and the
database code once:

```bash
cd papyrquill_flutter
flutter create . --platforms=android,windows --project-name papyrquill
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d windows     # or pick your Android device
```

`flutter create .` keeps the existing `lib/` and `pubspec.yaml`. If it
overwrites `lib/main.dart` with the counter demo, restore the `main.dart` from
this project.

### Android: allow plain HTTP

The server is `http://`, not `https://`. In
`android/app/src/main/AndroidManifest.xml` add these to the `<application>` tag
(the Kotlin app had the same):

```xml
android:usesCleartextTraffic="true"
```

and this above it, next to the other permissions:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

### Server address

Tap the gear icon on the home screen. Use your PC's Wi-Fi IP on the phone
(for example `http://192.168.1.10/papyrquill/api/`) and `http://localhost/papyrquill/api/`
for Windows on the same PC.

### Run the tests

```bash
flutter test
```

`test/html_codec_test.dart` checks the HTML <-> editor conversion,
`test/docx_builder_test.dart` checks the .docx builder, `test/timeline_test.dart` checks frame and chapter placement, and
`test/id_adoption_test.dart` checks how new rows get their ids (below; it uses a
fake server and an in-memory database, so SQLite must be loadable in tests).
Run them first: if one fails, the problem is in that piece, not the screens.

## How the editor stores text

The database and server keep **HTML**, exactly as the Android app did. The
editor works on Quill's internal format, so `lib/editor/html_codec.dart`
converts both ways when a chapter is opened and saved:

- Reads the HTML the Android editor wrote: `<b>`, `<i>`, `<u>`, `<s>`,
  `<ul><li>`, `<br>`, `<p style="text-align: ...">`, and formatting written as
  CSS such as `<span style="font-weight: bold">`.
- Writes the same style of HTML back, so chapters edited on Windows still open
  correctly in the Android app and on the server.
- Supports bold, italic, underline, strikethrough, links, alignment, headings,
  bulleted/numbered lists and blank lines. Colors, images and tables are not
  kept (text is). The Android editor offered none of those either.
- A chapter is only re-saved after you edit it, so opening a chapter never
  rewrites its stored HTML.

## How the document screen works

- Tap the title or description to edit them; the description is the story's
  `previewText`. Opening the screen pulls the latest chapters from the server.
- Tap a chapter to open the editor. Long-press a chapter (or use its ⋮ menu,
  handy with a mouse) to delete it.
- Drag the handle on the left of a chapter to reorder. The new order is saved
  in one database transaction (one UI refresh) and then pushed to the server.
- The bookmark icon at the bottom opens the character groups. The hourglass icon
  opens the Timeline. Your images are copied into `assets/images/`, and
  downscaled (the original `bookmark.png` was 11 MB).

## Characters

- **Document screen -> bookmark icon** opens the group grid. Tap a group to open
  it; the arch button at the bottom left creates a group (name + one of 6
  icons) and opens it straight away.
- **Characters screen:** the round + adds a character (name, description and any
  number of trait/value attributes). Tap a card to expand it. Long-press,
  right-click, or the Edit button inside an expanded card opens the editor,
  which also has the delete icon.
- **Bottom tabs** switch between groups, and the last tab (+) opens the group
  grid to add one. The Android code described these tabs in a comment but had
  only drawn the empty add tab.
- **Group options (⋮)** next to the group name has Delete group. The Android
  app had the action but no button for it. Deleting a group deletes its
  characters.
- The bookmark at the top right goes back to the Document screen.

## Timeline

- **Document screen -> hourglass icon** opens the Timeline. The round + at the
  bottom right adds a timeframe (e.g. "Year 1"); the hourglass at the bottom
  left goes back to the Document screen.
- **On a frame:** the ▲▼ arrows move the frame, the + picks an unassigned
  chapter to put in it, long-press (or right-click) the name to delete it. A
  deleted frame's chapters go back to the unassigned pool.
- **On a chapter:** drag the handle to reorder inside the frame. To move it to
  another frame, use its ⋮ menu ("Move to ...") or long-press the chapter and
  drop it on the other frame's card (the card turns darker pink when it will
  accept the drop). The drag does not auto-scroll, so use the menu for frames
  far apart.
- Frame order is sent with the bulk endpoint (the server has no "update frame"
  endpoint); chapter placement and order go through the normal chapter update.
- A chapter can't be moved back to "unassigned" (same server limitation as
  before), only deleted-frame chapters become unassigned.

## Home screen

- The pill-shaped box searches story titles (case-insensitive, as in Kotlin).
- Tap a card to open the story; long-press (or right-click on Windows) asks
  before deleting; the heart toggles favorite. Pull down to sync.
- The gear next to the search box is the server address. The Kotlin app had no
  such button because the address was hard-coded.

## DOCX export

- **Android:** opens the share sheet with the .docx file.
- **Windows:** opens a "Save as" dialog.
- Unlike the Android app (which exported plain text lines), this keeps bold,
  italic, underline, strikethrough, alignment, headings and lists. Links export
  as plain text. File names keep accented and non-Latin letters.
- The .docx is built in `lib/export/docx_builder.dart` with a small built-in
  zip writer, so no archive package is needed.

## Mapping from the Kotlin app

| Kotlin | Flutter |
| --- | --- |
| Room entities, `Dao.kt`, `AppDatabase.kt` | `lib/data/tables.dart`, `lib/data/app_database.dart` |
| `MapTypeConverter` | `lib/data/converters.dart` |
| `ApiModels.kt` | `lib/network/api_models.dart` |
| `PapyrApiService.kt` + `RemoteDataSource.kt` | `lib/network/remote_data_source.dart` |
| `RetrofitClient.kt` (hardcoded URL) | `lib/network/api_config.dart` (saved setting) |
| `SyncManager.kt` | `lib/network/sync_manager.dart` |
| `PapyrRepository.kt` | `lib/repository/papyr_repository.dart` |
| ViewModels | Riverpod providers in `lib/providers.dart` |
| `ui/theme/Color.kt` | `lib/theme/app_theme.dart` |
| `EditorScreen.kt` + `EditorViewModel.kt` | `lib/screens/editor_screen.dart` |
| richeditor-compose HTML | `lib/editor/html_codec.dart`, `lib/editor/document_html.dart` |
| `DocumentScreen.kt` + `DocumentViewModel.kt` | `lib/screens/document_screen.dart`, `lib/screens/document_actions.dart` |
| `CharacterViewModel.kt` + `CharacterGroupScreen.kt` + `CharacterScreen.kt` | `lib/screens/character_actions.dart`, `character_group_screen.dart`, `character_screen.dart`, `lib/widgets/book_top_header.dart` |
| `TimelineViewModel.kt` + `TimelineScreen.kt` | `lib/screens/timeline_actions.dart`, `lib/screens/timeline_screen.dart` |
| `HomeScreen.kt` + `HomeViewModel.kt` | `lib/screens/home_screen.dart` |
| `SplashScreen.kt` (+ `PaperBackground`) | `lib/screens/splash_screen.dart`, `lib/widgets/paper_background.dart` |
| `DocxExporter.kt` (Apache POI) | `lib/export/docx_builder.dart`, `lib/export/docx_exporter.dart` |

## Behavior differences from the Kotlin version

- **Upserts instead of REPLACE.** Room's `OnConflictStrategy.REPLACE` deletes
  the old row first, which fires the `ON DELETE CASCADE` rules. Pulling the
  story list would then delete each story's chapters, frames and characters
  locally until the next story pull. The Drift code updates the row in place.
- **Server address is a setting**, not a constant.
- **New rows adopt the server's id** instead of keeping a local id (see "How new
  rows get their ids").
- **Pulling chapters keeps the local text** when the server's list leaves it out.
- **Added `updateGroup`** to the database and repository, since the sync layer
  already had `pushGroupUpdated`.
- **Undo/redo** uses flutter_quill's built-in history instead of the manual
  snapshot stacks.
- **Server content can't overwrite your typing:** the latest chapter pulled
  from the server is applied only if you haven't started editing yet.
- Also saves when the app goes to the background, and **Ctrl+S** saves on
  Windows.
- **Reordering** uses Flutter's reorderable list with a drag handle, and the
  whole new order is saved at once instead of chapter by chapter.
- **DOCX export keeps formatting** (see above).
- The unused `TimelineChapter` entity is not ported (it was not registered in
  the Room database).

## How new rows get their ids

The server owns the real ids. The first version of this port (like the Kotlin
app) saved a new row with the local database's own id and told the server
nothing about it, so the two ids only matched by luck. With a phone and a PC
both creating things, they stopped matching, and a pull then added a second
copy of the same row.

Now:

1. A new story, chapter, group, frame or character is saved with a **temporary
   negative id**. Server ids are positive, so the two can never collide.
2. It is sent to the server straight away. The server answers with its real id
   (`{"success":true,"data":{"id":123}}`, as your PHP already does).
3. The row, and everything that points to it (a story's chapters, frames,
   groups and characters; a group's characters), is switched to that id in one
   database transaction. From then on both devices use the same id.
4. If the server cannot be reached, the row keeps its temporary id.
   `syncPending()` sends such rows later, parents before children. It runs when
   the app starts, on pull-to-refresh, and whenever a story, its characters or
   its document is opened. It stops at the first failure, so a dead server costs
   one timeout, not one per row.
5. Edits and deletes of a row that is still pending stay local; the create
   request, sent later, carries the latest text.

Details that keep this safe:

- A screen or editor that still holds a temporary id keeps working after the
  swap: the repository translates it (`resolveStoryId` and friends).
- If a pull brings in the server's copy of a row *while* the create is still
  being confirmed, the pulled copy is replaced by the local one (it is at least
  as new) instead of leaving two rows.
- If you delete a row while its create request is in flight, the server's copy
  is deleted too.
- If the server creates a row but its answer has no id, the row is not sent
  again in this session (that would create more copies), and a message is
  printed to the debug console.
- A pull that gets chapters **without their text** (the server's list may leave
  it out) no longer blanks the text stored on the device.
- `pushAllExistingData()` (the Kotlin app ran it on every launch) is no longer
  called. It sends local ids to the bulk endpoint, which overwrites rows with
  the same id, so it is only safe from one device.

### After updating from an earlier build

Rows created by earlier builds of this port have local ids that are not the
server's ids, and edits to them may have been sent to the wrong server rows.
Start the local copy over once:

- **Windows:** close the app and delete `papyrquill.sqlite` (and any
  `papyrquill.sqlite-wal` / `-shm` next to it) from your Documents folder.
- **Android:** Settings -> Apps -> PapyrQuill -> Storage -> Clear data.

The app then downloads everything from the server. If you tested with two
devices, it is worth checking the server's stories and chapters for rows that
got mixed up.

## Existing behavior kept as-is

These come from the Kotlin app and are still true:

- Updating a chapter with `timelineFrameId == null` omits the field, so a chapter
  can't be moved back to "unassigned" through the update endpoint.
- **Deletes and offline edits don't travel between devices.** A pull never
  removes a row that was deleted elsewhere. A delete or an edit of an
  already-synced row made while offline is not retried, and the next pull can
  restore the row or overwrite the edit. (Rows *created* offline are handled, as
  described above.)
- If the server creates a row but the answer is lost on the way back (a
  timeout), the app does not know and sends it again later, which makes a copy.
  This is rare and needs the server to take an idempotency key to fix.
- If the old Kotlin app is still installed and pointed at the same server, its
  launch-time bulk push still sends its local ids and can overwrite rows made on
  other devices. Retire it once everything runs on this app.

## If the build complains about `app_database.g.dart`

That file is generated, not hand-written. If you copy new project files over an
older copy, the old `lib/data/app_database.g.dart` is stale and can reference
names that no longer exist (for example `_nowMillis`). Delete it and regenerate:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Do this whenever `lib/data/tables.dart` or `app_database.dart` changes.

## If the first build shows errors

I could not compile this project when writing it, so a few small fixes may be
needed. Likely spots:

- `XFile` not found in `docx_exporter.dart`: add
  `import 'package:cross_file/cross_file.dart';` and `cross_file:` to
  `pubspec.yaml`.
- Package versions: `flutter_quill`, `share_plus` and `file_picker` change their
  APIs between major versions. The code targets flutter_quill 11, share_plus 13
  and file_picker 13. If pub picks other versions, the error will name the call.
