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
      <div class="nav-badge">
        <span>Verified Legal Document</span>
      </div>
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
      <h1>Dateora Smart Expiry Tracker</h1>
      <p style="font-size: 1.05rem; color: #475569; margin-bottom: 16px;">
        Official Privacy Policy and Data Protection Notice for users of Dateora.
      </p>
      <div class="doc-meta">
        <div><strong>Effective Date:</strong> October 24, 2026</div>
        <div><strong>Developer:</strong> Tushal Jadhav</div>
        <div><strong>Contact:</strong> tushaljadhav123@gmail.com</div>
        <div><strong>Package Name:</strong> com.dateora.dateora</div>
        <div><strong>Current Version:</strong> 1.0.0</div>
      </div>
    </header>

    <!-- Executive Summary Highlights -->
    <div class="summary-grid">
      <div class="summary-card">
        <div class="summary-icon">&#128274;</div>
        <div class="summary-title">On-Device Local Database</div>
        <div class="summary-desc">Currently, all your groceries, dates, photos, and quantities stay strictly on your phone in local SQLite storage.</div>
      </div>
      <div class="summary-card">
        <div class="summary-icon">&#128100;</div>
        <div class="summary-title">No Account Needed (v1.0)</div>
        <div class="summary-desc">Start tracking immediately without registration. Optional accounts will be introduced in future updates for cloud backup & subscriptions.</div>
      </div>
      <div class="summary-card">
        <div class="summary-icon">&#128737;</div>
        <div class="summary-title">Zero Data Brokering</div>
        <div class="summary-desc">We never sell, monetize, license, or broker your personal consumption habits to third parties or advertisers.</div>
      </div>
    </div>

    <!-- Section 1 -->
    <article class="section-card">
      <h2><span class="num">1</span> Overview & Architecture Philosophy</h2>
      <p>
        Dateora ("we", "our", or "the application") is a smart mobile utility designed to assist users in tracking household expiration dates, minimizing perishable waste, and organizing food, medicine, and personal care inventory.
      </p>
      <p>
        In the current release (v1.0), Dateora functions on an <strong>offline-first local architecture</strong>: your personal buying habits, medicine regimens, and dietary selections remain stored inside the private sandbox storage of your physical device.
      </p>

      <h3>1.1 Future Account Registration & Premium Subscription Services</h3>
      <p>
        Please note that the current no-account requirement is tailored for Dateora v1.0 local usage. As our user community grows and we introduce upcoming multi-device cloud synchronization, automated family sharing, and premium subscription tiers:
      </p>
      <ul>
        <li>Users will have the option to register a secure account (via email or OAuth sign-in) to authenticate and manage their subscriptions.</li>
        <li>Account and subscription transactions will be processed securely through Google Play Billing with industry-standard encryption.</li>
        <li>Users will always maintain full control to cancel subscriptions, export their inventory, or permanently delete their cloud account and all associated data at any time.</li>
      </ul>
    </article>

    <!-- Section 2 -->
    <article class="section-card">
      <h2><span class="num">2</span> Information Collected & Processing Purposes</h2>
      <p>
        To provide its core tracking and reminder services, Dateora processes specific data categories as detailed below:
      </p>

      <div class="table-container">
        <table>
          <thead>
            <tr>
              <th>Data Type</th>
              <th>Specific Elements</th>
              <th>Processing Purpose</th>
              <th>Retention & Storage</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td><strong>Inventory Data</strong></td>
              <td>Item name, category, expiration date, purchase date, quantity, storage location, user notes.</td>
              <td>To organize items, display countdown days, calculate waste savings, and trigger notifications.</td>
              <td><strong>Stored 100% locally</strong> in device SQLite database.</td>
            </tr>
            <tr>
              <td><strong>Images & Photos</strong></td>
              <td>Product front photographs, packaging expiry date stamps.</td>
              <td>To display thumbnail photos in item cards and allow AI date identification.</td>
              <td><strong>Local device sandbox storage only</strong>. Never published to any public gallery.</td>
            </tr>
            <tr>
              <td><strong>Barcode Data</strong></td>
              <td>EAN-13, EAN-8, UPC-A, Code 128 numerical product digits.</td>
              <td>To retrieve standardized public product names and categories.</td>
              <td><strong>Transient</strong>. Used only to pre-fill the name field upon scan.</td>
            </tr>
            <tr>
              <td><strong>Technical Diagnostics</strong></td>
              <td>Device model, Android version, crash logs, aggregate feature usage count.</td>
              <td>To monitor app stability and fix technical bugs.</td>
              <td><strong>Anonymous telemetry</strong> via Firebase Analytics (User can opt out anytime in Settings).</td>
            </tr>
          </tbody>
        </table>
      </div>

      <div class="callout">
        <p><strong>Photo Privacy Guarantee:</strong> Dateora does not index, scan, or access any images in your personal photo library except the specific files you deliberately photograph or select within the app.</p>
      </div>
    </article>

    <!-- Section 3 -->
    <article class="section-card">
      <h2><span class="num">3</span> Android Permissions & Justifications</h2>
      <p>
        Dateora adheres strictly to the Principle of Least Privilege. We request only runtime permissions strictly required to execute user-initiated actions:
      </p>
      <ul>
        <li>
          <strong>Camera (<code>android.permission.CAMERA</code>):</strong> Requested when you open the Barcode Scanner or tap the camera icon to photograph product packaging. It is never accessed in the background.
        </li>
        <li>
          <strong>Photo Library / Storage Access (<code>READ_MEDIA_IMAGES</code>):</strong> Requested only if you choose to attach an existing product photo from your device storage.
        </li>
        <li>
          <strong>Notifications (<code>POST_NOTIFICATIONS</code>) & Exact Alarms (<code>SCHEDULE_EXACT_ALARM</code>):</strong> Required to schedule local calendar notifications that warn you before items expire. Reminders are triggered by the local operating system clock without external push notification tracking.
        </li>
      </ul>
    </article>

    <!-- Section 4 -->
    <article class="section-card">
      <h2><span class="num">4</span> AI Vision Scanning & Data Protection</h2>
      <p>
        Dateora includes an optional <strong>AI Packaging Vision Auto-Fill</strong> feature powered by Google Gemini Vision.
      </p>
      <p>
        When you choose to tap "Scan Packaging with AI":
      </p>
      <ul>
        <li>Only the specific image of the product packaging and date stamp is transmitted via secure HTTPS (TLS 1.3) to the Google Gemini API.</li>
        <li>The image is processed transiently in volatile server memory solely to recognize product title and date characters.</li>
        <li>Google does not use images submitted via its API services to train foundational models.</li>
        <li>Once the extracted product name and date are returned to your phone, the session ends. No photos are permanently stored on remote servers.</li>
        <li><strong>Offline Choice:</strong> You are never required to use AI scanning. Manual entry and instant barcode scanning remain 100% accessible offline.</li>
      </ul>
    </article>

    <!-- Section 5 -->
    <article class="section-card">
      <h2><span class="num">5</span> Third-Party Service Providers</h2>
      <p>
        We integrate with selected third-party services that comply with global data protection standards (GDPR, CCPA):
      </p>
      <ul>
        <li>
          <strong>Google Play Services:</strong> Core application delivery, distribution, and in-app updates.
        </li>
        <li>
          <strong>Firebase Analytics & Crashlytics (Google LLC):</strong> Collects non-identifiable, aggregated crash diagnostics and feature event metrics. Users can completely disable analytics via <em>Settings &rarr; Privacy &rarr; Help Improve Dateora</em>.
        </li>
        <li>
          <strong>Open Food Facts:</strong> A non-profit public database queried anonymously with numerical barcode digits (e.g. 8901030383848) to auto-fill grocery names without user tracking.
        </li>
      </ul>
    </article>

    <!-- Section 6 -->
    <article class="section-card">
      <h2><span class="num">6</span> User Rights, Data Control & Deletion</h2>
      <p>
        Because all your data is stored on your local device, you possess total sovereignty:
      </p>
      <ul>
        <li><strong>Selective Deletion:</strong> You can edit, restore, or permanently delete any item from the inventory list or history screen at any moment.</li>
        <li><strong>1-Click Complete Wipe:</strong> Go to <em>Settings &rarr; Danger Zone &rarr; Clear All Data</em> to permanently and irrecoverably delete all items, categories, settings, and photos from your storage.</li>
        <li><strong>Uninstallation:</strong> Deleting the Dateora application via Android Settings automatically and immediately purges the entire SQLite database, photo cache, and all application files.</li>
      </ul>
    </article>

    <!-- Section 7 -->
    <article class="section-card">
      <h2><span class="num">7</span> Children's Privacy (COPPA & GDPR-K Compliance)</h2>
      <p>
        Dateora is a household utility application intended for general audiences. We do not knowingly solicit, collect, or store personal information from children under the age of 13 (or under 16 in the European Economic Area). If you become aware that a child has provided us with personal information, please contact us and we will promptly address the inquiry.
      </p>
    </article>

    <!-- Section 8 -->
    <article class="section-card">
      <h2><span class="num">8</span> Data Security Standards</h2>
      <p>
        We employ industry-standard security practices to safeguard data:
      </p>
      <ul>
        <li>Application sandbox isolation enforced by the Android Linux security architecture.</li>
        <li>Mandatory TLS 1.3 / HTTPS encryption for all external API network requests.</li>
        <li>Cleartext HTTP traffic is blocked via network security configuration (<code>usesCleartextTraffic="false"</code>).</li>
      </ul>
    </article>

    <!-- Section 9 -->
    <article class="section-card">
      <h2><span class="num">9</span> Changes to This Privacy Policy</h2>
      <p>
        We may update this Privacy Policy periodically to reflect enhancements in functionality or regulatory requirements. Any revisions will be published immediately on this URL with an updated "Effective Date". Continued use of Dateora following revisions constitutes your consent to the updated terms.
      </p>
    </article>

    <!-- Section 10 -->
    <article class="section-card">
      <h2><span class="num">10</span> Contact & Inquiries</h2>
      <p>
        If you have questions, feedback, or inquiries regarding this Privacy Policy or your data protection rights, please reach out to:
      </p>
      <div class="contact-card">
        <p><strong>Developer:</strong> Tushal Jadhav</p>
        <p><strong>Application:</strong> Dateora — Smart Expiry Tracker</p>
        <p><strong>Privacy & Support Email:</strong> <a href="mailto:tushaljadhav123@gmail.com">tushaljadhav123@gmail.com</a></p>
        <p><strong>Official Web Portal:</strong> <a href="https://dateora.onrender.com" target="_blank">https://dateora.onrender.com</a></p>
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
