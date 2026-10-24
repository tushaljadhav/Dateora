# Dateora — Architecture (Flutter)

> Companion docs: **Dateora_PRD.md** and **Dateora_Rules.md**.

## 1. Tech Stack

| Layer | Choice | Why |
|---|---|---|
| **Framework** | **Flutter (Dart 3.x)** | High-performance compiled native UI for Android and iOS |
| **State Management** | **`provider`** (`ChangeNotifier`, `Consumer`) | Clean, reactive, testable state without boilerplate |
| **Local Database** | **SQLite via `sqflite`** | Offline-first, fast local SQL storage with WAL mode & foreign keys |
| **Notifications** | **`flutter_local_notifications`** + `timezone` | Exact alarm triggers, Doze persistence, custom channel control |
| **Data Portability** | `share_plus` + `file_picker` | Zero-lockin JSON backup export and import |
| **Media / Photos** | `image_picker` | Camera and gallery photo attachment for items |
| **Cloud Sync** | Node.js / Express REST API with MySQL | Optional multi-device backup & sync |

## 2. Layers

```
UI (Screens / Widgets)
   │  listens to & calls
Providers (ItemsProvider, SettingsProvider)
   │  invokes
Repository / Service Layer (ItemRepository, NotificationService, ExportService, SyncService)
   │  reads/writes
DatabaseHelper (SQLite / sqflite)  <───>  Local Push Notifications
```

UI widgets never call the SQLite database or notifications directly; mutations strictly flow through `ItemRepository` which automatically keeps database records and scheduled notification alarms in sync.
