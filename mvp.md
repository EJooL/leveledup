> [!NOTE]
> **ARCHIVAL DOCUMENT — PRE-REFACTOR MVP BASELINE**
>
> This specification reflects the **original pre-refactor MVP baseline** (gamified RPG Quest Log, Skill Tree, and early 5-table scanner design) and is preserved for historical context and visual design-system tokens (Obsidian Matte Dark `#09090B`, Warm Terracotta `#B5462F`, Emerald `#10B981`, Gold/Amber `#F59E0B`, `Poppins` + `JetBrains Mono`).
>
> **Do not treat this document as the current architecture reference.** LeveledUp now follows the **Living CV & Verified Outcomes** architecture:
> - **4 Active Navigation Tabs:** `Home`, `Scanner`, `Wins` (role-agnostic Brag Doc, Zero-Hallucination STAR bullets, Living CV merge + PDF export), and `Progress` (chronological ATS Score History with `✓ Fixed:` diffs, `"I got the job 🎉"` First 90 Days mode, `scan_verified` / `win_verified` / `self_reported` verified quests, and bilingual Skill Gap action plans).
> - **Current Sources of Truth:** See [`README.md`](README.md), [`AGENTS.md`](AGENTS.md), and [`backend/sql/schema.sql`](backend/sql/schema.sql) (8 active MySQL tables).
> - **Retired / Gated Legacy Components:** `QuestLogScreen`, `SkillTreeScreen`, `QuestCard`, `XpLevelBanner`, and `ScoreRingWidget` have been removed; `Daily Check-In` remains preserved behind `ApiConstants.enableDailyCheckIn = false`.

---

# LeveledUp Mobile — Master Product, UI/UX Design System & Technical Specification (MVP)

Comprehensive product specification, **UI/UX Design System (matched 1:1 to the official LeveledUp web reference)**, mobile architecture, backend REST API, and MySQL database schema for **LeveledUp Mobile**:
- **Mobile Frontend:** **Flutter (Dart)**
- **Backend API:** **Node.js (Express.js)**
- **Database:** **MySQL (XAMPP / phpMyAdmin compatible)**

---

## 1. Executive Summary & Product Vision

**LeveledUp Mobile** is an all-in-one **Global ATS CV Scanner, AI Resume Optimizer, and Gamified Career Companion** designed for ambitious Indonesian talents aiming to break into global, remote, or multinational companies (`From Indonesia → Break into Global Companies 🚀`).

Unlike single-use CV scanners that users abandon once hired, **LeveledUp** accompanies the user across two continuous career phases:

```
┌─────────────────────────────────────────┐       ┌──────────────────────────────────────────┐
│     PHASE 1: THE GLOBAL HUNT (PRE-JOB)  │       │   PHASE 2: CAREER COMPANION (POST-HIRE)  │
├─────────────────────────────────────────┤  ──►  ├──────────────────────────────────────────┤
│ • Global ATS CV Score (0–100)           │       │ • RPG Level, XP & Career Rank System     │
│ • Anti-Bias Audit (Photo, TTL, NIK)     │       │ • Post-Hire Quests (First 90 Days, KPIs) │
│ • 5-Pillar Diagnostic & Before/After    │       │ • Interactive Engineering Skill Tree     │
│ • Zero-Hallucination AI Resume Rewrite  │       │ • Quantified Achievement Logger for CV   │
└─────────────────────────────────────────┘       └──────────────────────────────────────────┘
```

---

## 2. Frontend UI/UX Design System & Theme Specification (LeveledUp Signature Theme)

### 2.1 Visual Identity & Aesthetic Direction (Matched 1:1 to Reference)
- **Aesthetic Persona:** Minimalist, ultra-clean **Obsidian Matte Dark (`#09090B`)** paired with **Warm Terracotta (`#B5462F`)** as the signature brand accent and **Crisp White (`#FAFAFA`)** + **Muted Zinc (`#A1A1AA`)** typography.
- **Brand Mark (`LeveledUp`):**
  - Rounded squircle icon (`#B5462F` fill) containing a clean white upward arrow (`↑`), followed by bold **`Leveled`** in `#FAFAFA` white and **`Up`** in `#B5462F` terracotta.
- **Signature Visual Elements:**
  - **Pill Announcement Badge:** Dark pill (`#141417` fill, `1px solid #27272A` border) with a glowing terracotta dot (`#B5462F`) and text: `"From Indonesia → Break into Global Companies 🚀"`.
  - **Two-Tone Hero Typography:** First line in pure white (`"Pass ATS"` in `#FAFAFA`), second/third lines in warm terracotta (`"before getting rejected."` in `#B5462F`) with a subtle radial terracotta ambient glow behind the hero canvas.
  - **Full-Pill Primary Buttons (`border-radius: 999px`):** Solid `#B5462F` terracotta fill with crisp `#FFFFFF` bold text (`"Scan CV — Free"`).
  - **Matte Charcoal Dropzone & Cards:** `#121215` surface with `1px solid #27272A` hairline border, subtle rounded icon square (`#1C1C21`), and monospace privacy caption (`"Not saved permanently · free analysis"`).
  - **Minimalist Metric Callouts:** Clean frameless bottom stats (`"Free"`, `"5+"`, `"< 30 sec"`) in bold `#FAFAFA` above muted `#71717A` descriptions.

### 2.2 Exact Color Palette & Token Specification

| Role / Token Name | Hex Code | Usage in UI |
| :--- | :--- | :--- |
| **Primary Background Canvas** | `#09090B` | Main app scaffold background (Matte Obsidian / Zinc 950). |
| **Ambient Hero Glow** | `#B5462F` (`8%` opacity) | Subtle radial gradient glow behind hero headline and upload card. |
| **Card / Dropzone Surface** | `#121215` | Main cards, PDF upload dropzone, and diagnostic issue containers. |
| **Elevated Pill / Icon Box Surface** | `#18181C` | Top announcement pill, icon square boxes (`[↑]`), and unselected filter chips (Zinc 900). |
| **Interactive / Hover Surface** | `#222227` | Secondary buttons, progress bar tracks, and input field backgrounds. |
| **Hairline Border** | `#27272A` | `1px` crisp borders on all cards, pills, and dividers (`rgba(255, 255, 255, 0.08)`). |
| **Primary Brand Accent (Terracotta)** | `#B5462F` | Primary pill CTA buttons (`Scan CV — Free`), brand logo `Up`, headline emphasis (`before getting rejected.`), and active indicators. |
| **Terracotta Bright / Highlight** | `#D0533A` | Active border glow, highlighted text accents, and XP progress fills. |
| **Text Primary (Crisp White)** | `#FAFAFA` | Primary headlines (`Pass ATS`), card titles, stat numbers (`Free`, `5+`, `< 30 sec`), and button labels. |
| **Text Secondary (Warm Zinc)** | `#A1A1AA` | Body paragraphs, card descriptions, and secondary action links (`See how it works →`). |
| **Text Muted / Monospace** | `#71717A` | Captions, sub-labels (`no account required`), and monospace privacy notes (`#52525B`). |

### 2.3 Semantic Status & Gamification Tokens
- **ATS Ready / Quest Complete (`80–100`):** `#10B981` (Emerald 500) with `#10B981` at `12%` background tint.
- **Needs Polish / Placeholder Highlight (`60–79`):** `#F59E0B` (Amber 500) with `#F59E0B` at `14%` background tint.
- **Needs Improvement (`40–59`):** `#B5462F` (Terracotta / Rust Orange).
- **Critical ATS Risk (`< 40`):** `#EF4444` (Red 500) with `#EF4444` at `12%` background tint.

### 2.4 Typography & Component Geometry
- **Primary Font:** `Poppins` (Geometric Sans-Serif — matched 1:1 to the reference UI)
  - Hero Headline & Metric Numbers: `Bold (700)` / `SemiBold (600)`, line-height `1.2`.
  - Section Titles & Card Headers: `SemiBold (600)` / `Bold (700)`.
  - Body Copy: `Regular (400)` / `Medium (500)` in `#A1A1AA`.
- **Monospace Font:** `JetBrains Mono` (used for `"Not saved permanently · free analysis"`, `[placeholder]` tags, `+XP` pills, and ATS score counters).
- **Corner Radii:**
  - Primary CTA Buttons & Top Announcement Badge: `999px` (Full Stadium Pill)
  - Upload Dropzone & Feature Cards: `18px`
  - Inner Icon Containers (`44x44`): `12px`

---

## 3. Screen-by-Screen UI/UX Specifications & Google Stitch Prompt

### 3.1 Screen 1: LeveledUp Hero & ATS Scanner (Matched to Reference Screenshot)
- **Top App Bar:**
  - Left: `#B5462F` rounded squircle icon with white `↑` arrow + **`Leveled`** (`#FAFAFA`) **`Up`** (`#B5462F`).
  - Right: Language pill (`ID / EN` in `#18181C` with `#27272A` border) + compact `#B5462F` pill badge (`Scan CV` / `LVL`).
- **Top Announcement Pill:**
  - Dark pill (`#141417`, border `#27272A`) with a small `#B5462F` dot + `"From Indonesia → Break into Global Companies 🚀"`.
- **Two-Tone Editorial Hero Headline:**
  - Line 1: **`Pass ATS`** in `#FAFAFA` (White, 34px ExtraBold).
  - Line 2–3: **`before getting rejected.`** in `#B5462F` (Terracotta, 34px ExtraBold).
- **Hero Subtitle:**
  - `"Tired of getting ghosted by recruiters? Your CV might be getting rejected by robots (ATS) before a human even sees it. LeveledUp diagnoses fatal flaws in your CV using international standards and helps you fix them in seconds."` in `#A1A1AA`.
- **Primary CTA Row:**
  - Full-pill `#B5462F` button **`Scan CV — Free`** + text link **`See how it works →`** in `#A1A1AA`.
- **PDF Dropzone Card:**
  - `#121215` matte card with `1px solid #27272A` border and subtle radial terracotta glow.
  - Centered `48x48` rounded square (`#1C1C21`, border `#27272A`) with upload tray icon (`↑` in `#A1A1AA`).
  - Title: **`Tap to upload CV (PDF) here`** in `#FAFAFA` Bold.
  - Subtitle: `"or try instant sample demo · max 4 MB"` in `#71717A`.
  - Monospace footer: `"Not saved permanently · free analysis"` in `JetBrains Mono` (`#52525B`).
- **3-Column Footer Metrics:**
  - **`Free`** (`no account required`) | **`5+`** (`ATS issue categories checked`) | **`< 30 sec`** (`instant results`).

---

### 3.2 Screen 2: ATS Diagnostic Results & AI Zero-Hallucination Rewrite
- **Score Ring Header Card (`#121215`, border `#27272A`):**
  - Circular Score Ring (`0–100`) + file name badge + executive summary + full-pill `#B5462F` CTA `"Unlock Full Fixes & AI Rewrite"`.
- **Role Keyword Benchmark Card:**
  - Matched keywords in subtle emerald pills; missing keywords gated in free preview or unlocked via VIP code (`LEVELEDUPVIP2026`).
- **Diagnostic Issue Cards:**
  - `#121215` surface, severity badge, category label, issue title in `#FAFAFA`, and Before (strikethrough red) vs After (emerald) comparison boxes.
- **AI Zero-Hallucination Resume Rewrite Viewer:**
  - Clean single-column English STAR resume preview on `#121215` card where missing metrics are highlighted in bracketed `[placeholder]` amber pills.

---

### 3.3 Screen 3 & 4: Gamified Career Companion (Command Hub, Quests & Skill Tree)
- **Player Level & XP Card (`#121215` with `#B5462F` terracotta accent border):**
  - Level badge (`LVL 2` in `#B5462F` squircle), Rank title, `#B5462F` XP progress bar, streak counter, and **Career Stage Switcher** (*Phase 1: Global Hunt* $\rightarrow$ *Phase 2: First 90 Days Hired* $\rightarrow$ *Phase 3: Mid-Level* $\rightarrow$ *Phase 4: Senior Track*).
- **Career Quest Log:**
  - Pill stage filters (active pill in `#B5462F` terracotta with `#FFFFFF` text), checklist quest cards in `#121215` with `+XP` badges, and a full-pill `+ New Work Quest` button.
- **RPG Skill Tree & Badges:**
  - 2-column badge grid and competency cards (*Technical Craft*, *System Architecture*, *Leadership*, *Global Ops*) with `#B5462F` mastery progress bars.

---

### 3.4 Ready-to-Use Prompt for Google Stitch Design AI

> **Copy and paste this prompt into Google Stitch Design AI (alongside the reference image or `mvp.md`):**
>
> *"Design a mobile app UI/UX for **LeveledUp**—an International ATS CV Scanner, AI Resume Optimizer, and Gamified Career Companion app—matching the exact dark terracotta aesthetic of the LeveledUp web reference. Use **Matte Obsidian Black (`#09090B`)** as the main background canvas with a subtle radial terracotta glow (`rgba(181, 70, 47, 0.08)`), **Dark Matte Charcoal (`#121215` and `#18181C`)** for cards and pill containers with crisp `1px` borders (`#27272A`), **Warm Terracotta (`#B5462F`)** as the primary accent color (for the `LeveledUp` logo, the two-tone hero headline `'before getting rejected.'`, full-pill primary CTA buttons `'Scan CV — Free'`, XP progress bars, and active filter pills), **Crisp White (`#FAFAFA`)** for primary titles/numbers, and **Warm Zinc (`#A1A1AA` / `#71717A`)** for body copy and captions. Use `Plus Jakarta Sans` for headings/UI and `JetBrains Mono` for metadata (`'Not saved permanently · free analysis'`), ATS scores, and `[placeholder]` badges. Generate 4 mobile screens: (1) LeveledUp Hero & PDF Scanner with the `'From Indonesia → Break into Global Companies 🚀'` pill badge, two-tone headline, `#121215` upload dropzone card, and `'Free / 5+ / < 30 sec'` footer stats; (2) ATS Diagnostic Results & AI Zero-Hallucination Resume Rewrite viewer; (3) Gamified Career Companion Hub & Quest Log with stage pills (`Job Hunt`, `First 90 Days`, `Mid-Level`, `Senior Track`); and (4) RPG Skill Tree & Achievement Badges."*

---

## 4. Domain Analysis Rules (5 Global ATS Pillars)

| Pillar | Category ID | Detected Issues | Why It Fails Globally |
| :--- | :--- | :--- | :--- |
| **Personal Info Bias** | `personal_info` | Headshot photo, date/place of birth (TTL), age, marital status, religion, gender, National ID (NIK/KTP), blood type, height/weight, hobbies. | In US/UK/EU/CA, including demographic data triggers strict anti-discrimination (EEOC) liability. Resumes with photos are frequently auto-discarded. |
| **ATS Readability** | `ats_readability` | Complex tables, overlapping multi-column layouts, graphic headers/footers, unconventional fonts. | ATS parsers read top-to-bottom, left-to-right. Multi-column tables scramble job titles and dates. |
| **Keyword Match** | `keyword_match` | Missing core technical skills or industry-standard keywords for the inferred target role. | ATS algorithms rank applicants by keyword match percentage before a human recruiter reviews the file. |
| **Quantified Impact** | `achievements` | Passive duty descriptions (*"Bertanggung jawab atas..."*, *"Responsible for..."*) lacking metrics. | Global resumes require the **STAR pattern** (*Strong Action Verb + Context + Quantified Metric*). |
| **English Quality** | `language_quality` | Indonesian text in global applications, stiff literal translations, clichés (*"hard-working"*, *"under pressure"*). | For international/remote roles, your resume is the primary proof of fluent professional English communication. |

### 4.1 Golden Rule: Anti-Fabrication / Zero-Hallucination Policy
- AI **NEVER** invents numbers or metrics. Missing metrics are always rendered as bracketed placeholders (`[X]%`, `[team size]`).

### 4.2 Rule-Based Penalty Scoring Formula
- Starting Score: `100` | `critical`: `-11` | `warning`: `-7` | `suggestion`: `-3` | Minimum score: `10`.

---

## 5. Technical Architecture & MySQL Database Schema

- **Backend API (`backend/`):** Node.js Express (`POST /api/parse`, `POST /api/analyze`, `POST /api/unlock`, `POST /api/rewrite`).
- **Database (`backend/sql/schema.sql`):** MySQL tables `scans`, `scan_issues`, `scan_keywords`, `scan_rewrites`, and `access_codes` (default VIP code: `LEVELEDUPVIP2026`).
