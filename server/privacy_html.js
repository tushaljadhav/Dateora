// ─── Dateora Official Public Privacy Policy (Google Play Console Compliant) ───
// Professional, corporate, clean design matching Stripe / Apple / Linear standards.

function renderPrivacyPolicyHtml() {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Privacy Policy — Dateora Smart Expiry Tracker</title>
  <meta name="description" content="Official Privacy Policy for Dateora: Smart Expiry Tracker. Clear, transparent data practices and Google Play compliance.">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
  <style>
    :root {
      --bg: #f8fafc;
      --card-bg: #ffffff;
      --border: #e2e8f0;
      --border-subtle: #f1f5f9;
      --primary: #059669;
      --primary-dark: #047857;
      --primary-soft: #ecfdf5;
      --primary-border: #a7f3d0;
      --text-main: #0f172a;
      --text-body: #334155;
      --text-muted: #64748b;
      --text-light: #94a3b8;
      --shadow-sm: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
      --shadow-md: 0 4px 6px -1px rgba(0, 0, 0, 0.05), 0 2px 4px -2px rgba(0, 0, 0, 0.05);
      --shadow-lg: 0 10px 15px -3px rgba(0, 0, 0, 0.04), 0 4px 6px -4px rgba(0, 0, 0, 0.02);
    }

    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
    }

    body {
      font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
      background-color: var(--bg);
      color: var(--text-body);
      line-height: 1.7;
      padding-bottom: 80px;
      -webkit-font-smoothing: antialiased;
    }

    /* Top Navigation Bar */
    .top-nav {
      background: #ffffff;
      border-bottom: 1px solid var(--border);
      position: sticky;
      top: 0;
      z-index: 50;
      backdrop-filter: blur(8px);
    }

    .nav-container {
      max-width: 900px;
      margin: 0 auto;
      padding: 16px 24px;
      display: flex;
      align-items: center;
      justify-content: space-between;
    }

    .nav-brand {
      display: flex;
      align-items: center;
      gap: 10px;
      font-weight: 700;
      font-size: 1.15rem;
      color: var(--text-main);
      text-decoration: none;
    }

    .nav-logo-svg {
      width: 32px;
      height: 32px;
      border-radius: 8px;
      flex-shrink: 0;
    }

    .nav-badge {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      background: #f1f5f9;
      color: #475569;
      padding: 4px 12px;
      border-radius: 20px;
      font-size: 0.8rem;
      font-weight: 600;
      border: 1px solid #e2e8f0;
    }

    /* Main Container */
    .main-wrap {
      max-width: 900px;
      margin: 36px auto 0;
      padding: 0 24px;
    }

    /* Header Section */
    .doc-header {
      background: var(--card-bg);
      border: 1px solid var(--border);
      border-radius: 16px;
      padding: 40px;
      margin-bottom: 24px;
      box-shadow: var(--shadow-sm);
    }

    .doc-header-top {
      display: flex;
      align-items: center;
      gap: 16px;
      margin-bottom: 18px;
    }

    .doc-header-logo {
      width: 52px;
      height: 52px;
      border-radius: 14px;
      box-shadow: var(--shadow-md);
      flex-shrink: 0;
    }

    .doc-header .tag {
      display: inline-block;
      background: var(--primary-soft);
      color: var(--primary);
      border: 1px solid var(--primary-border);
      padding: 4px 12px;
      border-radius: 6px;
      font-size: 0.82rem;
      font-weight: 700;
      letter-spacing: 0.02em;
    }

    h1 {
      font-size: 2.25rem;
      font-weight: 800;
      color: var(--text-main);
      letter-spacing: -0.03em;
      line-height: 1.25;
      margin-bottom: 14px;
    }

    .doc-meta {
      display: flex;
      flex-wrap: wrap;
      gap: 20px;
      color: var(--text-muted);
      font-size: 0.9rem;
      padding-top: 14px;
      border-top: 1px solid var(--border-subtle);
    }

    .doc-meta strong {
      color: var(--text-main);
    }

    /* Key Guarantees Grid */
    .summary-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
      gap: 16px;
      margin-bottom: 32px;
    }

    .summary-card {
      background: var(--card-bg);
      border: 1px solid var(--border);
      border-radius: 12px;
      padding: 22px;
      box-shadow: var(--shadow-sm);
    }

    .summary-icon {
      width: 40px;
      height: 40px;
      border-radius: 10px;
      background: var(--primary-soft);
      color: var(--primary);
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 1.25rem;
      margin-bottom: 14px;
    }

    .summary-title {
      font-size: 1rem;
      font-weight: 700;
      color: var(--text-main);
      margin-bottom: 6px;
    }

    .summary-desc {
      font-size: 0.88rem;
      color: var(--text-muted);
      line-height: 1.55;
    }

    /* Content Cards */
    .section-card {
      background: var(--card-bg);
      border: 1px solid var(--border);
      border-radius: 16px;
      padding: 36px 40px;
      margin-bottom: 20px;
      box-shadow: var(--shadow-sm);
    }

    h2 {
      font-size: 1.28rem;
      font-weight: 700;
      color: var(--text-main);
      letter-spacing: -0.02em;
      margin-bottom: 16px;
      display: flex;
      align-items: center;
      gap: 10px;
    }

    h2 .num {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      width: 26px;
      height: 26px;
      background: #f1f5f9;
      color: var(--primary-dark);
      border: 1px solid #cbd5e1;
      border-radius: 6px;
      font-size: 0.8rem;
      font-weight: 700;
    }

    h3 {
      font-size: 1.05rem;
      font-weight: 700;
      color: var(--text-main);
      margin: 20px 0 10px;
    }

    p {
      color: var(--text-body);
      font-size: 0.95rem;
      margin-bottom: 16px;
      line-height: 1.7;
    }

    p:last-child {
      margin-bottom: 0;
    }

    strong {
      color: var(--text-main);
      font-weight: 600;
    }

    ul {
      margin: 12px 0 18px 24px;
      color: var(--text-body);
      font-size: 0.94rem;
    }

    li {
      margin-bottom: 10px;
      line-height: 1.6;
    }

    /* Tables */
    .table-container {
      overflow-x: auto;
      margin: 20px 0;
      border: 1px solid var(--border);
      border-radius: 10px;
    }

    table {
      width: 100%;
      border-collapse: collapse;
      font-size: 0.9rem;
      text-align: left;
    }

    th {
      background: #f8fafc;
      color: var(--text-main);
      font-weight: 700;
      padding: 12px 16px;
      border-bottom: 1px solid var(--border);
    }

    td {
      padding: 14px 16px;
      border-bottom: 1px solid var(--border);
      vertical-align: top;
      color: var(--text-body);
    }

    tr:last-child td {
      border-bottom: none;
    }

    .badge-label {
      display: inline-block;
      background: #f1f5f9;
      color: #475569;
      padding: 2px 8px;
      border-radius: 4px;
      font-size: 0.78rem;
      font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
      margin-top: 4px;
    }

    /* Callout Note */
    .callout {
      background: #f0fdf4;
      border-left: 4px solid var(--primary);
      padding: 18px 20px;
      border-radius: 0 10px 10px 0;
      margin: 22px 0;
    }

    .callout p {
      color: #166534;
      font-size: 0.92rem;
      margin: 0;
      line-height: 1.6;
    }

    /* Contact Details Box */
    .contact-card {
      background: #f8fafc;
      border: 1px solid var(--border);
      border-radius: 12px;
      padding: 24px;
      margin-top: 18px;
    }

    .contact-card p {
      margin-bottom: 8px;
      font-size: 0.92rem;
    }

    .contact-card a {
      color: var(--primary);
      font-weight: 600;
      text-decoration: none;
    }

    .contact-card a:hover {
      text-decoration: underline;
    }

    /* Footer */
    footer {
      max-width: 900px;
      margin: 40px auto 0;
      padding: 24px 24px 0;
      border-top: 1px solid var(--border);
      text-align: center;
      color: var(--text-muted);
      font-size: 0.88rem;
    }

    @media (max-width: 640px) {
      .doc-header, .section-card {
        padding: 24px 20px;
      }
      h1 {
        font-size: 1.75rem;
      }
    }
  </style>
</head>
<body>

  <!-- Top Navigation with Official App Logo -->
  <nav class="top-nav">
    <div class="nav-container">
      <a href="/" class="nav-brand">
        <svg class="nav-logo-svg" width="32" height="32" viewBox="0 0 1024 1024" fill="none" xmlns="http://www.w3.org/2000/svg">
          <defs>
            <linearGradient id="dateoraNavBg" x1="100" y1="100" x2="924" y2="924" gradientUnits="userSpaceOnUse">
              <stop offset="0%" stop-color="#3566FF"/>
              <stop offset="45%" stop-color="#4A65FF"/>
              <stop offset="100%" stop-color="#7E54FF"/>
            </linearGradient>
          </defs>
          <rect width="1024" height="1024" rx="230" fill="url(#dateoraNavBg)"/>
          <path d="M 689 603 A 220 220 0 1 1 653 399" stroke="#FFFFFF" stroke-width="58" stroke-linecap="round"/>
          <path d="M 428 506 L 500 578 L 652 426" stroke="#FFFFFF" stroke-width="72" stroke-linecap="round" stroke-linejoin="round"/>
          <circle cx="722" cy="286" r="64" fill="#FF5858"/>
        </svg>
        <span>Dateora</span>
      </a>
    </div>
  </nav>

  <main class="main-wrap">

    <!-- Document Header with Official Icon -->
    <header class="doc-header">
      <div class="doc-header-top">
        <svg class="doc-header-logo" width="52" height="52" viewBox="0 0 1024 1024" fill="none" xmlns="http://www.w3.org/2000/svg">
          <defs>
            <linearGradient id="dateoraHeadBg" x1="100" y1="100" x2="924" y2="924" gradientUnits="userSpaceOnUse">
              <stop offset="0%" stop-color="#3566FF"/>
              <stop offset="45%" stop-color="#4A65FF"/>
              <stop offset="100%" stop-color="#7E54FF"/>
            </linearGradient>
          </defs>
          <rect width="1024" height="1024" rx="230" fill="url(#dateoraHeadBg)"/>
          <path d="M 689 603 A 220 220 0 1 1 653 399" stroke="#FFFFFF" stroke-width="58" stroke-linecap="round"/>
          <path d="M 428 506 L 500 578 L 652 426" stroke="#FFFFFF" stroke-width="72" stroke-linecap="round" stroke-linejoin="round"/>
          <circle cx="722" cy="286" r="64" fill="#FF5858"/>
        </svg>
        <div>
          <div class="tag">Privacy Policy</div>
        </div>
      </div>
      <h1>Dateora: Smart Expiry Tracker</h1>
      <p style="font-size: 1.05rem; color: #475569; margin-bottom: 16px;">
        Privacy Policy & Data Notice for Dateora mobile application.
      </p>
      <div class="doc-meta">
        <div><strong>Effective Date:</strong> October 25, 2026</div>
        <div><strong>Developer:</strong> Tushal Jadhav</div>
        <div><strong>Contact:</strong> tushaljadhav123@gmail.com</div>
        <div><strong>Package Name:</strong> com.dateora.dateora</div>
        <div><strong>Version:</strong> 1.0.0</div>
      </div>
    </header>

    <!-- Summary Highlights -->
    <div class="summary-grid">
      <div class="summary-card">
        <div class="summary-icon">&#128274;</div>
        <div class="summary-title">On-Device Inventory</div>
        <div class="summary-desc">Your inventory (item names, dates, quantities, notes, photos) is stored on your phone, not on our servers.</div>
      </div>
      <div class="summary-card">
        <div class="summary-icon">&#128100;</div>
        <div class="summary-title">No Account Needed</div>
        <div class="summary-desc">No account, login, email or phone number is needed to track your groceries, medicines, and household items.</div>
      </div>
      <div class="summary-card">
        <div class="summary-icon">&#128737;</div>
        <div class="summary-title">Zero Ads & No Data Selling</div>
        <div class="summary-desc">We do not sell your data, we show no advertisements, and we do not use advertising identifiers.</div>
      </div>
    </div>

    <!-- Section 1 -->
    <article class="section-card">
      <h2><span class="num">1</span> Overview</h2>
      <p>
        Dateora is a mobile app that helps you track expiry dates of food, medicine and personal care items, and reminds you before they expire. It is built offline-first: your inventory is saved in a local database inside the app's private storage on your device.
      </p>
    </article>

    <!-- Section 2 -->
    <article class="section-card">
      <h2><span class="num">2</span> Information We Handle</h2>
      <div class="table-container">
        <table>
          <thead>
            <tr>
              <th>Data</th>
              <th>What it includes</th>
              <th>Why</th>
              <th>Where it goes</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td><strong>Inventory data</strong></td>
              <td>Item name, category, expiry date, quantity, location, notes, price (optional), reminder settings</td>
              <td>To show your items and send reminders</td>
              <td>Stored only on your device (local SQLite database)</td>
            </tr>
            <tr>
              <td><strong>Photos</strong></td>
              <td>Product photos you take or choose</td>
              <td>To show on item cards and (optionally) for AI scan</td>
              <td>Saved in the app's private storage on your device. Not saved to your public gallery</td>
            </tr>
            <tr>
              <td><strong>AI scan images</strong></td>
              <td>1-2 compressed photos of product packaging, only when you tap "Scan with AI"</td>
              <td>To read product name, category and expiry date</td>
              <td>Sent over HTTPS to our server (hosted on Render), then to Google Gemini. See Section 4</td>
            </tr>
            <tr>
              <td><strong>Barcode number</strong></td>
              <td>Digits of the barcode you scan</td>
              <td>To fetch the product name</td>
              <td>Sent to Open Food Facts. If not found there, sent to our server and Google Gemini. See Section 5</td>
            </tr>
            <tr>
              <td><strong>Random install ID</strong></td>
              <td>A random ID generated on first launch (not your Android ID or Advertising ID)</td>
              <td>To limit AI scans per day (fair-use limit)</td>
              <td>Stored on your device and sent to our server with AI scan and barcode requests</td>
            </tr>
            <tr>
              <td><strong>Crash and usage data</strong></td>
              <td>Crash reports, device model, Android version, app events (for example "item added", "AI scan used"), app instance ID</td>
              <td>To find bugs and improve the app</td>
              <td>Sent to Google Firebase (Analytics and Crashlytics). You can turn this off. See Section 6</td>
            </tr>
          </tbody>
        </table>
      </div>
      <p style="margin-top: 16px;">
        We do <strong>not</strong> collect your name, email, phone number, address, location, contacts, or financial information.
      </p>
    </article>

    <!-- Section 3 -->
    <article class="section-card">
      <h2><span class="num">3</span> Android Permissions</h2>
      <ul>
        <li><strong>Camera:</strong> used only when you open the barcode scanner or take a product photo. Never used in the background.</li>
        <li><strong>Notifications:</strong> used to show expiry reminders. Reminders are scheduled locally on your phone.</li>
        <li><strong>Photos:</strong> when you attach an existing photo, Dateora uses Android's system photo picker. It does not scan or browse your gallery.</li>
        <li><strong>Internet:</strong> needed for AI scan, barcode lookup and crash/usage reports.</li>
        <li><strong>Run at startup:</strong> used to re-schedule your reminders after the phone restarts.</li>
        <li><strong>Vibration:</strong> used for notification alerts.</li>
      </ul>
    </article>

    <!-- Section 4 -->
    <article class="section-card">
      <h2><span class="num">4</span> AI Packaging Scan (Google Gemini)</h2>
      <p>This feature is optional. When you tap "Scan with AI":</p>
      <ol style="padding-left: 20px; line-height: 1.6; color: var(--text-body); margin-bottom: 16px;">
        <li>The packaging image(s) are sent over HTTPS to the Dateora server, which forwards them to the Google Gemini API.</li>
        <li>Our server does not store the images or results. They are held in memory only while the request is processed.</li>
        <li>Google processes the images under its own Gemini API terms: <a href="https://ai.google.dev/gemini-api/terms" target="_blank">https://ai.google.dev/gemini-api/terms</a>.</li>
        <li>The server uses your random install ID (and IP address, in memory) only to apply daily usage limits.</li>
        <li>The extracted name, category and date are saved on your device.</li>
      </ol>
      <p>
        If you add your own Gemini API key in Settings, the app sends the images directly to Google using your key. The key is stored on your device in encrypted storage (Android Keystore).
      </p>
      <p>
        Manual entry and barcode scanning always work without AI scan.
      </p>
    </article>

    <!-- Section 5 -->
    <article class="section-card">
      <h2><span class="num">5</span> Barcode Lookup</h2>
      <p>
        When you scan a barcode, the app sends the barcode digits to <a href="https://world.openfoodfacts.org" target="_blank">Open Food Facts</a>, a public non-profit database. Like any website, Open Food Facts can see your IP address. If the product is not found, the barcode digits are sent to the Dateora server, which asks Google Gemini to suggest a product name and category.
      </p>
    </article>

    <!-- Section 6 -->
    <article class="section-card">
      <h2><span class="num">6</span> Analytics and Crash Reports (Firebase)</h2>
      <p>
        Dateora uses <strong>Google Firebase Analytics</strong> and <strong>Firebase Crashlytics</strong> to understand crashes and basic feature usage. These services use an app instance ID and collect device model, Android version, crash logs and app events. We do not send item names, notes or photos to Firebase.
      </p>
      <div class="callout">
        <p>This is turned <strong>on by default</strong>. You can turn it off any time: <strong>Settings &rarr; Privacy &rarr; Help improve Dateora.</strong></p>
      </div>
      <ul>
        <li>Google Privacy Policy: <a href="https://policies.google.com/privacy" target="_blank">https://policies.google.com/privacy</a></li>
        <li>Firebase Privacy Information: <a href="https://firebase.google.com/support/privacy" target="_blank">https://firebase.google.com/support/privacy</a></li>
      </ul>
    </article>

    <!-- Section 7 -->
    <article class="section-card">
      <h2><span class="num">7</span> Other Services</h2>
      <ul>
        <li><strong>Google Play:</strong> used to download and update the app.</li>
        <li><strong>Render:</strong> hosts our server for AI scan and barcode fallback. It may process requests and technical logs such as IP addresses as part of hosting.</li>
      </ul>
      <p style="margin-top: 12px;">
        We do not sell your data, share it for advertising, or use advertising IDs.
      </p>
    </article>

    <!-- Section 8 -->
    <article class="section-card">
      <h2><span class="num">8</span> Your Choices and Deleting Data</h2>
      <ul>
        <li><strong>Edit or delete items:</strong> any time from the item list or history.</li>
        <li><strong>Delete all data:</strong> Settings &rarr; Danger Zone &rarr; Delete All Data removes all items, reminders, saved photos and settings from your device.</li>
        <li><strong>Uninstalling:</strong> the app removes its local data from your device.</li>
        <li><strong>Backup/export:</strong> you can export a JSON backup and import it later. Photos are not included in the export. Exported files are yours; keep them safe.</li>
        <li><strong>Turn off analytics and crash reports:</strong> in Settings (Section 6).</li>
        <li><strong>AI scan:</strong> you can choose not to use it.</li>
        <li><strong>Questions or requests about data held by us:</strong> (for example server requests) email <a href="mailto:tushaljadhav123@gmail.com">tushaljadhav123@gmail.com</a>.</li>
      </ul>
    </article>

    <!-- Section 9 -->
    <article class="section-card">
      <h2><span class="num">9</span> Security</h2>
      <ul>
        <li>Data is stored in the app's private sandbox on your device.</li>
        <li>All network requests use HTTPS (encrypted in transit).</li>
        <li>No method of storage or transfer is 100% secure, so we cannot guarantee absolute security.</li>
      </ul>
    </article>

    <!-- Section 10 -->
    <article class="section-card">
      <h2><span class="num">10</span> Children's Privacy</h2>
      <p>
        Dateora is for general audiences and is not directed at children under 13. We do not knowingly collect personal information from children. If you believe a child has provided information, contact us and we will help.
      </p>
    </article>

    <!-- Section 11 -->
    <article class="section-card">
      <h2><span class="num">11</span> Changes to This Policy</h2>
      <p>
        We may update this policy. The new version will be posted at this URL with a new Effective Date. Please review it from time to time.
      </p>
    </article>

    <!-- Section 12 -->
    <article class="section-card">
      <h2><span class="num">12</span> Contact</h2>
      <div class="contact-card">
        <p><strong>Developer:</strong> Tushal Jadhav</p>
        <p><strong>Email:</strong> <a href="mailto:tushaljadhav123@gmail.com">tushaljadhav123@gmail.com</a></p>
        <p><strong>Website:</strong> <a href="https://dateora.onrender.com" target="_blank">https://dateora.onrender.com</a></p>
      </div>
    </article>

  </main>

  <footer>
    <p>&copy; 2026 Dateora. All rights reserved. Designed with privacy-first offline architecture.</p>
  </footer>

</body>
</html>`;
}

module.exports = { renderPrivacyPolicyHtml };
