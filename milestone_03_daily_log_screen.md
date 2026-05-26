# Milestone 3 — Daily Log Screen (The Core Interaction)

---

## Agent Context

You are a world-class Flutter engineer and product designer with 40 years of combined experience building premium consumer applications. Milestones 1 and 2 are complete — the design system is solid and the Dashboard is polished. Now you build the **Daily Log Screen** — the screen users interact with most frequently, multiple times a day. Every tap, swipe, and input here must feel effortless. The UX must be so smooth that logging becomes a habit in itself.

---

## Milestone 3 Objective

Build the **Daily Log Screen** — a beautiful, guided daily entry flow that captures mood, energy, tasks, habits, and free-form notes. The screen must feel like writing in a premium digital journal, not filling out a form.

---

## 1. Screen Architecture

The Daily Log screen is a **vertically scrolling single-screen experience** — not a multi-page wizard. Everything is on one scrollable page so users can see their progress and jump to any section. Use `CustomScrollView` with `SliverList`.

Sections from top to bottom:

1. **Screen Header** (date + log status indicator)
2. **Mood Selector** (interactive, animated emoji scale)
3. **Energy Selector** (horizontal slider with custom track)
4. **Tasks Section** (add/edit today's tasks inline)
5. **Habits Tracker** (check off habits with animation)
6. **Notes Section** (free-form text, expandable)
7. **Save / Done Button** (sticky at bottom)

---

## 2. Screen Header

- Title: "Today's Log" in `headingLarge`
- Below title: Current date in `bodyMedium` `textSecondary`
- Right side of header: A small pill badge showing log completion:
  - Gray "0/5 sections" when nothing is logged
  - Amber "3/5 sections" in progress
  - Green "Complete ✓" when all sections are filled
  - This badge animates its fill (background sweeps from left to right) as sections are completed — use `AnimatedContainer` with width transition
- A thin progress bar below the header (full screen width, 3dp height, amber fill, rounded ends) that animates its width as the user completes sections. Use `TweenAnimationBuilder` for smooth width transitions.

---

## 3. Mood Selector

### 3.1 Design Concept
A horizontal row of 5 mood states. The selected mood scales up and becomes vivid; unselected ones shrink and desaturate. It feels like choosing between real emotional states, not rating something with stars.

### 3.2 Mood States
Define 5 mood levels:
| Level | Label | Emoji | Color |
|---|---|---|---|
| 1 | Struggling | 😔 | `#FF4D6D` (rose) |
| 2 | Low | 😕 | `#FF8C42` (orange) |
| 3 | Okay | 😐 | `#F0A500` (amber) |
| 4 | Good | 🙂 | `#5BC67A` (green) |
| 5 | Great | 😄 | `#34C97B` (vivid green) |

### 3.3 Interaction & Animation
- 5 emoji circles arranged in a `Row`, evenly spaced
- Each circle: 52dp when unselected, 68dp when selected
- The size change animates via `AnimatedContainer` over 200ms `easeOutCubic`
- Unselected: background is the mood color at 12% opacity, emoji at 60% opacity
- Selected: background is the mood color at 25% opacity, emoji at 100% opacity, a subtle outer glow (`BoxShadow` in mood color at 30% opacity, blur 16dp)
- A label appears below the selected emoji (fades in over 150ms): the mood's text label in `labelSmall` bold, mood color
- On selection, haptic: `HapticUtils.selection()`
- The background of the entire mood section subtly tints to the selected mood color at 3% opacity — use an `AnimatedContainer` as the section background

### 3.4 Mood Description Input
Below the mood row, a small optional text field appears with a fade-in when any mood is selected:
- Placeholder: "What's driving this feeling?" in `textTertiary`
- `bodyMedium` text style
- No border — just a transparent filled container with the section background
- Max 2 lines visible, expandable

---

## 4. Energy Selector

### 4.1 Design Concept
Not a standard slider. Build a custom energy track using `CustomPainter` + `GestureDetector`.

### 4.2 Visual
- A full-width horizontal track, 14dp height, rounded ends
- The track background is a gradient from left to right: `#FF4D6D` (red, 1) → `#FF8C42` (orange, 2) → `#F0A500` (amber, 3) → `#5BC67A` (light green, 4) → `#34C97B` (green, 5)
- A white circular thumb, 28dp diameter, with a 2dp white border and a subtle drop shadow
- The thumb slides smoothly as the user drags left/right
- The track fills from left to the thumb position with the gradient (full opacity), and from thumb to end at 30% opacity

### 4.3 Labels
- Below the track: 5 labels evenly spaced ("Drained", "Low", "Moderate", "High", "Peak") in `labelSmall` `textTertiary`
- The label corresponding to the current selection is highlighted in the track's color at that position, `labelSmall` bold

### 4.4 Value Display
- Above the track center: A floating label showing the selected energy label ("High Energy") in `bodyMedium` bold, colored to match the position
- This label slides horizontally to follow the thumb with `AnimatedPositioned`

### 4.5 Haptics
Haptic feedback fires once each time the thumb crosses into a new energy level band (5 distinct haptic zones). Use `HapticUtils.selection()`.

---

## 5. Tasks Section

### 5.1 Section Header
- Left: "Today's Tasks" `headingMedium`
- Right: A "+" icon button (Phosphor `plus` icon, 32dp, amber colored, taps to add new task inline)

### 5.2 Task Input Flow
When the "+" is tapped:
- A new task row appears at the bottom of the task list with a fade-in + height-expand animation (height from 0 → 56dp, duration 250ms)
- The row contains:
  - An unchecked circle (left)
  - A `TextField` that auto-focuses with the keyboard opening (right — full width)
  - A small priority selector (3 colored dots — amber, textSecondary, rose — tappable to set priority)
  - A dismiss button (✕) on the far right
- Pressing Enter or tapping the check button saves the task (closes keyboard, task becomes a regular list item)
- The `TextField` uses `bodyLarge` style, no border, transparent background

### 5.3 Task List
Each existing task row:
- Left: Animated checkbox (same as Dashboard — draws the checkmark on completion)
- Center: Task title, with strikethrough animation on completion
- Right: Priority dot + swipe-to-delete (swipe left reveals red delete action)
- Swipe-to-delete uses `Dismissible` widget with a custom red background and a trash icon revealed on swipe

### 5.4 Reordering
Long-press on any task to enter reorder mode:
- All tasks get a subtle left indent revealing a drag handle (6 horizontal lines icon, `textTertiary`)
- `ReorderableListView` handles the drag-and-drop with the standard Flutter material drag effect
- Exiting reorder mode: tap anywhere outside or wait 3 seconds without dragging

### 5.5 Empty State
If no tasks: a small nudge message "Add your first focus for today ↑" in `bodySmall` `textTertiary`, centered, pointing up at the "+" button.

---

## 6. Habits Tracker

### 6.1 Layout
A vertical list of habit check-off rows. Each row:

- Left: A round checkbox (36dp). Unchecked: thin `divider`-colored border. Checked: filled with the habit's assigned color, white checkmark icon inside, with a small burst/confetti particle effect on first check
- Center: Habit emoji (20dp) + habit name in `bodyLarge`
- Right: A tiny frequency label in `labelSmall` `textTertiary` (e.g., "Daily", "3×/week")
- Below the habit name: A 5-day mini streak bar (Mon–Fri as 5 small 6dp circles, filled or empty based on past completion). This gives context at a glance.

### 6.2 Check Animation
When a habit is checked:
1. The circle fills with a radial sweep animation (like a pie chart filling up) over 300ms
2. A micro burst of 6 small circular particles radiates outward from the checkbox center (use a `CustomPainter` with a simple particle system — particles expand and fade over 400ms)
3. Haptic: `HapticUtils.success()`
4. The row's background briefly flashes the habit's color at 8% opacity, then returns to normal

### 6.3 Add New Habit
At the bottom of the habits list, a dashed border row:
- "＋ Add a habit" label in `bodyMedium` `textSecondary`
- Tapping opens a bottom sheet for habit creation (defined in detail below in section 6.4)

### 6.4 Add Habit Bottom Sheet
A `showModalBottomSheet` with `isScrollControlled: true`, handles keyboard avoidance.

Contents:
- Drag handle at top (40dp wide, 4dp high, `textTertiary` background, rounded)
- Title: "New Habit" in `headingMedium`
- **Emoji picker row:** 10 preset emojis in a horizontal scrollable row (book, dumbbell, water drop, apple, moon, pen, heart, brain, sun, leaf). Tapping one selects it with a scale animation. Selected emoji has an amber ring.
- **Name field:** `bodyLarge` text field, placeholder "Habit name..."
- **Color picker row:** 8 circles (32dp) in different colors. Selected circle has a white checkmark inside.
- **Frequency selector:** Row of 3 options — "Daily", "Weekdays", "Custom". Tapping a chip selects it (amber background, dark text). "Custom" opens a `Mon Tue Wed Thu Fri Sat Sun` day-picker row.
- **Save button:** Full-width `LuminaButton` "Add Habit"

The sheet enters with a spring curve (defined in `AppMotion.spring`).

---

## 7. Notes Section

### 7.1 Design
A large, open text area styled like a journal page:
- No border, no visible container
- Subtle horizontal rule lines drawn by `CustomPainter` behind the text (like lined paper) — line color is `divider` colored
- Placeholder: "Write anything — what happened, what you're thinking, what you're grateful for..." in `textTertiary`
- `bodyLarge` text style
- Minimum 6 lines visible, expands infinitely as the user types (use `expands: false` with `minLines: 6`, `maxLines: null`)
- A small character/word count in `labelSmall` `textTertiary` appears in the bottom-right corner of the notes area when the user is typing

### 7.2 Formatting Toolbar (minimal)
When the notes field is focused, a small toolbar appears above the keyboard (using `KeyboardSuggestionOverlay` or a `Row` positioned above the keyboard using `MediaQuery.viewInsetsBottom`):
- 4 buttons: **B** (bold), _I_ (italic), 💛 (highlight), # (heading)
- These apply markdown-style formatting — just visually wrap the selected text in the corresponding markdown symbols (no need for rich text rendering in this milestone)
- Toolbar has `backgroundCard` background, rounded top corners (12dp), soft shadow

---

## 8. Save / Done Button

### 8.1 Sticky Positioning
The save button is **not** in the scroll view. It is a `Positioned` widget inside a `Stack` that wraps the entire screen, fixed to the bottom:
- Bottom: 0
- Left & Right: 0
- Background: gradient from transparent → `backgroundPrimary` (height 80dp), the button sits at the bottom of this gradient so it appears to float above the content
- The `LuminaButton` is inside this area with `pagePadding` horizontal margins

### 8.2 Button States
- **Default:** "Save Today's Log" label
- **Partial:** "Save Progress (3/5)" — updates dynamically as sections are filled
- **Complete:** "Complete Today ✓" — amber fill button
- **Already saved today:** Transforms into a "Update Log" outlined button (amber outline, transparent fill, amber text)

### 8.3 On Save
1. Validate that at least mood OR one task is filled (if nothing at all, show a gentle `SnackBar`: "Add at least one thing to log.")
2. Save all data to local Hive storage via the `LogRepository`
3. Show a brief full-screen success moment:
   - A green checkmark icon scales in from 0.5 → 1.0 over 300ms in the center of the screen
   - Background briefly tints green at 5%
   - Text: "Logged ✓" appears below the icon
   - This overlay auto-dismisses after 1.2 seconds
4. Update the streak counter (call `StreakService.recordLog()`)
5. Haptic: `HapticUtils.success()`
6. Navigate back to Dashboard (the dashboard re-fetches and shows the updated data)

---

## 9. Data Layer

Create `LogRepository` and `TodayLogNotifier` (Riverpod `AsyncNotifierProvider`):

Methods:
- `getTodayLog()` → `DailyLog?`
- `saveDailyLog(DailyLog log)` → void
- `updateTask(String id, bool isCompleted)` → void
- `addTask(Task task)` → void
- `deleteTask(String id)` → void
- `checkHabit(String habitId)` → void
- `uncheckHabit(String habitId)` → void

**Model: `DailyLog`**
```
DailyLog {
  id: String (uuid)
  date: DateTime
  mood: int? (1-5)
  moodNote: String?
  energy: int? (1-5)
  tasks: List<Task>
  completedHabitIds: List<String>
  notes: String?
  createdAt: DateTime
  updatedAt: DateTime
}
```

Hive box key for today's log: `log_YYYY-MM-DD` (e.g., `log_2025-05-27`).

---

## 10. Keyboard Handling

- The entire screen is wrapped in `GestureDetector` with `onTap: () => FocusScope.of(context).unfocus()` so tapping outside any field dismisses the keyboard
- Use `MediaQuery.viewInsetsBottom` to add extra bottom padding to the scroll view when the keyboard is open, so content is always visible
- `WidgetsBinding.addPostFrameCallback` to scroll to the currently focused section when the keyboard opens

---

## 11. Deliverables for This Milestone

By the end of Milestone 3:

1. All 6 log sections render correctly in both themes
2. Mood selector — 5 moods, selection animation, background tint all work
3. Energy slider — custom painted, smooth drag, per-zone haptics
4. Task section — inline add, checkbox animation, swipe-to-delete, long-press reorder
5. Habit section — check animation with particle burst, add habit bottom sheet with full form
6. Notes section — lined paper background, formatting toolbar above keyboard
7. Save button — sticky, dynamically updates label, success overlay animation
8. All data persists in Hive — reopening the log screen shows today's saved data
9. Streak is updated correctly on save
10. Keyboard handling is smooth — content never hidden behind keyboard

---

## Quality Bar

- The mood selector must feel **delightful** — this is the most frequently used control in the app. Test it 10 times. If it doesn't bring a small smile, improve it.
- The habit check burst animation must be visible and satisfying on a real device
- The energy slider must feel smooth — no jitter, no lag
- Zero layout overflow errors at any screen size (test on small devices: 360px wide)
