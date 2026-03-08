import re

with open("/home/neo/Hunting_Call_New/docs/wiki.html", "r", encoding="utf-8") as f:
    html = f.read()

# 1. Update Sidebar - Architecture
arch_search = """                <a class="nav-item" data-page="recording-logic" onclick="showPage('recording-logic')">
                    <span class="icon">🎙️</span> Recording Logic
                </a>"""
arch_replace = arch_search + """
                <a class="nav-item" data-page="profile-data" onclick="showPage('profile-data')">
                    <span class="icon">💾</span> Profile Data Sync
                </a>"""
html = html.replace(arch_search, arch_replace)

# 2. Update Sidebar - Operations
ops_search = """                <a class="nav-item" data-page="audit" onclick="showPage('audit')">
                    <span class="icon">🔍</span> Code Audit Report
                </a>"""
ops_replace = """                <a class="nav-item" data-page="build-ops" onclick="showPage('build-ops')">
                    <span class="icon">⚙️</span> Android Build Ops
                </a>
                <a class="nav-item" data-page="technical-quirks" onclick="showPage('technical-quirks')">
                    <span class="icon">🧩</span> Technical Quirks
                </a>
                <a class="nav-item" data-page="audio-norm" onclick="showPage('audio-norm')">
                    <span class="icon">🎧</span> Audio Normalization
                </a>\n""" + ops_search
html = html.replace(ops_search, ops_replace)

# 3. Update Home Grid
grid_search = """                    <div class="home-card" onclick="showPage('paywall')">
                        <div class="card-icon">💎</div>
                        <h3>Paywall UI</h3>
                        <p>Luxury gold-gradient monetization touchpoints and dynamic store price parsing.</p>
                    </div>"""
grid_replace = grid_search + """
                    <div class="home-card" onclick="showPage('profile-data')">
                        <div class="card-icon">💾</div>
                        <h3>Profile Data Sync</h3>
                        <p>Sort-on-read migrations and hybrid Firebase/Local ordering strategies.</p>
                    </div>
                    <div class="home-card" onclick="showPage('build-ops')">
                        <div class="card-icon">⚙️</div>
                        <h3>Android Build Ops</h3>
                        <p>Gradle OOM fixes, deadlock resolutions, and release workflow scripts.</p>
                    </div>
                    <div class="home-card" onclick="showPage('technical-quirks')">
                        <div class="card-icon">🧩</div>
                        <h3>Technical Quirks</h3>
                        <p>DI Matrices, race conditions, WCAG accessibility rules, and memory cleanup.</p>
                    </div>
                    <div class="home-card" onclick="showPage('audio-norm')">
                        <div class="card-icon">🎧</div>
                        <h3>Audio Normalization</h3>
                        <p>Asset workflows scaling animal calls to consistent peak amplitudes and bitrates.</p>
                    </div>"""
html = html.replace(grid_search, grid_replace)

# 4. Insert Articles
articles_to_add = """
            <!-- ═══ PROFILE DATA ═══ -->
            <div class="article" id="page-profile-data" data-tags="tech"
                data-searchable="profile data history sync reverse order newest first prepending timeline sort on read migration unified repository">
                <div class="article-header">
                    <h2>Profile Data & History Sync</h2>
                    <div class="article-meta">
                        <span class="article-tag tag-tech">Technical</span>
                    </div>
                </div>
                <div class="article-body">
                    <p>Ensuring consistent data ordering across multiple platforms and storage backends (Firebase, Firedart, SQLite) is a core requirement for OUTCALL.</p>

                    <h3>History Ordering Discrepancy</h3>
                    <p>A critical discrepancy was discovered between local and cloud history storage:</p>
                    <ul>
                        <li><strong>Local Sources:</strong> Used <code>insert(0, item)</code> to prepend new entries (newest-first).</li>
                        <li><strong>Cloud Sources:</strong> Used <code>.add(data)</code>, appending to the end (newest-last).</li>
                    </ul>

                    <h3>Read-Time Migration (Sort-On-Read)</h3>
                    <p>To avoid complex offline database migrations, a sort-on-read strategy was deployed in the <code>_sanitizeProfileData</code> method of the <code>UnifiedProfileRepository</code>.</p>
                    <p>Every time a profile is loaded from any cloud source, the <code>history</code> list is explicitly sorted by its timestamp field in <strong>descending order</strong> (newest first).</p>
                    <p>This ensures existing users with flipped histories see their records fixed immediately upon loading, without requiring write-backs.</p>
                </div>
            </div>

            <!-- ═══ BUILD OPS ═══ -->
            <div class="article" id="page-build-ops" data-tags="tech"
                data-searchable="android build ops gradle OOM deadlock lock workflow appbundle APK">
                <div class="article-header">
                    <h2>Android Build & Ops</h2>
                    <div class="article-meta">
                        <span class="article-tag tag-tech">Technical</span>
                    </div>
                </div>
                <div class="article-body">
                    <h3>Release Troubleshooting</h3>
                    <p>Production builds are generated via <code>./scripts/build_app.sh</code>.</p>
                    
                    <h4>Gradle Out of Memory (OOM) Errors</h4>
                    <pre><code># Fix in android/gradle.properties:
org.gradle.jvmargs=-Xmx4G -XX:MaxMetaspaceSize=1G
org.gradle.workers.max=1</code></pre>

                    <h4>Deadlock Cleanup</h4>
                    <p>If builds fail with timeouts or hung lock files:</p>
                    <pre><code>cd android && ./gradlew --stop
rm -f .gradle/noVersion/buildLogic.lock</code></pre>

                    <h3>Release Workflows</h3>
                    <ul>
                        <li><strong>Upload scripts:</strong> <code>upload_play.py</code> and <code>upload_apk_gdrive.py</code>.</li>
                        <li><strong>Tagging:</strong> Use <code>vX.Y.Z</code> tags to trigger GitHub Actions.</li>
                    </ul>
                </div>
            </div>

            <!-- ═══ TECHNICAL QUIRKS ═══ -->
            <div class="article" id="page-technical-quirks" data-tags="tech"
                data-searchable="technical quirks DI dependency injection accessibility WCAG memory leak race condition rating logic auth firedart linux">
                <div class="article-header">
                    <h2>Detailed Implementation Quirks</h2>
                    <div class="article-meta">
                        <span class="article-tag tag-tech">Technical</span>
                    </div>
                </div>
                <div class="article-body">
                    <h3>The DI Matrix</h3>
                    <p>The <code>PlatformEnvironment</code> is critical for Riverpod. When <code>Platform.isLinux</code> is true, we CANNOT use <code>Firebase.initializeApp()</code> normally for Auth. We rely entirely on the <code>FiredartAuthRepository</code> and <code>sqflite_common_ffi</code> instead.</p>

                    <h3>Rating Algorithm Cleanup</h3>
                    <p>FFT extraction for spectrogram comparison requires careful memory management. We must specifically destroy <code>cloud_audio_service</code> instances on route pops to prevent memory leaks during spectrogram generation.</p>

                    <h3>Achievement Calculation Race Condition</h3>
                    <p><strong>Issue:</strong> Previously earned achievements displayed as "newly earned" after analysis because <code>RatingScreen</code> checked for achievements using stale profile state.</p>
                    <p><strong>Resolution:</strong> Modified to enforce strict sequencing: <code>loadProfile()</code> → calculate achievements → <code>saveAchievements()</code> → final <code>loadProfile()</code>.</p>
                </div>
            </div>

            <!-- ═══ AUDIO NORMALIZATION ═══ -->
            <div class="article" id="page-audio-norm" data-tags="tech audio"
                data-searchable="audio normalization asset pipeline amplitude RMS decibel peak sample rate 44100Hz workflow">
                <div class="article-header">
                    <h2>Audio Asset Normalization</h2>
                    <div class="article-meta">
                        <span class="article-tag tag-tech">Technical</span>
                        <span class="article-tag tag-audio">Audio</span>
                    </div>
                </div>
                <div class="article-body">
                    <p>Raw WAV and MP3 files from hunters possess wildly varying RMS amplitudes, peak decibels, and sample rates. It is disruptive if a user swaps from a quiet purr to a blaring elk bugle.</p>

                    <h3>Automated Workflow</h3>
                    <p>All incoming assets pass through an automated normalization step using the OUTCALL workspace command: <code>/update-assets</code>.</p>
                    <ol>
                        <li>Downloads target audio assets.</li>
                        <li>Runs batch processing to normalize peak amplitude to a target <strong>-3.0 dBFS</strong>.</li>
                        <li>Standardizes sample rates to <strong>44100 Hz</strong> (optimal for our `AnalyzeAudioUseCase` FFT processing constraint length of 1024).</li>
                    </ol>
                    <p>This guarantees the UI feels premium: switching tracks maintains a consistent volume, and the recording graph doesn't suffer scale mismatch issues.</p>
                </div>
            </div>
"""

insert_point = "            <!-- ═══ PAYMENT ═══ -->"
html = html.replace(insert_point, articles_to_add + "\n" + insert_point)

with open("/home/neo/Hunting_Call_New/docs/wiki.html", "w", encoding="utf-8") as f:
    f.write(html)

print("Wiki maxed out at 21 sections!")
