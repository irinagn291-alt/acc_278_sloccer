# Inkwell

Inkwell is a practice sheet for people who count daily calligraphy strokes against a fixed quota. The home screen is today's manuscript and ink tray. You dip the nib, then stroke while the ink is wet.

## Architecture

The sheet is an algebraic fold with three nib cases: Dry, Wet, and Filled. The day's marks are the fold itself. One type, `SheetFold`, owns every transition. Views only render the current case.

That fits this product because a stroke is not a free increment. It is legal only inside a wet window, it can file the day when the tally meets capacity, and a dry stroke is a different mark that must not move the tally. A single fold keeps those refusals in one place so the canvas cannot invent a fourth nib state.

## Why dip, then stroke

Dip writes a WetMark and opens an eight-second window. Stroke during that window writes a StrokeMark and moves today's tally toward the sheet capacity. Stroke on a dry nib writes a BleedMark and leaves the tally where it is. Reaching capacity writes a FillMark and folds the nib to Filled. A second dip while the nib is wet is refused. Dip on a filled sheet is refused. Peel removes only the last StrokeMark. An empty day reads as blank.

The opening sheet on the Simulator is already wet and one stroke shy of capacity, so the next tap is Stroke.

## Look

Art direction is an Art Deco poster in mixed media: flat gouache, cut paper, an engraved line, and one monumental object. Palette and type come from the app tokens (Georgia, the sheet colours). Asset files are filled in a later pass. Prompts:

- ink_AppIcon: Art Deco poster emblem, mixed media, a solid inkwell and broad nib centred and filling the canvas edge to edge. Flat gouache, engraved line, sunburst geometry. No text, no numerals, no rounded mask, no drop shadow, no alpha.
- ink_Splash: Vertical Art Deco poster, mixed media, a quiet uncluttered centre band with a distant inkwell low in the frame and a geometric border. Flat gouache, engraved line. No text. Fills the canvas.
- ink_Onboarding1: Cutout. A solid closed practice folio and a broad nib, Art Deco poster mixed media, gouache and cut paper, subject centred. Opaque subject, transparent corners, no plate, no lettering.
- ink_Onboarding2: Cutout. A hand mid-stroke with a wet nib on a small sheet, Art Deco poster mixed media, solid forms, subject centred. Opaque subject, transparent corners, no hollow outline, no lettering.
- ink_Onboarding3: Cutout. A thick filled manuscript stack with a solid seal on top, Art Deco poster mixed media, monumental and centred. Opaque subject, transparent corners, no lettering.
- ink_EmptyHome: Cutout. A solid closed ceramic inkwell with the lid on, waiting, Art Deco poster mixed media. Fully opaque subject, not glass, not a wire frame, transparent corners, no lettering.
- ink_EmptyList: Cutout. A solid closed signature of blank paper, tied, Art Deco poster mixed media, centred. Opaque subject, transparent corners, no lettering.
- ink_CardBackdrop: Abstract Art Deco geometric band, mixed media, low detail, suitable to sit behind type. Fills the canvas. No text, no object that competes with a title.
- ink_ControlFace: Cutout. The solid face of a broad calligraphy nib, Art Deco poster mixed media, metal-like but painted, centred. Opaque subject, transparent corners, not a hollow ring, no lettering.
- ink_TwistHero: Cutout. A monumental wet nib just lifted from an inkwell, one drop formed as a solid bead, Art Deco poster mixed media, centred. Opaque subject, transparent corners, no lettering.
- ink_SuccessMark: Cutout. A solid filled confirmation seal, thick and closed, Art Deco poster mixed media, occupying the middle. Not an outline, not a hollow ring. Opaque subject, transparent corners, no lettering.
- ink_HeaderDecor: Cutout. A wide Art Deco frieze of stepped fans and a thin rule, mixed media, solid ornament. Transparent corners, no lettering, no full-bleed plate.

## How this differs

Other capacity counters log a unit from a list or a row of tabs. Inkwell keeps one manuscript on screen. Calendar, charts, history, and settings are sheets over that page. The wet nib is the gate, not a timer beside a generic counter.

## Build

```bash
cd apps/Inkwell
xcodegen generate
xcodebuild build-for-testing -scheme Inkwell -destination 'generic/platform=iOS Simulator' -jobs 4 CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO SWIFT_TREAT_WARNINGS_AS_ERRORS=YES
```
