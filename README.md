# Note App

A modern, fully offline, local-first Windows desktop note-taking application built with **Flutter** and **Riverpod**.

> **This application is entirely offline.** There is no login, authentication, API, cloud sync, or any internet dependency. All data lives locally in SQLite databases within a user-chosen workspace folder.

---

## Key Features

- **Local-first, offline by default:** All data resides exactly where you tell it to.
- **Multi-Database Support:** Keep work, personal, and project notes completely separate.
- **Customizable Workspace:** Choose your own vault directory to easily back up or sync with your preferred cloud drive provider.
- **Clean Interface:** Designed specifically for desktop screens with a persistent sidebar and focused editor view.
- **Secure by Default:** No telemetry, no forced account creation, no vendor lock-in.
- **Desktop Packaging Ready**: Reproducible MSIX and PKGBUILD setups included (see [PACKAGING.md](PACKAGING.md)).
- **Desktop-first layout** — ChatGPT-inspired design with left sidebar + right editor panel
- **Multi-database support** — Multiple SQLite databases per workspace, switchable in one click
- **Workspace manifest system** — `.notes_workspace.json` tracks databases, settings, and active state
- **Auto-load last workspace** — App remembers the last opened workspace and loads it automatically on restart
- **Notes CRUD** — Create, rename, edit, duplicate, and soft-delete notes
- **Debounced autosave** — Saves automatically 700 ms after you stop typing
- **2 built-in themes** — Default (deep blue) and Terminal (green-on-black), with scalable theme system
- **3 sort modes** — Alphabetical, Last Modified, and Custom manual ordering
- **Drag-and-drop reordering** — Reorder notes in the sidebar when Custom sort is active
- **Groups** — Create, rename, delete, and color-code note groups
- **Group color accents** — Notes visually inherit their group color (left accent bar + name pill)
- **Group filtering** — Click a group chip in the sidebar to filter notes
- **Scrollable group bar** — Horizontal scroll with mouse wheel support + visible Scrollbar, "+" button always accessible
- **Right-click context menus** — Notes: Düzenle, Kısayol toggle, Rename, Duplicate, Group, Delete. Groups: Rename, Change Color, Delete
- **Shortcut notes** — Mark a note as shortcut; left-click copies content to clipboard with feedback
- **Editor toolbar** — Formatting actions: H1, H2, H3, Checkbox, Bold, Emoji
- **Robust toolbar actions** — Headings/checkboxes strip existing prefixes before applying; toggleable; bold wraps selection correctly
- **Live Markdown Highlighting** — Editor parses raw plain text and highlights headings, checkboxes, and bold text dynamically as you type without changing the storage format
- **Emoji picker** — Full emoji picker via `emoji_picker_flutter`, inserts directly into content
- **Adjustable editor font size** — 10–20 pt stepper in Settings, persisted in manifest. Editor uses clean sans-serif typography (Segoe UI/Inter/Roboto)
- **Persistent settings** — Theme, sort mode, font size persist in the workspace manifest
- **Modular architecture** — Services → Repositories → Providers → UI

---

## Architecture Overview

```
┌─────────────────────────────────────────────────┐
│                     UI Layer                    │
│  AppShell · AppSidebar · NotesList · EditorPanel│
│  MarkdownTextController · SettingsDialog        │
├─────────────────────────────────────────────────┤
│                 Provider Layer                  │
│  workspace · database · notes · groups · settings│
│               app_preferences                   │
├─────────────────────────────────────────────────┤
│               Repository Layer                  │
│          NotesRepository · GroupsRepository      │
├─────────────────────────────────────────────────┤
│                 Service Layer                   │
│  WorkspaceService · DatabaseService · NotesSvc  │
│           GroupsService · AppPreferences         │
├─────────────────────────────────────────────────┤
│   SQLite (via sqlite3)  ·  SharedPreferences    │
└─────────────────────────────────────────────────┘
```

---

## Folder Structure

```
lib/
├── main.dart                           # Entry point, initializes AppPreferences
├── app/
│   └── main.dart                       # MaterialApp, ConsumerWidget, theme from settings
├── core/
│   ├── constants.dart
│   ├── utils.dart
│   └── theme_definitions.dart          # 2 themes + NoteAppColors ThemeExtension
├── models/
│   ├── note.dart                       # Note (group_id, sort_order, is_shortcut)
│   ├── group.dart                      # Group model + GroupColors palette (10 colors)
│   ├── database_info.dart
│   ├── workspace_manifest.dart
│   └── app_settings.dart               # AppThemeId, AppSortMode, editorFontSize
├── services/
│   ├── workspace_service.dart
│   ├── database_service.dart           # Schema + migrations (notes, groups, is_shortcut)
│   ├── notes_service.dart              # CRUD + sort + group filter + reorder + shortcut toggle
│   ├── groups_service.dart             # Groups CRUD + assign/remove note
│   └── app_preferences.dart            # shared_preferences wrapper (last workspace path)
├── data/
│   └── repositories/
│       ├── notes_repository.dart
│       └── groups_repository.dart
├── providers/
│   ├── workspace_provider.dart
│   ├── database_provider.dart          # Exposes NotesService + GroupsService
│   ├── notes_provider.dart             # Group filter sync, sort sync, toggleShortcut
│   ├── groups_provider.dart            # Group filter state, CRUD
│   ├── settings_provider.dart          # Theme + sort + font size → manifest
│   └── app_preferences_provider.dart   # Device-level preferences
└── ui/
    ├── screens/
    │   └── settings_screen.dart        # Theme, sort, font size, workspace, DBs
    └── widgets/
        ├── app_shell.dart              # Auto-loads last workspace on startup
        ├── app_sidebar.dart            # Scrollable groups bar, sort tabs, search
        ├── notes_list.dart             # Shortcut badge, click-to-copy, context menu
        ├── main_editor_panel.dart      # Robust toolbar, emoji, group chip, font size
        └── markdown_text_controller.dart # Hybrid live syntax highlighting for editor
```

---

## Edit / View Hybrid Editor

To deliver a high-quality modern desktop note-taking experience _while still storing exactly plain text offline_:
The app uses a custom `MarkdownTextController` which overrides how Flutter builds its text spans during typing.

- Lines starting with `# `, `## `, `### ` enlarge automatically and turn bold.
- Lines starting with `- [ ] ` or `- [x] ` render custom distinct styles.
- Content wrapping `**words**` highlights instantly.
- The default text is drawn with a high-quality desktop typography stack (Segoe UI, Inter, Roboto) rather than generic monospace code font.

This provides the exact experience requested—structured, polished, beautiful—without relying on heavy unmaintainable HTML wrappers or complex `quill_editor` models.

---

## Shortcut Notes

A note can be marked as a "Shortcut Note" via the right-click context menu.

| Action                  | Behavior                                                       |
| ----------------------- | -------------------------------------------------------------- |
| **Mark as shortcut**    | Right-click → "Kısayol Olarak Ayarla"                          |
| **Remove shortcut**     | Right-click → "Kısayoldan Çıkar"                               |
| **Left-click shortcut** | Copies note content to clipboard + shows "Kopyalandı" snackbar |
| **Edit shortcut**       | Right-click → "Düzenle" opens it in the editor                 |
| **Visual indicator**    | ⚡ bolt icon next to the title in the notes list               |

Stored as `is_shortcut INTEGER NOT NULL DEFAULT 0` in the notes table.

---

## Groups

### Schema

```sql
groups(
  id          INTEGER PRIMARY KEY,
  name        TEXT NOT NULL,
  color       TEXT NOT NULL,    -- hex string, e.g. '#2563EB'
  created_at  INTEGER NOT NULL
)
```

Notes reference groups via `group_id INTEGER NULL` in the `notes` table.

### Scrollable Group Bar

The group chips are in a horizontally scrollable row with:

- Dedicated visible `Scrollbar` on hover underneath the chips
- Mouse wheel translates vertical scroll to horizontal effortlessly
- The "+" button is the last item inside the scroll area, always reachable
- Works cleanly with many groups without layout overflow clipping

---

## Editor Toolbar

### Robust Formatting Actions

| Button       | Text Convention | Behavior                                                                     |
| ------------ | --------------- | ---------------------------------------------------------------------------- |
| **Emoji**    | N/A             | Toggles emoji picker panel below content                                     |
| **H1**       | `# ` prefix     | Strips existing prefix → applies `# ` (toggles off if already H1)            |
| **H2**       | `## ` prefix    | Strips existing prefix → applies `## ` (toggles off if already H2)           |
| **H3**       | `### ` prefix   | Strips existing prefix → applies `### ` (toggles off if already H3)          |
| **Checkbox** | `- [ ] ` prefix | Strips heading prefix → toggles `- [ ] ` on/off                              |
| **Bold**     | `**text**`      | Wraps selection with `**`. No selection → inserts `****` with cursor between |

All actions operate on the **current line** where the cursor sits. Heading/checkbox actions strip conflicting prefixes before applying. Clicking the same button again toggles it off.

### Editor Settings

- Default text size: **12pt** (configurable 10–20 pt in Settings)
- Font: `Segoe UI` / `Inter` / `Roboto`
- Title: distinct 24pt heading style
- Content: 1.6 line height for readability

---

## Database Schema

### `notes` table

```sql
notes(
  id          INTEGER PRIMARY KEY,
  title       TEXT NOT NULL,
  content     TEXT NOT NULL,
  group_id    INTEGER NULL,
  created_at  INTEGER NOT NULL,
  updated_at  INTEGER NOT NULL,
  is_deleted  INTEGER NOT NULL DEFAULT 0,
  sort_order  INTEGER NOT NULL DEFAULT 0,
  is_shortcut INTEGER NOT NULL DEFAULT 0
)
```

### `groups` table

```sql
groups(
  id          INTEGER PRIMARY KEY,
  name        TEXT NOT NULL,
  color       TEXT NOT NULL,
  created_at  INTEGER NOT NULL
)
```

---

## Settings Storage

| Setting             | Stored In                         | Key                   |
| ------------------- | --------------------------------- | --------------------- |
| Theme               | Workspace manifest `settings`     | `theme`               |
| Sort mode           | Workspace manifest `settings`     | `sort_mode`           |
| Editor font size    | Workspace manifest `settings`     | `editor_font_size`    |
| Last workspace path | shared_preferences (device-level) | `last_workspace_path` |

---

## How to Run

```bash
cd note_app
flutter pub get
flutter run -d windows
```

**Requires:** Flutter SDK ≥ 3.2.0, Visual Studio with C++ workload.

---

## Troubleshooting

| Problem                             | Solution                                                                  |
| ----------------------------------- | ------------------------------------------------------------------------- |
| App asks for workspace every launch | Check `shared_preferences` is working; ensure the saved path still exists |
| Groups overflow sidebar             | Fixed — group bar is horizontally scrollable with mouse wheel support     |
| Bold inserts only `*`               | Fixed — now properly inserts `****` or wraps selection with `**`          |
| Headings don't remove old prefix    | Fixed — all heading/checkbox actions strip existing prefixes first        |
| Font size not changing              | Adjust in Settings → Editör → Yazı Boyutu (10–20 pt)                      |

---

## License

Private project — © Eren Şahin
