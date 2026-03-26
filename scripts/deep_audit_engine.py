"""
OUTCALL Deep Codebase Audit Engine
Scans every file across both Flutter & Python repos, generates comprehensive metrics.
"""
import os, re, json, sys

# ── Configuration ──
FLUTTER_LIB = r"C:\Users\neo31\Hunting_Call\lib"
FLUTTER_ROOT = r"C:\Users\neo31\Hunting_Call"
BACKEND_ROOT = r"C:\Users\neo31\Hunting_Call_AI_Backend"
OUTPUT = r"C:\Users\neo31\Hunting_Call\audit_data.json"

results = {
    "flutter": {"files": [], "summary": {}},
    "backend": {"files": [], "summary": {}},
    "security": [],
    "dependencies": {"used": [], "unused_candidates": []},
    "assets": {"audio_files": 0, "image_files": [], "model_files": []},
}

# ── Phase 1: Flutter Dart Files ──
print("[██░░░░░░░░] 10% | Scanning Flutter Dart files...")
dart_files = []
for root, _, files in os.walk(FLUTTER_LIB):
    for f in files:
        if f.endswith('.dart'):
            dart_files.append(os.path.join(root, f))

total = len(dart_files)
for i, path in enumerate(dart_files):
    pct = int((i+1)/total * 40) + 10
    bar = "█" * (pct // 10) + "░" * (10 - pct // 10)
    if (i+1) % 10 == 0 or i == total-1:
        print(f"\r[{bar}] {pct}% | {i+1}/{total} dart files scanned", end="", flush=True)
    
    try:
        with open(path, 'r', encoding='utf-8') as file:
            content = file.read()
            lines = content.split('\n')
    except:
        continue
    
    line_count = len(lines)
    rel_path = os.path.relpath(path, FLUTTER_LIB)
    feature = rel_path.split(os.sep)[0] if os.sep in rel_path else "root"
    
    # Complexity: count branching logic
    ifs = len(re.findall(r'\bif\s*\(', content))
    fors = len(re.findall(r'\bfor\s*\(', content))
    whiles = len(re.findall(r'\bwhile\s*\(', content))
    switches = len(re.findall(r'\bswitch\s*\(', content))
    catches = len(re.findall(r'\bcatch\s*\(', content))
    complexity = ifs + fors + whiles + switches + catches
    
    # Issues
    empty_catches = len(re.findall(r'catch\s*\([^)]*\)\s*\{\s*\}', content))
    todos = len(re.findall(r'\b(TODO|FIXME|HACK|XXX)\b', content, re.IGNORECASE))
    raw_listviews = len(re.findall(r'ListView\(', content))
    listview_builders = len(re.findall(r'ListView\.builder', content))
    setstate_calls = len(re.findall(r'setState\s*\(', content))
    print_stmts = len(re.findall(r'\bprint\s*\(', content))
    hardcoded_colors = len(re.findall(r'Color\(0x[0-9a-fA-F]+\)', content))
    magic_numbers = len(re.findall(r'(?<!\w)\d{3,}(?!\w)(?!\.dart)(?!x[0-9a-fA-F])', content))
    async_no_try = 0
    nested_depth = 0
    
    # Check for deeply nested code (more than 5 indentation levels)
    for line in lines:
        stripped = line.replace('\t', '    ')
        indent = len(stripped) - len(stripped.lstrip())
        if indent > 20:  # 5+ levels of nesting
            nested_depth += 1
    
    # Unused imports (basic heuristic)
    imports = re.findall(r"import '([^']+)'", content)
    
    # Build methods longer than 80 lines
    build_methods = re.findall(r'Widget build\(BuildContext', content)
    long_methods = []
    method_matches = list(re.finditer(r'(Widget \w+\(|void \w+\(|Future<[^>]+> \w+\()', content))
    for m in method_matches:
        start_line = content[:m.start()].count('\n')
        # Find closing brace (rough heuristic)
        brace_count = 0
        found_open = False
        end_line = start_line
        for j in range(m.start(), min(m.start() + 5000, len(content))):
            if content[j] == '{':
                brace_count += 1
                found_open = True
            elif content[j] == '}':
                brace_count -= 1
            if found_open and brace_count == 0:
                end_line = content[:j].count('\n')
                break
        method_len = end_line - start_line
        if method_len > 80:
            method_name = re.search(r'(\w+)\(', m.group()).group(1) if re.search(r'(\w+)\(', m.group()) else "unknown"
            long_methods.append({"name": method_name, "lines": method_len})
    
    entry = {
        "filename": os.path.basename(path),
        "rel_path": rel_path,
        "feature": feature,
        "lines": line_count,
        "complexity": complexity,
        "ifs": ifs,
        "fors": fors,
        "catches": catches,
        "empty_catches": empty_catches,
        "todos": todos,
        "raw_listviews": raw_listviews,
        "listview_builders": listview_builders,
        "setstate_calls": setstate_calls,
        "print_stmts": print_stmts,
        "hardcoded_colors": hardcoded_colors,
        "magic_numbers": magic_numbers,
        "nested_depth_violations": nested_depth,
        "long_methods": long_methods,
        "import_count": len(imports),
    }
    results["flutter"]["files"].append(entry)

print()

# Flutter summary
all_dart = results["flutter"]["files"]
total_lines = sum(f["lines"] for f in all_dart)
total_complexity = sum(f["complexity"] for f in all_dart)
total_empty_catches = sum(f["empty_catches"] for f in all_dart)
total_raw_lv = sum(f["raw_listviews"] for f in all_dart)
total_lv_builder = sum(f["listview_builders"] for f in all_dart)
total_todos = sum(f["todos"] for f in all_dart)
total_long_methods = sum(len(f["long_methods"]) for f in all_dart)
total_nesting = sum(f["nested_depth_violations"] for f in all_dart)
total_magic = sum(f["magic_numbers"] for f in all_dart)
total_hardcoded_colors = sum(f["hardcoded_colors"] for f in all_dart)

# Feature distribution
features = {}
for f in all_dart:
    feat = f["feature"]
    if feat not in features:
        features[feat] = {"files": 0, "lines": 0, "complexity": 0, "issues": 0}
    features[feat]["files"] += 1
    features[feat]["lines"] += f["lines"]
    features[feat]["complexity"] += f["complexity"]
    features[feat]["issues"] += f["empty_catches"] + f["raw_listviews"] + f["todos"] + len(f["long_methods"])

results["flutter"]["summary"] = {
    "total_files": len(all_dart),
    "total_lines": total_lines,
    "total_complexity": total_complexity,
    "total_empty_catches": total_empty_catches,
    "total_raw_listviews": total_raw_lv,
    "total_listview_builders": total_lv_builder,
    "total_todos": total_todos,
    "total_long_methods": total_long_methods,
    "total_nesting_violations": total_nesting,
    "total_magic_numbers": total_magic,
    "total_hardcoded_colors": total_hardcoded_colors,
    "features": features,
}

# ── Phase 2: Backend Python Files ──
print("[██████░░░░] 60% | Scanning Python backend...")
py_files = [f for f in os.listdir(BACKEND_ROOT) if f.endswith('.py')]
for pf in py_files:
    path = os.path.join(BACKEND_ROOT, pf)
    try:
        with open(path, 'r', encoding='utf-8') as file:
            content = file.read()
            lines = content.split('\n')
    except:
        continue
    
    line_count = len(lines)
    complexity = len(re.findall(r'\b(if|for|while|except|elif)\b', content))
    bare_excepts = len(re.findall(r'except\s*:', content))
    broad_excepts = len(re.findall(r'except\s+Exception', content))
    todos = len(re.findall(r'\b(TODO|FIXME|HACK)\b', content, re.IGNORECASE))
    hardcoded_urls = re.findall(r'https?://[^\s\'"]+', content)
    api_keys_exposed = len(re.findall(r'(api_key|API_KEY|secret|SECRET|password|PASSWORD)\s*=\s*["\'][^"\']+["\']', content))
    
    results["backend"]["files"].append({
        "filename": pf,
        "lines": line_count,
        "complexity": complexity,
        "bare_excepts": bare_excepts,
        "broad_excepts": broad_excepts,
        "todos": todos,
        "hardcoded_urls": len(hardcoded_urls),
        "api_keys_exposed": api_keys_exposed,
    })

be_files = results["backend"]["files"]
results["backend"]["summary"] = {
    "total_files": len(be_files),
    "total_lines": sum(f["lines"] for f in be_files),
    "total_complexity": sum(f["complexity"] for f in be_files),
    "total_bare_excepts": sum(f["bare_excepts"] for f in be_files),
    "total_broad_excepts": sum(f["broad_excepts"] for f in be_files),
    "total_api_keys_exposed": sum(f["api_keys_exposed"] for f in be_files),
}

# ── Phase 3: Assets ──
print("[███████░░░] 70% | Auditing assets...")
audio_dir = os.path.join(FLUTTER_ROOT, "assets", "audio")
if os.path.isdir(audio_dir):
    results["assets"]["audio_files"] = len([f for f in os.listdir(audio_dir) if f.endswith(('.mp3','.wav'))])

img_dir = os.path.join(FLUTTER_ROOT, "assets", "images")
if os.path.isdir(img_dir):
    for root, _, files in os.walk(img_dir):
        for f in files:
            fp = os.path.join(root, f)
            sz = os.path.getsize(fp)
            results["assets"]["image_files"].append({"name": f, "size_kb": round(sz/1024, 1)})

model_dir = os.path.join(FLUTTER_ROOT, "assets", "models")
if os.path.isdir(model_dir):
    for f in os.listdir(model_dir):
        fp = os.path.join(model_dir, f)
        if os.path.isfile(fp):
            sz = os.path.getsize(fp)
            results["assets"]["model_files"].append({"name": f, "size_kb": round(sz/1024, 1)})

# ── Phase 4: Dependency Audit ──
print("[████████░░] 80% | Auditing dependencies...")
pubspec_path = os.path.join(FLUTTER_ROOT, "pubspec.yaml")
if os.path.isfile(pubspec_path):
    with open(pubspec_path, 'r') as f:
        pubspec = f.read()
    
    dep_names = re.findall(r'^\s{2}(\w[\w_]*?):', pubspec, re.MULTILINE)
    all_dart_content = ""
    for df in dart_files:
        try:
            with open(df, 'r', encoding='utf-8') as f2:
                all_dart_content += f2.read()
        except:
            pass
    
    for dep in dep_names:
        if dep in ('flutter', 'flutter_test', 'sdk'):
            continue
        # Check if the package is imported anywhere
        patterns = [
            f"package:{dep}/",
            f"package:{dep}.",
        ]
        used = any(p in all_dart_content for p in patterns)
        if used:
            results["dependencies"]["used"].append(dep)
        else:
            results["dependencies"]["unused_candidates"].append(dep)

# ── Phase 5: Security ──
print("[█████████░] 90% | Running security checks...")

# Check firestore rules
rules_path = os.path.join(FLUTTER_ROOT, "firestore.rules")
if os.path.isfile(rules_path):
    with open(rules_path, 'r') as f:
        rules = f.read()
    # Check for active (non-commented) allow list rule
    active_lines = [l for l in rules.split('\n') if not l.strip().startswith('//')]
    active_rules = '\n'.join(active_lines)
    if 'allow list: if isAuthenticated()' in active_rules:
        results["security"].append({
            "severity": "CRITICAL",
            "category": "Data Exposure",
            "file": "firestore.rules",
            "line": rules[:rules.index('allow list: if isAuthenticated()')].count('\n') + 1,
            "description": "Universal collection listing allows any authenticated user to dump all user profiles",
        })
    if 'allow read: if true' in rules:
        results["security"].append({
            "severity": "LOW",
            "category": "Information Disclosure",
            "file": "firestore.rules",
            "description": "Config collection is world-readable (acceptable for version checks)",
        })

# Check for exposed credentials
for pf in py_files:
    path = os.path.join(BACKEND_ROOT, pf)
    try:
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()
        keys = re.findall(r'(api_key|API_KEY|secret|SECRET|password|token)\s*=\s*["\']([^"\']{8,})["\']', content, re.IGNORECASE)
        for k in keys:
            results["security"].append({
                "severity": "HIGH",
                "category": "Credential Exposure",
                "file": pf,
                "description": f"Hardcoded credential found: {k[0]}='{k[1][:4]}***'",
            })
    except:
        pass

# Check for oauth files
for cred_file in ['oauth_credentials.json', 'oauth_token.json']:
    if os.path.isfile(os.path.join(BACKEND_ROOT, cred_file)):
        results["security"].append({
            "severity": "HIGH",
            "category": "Credential Storage",
            "file": cred_file,
            "description": f"OAuth credential file '{cred_file}' is stored in the repository and may be committed to Git",
        })

# Check gitignore
gitignore_path = os.path.join(BACKEND_ROOT, ".gitignore")
if os.path.isfile(gitignore_path):
    with open(gitignore_path, 'r') as f:
        gitignore = f.read()
    if 'oauth_token.json' not in gitignore:
        results["security"].append({
            "severity": "HIGH",
            "category": "Version Control",
            "file": ".gitignore",
            "description": "oauth_token.json is not listed in .gitignore — tokens may leak to GitHub",
        })

print("[██████████] 100% | Audit complete!")
print(f"\n=== SCAN RESULTS ===")
print(f"Flutter: {results['flutter']['summary']['total_files']} files, {results['flutter']['summary']['total_lines']} lines")
print(f"Backend: {results['backend']['summary']['total_files']} files, {results['backend']['summary']['total_lines']} lines")
print(f"Security Issues: {len(results['security'])}")

with open(OUTPUT, 'w') as f:
    json.dump(results, f, indent=2)
print(f"\nData written to {OUTPUT}")
