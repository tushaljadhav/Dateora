// ─── Dateora Official Public Privacy Policy (Google Play Console Compliant) ───
// Fully satisfies Google Play Developer Policy Center: User Data, Permissions, Third-Party SDKs, and Data Deletion.

function renderPrivacyPolicyHtml() {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Privacy Policy — Dateora Smart Expiry Tracker</title>
  <meta name="description" content="Official Privacy Policy for Dateora: Smart Expiry Tracker. Learn how your data, camera permissions, and privacy are protected.">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">
  <style>
    :root {
      --bg: #090e17;
      --surface: #111a2e;
      --surface-card: #15223c;
      --border: rgba(255, 255, 255, 0.08);
      --border-accent: rgba(16, 185, 129, 0.25);
      --primary: #10b981;
      --primary-light: #34d399;
      --primary-glow: rgba(16, 185, 129, 0.15);
      --text: #f8fafc;
      --text-muted: #94a3b8;
      --text-dim: #64748b;
      --badge-bg: rgba(16, 185, 129, 0.12);
    }
    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
    }
    body {
      font-family: 'Plus Jakarta Sans', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background-color: var(--bg);
      color: var(--text);
      line-height: 1.7;
      padding: 0 16px 80px;
      -webkit-font-smoothing: antialiased;
    }
    .container {
      max-width: 860px;
      margin: 0 auto;
    }
    header {
      padding: 48px 0 32px;
      text-align: center;
      border-bottom: 1px solid var(--border);
      margin-bottom: 40px;
    }
    .brand-pill {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      background: var(--badge-bg);
      color: var(--primary-light);
      border: 1px solid var(--border-accent);
      padding: 6px 16px;
      border-radius: 9999px;
      font-size: 0.85rem;
      font-weight: 700;
      letter-spacing: 0.03em;
      margin-bottom: 16px;
    }
    .brand-pill span {
      width: 8px;
      height: 8px;
      border-radius: 50%;
      background: var(--primary);
      display: inline-block;
      box-shadow: 0 0 8px var(--primary);
    }
    h1 {
      font-size: 2.4rem;
      font-weight: 800;
      letter-spacing: -0.02em;
      margin-bottom: 12px;
      background: linear-gradient(135deg, #ffffff 40%, var(--primary-light) 100%);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
    }
    .meta {
      color: var(--text-muted);
      font-size: 0.92rem;
    }
    .highlights-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
      gap: 16px;
      margin-bottom: 40px;
    }
    .highlight-card {
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: 16px;
      padding: 20px;
      transition: transform 0.2s, border-color 0.2s;
    }
    .highlight-card:hover {
      border-color: var(--primary);
      transform: translateY(-2px);
    }
    .highlight-icon {
      font-size: 1.5rem;
      margin-bottom: 8px;
      display: inline-block;
    }
    .highlight-title {
      font-weight: 700;
      font-size: 1.05rem;
      color: #fff;
      margin-bottom: 4px;
    }
    .highlight-desc {
      font-size: 0.88rem;
      color: var(--text-muted);
      line-height: 1.5;
    }
    .content-section {
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: 20px;
      padding: 32px;
      margin-bottom: 24px;
    }
    h2 {
      font-size: 1.35rem;
      font-weight: 800;
      color: #ffffff;
      margin-bottom: 14px;
      display: flex;
      align-items: center;
      gap: 10px;
    }
    h2 .section-num {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      width: 28px;
      height: 28px;
      background: var(--primary-glow);
      color: var(--primary-light);
      border: 1px solid var(--border-accent);
      border-radius: 8px;
      font-size: 0.82rem;
      font-weight: 800;
    }
    p {
      color: var(--text-muted);
      font-size: 0.96rem;
      margin-bottom: 16px;
    }
    p:last-child {
      margin-bottom: 0;
    }
    strong {
      color: #f1f5f9;
      font-weight: 600;
    }
    ul {
      margin-left: 20px;
      margin-bottom: 16px;
      color: var(--text-muted);
      font-size: 0.95rem;
    }
    li {
      margin-bottom: 8px;
    }
    .badge-tag {
      display: inline-block;
      background: rgba(255, 255, 255, 0.06);
      color: var(--text-muted);
      padding: 3px 8px;
      border-radius: 6px;
      font-size: 0.78rem;
      font-family: monospace;
      margin-right: 4px;
    }
    .callout {
      background: rgba(16, 185, 129, 0.08);
      border-left: 3px solid var(--primary);
      padding: 16px 20px;
      border-radius: 0 12px 12px 0;
      margin: 20px 0;
    }
    .callout p {
      color: #e2e8f0;
      font-size: 0.92rem;
      margin: 0;
    }
    .table-container {
      overflow-x: auto;
      margin: 16px 0;
      border-radius: 12px;
      border: 1px solid var(--border);
    }
    table {
      width: 100%;
      border-collapse: collapse;
      font-size: 0.9rem;
      text-align: left;
    }
    th, td {
      padding: 12px 16px;
      border-bottom: 1px solid var(--border);
    }
    th {
      background: var(--surface-card);
      color: #fff;
      font-weight: 700;
    }
    tr:last-child td {
      border-bottom: none;
    }
    td {
      color: var(--text-muted);
    }
    .contact-box {
      background: linear-gradient(135deg, var(--surface) 0%, var(--surface-card) 100%);
      border: 1px solid var(--border-accent);
      border-radius: 16px;
      padding: 24px;
      margin-top: 16px;
    }
    .contact-box a {
      color: var(--primary-light);
      text-decoration: none;
      font-weight: 600;
    }
    .contact-box a:hover {
      text-decoration: underline;
    }
    footer {
      text-align: center;
      padding-top: 40px;
      color: var(--text-dim);
      font-size: 0.85rem;
      border-top: 1px solid var(--border);
      margin-top: 40px;
    }
  </style>
</head>
<body>
  <div class="container">
    <header>
      <div class="brand-pill">
        <span></span> Official Privacy Policy
      </div>
      <h1>Dateora Smart Expiry Tracker</h1>
      <p class="meta">
        <strong>Effective Date:</strong> October 24, 2026 &bull; 
        <strong>Application:</strong> Dateora &bull; 
        <strong>Developer:</strong> Tushal Jadhav
      </p>
    </header>

    <div class="highlights-grid">
      <div class="highlight-card">
        <div class="highlight-icon">🔒</div>
        <div class="highlight-title">100% On-Device Data</div>
        <div class="highlight-desc">All products, expiry dates, quantities, and photos are saved locally in SQLite on your device.</div>
      </div>
      <div class="highlight-card">
        <div class="highlight-icon">🚫</div>
        <div class="highlight-title">No Account Needed</div>
        <div class="highlight-desc">No mandatory signup, no phone numbers, no social logins, and no passwords required.</div>
      </div>
      <div class="highlight-card">
        <div class="highlight-icon">🛡️</div>
        <div class="highlight-title">Zero Ad Tracking</div>
        <div class="highlight-desc">We never sell, rent, monetize, or broker your personal grocery or consumption data to third parties.</div>
      </div>
    </div>

    <!-- Section 1 -->
    <div class="content-section">
      <h2><span class="section-num">1</span> Overview & Commitment</h2>
      <p>
        Welcome to <strong>Dateora</strong> ("we", "our", or "us"). Dateora is an offline-first mobile application designed to help individuals and households track product expiration dates, minimize food waste, and organize groceries, medicines, and household essentials.
      </p>
      <p>
        Your privacy is our core engineering foundation. Unlike conventional cloud apps that synchronize your entire pantry to a central database, Dateora was architected to ensure that your consumption patterns, medicine habits, and household purchases remain strictly on your own hardware.
      </p>
    </div>

    <!-- Section 2 -->
    <div class="content-section">
      <h2><span class="section-num">2</span> Data We Collect & How We Use It</h2>
      <p>To provide core app functionality, Dateora accesses or processes the following categories of data:</p>
      
      <div class="table-container">
        <table>
          <thead>
            <tr>
              <th>Data Category</th>
              <th>How It Is Used</th>
              <th>Storage Location</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td><strong>Inventory Data</strong><br><span class="badge-tag">Items</span> <span class="badge-tag">Dates</span> <span class="badge-tag">Prices</span></td>
              <td>Stores your added items, expiry dates, purchase records, categories, and disposal logs.</td>
              <td><strong>Local Device Only</strong> (Encrypted SQLite Database)</td>
            </tr>
            <tr>
              <td><strong>Photos & Camera</strong><br><span class="badge-tag">Product Photos</span> <span class="badge-tag">Date Stamp</span></td>
              <td>Allows you to capture item reference images and scan expiry labels or barcodes.</td>
              <td><strong>Local App Sandbox</strong> (Internal private storage)</td>
            </tr>
            <tr>
              <td><strong>Barcode Data</strong><br><span class="badge-tag">EAN-13</span> <span class="badge-tag">UPC</span> <span class="badge-tag">QR</span></td>
              <td>Translates packet barcodes into human-readable product names and categories.</td>
              <td>Transient (Used only to fill form fields)</td>
            </tr>
            <tr>
              <td><strong>Technical Diagnostics</strong><br><span class="badge-tag">Crash Logs</span> <span class="badge-tag">OS Version</span></td>
              <td>Monitors app stability and resolves device-specific crashes (Optional).</td>
              <td>Anonymous telemetry via Firebase</td>
            </tr>
          </tbody>
        </table>
      </div>

      <div class="callout">
        <p><strong>Strict Promise:</strong> We never scan your private gallery or access photos outside the Dateora camera viewfinder or files you deliberately select.</p>
      </div>
    </div>

    <!-- Section 3 -->
    <div class="content-section">
      <h2><span class="section-num">3</span> Permissions Requested & Justification</h2>
      <p>Dateora requests specific Android runtime permissions strictly when needed for user-initiated actions:</p>
      <ul>
        <li><strong>CAMERA (<code>android.permission.CAMERA</code>):</strong> Required to scan barcodes and photograph packaging expiry date seals directly within the app.</li>
        <li><strong>READ_MEDIA_IMAGES / STORAGE:</strong> Required solely if you choose to attach existing product photos from your gallery.</li>
        <li><strong>POST_NOTIFICATIONS / SCHEDULE_EXACT_ALARM:</strong> Required to deliver timely reminder alerts before items reach their expiration date. Notifications are triggered locally on the device by the operating system clock.</li>
      </ul>
    </div>

    <!-- Section 4 -->
    <div class="content-section">
      <h2><span class="section-num">4</span> AI Vision Scanning & Third-Party Processors</h2>
      <p>
        Dateora includes an optional <strong>AI Packaging Vision Auto-Fill</strong> feature powered by Google Gemini Vision.
      </p>
      <p>
        When you choose to tap "Scan Packaging with AI":
      </p>
      <ul>
        <li>Only the specific photo of the product front and date stamp is transmitted via secure HTTPS (TLS 1.3) to the Google Gemini API.</li>
        <li>The AI processes the image solely in volatile memory to identify the product title, category, and date digits.</li>
        <li>Google does not use customer images submitted via the API to train foundational AI models.</li>
        <li>Once the text is extracted and returned to your phone, the session ends. No images are permanently stored on any remote cloud server.</li>
        <li>If you prefer, you can use Dateora 100% offline via manual entry or barcode scan without ever invoking AI scanning.</li>
      </ul>
    </div>

    <!-- Section 5 -->
    <div class="content-section">
      <h2><span class="section-num">5</span> Third-Party Service Providers</h2>
      <p>We work with trusted industry providers that comply with international privacy standards (GDPR, CCPA):</p>
      <ul>
        <li><strong>Google Play Services:</strong> Used for app distribution, updates, and core Android runtime services.</li>
        <li><strong>Firebase Analytics & Crashlytics (Google LLC):</strong> Collects anonymous aggregated crash reports and basic engagement numbers (e.g. number of items added). No personal names, photos, or barcodes are transmitted. You can disable analytics anytime in <em>Settings &rarr; Privacy</em>.</li>
        <li><strong>Open Food Facts:</strong> A non-profit open database used for public barcode title resolution. Barcode numbers are queried anonymously without user tracking.</li>
      </ul>
    </div>

    <!-- Section 6 -->
    <div class="content-section">
      <h2><span class="section-num">6</span> Data Retention, Deletion & User Rights</h2>
      <p>
        Because all your inventory and photos reside locally on your phone, you have absolute ownership and control:
      </p>
      <ul>
        <li><strong>Instant Item Deletion:</strong> Swiping left or tapping delete on any item permanently purges its record and associated image file from disk.</li>
        <li><strong>Complete Data Wipe:</strong> Navigate to <em>Settings &rarr; Clear All Data</em> to permanently erase all products, history, database tables, and settings in 1 click.</li>
        <li><strong>App Uninstall:</strong> Uninstalling Dateora via Android System Settings immediately deletes the entire local SQLite database, photo cache, and all application state.</li>
      </ul>
    </div>

    <!-- Section 7 -->
    <div class="content-section">
      <h2><span class="section-num">7</span> Children's Privacy (COPPA & GDPR-K)</h2>
      <p>
        Dateora is a general audience utility intended for household inventory management. We do not knowingly collect, solicit, or retain any personally identifiable information from children under the age of 13 (or under 16 in the European Union). If you believe a child has provided us with personal information, please contact us immediately.
      </p>
    </div>

    <!-- Section 8 -->
    <div class="content-section">
      <h2><span class="section-num">8</span> Security Safeguards</h2>
      <p>
        We employ industry-standard security safeguards to protect your information:
      </p>
      <ul>
        <li>App Sandbox isolation provided by the Android Linux kernel.</li>
        <li>Enforced HTTPS/TLS transport for all network communication.</li>
        <li>No insecure cleartext HTTP traffic allowed (<code>usesCleartextTraffic="false"</code>).</li>
      </ul>
    </div>

    <!-- Section 9 -->
    <div class="content-section">
      <h2><span class="section-num">9</span> Changes to This Privacy Policy</h2>
      <p>
        We may update our Privacy Policy from time to time. Any changes will be posted on this page with an updated "Effective Date". We encourage you to review this page periodically. Continued use of Dateora after changes constitute acceptance of the updated policy.
      </p>
    </div>

    <!-- Section 10 -->
    <div class="content-section">
      <h2><span class="section-num">10</span> Contact Us</h2>
      <p>
        If you have any questions, suggestions, or data protection inquiries regarding this Privacy Policy or Dateora, please contact us:
      </p>
      <div class="contact-box">
        <p><strong>Developer:</strong> Tushal Jadhav</p>
        <p><strong>App:</strong> Dateora — Smart Expiry Tracker</p>
        <p><strong>Support & Privacy Email:</strong> <a href="mailto:tushaljadhav.dev@gmail.com">tushaljadhav.dev@gmail.com</a></p>
        <p><strong>Website:</strong> <a href="https://dateora.onrender.com" target="_blank">https://dateora.onrender.com</a></p>
      </div>
    </div>

    <footer>
      <p>&copy; 2026 Dateora. All rights reserved. Designed with privacy-first offline architecture.</p>
    </footer>
  </div>
</body>
</html>`;
}

module.exports = { renderPrivacyPolicyHtml };
