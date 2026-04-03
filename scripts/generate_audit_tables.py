import os
import re

lib_dir = r"C:\Users\neo31\Hunting_Call\lib"

metrics = []
for root, _, files in os.walk(lib_dir):
    for f in files:
        if f.endswith('.dart'):
            path = os.path.join(root, f)
            with open(path, 'r', encoding='utf-8') as file:
                try:
                    lines = file.readlines()
                    line_count = len(lines)
                    content = "".join(lines)
                    
                    # basic complexity: count indents/if/for/switch
                    complexity = len(re.findall(r'\b(if|for|while|switch|catch)\b', content))
                    
                    # vulnerabilities
                    empty_catches = len(re.findall(r'catch\s*\([^)]*\)\s*\{\s*\}', content))
                    todos = len(re.findall(r'\b(TODO|FIXME)\b', content, re.IGNORECASE))
                    hardcoded_strings = len(re.findall(r"(?:\s*['\"][^'\"]{10,}['\"](?!\s*:))", content)) # basic heuristic
                    list_views = len(re.findall(r'ListView\(', content))
                    
                    metrics.append({
                        'filename': f,
                        'lines': line_count,
                        'complexity': complexity,
                        'empty_catches': empty_catches,
                        'todos': todos,
                        'list_views': list_views
                    })
                except Exception as e:
                    pass

# Sort by lines descending
metrics = sorted(metrics, key=lambda x: x['lines'], reverse=True)

md_table = "| Filename | Line Count | Logic Complexity Score | Empty Catch Traps | Raw `ListView`s |\n"
md_table += "|----------|------------|------------------------|-------------------|-----------------|\n"

for m in metrics[:40]:  # Top 40 largest files
    md_table += f"| `{m['filename']}` | {m['lines']} | {m['complexity']} | {m['empty_catches']} | {m['list_views']} |\n"

with open(r'C:\Users\neo31\Hunting_Call\temp_metrics_table.md', 'w') as f:
    f.write(md_table)
    
print("Metrics table generated!")
