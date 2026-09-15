# Dateora — Product Requirements Document (PRD)

> Companion files: **Dateora_Architecture.md** (tech stack, data model, notification internals) and **Dateora_Rules.md** (conventions, QA checklist, launch checklist, and exactly what changed from your original prompt). Hand Antigravity all three together — see the last section of the Rules doc for a suggested phased build order instead of one giant prompt.

## 1. Vision

**One-liner:** Dateora is a premium, offline-first app that stops you from throwing away money — or worse, using expired medicine — by tracking every expiry date in your home (groceries, medicine, skincare, household goods, documents) and reminding you before it's too late.

**Problem:** Expiry dates live scattered across a fridge, a medicine cabinet, a bathroom shelf, and a drawer of documents. The cost isn't just wasted food — it's expired medicine taken by mistake, lapsed warranties, and spoiled skincare.

**Non-goals for v1:** no mandatory account/login, no ads, no social features, no server dependency for core functionality. Every core feature works in airplane mode.

## 2. Who it's for
- Someone managing a household pantry *and* medicine cabinet who wants one place to track both
- Someone tracking medication expiry for elderly parents
- Someone who buys skincare/cosmetics in bulk and loses track of which jar is oldest

## 3. Core Flow
Add item → set expiry → choose reminder → save → get notified. Unchanged from your original brief — it was already right. The required-fields path (name, category, expiry date) must complete in under 30 seconds; everything else sits behind an optional "Add more details" disclosure so the fast path never feels cluttered.

## 4. Screens

### 4.0 Onboarding (new — the original brief didn't cover this)
Two short, skippable screens:
1. What Dateora does + the "no login needed" promise.
2. Notification permission request, asked with context — *"Dateora reminds you before things expire — allow notifications?"* — rather than a bare OS prompt at cold start. If denied, the app stays fully usable; a small, non-blocking banner on Home offers to enable it later from Settings.

### 4.1 Home
- Time-of-day-aware greeting
- Three tappable stat chips: Total items / Expiring Soon / Expired — each jumps into Items pre-filtered
- "+ Add Item" as a floating action button, reachable with one thumb from anywhere on the screen
- "Expiring Soon" list: item name, category icon, exact date, status pill — sorted soonest-first
- Empty state (illustration + "Add your first item" CTA) only when the user has zero items app-wide

### 4.2 Add Item
**Required:** name, category (icon grid, including "Custom"), expiry date (quick chips: Today / Tomorrow / 7 days / 30 days / Custom picker)
**Optional**, collapsed under "Add more details": photo, quantity + unit, storage location, notes
**Reminder selector**, defaulting to "3 days before," editable per item: 7 days / 3 days / 1 day / on expiry day / none
**Validation:** expiry date can't be blank. A past date is still allowed (for logging something already expired) but is immediately flagged "already expired" so there's no confusion later.
Saving writes the item, schedules its notification(s), and returns to Home with a brief confirmation — no forced detour screen.

### 4.3 Items
- Search: matches item name, tolerant of small typos
- Filter chips: All / Expiring Soon / Expired / Safe, plus a category multi-select
- Sort: expiry date soonest-first (default) / recently added / name A–Z
- Row: name, category icon, expiry date, status pill
- Empty state text is specific to the active filter (e.g. "No expired items — nice!" reads very differently from "No items yet")

### 4.4 Item Details
- Photo (or category icon placeholder), name, category, exact expiry date, live countdown/status
- Reminder settings, editable inline
- Quantity, location, notes if present
- Actions: **Edit**, **Delete** (with confirmation), and **Mark as →** Used / Finished / Disposed — three distinct outcomes, not one combined button. (Your original only offered "Used/Finished" here while History expected four separate buckets — see the Rules doc for why this needed fixing.)

### 4.5 Calendar
- Month view; any day with items gets a small colored dot — red if it has an expired item, amber if expiring within the alert window, green if only safe items
- Tapping a day opens that day's items in a bottom sheet, reusing the Items row component

### 4.6 History
- Four filters: Used, Finished, Disposed, Expired
- Each entry snapshots the item as it was when it left the active list (name, category, date, photo), so history stays meaningful even later
- **Restore** action to bring an item back to active tracking — covers the realistic "marked it Used by mistake" case, which the original didn't account for

### 4.7 Settings
- Notifications: master toggle, default reminder offset, daily notification time, deep-link to OS notification settings when permission is off
- Appearance: Light / Dark / System
- Data: Export (JSON), Import (validated before merging, warns on conflicts), Delete all data (double confirmation)
- About: version number, Privacy Policy, feedback/contact

## 5. Status Thresholds
- **Expired** — expiry date is before today
- **Expiring Soon** — within the user's configured window (default 7 days)
- **Safe** — everything else
Status is never color-only — always paired with a text label (and an icon where space allows), so it holds up for colorblind users too.

## 6. Notification Copy
Kept from your original brief, since it was already right:
- 7 days before → *"[Item] expires in 7 days."*
- Tomorrow → *"[Item] expires tomorrow."*
- Today → *"[Item] expires today."*

One addition your version missed: an **already-expired catch-up notice** the first time the app is opened after something has silently expired with no reminder close enough to have caught it — otherwise an item can go stale with zero warning.

## 7. Design Direction
Palette kept as-is — it was already a well-chosen, trustworthy Apple/Linear-style set:
Primary blue `#2563EB` · cyan accent `#0EA5E9` · success `#22C55E` · warning `#F59E0B` · danger `#EF4444`

Specifics the original left open:
- **Type:** one geometric-humanist sans (Inter or Manrope), 3–4 weights max
- **Spacing:** consistent 8pt grid (8 / 16 / 24 / 32)
- **Radius:** one corner-radius scale (e.g. 12px cards, 8px chips/buttons) — never mixed
- **Motion:** exactly one micro-interaction — a subtle save confirmation — nothing else animates, in the spirit of the original's "avoid unnecessary animations"
- **Dark mode:** true parity, with contrast independently rechecked for both themes, not just inverted colors

## 8. Edge Cases (expanded from your original list)
- Empty states are written per-screen, not one reused generic string
- Retroactively adding an already-expired item is allowed and clearly labeled
- Timezone or device-clock changes — recompute status against the device's current time on every app foreground; never trust a cached "days left" number
- Permission denied — app stays fully usable; reminders are silently skipped with a visible, non-nagging banner
- Duplicate item names (e.g. two milk cartons) are allowed, disambiguated by added-date/photo
- Deleting an item cancels *every* notification tied to it, not just the "main" one
- Reinstall / data wipe — Import restores from the user's last export, so there's no unrecoverable data loss

## 9. Roadmap
- **v1 (MVP):** everything above
- **v1.1:** Home Screen widget showing the next 3 expiring items; a quick swipe-to-"Mark as Used" gesture in the Items list
- **v2:** barcode scanning to prefill name/category/photo; OCR expiry-date detection from a photo
- **v3:** an on-device or opt-in-cloud assistant (e.g. "you usually finish milk in 5 days — set that as your dairy default?"); optional encrypted cloud backup/sync
- **Optional, not required for MVP:** a Hindi (or other regional language) UI toggle, and Indian-household category presets (spices, ghee, pooja/festival items). Cheap to add once i18n scaffolding exists and a real differentiator for the Indian market — but shouldn't delay v1.

## 10. Success Criteria
- Median time to add an item (required fields only) under 30 seconds
- Zero duplicate or orphaned notifications after 50 add/edit/delete cycles in QA
- Every core flow — add, edit, delete, search, filter, calendar, history — works fully in airplane mode
