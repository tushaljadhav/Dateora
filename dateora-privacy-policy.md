# Privacy Policy: Dateora Smart Expiry Tracker

**Effective Date:** October 25, 2026
**Developer:** Tushal Jadhav
**App:** Dateora: Smart Expiry Tracker (package: com.dateora.dateora)
**Version:** 1.0.0
**Contact:** tushaljadhav123@gmail.com

---

## Summary

- Your inventory (item names, dates, quantities, notes, photos) is stored **on your phone**, not on our servers.
- No account, login, email or phone number is needed.
- We do not sell your data and we show no ads.
- Some features use internet services (AI scan, barcode lookup, crash and usage reports). These are explained below.

## 1. Overview

Dateora is a mobile app that helps you track expiry dates of food, medicine and personal care items, and reminds you before they expire. It is built offline-first: your inventory is saved in a local database inside the app's private storage on your device.

## 2. Information We Handle

| Data | What it includes | Why | Where it goes |
|---|---|---|---|
| Inventory data | Item name, category, expiry date, quantity, location, notes, price (optional), reminder settings | To show your items and send reminders | Stored only on your device (local SQLite database) |
| Photos | Product photos you take or choose | To show on item cards and (optionally) for AI scan | Saved in the app's private storage on your device. Not saved to your public gallery |
| AI scan images | 1-2 compressed photos of product packaging, only when you tap "Scan with AI" | To read product name, category and expiry date | Sent over HTTPS to our server (hosted on Render), then to Google Gemini. See Section 4 |
| Barcode number | Digits of the barcode you scan | To fetch the product name | Sent to Open Food Facts. If not found there, sent to our server and Google Gemini. See Section 5 |
| Random install ID | A random ID generated on first launch (not your Android ID or Advertising ID) | To limit AI scans per day (fair-use limit) | Stored on your device and sent to our server with AI scan and barcode requests |
| Crash and usage data | Crash reports, device model, Android version, app events (for example "item added", "AI scan used"), app instance ID | To find bugs and improve the app | Sent to Google Firebase (Analytics and Crashlytics). You can turn this off. See Section 6 |

We do **not** collect your name, email, phone number, address, location, contacts, or financial information.

## 3. Android Permissions

- **Camera:** used only when you open the barcode scanner or take a product photo. Never used in the background.
- **Notifications:** used to show expiry reminders. Reminders are scheduled locally on your phone.
- **Photos:** when you attach an existing photo, Dateora uses Android's system photo picker. It does not scan or browse your gallery.
- **Internet:** needed for AI scan, barcode lookup and crash/usage reports.
- **Run at startup:** used to re-schedule your reminders after the phone restarts.
- **Vibration:** used for notification alerts.

## 4. AI Packaging Scan (Google Gemini)

This feature is optional. When you tap "Scan with AI":

1. The packaging image(s) are sent over HTTPS to the Dateora server, which forwards them to the Google Gemini API.
2. Our server does not store the images or results. They are held in memory only while the request is processed.
3. Google processes the images under its own Gemini API terms: https://ai.google.dev/gemini-api/terms
4. The server uses your random install ID (and IP address, in memory) only to apply daily usage limits.
5. The extracted name, category and date are saved on your device.

If you add your own Gemini API key in Settings, the app sends the images directly to Google using your key. The key is stored on your device in encrypted storage (Android Keystore).

Manual entry and barcode scanning always work without AI scan.

## 5. Barcode Lookup

When you scan a barcode, the app sends the barcode digits to **Open Food Facts** (https://world.openfoodfacts.org), a public non-profit database. Like any website, Open Food Facts can see your IP address. If the product is not found, the barcode digits are sent to the Dateora server, which asks Google Gemini to suggest a product name and category.

## 6. Analytics and Crash Reports (Firebase)

Dateora uses **Google Firebase Analytics** and **Firebase Crashlytics** to understand crashes and basic feature usage. These services use an app instance ID and collect device model, Android version, crash logs and app events. We do not send item names, notes or photos to Firebase.

This is turned **on by default**. You can turn it off any time: **Settings → Privacy → Help improve Dateora.**

Google's policy: https://policies.google.com/privacy
Firebase privacy information: https://firebase.google.com/support/privacy

## 7. Other Services

- **Google Play:** used to download and update the app.
- **Render:** hosts our server for AI scan and barcode fallback. It may process requests and technical logs such as IP addresses as part of hosting.

We do not sell your data, share it for advertising, or use advertising IDs.

## 8. Your Choices and Deleting Data

- **Edit or delete items** any time from the item list or history.
- **Delete all data:** Settings → Danger Zone → Delete All Data removes all items, reminders, saved photos and settings from your device.
- **Uninstalling** the app removes its local data from your device.
- **Backup/export:** you can export a JSON backup and import it later. Photos are not included in the export. Exported files are yours; keep them safe.
- **Turn off analytics and crash reports** in Settings (Section 6).
- **AI scan:** you can choose not to use it.
- **Questions or requests about data held by us** (for example server requests): email tushaljadhav123@gmail.com.

## 9. Security

- Data is stored in the app's private sandbox on your device.
- All network requests use HTTPS (encrypted in transit).
- No method of storage or transfer is 100% secure, so we cannot guarantee absolute security.

## 10. Children's Privacy

Dateora is for general audiences and is not directed at children under 13. We do not knowingly collect personal information from children. If you believe a child has provided information, contact us and we will help.

## 11. Changes to This Policy

We may update this policy. The new version will be posted at this URL with a new Effective Date. Please review it from time to time.

## 12. Contact

**Developer:** Tushal Jadhav
**Email:** tushaljadhav123@gmail.com
**Website:** https://dateora.onrender.com
