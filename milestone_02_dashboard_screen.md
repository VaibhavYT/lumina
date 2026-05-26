# Milestone 2 — Dashboard Screen (The Soul of the App)

---

## Agent Context

You are a world-class Flutter engineer and product designer with 40 years of combined experience building premium consumer applications. You have already completed Milestone 1 — the design system, theme engine, app shell, and navigation are all in place. Every color, typography token, spacing constant, and reusable widget exists and is working. You do not redefine any of those. You build on top of them.

This milestone is the **most important screen** in the entire app. The Dashboard is the first thing users see every time they open Lumina. It must feel like opening a premium journal that already knows you. It must feel warm, personal, and intelligent — not like a productivity dashboard, but like a morning conversation with a mentor who cares about your growth.

---

## Milestone 2 Objective

Build the **Dashboard Screen** — a beautiful, animated home screen that greets the user, shows today's context at a glance, surfaces the AI mentor's most recent insight, and gives immediate entry points into logging and checking in.

---

## 1. Screen Architecture

The Dashboard is a `CustomScrollView` with `SliverList` children. Do not use a `ListView` — the `CustomScrollView` is required for the collapsing header behavior and smooth performance with many cards.

The screen has these sections, top to bottom:

1. **Greeting Header** (collapsing SliverAppBar behavior)
2. **Today's Snapshot Row** (3 quick-stat chips)
3. **AI Mentor Card** (most prominent card — the intelligence heart)
4. **Today's Focus** (today's top 3 tasks)
5. **Mood & Energy Check-In Banner** (conditional — only shows if user hasn't logged today)
6. **Habit Rings Row** (horizontal scrollable habit progress rings)
7. **Recent Patterns Teaser** (mini insight card, taps into Insights screen)
8. **Bottom spacer** (for bottom nav bar clearance)

---

## 2. Greeting Header

### 2.1 Structure
A collapsing `SliverAppBar` with:
- `expandedHeight`: 160dp
- `pinned`: true
- `backgroundColor`: transparent
- `flexibleSpace`: `FlexibleSpaceBar` with custom content

### 2.2 Visual Design
**Collapsed state:** Shows "Good Morning, [Name]" in `headingMedium` centered, with a small amber sparkle icon to the left. Background becomes the app's `backgroundSecondary` color with the blur effect.

**Expanded state (default):**
- Top right: A small circular avatar/initials badge (32dp) in amber, showing user's first initial — tappable, navigates to Settings
- Time-aware greeting in `displayLarge`:
  - 5am–12pm: "Good Morning" + a soft sun Lottie animation (16dp, plays once)
  - 12pm–6pm: "Good Afternoon"
  - 6pm–10pm: "Good Evening"
  - 10pm–5am: "Late Night, [Name]" (more personal, intimate)
- Below the greeting, a dynamic subtitle in `bodyMedium` in `textSecondary`:
  - If no log today: "How's your day shaping up?"
  - If logged mood: "You're feeling [mood] today — let's make it count."
  - If all tasks done: "All tasks done. Strong day. 🔥"
  - These strings are stored in a `DashboardGreetingService` that reads from local storage
- The date displayed in `labelSmall` `textTertiary` format: "Tuesday, 27 May"

### 2.3 Background Decoration
In the expanded state, the header's background shows a **very subtle radial gradient** — amber at 4% opacity radiating from the top-right corner, fading to transparent. This creates a warm, alive feel without being garish. It responds to theme: in light mode the gradient is amber at 6%, in dark mode at 4%.

### 2.4 Entry Animation
On first mount, the greeting text fades in and slides up 16dp over 600ms with `easeOutCubic`. The subtitle appears 100ms later with the same motion. Use `flutter_animate` for this.

---

## 3. Today's Snapshot Row

A horizontal row of 3 compact stat chips, no scrolling needed, evenly spaced:

**Chip 1 — Tasks**
- Icon: checkmark circle (Phosphor)
- Value: `3/5` (completed / total today)
- Label: "Tasks"
- Color: success green when all done, textSecondary otherwise

**Chip 2 — Mood**
- Icon: smiley face (Phosphor, appropriate variant)
- Value: user's logged mood emoji or "—" if not logged
- Label: "Mood"
- Color: secondaryAccent

**Chip 3 — Streak**
- Icon: flame (Phosphor)
- Value: `12 days` (daily log streak)
- Label: "Streak"
- Color: amber/primaryAccent when streak > 0

**Chip Design:**
- Each chip is a `LuminaCard` with reduced padding (10dp horizontal, 12dp vertical)
- Chips appear with a staggered entrance: chip 1 at 0ms delay, chip 2 at 80ms, chip 3 at 160ms — all fade + scale from 0.92
- Values use `AnimatedCounter` for number changes

---

## 4. AI Mentor Card

This is the **crown jewel** of the dashboard. It must look premium, feel intelligent, and be the user's first reason to trust the app.

### 4.1 Visual Design
- Full-width card with `AppRadius.radiusXl` (24dp)
- In dark mode: a subtle gradient border — a 1px border with a `LinearGradient` from amber (40% opacity) to indigo (20% opacity), achieved using a `DecoratedBox` wrapper with a `Gradient` border trick
- Background: `backgroundCard` with a very subtle amber shimmer overlay (4% opacity amber linear gradient top-left to bottom-right)
- A small glowing amber sparkle icon (24dp) in the top-left of the card, with a soft 12dp amber glow (`BoxShadow` in amber at 40% opacity, blur 20dp)

### 4.2 Content States

**State A — No AI insight yet (new user or first day):**
- Headline: "Your mentor is getting to know you" in `headingMedium`
- Body: "Log your first day to unlock personalized insights." in `bodyMedium` `textSecondary`
- CTA button: "Start Today's Log" — uses `LuminaButton`

**State B — AI insight available:**
- Small label above: "Mentor Insight" in `labelSmall` with the amber sparkle icon, amber colored
- Insight headline (1 line): e.g., "Your energy peaks on Tuesday mornings" — `headingMedium`
- Insight body (2-3 lines): The actual Gemini-generated insight text — `bodyMedium` `textSecondary`
- Bottom row: "See full analysis →" text button in amber, aligned right

**State C — Loading (fetching AI insight):**
- Show `ShimmerLoader` blocks matching the shape of State B content
- Animate with the shimmer sweep

### 4.3 Entrance Animation
The mentor card enters with a slight scale animation from 0.95 → 1.0 and fade-in over 400ms, with a 200ms delay after the snapshot row. This gives the impression the card is "materializing."

---

## 5. Today's Focus (Task List)

### 5.1 Section Header
- Left: "Today's Focus" in `headingMedium`
- Right: "Add +" text button in amber (taps to log screen, pre-filtered to task entry)

### 5.2 Task Items
Each task is its own card, stacked vertically with 8dp gap. Each card contains:

- Left: A circular checkbox. Unchecked: 22dp circle with `divider` colored border. Checked: amber filled circle with a white checkmark icon (animated — the checkmark draws in with a path animation over 200ms when tapped)
- Center: Task title in `bodyLarge`. When completed, title gets a strikethrough that animates in from left to right (use `AnimatedDefaultTextStyle` or a custom `CustomPainter` strikethrough approach)
- Right (optional): A small priority dot — amber for high, textTertiary for normal
- Long press on any task shows a context menu: Edit, Delete, Move to Tomorrow

**Completion animation sequence:**
1. Checkmark draws in (200ms)
2. Strikethrough sweeps across the text (150ms delay, 200ms duration)
3. Card background briefly flashes success green at 10% opacity (150ms, fades out)
4. Haptic: `HapticUtils.success()`
5. After 600ms, the task card gracefully collapses (height animates to 0) if a "hide completed" setting is enabled

**Empty state:**
If no tasks today: a small centered illustration (use a simple SVG or Lottie asset — a minimalist outline of a notepad) with "No tasks yet. A focused day starts here." in `bodyMedium` `textSecondary` centered.

Show maximum 3 tasks on dashboard. If more, show "2 more tasks →" link at the bottom.

---

## 6. Mood & Energy Check-In Banner

Only render this section if the user has not logged mood today. Once logged, this section disappears with a collapse animation.

**Design:**
- A horizontal banner (not a full card — a shorter, 72dp-height pill-shaped container)
- Left side: Two emoji-like icons side by side — a face icon (mood) and a lightning bolt (energy), in secondaryAccent color
- Center text: "How are you feeling right now?" in `bodyMedium`
- Right side: Amber arrow button (chevron right icon, 32dp circle background)
- Tapping anywhere on the banner navigates to the Log screen, pre-scrolled to the mood/energy entry section
- The banner pulses once with a very subtle amber glow animation (scale 1.0 → 1.015 → 1.0, duration 2 seconds, looping) to draw attention

---

## 7. Habit Rings Row

A horizontally scrollable row of circular progress rings, one per tracked habit.

### 7.1 Ring Widget — `HabitRingWidget`
Build this as a standalone `StatelessWidget` using `CustomPainter`:
- Outer ring: thin (3dp stroke) `textTertiary` colored background arc (full 360°)
- Inner progress ring: same 3dp stroke, colored with the habit's assigned color, sweeps from top (270°) clockwise based on completion percentage
- The ring does NOT use `CircularProgressIndicator` — it is a custom painted arc with rounded stroke caps
- Center: The habit's emoji (24dp) or icon
- Below the ring: Habit name in `labelSmall` `textSecondary`, centered, max 2 lines
- Ring size: 64dp total diameter

### 7.2 Row Layout
- `ListView.builder` horizontal, `scrollDirection: Axis.horizontal`
- Each ring item is 80dp wide, with 12dp gap between items
- First item gets 20dp left padding (page padding), last item gets 20dp right padding
- Show up to 8 habits; if more, the last ring is a `+N more` ring

### 7.3 Entrance Animation
Rings animate in with a staggered delay (60ms per ring): each ring fades in and slides up 12dp. The progress arc itself animates from 0 to its actual value over 800ms with `easeOutCubic` when the screen loads — this is one of the most satisfying animations in the app.

---

## 8. Recent Patterns Teaser

A compact card at the bottom of the scroll:

- Left: "This Week" label in `labelSmall` amber
- Headline: A one-liner insight, e.g., "Your mood drops on Wednesdays" — `bodyLarge`
- Below: A tiny 5-day mini bar chart (Mon–Fri or the last 5 days) using `CustomPainter` — 5 bars, 6dp wide each, 4dp gap, height proportional to mood score (1–5). Bars use secondaryAccent color, with the lowest bar highlighted in `warningColor`.
- Right: Chevron right icon, taps to Insights screen

---

## 9. Pull-to-Refresh

Implement pull-to-refresh using `RefreshIndicator`:
- Custom color: amber
- On refresh: re-fetch AI mentor insight from local cache (Supabase fetch happens in background silently)
- Show a brief toast/snackbar on complete: "Updated ✓" — styled per `SnackBarTheme`

---

## 10. Data Layer for Dashboard

Create `DashboardRepository` and `DashboardNotifier` (Riverpod `AsyncNotifierProvider`):

**Local data (from Hive/Isar):**
- `getTodaysTasks()` — returns list of today's `Task` models
- `getTodaysMoodEntry()` — returns `MoodEntry?` for today
- `getCurrentStreak()` — returns int
- `getTodaysHabitProgress()` — returns list of `HabitProgress` models

**Models to define (Hive-annotated):**
```
Task { id, title, isCompleted, priority, dueDate, createdAt }
MoodEntry { id, mood (1-5), energy (1-5), note, timestamp }
HabitProgress { habitId, name, emoji, color, completedToday, targetPerDay }
MentorInsight { id, headline, body, generatedAt }
```

All models are stored locally (Hive boxes). Supabase sync happens in the background and is handled in Milestone 4. For now, data is written and read from local storage only.

---

## 11. Scroll Performance

- Use `const` constructors wherever possible
- All `CustomPainter` widgets must implement `shouldRepaint` returning `false` when data hasn't changed
- Use `RepaintBoundary` around the habit rings row and the mini bar chart
- The `CustomScrollView` must maintain 60fps on a mid-range Android device

---

## 12. Deliverables for This Milestone

By the end of Milestone 2:

1. Dashboard screen renders all 7 sections correctly in both light and dark modes
2. Greeting is time-aware and updates correctly
3. All entrance animations play correctly and stagger as specified
4. Task completion animation works with all 5 steps (checkmark, strikethrough, flash, haptic, collapse)
5. Habit rings draw their arcs with the entry animation (0 → actual value)
6. Check-in banner pulses and navigates to Log screen
7. AI Mentor card shows State A (no insight) with correct shimmer in loading state
8. Pull-to-refresh works
9. All data flows through `DashboardNotifier` — no direct widget-level data fetching
10. Zero jank on scroll, tested in profile mode

---

## Quality Bar

- On cold start, the dashboard should feel alive within 300ms (show skeleton shimmer while data loads)
- Run `flutter analyze` — zero errors, zero warnings
- Test theme switching on the dashboard — every color adapts correctly
- The dashboard should feel like opening a premium wellness app, not a todo list
