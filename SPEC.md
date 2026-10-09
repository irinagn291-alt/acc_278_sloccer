# Inkwell — Build Specification

> Portfolio app 164, batch pending. This document is the complete brief for
> building this application. Read all of it before writing any code. Anything
> not specified here is your decision, but must stay consistent with section 3.

**One-line positioning:** Count daily lettering strokes against your sheet capacity.

| Field | Value |
| --- | --- |
| Product name | Inkwell |
| Bundle identifier | `com.inkwell.sheet` |
| Domain | https://inkwell-sheet.pro |
| Contact URL | https://inkwell-sheet.pro/contact-us |
| Deployment target | iOS 17.0 |
| Swift version | 6.2, strict concurrency `complete` |
| Devices | iPhone and iPad, portrait |
| Interface style | Light |
| Asset prefix | `ink_` |
| User-Agent | `Inkwell/1.0 (iOS; +https://inkwell-sheet.pro)` |

---

## 1. Non-negotiable constraints

1. **No CocoaPods.** Dependencies come from Swift Package Manager, a local
   in-repo package, a vendored source folder, or nothing at all — per section 3.
2. **No shared code with other portfolio apps.** Business rules are re-implemented
   here under this app's own type names.
3. **All code, identifiers, comments, UI copy and the README are in English.**
4. **No launch gate, no WebView shell, no remote configuration, no analytics.**
   Guideline 4.2 (Minimum Functionality): this is a native SwiftUI product, not
   a web browsing experience. WKWebView / SFSafariViewController as UI is a
   reject. Push notifications, Core Location, and sharing do not make a
   browser or a thin catalog into an App Store app.
5. **Guideline 5.1.1 (Privacy):** never direct the user to grant camera access.
   A pre-permission screen may exist; the proceed button is **Continue** or
   **Next**, never "Allow camera", "Enable camera", "Grant camera", or a bare
   Allow/Enable that triggers `requestAccess`. The system alert is the only Allow.
6. **No CI files.** No `bitrise.yml`, no `Scripts/`, no `metadata/` folder.
7. **Assets are AI-generated.** No stock photography. SF Symbols may support
   small affordances but must never be the primary iconography.
8. **The app must build clean** with
   `xcodegen generate && xcodebuild -scheme Inkwell -destination 'generic/platform=iOS' build`.
9. **Nothing may echo another app in this batch** in naming, layout or visuals.
10. **This is not a calorie meal-slot tracker** unless family is `food_tracker`.
   Do not invent food logging to fill the brief.

---

## 2. Product core

The product is offline-first. No account, no sign-in, no ads, no in-app purchase,
no analytics SDK, no remote config. All user data stays on the device.

A letterform student dips the nib and strokes today's practice sheet so the tally reaches the sheet capacity and files as filled.

### 2.1 User flow

1. Stroke the sheet once on home because seed left the nib wet one stroke shy of capacity
2. Dip the nib when the wet window expires so the next strokes count again
3. Open Calendar from the sheet chrome to see which days filed FillMark
4. Open Charts to read weekly stroke volume and BleedMark misses
5. Set sheet capacity and export marks in Settings

### 2.2 Essential behaviour

- Today stroke tally vs user-set sheet capacity on a fused tray-and-canvas rail
- Dip-then-stroke gate with an eight-second wet window and BleedMark on dry strokes
- Peel removes the last StrokeMark and restores tally without moving FillMark backward
- Calendar sheet keyed by YYYYMMDD showing filled and partial days
- Charts sheet for weekly totals, fill streak, and bleed discipline
- History sheet listing StrokeMarks and BleedMarks in stroke order
- Local-only UserDefaults persistence with debounced saves

---

## 3. Uniqueness assignment for Inkwell

| Axis | Assigned value |
| --- | --- |
| Architecture | **Inkwell ADT fold (Dry | Wet | Filled); the sheet is a fold over Strokes; Dip writes a WetMark and folds Dry to Wet with an eight-second window; Stroke on Wet writes a StrokeMark and increments Tally; Stroke on Dry writes a BleedMark and keeps Tally; reaching SheetCapacity writes a FillMark and folds Wet to Filled; Dip on Filled is refused; a second Dip while Wet is refused; Peel removes the last StrokeMark only; an empty day writes Blank** |
| UI approach | **UIKit shell hosting SwiftUI via UIHostingController · canvas-first** |
| Naming convention | **Inkwell / practice-sheet lexicon** |
| File organization | **By inkwell role (Sheet, Nib, Tally, Dip, WetMark, StrokeMark, BleedMark, FillMark)** |
| Dependency strategy | **None (zero external dependencies) · no SPM entry, no CocoaPods, no vendored source; UIKit, Core Graphics, AVFoundation and URLSession only** |
| Design direction | **huggingface · tray-plus-canvas · branded** |
| Typography | **Georgia** |
| Navigation pattern | **Sheet-locked chrome (the practice sheet canvas never leaves; Calendar, Charts, History and Settings arrive as sheets; dip and stroke fuse on Sheet)** |
| AI art style | **Art Deco poster · mixed-media** |
| Functional twist | **Dip-then-stroke (Dip opens an eight-second wet window; only Wet accepts Stroke; Stroke on Dry writes BleedMark; FillMark at SheetCapacity)** |
| Persistence | **UserDefaults+Codable · one Chart root record holding Islands, Books, Sessions, Runs and Rhumbs, encoded under a single key with a debounced save after each mark** |
| Screen composition | see 3.6 |

### 3.0 Product concept

This is the product the contracts below are assigned to. Do not substitute another.

**Family** — metric_capacity

**Core** — A letterform student dips the nib and strokes today's practice sheet so the tally reaches the sheet capacity and files as filled.

**Audience** — People who count daily calligraphy or lettering strokes against a fixed sheet quota and want a wet-nib gate, not a timer or a generic counter grid.

**User flow**

1. Stroke the sheet once on home because seed left the nib wet one stroke shy of capacity
2. Dip the nib when the wet window expires so the next strokes count again
3. Open Calendar from the sheet chrome to see which days filed FillMark
4. Open Charts to read weekly stroke volume and BleedMark misses
5. Set sheet capacity and export marks in Settings

**Essential features**

- Today stroke tally vs user-set sheet capacity on a fused tray-and-canvas rail
- Dip-then-stroke gate with an eight-second wet window and BleedMark on dry strokes
- Peel removes the last StrokeMark and restores tally without moving FillMark backward
- Calendar sheet keyed by YYYYMMDD showing filled and partial days
- Charts sheet for weekly totals, fill streak, and bleed discipline
- History sheet listing StrokeMarks and BleedMarks in stroke order
- Local-only UserDefaults persistence with debounced saves

**Twist** — Dip-then-stroke. Home is today's practice sheet and ink tray. Dip writes a WetMark, folds Dry to Wet, and opens an eight-second wet window. Stroke on Wet writes a StrokeMark and increments today's tally toward SheetCapacity. Stroke on Dry writes a BleedMark and keeps the tally. When tally reaches SheetCapacity, FillMark folds Wet to Filled. Dip on Filled is refused. A second Dip while Wet is refused. Peel drops the last StrokeMark and may reopen Wet if tally sits below capacity. Seed already Dips into Wet with tally at capacity minus one so the opening tap is Stroke. Home verb: stroke-the-sheet — not tick-the-lit-bead and not crest-the-weir. Local only.

**Why this is not a repeat** — Same family as metric vs capacity but a new home verb: wet-nib dip gates each stroke on one manuscript canvas. It is not Soroban's lantern circuit across multiple counters, not Castellum or Phreatic hydration, not Batten's savings clip, and not the generic five-tab log-one-unit chrome without a refusal mechanic.

### 3.0a Craft from the shipped portfolio

Full craft is in KNOWLEDGE.md. Follow it. Do not copy type names or layouts.
- Home: Today metric vs capacity — only if you add a real second verb. Prefer another family.
- Invariant: If you must: one unit log, capacity formula, calendar. Do not ship the 5-tab chrome (Home/Calendar/History/Charts/Settings) as the uniqueness.
- Never: This family is a clone cluster. Pick a rare verb or a different family.
- Taste DNA is section 7.6. Do not invent a second look.
- A TabView with exactly three tabs is the factory stamp — use two or four-to-five destinations, or a different chrome. `-ReviewScreen today|log|goals` are launch keys, not tabs.

### 3.1 Architecture contract

The practice sheet is an algebraic fold with three cases, Dry, Wet, and Filled, and that sheet is itself a fold over the day's strokes. Dip writes a WetMark and folds Dry to Wet for eight seconds, after which the nib returns to Dry with no extra mark; a second Dip while Wet is refused, and Dip on Filled is refused. Stroke on Wet writes a StrokeMark and increments Tally, while Stroke on Dry writes a BleedMark and keeps Tally. Reaching SheetCapacity writes a FillMark and folds Wet to Filled. Peel removes the last StrokeMark only, restores Tally by one, and reopens Wet when Tally sits below capacity inside a still-open wet window, leaving FillMarks on earlier days unchanged and clearing today's FillMark only when today's tally drops below capacity. An empty day writes Blank, one Sheet type owns every transition, views only render the fold, and unit tests cover Dip, Stroke, BleedMark, FillMark, and Peel.

Put a short comment block at the top of each principal type stating the role it
plays in this architecture. The README must justify the pattern for this product.

### 3.2 UI contract

A UIKit shell owns the window. SheetHostController embeds the practice sheet with UIHostingController, and every other surface is another hosted SwiftUI view. The sheet is canvas-first: one SwiftUI Canvas is the manuscript and fills the remaining height, with the ink tray and the capacity rail fused on that same screen. Dip, Stroke, and Peel are native Buttons on that canvas, minimum 44pt, contentShape on the whole control, VoiceOver labels on icon-only chrome. Calendar, Charts, History, and Settings are stock List and Form screens. The Canvas stays on Sheet alone. Primary Stroke uses a ButtonStyle with default, pressed, disabled, and loading; Peel uses a destructive variant. Reduce Motion fades the group in at once; otherwise tray and canvas reveal in 40 to 60ms steps, capped at 360ms. One haptic fires on an accepted StrokeMark. The ui axis string is never a visible title.

### 3.3 Naming contract

Convention: Inkwell / practice-sheet lexicon.

Examples to follow: `SheetFold`, `WetMark`, `strokeTheSheet()`, `sheetCapacity`

### 3.4 Dependency contract

Zero external dependencies. project.yml has no packages key, no CocoaPods, and no vendored source. The target may import UIKit, SwiftUI, Core Graphics, Foundation, and UserDefaults only. AVFoundation stays unlinked because the app does not use the camera. URLSession stays unlinked because the product is local only and the cgi search.pl endpoint is not called.

### 3.5 Navigation contract

Sheet-locked chrome: the practice sheet canvas stays mounted for the life of the window. There is no TabView and no counter-list home. Calendar, Charts, History, and Settings are modal sheets from the sheet chrome. Dip and Stroke stay on Sheet. Read ProcessInfo.processInfo.arguments once, after onboarding is complete. `-ReviewScreen today` leaves Sheet in place. `-ReviewScreen log` presents History. `-ReviewScreen goals` presents Settings, where sheet capacity and export live. Extra keys `calendar` and `charts` present those sheets. Onboarding uses Next or Continue, full width, at the bottom of each page.

### 3.6 Screen composition contract

Sheet-root practice canvas with ink tray and capacity rail; Calendar, Charts, History and Settings arrive as sheets over sheet-locked chrome; no tab bar and no separate counter list home.

Onboarding is three full pages: what the sheet is, dip then stroke, and a filled day. Skip writes a default SheetCapacity and a completion flag. The Simulator seed marks onboarding complete.

Sheet is the root and the mechanic. The tray holds the nib state in words (Dry, Wet, Filled) plus Dip. The canvas is today's manuscript, with stroke lines already on the page when seeded. The capacity rail shows Tally against SheetCapacity through NumberFormatter. Stroke is the primary verb and is enabled when the nib is Wet. Peel sits on the sheet. Chrome buttons open Calendar, Charts, History, and Settings. A Blank day, before any marks exist, is a full-page empty state: a cutout, the headline "The sheet is blank.", one line inviting a dip, and Dip as a full-width bottom button. Seeded home is a used sheet, one stroke shy of capacity, nib already Wet, so the next tap is Stroke.

Calendar is a sheet. Days are Int keys in YYYYMMDD form from Calendar.current.startOfDay. Each day reads as filled, partial, or blank, with a word or mark besides color. Empty month copy fills the page.

Charts is a sheet of stock rows: weekly stroke volume, fill streak, and BleedMark misses. It is not a second Canvas.

History is a sheet listing StrokeMarks and BleedMarks in stroke order. Its empty state is a full page with a cutout, one headline, one line, and a button back to the sheet.

Settings is a sheet: edit SheetCapacity, export the local mark list, re-run onboarding, reset with a confirmation that names the folio and says the marks will be erased, and a contact link to https://inkwell-sheet.pro/contact-us. iPhone and iPad both use the full width. The canvas and lists take the remaining height.

Section 5 lists the logical functions that must exist. This section decides how
they are grouped into actual screens. Where the two disagree, this section wins.

A TabView with exactly three tabs is the factory stamp — use two or four-to-five destinations, or a different chrome. `-ReviewScreen today|log|goals` are launch keys, not tabs.

---

## 4. Target file organization

Scheme: **By inkwell role (Sheet, Nib, Tally, Dip, WetMark, StrokeMark, BleedMark, FillMark)**

```
Inkwell/
  Shell/SheetHostController.swift
Sheet/SheetFold.swift
Sheet/SheetCanvas.swift
Sheet/CalendarSheet.swift
Sheet/ChartsSheet.swift
Sheet/HistorySheet.swift
Sheet/SettingsSheet.swift
Nib/NibFold.swift
Tally/Tally.swift
Dip/Dip.swift
WetMark/WetMark.swift
StrokeMark/StrokeMark.swift
BleedMark/BleedMark.swift
FillMark/FillMark.swift
  Assets.xcassets/
```

Adapt the leaf files to the architecture, but the top-level shape is fixed. Do
not create a `Utils/` or `Helpers/` dumping ground.

---

## 5. Screens

Build the screens named in section 3.6. The labels below are logical;
actual type names follow this app's naming convention.

### 5.1 Onboarding
Three to four pages. Explains the product, writes initial settings, sets a
completion flag. Skip still writes sensible defaults. Re-runnable from Settings.

### 5.2 Home
A first-class screen for **Home**. Must render empty, populated and error states.

### 5.3 Calendar
A first-class screen for **Calendar**. Must render empty, populated and error states.

### 5.4 Charts
A first-class screen for **Charts**. Must render empty, populated and error states.

### 5.5 History
A first-class screen for **History**. Must render empty, populated and error states.

### 5.6 Settings
A first-class screen for **Settings**. Must render empty, populated and error states.

### 5.7 Settings
Holds: re-run onboarding, reset all data (confirmed), and the contact link to
the domain contact-us URL.

### 5.8 Twist screen
See section 12. The twist needs at least one screen of its own plus a surface on the home screen.


---

## 6. Domain model

Minimum entities, named per this app's convention:

- **MetricRecord** — named per this app's convention.
- **CapacityRecord** — named per this app's convention.
- Plus whatever the twist in section 12 requires.


---

## 7. Design system

Direction: **huggingface · tray-plus-canvas · branded**

### 7.1 Palette

| Token | Hex | Use |
| --- | --- | --- |
| `background` | `#FFFFFF` | Screen background |
| `surface` | `#FFFFFF` | Cards, rows, sheets |
| `ink` | `#0D1117` | Primary text and icons |
| `accent` | `#A38200` | Primary action, key figure, progress fill |
| `muted` | `#727478` | Secondary text, dividers, disabled |

The scaffold already wrote these exact values to `Inkwell/DesignTokens.swift`
(`DesignTokens.bg`, `.surface`, `.ink`, `.accent`, `.muted`, plus
`DesignTokens.fontFamily`). Reach every colour through `DesignTokens` — a
typed accessor on top of it is fine. Keep the file and its hex values; do not
move them into `Assets.xcassets` and never hard-code a hex string anywhere else.

### 7.2 Typography

Family: **Georgia**

Georgia is the only family, reached through one accessor with six steps: display, title, headline, body, caption, micro. Georgia-Bold carries the tally and the Stroke label. Georgia-Italic is the single playful moment, used only for the eight-second wet count. Body is about 17pt. Display is the tally, one or two short lines. Sizes use a relative Dynamic Type style, stay at least 12pt, and the sheet title still reads at the largest accessibility size. Tally, SheetCapacity, wet seconds, and dates go through NumberFormatter. No fixed point size that ignores Dynamic Type.

Define a type scale of at most six steps behind one accessor and use only those
steps. Text stays legible at the largest Dynamic Type size.

### 7.3 Layout

- One base spacing unit (4 or 8 pt); only multiples of it.
- Corner radius and elevation are fixed by section 7.4, not chosen per screen.
- Every interactive element is at least 44x44 pt.

### 7.4 Component contract

Corner radius: **12pt** for cards, sheets and primary surfaces; **8pt** for chips, badges and small controls. Reach both through one accessor. Never a bare literal number, and never zero — a hard edge is not this app's design direction.

Elevation: **material** — SwiftUI `Material` (`.regularMaterial` / `.thinMaterial`), reused everywhere a surface sits above another.

Primary control: **bordered prominent** — primary actions use `.buttonStyle(.borderedProminent)` or an equivalent filled, bordered shape.

This is arithmetic, not a suggestion: every card, sheet, chip and button in this app uses these two radii and this elevation style. Do not introduce a second radius or a second elevation style.

### 7.5 Custom rendering scope

This app's `ui` axis is **UIKit shell hosting SwiftUI via UIHostingController · canvas-first**.

If that approach uses anything beyond stock SwiftUI/UIKit controls — `Canvas`, `CALayer`, Metal, SceneKit, SpriteKit, RealityKit, a hand-drawn `UIViewRepresentable`, or any other pixel-level custom rendering — confine it to exactly one hero surface on one screen (the mechanic's home view, or the one screen this axis exists to showcase). Every other screen — every list, every settings screen, every sheet, every secondary surface — is built from stock components: `List`, `Form`, `NavigationStack`, `TabView`, `Button`, `.sheet`, native `Text`/`Image`. A second custom-rendered surface elsewhere in the app is a defect, not a stylistic choice.

If **UIKit shell hosting SwiftUI via UIHostingController · canvas-first** is already fully native (no custom drawing layer), this section is satisfied automatically — there is nothing to confine.

The `ui` axis value is an implementation choice. It must never appear as a user-visible section title or label.

### 7.6 Taste DNA

Aesthetic: **agency** (High-end agency: huge type, air, one accent, hairline depth.)

Reference system: **huggingface** — steal rhythm and restraint, not their colours or logos.

Mood: **ML community hub. Sunny yellow accent, monospace identity, cheerful and dense.**.

Home rhythm (`tray-plus-canvas`, dense): Tray of materials, canvas of the work.

High-end agency: huge type, air, one accent, hairline depth. Layout `tray-plus-canvas`, density dense. Kit 12/8, material, bordered prominent. Palette recipe `branded`. Grouped reveals step 40-60ms, cap 360ms total. Last item must not arrive late. Reduce Motion: the group appears at once. Reduce Motion: fade only. Do not invent a second radius or a second accent.

Type move: Soft rounded UI type, one playful moment, no serif. Reference type feel: agency.

Motion (`stagger`): Grouped reveals step 40-60ms, cap 360ms total. Last item must not arrive late. Reduce Motion: the group appears at once.

Voice (`warm`): Human and brief. Empty states invite. Errors stay calm and useful.

Anti-slop from KNOWLEDGE.md applies. Taste never overrides contrast, 44pt hits, VoiceOver labels, or Reduce Motion.

---

## 8. UI and UX quality bar

Every item here is a defect if it is missing. Do not treat this as advice.

**Layout**

- Respect safe areas on every screen. Nothing sits under the notch, the Dynamic
  Island or the home indicator.
- The app is portrait-only on iPhone. Lock it in the Info settings and do not
  write rotation-dependent layout.
- No layout shift when asynchronous data arrives. Reserve the final size up
  front, or use a redacted placeholder of the same dimensions.
- Long product names must truncate gracefully, never push a number off screen.
  Numbers win; names truncate.
- Sibling cards, images and titles never overlap. Each cell owns its frame;
  `scaledToFill` is clipped to that cell. A chopped headline or two canvases
  in one slot is a defect, not a collage.
- Minimum tap target 44x44 pt for every interactive element, including small
  icon buttons and list accessories.
- Pick one base spacing unit and use only multiples of it. No arbitrary values.

**Keyboard**

- The grams field uses `.decimalPad`, and the decimal separator matches the
  user's locale.
- Content scrolls out from under the keyboard. The focused field is always
  visible.
- Tapping outside the field, or scrolling, dismisses the keyboard.
- Validate on the fly: reject negative and non-numeric input rather than
  crashing the parser later.

**Loading and state**

- Every asynchronous operation has a visible loading state.
- Guard against the spinner flash: if the work finishes in under 150 ms, do not
  show a spinner at all.
- Every list has a designed empty state containing a primary action, not just a
  sentence of text.
- Every error state offers a retry, and states plainly what failed.
- Disable the primary button while its action is in flight so it cannot be
  double-tapped into a double push or a duplicate entry.

**Typography and accessibility**

- All text scales with Dynamic Type. Verify at the largest accessibility size:
  nothing may clip or overlap.
- Every icon-only control has an `accessibilityLabel`. Decorative images are
  marked as decorative so VoiceOver skips them.
- Colour is never the only signal. Pair it with a label, a shape or an icon.
- Honour Reduce Motion: replace movement-heavy transitions with a fade.
- Meet contrast requirements against the palette in section 7. Check the muted
  colour against the background specifically; that is where these palettes fail.

**Formatting**

- Format every number with `NumberFormatter`, never string interpolation. Group
  separators and decimal separators must follow the locale.
- Energy is shown as a whole number of kcal. Macros are shown with at most one
  decimal place.
- Round only at the point of display. Stored values keep full precision.
- Day boundaries use `Calendar.current.startOfDay(for:)` in the user's current
  time zone. Handle the day changing while the app is open, and handle the
  short and long days that daylight saving produces.
- Unknown macro values render as a dash or the word "unknown", never as 0.

**Motion and feedback**

- One haptic on a successful commit (a food logged, a target saved). No haptic
  on navigation.
- Animations are short (0.2 to 0.35 s) and use a single shared easing curve.
- Nothing animates on first appearance of a screen except an intentional entry
  transition.

**Navigation**

- Back always works and never loses entered data without asking.
- A destructive action (delete a log row, reset all data) is confirmed.
- Modal sheets can always be dismissed; there is no dead end.
- Deep state is restorable: relaunching returns the user to a sane screen.


Every item here is a defect if it is missing. Section 7.4 fixed the numbers —
this is where they have to show up on screen.

**Hierarchy and density**

- Every screen has exactly one dominant element (a hero number, a canvas, a
  primary card) that the eye lands on first. A screen where every element has
  equal weight reads as a spreadsheet, not a product.
- Related content is grouped into a card or a section with the elevation
  style from 7.4, not left floating on the bare background.
- Unused flat background is not "minimal" — see the density rule in
  `KNOWLEDGE.md`. If a screen has room left after the mechanic and the
  content, add a secondary surface (a stat strip, a recent-activity card, a
  related-item row), not a `Spacer`.

**Components**

- Every card, sheet, chip, row and button in the app uses the corner radius
  and elevation from section 7.4. No screen introduces its own radius or its
  own shadow value "just for this one card".
- Buttons have a pressed state (`ButtonStyle` with a scale or opacity change
  on `isPressed`) and a disabled state that is visibly different, not just
  non-interactive.
- Chips and badges are pill or rounded-rect shaped per 7.4, never a bare
  `Text` with no background sitting where a control is expected.
- A functional control (add, filter, sort, close, more, share, delete) is an
  SF Symbol inside a properly hit-targeted `Button`. SF Symbols are fine and
  expected here — section 16 only bans them as the app's primary brand
  iconography (app icon, empty-state hero, onboarding art), which is what the
  generated assets in section 13 are for.

**Depth and material**

- At least one surface in the app (a sheet, a modal, a floating toolbar) uses
  the elevation style from 7.4 to visibly sit above the content behind it.
  A flat app with no depth anywhere reads as a wireframe.
- Icons and generated art sit on the surface colour from 7.1, never directly
  on a colour that makes their edges disappear.

**Motion as feedback, not decoration**

- The one dominant element in a screen (7.4's primary control, the mechanic's
  hero) responds visibly to touch: a scale, a colour shift, a haptic — pick
  at least one. A control that looks identical pressed and unpressed reads as
  broken, not calm.

**Taste DNA (section 7.6)**

- Home uses the assigned layout family and density. Three identical equal-weight
  cards, a leftover bento hole, or a second column structure copied down the
  page is a defect.
- Copy follows the assigned voice. No em-dash, no elevate/unlock/seamless, no
  emoji, no SECTION 01 labels.
- Motion follows the assigned personality and honours Reduce Motion with a fade.
  One signature motion per view. No glow stacked on glass stacked on spring.
- Tokens by intent: the live verb wears accent; delete does not wear primary.


---

## 9. Concurrency

The target builds with Swift 6.2 and `SWIFT_STRICT_CONCURRENCY = complete`. It
must compile with **zero concurrency warnings**. Warnings here become crashes
later, so they are not negotiable.

- All UI types are `@MainActor`. Annotate the type, not individual methods.
- Any value crossing an actor boundary is `Sendable`. Prefer immutable structs
  of primitives.
- Do not use `@unchecked Sendable`. If it is genuinely unavoidable, it needs a
  comment explaining what guarantees the safety.
- No mutable global state. No `static var` that is written after launch.
- Networking and storage APIs are `async` and honour cancellation. When the
  search query changes, cancel the in-flight task; do not let a stale response
  overwrite fresh results.
- Use structured concurrency. Avoid `Task.detached` unless there is a stated
  reason. Never fire a `Task` that outlives the view without owning it.
- Never use `DispatchQueue.main.asyncAfter` to paper over an ordering problem.
  Fix the ordering.
- `Timer` and notification observers are invalidated in `deinit` or on
  disappear.


---

## 10. Persistence engineering

Chosen technology: **UserDefaults+Codable · one Chart root record holding Islands, Books, Sessions, Runs and Rhumbs, encoded under a single key with a debounced save after each mark**

UserDefaults stores one Codable Folio as JSON under the single key ink.folio.v1, schemaVersion starting at 1. A debounced save runs after each accepted mark, and a flush runs when scenePhase becomes inactive or background and after Peel or reset. The assigned Chart root, with its Islands, Books, Sessions, Runs, and Rhumbs groups, is this Folio: day Sheets keyed by Int YYYYMMDD, the SheetCapacity record, nib sessions that store each WetMark window, weekly run totals for Charts, and the ordered marks WetMark, StrokeMark, BleedMark, and FillMark. Day edges use Calendar.current.startOfDay before the integer key. Decode failure restores the previous good snapshot, then an empty Folio. The in-memory Folio is the source of truth, so a failed write does not show marks that were not stored. Views never touch UserDefaults. resetAllData() is on Settings. The Simulator seed runs once behind ink.demo.v1, writes several prior days plus a Wet today at capacity minus one, marks onboarding complete, and is compiled out of device builds.

This app persists to **files on disk**. The following are mandatory.

- Write atomically. Either `Data.write(to:options: .atomic)` or write to a
  temporary file and `FileManager.replaceItemAt`. A non-atomic write that is
  interrupted leaves a truncated file and the app will not launch.
- Create the containing directory with
  `withIntermediateDirectories: true` before the first write.
- Every document carries a `schemaVersion` field from version 1, and the decoder
  switches on it.
- Decoding failure must be recoverable: keep the previous good file as a
  `.backup`, fall back to it, and if that also fails start from empty state and
  tell the user. Never crash on a corrupt file.
- All file IO happens off the main thread. The main thread never blocks on disk.
- Debounce writes during rapid edits, but force a flush when `scenePhase`
  becomes `.inactive` or `.background`, and after any destructive action.
- Exclude caches from backup with `URLResourceValues.isExcludedFromBackup` where
  appropriate; user data belongs in Application Support and should be backed up.
- Keep an explicit in-memory source of truth and treat the file as a projection
  of it, so a failed write never leaves the UI showing data that does not exist.


Regardless of technology:

- One seam between domain logic and storage; the UI never touches storage types.
- Writes survive a force-quit. Do not rely on `applicationWillTerminate`.
- Provide `resetAllData()`, used by tests and reachable from Settings.

---

## 11. Networking

- One client type owns both Open Food Facts endpoints.
- Set `User-Agent` on every request. Open Food Facts throttles clients that do
  not identify themselves.
- 15 second timeout. One retry on a transient transport failure, then a typed
  error. Do not retry a 404.
- Cancel the in-flight search when the query changes. Debounce input by roughly
  300 ms.
- Decode into DTO types that mirror the JSON exactly, then map to domain types.
  Never decode straight into your domain model.
- Dedicated `JSONDecoder` with `.useDefaultKeys`. Never `convertFromSnakeCase` —
  Open Food Facts keys like `energy-kcal_100g` break snake_case conversion.
- Resolve a scanned code with `GET /api/v2/product/<barcode>.json`, not a search.
- Open Food Facts data is user-contributed and frequently incomplete. Every
  numeric field is optional. A product with no energy value is a normal case
  that the UI must present, not an error.
- Some numeric fields arrive as strings. The decoder must accept both a number
  and a numeric string for every nutriment.
- `status` of `0` in the product response means not found. Map it to a distinct
  error case so the UI can offer manual entry.
- Never crash on malformed JSON. A decoding failure is a handled error.
- Cache every resolved product locally on success, so the app degrades to a
  working offline catalogue.


Set `User-Agent: Inkwell/1.0 (iOS; +https://inkwell-sheet.pro)` on every request. Never reuse another app's string.
No required remote catalog. Network only if this product actually needs it.

---

## 11b. App Store readiness

The app must be submittable without further work.

- `PrivacyInfo.xcprivacy` in the target, declaring the UserDefaults access API
  reason `CA92.1` and the file timestamp reason `C617.1`, with
  `NSPrivacyTracking` false and no collected data types.
- `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO` in the pbxproj so TestFlight
  does not sit on Missing Compliance.
- `NSCameraUsageDescription` written specifically for this app. Generic strings
  get rejected.
- `LSApplicationCategoryType` of `public.app-category.healthcare-fitness`.
- Portrait only, iPhone and iPad (`TARGETED_DEVICE_FAMILY = "1,2"`).
- No account, no sign-in, no delete-account flow, no in-app purchase, no ads, no
  user-generated content, and therefore no report or block UI.
- App Tracking Transparency is never invoked.
- The camera is the only sensitive permission requested.
- Guideline 5.1.1 (Privacy): do not encourage or direct the user to grant camera
  access. A pre-permission screen may exist, but the proceed button must be
  **Continue** or **Next** — never "Allow camera", "Enable camera",
  "Grant camera", or a bare Allow/Enable that calls `requestAccess`. The
  system dialog is the only Allow. Denied/restricted offers Open Settings.
- The app must not present itself as a clinician or as medical advice.
- Guideline 4.2 (Design — Minimum Functionality): the binary must be a native
  product, not a web browsing experience. No WKWebView / SFSafariViewController
  / UIWebView as home, a tab, or the primary UX. A content catalog, article
  reader, or site wrapper that could be a website is a reject. Push
  notifications, Core Location, and sharing do not make that acceptable.
- Guideline 1.4.1 (Safety — Physical Harm): if the binary shows health or
  medical recommendations, body-based targets, dosages, "you should" guidance,
  or product health claims (food, drink, supplement, remedy), put citations
  in the app. Tappable links to the sources, easy to find: same screen as the
  claim, or a Sources row one tap from Settings. Name the source (Open Food
  Facts, USDA FoodData Central, WHO, NIH MedlinePlus, …) and link it. A
  "not medical advice" footer without sources is a reject. A personal log
  that never advises does not invent claims to cite.
- Nutrition catalog data is credited to the database this app actually uses
  (Open Food Facts unless the spec names another). Credit is a tappable link,
  not a dead "OpenFoodFacts" label.


### First minute on a clean install (Guideline 2.1)

A reviewer judges completeness (Guideline 2.1) in the first minute on a clean
install. The loop must finish there without knowing the app's rules. Long form:
`docs/REVIEW-LESSONS-2026-09-25.md`.

- The home verb writes a visible object on the first tap of a clean install:
  a row, a card, a mark on the dial. No second screen needed to see it.
- Never leave the home control disabled until an unexplained condition holds
  ("two links first", "long press first", "add a volume first"). Accept the
  first input with sane defaults and show the rule afterwards.
- The twist fires after a successful write, as a visible consequence (a highlight,
  a caption, a next step), never instead of the write.
- A refusal is allowed only after the first success, and it must name the next
  tap that works.
- Nothing in the first session waits for midnight, a second day, a second item or
  a streak. A screen that can only fill later shows its action, not a wait.
- Every empty state names one action, and that action completes on the spot.
- Next to home there is at least one more screen that works on a clean install.
- The subtitle and the first description line name an everyday action a stranger
  understands. Coined words may decorate labels; each primary button still says
  what it does.
- A failed network lookup falls back to local data or typed input with a message;
  the loop still finishes offline.


Ignore the food-log and Open Food Facts lines above when they conflict with this
family. Category for this app is `public.app-category.lifestyle`. Camera permission only if the
product actually captures.

Project settings that follow from the above:

```yaml
INFOPLIST_KEY_UIUserInterfaceStyle: Light
INFOPLIST_KEY_UISupportedInterfaceOrientations: UIInterfaceOrientationPortrait
INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad: UIInterfaceOrientationPortrait
INFOPLIST_KEY_UIRequiresFullScreen: YES
INFOPLIST_KEY_ITSAppUsesNonExemptEncryption: NO
INFOPLIST_KEY_LSApplicationCategoryType: public.app-category.lifestyle
TARGETED_DEVICE_FAMILY: "1,2"
SWIFT_STRICT_CONCURRENCY: complete
```

---

## 12. Functional twist: Dip-then-stroke (Dip opens an eight-second wet window; only Wet accepts Stroke; Stroke on Dry writes BleedMark; FillMark at SheetCapacity)

Home is today's practice sheet and ink tray, and the persisted verb is stroke-the-sheet. Dip writes a WetMark, folds Dry to Wet, and opens an eight-second wet window during which Stroke writes a StrokeMark and increments Tally toward SheetCapacity. Stroke after the window, or on Dry, writes a BleedMark and leaves Tally unchanged. At SheetCapacity a FillMark folds Wet to Filled, Dip on that filled sheet is refused, and a second Dip while the nib is already Wet is refused. Peel drops the last StrokeMark, restores Tally, and reopens Wet when the count sits below capacity inside a live window, leaving earlier FillMarks in place. The Simulator seed runs once behind ink.demo.v1, marks onboarding complete, and leaves the nib Wet with Tally at SheetCapacity minus one so the first tap is Stroke; refused dips and dry bleeds stay unit-test fixtures.

This is the app's marketed differentiator. It must be:

- visible on the home screen, not buried in settings;
- backed by real persisted data, not a cosmetic flourish;
- covered by at least one unit test;
- described in the README as the reason a user would pick this app.

---

## 13. AI-generated assets

Art style: **Art Deco poster · mixed-media**


Base prompt, reused and extended for every asset:

```
Art Deco poster, mixed media. Flat gouache and cut-paper collage with an engraved line, stepped geometric borders, a sunburst, and one monumental object centred like a 1920s travel poster. Crisp printed grain, solid forms, no lettering, no numerals, no photoreal glass, no clay, no 3D render. Palette comes from the app tokens already chosen.
```

All 12 images below are required. Generate each one, export
as PNG, and add it to `Assets.xcassets` as its own image set named exactly as
given. Every name carries the `ink_` prefix.

### 13.1 App icon rules (strict)

The icon is rejected by App Store Connect if any of these are wrong:

- Exactly **1024 x 1024 px**.
- **No alpha channel.**
- sRGB colour profile, 8 bits per channel, PNG.
- **No text and no words** in the artwork.
- **No rounded corners and no built-in mask.**
- The subject stays inside the middle 80%.

### 13.2 Full asset list

| # | Image set | Size (px) | Alpha | Purpose |
| --- | --- | --- | --- | --- |
| 1 | `ink_AppIcon` | 1024x1024 | **NO** | App Store icon. NO alpha channel, NO transparency, NO text, NO rounded corners, NO drop shadow outside the canvas. |
| 2 | `ink_Splash` | 1290x2796 | fill | Launch background. The middle third must stay quiet so the wordmark reads on top. |
| 3 | `ink_Onboarding1` | 1024x1536 | **required cutout** | Onboarding page 1 illustration: what the app is for. |
| 4 | `ink_Onboarding2` | 1024x1536 | **required cutout** | Onboarding page 2 illustration: the main verb. |
| 5 | `ink_Onboarding3` | 1024x1536 | **required cutout** | Onboarding page 3 illustration: why they stay. |
| 6 | `ink_EmptyHome` | 1024x1024 | **required cutout** | Empty state: the home screen has nothing yet. Calm and inviting, never sad. |
| 7 | `ink_EmptyList` | 1024x1024 | **required cutout** | Empty state: a secondary list has no rows. |
| 8 | `ink_CardBackdrop` | 1200x800 | fill | Backdrop art for a primary card. Low contrast so text stays readable. |
| 9 | `ink_ControlFace` | 512x512 | **required cutout** | Custom control artwork used for the primary interactive element. |
| 10 | `ink_TwistHero` | 1024x1024 | **required cutout** | Hero art for the 'Dip-then-stroke (Dip opens an eight-second wet window; only Wet accepts Stroke; Stroke on Dry writes BleedMark; FillMark at SheetCapacity)' feature screen. |
| 11 | `ink_SuccessMark` | 512x512 | **required cutout** | Shown briefly when the primary action succeeds. |
| 12 | `ink_HeaderDecor` | 1200x600 | **required cutout** | Decorative header accent on the main screen. |

### Prompt per asset

**`ink_AppIcon`** — 1024x1024

```
Art Deco poster emblem, mixed media, a solid inkwell and broad nib centred and filling the canvas edge to edge. Flat gouache, engraved line, sunburst geometry. No text, no numerals, no rounded mask, no drop shadow, no alpha.
```

**`ink_Splash`** — 1290x2796

```
Vertical Art Deco poster, mixed media, a quiet uncluttered centre band with a distant inkwell low in the frame and a geometric border. Flat gouache, engraved line. No text. Fills the canvas.
```

**`ink_Onboarding1`** — 1024x1536

```
Cutout. A solid closed practice folio and a broad nib, Art Deco poster mixed media, gouache and cut paper, subject centred. Opaque subject, transparent corners, no plate, no lettering.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`ink_Onboarding2`** — 1024x1536

```
Cutout. A hand mid-stroke with a wet nib on a small sheet, Art Deco poster mixed media, solid forms, subject centred. Opaque subject, transparent corners, no hollow outline, no lettering.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`ink_Onboarding3`** — 1024x1536

```
Cutout. A thick filled manuscript stack with a solid seal on top, Art Deco poster mixed media, monumental and centred. Opaque subject, transparent corners, no lettering.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`ink_EmptyHome`** — 1024x1024

```
Cutout. A solid closed ceramic inkwell with the lid on, waiting, Art Deco poster mixed media. Fully opaque subject, not glass, not a wire frame, transparent corners, no lettering.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`ink_EmptyList`** — 1024x1024

```
Cutout. A solid closed signature of blank paper, tied, Art Deco poster mixed media, centred. Opaque subject, transparent corners, no lettering.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`ink_CardBackdrop`** — 1200x800

```
Abstract Art Deco geometric band, mixed media, low detail, suitable to sit behind type. Fills the canvas. No text, no object that competes with a title.
```

**`ink_ControlFace`** — 512x512

```
Cutout. The solid face of a broad calligraphy nib, Art Deco poster mixed media, metal-like but painted, centred. Opaque subject, transparent corners, not a hollow ring, no lettering.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`ink_TwistHero`** — 1024x1024

```
Cutout. A monumental wet nib just lifted from an inkwell, one drop formed as a solid bead, Art Deco poster mixed media, centred. Opaque subject, transparent corners, no lettering.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`ink_SuccessMark`** — 512x512

```
Cutout. A solid filled confirmation seal, thick and closed, Art Deco poster mixed media, occupying the middle. Not an outline, not a hollow ring. Opaque subject, transparent corners, no lettering.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`ink_HeaderDecor`** — 1200x600

```
Cutout. A wide Art Deco frieze of stepped fans and a thin rule, mixed media, solid ornament. Transparent corners, no lettering, no full-bleed plate.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```


### 13.3 Asset rules

- Cut-outs (everything except AppIcon, Splash, CardBackdrop): isolated subject,
  real PNG alpha, all four corners transparent. No square plate.
- Assets must be semantically different from each other.
- Record the exact prompt used for every asset in the README.
- SF Symbols are permitted only for close, chevron, share and similar system
  affordances.

Scanner frames, reticles, and seamless tiles are drawn in SwiftUI via `Path` or `Shape`. GenerateImage is not used for those. Every other in-app graphic (except AppIcon, Splash, CardBackdrop) is a **cutout**: isolated SOLID opaque subject in the center, real PNG alpha, all four corners transparent. An opaque square plate inside a circle or pentagon is a fail. A hollow glass box or wire frame with a transparent center is a fail.

---

## 14. Demo data

Seed a small local demo dataset for this family's entities so Simulator
screenshots are not empty. The same seed must mark onboarding complete and
fill the primary surface — otherwise `-ReviewScreen` never fires. Never seed
on a physical device. Guard with `#if targetEnvironment(simulator)` and
`ink.demo.v1`.

Seed the happy path: the home primary verb is enabled. The blocked / gated /
error state is a unit-test fixture, not Simulator home. Home chrome names the
job and the next tap in words a stranger knows. Axis values (`ui`, `naming`,
`architecture`) never become user-visible titles. A card that looks tappable
is a `Button`. A readout does not use button chrome.

---

## 16. Anti-patterns

The following will fail review:

- `try!`, `as!`, or force-unwrapping anything derived from the network, the
  database or a file.
- `fatalError` anywhere reachable at runtime. It is acceptable only for a
  programmer error in an initialiser that cannot fail in practice, and needs a
  comment.
- Swallowing an error with an empty `catch`.
- `print` used as production logging.
- A hard-coded hex colour outside the single colour accessor.
- A hard-coded font name outside the single typography accessor.
- An SF Symbol used as the app's brand iconography — the app icon, the
  empty-state hero, or onboarding art. Those come from section 13. SF Symbols
  are the right choice for every functional control (add, filter, sort,
  close, share, delete) — leaving those as bare text instead of a symbol is
  also a defect.
- Storing a value that can be computed (day totals, remaining budget, macro
  percentages).
- Blocking the main thread on disk or network work.
- `UIScreen.main` for sizing. Use the geometry the layout system gives you.
- Index positions used as list identity. Identity is a stable identifier.
- A view that reaches into the persistence layer directly, bypassing the
  architecture's designated seam.
- Business logic inside a `View` body or a `UIViewController` method, when the
  assigned architecture places it elsewhere.
- Copying a source file from another app in this batch.
- A `TabView` with exactly three tabs. That is the factory stamp — two or
  four-to-five destinations, or a different chrome. ReviewScreen keys are
  not tabs.


---

## 17. Tests

Add a unit test target `InkwellTests` covering at minimum:

1. The core domain invariant of this family (the thing that would be wrong if
   the calculator, decay, crate, or log lied).
2. Empty, populated and invalid input paths for the primary verb.
3. The section 12 twist logic.
4. One architecture-specific test proving the pattern holds.
5. A persistence round-trip: write, relaunch-equivalent reload, verify.
6. `Inkwell/ReviewLaunch.swift` (scaffold, keep it) parses `ProcessInfo.processInfo.arguments`.
   Read `ReviewLaunch.screen` once after onboarding:
   `-ReviewScreen today|log|goals` switches the running app's live navigation. Extra cover slugs open those screens.
   Cover that parser with a unit test. Do not host a `View` in the test.

---

## 18. README.md

Write `README.md` at the app folder root covering:

1. What the app does and who it is for.
2. The architecture used and **why** it suits this product.
3. The unique feature added and how it works.
4. The AI art style and the exact prompt used for every asset.
5. How this app differs from others in the batch.
6. Build instructions.

---

## 19. Definition of done

**Build**
- [ ] `xcodegen generate` succeeds.
- [ ] `xcodebuild -scheme Inkwell -destination 'generic/platform=iOS' build` succeeds.
- [ ] Zero new compiler warnings.
- [ ] Strict concurrency `complete` compiles clean.
- [ ] Test target passes.

**Function**
- [ ] Onboarding to first successful primary action works on a clean install.
- [ ] Every screen in section 3.6 exists and handles empty / filled / error.
- [ ] Reset and contact link live in Settings.
- [ ] Force-quitting immediately after a write loses nothing.
- [ ] Seeded home names the job and next tap; primary verb enabled.
- [ ] App reads `-ReviewScreen today|log|goals` after onboarding.

**Uniqueness**
- [ ] Architecture matches **Inkwell ADT fold (Dry | Wet | Filled); the sheet is a fold over Strokes; Dip writes a WetMark and folds Dry to Wet with an eight-second window; Stroke on Wet writes a StrokeMark and increments Tally; Stroke on Dry writes a BleedMark and keeps Tally; reaching SheetCapacity writes a FillMark and folds Wet to Filled; Dip on Filled is refused; a second Dip while Wet is refused; Peel removes the last StrokeMark only; an empty day writes Blank** with no leakage across layers.
- [ ] UI approach matches **UIKit shell hosting SwiftUI via UIHostingController · canvas-first**.
- [ ] Custom rendering, if any, is confined to one hero surface (section 7.5).
- [ ] Navigation matches **Sheet-locked chrome (the practice sheet canvas never leaves; Calendar, Charts, History and Settings arrive as sheets; dip and stroke fuse on Sheet)**.
- [ ] Screen composition follows section 3.6.
- [ ] Typography uses **Georgia** and nothing else.
- [ ] Palette matches section 7.1 exactly.
- [ ] Home rhythm and motion match section 7.6. No second look.

**Quality**
- [ ] Section 8 UI/UX bar satisfied end to end.
- [ ] Contact link present.
- [ ] `PrivacyInfo.xcprivacy` present and correct.
- [ ] README complete.

---

## 20. Build commands

```bash
cd Inkwell
xcodegen generate
xcodebuild build-for-testing -scheme Inkwell -destination 'generic/platform=iOS Simulator' -jobs 4 CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO -derivedDataPath '/Users/belzephyrus/Documents/gambling-factory/.artifacts/genesis/com.inkwell.sheet/DerivedData' SWIFT_TREAT_WARNINGS_AS_ERRORS=YES
xcodebuild -scheme Inkwell -destination 'generic/platform=iOS' -jobs 4 CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO -derivedDataPath '/Users/belzephyrus/Documents/gambling-factory/.artifacts/genesis/com.inkwell.sheet/DerivedData' SWIFT_TREAT_WARNINGS_AS_ERRORS=YES build
xcrun simctl list devices available
xcodebuild test-without-building -scheme Inkwell -destination 'platform=iOS Simulator,id=<UDID>' -jobs 4 -derivedDataPath '/Users/belzephyrus/Documents/gambling-factory/.artifacts/genesis/com.inkwell.sheet/DerivedData'
```

Signing is off only on that command line. Do not put CODE_SIGNING_ALLOWED, CODE_SIGNING_REQUIRED, CODE_SIGN_IDENTITY, DEVELOPMENT_TEAM, SWIFT_TREAT_WARNINGS_AS_ERRORS or -derivedDataPath in project.yml — they are command-line only. CI signs the archive. Leave CODE_SIGN_STYLE: Automatic as the scaffold set it. The exact simulator does not matter — use any available UDID from the list.
