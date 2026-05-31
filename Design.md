---
name: design-guidelines
description: Behavioral guidelines for building world-class Flutter UI. Use when creating new screens, rebuilding components, designing animations, transitions, or any visual work in Flutter. Prevents generic AI-generated mobile UI. Forces intentional, novel, emotionally resonant design decisions.
license: MIT
---

# Design Guidelines — Flutter UI

Behavioral guidelines for producing Flutter UI that does not look like anything that already exists. Derived from first principles of what makes mobile interfaces genuinely memorable, adopted, and loved.

**Tradeoff:** These guidelines bias toward intentionality over speed. For trivial utility screens, use judgment. For any user-facing surface, apply fully.

---

## 0. Before You Write a Single Widget

**Design is a thinking act first. Code is the last step.**

Before touching `Widget build()`:

- **Name the emotion.** What should the user *feel* when they open this screen? Not "good" — be specific. Anticipation? Calm focus? Playful delight? Quiet confidence? Every widget decision flows from this answer.
- **Name the metaphor.** What does this UI feel like it *is*? A ritual? A control room? A journal? A stage? A window? The metaphor is your creative constraint — it prevents incoherence.
- **Name what this screen must NOT look like.** Generic card lists? Settings-style rows? Another dark-mode gradient? Rule out the obvious. What exists already is the floor, not the ceiling.
- **State your assumptions.** If the spec is ambiguous, name what you're assuming. If two design directions are equally valid, present both and ask. Do not silently pick the safer one.

If you cannot answer these three questions, stop. Ask. Proceeding without them produces forgettable UI.

---

## 1. Identity Over Trends

**Design for this app's soul, not for what's popular this year.**

- Do not default to Material 3 conventions just because Flutter ships with them. Material is a *floor*, not a ceiling.
- Do not use Cupertino conventions unless the metaphor demands it.
- Do not chase glassmorphism, bento grids, or neubrutalism because they are trending. If the aesthetic fits the emotion and metaphor — use it. If not, discard it.
- Every app has a cultural and emotional identity. Design must express *that* identity — not a design system's defaults.

Ask yourself: "If I removed the app name and logo, would a user still know which app this is?" If no — the design has no identity. Rethink.

---

## 2. Color Is Atmosphere, Not Decoration

**Color creates a world. Choose it like a cinematographer, not a painter.**

Do not hardcode a palette. Instead, reason through these questions each time:

- **What time of day does this app *feel* like?** Pre-dawn? Golden hour? Midnight? Let that light temperature guide your hue decisions.
- **What is the emotional temperature?** Warm tones push intimacy, urgency, energy. Cool tones push calm, focus, trust. Neutral tones push sophistication and restraint.
- **What is the dominant-to-accent ratio?** A 90/10 split (one dominant surface, one sharp accent) is almost always stronger than evenly distributed color. Commit to dominance.
- **Where does color *earn* its appearance?** Color used everywhere means nothing. Reserve accent color for moments that matter — a CTA, an active state, a moment of delight.
- **Does the palette work in both ambient light conditions?** Test mentally against a bright outdoor screen and a dark bedroom. If it collapses in one, rethink.

Never use color just to fill space. Every color decision must serve the atmosphere.

---

## 3. Typography Is Voice, Not Formatting

**Type choices tell the user who is speaking before they read a word.**

- Choose a type pairing with *personality contrast* — a display face with character, a body face with readability. Never use the system default as a design decision. Use it only when neutrality is intentional.
- **Scale with intent.** Use a modular type scale — but break it deliberately for hierarchy moments. The biggest text on a screen should feel *commanding*, not just large.
- **Letter-spacing and line-height are not afterthoughts.** Tight tracking on large display text feels luxury. Generous leading on body text feels editorial. Make a choice.
- **Weight contrast creates hierarchy without color.** A thin label next to a bold value is already a composition.
- **Text alignment is spatial design.** Center alignment creates ceremony. Left alignment creates flow. Right alignment creates tension. Use alignment purposefully.

Ask: "If I read only the type, stripped of all color and imagery, does the hierarchy still read clearly?"

---

## 4. Layout Is Choreography, Not Arrangement

**Don't place widgets. Compose scenes.**

- **Establish a visual rhythm first.** Consistent spacing units (use a base unit — 4px or 8px — and multiply) create invisible structure that users feel even when they can't name it.
- **Use asymmetry intentionally.** Perfectly centered, evenly spaced layouts read as generic. Introduce weight imbalance, offset elements, or deliberate whitespace to create visual tension that feels designed.
- **Whitespace is not empty space.** It is a design element with equal weight to content. Use it to let the most important thing breathe.
- **Break the grid when it serves the emotion.** An element that bleeds to the edge, overlaps a card, or sits at an unexpected angle can be the one thing a user remembers.
- **Stack depth intentionally.** Elevation (shadows, overlaps, blurs) creates a spatial hierarchy. The eye goes to what feels closest. Use z-depth to guide attention, not just to separate cards.

The test: Cover the content. Does the layout itself feel considered?

---

## 5. Motion Is Meaning, Not Polish

**Every animation must justify its existence with a reason, not just a feeling.**

Before adding any animation or transition in Flutter:

- **State what the animation communicates.** Continuity? Cause-and-effect? State change? Hierarchy? If you can't state it, cut the animation.
- **Use physics-based curves for interactions, eased curves for transitions.** `SpringSimulation`, `Curves.easeOutExpo`, `Curves.fastLinearToSlowEaseIn` — these feel natural because they mirror physical reality. Avoid linear animations on user-initiated gestures.
- **Duration discipline.** Micro-interactions: 150–250ms. State transitions: 250–400ms. Page transitions: 350–500ms. Anything slower than 500ms must carry narrative weight or it feels broken.
- **Stagger reveals to guide the eye.** When multiple elements appear, stagger their entry to tell the user where to look first. Do not animate everything at once.
- **Animate the *delta*, not the whole screen.** When something changes, only the changed element and its spatial context should animate. Everything else stays still.
- **Hero transitions must feel spatial.** A tapped card that expands into a detail page should feel like the user moved *toward* it, not like it replaced the screen.

Ask: "If I removed this animation, what meaning is lost?" If the answer is "nothing" — cut it.

---

## 6. Component Design — Novel, Not Assembled

**Build components that feel invented for this app, not assembled from a library.**

When creating or rebuilding a component:

- **Start from function, not form.** What does this component *do* for the user? What decision does it support or action does it enable? Let function drive shape.
- **Reject the first three obvious implementations.** The obvious button is a rounded rectangle. The obvious list item is an icon + title + subtitle. The obvious bottom sheet is a white card. Name three standard implementations — then design the fourth.
- **Small surface, high detail.** The smaller the component, the more a refined detail matters. Corner radii, border weights, icon sizing, padding rhythm — these are where craft lives.
- **States are part of the design.** Every interactive component has: default, hover/focused, pressed, loading, disabled, error, empty, success. Design all of them. A component with no error state is not finished.
- **Feedback is instant.** Visual response to a tap must begin within one frame. If the user questions whether they tapped, the feedback is too slow.

---

## 7. The Unforgettable Detail Principle

**Every screen must have one thing a user will remember and describe to someone else.**

It could be:

- A transition that feels physically satisfying
- A background that shifts with user context
- A type treatment that's unexpected but perfectly legible
- A loading state that has personality
- An empty state that makes the user smile
- A color moment that appears exactly once and then is gone

This is not decoration. This is the signature. It is what turns a functional app into one that gets talked about.

Before marking any screen complete, ask: "What is the one thing a user will describe when they tell a friend about this app?" If the answer is "I don't know" — the screen is not finished.

---

## 8. Flutter-Specific Execution Rules

**Technical choices that separate mediocre Flutter UI from elite Flutter UI.**

- **Prefer `CustomPainter` for anything that can't be composed from standard widgets without compromise.** If you're fighting Flutter's layout system, you're building the wrong widget.
- **Use `AnimationController` + `CurvedAnimation` over implicit animations when timing precision matters.** `AnimatedContainer` is a shortcut — not a solution for hero moments.
- **Clip intentionally.** `ClipRRect`, `ClipPath`, and `ShaderMask` are design tools. Use them to create shapes and effects that feel custom. Unclipped widgets look unfinished at edges.
- **Slivers for scroll performance.** Any scrollable screen with more than 8–10 items must use `SliverList` / `SliverGrid`. `ListView` is a prototype tool.
- **`RepaintBoundary` around complex animated subtrees.** Isolate expensive paints. Your animations must hit 60fps on a mid-range Android device — not just a flagship.
- **Responsive to keyboard, safe areas, and dynamic text.** Every screen must not break when the keyboard appears, when a user enables large text, or when running on an unusual aspect ratio (foldables, tablets). These are not edge cases.
- **Never hardcode pixel values for spacing.** Use a spacing system (`AppSpacing.sm`, `AppSpacing.md`, etc.) or a base multiplier. Hardcoded values break at different densities.

---

## 9. The Two Review Gates

**Before any UI work is considered complete, pass both.**

### Gate 1 — The Interaction Test
Reason through every user gesture on the screen:
- Does every tap have instant, clear visual feedback?
- Do all transitions feel spatially coherent (things appear from where they make sense)?
- Is any animation longer than needed, or missing when expected?

If any interaction feels inert or jarring — it is not done.

### Gate 2 — The Identity Test
Mentally strip the app icon and name. Ask:
- Could this screen belong to any other app?
- Does it express the emotional identity established in step 0?
- Is there one unforgettable detail (per rule 7)?

If the screen could be from any app — it has no identity. Return to step 0.

---

## Summary — The Designer's Checklist

```
Before coding:
  [ ] Emotion named
  [ ] Metaphor named
  [ ] What it must NOT look like — named

During design:
  [ ] Color serves atmosphere, not decoration
  [ ] Typography has personality and hierarchy
  [ ] Layout has rhythm and intentional tension
  [ ] Every animation has a stated reason
  [ ] Components are designed from function, not assembled

Before marking done:
  [ ] Interaction test passed
  [ ] Identity test passed
  [ ] One unforgettable detail exists
```

Build UI that earns attention. Then earns trust. Then earns loyalty. In that order.