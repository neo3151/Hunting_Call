# 1. Update .gitignore
$ignoreText = @"

# Post-Cleanup Additions
*.pdf
node_modules/
OUTCALL_*_Report.*
audit_*
stress_test_*
"@
Add-Content -Path "C:\Users\neo31\Hunting_Call\.gitignore" -Value $ignoreText

Set-Location "C:\Users\neo31\Hunting_Call"

# 2. Untrack node_modules and docs/reports that are mistakenly tracked
git rm -r --cached node_modules 2>$null
git rm -r --cached functions/node_modules 2>$null
git rm --cached *.pdf *.html 2>$null
git rm --cached scripts/*.pdf scripts/*.html 2>$null
git rm --cached docs/*.pdf docs/*.html 2>$null

# 3. Physically delete junk files from root
$junk = @(
    "build_log.txt", "errors.txt", "issues.txt", "issues2.txt", "git_log.txt", "git_log_recent.txt",
    "git_branches.txt", "git_reflog.txt", "git_stash.txt", "git_status.txt", "march_commits.txt", 
    "dangling_commits.txt", "pip_check.txt", "stress_results2.txt", "stress_test_final.txt", 
    "stress_test_results.txt", "show.txt", "audit_summary.txt", "audit_comparison.txt", 
    "oversized_methods.txt", "release_notes_1.5.3.txt",
    "NUL", "audit_data*.json", "color_analysis.json", 
    "image_conversion_log.json", "rc_current.json", "remoteconfig_current.json",
    "App_Master_Audit.pdf", "OUTCALL_Audit_Report.pdf", 
    "OUTCALL_Full_Remediation_Report.html", "OUTCALL_Full_Remediation_Report.pdf",
    "Audio_Asset_Fix_Report.pdf", "OUTCALL_Deep_Audit_Report.pdf",
    "hunting_calls_portable.zip", "workspace_cleanup.zip", "*.apk",
    ".idea/", ".vscode/settings.json"
)

foreach ($j in $junk) {
    if (Test-Path $j) {
        git rm -r --force $j 2>$null
        Remove-Item $j -Force -Recurse -ErrorAction SilentlyContinue
    }
}

# Delete HTML/PDF from scripts
Remove-Item scripts/*.pdf -Force -ErrorAction SilentlyContinue
Remove-Item scripts/*.html -Force -ErrorAction SilentlyContinue

echo "Cleanup junk completed."

# 4. Move root python scripts to scripts/
$pyScripts = @(
    "check_issues.py", "generate_audit_tables.py", "get_all_apks.py", 
    "get_latest.py", "remove_calls.py", "remove_egyptian_goose.py", 
    "remove_muscovy.py", "upload_to_drive.py"
)
foreach ($py in $pyScripts) {
    if (Test-Path $py) {
        git mv $py scripts/ 2>$null
        if (Test-Path $py) {
            Move-Item $py "scripts/" -Force -ErrorAction SilentlyContinue
        }
    }
}
echo "Moved scripts."

# 5. Commit
git add -u
git add .gitignore
git add scripts/
git commit -m "chore: repository cleanup of detritus, logs, reports, and root scripts"
git push origin HEAD

echo "All cleanup tasks pushed."
