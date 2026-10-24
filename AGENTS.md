# Dateora Mobile Application

Dateora is built with **Flutter (Dart 3.x)**.

### Architecture Guidelines
- **Framework:** Flutter (Android, iOS, Web)
- **State Management:** `provider` (`ChangeNotifier`, `Consumer`)
- **Local Database:** SQLite via `sqflite`
- **Notifications:** `flutter_local_notifications` + `timezone`
- **Design System:** Material 3 with customized `AppColors` and `AppTheme`
- **Backend Sync:** REST API connecting to Node.js/Express with MySQL
