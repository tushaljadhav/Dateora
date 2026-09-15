# Dateora — Architecture

> Read alongside **Dateora_PRD.md** (what to build) and **Dateora_Rules.md** (conventions, checklists, and what changed from the original prompt).

## 1. Recommended Stack

Chosen to match what you're already comfortable with — this is close to the same mobile-client combo from your health-monitoring app — and to keep the app future-proof for barcode/OCR/AI without a rewrite.

| Layer | Choice | Why |
|---|---|---|
| Framework | React Native via **Expo**, using a Dev Client build (not Expo Go — notifications need a native module) | Keeps you in TS/React; EAS Build handles signing and Play Store target-API compliance for you |
| Expo SDK | Latest stable — SDK 56 has a known Hermes memory regression affecting `react-native-reanimated`/`react-native-worklets`, fixed in SDK 57. Use whichever is current and stable when you start. | Avoids a known, documented bug |
| Language | TypeScript, strict mode | Matches your existing projects |
| Navigation | Expo Router (file-based) | Current Expo default; tabs for Home/Items/Calendar/History/Settings, stacked screens for Add/Edit/Details/Onboarding |
| Styling | NativeWind | Same as your health app's mobile client |
| State | Zustand | Same as your health app — one store per domain (items, settings, filters) |
| Local DB | SQLite via `expo-sqlite` + **Drizzle ORM** | Type-safe on-device schema/queries — the closest on-device equivalent to the Prisma workflow you already use server-side |
| Forms/validation | React Hook Form + Zod | Keeps Add Item fast and strongly typed |
| Notifications | **`@notifee/react-native`** | The right tool for *local* scheduled notifications on Android — full channel control, exact-alarm triggers, reliable delivery through Doze. Plain `expo-notifications` is built more for remote push; Notifee is built for "the reminder fires exactly when promised," which is Dateora's entire value proposition. Needs a Dev Client build — which you'd need for a launch-ready app anyway. |
| Icons | lucide-react-native | One consistent icon family, as required |
| Future: barcode/OCR | `expo-camera`'s built-in barcode scanning; OCR via ML Kit text recognition, or a cloud OCR call gated behind a "Pro" flag later | Decoupled from the core flow (see §7), so it slots in without touching Add Item's save logic |

## 2. Layers

```
UI (screens / components)
   |  reads/writes via hooks
Zustand stores (items, settings, filters — pure state, no I/O)
   |  calls
Repository / service layer (itemRepository, notificationService, exportService)
   |  talks to
SQLite via Drizzle  <---->  Notifee (scheduling)
```

UI components never import the database or Notifee directly — always through the repository/service layer. This is what makes the original brief's "clean separation" requirement actually enforceable rather than aspirational.

## 3. Data Model

**Item**

| Field | Type | Notes |
|---|---|---|
| id | string (uuid) | |
| name | string | required |
| category | string | required — a preset or custom category |
| expiryDate | ISO date string | required |
| photoUri | string? | local file URI |
| quantity | number? | |
| unit | string? | |
| location | string? | |
| notes | string? | |
| reminderOffsets | number[] | days before expiry, e.g. `[7, 3, 1, 0]` |
| status | enum: `active \| used \| finished \| disposed` | drives the History bucket |
| statusChangedAt | ISO datetime? | when it left "active" |
| createdAt / updatedAt | ISO datetime | |

**NotificationRecord** (internal, not user-facing)

| Field | Type | Notes |
|---|---|---|
| id | string | deterministic: `${itemId}:${offsetDays}` so edits/deletes can target it precisely |
| itemId | string | foreign key |
| firesAt | ISO datetime | |
| notifeeTriggerId | string | returned by Notifee when scheduled |

**Settings**

| Field | Type |
|---|---|
| theme | `'light' \| 'dark' \| 'system'` |
| defaultReminderOffsets | number[] |
| dailyNotificationTime | `'HH:mm'` |
| expiringSoonWindowDays | number (default 7) |

## 4. Notification System — Technical Detail
- **Channel:** one Android channel, "Expiry Reminders," created on first launch, high importance so reminders aren't silently demoted
- **Scheduling:** on save/edit, create one Notifee trigger notification per active `reminderOffset`, using `TriggerType.TIMESTAMP` with `alarmManager: { allowWhileIdle: true }` so it still fires during Doze
- **Deterministic IDs:** notification id = `${itemId}:${offsetDays}` — editing an item cancels and re-creates *only that item's* notifications, so duplicates are structurally impossible rather than just "checked for"
- **Permissions:** request `POST_NOTIFICATIONS` (Android 13+) contextually during onboarding, not before the user has seen any value. For exact-alarm reliability on Android 12+, check `canScheduleExactAlarms()` and fall back to inexact scheduling with a one-line explanation in Settings if it's denied, rather than silently failing.
- **Battery optimization:** after the first successful item add, optionally prompt once (never nag) to exclude Dateora from battery optimization — aggressive OEM battery managers on budget Android phones are the single biggest real-world cause of "my reminder didn't fire" complaints
- **Reboot persistence:** verify in QA that scheduled triggers survive a device reboot on your target OEM/Android versions; as a safety net, re-register all future notifications from the DB on the first app-open after a boot

## 5. Offline & Data Portability
- No network permission at all in v1 — everything above works with it removed entirely
- Export produces one JSON file (items + settings), versioned with a `schemaVersion` field so future app versions can migrate older exports
- Import validates schema version and item shape *before* writing anything, and shows a diff-style summary ("12 items will be added, 2 already exist") before committing

## 6. Folder Structure

```
dateora/
  app/                      # Expo Router routes
    (tabs)/
      home.tsx
      items.tsx
      calendar.tsx
      history.tsx
      settings.tsx
    item/[id].tsx
    add-item.tsx
    onboarding.tsx
  src/
    components/             # ItemRow, StatusPill, EmptyState, etc.
    stores/                 # useItemsStore, useSettingsStore
    db/                     # Drizzle schema + client
    services/
      itemRepository.ts
      notificationService.ts
      exportService.ts
    types/
    theme/                  # colors, spacing, radius, typography tokens
  assets/
```

## 7. Extensibility (barcode / OCR / AI / cloud)
Add Item's name/category/photo fields are filled today from one `AddItemDraft` object built by manual input. Barcode scanning and OCR later just become two more ways to produce that same draft object (`fromBarcode()`, `fromOcr()`), handing off to the identical save path — no changes needed to the DB, notification, or Items-list code when those features arrive. Cloud sync later sits entirely inside the repository layer (swap the local-only implementation for one that also pushes to a backend) without the UI ever knowing the difference.

## 8. Play Store Technical Checklist
- `minSdkVersion` 24–26 (broad device reach); `compileSdk` / `targetSdk` **36 (Android 16)** — this is a hard requirement for all new app submissions as of **August 31, 2026**. Building on a current Expo SDK via EAS Build keeps this compliant for you automatically.
- No unused permissions declared — no `INTERNET` permission at all if v1 truly stays offline-only, which also doubles as a genuine trust signal in your store listing
- Signed release build via EAS Build, with versionCode auto-incremented per submission
