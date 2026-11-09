# LeveledUp Mobile — Flutter Frontend (ATS Scanner & RPG Career Companion)

Mobile frontend built with **Flutter & Riverpod**, implementing both the **Global ATS CV Scanner & AI Optimizer** from [mvp.md](../mvp.md) and the **Gamified Career Companion** for post-hire progression.

---

## 🎨 Palette & Design System
- **Primary Canvas:** `#020617` (`AppColors.background` — Deep Midnight Slate-950)
- **Primary Contrast & Typography:** `#FFFFFF` (`AppColors.white`)
- **Elevated Surfaces:** `#0B1120` & `#0F172A` with `10%–20%` white borders
- **Gamified Accents:**
  - **Electric Cyan (`#38BDF8`):** Active scanner radar, tech skills, role benchmarks
  - **Level-Up Gold (`#F59E0B` / `#FBBF24`):** XP progress bars, level shield, VIP unlock badges
  - **Emerald (`#10B981`):** Completed quests, matched keywords, 80+ ATS readiness
  - **Crimson (`#F43F5E`):** Critical ATS bias risks

---

## 📱 Core Modules & Screens

1. **Command Hub (`HomeDashboardScreen`)**
   - Player Level Shield, Rank Title (`Aspiring Global Talent` $\rightarrow$ `Global Principal Architect`), Streak Counter, and animated XP progress bar.
   - **Career Phase Switcher**:
     - *Phase 1: Global Job Hunt*
     - *Phase 2: First 90 Days (Hired!)*
     - *Phase 3: High-Impact Contributor*
     - *Phase 4: Senior & Tech Lead Track*
2. **Global ATS Scanner (`ScannerScreen`)**
   - Upload any `.pdf` file ($\le 4\text{ MB}$) via `file_picker` or run the **1-Tap Instant Demo Scan**.
   - Custom `ScoreRingWidget` (`CustomPainter`), 5 Global ATS Pillars breakdown, and Keyword Match benchmark.
   - **VIP Unlock Dialog** (Default MVP promo code: `LEVELEDUPVIP2026`) awarding `+120 XP`.
   - **AI Zero-Hallucination Resume Rewrite** highlighting `[placeholder]` metrics in glowing amber via `PlaceholderRichText`, plus 1-tap Markdown copy & native share sheet (`share_plus`).
3. **Career Quest Log (`QuestLogScreen`)**
   - Pre-loaded career quests for every career stage + ability to **Create Custom Work Quests** (turn your real sprint deliverables and KPIs into XP milestones).
4. **RPG Skill Tree & Trophies (`SkillTreeScreen`)**
   - 4 Skill Branches (`Technical Craft`, `System Architecture`, `Leadership & Impact`, `Global Career Ops`) with multi-tier upgrades.
   - Unlockable Achievement Badges (`Vanguard Initiate`, `ATS Challenger`, `Zero-Bias Architect`, `STAR Storyteller`, `Offer Secured`, `High-Impact Vanguard`).

---

## 🚀 Getting Started

If generating platform runner folders (`android/`, `ios/`, `web/`, `windows/`) for the first time on your machine:

```bash
cd mobile
flutter create .
flutter pub get
flutter run
```

