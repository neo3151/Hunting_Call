---
description: Morning check-in — pull today's and this week's TeamUp events
---

# Morning Calendar Check-In

// turbo-all

## Steps

1. Build and run the check-in script:
```
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass; npx tsc --project c:\Users\neo31\.gemini\antigravity\playground\glowing-bohr\google-mcp\tsconfig.json; npx tsc --project c:\Users\neo31\.gemini\antigravity\playground\glowing-bohr\tsconfig.json; node c:\Users\neo31\.gemini\antigravity\playground\glowing-bohr\dist\checkin.js
```

2. Review the output and summarize the day's schedule to the user. Highlight any upcoming meetings in the next few hours. If there are conflicts or tight scheduling, call those out.
