# Dateora — Master Project & Design Specification

> **Version:** 1.0.0 (Production Ready)  
> **Type:** Mobile Application (Offline-First Expiry Tracker)  
> **Framework:** Flutter (Dart 3.x)  
> **State Management:** Provider (`ChangeNotifier`, `Consumer`)  
> **Local Database:** SQLite via `sqflite`  
> **Cloud Sync:** Node.js/Express REST API with MySQL (`FreeSQLDatabase.com`)

---

## 1. Executive Summary & Vision

* **App Name:** Dateora
* **One-Liner:** A premium, offline-first household expiration tracker that prevents users from wasting money or consuming expired food and medicine by tracking expiry dates and sending timely alerts.
* **Core Philosophy:** 
  * **No mandatory login / signup:** Immediate utility upon cold start.
  * **100% Offline-First:** Every core feature (adding, searching, filtering, calendar, reminders) works in airplane mode.
  * **Fast Path Path to Value:** Adding an item requires less than 30 seconds (name, category, expiry date); all optional fields (photo, quantity, unit, location, notes) are cleanly collapsed.
  * **No Dead Buttons / No Placeholders:** Every visible control is fully functional and interactive.

---

## 2. Technical Stack & Dependencies

| Layer | Technology | Purpose |
| :--- | :--- | :--- |
| **Mobile Core** | Flutter 3.13.4+ / Dart 3.1.2+ | Native compilation for Android & iOS |
| **State Management** | `provider: ^6.1.5` | Reactive, decoupled state without boilerplate |
| **Local Storage** | `sqflite: ^2.3.2`, `path_provider`, `path` | Local SQLite database engine (`dateora.db`) with WAL mode |
| **Notifications** | `flutter_local_notifications: ^18.0.1`, `timezone: ^0.9.4` | System alarm manager & exact notification triggers |
| **Preferences** | `shared_preferences: ^2.2.3` | Theme mode, daily alert time, onboarding completion flag |
| **Image & Media** | `image_picker: ^1.0.8` | Camera & gallery photo attachment |
| **Portability** | `share_plus: ^7.2.2`, `file_picker: ^8.0.0` | Cross-device JSON export and import |
| **HTTP / Networking** | `http: ^1.1.0` | Cloud Push / Pull sync with REST API |
| **Date Formatting** | `intl: ^0.19.0` | Localized date parsing and human formatting |
| **IDs** | `uuid: ^4.6.0` | Collision-resistant UUIDv4 IDs |

---

## 3. Design System & UI/UX Guidelines

The design follows a modern Apple/Linear-inspired minimal aesthetic: clean, card-based, content-focused, without distracting gradients or visual clutter.

### 3.1 Curated Color Palette
```dart
// Brand Colors
static const Color primary      = Color(0xFF2563EB); // Royal Blue 600
static const Color primaryLight = Color(0xFF3B82F6); // Blue 500
static const Color primaryDark  = Color(0xFF1D4ED8); // Blue 700
static const Color accent       = Color(0xFF0EA5E9); // Cyan

// Semantic Status Colors (Status is never color-only — always accompanied by text and icon)
static const Color safe         = Color(0xFF10B981); // Emerald Green (Safe items)
static const Color warning      = Color(0xFFF59E0B); // Amber (Expiring soon)
static const Color danger       = Color(0xFFEF4444); // Red (Expired items)

// Dark Theme Surfaces
static const Color darkBg           = Color(0xFF090D16); // Deep space background
static const Color darkSurface      = Color(0xFF131C2E); // Elevated cards & navbar
static const Color darkCard         = Color(0xFF182238); // Tile background
static const Color darkBorder       = Color(0xFF1E293B); // Subtle border
static const Color darkTextPrimary  = Color(0xFFF8FAFC);
static const Color darkTextSecondary= Color(0xFF94A3B8);
static const Color darkTextMuted    = Color(0xFF64748B);

// Light Theme Surfaces
static const Color lightBg          = Color(0xFFF8FAFC); // Clean off-white
static const Color lightSurface     = Color(0xFFFFFFFF); // Card background
static const Color lightCard        = Color(0xFFFFFFFF);
static const Color lightBorder      = Color(0xFFE2E8F0); // Light divider
static const Color lightTextPrimary = Color(0xFF0F172A);
static const Color lightTextSecondary=Color(0xFF475569);
static const Color lightTextMuted   = Color(0xFF94A3B8);
```

### 3.2 Spacing & Radii Scale
* **Base Grid:** Strict 8pt grid (`4px`, `8px`, `12px`, `16px`, `20px`, `24px`, `32px`).
* **Corner Radius:**
  * Cards & Modals: `16px`
  * Buttons & TextInputs: `12px` to `14px`
  * Status Pills: `20px` (pill/capsule shape)
  * Category Badges: `12px`

### 3.3 Status Thresholds
* **Expired:** Expiry date is before today (`daysLeft < 0`). Badge is Red (`#EF4444`) with `Icons.error_outline`.
* **Expiring Soon:** Within user's alert window (`daysLeft <= 7`). Badge is Amber (`#F59E0B`) with `Icons.access_time`.
* **Safe:** Everything else (`daysLeft > 7`). Badge is Green (`#10B981`) with `Icons.check_circle_outline`.

---

## 4. Preset Categories

Dateora provides 9 built-in categories, each with distinct semantic styling:
1. **Groceries** (`#10B981`) — `Icons.local_grocery_store_outlined`
2. **Medicine** (`#EF4444`) — `Icons.medical_services_outlined`
3. **Skincare** (`#EC4899`) — `Icons.spa_outlined`
4. **Dairy & Eggs** (`#F59E0B`) — `Icons.egg_outlined`
5. **Household** (`#8B5CF6`) — `Icons.home_outlined`
6. **Documents** (`#3B82F6`) — `Icons.description_outlined`
7. **Beverages** (`#06B6D4`) — `Icons.coffee_outlined`
8. **Pantry** (`#F97316`) — `Icons.kitchen_outlined`
9. **Custom** (`#64748B`) — `Icons.label_outline`

---

## 5. Screen Hierarchy & User Flows

```
OnboardingScreen (First launch only)
       │
MainNavigationScreen (Persistent Bottom Bar + Floating Action Button)
  ├── Tab 1: HomeScreen (Dashboard, Greeting, Stat Chips, Attention Feed)
  ├── Tab 2: ItemsScreen (Search, All/Expiring/Expired/Safe Chips, Category Scroll, Sort Menu)
  ├── Tab 3: CalendarScreen (Monthly interactive grid with colored dots & bottom day list)
  ├── Tab 4: HistoryScreen (Used, Finished, Disposed, Expired tabs + Restore button)
  └── Tab 5: SettingsScreen (Theme Mode, Reminders, Cloud Sync, JSON Backup, Reset)
  └── [FAB] ➔ AddItemScreen (Quick date chips, categories, collapsible extra details)
  └── [Item Tap] ➔ ItemDetailsScreen (Countdown, inline reminders, Mark outcomes, Delete)
                    └── EditItemScreen (Full update & auto notification reschedule)
```

### Screen Details:
1. **OnboardingScreen:** Contextual 2-step tour explaining zero sign-up requirement and requesting notification permissions with purpose rather than a bare OS popup.
2. **HomeScreen:** Dynamic greeting (`Good Morning`, `Good Afternoon`, `Good Evening`), 3 tappable stat cards (`Total Items`, `Expiring Soon`, `Expired`), and an "Attention Needed" preview feed.
3. **AddItemScreen:** 
   * Quick date chips: `Today` (0d), `Tomorrow` (1d), `7 Days`, `30 Days`, or custom calendar picker.
   * Multi-select reminder chips: `On expiry day`, `1 day before`, `3 days before`, `7 days before`.
   * Optional details: Image picker, quantity + unit, storage location, notes.
4. **ItemDetailsScreen:**
   * Full view with photo/category hero, live relative countdown string (`"Expires in 3 days"`, `"Expired 2 days ago"`).
   * Three distinct outcomes: **Used**, **Finished**, **Disposed** (cancels reminders and moves to History).
   * Restore action to bring accidentally archived items back to active tracking.
5. **CalendarScreen:** Monthly grid with color-coded dot badges (Red = expired, Amber = warning, Green = safe). Day selection displays items in a bottom list.
6. **HistoryScreen:** TabBar separating items into `Used`, `Finished`, `Disposed`, and `Expired`.
7. **SettingsScreen:** Dark/Light/System theme selector, daily alert time picker, Cloud Backup & Restore buttons, and JSON file export/import.

---

## 6. Local SQLite Database Architecture

* **Database Name:** `dateora.db`
* **Engine:** SQLite with WAL (`Write-Ahead Logging`) mode and foreign keys enabled.

### Table: `items`
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `TEXT` | `PRIMARY KEY NOT NULL` | UUIDv4 string |
| `name` | `TEXT` | `NOT NULL` | Item display name |
| `category` | `TEXT` | `NOT NULL` | Category ID (e.g. `groceries`) |
| `expiry_date` | `TEXT` | `NOT NULL` | ISO format `YYYY-MM-DD` |
| `photo_uri` | `TEXT` | `NULLABLE` | Local file path to attached photo |
| `quantity` | `REAL` | `NULLABLE` | Quantity amount (e.g. `2.5`) |
| `unit` | `TEXT` | `NULLABLE` | Unit name (e.g. `bottles`, `kg`) |
| `location` | `TEXT` | `NULLABLE` | Storage place (e.g. `Fridge`) |
| `notes` | `TEXT` | `NULLABLE` | Custom notes |
| `reminder_offsets` | `TEXT` | `NOT NULL` | JSON array e.g. `"[7,3,1]"` |
| `status` | `TEXT` | `DEFAULT 'active'` | `active`, `used`, `finished`, `disposed`, `expired` |
| `status_changed_at`| `TEXT` | `NULLABLE` | ISO timestamp of status change |
| `created_at` | `TEXT` | `NOT NULL` | ISO creation timestamp |
| `updated_at` | `TEXT` | `NOT NULL` | ISO last updated timestamp |

### Table: `notification_records`
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `TEXT` | `PRIMARY KEY NOT NULL` | Deterministic ID `${itemId}:${offsetDays}` |
| `item_id` | `TEXT` | `REFERENCES items(id) ON DELETE CASCADE` | Parent item ID |
| `fires_at` | `TEXT` | `NOT NULL` | ISO datetime when alert fires |
| `notifee_trigger_id`| `TEXT` | `NULLABLE` | Native trigger identifier |

### Table: `app_settings`
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `setting_key` | `TEXT` | `PRIMARY KEY NOT NULL` | Setting identifier |
| `setting_value` | `TEXT` | `NOT NULL` | Serialized setting value |

---

## 7. Remote Cloud Backend & Sync Architecture

* **Database:** MySQL on `sql12.freesqldatabase.com` (Database: `sql12838670`)
* **API Server:** Node.js Express server (`server/index.js`) deployed on Render (`https://dateora.onrender.com/api`)
* **Endpoints:**
  * `POST /api/sync/push`: Accepts `{ items: [...], settings: {...} }` and upserts into remote MySQL.
  * `GET /api/sync/pull`: Returns `{ success: true, data: { items: [...], settings: {...} } }`.
  * `POST /api/items`: CRUD items.
  * `GET /api/settings`: Fetch cloud settings.
* **Compatibility:** Flutter's `SyncService` natively maps between SQLite column names and remote API JSON properties.

---

## 8. Android Native Configuration

* **Package ID:** `com.dateora.dateora`
* **`minSdkVersion`:** `21` (Android 5.0+)
* **`targetSdkVersion`:** `34` (Android 14)
* **Declared Android Permissions (`AndroidManifest.xml`):**
  * `android.permission.POST_NOTIFICATIONS`
  * `android.permission.SCHEDULE_EXACT_ALARM`
  * `android.permission.USE_EXACT_ALARM`
  * `android.permission.RECEIVE_BOOT_COMPLETED`
  * `android.permission.VIBRATE`
* **Release Artifact:** `build/app/outputs/flutter-apk/app-release.apk` (24.5 MB)
