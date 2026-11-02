# Multi-Level 2D Mobile Game (Game Developer Internship — Week 4 Major Capstone)

A production-ready cross-platform 2D Mobile Game built with **Flutter** and the **Flame Engine**. Features 3 progressive levels, enemy AI behaviors, power-ups (invincibility shield & 2x score multiplier), persistent high-score saving via `shared_preferences`, lives management system, sound effects, and Play Store APK packaging readiness[cite: 29].

---

## 📌 Features & System Architecture

- **3 Progressive Levels:** Environment-specific platform layouts and scaling difficulty[cite: 29].
- **Power-Up System:**
  - 🛡️ **Shield Power-Up:** Grants 5 seconds of invincibility[cite: 29].
  - ⚡ **2X Multiplier:** Doubles point yield for 8 seconds[cite: 29].
- **High Score Persistence:** Stores player high scores locally across sessions using `shared_preferences`[cite: 29].
- **Play Store Packaging:** Release APK compilation pipeline configuration (`flutter build apk --release`)[cite: 29].

---

## 🚀 How to Run & Build

1. **Install Dependencies:**
   ```bash
   flutter pub get
   ```
