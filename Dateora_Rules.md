# Dateora — Rules & Conventions

> Read alongside **Dateora_PRD.md** and **Dateora_Architecture.md**.

## 1. Non-Negotiables (kept from your original brief — these instincts were right)
- No excessive gradients, no huge cards, no more than the five brand colors, no unnecessary animation, no clutter
- One icon family (lucide-react-native), one type family, one spacing scale, one radius scale — pick once, apply everywhere, never introduce a second value "just this once"
- No mandatory login/signup, ever, for core functionality
- No placeholder content, no dead buttons — if it's visible, it works

## 2. Code Conventions
- TypeScript strict mode; no `any` in the repository/service layer
- UI components are presentational only — no direct DB or Notifee calls from a screen or component; always go through `services/`
- Every mutation to an item (add / edit / delete / mark-as) goes through a single `itemRepository` function that also owns rescheduling that item's notifications — so "forgot to update the reminder when the item changed" becomes structurally impossible, not just a thing to remember
- Dates are stored and compared in UTC internally; displayed in device-local time

## 3. Notification Rules
- Never schedule a notification without first canceling any existing notification with the same deterministic id
- Only `itemRepository` may call `notificationService` — no other code path schedules notifications for an item
- Always re-verify `expiryDate` against "now" on app foreground before trusting a cached status label

## 4. QA Checklist Before Calling This "Done"
- [ ] Add → Edit → Delete cycle across 20+ items — zero duplicate or orphaned notifications afterward
- [ ] Kill the app, reboot the device, confirm pending reminders still fire
- [ ] Deny notification permission at onboarding — app stays fully usable, banner offers re-enable later
- [ ] Airplane mode on for an entire session — every PRD feature still works
- [ ] Add items expiring today, tomorrow, in 7/30 days, and in the past — status and copy are all correct
- [ ] Light and dark mode both pass a contrast check on every status color
- [ ] Export, wipe app data, Import — data returns intact
- [ ] Search with typos, empty results, and special characters in item names
- [ ] Rotate/resize if tablets are in scope — no clipped layouts

## 5. Play Store Launch Checklist
- App icon + adaptive icon, feature graphic, at least 4 screenshots per theme (light + dark)
- Privacy policy: since v1 stores everything on-device with no account and no network permission, the honest policy is short — state plainly that no data leaves the device. That's a genuine selling point, not just legal boilerplate.
- Permissions listed in the store listing match exactly what's declared in the manifest (should just be notifications in v1)
- Target API level 36 (Android 16) — required for all new submissions since August 31, 2026
- Test the actual signed release build end-to-end, not just a dev build, before submitting

## 6. What Changed From Your Original Prompt
Your original brief was already well thought through — the screen list, the notification copy, and the "avoid" list were all solid instincts. Here's what this pass adds or fixes:

- **Named an actual tech stack.** The original never specified one — the single biggest gap for handing a prompt to an AI IDE.
- **Fixed a real inconsistency.** Item Details only offered one combined "Mark as Used/Finished" action, but History expected four separate buckets (Used/Finished/Disposed/Expired). Item Details now offers all three real outcomes.
- **Made "no duplicate notifications" actually achievable.** The original said to avoid duplicates but not how. This version gives deterministic notification IDs, exact-alarm + Doze handling, battery-optimization guidance, and reboot-persistence steps.
- **Added onboarding and a contextual permission request.** The original jumped straight to Home with no mention of when or how notification permission gets asked.
- **Added a real data model, folder structure, and extensibility plan** for barcode/OCR/AI/cloud instead of just naming them as future features.
- **Added accessibility notes** (status is never color-only), an export/import file format, and concrete QA + Play Store checklists.
- **Split one flat prompt into PRD / Architecture / Rules** — the same documentation structure you already use for AI-IDE handoffs, so Antigravity gets cleaner, separated context instead of one wall of text.

## 7. Suggested Build Order for Antigravity
Feeding all of this in one giant prompt tends to produce an app that's 70% right everywhere rather than 100% right anywhere. Suggested phases, each its own prompt/session:

1. **Scaffold:** Expo Router navigation shell (empty tab screens), theme tokens, Drizzle schema + DB client
2. **Core loop:** Add Item + Items list + Home, no notifications yet — get CRUD solid first
3. **Notifications end-to-end:** Notifee, permissions, deterministic scheduling — test this phase harder than any other
4. **Calendar + History + Mark-as flows**
5. **Settings, Export/Import, onboarding, empty states, dark-mode pass**
6. **QA checklist + Play Store packaging**

Keep all three files in the project root (or wherever Antigravity reads persistent context from) so every phase can reference the same PRD/Architecture/Rules without re-pasting them each time.
