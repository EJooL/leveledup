# LeveledUp — ATS CV Scanner & Living-CV Career Companion

**LeveledUp** is an AI-powered career companion built for Indonesian fresh graduates and early-career professionals across diverse fields — including **Data Analytics, Digital Marketing, Accounting & Finance, UI/UX Design, Product Management, Human Resources, and Software Engineering**.

Unlike one-off resume checkers that you abandon once you submit an application, **LeveledUp treats your CV as a living document**:

```text
Scan CV (PDF) ──► Fix ATS Flaws & Skill Gaps ──► "I got the job" (First 90 Days)
      ▲                                                        │
      │                                                        ▼
Export Updated PDF ◄── Merge STAR Bullets ("Add to my CV") ◄── Log Win (Brag Doc)
```

Every feature inside the app is tied to a real-world outcome: a higher ATS score verified across scans, clear actions for missing role skills, documented achievements ready for performance reviews, and an up-to-date `.pdf` resume you can export in one tap.

---

## Key Features & How to Use LeveledUp

### 1. Home (`Home` Tab)
Your daily command center shows:
- **Latest ATS Score** and current mode (**Job Hunt Mode** or **Hired · First 90 Days**)
- **Next Best Action** based on your actual scan and checklist progress
- **Checklist Progress** (e.g., `3 of 6 done`) and **Score Timeline** summary
- **Quick Actions**: `Scan CV`, `Log Win`, `Skill Gap`, and **`Got the Job`**

---

### 2. AI ATS CV Scanner (`Scanner` Tab)
1. **Upload Your CV (`.pdf`, max 4 MB)** or try the built-in **Demo CV (Indo / English)** buttons.
2. **Real Photo & Personal Bias Audit**: Checks actual embedded images in your PDF (without false positives on words like "image" or "photo") alongside Date/Place of Birth (TTL), Age, Religion, Marital Status, and NIK/KTP.
3. **Bilingual Evaluation (`ID` / `EN`)**: Automatically detects your CV language and audits 5 pillars:
   - Personal Info Bias (EEOC compliance)
   - ATS Readability
   - Role Keyword Match
   - Quantified Impact (STAR Method)
   - Language Quality & Clichés
4. **Unlock Full Fixes (`LEVELEDUPVIP2026`)**: Reveals detailed explanations, concrete fixes, Before/After examples, and all missing role keywords.
5. **AI Rewrite & Local PDF Export**: Converts passive job duties into structured **STAR achievement bullets**, highlights missing metrics using **`[placeholder]`** tags, and exports a clean single-column `.pdf` directly to your device.

> **Zero-Hallucination Guarantee:** LeveledUp **never** invents numbers, company names, or achievements you did not provide. Whenever a metric is missing, you will see highlighted markers such as `[X]%` or `[number]` so you can fill in your real results before sending your CV.

---

### 3. Brag Doc & Living CV (`Wins` Tab)
Built for **both** job seekers (projects, internships, campus leadership) and employed users building their career record:
1. **Log a Win**: Enter what you achieved, an optional measurable metric, and pick a role-agnostic category (*Project & Delivery*, *Metrics & Growth*, *Process & Quality*, or *Leadership & Teamwork*).
2. **Instant STAR Bullet Conversion**: Gemini (with bilingual `ID`/`EN` rule-based fallback) turns your note into a polished STAR resume bullet — using `[placeholder]` tags if no metric was provided.
3. **Add to My CV & Export PDF**: Select one or more saved wins, tap **`Add Selected to My CV`**, and download your updated **Living CV (`.pdf`)** immediately via **`Download Updated PDF CV (.pdf)`**.

---

### 4. Verified Progress, Score History & Skill Gap (`Progress` Tab)
- **ATS Score History (`54 -> 71 -> 82`)**: Tracks every scan over time and shows exactly how many points you gained plus which flaws were resolved (`✓ Fixed: ...`) between versions.
- **Verified Job-Hunt Checklist (`X of Y done`)**:
  - **`Verified by Scan`**: Tasks like *Run Your First ATS Scan*, *Purge Personal Bias Data*, and flaw-specific quests (e.g., *Add measurable results to 3 bullets*) cannot be checked off manually — they auto-complete only when a re-scan proves the issue is fixed.
  - **`Self-reported`**: Supporting tasks (e.g., updating your LinkedIn headline, showcasing 3 portfolio projects, sending 5 applications) can be checked off manually or expanded via **Add Self-Reported Goal**.
- **Role-Agnostic Skill Gap**: Replaces generic skill trees with concrete action steps for missing keywords in your target role (covering *Data Analyst*, *Digital Marketing Specialist*, *Accounting & Finance Associate*, *UI/UX Designer*, *Product Manager*, *Human Resources & People Ops*, *Software Engineer*, and *Mobile Developer*), complete with copyable sample STAR bullets in English or Bahasa Indonesia.
- **Got the Job? Switch Modes in One Tap**: Tap **`I got the job`** on **Home** or **Progress** to activate your **First 90 Days Onboarding Checklist** (*meet manager & define 30/60/90 goals, document first deliverable, log & merge your first work win into your living CV, request 30-day feedback*).

---

## Quick Start (Running Locally)

### Prerequisites
- **Node.js** (v18+ recommended)
- **MySQL** (e.g., XAMPP / MySQL Server running on `localhost:3306`)
- **Flutter SDK** (`^3.5.0`) + Chrome (for Web) or Android/iOS emulator
- *(Optional)* A **Gemini API Key** from [Google AI Studio](https://aistudio.google.com/) (if omitted or offline, the backend automatically uses deterministic bilingual rule-based fallbacks)

### 1. Backend Setup (`backend/`)
```bash
cd backend
npm install

# Configure environment variables
cp .env.example .env
# Edit .env if needed (DB_HOST, DB_USER, DB_PASSWORD, GEMINI_API_KEY)

# Initialize/sync all 8 MySQL tables in leveledup_db (starts XAMPP MySQL first)
npm run init-db

# Verify all 96 automated API, MySQL & AI guardrail assertions pass
npm test

# Start the API server on http://localhost:5000
npm run dev
```

### 2. App Setup (`mobile/`)
```bash
cd mobile
flutter pub get
flutter analyze
flutter run -d chrome
```

> **Note:** On Android Emulator, [ApiConstants](mobile/lib/core/constants/api_constants.dart) automatically routes API traffic to `http://10.0.2.2:5000`. On Web/Desktop, it uses `http://localhost:5000`. Use VIP test code **`LEVELEDUPVIP2026`** in the Scanner unlock modal to test premium diagnostics and AI CV rewrite.

---

## Project Architecture & Technical Reference

| Component | Stack / Details |
| :--- | :--- |
| **Frontend** | Flutter, Riverpod (`flutter_riverpod`), Dio, Google Fonts (`Poppins`, `JetBrains Mono`), Pure-Dart PDF 1.4 Generator |
| **Backend** | Node.js, Express, `unpdf` (text + page-1 embedded photo detection), `@google/genai` (`gemini-2.5-flash`) with zero-hallucination guardrails & bilingual validation, AES-256-GCM token encryption |
| **Database** | MySQL (`leveledup_db`) — 8 tables defined in [backend/sql/schema.sql](backend/sql/schema.sql) |
| **Identity** | Zero-friction device-scoped UUID (`x-device-id` header stored via `SharedPreferences`) implemented in [ApiClient](mobile/lib/core/network/api_client.dart) |

<details>
<summary><strong>MySQL Tables & Backend REST Endpoints Reference</strong></summary>

### MySQL Tables (`leveledup_db`)
1. `scans` — ATS scan metadata, score, and encrypted token (`device_id` indexed)
2. `scan_issues` — Detected ATS flaws per scan (`issue_key`, `category`, `severity`, `detail`, `fix`, Before/After rewrites)
3. `scan_keywords` — Target role (`job_title`), matched keywords, and missing keywords
4. `scan_rewrites` — Saved AI-rewritten and Living-CV merged resumes
5. `access_codes` — VIP promo codes (`LEVELEDUPVIP2026`)
6. `career_profiles` — Mode state (`job_hunt` / `hired`), target role, `hired_at`, `last_win_logged_at`
7. `work_wins` — Brag Doc achievements, categories, languages, Zero-Hallucination STAR bullets, merge status
8. `career_quests` — `scan_verified`, `win_verified`, and `self_reported` checklist items

### REST Endpoints (`http://localhost:5000`)
- `GET /api/health` — API health, MySQL status, and Gemini status
- `POST /api/parse` — In-memory PDF text and embedded photo extraction
- `POST /api/analyze` — 5-pillar bilingual (`id`/`en`) ATS analysis
- `POST /api/unlock` — VIP code validation & AES-256-GCM decryption
- `POST /api/rewrite` — Zero-Hallucination STAR resume rewrite
- `GET /api/wins` — List Brag Doc wins & 90-day reminder flag
- `POST /api/wins` — Log an achievement and generate a STAR bullet
- `POST /api/wins/merge-cv` — Merge selected STAR bullets into Living CV (`scan_rewrites`)
- `GET /api/progress` — Chronological score timeline (`fixedIssues` diffs), verified quests, and Skill Gap actions
- `POST /api/progress/quest-toggle` — Toggle `self_reported` quests (`scan_verified`/`win_verified` reject manual toggles)
- `POST /api/progress/mode` — Switch between `job_hunt` and `hired` (First 90 Days)

</details>
