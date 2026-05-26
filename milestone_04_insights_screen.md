# Milestone 4 — Insights Screen (Data Visualization & Pattern Discovery)

---

## Agent Context

You are a world-class Flutter engineer and product designer with 40 years of combined experience building premium consumer applications. Milestones 1–3 are complete. The design system, dashboard, and daily log are fully functional. Now you build the **Insights Screen** — the analytical brain of Lumina, where data collected daily transforms into beautiful, emotionally resonant visualizations that help users understand their own patterns.

The goal of this screen is to make the user feel like they are being *understood*. Not just shown charts, but shown **what their data means about them as a person**.

---

## Milestone 4 Objective

Build the **Insights Screen** — a data visualization and pattern analysis screen with beautiful animated charts, trend analysis, burnout detection indicators, and habit consistency visualizations. All charts are custom-built using `CustomPainter` or the `fl_chart` package.

---

## 1. Screen Architecture

A `CustomScrollView` with a `SliverAppBar` and multiple content sections. The screen has a **time range filter** (7 days / 30 days / 90 days) that triggers all charts to re-render with animation when changed.

Sections:

1. **Header + Time Range Filter**
2. **Mood Journey Chart** (line chart, most prominent)
3. **Energy Patterns** (bar chart)
4. **Burnout Risk Card** (AI-computed, amber/red indicator)
5. **Habit Consistency Grid** (heatmap-style calendar)
6. **Productivity Patterns** (task completion by day of week)
7. **Emotional Triggers** (AI-identified tags)
8. **Notable Streaks** (milestone cards)

---

## 2. Header + Time Range Filter

### 2.1 Header
- Title: "Your Patterns" in `displayMedium`
- Subtitle: "Insights from the last [N] days" in `bodyMedium` `textSecondary`, updates dynamically based on selected range

### 2.2 Time Range Filter
A segmented control with 3 options: "7D", "30D", "90D":
- Build this from scratch — do not use `SegmentedButton`
- A `Row` of 3 `GestureDetector` containers inside a rounded pill-shaped parent container (background: `backgroundCard`)
- Selected segment: amber background, dark text, with a sliding animated indicator (`AnimatedPositioned` or a `Stack` with an amber pill that slides)
- Unselected: transparent, `textSecondary` text
- The sliding animation: 250ms `easeInOutCubic`
- On segment change, all charts animate their data update simultaneously

---

## 3. Mood Journey Chart

### 3.1 Design
This is the hero chart of the screen. A smooth line/area chart showing mood (1–5) over the selected time range.

Use `fl_chart` (`LineChart` widget) with heavy customization — no default fl_chart styling should remain visible.

### 3.2 Chart Specifications
- **Chart area height:** 200dp
- **Y axis:** 5 levels, no visible axis line, only the horizontal grid lines (very faint, `divider` color, dashed)
- **X axis:** Day labels in `labelSmall` `textTertiary` (Mon, Tue, Wed...) — show every other label if 30D, every 7th if 90D
- **Line:** 2.5dp stroke, color changes based on average mood:
  - Average ≥ 4: `successColor` (#34C97B)
  - Average 3–4: `primaryAccent` (amber)
  - Average < 3: `warningColor` (orange)
- **Area fill:** A `LinearGradient` from the line color at 40% opacity (top) to 0% (bottom) fills the area under the line
- **Data points:** Small 6dp filled circles at each data point, same color as the line, with a white 2dp border
- **Interaction:** Tapping/dragging on the chart shows a floating tooltip:
  - A rounded pill (12dp radius) in `backgroundElevated`
  - Shows: "Tue, 27 May" + the mood emoji + mood label
  - A thin vertical amber line descends from the tooltip to the data point
  - The tooltip follows finger position with a smooth `AnimatedPositioned`

### 3.3 Entry Animation
When the chart first loads (or when time range changes):
- The line draws from left to right using a path animation (clip the path progressively using `AnimatedBuilder` + `CustomClipper`)
- The area fill fades in simultaneously
- Duration: 800ms, `easeOutCubic`
- Data points pop in with a scale animation once the line reaches them (staggered)

### 3.4 Empty State
If fewer than 3 data points: show a centered message: "Log for a few more days to see your mood journey" with the mini Lottie animation.

---

## 4. Energy Patterns — Bar Chart

### 4.1 Design
A grouped bar chart showing average energy by day of week (Mon–Sun) across the selected period.

Build this with `CustomPainter` (not fl_chart) for full control.

### 4.2 Specifications
- 7 bars, one per day of week
- Bar width: calculated as `(screenWidth - 40) / 7 - 8`
- Bar height: proportional to average energy (1–5), max height: 120dp
- Bar color: gradient from `secondaryAccent` (bottom) to a lighter shade (top), 8dp top radius only (flat bottom)
- Below each bar: Day label in `labelSmall` `textTertiary`
- The highest-energy bar has a small amber star/crown icon above it
- Bars for days with no data are shown at minimum height (8dp) in `textTertiary` at 30% opacity

### 4.3 Entry Animation
Bars grow from bottom to top when entering. Use `AnimatedBuilder` with a `CurvedAnimation`:
- Duration: 600ms per bar
- Stagger: 60ms delay per bar (Mon first, Sun last)
- Curve: `easeOutCubic`

### 4.4 Day Pattern Insight
Below the chart, a small insight line in `bodyMedium` with an amber spark icon:
- Auto-generated text: "Your energy peaks on [highest day]. Consider scheduling deep work then."
- This text is derived locally by finding the day with the highest average — no AI call needed.

---

## 5. Burnout Risk Card

### 5.1 The Algorithm (Local)
Calculate a burnout risk score (0–100) based on these local signals:
- Low mood (< 3) for 3+ consecutive days: +30 points
- Low energy (< 3) for 3+ days: +25 points
- Habit completion rate < 40% for a week: +20 points
- Task completion rate < 30% for a week: +15 points
- No log entries for 2+ days: +10 points

Clamp to 0–100. Define thresholds:
- 0–30: **"Balanced"** — green
- 31–60: **"Watch Out"** — amber
- 61–100: **"High Risk"** — rose/red

### 5.2 Card Design
- Full-width `LuminaCard`
- Top row: amber sparkle icon + "Burnout Radar" label in `labelSmall` amber
- Center: A large circular gauge (160dp diameter) built with `CustomPainter`:
  - A semi-circle arc (180°, bottom half) as the background track — gray
  - The progress arc fills from left to right based on the score
  - The arc color changes: green → amber → rose (gradient along the arc using `PathMetrics`)
  - A needle pointer (thin line from center, 60dp long) rotates to point to the score value — needle animates from 0 to the value over 600ms with `easeOutCubic`
  - Below the center: The score number in `displayMedium` bold (use `AnimatedCounter`)
  - Very below: The risk label in `labelLarge` colored to match the level

- Below the gauge: 3–4 bullet points (the contributing signals) in `bodySmall` `textSecondary`. Each bullet has a small colored dot (red/amber/green) indicating its contribution.

- If risk is "High": A special amber-bordered call-to-action box: "Your mentor has advice for you →" (taps to Mentor screen)

### 5.3 Animation
The gauge needle sweeps in over 800ms after the card enters the viewport. Use `AnimatedBuilder` with a `Tween<double>` controlled by a visibility check (use `VisibilityDetector` package or a manual scroll listener to trigger).

---

## 6. Habit Consistency Heatmap

### 6.1 Design
A GitHub-style contribution heatmap but for habits. Shows the last 30 or 90 days as a grid of small squares.

Build entirely with `CustomPainter`.

### 6.2 Specifications
- Each day is a 14dp × 14dp square with 3dp gap
- Squares are arranged in 7-row columns (Mon at top, Sun at bottom) — standard GitHub-style orientation
- Color intensity based on habit completion rate that day:
  - 0%: `backgroundCard` (empty day)
  - 1–33%: `secondaryAccent` at 30% opacity
  - 34–66%: `secondaryAccent` at 60% opacity
  - 67–99%: `secondaryAccent` at 85% opacity
  - 100%: `secondaryAccent` full opacity — all habits done
  - No data (future day): `backgroundCard` at 50% opacity
- Above the grid: Month labels (`labelSmall` `textTertiary`) positioned at column boundaries where months change
- Left: Day labels ("M", "W", "F") at every other row

### 6.3 Interaction
Tapping a square shows a tooltip popup:
- "27 May — 3/4 habits done" in `bodySmall`
- The tooltip has `backgroundElevated` background, rounded corners (8dp)

### 6.4 Entry Animation
All squares fade in simultaneously with a slight scale from 0.8 → 1.0 over 400ms. Simple and clean.

---

## 7. Productivity Patterns — Task Completion

### 7.1 Design
A horizontal grouped display showing:
- Average tasks added per day (over the period)
- Average tasks completed per day
- Completion percentage

Presented as a simple ratio visualization:
- Two horizontal bars stacked (added = full width, completed = partial width based on %)
- Completed bar color: `successColor`; Added bar color: `backgroundElevated`
- Below: "You complete [X]% of your daily tasks on average." in `bodyMedium`

### 7.2 Best/Worst Day
Two small side-by-side cards:
- Left card (green tint): "Best Day 🏆" — [Day name] — [X tasks completed]
- Right card (warm tint): "Challenging Day" — [Day name] — [X% completion]
- These are derived by day-of-week analysis of task completion history

---

## 8. Emotional Triggers Section

### 8.1 Overview
This section shows **AI-identified patterns** — words, themes, and situations from the user's daily notes that correlate with high or low mood days.

The data for this section comes from a **Supabase Edge Function** that sends the user's notes (last 30 days) to Gemini and receives back a structured list of triggers.

### 8.2 Data Model
```
EmotionalTrigger {
  tag: String (e.g., "meetings", "exercise", "poor sleep")
  sentiment: "positive" | "negative" | "neutral"
  frequency: int (how many days it appeared)
  moodCorrelation: double (-1.0 to 1.0)
}
```

### 8.3 Visual Design
A tag cloud / pill row layout. Tags are sorted by frequency (most frequent first).

- Positive triggers (moodCorrelation > 0.3): green background at 15% opacity, green text
- Negative triggers (moodCorrelation < -0.3): rose background at 15% opacity, rose text
- Neutral: `backgroundCard` background, `textSecondary` text
- Each pill shows the tag text + a small up/down arrow indicating correlation direction
- Tapping a pill expands a bottom sheet with: "On days you mentioned [tag], your average mood was [X]/5" + the specific days listed

### 8.4 Loading State
Show 8 shimmer pills of varying widths while the edge function response is loading.

### 8.5 Empty State
"Log your notes daily for 7 days to unlock emotional trigger analysis." — `bodyMedium` `textSecondary` centered.

---

## 9. Notable Streaks

A horizontal scrollable row of milestone cards. Each card celebrates a streak or achievement:

Examples:
- "🔥 12-Day Logging Streak"
- "💪 7-Day Exercise Habit"
- "😊 5 Great Mood Days This Month"
- "✅ 100 Tasks Completed"

**Card design:**
- 140dp wide, 90dp tall
- Background: a subtle gradient using the achievement's theme color at 15% opacity
- Large emoji (32dp) centered top
- Metric in `headingMedium` bold
- Label in `labelSmall` `textSecondary`
- A soft glow effect (matching color) using `BoxShadow`

Scroll is horizontal, no scrollbar visible.

---

## 10. Supabase Edge Function — Emotional Triggers

Define the edge function contract (the function itself is built in Milestone 5, but define the interface now):

**Function name:** `analyze-emotional-triggers`

**Request payload:**
```json
{
  "userId": "string",
  "notes": [
    { "date": "2025-05-27", "text": "Had a tough standup, feeling behind on work" },
    ...
  ],
  "moodData": [
    { "date": "2025-05-27", "mood": 2 },
    ...
  ]
}
```

**Response:**
```json
{
  "triggers": [
    { "tag": "meetings", "sentiment": "negative", "frequency": 8, "moodCorrelation": -0.6 },
    { "tag": "exercise", "sentiment": "positive", "frequency": 5, "moodCorrelation": 0.7 }
  ]
}
```

Create the Dart model, repository method, and Riverpod provider for this now. The provider should:
- Check if cached data (from Hive) is less than 24 hours old — if so, return cached
- Otherwise call the edge function and cache the response

---

## 11. Scroll Performance

- All `CustomPainter` charts should be wrapped in `RepaintBoundary`
- Charts should only animate when they enter the viewport (use `VisibilityDetector` or a scroll-aware `AnimationController`)
- The heatmap grid for 90 days (≈90 squares) must render without lag — use a single `CustomPainter` for the entire grid, not individual widgets per square
- Charts should not re-paint on every rebuild — implement `shouldRepaint` correctly

---

## 12. Deliverables for This Milestone

1. Insights screen renders all 8 sections in both themes
2. Time range filter (7D/30D/90D) switches with sliding animation and all charts re-animate
3. Mood Journey line chart — draws with path animation, tappable tooltip works
4. Energy bar chart — bars grow from bottom with stagger animation, peak bar has star
5. Burnout gauge — needle sweeps to score value, color zones are correct
6. Habit heatmap — correct grid layout, tappable day tooltip
7. Emotional triggers — loading shimmer, tag cloud with sentiment colors
8. Notable streaks — horizontal scroll, correct calculations
9. All chart data is read from Hive (local data from Milestone 3 logs)
10. Emotional triggers provider is ready and returns cached/loading/error states correctly

---

## Quality Bar

- The mood line chart animation must feel premium — test it 5 times, it should be as smooth as a native iOS chart
- The burnout gauge needle must animate smoothly — no jumpiness
- The heatmap must render the full 90-day grid without any frame drops
- Empty states for each section must be informative and not feel like errors
