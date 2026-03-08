import re

with open("/home/neo/Hunting_Call_New/docs/wiki.html", "r", encoding="utf-8") as f:
    html = f.read()

# 1. Update Sidebar - Architecture
arch_search = """                <a class="nav-item" data-page="testing" onclick="showPage('testing')">
                    <span class="icon">🧪</span> Testing Methods
                </a>"""
arch_replace = arch_search + """
                <a class="nav-item" data-page="app-shell" onclick="showPage('app-shell')">
                    <span class="icon">🔄</span> App Lifecycle
                </a>
                <a class="nav-item" data-page="recording-logic" onclick="showPage('recording-logic')">
                    <span class="icon">🎙️</span> Recording Logic
                </a>"""
html = html.replace(arch_search, arch_replace)

# 2. Update Sidebar - Monetization (rename Payment & IAP slightly or just add below)
pay_search = """                <a class="nav-item" data-page="payment" onclick="showPage('payment')">
                    <span class="icon">💳</span> Payment & IAP
                </a>"""
pay_replace = pay_search + """
                <a class="nav-item" data-page="entitlement" onclick="showPage('entitlement')">
                    <span class="icon">🔐</span> Entitlement Logic
                </a>
                <a class="nav-item" data-page="paywall" onclick="showPage('paywall')">
                    <span class="icon">💎</span> Paywall UI
                </a>"""
html = html.replace(pay_search, pay_replace)

# 3. Update Home Grid
grid_search = """                    <div class="home-card" onclick="showPage('build')">
                        <div class="card-icon">🚀</div>
                        <h3>Build & Release</h3>
                        <p>Automated release.sh workflow, GitHub Actions CI/CD, and Android troubleshooting.</p>
                    </div>"""
grid_replace = grid_search + """
                    <div class="home-card" onclick="showPage('app-shell')">
                        <div class="card-icon">🔄</div>
                        <h3>App Lifecycle</h3>
                        <p>Centralized PageView state management and cleanup to prevent background audio leaks.</p>
                    </div>
                    <div class="home-card" onclick="showPage('recording-logic')">
                        <div class="card-icon">🎙️</div>
                        <h3>Recording Logic</h3>
                        <p>Hardened duration failsafes and Practice mode controller constraints.</p>
                    </div>
                    <div class="home-card" onclick="showPage('entitlement')">
                        <div class="card-icon">🔐</div>
                        <h3>Entitlement Logic</h3>
                        <p>Hybrid Cloud + Local persistence for offline and sandbox premium feature unlocking.</p>
                    </div>
                    <div class="home-card" onclick="showPage('paywall')">
                        <div class="card-icon">💎</div>
                        <h3>Paywall UI</h3>
                        <p>Luxury gold-gradient monetization touchpoints and dynamic store price parsing.</p>
                    </div>"""
html = html.replace(grid_search, grid_replace)

# 4. Insert Articles
articles_to_add = """
            <!-- ═══ APP SHELL ═══ -->
            <div class="article" id="page-app-shell" data-tags="tech"
                data-searchable="app shell lifecycle management pageview tab switch memory dispose audio service resource leak">
                <div class="article-header">
                    <h2>App Shell Lifecycle Management</h2>
                    <div class="article-meta">
                        <span class="article-tag tag-tech">Technical</span>
                    </div>
                </div>
                <div class="article-body">
                    <p>In Outcall, the <code>MainShell</code> uses a <code>PageView</code> to host the primary features (Home, Library, Practice, etc.). Because <code>PageView</code> keeps inactive routes alive in the widget tree, standard screen-level <code>dispose()</code> methods do not fire when the user switches tabs. This creates "resource leaks" where audio or recordings continue playing/running in the background.</p>

                    <h3>1. The Centralized Stop Pattern</h3>
                    <p>To prevent leaks, all global services (Audio, Recording) must be hooked into the <code>MainShell</code> tab-switching logic.</p>
                    
                    <h4>Implementation in <code>MainShell</code>:</h4>
                    <ul>
                        <li><strong>MainShell as ConsumerStatefulWidget</strong>: Converted to access Riverpod providers globally.</li>
                        <li><strong><code>_onPageChanged(int index)</code> Hook</strong>: This is the single source of truth for tab transitions.</li>
                    </ul>

<pre><code>void _onPageChanged(int index) {
  // 1. Stop any playing reference audio
  ref.read(audioServiceProvider).stop();
  
  // 2. Kill any active recording or countdown sessions
  final recState = ref.read(recordingNotifierProvider);
  if (recState.isRecording || recState.isCountingDown) {
    ref.read(recordingNotifierProvider.notifier).reset();
  }
  
  setState(() {
    _currentIndex = index;
  });
}</code></pre>

                    <h3>2. Audio Playback Lifecycle</h3>
                    <p>While the shell handles tab-switching, individual screens should still clean up if they are popped or replaced:</p>
                    <ul>
                        <li><code>AnimalCallsScreen</code> and <code>CallDetailScreen</code> call <code>_audioService?.stop()</code> in their <code>dispose()</code> methods.</li>
                        <li>They also use <code>RouteAware</code> (<code>didPushNext</code>) to stop audio when the user navigates deeper.</li>
                    </ul>

                    <h3>3. Recording Session Lifecycle</h3>
                    <p>Recording sessions are particularly "risky" because they can consume significant storage if left running.</p>
                    <ul>
                        <li><strong>Tab Switch Reset</strong>: Always call <code>recordingNotifier.reset()</code> on tab switch.</li>
                        <li><strong>Hard Failsafe</strong>: In addition to the UI-level auto-stop timer, the <code>RecordingNotifier</code> implements a controller-level hard max duration.</li>
                    </ul>
                </div>
            </div>

            <!-- ═══ RECORDING LOGIC ═══ -->
            <div class="article" id="page-recording-logic" data-tags="tech"
                data-searchable="recording session logic duration hardening timer practice auto-stop">
                <div class="article-header">
                    <h2>Recording Session & Duration Hardening</h2>
                    <div class="article-meta">
                        <span class="article-tag tag-tech">Technical</span>
                    </div>
                </div>
                <div class="article-body">
                    <p>The practice and recording session requires strict lifecycle management to prevent "runaway" recordings.</p>

                    <h3>1. Practice Mode Selection</h3>
                    <p>To maintain a unified "luxury" feel, the <strong>Practice tab</strong> uses the same 3-tier grid navigation as the Library screen.</p>
                    <ul>
                        <li><strong>Selection Mode:</strong> Triggered via <code>selectionMode: true</code> on <code>CategoryGridScreen</code>.</li>
                        <li>In this mode, tapping a call returns the <code>call.id</code> to the <code>RecorderPage</code> context.</li>
                    </ul>

                    <h3>2. Hardening Recording Duration Limits</h3>
                    
                    <h4>2.1 UI-level Auto-Stop Timer</h4>
                    <p>The <code>RecorderPage</code> maintains an <code>_autoStopTimer</code> calculated as <code>(idealDurationSec + 2).clamp(3, 60)</code>.</p>
                    <div class="info-box warning">
                        <div class="info-box-title">Risk</div>
                        UI timers can be unreliable if the widget enters a background state in a flutter <code>PageView</code>.
                    </div>

                    <h4>2.2 Controller-level Failsafe</h4>
                    <p>To ensure recordings always stop, a hard duration limit is implemented at the <code>RecordingNotifier</code> level.</p>
                    <ul>
                        <li><strong>Mechanism:</strong> Calculates a <code>maxDurationSec</code> (e.g., <code>idealDurationSec + 3</code>, ceiling 65s) upon starting.</li>
                        <li><strong>Enforcement:</strong> In the <code>_startTimer</code> tick, the controller checks <code>recordDuration >= _maxDuration</code>. If exceeded, it strictly calls <code>stopRecording()</code>.</li>
                    </ul>

                    <h3>Summary of Duration Rules</h3>
                    <table>
                        <tr><th>Scenario</th><th>Behavior</th></tr>
                        <tr><td><strong>Normal Practice</strong></td><td>Auto-stop at <code>idealDurationSec + 2s</code>.</td></tr>
                        <tr><td><strong>UI Timer Failure</strong></td><td>Controller hard limit stops at <code>idealDurationSec + 3s</code>.</td></tr>
                        <tr><td><strong>Absolute Maximum</strong></td><td>Hard ceiling of 65 seconds for any recording.</td></tr>
                        <tr><td><strong>Switching Tabs</strong></td><td>Stop recording immediately.</td></tr>
                    </table>
                </div>
            </div>

            <!-- ═══ ENTITLEMENT LOGIC ═══ -->
            <div class="article" id="page-entitlement" data-tags="tech business"
                data-searchable="entitlement persistence premium unlock hybrid cloud local shared preferences guest">
                <div class="article-header">
                    <h2>Entitlement & Hybrid Persistence</h2>
                    <div class="article-meta">
                        <span class="article-tag tag-tech">Technical</span>
                        <span class="article-tag tag-business">Business</span>
                    </div>
                </div>
                <div class="article-body">
                    <p>Premium status is a persistently verified state managed by the <code>UnifiedProfileRepository</code>.</p>

                    <h3>Hybrid Verification Logic</h3>
                    <p>To ensure robustness against network issues, the repository implements a hybrid check:</p>
                    <ol>
                        <li><strong>Cloud Source</strong>: Fetch the user document from the <code>profiles</code> Firestore collection.</li>
                        <li><strong>Local Backup</strong>: If <code>isPremium</code> is <code>false</code> (or the fetch fails), checks the <code>LocalProfileDataSource</code> (Secure Storage).</li>
                        <li><strong>Override</strong>: If local cache says the user is premium, the returned entity has <code>isPremium: true</code>.</li>
                    </ol>

                    <h3>Reliability of setPremiumStatus</h3>
                    <p>When a purchase is verified:</p>
                    <ul>
                        <li><strong>Local Write</strong>: Immediately saved to local secure storage.</li>
                        <li><strong>Cloud Write</strong>: Update sent to Firestore.</li>
                    </ul>
                    <p>This ensures that if the user loses internet immediately after purchasing, "Pro" features remain unlocked.</p>
                </div>
            </div>

            <!-- ═══ PAYWALL UI ═══ -->
            <div class="article" id="page-paywall" data-tags="business ui"
                data-searchable="paywall UI UX design monetization gradient shimmer subscription parsed sandbox price">
                <div class="article-header">
                    <h2>Paywall UI & Configuration</h2>
                    <div class="article-meta">
                        <span class="article-tag tag-business">Business</span>
                        <span class="article-tag tag-ui">Design</span>
                    </div>
                </div>
                <div class="article-body">
                    <p>The <code>PaywallScreen</code> is the primary monetization touchpoint.</p>

                    <h3>Visual Design</h3>
                    <ul>
                        <li><strong>Gradient Buttons</strong>: Uses a transitioning gold gradient (<code>accentGoldDark</code> to <code>accentGoldLight</code>).</li>
                        <li><strong>Glassmorphism</strong>: Shown as a modal bottom sheet with a deep charcoal surface.</li>
                    </ul>

                    <h3>Price Parsing & Sandbox Handling</h3>
                    <p>Store price strings (from Google/Apple) vary by locale. In sandbox testing, periods like <code>/30 min</code> frequently leak into price strings.</p>
                    
                    <p>The <code>PaywallScreen</code> uses <code>_stripBillingPeriod</code> to clean these strings:</p>
                    <ul>
                        <li>Uses regex to isolate the currency and numeric amount (e.g., <code>$24.99</code>).</li>
                        <li>Handles both <code>/</code> and <code> per </code> separators.</li>
                        <li>Ensures UI consistently appends the intended period (e.g., <code>/yr</code>).</li>
                    </ul>
                    
                    <p>This prevents confusing "/30mins" labels from appearing to users in test tracks!</p>
                </div>
            </div>
"""

insert_point = "            <!-- ═══ DATA FETCHING ═══ -->"
html = html.replace(insert_point, articles_to_add + "\n" + insert_point)

with open("/home/neo/Hunting_Call_New/docs/wiki.html", "w", encoding="utf-8") as f:
    f.write(html)

print("Wiki loaded with even MORE articles!")
