# Google Play Store Assets for Dateora

All graphics in this folder are pre-sized according to official Google Play Store specifications.

## 📦 Files in this Folder

| File Name | Exact Dimensions | Google Play Requirement |
|---|---|---|
| `app_icon_512x512.png` | **512 x 512 px** | App Icon (PNG with alpha) |
| `feature_graphic_1024x500.png` | **1024 x 500 px** | Feature Graphic banner (PNG/JPG) |
| `1_dashboard_1080x1920.png` | **1080 x 1920 px (9:16)** | Phone Screenshot 1: Expiry Tracking Dashboard |
| `2_ai_scanner_1080x1920.png` | **1080 x 1920 px (9:16)** | Phone Screenshot 2: AI Packaging Scanner |
| `3_notifications_1080x1920.png` | **1080 x 1920 px (9:16)** | Phone Screenshot 3: Timely Expiry Reminders |

---

## 🚀 How to Upload on Google Play Console

### 1. Upload Graphics & Screenshots:
1. Open [Google Play Console](https://play.google.com/console).
2. Go to **Store presence** &rarr; **Main store listing**.
3. **App Icon:** Upload `app_icon_512x512.png`.
4. **Feature Graphic:** Upload `feature_graphic_1024x500.png`.
5. **Phone Screenshots:** Upload `1_dashboard_1080x1920.png`, `2_ai_scanner_1080x1920.png`, and `3_notifications_1080x1920.png`.
6. Click **Save**.

### 2. Set Privacy Policy:
1. Go to **Policy and programs** &rarr; **App content** &rarr; **Privacy policy**.
2. Enter URL: `https://dateora.onrender.com/privacy`
3. Click **Save**.

### 3. Upload App Bundle (AAB):
1. Go to **Release** &rarr; **Production** (or **Closed testing / Internal testing**).
2. Click **Create new release**.
3. Under App bundles, upload: **`Dateora.aab`** (located at the root of your project folder `C:\Users\Tushal\Desktop\Dateora\Dateora.aab`).
4. Enter release notes and click **Review release** &rarr; **Start rollout**.
