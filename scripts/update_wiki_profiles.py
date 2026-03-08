import os
import re

# Base paths
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WIKI_PATH = os.path.join(BASE_DIR, 'docs', 'wiki.html')
KB_DIR = os.path.join(BASE_DIR, 'docs', 'kb', 'calls')

# Define the 17 call profiles
CALL_PROFILES = [
    {"id": "bobcat-growl", "icon": "🐾", "title": "Bobcat Growl", "file": "bobcat_growl.md", "tags": "predator bobcat growl purr mfcc"},
    {"id": "coyote-howl", "icon": "🐺", "title": "Coyote Howl", "file": "coyote_howl.md", "tags": "predator coyote howl yip dtw glissando"},
    {"id": "crow-call", "icon": "🐦‍⬛", "title": "Crow Call", "file": "crow_call.md", "tags": "locator crow shock gobble rhythm locator"},
    {"id": "buck-grunt", "icon": "🦌", "title": "Buck Grunt", "file": "deer_buck_grunt.md", "tags": "deer whitetail buck grunt tending dominant"},
    {"id": "doe-bleat", "icon": "🦌", "title": "Doe Bleat", "file": "deer_doe_bleat.md", "tags": "deer whitetail doe bleat estrus"},
    {"id": "snort-wheeze", "icon": "😤", "title": "Snort Wheeze", "file": "deer_snort_wheeze.md", "tags": "deer whitetail snort wheeze challenge aggressive mfcc"},
    {"id": "mallard-greeting", "icon": "🦆", "title": "Mallard Greeting", "file": "duck_mallard_greeting.md", "tags": "duck mallard greeting hail quack cadence"},
    {"id": "feed-chuckle", "icon": "🦆", "title": "Feed Chuckle", "file": "duck_feeding_chuckle.md", "tags": "duck mallard feed chuckle rolling rhythm dt"},
    {"id": "elk-bugle", "icon": "⛰️", "title": "Elk Bugle", "file": "elk_bugle.md", "tags": "elk bugle bull challenge lip bawl crepe"},
    {"id": "cow-mew", "icon": "⛰️", "title": "Cow Mew", "file": "elk_cow_mew.md", "tags": "elk cow mew calf chirp pitch slide"},
    {"id": "fox-scream", "icon": "🦊", "title": "Fox Scream", "file": "fox_scream.md", "tags": "predator fox red scream bark envelope"},
    {"id": "goose-honk", "icon": "🪿", "title": "Goose Honk", "file": "goose_honk.md", "tags": "goose canada honk cluck pitch break"},
    {"id": "hog-grunt", "icon": "🐗", "title": "Hog Grunt", "file": "hog_grunt.md", "tags": "hog feral boar grunt squeal sub-bass chaos"},
    {"id": "owl-hoot", "icon": "🦉", "title": "Owl Hoot", "file": "owl_hoot.md", "tags": "locator owl hoot barred shock gobble resonance"},
    {"id": "rabbit-distress", "icon": "🐇", "title": "Rabbit Distress", "file": "rabbit_distress.md", "tags": "predator rabbit distress scream squeal chaos pitch"},
    {"id": "turkey-gobble", "icon": "🦃", "title": "Turkey Gobble", "file": "turkey_gobble.md", "tags": "turkey gobble tom shock rattle mfcc envelope"},
    {"id": "turkey-yelp", "icon": "🦃", "title": "Turkey Yelp", "file": "turkey_yelp.md", "tags": "turkey yelp cluck hen pitch break roll over"}
]

def load_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        return f.read()

def inject_html():
    wiki_html = load_file(WIKI_PATH)

    # 1. Update Sidebar Navigation
    nav_insertion_point = """
                    <a class="nav-item" data-page="ethics" onclick="showPage('ethics')">
                        <span class="icon">🌲</span> Conservation Ethics
                    </a>
                </div>

                <div class="nav-section">
                    <div class="nav-section-title">CORE CALL PROFILES</div>"""
                    
    for call in CALL_PROFILES:
        nav_insertion_point += f"""
                    <a class="nav-item" data-page="{call['id']}" onclick="showPage('{call['id']}')">
                        <span class="icon">{call['icon']}</span> {call['title']}
                    </a>"""

    wiki_html = wiki_html.replace(
        """                    <a class="nav-item" data-page="ethics" onclick="showPage('ethics')">
                        <span class="icon">🌲</span> Conservation Ethics
                    </a>
                </div>""",
        nav_insertion_point
    )

    # 2. Update Home Grid
    grid_insertion_point = ""
    for call in CALL_PROFILES:
        grid_insertion_point += f"""
                    <div class="home-card" onclick="showPage('{call['id']}')">
                        <div class="card-icon">{call['icon']}</div>
                        <h3>{call['title']}</h3>
                        <p>Acoustic profile and AI scoring analysis for {call['title'].lower()}.</p>
                    </div>"""

    # We need to find the end of the home-grid to properly insert this
    wiki_html = wiki_html.replace(
        """                    <div class="home-card" onclick="showPage('ethics')">
                        <div class="card-icon">🌲</div>
                        <h3>Conservation Ethics</h3>
                        <p>The dangers of over-calling public land, safety, and community standards.</p>
                    </div>
                </div>
            </div>""",
        f"""                    <div class="home-card" onclick="showPage('ethics')">
                        <div class="card-icon">🌲</div>
                        <h3>Conservation Ethics</h3>
                        <p>The dangers of over-calling public land, safety, and community standards.</p>
                    </div>{grid_insertion_point}
                </div>
            </div>"""
    )


    # 3. Inject Articles
    articles_html = ""
    for call in CALL_PROFILES:
        md_path = os.path.join(KB_DIR, call['file'])
        if os.path.exists(md_path):
            md_content = load_file(md_path)
            
            # Very basic markdown to HTML conversion for these specific files
            html_content = md_content.replace('## Field Application', '<h3>Field Application</h3>')
            html_content = html_content.replace('## Engine Analysis & Scoring', '<h3>Engine Analysis & Scoring</h3>')
            html_content = html_content.replace('### Key Processing Metrics', '<h4>Key Processing Metrics</h4>')
            html_content = html_content.replace('### Scoring Tips', '<h4>Scoring Tips</h4>')
            
            # Handle standard paragraphs and lists roughly
            lines = html_content.split('\\n')
            formatted_lines = []
            in_list = False
            
            for line in lines:
                if line.startswith('# '):
                    title = line.replace('# ', '')
                    formatted_lines.append(f'<h2>{title}</h2>')
                elif line.startswith('- '):
                    if not in_list:
                        formatted_lines.append('<ul>')
                        in_list = True
                    item = line.replace('- ', '')
                    item = re.sub(r'\\*\\*(.*?)\\*\\*', r'<strong>\1</strong>', item)
                    formatted_lines.append(f'<li>{item}</li>')
                elif line.startswith('1. ') or line.startswith('2. ') or line.startswith('3. '):
                    if not in_list:
                        formatted_lines.append('<ol>')
                        in_list = True
                    item = re.sub(r'^\\d+\\.\\s+', '', line)
                    item = re.sub(r'\\*\\*(.*?)\\*\\*', r'<strong>\1</strong>', item)
                    formatted_lines.append(f'<li>{item}</li>')
                else:
                    if in_list and line.strip() == '':
                        formatted_lines.append('</ul>') # Or </ol>, rough approximation
                        in_list = False
                    elif line.strip() != '' and not line.startswith('<h'):
                        formatted_lines.append(f'<p>{line}</p>')

            if in_list:
                 formatted_lines.append('</ul>')
            
            body_html = '\\n'.join(formatted_lines)
            
            articles_html += f"""
            <!-- ═══ {call['id'].upper()} ═══ -->
            <div class="article" id="page-{call['id']}" data-tags="audio profile"
                data-searchable="{call['tags']}">
                <div class="article-header">
                    <h2>{call['title']} Profile</h2>
                    <div class="article-meta">
                        <span class="article-tag tag-audio">Audio</span>
                        <span class="article-tag tag-community">Community</span>
                    </div>
                </div>
                <div class="article-body">
                    {body_html}
                </div>
            </div>
"""

    wiki_html = wiki_html.replace(
        """    </div>
    </main>
    </div>""",
        f"""{articles_html}
    </div>
    </main>
    </div>"""
    )

    with open(WIKI_PATH, 'w', encoding='utf-8') as f:
        f.write(wiki_html)
    print("SUCCESS: 17 Profile sections injected successfully into wiki.html!")

if __name__ == '__main__':
    inject_html()
