# Note App

A modern, fully offline, local-first Windows desktop note-taking application built with **Flutter** and **Riverpod**.

> **This application is entirely offline.** There is no login, authentication, API, cloud sync, or any internet dependency. All data lives locally in SQLite databases within a user-chosen workspace folder.

---

## Features

- **Desktop-first layout** — ChatGPT-inspired design with a left sidebar and right editor panel
- **Multi-database support** — Multiple SQLite databases per workspace, switchable in one click
- **Workspace manifest system** — `.notes_workspace.json` tracks databases, settings, and active state
- **Notes CRUD** — Create, rename, edit, duplicate, and soft-delete notes
- **Debounced autosave** — Saves automatically 700 ms after you stop typing
- **2 built-in themes** — Default (deep blue) and Terminal (green-on-black), with scalable theme system
- **3 sort modes** — Alphabetical, Last Modified, and Custom manual ordering
- **Drag-and-drop reordering** — Reorder notes in the sidebar when Custom sort is active
- **Right-click context menu** — Rename, Duplicate, Add to Group (placeholder), Delete
- **Persistent settings** — Theme and sort preferences persist in the workspace manifest
- **Modular architecture** — Services → Repositories → Providers → UI

---

## Architecture Overview

```
┌─────────────────────────────────────────────────┐
│                     UI Layer                    │
│  AppShell · AppSidebar · NotesList · EditorPanel│
│                  SettingsDialog                 │
├─────────────────────────────────────────────────┤
│                 Provider Layer                  │
│  workspace · database · notes · settings        │
├─────────────────────────────────────────────────┤
│               Repository Layer                  │
│                NotesRepository                  │
├─────────────────────────────────────────────────┤
│                 Service Layer                   │
│  WorkspaceService · DatabaseService · NotesSvc  │
├─────────────────────────────────────────────────┤
│              SQLite (via sqlite3)               │
└─────────────────────────────────────────────────┘
```

**Key principle:** UI never calls SQLite directly. All data flows through providers which delegate to repositories/services.

---

## Folder Structure

```
lib/
├── main.dart                       # App entry point, ProviderScope
├── app/
│   └── main.dart                   # MaterialApp (ConsumerWidget), theme from settingsProvider
├── core/
│   ├── constants.dart              # App-wide constants
│   ├── utils.dart                  # Utility helpers (timestamps)
│   └── theme_definitions.dart      # Centralized theme builder + NoteAppColors extension
├── models/
│   ├── note.dart                   # Note data model (with sort_order)
│   ├── database_info.dart          # Database metadata (name, label, createdAt)
│   ├── workspace_manifest.dart     # Workspace manifest model
│   └── app_settings.dart           # AppThemeId, AppSortMode, AppSettings
├── services/
│   ├── workspace_service.dart      # Load/save/create workspace manifests
│   ├── database_service.dart       # Open/close SQLite, ensure schema + migrations
│   └── notes_service.dart          # CRUD queries with sort modes + reorder + duplicate
├── data/
│   └── repositories/
│       └── notes_repository.dart   # Thin wrapper over NotesService
├── providers/
│   ├── workspace_provider.dart     # WorkspaceState + WorkspaceNotifier
│   ├── database_provider.dart      # DatabaseState + DatabaseNotifier
│   ├── notes_provider.dart         # NotesState + NotesNotifier (reorder, rename, duplicate)
│   └── settings_provider.dart      # AppSettings notifier, persists to manifest
└── ui/
    ├── screens/
    │   └── settings_screen.dart    # Settings dialog (theme, sort, workspace, DBs)
    └── widgets/
        ├── app_shell.dart          # Root shell: sidebar + editor Row
        ├── app_sidebar.dart        # 300px sidebar with sort selector tabs
        ├── notes_list.dart         # ListView / ReorderableListView + context menu
        └── main_editor_panel.dart  # DB selector, title field, content field, autosave
```

---

## Theme System

Two built-in themes, selectable from Settings:

| Theme                   | Background | Primary   | Hover     | Highlight |
| ----------------------- | ---------- | --------- | --------- | --------- |
| **Default (Koyu Mavi)** | `#0F172A`  | `#2563EB` | `#38BDF8` | `#60A5FA` |
| **Terminal (Yeşil)**    | `#000000`  | `#00FF41` | `#00C853` | `#00E676` |

Themes are defined centrally in `theme_definitions.dart` using a shared builder. Adding a new theme requires only adding an enum value and a color set — no widget changes needed.

Theme preference persists in the workspace manifest `settings` map.

---

## Sort Modes

| Mode                       | Order        | SQL                                        |
| -------------------------- | ------------ | ------------------------------------------ |
| **Alphabetical** (default) | Title A→Z    | `ORDER BY LOWER(title) ASC`                |
| **Last Modified**          | Newest first | `ORDER BY updated_at DESC`                 |
| **Custom**                 | Manual       | `ORDER BY sort_order ASC, updated_at DESC` |

- The sort selector appears as segmented tabs below the search bar.
- Also configurable from the Settings dialog dropdown.
- Sort preference persists in the workspace manifest.

### Custom Drag-and-Drop

When sort mode is **Custom**:

- A drag handle icon (≡) appears on each note item.
- Notes can be reordered by clicking and dragging the handle.
- The new order is written to the `sort_order` column in the database.
- Drag reorder is **disabled** in Alphabetical and Last Modified modes.

---

## Database Schema

### `meta` table

```sql
meta(key TEXT PRIMARY KEY, value TEXT)
```

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
  sort_order  INTEGER NOT NULL DEFAULT 0   -- added in migration v2
)
```

**Migration:** When `DatabaseService` opens a database, it checks `PRAGMA table_info` and adds `sort_order` if missing. Existing notes receive a sensible order based on `created_at`.

---

## Right-Click Context Menu

Right-clicking a note in the sidebar opens a context menu with:

| Action               | Behavior                                        |
| -------------------- | ----------------------------------------------- |
| **Yeniden Adlandır** | Opens a rename dialog                           |
| **Kopyala**          | Duplicates the note                             |
| **Gruba Ekle**       | Placeholder dialog (groups not yet implemented) |
| **Sil**              | Soft deletes the note                           |

---

## Workspace & Manifest

The app operates within a **workspace folder** chosen by the user. Inside that folder, a manifest file tracks all databases and settings.

### Manifest: `.notes_workspace.json`

```json
{
  "format_version": 1,
  "app_id": "com.erensahin.notes",
  "workspace_id": "c5579b7b-...",
  "active_db": "notes_main.db",
  "databases": [
    { "name": "notes_main.db", "label": "Ana", "created_at": 1772806809 }
  ],
  "settings": {
    "theme": "defaultTheme",
    "sort_mode": "alphabetical"
  }
}
```

| Field                | Purpose                                     |
| -------------------- | ------------------------------------------- |
| `name`               | Actual SQLite filename on disk              |
| `label`              | User-friendly display name shown in the UI  |
| `active_db`          | The `name` of the currently active database |
| `settings.theme`     | Selected theme ID                           |
| `settings.sort_mode` | Selected sort mode                          |

---

## How to Run

### Prerequisites

- Flutter SDK ≥ 3.2.0
- Windows desktop development tools (Visual Studio with C++ workload)

### Steps

```bash
cd note_app
flutter pub get
flutter run -d windows
```

---

## Dependencies

| Package                | Purpose                            |
| ---------------------- | ---------------------------------- |
| `flutter_riverpod`     | State management                   |
| `sqlite3`              | SQLite database driver             |
| `sqlite3_flutter_libs` | Native SQLite binaries for Flutter |
| `file_picker`          | Folder/file picker dialogs         |
| `path`                 | Cross-platform path manipulation   |
| `path_provider`        | Platform-specific directory paths  |
| `uuid`                 | UUID generation for workspace IDs  |

---

## Current Limitations

- No rich text editor — content is plain text for now
- No note groups or folders (placeholder exists)
- No keyboard shortcuts
- Search filters in memory (no FTS)
- No import/export
- No undo/redo history beyond system defaults

---

## Planned Future Phases

1. **Groups & Folders** — Organize notes into hierarchical groups via `group_id`
2. **Shortcuts** — Quick-access pinned notes section
3. **Advanced Editor Engine** — Rich text / Markdown support
4. **Heading Folding** — Collapse/expand sections
5. **Drive Export** — Export database snapshots
6. **Full-Text Search** — SQLite FTS5 integration
7. **Additional Themes** — Light mode, custom accent colors

---

## Troubleshooting

| Issue                               | Solution                                           |
| ----------------------------------- | -------------------------------------------------- |
| App shows "Çalışma alanı seçilmedi" | Click **Klasör Seç** and pick a folder             |
| "Database file already exists"      | Choose a different label/name                      |
| Notes don't appear after DB switch  | Ensure the DB file exists in workspace             |
| Build fails on Windows              | Ensure Visual Studio C++ build tools are installed |
| `sqlite3` import error              | Run `flutter pub get`                              |

---

## License

Private project — © Eren Şahin
