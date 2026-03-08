import re

with open("/home/neo/Hunting_Call_New/docs/wiki.html", "r", encoding="utf-8") as f:
    html = f.read()

# 1. Update Sidebar - Add Encyclopedia at the end
nav_search = """                <a class="nav-item" data-page="audit" onclick="showPage('audit')">
                    <span class="icon">🔍</span> Code Audit Report
                </a>
            </div>"""
nav_replace = nav_search + """

            <div class="nav-section">
                <div class="nav-section-title">Techniques & Community</div>
                <a class="nav-item" data-page="turkey" onclick="showPage('turkey')">
                    <span class="icon">🦃</span> Turkey Calling
                </a>
                <a class="nav-item" data-page="elk" onclick="showPage('elk')">
                    <span class="icon">🦌</span> Elk Calling
                </a>
                <a class="nav-item" data-page="waterfowl" onclick="showPage('waterfowl')">
                    <span class="icon">🦆</span> Waterfowl Calling
                </a>
                <a class="nav-item" data-page="predator" onclick="showPage('predator')">
                    <span class="icon">🐺</span> Predators & Deer
                </a>
                <a class="nav-item" data-page="scoring-deep" onclick="showPage('scoring-deep')">
                    <span class="icon">📈</span> Scoring Pipeline
                </a>
                <a class="nav-item" data-page="ethics" onclick="showPage('ethics')">
                    <span class="icon">🌲</span> Conservation Ethics
                </a>
            </div>"""
html = html.replace(nav_search, nav_replace)

# 2. Update Home Grid
grid_search = """                </div>\n            </div>\n\n            <!-- ═══ ANIMAL BIOACOUSTICS ═══ -->"""
grid_replace = """
                    <div class="home-card" onclick="showPage('turkey')">
                        <div class="card-icon">🦃</div>
                        <h3>Turkey Calling</h3>
                        <p>The art of the diaphragm and friction pot. Yelps, clucks, purrs, and cutts.</p>
                    </div>
                    <div class="home-card" onclick="showPage('elk')">
                        <div class="card-icon">🦌</div>
                        <h3>Elk Calling</h3>
                        <p>Mastering the bugle tube, cow mews, lip bawls, and estrus whines.</p>
                    </div>
                    <div class="home-card" onclick="showPage('waterfowl')">
                        <div class="card-icon">🦆</div>
                        <h3>Waterfowl Calling</h3>
                        <p>Single and double reed manipulation for hail calls and feed chuckles.</p>
                    </div>
                    <div class="home-card" onclick="showPage('predator')">
                        <div class="card-icon">🐺</div>
                        <h3>Predators & Deer</h3>
                        <p>Whitetail grunts, buck roars, rabbit distress, and coyote howls.</p>
                    </div>
                    <div class="home-card" onclick="showPage('scoring-deep')">
                        <div class="card-icon">📈</div>
                        <h3>Scoring Pipeline</h3>
                        <p>How DTW, MFCC, and Pitch Extraction calculate the 100-point performance metric.</p>
                    </div>
                    <div class="home-card" onclick="showPage('ethics')">
                        <div class="card-icon">🌲</div>
                        <h3>Conservation Ethics</h3>
                        <p>The dangers of over-calling public land, safety, and community standards.</p>
                    </div>
""" + grid_search
html = html.replace(grid_search, grid_replace)

# 3. Insert Articles
articles_to_add = """
            <!-- ═══ TURKEY ═══ -->
            <div class="article" id="page-turkey" data-tags="turkey community technique"
                data-searchable="turkey diaphragm friction pot peg box call yelp cluck purr cutt raspy break setup">
                <div class="article-header">
                    <h2>The Art of Turkey Calling</h2>
                    <div class="article-meta">
                        <span class="article-tag tag-community">Community</span>
                    </div>
                </div>
                <div class="article-body">
                    <p>Turkey calling is widely considered one of the most interactive and challenging forms of acoustic hunting.</p>

                    <h3>Tools of the Trade</h3>
                    <ul>
                        <li><strong>Diaphragm (Mouth) Calls:</strong> Hands-free, high learning curve. Push air over the reed while dropping the jaw to create the distinct two-note "break" of a yelp.</li>
                        <li><strong>Friction Calls (Pot and Peg):</strong> Excellent for soft purrs and clucks. Draw small ovals for yelps, slow drags for purrs.</li>
                        <li><strong>Box Calls:</strong> Incredible volume and reach; can pierce through heavy wind.</li>
                    </ul>

                    <h3>Core Vocabulary</h3>
                    <ul>
                        <li><strong>The Yelp:</strong> A basic two-note sound (high to low). OUTCALL focuses on mastering the "break".</li>
                        <li><strong>The Cluck & Purr:</strong> Soft, contented sounds used to reassure a hung-up gobbler.</li>
                        <li><strong>The Cutt:</strong> Loud, sharp, aggressive clucks. Used to demand attention or challenge a boss hen.</li>
                    </ul>

                    <h3>Advanced Strategy: "Taking his Temperature"</h3>
                    <p>You don't just call; you have a conversation. Less is often more in the turkey woods to avoid making a tom suspicious.</p>
                </div>
            </div>

            <!-- ═══ ELK ═══ -->
            <div class="article" id="page-elk" data-tags="elk community technique"
                data-searchable="elk bugle tube cow mew estrus whine lip bawl chuckles grunts setup wind">
                <div class="article-header">
                    <h2>The Art of Elk Calling</h2>
                    <div class="article-meta">
                        <span class="article-tag tag-community">Community</span>
                    </div>
                </div>
                <div class="article-body">
                    <p>Elk calling requires immense lung capacity, precise air control, and an understanding of herd dynamics.</p>

                    <h3>Tools of the Trade</h3>
                    <ul>
                        <li><strong>Diaphragm Calls:</strong> Built with thicker reeds. Requires pushing air from deep in the diaphragm.</li>
                        <li><strong>Bugle Tubes:</strong> A resonance chamber used to amplify and project the sound, creating a deep guttural challenge bugle.</li>
                        <li><strong>External Reed Calls:</strong> Excellent for perfect cow mews and calf chirps with very little practice, but prone to freezing up.</li>
                    </ul>

                    <h3>Core Vocabulary</h3>
                    <ul>
                        <li><strong>The Cow Mew:</strong> A short, sliding vocalization used to calm a herd. OUTCALL focuses on the seamless downward slide.</li>
                        <li><strong>The Estrus Whine:</strong> A nasally, urgent version of the cow mew.</li>
                        <li><strong>Location Bugle:</strong> A clear, ringing two-note bugle without aggressive growls.</li>
                        <li><strong>Challenge Bugle (Lip Bawl):</strong> A violent scream finishing with aggressive, rhythmic chuckles to challenge a herd bull.</li>
                    </ul>
                </div>
            </div>

            <!-- ═══ WATERFOWL ═══ -->
            <div class="article" id="page-waterfowl" data-tags="waterfowl ducks geese community technique"
                data-searchable="waterfowl duck goose single double reed hail call high-ball greeting feed chuckle mallard canandian honk">
                <div class="article-header">
                    <h2>The Art of Waterfowl Calling</h2>
                    <div class="article-meta">
                        <span class="article-tag tag-community">Community</span>
                    </div>
                </div>
                <div class="article-body">
                    <p>Waterfowl calling is perhaps the most competitive and stylized of all hunting acoustic disciplines.</p>

                    <h3>Tools of the Trade</h3>
                    <ul>
                        <li><strong>Single Reed Duck Calls:</strong> Unmatched volume and capable of the sharpest cuts. Very unforgiving. Requires staccato bursts of air ("tick, tick, tick").</li>
                        <li><strong>Double Reed Duck Calls:</strong> Easier to master, built-in rasp. Great for close-in timber.</li>
                        <li><strong>Short Reed Goose Calls:</strong> Extreme realism for Canadas, but highly technical hand-back pressure is required to "break" the reed.</li>
                    </ul>

                    <h3>Core Vocabulary</h3>
                    <ul>
                        <li><strong>The Hail Call:</strong> A loud, aggressive, descending sequence used to get the attention of high-flying travelers.</li>
                        <li><strong>The Greeting Call:</strong> A rhythmic sequence dropping slightly in pitch. Tells circling birds it's safe.</li>
                        <li><strong>The Feed Chuckle:</strong> A rapid, rolling sequence of low-volume "tik-a-tik" sounds mimicking a feeding frenzy.</li>
                    </ul>
                </div>
            </div>

            <!-- ═══ PREDATOR ═══ -->
            <div class="article" id="page-predator" data-tags="predator deer coyote whitetail community technique"
                data-searchable="deer whitetail predator coyote rabbit distress tending grunt buck roar snort wheeze rattling howl bark fox">
                <div class="article-header">
                    <h2>Deciphering Whitetails & Predators</h2>
                    <div class="article-meta">
                        <span class="article-tag tag-community">Community</span>
                    </div>
                </div>
                <div class="article-body">
                    <p>Calling whitetails and predators requires patience, precision, and relying on biological instincts.</p>

                    <h3>Whitetail Deer Vocabulary</h3>
                    <ul>
                        <li><strong>The Tending Grunt:</strong> Short, rhythmic grunts of a trailing buck. OUTCALL focuses on a steady walking cadence.</li>
                        <li><strong>The Buck Roar / Snort Wheeze:</strong> A highly aggressive dominance challenge pushing air forcefully through pinched nostrils.</li>
                        <li><strong>Rattling:</strong> Crashing antlers simulating a fight.</li>
                    </ul>

                    <h3>Predator Calling</h3>
                    <ul>
                        <li><strong>The Rabbit Distress:</strong> The universal dinner bell. Chaotic, desperate squeals of a dying animal.</li>
                        <li><strong>The Coyote Howl:</strong> The Lone Howl locates packs at dawn, while the Challenge Bark-Howl pulls a dominant alpha to defend his territory.</li>
                    </ul>
                </div>
            </div>

            <!-- ═══ SCORING DEEP DIVE ═══ -->
            <div class="article" id="page-scoring-deep" data-tags="tech audio"
                data-searchable="scoring pipeline engine AI analysis MFCC DTW DSP fast fourier transform pitch CREPE YIN">
                <div class="article-header">
                    <h2>The AI Scoring Pipeline</h2>
                    <div class="article-meta">
                        <span class="article-tag tag-tech">Technical</span>
                        <span class="article-tag tag-audio">Audio</span>
                    </div>
                </div>
                <div class="article-body">
                    <p>The OUTCALL scoring engine integrates advanced DSP and ML algorithms to translate raw acoustics into a 100-point metric.</p>

                    <h3>Pipeline Architecture</h3>
                    <p>It rigorously separates raw feature extraction (the "Ear") from mathematical evaluation (the "Brain") using an isolated <code>compute()</code> thread to prevent UI jank.</p>

                    <h3>Advanced Feature Extraction</h3>
                    <ul>
                        <li><strong>MFCC:</strong> Spectral fingerprinting capturing the exact timbre (tone quality).</li>
                        <li><strong>Dynamic Time Warping (DTW):</strong> "Stretches" the time axis of the user's attempt to align spectral peaks with the reference track, neutralizing tempo variations.</li>
                        <li><strong>Harmonic Extraction:</strong> Differentiates true vocal fold resonance from white-noise rushing air.</li>
                    </ul>

                    <h3>The Weighted Matrix</h3>
                    <p>Pitch Accuracy (40%), Tone Quality (30%), Rhythmic Cadence (20%), and Duration & Envelope (10%). Noise floor algorithms actively slice the bottom 10% of frequency frames as dynamic background noise rejection.</p>
                </div>
            </div>

            <!-- ═══ ETHICS ═══ -->
            <div class="article" id="page-ethics" data-tags="community ethics safety"
                data-searchable="ethics conservation community over-calling public land pressured etiquette safety NWTF RMEF">
                <div class="article-header">
                    <h2>Conservation & Ethics</h2>
                    <div class="article-meta">
                        <span class="article-tag tag-community">Community</span>
                    </div>
                </div>
                <div class="article-body">
                    <p>Hunting with a call is a conversation with nature. Doing so unethically damages the resource.</p>

                    <h3>The Problem of Over-Calling</h3>
                    <p>On heavily hunted public lands, turkeys called incessantly become "call-shy". A poor bugling technique educates elk herds, pushing them out of watersheds entirely.</p>

                    <h3>Ethical Standards</h3>
                    <ol>
                        <li><strong>Less is More:</strong> Let the animal dictate the pace. Patience kills more than perfect calling.</li>
                        <li><strong>Never Call "Just to Hear Them":</strong> Every interaction educates the animal. Avoid doing it outside of active hunting setups.</li>
                        <li><strong>Proper Identification:</strong> A perfect bugle draws in hunters too. Always maintain positive visual ID.</li>
                    </ol>

                    <h3>Community Etiquette</h3>
                    <p>Never "horn in" on another hunter's setup. Support conservation organizations like NWTF and RMEF to ensure habitats remain intact.</p>
                </div>
            </div>
"""

# Insert articles exactly before </main>
file_end_search = """            </div>
        </main>"""
file_end_replace = articles_to_add + "\n" + file_end_search
html = html.replace(file_end_search, file_end_replace)

with open("/home/neo/Hunting_Call_New/docs/wiki.html", "w", encoding="utf-8") as f:
    f.write(html)

print("Wiki completely maxed out at 27 sections! ENCYCLOPEDIA EDITION!")
