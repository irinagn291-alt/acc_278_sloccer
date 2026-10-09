<!-- gf-brief source=371443e88a718517a47b1c8f941044d3e0f579b0157afc17217cf45a21ea2f7f written=2026-10-09T13:25:29+03:00 -->
# Inkwell

## What it is

Inkwell is a daily practice sheet for people who count calligraphy strokes against a quota they set. You dip the nib to wet the ink, then stroke while it is wet so today’s tally moves toward the sheet capacity. When the tally meets that capacity, the day files as filled; a dry stroke is a bleed and does not count.

## Launch and onboarding

A cold launch shows a system launch screen with no words, then the app.

If the introduction has not been finished, three pages appear. Each page has an illustration, a title, a line of copy, a page count, **Next** or **Continue**, and **Skip**. **Skip** on any page, or **Continue** on the last page, finishes the introduction and opens **Today's sheet**. Both actions set a usable sheet capacity of 8 strokes if none is set yet. While that save is in progress, **Next**, **Continue**, and **Skip** do not accept another tap.

1. Title: **A sheet with a quota**. Body: **Count today's calligraphy strokes against the capacity you set for the page.** Page count: **Page 1 of 3**. Buttons: **Next**, **Skip**.
2. Title: **Dip, then stroke**. Body: **Dip opens eight seconds of wet ink. Stroke while it is wet and the tally moves. A dry stroke is a bleed and does not count.** Page count: **Page 2 of 3**. Buttons: **Next**, **Skip**.
3. Title: **File the day**. Body: **When the tally meets the sheet capacity, the day files as filled. Peel can lift the last counted stroke.** Page count: **Page 3 of 3**. Buttons: **Continue**, **Skip**.

If the introduction is already finished, launch goes straight to **Today's sheet**. If the sheet is still loading after a short wait, a redacted placeholder appears (VoiceOver: **Loading today's sheet**). If the sheet cannot be read, one of these notices can appear on **Today's sheet** (and on **Settings**): **The sheet file could not be read. Restored the last good folio.** or **The sheet file could not be read. Started from an empty folio.** If a later save fails: **The sheet could not be saved. The last stored marks are still here.** If erase fails: **The sheet could not be erased. The last stored marks are still here.** Calendar’s fallback line when no other notice is set: **The saved sheet could not be opened.**

## Screens

There is no tab bar. **Today's sheet** stays on screen. **Calendar**, **Charts**, **History**, and **Settings** open as sheets over it. Each sheet has a drag indicator and a trailing close control (VoiceOver: **Close**).

### Today's sheet

Title: **Today's sheet**.

Chrome (always present after the introduction, including on a blank day):

- **Calendar** — opens the Calendar sheet.
- **Charts** — opens the Charts sheet.
- **History** — opens the History sheet.
- **Settings** — opens the Settings sheet.

**Blank day** (no marks yet today):

- Headline: **The sheet is blank.**
- Body: **Dip the nib to open the wet window, then stroke today's lines.**
- **Dip** (VoiceOver: **Dip the nib**) — opens eight seconds of wet ink and replaces this empty state with the practiced sheet. **Stroke the sheet** and **Peel** are not on this empty state.

**After the first mark today** (a dip is enough), the practiced sheet shows:

- Nib word: **Dry**, **Wet**, or **Filled**.
- When **Dry**: **Dip to open the wet window**. **Dip** is available.
- When **Wet**: **N seconds of wet ink** (the integer counts down; VoiceOver: **N seconds of wet ink remain**). **Dip** is dimmed and does nothing.
- When **Filled**: **Dip is closed on a filled sheet**. **Dip** is dimmed and does nothing.
- Capacity figure: **X of Y** (today’s counted strokes, then the capacity you set). Caption: **Strokes on this sheet, against the capacity you set**. A bar fills in proportion to that fraction, capped at full (VoiceOver: **Strokes X of Y**).
- A manuscript area draws one ink line per counted stroke, up to the capacity. If today has any bleeds, their count appears as a bare number in the corner (VoiceOver: **Sheet with N strokes**).
- **Latest lines** — up to the four most recent **Counted stroke** or **Dry bleed** rows, newest first, each with a medium-style date. Dips and fills are omitted. The heading is hidden until at least one counted stroke or bleed exists.

Bottom prompts and controls (not shown on a blank day):

- When wet: **The nib is wet. Stroke the sheet. N strokes remain.**
- When dry: **The nib is dry. Dip before you stroke, or a dry stroke is a bleed and does not count.**
- When filled: **Today's sheet is filled. Peel if you need the last stroke back.**
- **Stroke the sheet** — while wet, writes a counted stroke, draws a line, moves the tally, and gives a short haptic. If that stroke meets capacity, the nib becomes **Filled**. While dry, it still accepts the tap, writes a bleed, leaves the tally unchanged, and shows **That stroke was dry, so it is a bleed. Today's count stayed put.** While filled, the button is dimmed and does nothing (VoiceOver hint: **The sheet is already filled**). VoiceOver hints otherwise: **Writes a counted stroke** or **Writes a bleed and leaves the tally**.
- **Peel** (VoiceOver: **Peel the last stroke**) — dimmed until today has at least one counted stroke. When enabled, it asks: title **Peel the last stroke?**; message **The last counted stroke leaves the sheet and today's count drops by one.**; **Peel the stroke** removes today’s last counted stroke and shows **The last counted stroke is off the sheet.**; **Cancel** dismisses. If the tally then sits below capacity, the day is no longer filled. If a wet window is still open, the nib can read **Wet** again. Yesterday’s strokes cannot be peeled. Bleeds and dips stay.

**Dip** and **Stroke the sheet** refuse a second tap while a dip or stroke is already in progress. Spinners appear only if that work lasts more than a brief moment.

A new local calendar day starts a new blank sheet. Earlier days stay in Calendar, Charts, and History.

### Calendar

Title: **Calendar**.

**Previous month** and **Next month** move the month. The centre label is the month and year in the device’s locale (for example, October 2026).

Empty month: **This month is still blank.** **Filled and partial days show up here after you stroke the sheet.** **Back to the sheet** dismisses.

When any day in that month has a mark, every day of the month is listed. Each row shows a medium-style date and **Blank**, **Partial**, or **Filled**. A dip alone makes today **Partial**. Rows are not buttons.

Error: **The calendar could not be read.** plus the notice line. **Try again** reloads. Use **Close** to dismiss if reload does not help.

### Charts

Title: **Charts**.

Empty: **No weekly marks yet.** **Stroke a wet sheet and the week will show volume, streak, and bleeds.** **Back to the sheet** dismisses.

Populated list:

- Section **Weekly stroke volume** — one row per week that has marks, medium-style date of the week’s start, and the counted-stroke total. A dip alone can create a week row whose total is 0. If that section has no counted-stroke weeks: **This week has no counted strokes yet.**
- Section **Fill streak** — **Filled days in a row** and a whole number. The streak counts consecutive filled days ending today if today is filled, otherwise ending yesterday.
- Section **Dry bleeds** — **Dry strokes** and a whole number of bleeds across all days.

Error: **Charts could not be read.** plus the notice. **Try again** reloads. **Back to the sheet** dismisses.

### History

Title: **History**.

Empty: **No strokes on the sheet yet.** **Dip, then stroke. Counted strokes and dry bleeds will list here in order.** **Back to the sheet** dismisses.

Populated: one row per counted stroke or bleed, oldest first. Title **Stroke** or **Bleed**, a medium-style date, and a badge **Counted** or **Miss**. Dips and fills do not appear. Rows are not buttons.

Error: **History could not be read.** plus the notice. **Try again** reloads. **Back to the sheet** dismisses.

### Settings

Title: **Settings**.

Section **Sheet capacity**:

- Field placeholder **Strokes on a full sheet**, number pad, prefilled with the current capacity.
- **Save capacity** — stores a whole number of at least 1. Keyboard toolbar: **Done** dismisses the pad.
- Live errors: **Use a whole number of strokes.** **Enter a capacity of at least 1 stroke.** After a failed save: **That capacity could not be saved.** **Save capacity** is dimmed while an error is showing or a save is in progress.
- Lowering capacity so today’s counted strokes already meet it files today as filled. Raising it above today’s count clears today’s filled state so you can stroke again. Extra counted strokes already on the day are not deleted.

Section **Marks**:

- If there are no marks: **There are no marks to export yet.**
- Otherwise **Export marks** opens the system share sheet. The shared text is one line per mark, in order: **Dip** date, **Stroke** date, **Bleed** date, or **Fill** date.

Section **Sheet**:

- **Show the introduction again** — closes Settings and returns the three introduction pages. Existing marks and capacity stay. **Skip** or **Continue** brings you back to **Today's sheet**.
- **Erase every mark** — asks: title **Erase every mark?**; message **Every mark on this sheet will be erased.**; **Erase every mark** wipes every mark and the introduction-complete flag and restores the default capacity of 8; **Cancel** dismisses. After a successful erase, finishing or closing Settings shows the introduction again.

Section **Contact**:

- **Contact Inkwell** — opens the support page.

## Features

- Daily **Today's sheet** with a stroke quota (**sheet capacity**).
- **Dip** to open **eight seconds of wet ink**.
- **Stroke the sheet** while **Wet** to write a **counted stroke** and move the **tally**.
- A **dry stroke** is a **bleed** / **dry bleed** and does not move the tally.
- **Peel** lifts today’s last counted stroke.
- A day **files as filled** when the tally meets capacity.
- Day readings: **Blank**, **Partial**, **Filled**.
- Nib readings: **Dry**, **Wet**, **Filled**.
- **Calendar** of filled and partial days by month.
- **Charts**: **Weekly stroke volume**, **Fill streak** (**Filled days in a row**), **Dry bleeds** (**Dry strokes**).
- **History** of **Stroke** / **Bleed** rows marked **Counted** or **Miss**.
- **Latest lines** of recent counted strokes and dry bleeds.
- Set **Strokes on a full sheet** and **Save capacity**.
- **Export marks**.
- **Show the introduction again**.
- **Erase every mark**.
- **Contact Inkwell**.

## Behaviours that can look like bugs

- On a blank day there is no **Stroke the sheet** until you tap **Dip**. That is the start of the day; after the dip the practiced sheet appears.
- **Dip** does nothing while the nib is **Wet**. Wait until the countdown ends and the nib reads **Dry**, then dip again.
- **Dip** does nothing while the nib is **Filled**. **Peel** if you need the last stroke back, or wait for the next calendar day.
- **Stroke the sheet** looks quieter when the nib is **Dry**, but it still works. The result is a bleed and **That stroke was dry, so it is a bleed. Today's count stayed put.** Dip first if you want the tally to move.
- **Stroke the sheet** is dimmed when the day is filled. Use **Peel** or raise capacity in Settings.
- **Peel** is dimmed until today has a counted stroke. Bleeds cannot be peeled. Confirm with **Peel the stroke**.
- The wet window is only eight seconds. After it ends the nib is **Dry** even if the day is only partial. Dip again before the next counted stroke.
- You cannot dip a second time during the same wet window.
- The introduction blocks the sheet until **Skip** or **Continue**.
- **Save capacity** stays dimmed while the field shows **Use a whole number of strokes.** or **Enter a capacity of at least 1 stroke.** Type a whole number of at least 1.
- **Calendar** stays on **This month is still blank.** until that month has any mark (a dip alone is enough to mark today **Partial**).
- **Charts** stays on **No weekly marks yet.** until there is a mark that belongs to a week. A dip alone can instead show a week row with 0 counted strokes.
- **History** stays on **No strokes on the sheet yet.** until a counted stroke or a bleed exists. Dips and fills never appear there.
- **Latest lines** shows at most four rows and omits dips and fills.
- After **Erase every mark**, the introduction returns. That is intended.
- **Show the introduction again** loops the same three pages on purpose; marks are still there when you finish.
- At local midnight, **Today's sheet** becomes blank for the new day even if yesterday was filled.
- Changing capacity can fill or unfill today immediately. If you lower capacity below strokes already counted, the figure can read as more strokes than capacity until you peel.
- **Next**, **Continue**, **Skip**, **Dip**, **Stroke the sheet**, **Peel**, **Save capacity**, and **Try again** ignore extra taps while their work is running.

## Starter content and resume

None. A device install starts with a blank sheet after the introduction and a capacity of 8.

Unfinished work resumes. Counted strokes, bleeds, dips, fills, capacity, and whether the introduction was finished all come back on the next launch. A wet window does not stay wet after those eight seconds. **Show the introduction again** does not discard marks. **Erase every mark** does.

## Permissions

None.

## Absent

Login or accounts, in-app purchase, ads, analytics, user-generated content, account deletion flow, and an App Tracking Transparency prompt are all absent.

## Data and support

Everything stays on this device. Support is **Contact Inkwell** in Settings.

## Scanning and health

None.

## Platform

Copy is English. Dates and numbers follow the device’s region, calendar, and time zone. Portrait only, light appearance only, full screen on iPhone and iPad. Minimum iOS 17.0.

## Category

Lifestyle.
