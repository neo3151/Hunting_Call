---
description: Use complexity tiers instead of time estimates when scoping work
---

# Complexity Tiers

When estimating task complexity, use these tiers instead of time-based estimates:

| Tier | Label | Scope | Files | Risk |
|------|-------|-------|-------|------|
| 🟢 | **Quick Win** | Single concern, minimal risk | 1-2 | Low |
| 🔵 | **Focused Task** | Clear scope, one sitting | 3-6 | Low-Med |
| 🟡 | **Session** | Needs planning, may hit surprises | 6-15 | Medium |
| 🟠 | **Multi-Session** | Architectural, needs review checkpoints | 15+ | Med-High |
| 🔴 | **Project** | Touches most of codebase, phased rollout | Many | High |

## Usage

When proposing or discussing work, always lead with the tier:

> "Breaking up rating_screen is a **🔵 Focused Task** — straightforward widget extraction."

> "Adding go_router is **🟠 Multi-Session** — touches navigation across every screen."

## Rules

1. Always state the tier **before** starting work
2. If a task escalates mid-work (e.g., 🔵 → 🟡), call it out
3. For 🟡 and above, create an implementation plan before executing
4. For 🟠 and above, request user review at checkpoints
