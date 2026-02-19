---
description: Update Obsidian notes with current project status after completing a significant task
---

# Update Obsidian Notes

Run this workflow at the end of any significant task (feature completion, major refactor, bug fix session, etc.) to keep Obsidian notes in sync with actual project state.

## Steps

1. **Identify the relevant note** in the Obsidian vault (`/home/neo/.gemini/` on Linux, `C:\Users\neo31\Notes\` on Windows). Check if a note already exists for the topic area:
   - `Outcall.md` — Hunting Call app project status
   - `Clean Architecture Migration.md` — architecture/refactoring work
   - Create a new note if the topic doesn't match an existing one (e.g. `Audio Pipeline.md`, `Firebase Setup.md`)

2. **Read the existing note** to understand what's already documented.

3. **Update the note** with:
   - `> **Last Updated:** [current date]` — always update the date
   - `> **Status:**` — one-line summary with emoji (✅ Complete, 🔄 In Progress, ⏸️ Paused)
   - **What was done** — concise bullet points of completed work
   - **Key files** — list any important files created or heavily modified
   - **Next steps** — if there's remaining work, note it briefly

4. **Keep it concise** — Obsidian notes should be scannable, not exhaustive. Use tables and bullet points, not paragraphs.

## Formatting Template

```markdown
# 🏗️ [Topic Name]
> **Last Updated:** [Date]  
> **Status:** [emoji] [One-line status]

---

## 📋 What Was Done
- Bullet points of completed work

## 📂 Key Files
- `path/to/important/file` — what it does

## 🔜 Next Steps (if applicable)
- What remains to be done
```
