import re

with open("/home/neo/Hunting_Call_New/docs/wiki.html", "r", encoding="utf-8") as f:
    html = f.read()

# 1. Update Sidebar - Architecture
arch_search = """                <a class="nav-item" data-page="architecture" onclick="showPage('architecture')">
                    <span class="icon">🏗️</span> App Architecture
                </a>"""
arch_replace = arch_search + """
                <a class="nav-item" data-page="data-fetching" onclick="showPage('data-fetching')">
                    <span class="icon">⚡</span> Data Fetching
                </a>
                <a class="nav-item" data-page="testing" onclick="showPage('testing')">
                    <span class="icon">🧪</span> Testing Methods
                </a>"""
html = html.replace(arch_search, arch_replace)

# 2. Update Sidebar - Operations
ops_search = """                <a class="nav-item" data-page="audit" onclick="showPage('audit')">
                    <span class="icon">🔍</span> Code Audit Report
                </a>"""
ops_replace = """                <a class="nav-item" data-page="sprint" onclick="showPage('sprint')">
                    <span class="icon">📜</span> Sprint History
                </a>
                <a class="nav-item" data-page="build" onclick="showPage('build')">
                    <span class="icon">🚀</span> Build & Release
                </a>\n""" + ops_search
html = html.replace(ops_search, ops_replace)

# 3. Update Home Grid
grid_search = """                    <div class="home-card" onclick="showPage('audit')">
                        <div class="card-icon">🔍</div>
                        <h3>Code Audit Report</h3>
                        <p>Deep codebase audit results with Grok comparison — fact-checked findings and real issues
                            identified.</p>
                    </div>"""
grid_replace = grid_search + """
                    <div class="home-card" onclick="showPage('data-fetching')">
                        <div class="card-icon">⚡</div>
                        <h3>Data Fetching</h3>
                        <p>Cache-first Firestore strategy for near-instant &lt;100ms loading times.</p>
                    </div>
                    <div class="home-card" onclick="showPage('testing')">
                        <div class="card-icon">🧪</div>
                        <h3>Testing Methods</h3>
                        <p>Automated CI gates, 100-point manual checklist, and Firestore concurrency stress testing.</p>
                    </div>
                    <div class="home-card" onclick="showPage('sprint')">
                        <div class="card-icon">📜</div>
                        <h3>Sprint History</h3>
                        <p>Detailed log of OUTCALL's continuous development, rebranding, and feature epics.</p>
                    </div>
                    <div class="home-card" onclick="showPage('build')">
                        <div class="card-icon">🚀</div>
                        <h3>Build & Release</h3>
                        <p>Automated release.sh workflow, GitHub Actions CI/CD, and Android troubleshooting.</p>
                    </div>"""
html = html.replace(grid_search, grid_replace)

# 4. Insert Articles
articles_to_add = """
            <!-- ═══ DATA FETCHING ═══ -->
            <div class="article" id="page-data-fetching" data-tags="tech"
                data-searchable="data fetching cache first firestore loading offline latency getCollection getDocument FirebaseApiGateway persistent cache snappy performance">
                <div class="article-header">
                    <h2>Data Fetching Strategy: Cache-First</h2>
                    <div class="article-meta">
                        <span class="article-tag tag-tech">Technical</span>
                    </div>
                </div>
                <div class="article-body">
                    <p>To ensure a "snappy" luxury experience, a cache-first strategy is implemented for all high-traffic read operations in the <code>FirebaseApiGateway</code>.</p>
                    
                    <h3>1. Overview</h3>
                    <p>By default, Firestore queries attempt to reach the server to ensure the freshest data. On mobile networks, this can introduce noticeable latency, breaking the premium feel. The <strong>Cache-First</strong> strategy attempts to read from the local persistent cache first, instantly returning results while Firestore background-syncs with the server.</p>
                    
                    <h3>2. Implementation</h3>
                    <p>The following methods use <code>Source.cache</code> in their <code>get()</code> calls:</p>
                    <ul>
                        <li><code>getDocument(String path)</code></li>
                        <li><code>getCollection(String path)</code></li>
                        <li><code>queryCollection(Query query)</code></li>
                        <li><code>getTopDocuments(String path, String orderBy, int limit)</code></li>
                    </ul>
                    
                    <pre><code>Future&lt;Map&lt;String, dynamic&gt;&gt; getDocument(String path) async {
  try {
    // Attempt cache first for instant UI response
    final snapshot = await _firestore.doc(path).get(const GetOptions(source: Source.cache));
    return snapshot.data() ?? {};
  } catch (e) {
    // Fallback to server if cache is empty or fails
    final snapshot = await _firestore.doc(path).get(const GetOptions(source: Source.server));
    return snapshot.data() ?? {};
  }
}</code></pre>
                    
                    <h3>3. Benefits</h3>
                    <ol>
                        <li><strong>Near-Instant Loading</strong>: Screens like Global Rankings and Animal Libraries load in &lt;100ms when data is already cached.</li>
                        <li><strong>Offline Support</strong>: Users can browse the library and review their offline practice attempts without an active connection.</li>
                        <li><strong>Reduced Data Usage</strong>: Fewer server read operations occur during frequent navigation between tabs.</li>
                    </ol>
                    
                    <div class="info-box tip">
                        <div class="info-box-title">Risk Management</div>
                        <strong>Stale Data</strong>: Users might see slightly outdated leaderboards if they haven't synced recently. This is an acceptable trade-off for the performance gain.
                    </div>
                </div>
            </div>

            <!-- ═══ TESTING METHODS ═══ -->
            <div class="article" id="page-testing" data-tags="tech"
                data-searchable="testing quality assurance unit tests manual stress test audio UI UX firestore backend latency concurrency release protocol">
                <div class="article-header">
                    <h2>Testing & Quality Assurance</h2>
                    <div class="article-meta">
                        <span class="article-tag tag-tech">Technical</span>
                    </div>
                </div>
                <div class="article-body">
                    <p>Maintaining the "luxury" and "premium" feel of OUTCALL requires rigorous testing, specifically targeting the complexities of cross-platform audio processing and high-concurrency Firestore interactions.</p>

                    <h3>1. Automated Testing Stack</h3>
                    <ul>
                        <li><strong>Domain Logic</strong>: Unit tests cover core logic (<code>ProfanityFilter</code>, <code>SpamFilter</code>, <code>CalibrationProfile</code>).</li>
                        <li><strong>CI Enforcement</strong>: All tests must pass in the <code>quality-gate</code> job of the GitHub Actions pipeline before a deployment is allowed.</li>
                    </ul>

                    <h3>2. Manual "Stress Test" Checklist</h3>
                    <p>Before major releases, a manual check is performed on real hardware.</p>

                    <h4>Recording Edge Cases</h4>
                    <ul>
                        <li>Home/Back button behavior during active recording.</li>
                        <li>Rapid start/stop stress (hammering the record button).</li>
                        <li>System interruptions (phone calls, alarms) during recording.</li>
                        <li>Storage capacity limits (graceful failure when device is full).</li>
                    </ul>

                    <h4>Audio Playback</h4>
                    <ul>
                        <li>Rapid play/stop toggling (10× quickly on the same track).</li>
                        <li>Cloud audio behavior under "Airplane Mode" constraints.</li>
                        <li>Audio lifecycle logic (ensuring background audio stops when navigating to "Home").</li>
                    </ul>

                    <h4>Navigation & UX</h4>
                    <ul>
                        <li>Split-screen mode and orientation rotation during analysis processing.</li>
                        <li>"Tab hammering": Rapidly switching between Home, Library, and Record.</li>
                        <li>Long session stability (30+ minutes of continuous UI interaction).</li>
                    </ul>

                    <h3>3. Firestore Backend Stress Testing</h3>
                    <p>OUTCALL utilizes a custom Python stress tester (<code>scripts/stress_test_firestore.py</code>) to find backend breaking points.</p>
                    
                    <table>
                        <tr>
                            <th>Metric Tracked</th>
                            <th>Purpose / Target</th>
                        </tr>
                        <tr>
                            <td><strong>Profile Write Latency</strong></td>
                            <td>Simulates concurrent users. Target P95 latency &lt;800ms.</td>
                        </tr>
                        <tr>
                            <td><strong>Leaderboard Contention</strong></td>
                            <td>Tests transactional isolation by submitting scores to same doc simultaneously.</td>
                        </tr>
                        <tr>
                            <td><strong>Burst Reads</strong></td>
                            <td>Measures duration to fetch 50+ documents across multiple collections.</td>
                        </tr>
                    </table>

                    <div class="info-box important">
                        <div class="info-box-title">Release Protocol</div>
                        Any <strong>❌ Fail</strong> in the manual checklist is a hard blocker for production. Target is a <strong>100% pass rate</strong> before promoting a build from Alpha to Production.
                    </div>
                </div>
            </div>

            <!-- ═══ SPRINT HISTORY ═══ -->
            <div class="article" id="page-sprint" data-tags="business"
                data-searchable="sprint history epics roadmap development updates rebranding outcall gobble guru performance native IAP universal UX accessibility launch fixed practice linux fingerprint">
                <div class="article-header">
                    <h2>Sprint History & Epics</h2>
                    <div class="article-meta">
                        <span class="article-tag tag-business">Business</span>
                    </div>
                </div>
                <div class="article-body">
                    <blockquote>Tracks the major epics and feature additions for the OUTCALL application.</blockquote>

                    <h3>1. Deep Audit & Knowledge Base (March 7-8, 2026)</h3>
                    <ul>
                        <li><strong>Objective</strong>: Ground-truth audit of the codebase and creation of this searchable internal wiki.</li>
                        <li><strong>Scoring Engine Retuning</strong>: Solved the "24% score" bug for real-world recordings. Optimized noise penalties and MFCC weights.</li>
                        <li><strong>WAV Parser Roadmap</strong>: Identified risk in hardcoded WAV offsets; established chunk-based parsing strategy.</li>
                        <li><strong>Bioacoustics Reference</strong>: Integrated peer-reviewed frequency data for 5+ species directly into the scoring thresholds.</li>
                        <li><strong>Market Analysis</strong>: Conducted competitive research identifying OUTCALL's unique training niche vs. iHunt/HuntWise.</li>
                    </ul>

                    <h3>2. Rebranding & Performance (Early March 2026)</h3>
                    <ul>
                        <li><strong>Complete Rebranding (OUTCALL)</strong>: Removed the green turkey "Gobble Guru" logo. Replaced with gold-on-charcoal OUTCALL branding.</li>
                        <li><strong>AI Chatbot Integration</strong>: Developed a pure JS chatbot (<code>chatbot.js</code>) using a FAQ-First strategy with an Ollama fallback (Gemma 3 4B).</li>
                        <li><strong>Performance Optimization</strong>: Implemented <code>Source.cache</code> first strategy across <code>FirebaseApiGateway</code> for near-instant loading.</li>
                        <li><strong>2x2 Metrics Grid</strong>: Overhauled the <code>AttemptDetailSheet</code> UI from a cramped row to a clean 2x2 grid.</li>
                        <li><strong>Metric Labeling</strong>: Translated raw keys (<code>timbre</code>, <code>air</code>) into human-readable tabs: Tone Quality, Breath Control, Pitch, and Rhythm.</li>
                    </ul>

                    <h3>3. The Path to v1.8.3 (February - March 2026)</h3>
                    <ul>
                        <li><strong>Migration to Native IAP:</strong> Replaced RevenueCat with <code>in_app_purchase</code>. Developed a custom <code>NativePaymentRepository</code>.</li>
                        <li><strong>Paywall UX Re-Alignment:</strong> Finalized the Monthly ($4.99) and Yearly ($29.99) subscription models in a luxury UI.</li>
                        <li><strong>Universal UX & iOS Accessibility:</strong> Swept the UI ensuring all buttons hit a 14pt minimum size. Verified WCAG AA high contrast. Added Apple Sign-In.</li>
                        <li><strong>App Launch Optimization:</strong> Rebuilt the boot sequence. Added a native splash screen that precaches assets and defers heavy init.</li>
                        <li><strong>Fixed Practice Recording Times:</strong> Simplified the recording UX by moving to a strict 15-second fixed window.</li>
                    </ul>
                </div>
            </div>

            <!-- ═══ BUILD & RELEASE ═══ -->
            <div class="article" id="page-build" data-tags="tech"
                data-searchable="build release workflow deployment GitHub Actions CI/CD pipeline automation python scripts troubleshooting play store appbundle APK google drive gradle Daemon OOM missing google services lock">
                <div class="article-header">
                    <h2>Build & Release Workflow</h2>
                    <div class="article-meta">
                        <span class="article-tag tag-tech">Technical</span>
                    </div>
                </div>
                <div class="article-body">
                    <p>This document tracks the workflow for building and releasing the Outcall application to Google Play.</p>

                    <h3>1. Automated Release Workflow (Recommended)</h3>
                    <p>The primary release mechanism is the <code>release.sh</code> script, which categorizes versions, tags the repository, and triggers the GitHub Actions CI/CD pipeline.</p>
                    
                    <pre><code># Usage: ./scripts/release.sh &lt;version&gt; &lt;build_number&gt; [release_notes]
./scripts/release.sh 1.8.3 37 "Major update with new animal calls and calibration."</code></pre>
                    
                    <ol>
                        <li>Updates <code>pubspec.yaml</code> versions.</li>
                        <li>Updates <code>distribution/whatsnew/en-US.txt</code>.</li>
                        <li>Commits and tags the release (e.g., <code>v1.8.3</code>).</li>
                        <li>Pushes to <code>main</code>, triggering <code>.github/workflows/deploy_release.yml</code>.</li>
                    </ol>

                    <h4>GitHub Actions Pipeline</h4>
                    <p>The pipeline triggers on any tag starting with <code>v</code>.</p>
                    <ul>
                        <li><strong>quality-gate</strong>: Restores <code>google-services.json</code>, runs <code>flutter analyze</code> and <code>flutter test</code>.</li>
                        <li><strong>deploy</strong>: Restores Keystore, builds the Release AAB, uploads to Play Store Alpha Track, and creates a GitHub Release.</li>
                    </ul>

                    <h3>2. Manual Build & Upload Tools</h3>
                    <p>If automation fails, use these specialized scripts:</p>

                    <h4>Local Production Build</h4>
                    <pre><code>flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols</code></pre>

                    <h4>Manual Play Store Upload</h4>
                    <ul>
                        <li><strong>Service Account (Recommended)</strong>: Computes via <code>scripts/upload_to_play_store.py</code> entirely headless.</li>
                        <li><strong>OAuth2 Interactive</strong>: <code>scripts/upload_play.py</code> for one-off manual uploads without service accounts.</li>
                    </ul>

                    <h4>Google Drive Upload (For Testers)</h4>
                    <pre><code>flutter build apk --release
python scripts/upload_apk_gdrive.py</code></pre>

                    <h3>3. Troubleshooting & Common Pitfalls</h3>
                    
                    <h4>Gradle Daemon Exit / OOM</h4>
                    <p><strong>Fix:</strong> Increase memory limit in <code>android/gradle.properties</code>:</p>
                    <pre><code>org.gradle.jvmargs=-Xmx4G -XX:MaxMetaspaceSize=1G
org.gradle.workers.max=1</code></pre>

                    <h4>Stale Build Locks</h4>
                    <p><strong>Fix:</strong> Clear Gradle locks manually:</p>
                    <pre><code>cd android && ./gradlew --stop
rm -f .gradle/noVersion/buildLogic.lock</code></pre>
                </div>
            </div>
"""

insert_point = "            <!-- ═══ BIOACOUSTICS ═══ -->"
html = html.replace(insert_point, articles_to_add + "\n" + insert_point)

with open("/home/neo/Hunting_Call_New/docs/wiki.html", "w", encoding="utf-8") as f:
    f.write(html)

print("Wiki updated successfully!")
