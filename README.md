# FinMate — Personal Finance Manager (Flutter, 100% Offline)

## 1. Getting an installable APK — two ways

### A) Zero local setup — GitHub Actions (recommended)
1. Create a new **public or private** GitHub repo and push this entire
   folder to it (including `.github/workflows/build-apk.yml`).
2. Go to the repo's **Actions** tab — a "Build APK" run starts
   automatically. It scaffolds the Android platform files, generates the
   database code, and builds a release APK, all in GitHub's cloud.
3. When it finishes (green check), open the run → **Artifacts** →
   download `finmate-release-apk` → unzip it → you have `app-release.apk`.
4. Copy that APK to your phone (email/Drive/USB) and tap it to install.
   You'll need to allow "Install unknown apps" for whichever app you used
   to open the file (Settings → Apps → Special access → Install unknown
   apps) — that's a one-time Android setting, not something wrong with
   the app.

This needs nothing installed on your computer except a way to `git push`.

### B) Locally, with Flutter installed
```bash
cd finmate
flutter create --org com.finmate --project-name finmate .
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter build apk --release
# APK is at build/app/outputs/flutter-apk/app-release.apk
```
Or `flutter run` with your phone plugged in (USB debugging on) for a
live debug build instead of a standalone APK.

### Android manifest additions (needed either way)
The CI workflow patches these automatically. If you're building locally,
add inside `<manifest>` in `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.USE_BIOMETRIC"/>
<uses-permission android:name="android.permission.CAMERA"/>
```
And set `minSdkVersion 23` in `android/app/build.gradle` (required by
`local_auth` and `sqlite3_flutter_libs`).

## 2. Architecture

Clean Architecture / MVVM, Repository Pattern, Riverpod for DI + state,
GoRouter for navigation:
```
lib/
  core/        constants, theme, routing, reusable widgets, DI, error types
  data/        Drift database (tables + DAOs), repositories, services, models
  presentation/  one folder per feature/screen
```

**Database (Drift/SQLite)** — Transactions, Categories, Budgets,
Subscriptions, SavingsGoals, FutureExpenses, Debts. Indexed on
date/category/type/dedupe-hash for smooth performance at 100k+ rows.

## 3. Everything currently working

- Splash → Onboarding (slides + quick setup) → Dashboard. Login screen
  skipped by design — PIN/biometric lock covers security instead.
- **Dashboard**: real-time balance (today-only, doesn't include
  future-dated entries), income/expense, month trend chart, quick
  actions, Financial Health Score, budget progress, upcoming
  bills/subscriptions, recent transactions.
- **Add Expense/Income**: editable category templates, dynamic note
  prompt, date/time/payment method, **Repeat** picker (specific dates or
  "weekdays in range") that bulk-creates transactions — e.g. "₹10 for
  milk, every weekday, next 4 weeks."
- **Transactions**: search, filters, sort, swipe-to-delete with undo,
  edit/duplicate/delete from detail view.
- **Statement Import**: PDF/CSV/XLSX/TXT file import *or* **camera scan**
  of a paper statement (on-device OCR via Google ML Kit) → generic
  parser with light bank-name detection (SBI/HDFC/ICICI/Axis/Kotak/PNB/
  BoB) → AI-suggested categorization → duplicate detection → review &
  confirm import.
- **Analytics**: pie/bar charts, category breakdown, daily trend, key
  insights.
- **Subscriptions, Budget Goals, Savings Goals**: full CRUD + progress.
- **Future Planner**: projected balance chart (60 days) combining real
  future-dated transactions, planned purchases, and subscription
  renewals, plus a rule-based "Safe to Buy / Not Recommended" verdict.
- **Borrow & Lend**: track money borrowed/lent per person, settle with an
  optional linked transaction.
- **Insights**: rule-based Financial Health Score breakdown + on-demand
  "Analyze Spending" (never runs automatically or in the background).
- **Category Management**: add/delete templates, separated by
  Expense/Income.
- **Bulk Delete**: by day/week/month/custom range/category/source/type,
  or everything — each with a confirmation step.
- **Backup & Restore**: exports every table to its own JSON file
  (`finmate_transactions.json`, `finmate_categories.json`, etc.) into a
  folder you choose via the system file picker; Restore reads the same
  files back in. PIN/biometric secrets are deliberately excluded from
  backups — they never leave secure device storage.
- **PIN & Biometric App Lock**: set a PIN in Settings, optionally enable
  biometric, choose a re-lock timeout (Immediately / 1 min / 5 min /
  Never). A lock screen overlays the app on cold start and on resume
  after the timeout.
- **Background reminders (WorkManager)**: a lightweight check every 12
  hours for budget overruns (≥90%), subscriptions renewing within 3 days,
  weekly savings-goal nudges, and future-expense reminders — independent
  of the AI toggle, and the only background work FinMate ever does.
- **Settings**: Dark Mode, AI toggle, Security section, notification
  toggles, CSV/Excel/PDF export.
- Profile + navigation drawer + bottom nav (Home / Transactions / Planner
  / Profile, with a center Add-Expense FAB).

## 4. Decisions worth knowing about

- **Database:** Drift (SQLite) instead of Isar — fully open source.
- **AI:** Rule-based only (keyword categorization, month-over-month spend
  comparison, deterministic Financial Health Score). Only runs on
  explicit button taps, gated fully by the Settings toggle.
- **Charts:** FL Chart (MIT-licensed) instead of Syncfusion, to honor the
  "fully open source, $0 budget" constraint.
- **Bank-specific parsing — an honest caveat:** rather than fabricate
  fixed-column parsers for SBI/HDFC/ICICI/Axis that I couldn't validate
  against real statement samples (and which could silently produce wrong
  amounts/dates if wrong), I built one robust generic parser with fuzzy
  column matching plus bank-name detection/tagging. It handles the
  common statement layouts well; if a specific bank's format doesn't
  parse cleanly, send a sample (with numbers redacted) and I'll tune the
  patterns against it directly rather than guessing.
- **Balance vs. projection:** "Current Balance" only counts transactions
  up to today. Future-dated entries (scheduled repeats, planned income)
  feed the separate Future Planner projection chart instead.

## 5. Still open (smaller items)

- PIN/biometric lock currently guards app foreground/resume; it doesn't
  yet gate individual sensitive actions (e.g. viewing/export) separately.
- Multi-language (English-only for now, but `intl` is already in use so
  adding `.arb` files later is straightforward).
- Visual polish pass: empty/loading states everywhere, dark-mode contrast
  check, a real app icon/splash asset (currently a placeholder icon).
- Onboarding doesn't yet offer "create first budget" — quick setup covers
  currency + starting balance + a pointer to PIN setup in Settings.

Tell me what to prioritize next and I'll keep building on this same
foundation without breaking anything already in place.

