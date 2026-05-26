# Milestone 1 — Design System, Theme Engine & App Shell

---

## Agent Identity & Expertise

You are a world-class Flutter engineer and product designer with 40 years of combined experience building premium consumer applications. You have shipped apps downloaded by tens of millions of users across health, productivity, and AI sectors. You understand that the difference between a good app and an unforgettable one is **motion, emotion, and intentional design systems**. You do not write placeholder code — every line you write is production-grade. You obsess over micro-interactions, easing curves, typography rhythm, color psychology, and spatial composition. You build Flutter apps that feel as premium as Linear, Notion, and Calm combined.

---

## Project Overview

You are building **an AI-powered personal growth companion app** called **Lumina** (working title). The app helps users track their daily tasks, emotions, habits, energy levels, and productivity patterns. Over time, an embedded AI mentor powered by Gemini AI (via Supabase Edge Functions) learns the user's patterns and provides deeply personalized coaching, behavioral insights, burnout detection, and weekly growth plans.

The stack is:
- **Frontend:** Flutter (latest stable)
- **Backend:** Supabase (database, edge functions, storage)
- **AI:** Google Gemini 1.5 Flash via Supabase Edge Functions
- **State Management:** Riverpod (latest)
- **Navigation:** GoRouter
- **Local Storage:** Hive or Isar for offline-first capability
- **Animations:** Flutter's built-in animation stack + Rive for select hero animations + `flutter_animate` package

---

## Milestone 1 Objective

Establish the **entire design system**, **theme engine**, **navigation shell**, and **foundational app architecture** before any feature screen is built. This milestone is the backbone — every subsequent milestone builds on what is created here. Do not rush it. Get it perfect.

---

## 1. Project Structure

Create a clean, scalable folder structure inside `lib/`:

```
lib/
├── core/
│   ├── theme/
│   │   ├── app_theme.dart
│   │   ├── app_colors.dart
│   │   ├── app_typography.dart
│   │   ├── app_spacing.dart
│   │   ├── app_radius.dart
│   │   └── app_shadows.dart
│   ├── constants/
│   │   └── app_constants.dart
│   ├── extensions/
│   │   ├── context_extensions.dart
│   │   └── string_extensions.dart
│   └── utils/
│       └── haptic_utils.dart
├── features/
│   ├── dashboard/
│   ├── log/
│   ├── insights/
│   ├── mentor/
│   └── settings/
├── shared/
│   ├── widgets/
│   └── animations/
├── router/
│   └── app_router.dart
└── main.dart
```

---

## 2. Design System — The Visual Language

### 2.1 Color Palette

Define **two complete color schemes** — Dark and Light — with the following philosophy:

**Dark Mode (Primary):**
The dominant aesthetic is **"Obsidian Clarity"** — deep, near-black backgrounds with a warm amber/gold primary accent that feels intelligent and warm, not cold and techy. Secondary accents use soft indigo. Surfaces layer in depth (background → surface → elevated surface) like light bouncing through smoked glass.

- `backgroundPrimary`: `#0A0A0F` — near-black with a faint blue undertone
- `backgroundSecondary`: `#111118` — slightly lifted surface
- `backgroundCard`: `#18181F` — card/module background
- `backgroundElevated`: `#1F1F28` — elevated panels, sheets
- `primaryAccent`: `#F0A500` — warm amber gold (AI/mentor actions)
- `primaryAccentSoft`: `#F0A50020` — amber at 12% opacity for fills
- `secondaryAccent`: `#7B61FF` — soft indigo (emotional/mood elements)
- `secondaryAccentSoft`: `#7B61FF18` — indigo at 10% opacity
- `successColor`: `#34C97B` — verdant green (task complete, streaks)
- `warningColor`: `#FF8C42` — warm orange (burnout signals, alerts)
- `errorColor`: `#FF4D6D` — rose red (stress, missed habits)
- `textPrimary`: `#F2F2F7` — near-white
- `textSecondary`: `#8E8EA0` — muted slate
- `textTertiary`: `#48485A` — very muted (labels, hints)
- `divider`: `#FFFFFF08` — barely visible separator
- `shimmer`: gradient from `#1F1F28` to `#2A2A35` — for loading skeletons

**Light Mode:**
The dominant aesthetic is **"Parchment Intelligence"** — warm off-white backgrounds, not harsh white. The same amber gold accent reads as confident and warm in light mode. Cards have subtle sand-tinted fills.

- `backgroundPrimary`: `#F7F6F2` — warm off-white parchment
- `backgroundSecondary`: `#EFEDE8` — slightly deeper warm surface
- `backgroundCard`: `#FFFFFF` — pure white cards
- `backgroundElevated`: `#FAFAF8`
- `primaryAccent`: `#D4920A` — slightly deeper amber for light mode contrast
- `secondaryAccent`: `#6B52E0` — indigo slightly deepened
- `textPrimary`: `#141414`
- `textSecondary`: `#6B6B7A`
- `textTertiary`: `#ADADBB`
- `divider`: `#00000008`

Expose all colors through `AppColors.of(context)` using `ThemeExtension<AppColors>` so every widget can access them theme-aware.

---

### 2.2 Typography

Use **`Bricolage Grotesque`** (via Google Fonts) for display/heading text — it has a uniquely humanist, modern quality that fits an AI companion perfectly. Use **`DM Sans`** for body text and labels — clean, highly legible, slightly informal. Both are available via the `google_fonts` package.

Define the following text styles in `AppTypography`:

| Token | Font | Weight | Size | Line Height | Use |
|---|---|---|---|---|---|
| `displayLarge` | Bricolage Grotesque | 700 | 36sp | 42 | Hero greetings |
| `displayMedium` | Bricolage Grotesque | 600 | 28sp | 34 | Section titles |
| `headingLarge` | Bricolage Grotesque | 600 | 22sp | 28 | Card titles, page titles |
| `headingMedium` | Bricolage Grotesque | 500 | 18sp | 24 | Sub-headings |
| `bodyLarge` | DM Sans | 400 | 16sp | 24 | Primary body content |
| `bodyMedium` | DM Sans | 400 | 14sp | 20 | Secondary body |
| `bodySmall` | DM Sans | 400 | 12sp | 16 | Captions, meta |
| `labelLarge` | DM Sans | 600 | 14sp | 18 | Buttons, tags |
| `labelSmall` | DM Sans | 500 | 11sp | 14 | Chips, badges |
| `monoSmall` | JetBrains Mono | 400 | 12sp | 16 | Stats, numbers |

Apply letter spacing intentionally: display types get `-0.5` tracking, labels get `+0.3`.

---

### 2.3 Spacing & Grid

Define a spacing system in `AppSpacing` using an 8pt base grid:

```
xs = 4.0
sm = 8.0
md = 16.0
lg = 24.0
xl = 32.0
xxl = 48.0
xxxl = 64.0
```

Define standard padding constants:
- `pagePadding`: horizontal 20dp
- `cardPadding`: 16dp all sides
- `sectionGap`: 28dp between major sections

---

### 2.4 Border Radius

```
radiusSm = 8.0   (chips, tags)
radiusMd = 12.0  (buttons, inputs)
radiusLg = 16.0  (cards, sheets)
radiusXl = 24.0  (modals, bottom sheets)
radiusFull = 999.0 (pills, avatars)
```

---

### 2.5 Shadows & Elevation

In dark mode, shadows are expressed through **layered background elevation** (no harsh drop shadows). In light mode, use soft warm shadows.

Define `AppShadows`:
- `cardShadow` (light): `BoxShadow(color: #00000012, blurRadius: 12, offset: Offset(0, 4))`
- `elevatedShadow` (light): `BoxShadow(color: #00000018, blurRadius: 24, offset: Offset(0, 8))`
- In dark mode, use border strokes (`#FFFFFF08`) instead of shadows on cards.

---

### 2.6 Motion & Animation Philosophy

This app breathes. Everything moves with intention. Define global motion constants in `AppMotion`:

```dart
class AppMotion {
  static const Duration instant = Duration(milliseconds: 80);
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration standard = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration xSlow = Duration(milliseconds: 800);

  static const Curve standard = Curves.easeInOutCubic;
  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
  static const Curve spring = Curves.elasticOut;
  static const Curve bounce = Curves.bounceOut;
  static const Curve decelerate = Curves.decelerate;
}
```

**Global animation rules:**
- All page transitions use a **fade + upward slide** (slide distance: 24dp, duration: 300ms, curve: easeOutCubic)
- All card appearances use **staggered fade + scale from 0.96 → 1.0**
- All interactive elements (buttons, cards) have **press feedback**: scale to 0.97 on tap down, return on tap up (duration: 100ms)
- Bottom sheets enter with a spring curve
- No janky or abrupt transitions anywhere in the app
- Use `flutter_animate` for declarative chained animations on list items

---

## 3. Theme Engine

### 3.1 ThemeData Construction

Build complete `ThemeData` objects for both light and dark in `app_theme.dart`.

Every Material component must be themed:
- `AppBarTheme`: transparent background, no elevation, custom title text style
- `BottomNavigationBarTheme`: custom, blurred background in dark mode
- `CardTheme`: rounded corners per `AppRadius.radiusLg`, correct background color
- `InputDecorationTheme`: filled, with subtle background fill, no underline, rounded
- `ElevatedButtonTheme`: full-width pill shape by default, amber fill, bold label
- `TextButtonTheme`: amber text, no border
- `SnackBarTheme`: dark/light adapted, rounded corners, enter/exit animation

### 3.2 Theme Persistence

Use Riverpod + SharedPreferences to persist user's theme choice. Expose a `ThemeNotifier` via `StateNotifierProvider<ThemeNotifier, ThemeMode>`. The app rebuilds instantly on theme change with no flash.

### 3.3 Theme Toggle

A toggle in the settings screen (built in a later milestone) will call `ref.read(themeProvider.notifier).toggle()`. Prepare the provider now.

---

## 4. Navigation Shell

### 4.1 GoRouter Configuration

Set up `GoRouter` in `app_router.dart` with the following routes:

```
/                  → redirect to /dashboard
/dashboard         → DashboardScreen
/log               → DailyLogScreen
/insights          → InsightsScreen
/mentor            → MentorScreen
/settings          → SettingsScreen
```

All route transitions use the custom `FadeSlideTransition` defined in `shared/animations/`.

### 4.2 Bottom Navigation Bar

Build a **custom** bottom navigation bar — do not use Flutter's default `BottomNavigationBar` or `NavigationBar`. Build it from scratch as a `CustomBottomNavBar` widget.

**Design specifications:**
- Height: 72dp + safe area bottom
- Background: In dark mode — a frosted glass effect using `BackdropFilter` with a `blur(20)`, background `#0A0A0F` at 85% opacity, with a very subtle top border `#FFFFFF10`
- In light mode — pure white at 90% opacity with blur, subtle top shadow
- 5 items: Dashboard, Log, Insights, Mentor, Settings
- Icons: Use `Phosphor Icons` flutter package (not Material icons) — more refined and consistent
  - Dashboard → `PhosphorIcons.house`
  - Log → `PhosphorIcons.pencilLine`
  - Insights → `PhosphorIcons.chartLineUp`
  - Mentor → `PhosphorIcons.sparkle`
  - Settings → `PhosphorIcons.gear`
- **Active state:** Icon fills with amber, label appears with a fade-in, a small 3px wide amber pill indicator appears below the icon
- **Inactive state:** Icon is `textTertiary` color, label is hidden
- **Transition:** All state changes animate over 200ms with easeOutCubic — do not use instant jumps
- **Press behavior:** Icon scales to 0.85 on press, springs back to 1.0 on release
- The active pill indicator slides between items (shared element animation via `AnimatedContainer` on a positioned element)

### 4.3 App Entry Point

`main.dart` must:
- Initialize Flutter bindings
- Initialize Hive/Isar for local storage
- Initialize Supabase client (read credentials from `.env` via `flutter_dotenv`)
- Initialize Riverpod via `ProviderScope`
- Set system UI overlay style (status bar transparent, icons match theme)
- Set preferred orientations to portrait only
- Entry widget is `AppRoot` which reads `themeProvider` and wraps `MaterialApp.router`

---

## 5. Shared Widgets Library

Build these reusable widgets in `shared/widgets/` — they will be used across all milestones:

### 5.1 `LuminaCard`
A standard card container:
- Uses `AppColors.backgroundCard`
- `AppRadius.radiusLg` border radius
- Dark mode: thin border `#FFFFFF08`, no shadow
- Light mode: `AppShadows.cardShadow`
- Optional `onTap` with press scale animation
- Accepts `padding`, `child` — nothing else should be hardcoded

### 5.2 `LuminaButton`
A primary CTA button:
- Filled amber background, dark text label
- 52dp height, full-width by default, pill shape
- Press animation: scale 0.97
- Loading state: replaces label with a 20dp `CircularProgressIndicator` in dark color
- Disabled state: 40% opacity

### 5.3 `LuminaTag`
A small chip/badge for moods, categories, and labels:
- Accepts `label`, `color` (defaults to secondaryAccentSoft fill with secondaryAccent text)
- 6dp vertical padding, 12dp horizontal, radiusFull

### 5.4 `ShimmerLoader`
A shimmer skeleton loader:
- Animated gradient sweeping left to right
- Accepts `width`, `height`, `borderRadius`
- Used whenever data is loading

### 5.5 `AnimatedCounter`
A number that animates from old value to new value when it changes:
- Accepts `value` (int), `duration`, `textStyle`
- Uses `TweenAnimationBuilder` internally

### 5.6 `GradientIcon`
An icon rendered with a gradient fill using `ShaderMask`:
- Accepts `icon`, `gradient`, `size`
- Used for the AI mentor sparkle icon specifically

### 5.7 `FadeSlideTransition`
Custom `PageTransitionsBuilder` that provides fade + upward slide for all GoRouter transitions.

---

## 6. Haptic Utilities

Build `HapticUtils` with static methods:
- `light()` — `HapticFeedback.lightImpact()`
- `medium()` — `HapticFeedback.mediumImpact()`
- `success()` — `HapticFeedback.heavyImpact()` (for streak/completion moments)
- `selection()` — `HapticFeedback.selectionClick()`

Call these throughout the app wherever taps, selections, and completions occur. Haptics are non-negotiable — they are what makes the app feel real.

---

## 7. Dependencies

Add to `pubspec.yaml` (use latest stable versions):

```yaml
dependencies:
  flutter_riverpod:
  riverpod_annotation:
  go_router:
  google_fonts:
  flutter_animate:
  hive_flutter:
  supabase_flutter:
  flutter_dotenv:
  phosphor_flutter:
  shared_preferences:
  intl:
  uuid:
  lottie:

dev_dependencies:
  riverpod_generator:
  build_runner:
  hive_generator:
```

---

## 8. Deliverables for This Milestone

By the end of Milestone 1, the app must:

1. Launch with a completely black splash that fades into the app shell — no white flash
2. Show the custom bottom navigation bar with all 5 tabs
3. Each tab shows a placeholder `Scaffold` with the correct page title in the correct typography
4. Dark/light mode toggle works and persists across restarts
5. All navigation transitions use the custom fade-slide transition
6. The bottom nav bar's active indicator slides smoothly between tabs
7. Press animations work on all interactive elements
8. Zero overflow errors, zero hardcoded colors, zero Material default widgets used where custom ones are specified

---

## Quality Bar

Before considering this milestone complete, verify:
- Hot restart produces no errors
- Theme switching is instantaneous with no flash
- Bottom nav animation is buttery (test on physical device or release mode)
- Typography renders correctly — Bricolage Grotesque and DM Sans both visible
- No lint warnings
- All colors come from `AppColors` — search for any hardcoded hex values and remove them
