import os
import re

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WIKI_PATH = os.path.join(BASE_DIR, 'docs', 'wiki.html')
KB_DIR = os.path.join(BASE_DIR, 'docs', 'kb')

# Files to inject
FILES = [
    ('dev_major_implementations.md', 'Major Implementations', 'dev-implementations'),
    ('dev_roadmap.md', 'App Roadmap (2026-2027)', 'dev-roadmap')
]

import markdown

def inject_dev_docs():
    with open(WIKI_PATH, 'r', encoding='utf-8') as f:
        html = f.read()

    # 1. Inject into Sidebar
    # Find the "Operations" nav section and insert "App Development & Roadmap" section before it, or just add them under Architecture.
    # Let's add a new section for APP DEVELOPMENT
    if 'App Development & Roadmap' not in html:
        nav_injection = """
                <div class="nav-section-title">App Development & Roadmap</div>
                <a href="#dev-implementations" class="nav-item" data-target="dev-implementations"><div class="icon"><i class="fas fa-layer-group"></i></div>Major Implementations</a>
                <a href="#dev-roadmap" class="nav-item" data-target="dev-roadmap"><div class="icon"><i class="fas fa-route"></i></div>Development Roadmap</a>
"""
        # Insert before: <div class="nav-section-title">Operations</div>
        html = html.replace('<div class="nav-section-title">Operations</div>', nav_injection + '                <div class="nav-section-title">Operations</div>')

    # 2. Inject into Grid
    # Add a new Grid category card
    if 'Major Implementations' not in html:
        grid_injection = """
                    <div class="card" onclick="document.querySelector('[data-target=\\'dev-implementations\\']').click()">
                        <div class="card-icon"><i class="fas fa-layer-group"></i></div>
                        <h3>Major Implementations</h3>
                        <p>Core architecture, AI coach, and scoring pipeline history.</p>
                    </div>
                    <div class="card" onclick="document.querySelector('[data-target=\\'dev-roadmap\\']').click()">
                        <div class="card-icon"><i class="fas fa-route"></i></div>
                        <h3>App Roadmap (2026-2027)</h3>
                        <p>Future features, social integration, and iOS expansion.</p>
                    </div>
"""
        # Insert at the end of the overview grid
        html = html.replace('</div>\n            </article>\n\n            <!-- END OVERVIEW -->', grid_injection + '                </div>\n            </article>\n\n            <!-- END OVERVIEW -->')

    # 3. Inject Articles
    for filename, title, target in FILES:
        if f'id="{target}"' not in html:
            with open(os.path.join(KB_DIR, filename), 'r', encoding='utf-8') as f:
                md_content = f.read()
            html_content = markdown.markdown(md_content)
            
            article_template = f"""
            <article id="{target}" class="article">
                <div class="article-header">
                    <h2>{title}</h2>
                    <div class="article-meta">
                        <span><i class="fas fa-clock"></i> Updated March 2026</span>
                        <span><i class="fas fa-folder"></i> App Development</span>
                    </div>
                </div>
                <div class="content format-standard">
{html_content}
                </div>
            </article>
"""
            # Insert before the end of main-content
            html = html.replace('</main>', article_template + '        </main>')

    with open(WIKI_PATH, 'w', encoding='utf-8') as f:
        f.write(html)
        
    print("Injected Dev Docs successfully.")

if __name__ == '__main__':
    inject_dev_docs()
