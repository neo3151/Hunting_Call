import json

pre = json.load(open(r'C:\Users\neo31\Hunting_Call\audit_data_pre_fix.json'))
post = json.load(open(r'C:\Users\neo31\Hunting_Call\audit_data.json'))
ps = pre['flutter']['summary']
ns = post['flutter']['summary']

print('=== BEFORE vs AFTER ===')
keys = ['total_files','total_lines','total_complexity','total_empty_catches',
        'total_raw_listviews','total_listview_builders','total_todos',
        'total_long_methods','total_nesting_violations','total_magic_numbers',
        'total_hardcoded_colors']

for k in keys:
    pv = ps.get(k, 0)
    nv = ns.get(k, 0)
    delta = nv - pv
    sym = '+' if delta > 0 else ''
    print(f'{k:35s}: {pv:6d} -> {nv:6d}  ({sym}{delta})')

pre_sec = len(pre['security'])
post_sec = len(post['security'])
print(f"{'security_issues':35s}: {pre_sec:6d} -> {post_sec:6d}  ({post_sec - pre_sec:+d})")
print()
print('--- Security Details (Post-Fix) ---')
for s in post['security']:
    print(f"  [{s['severity']}] {s['category']}: {s['description']}")
