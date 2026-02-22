# EdgeTX Model Wizard — Developer Reference

This document describes the page/settings API used by the model wizard scripts
(`fixed-wing.lua`, `heli.lua`, `multi-rotor.lua`) and the architecture that
makes them work on both colour and BW radios.

---

## Architecture Overview

```
WizardLoader.lua          — model type selection screen (BW & colour)
  └─ 1.Plane.lua          — entry point, passes "plane" to fixed-wing.lua
  └─ 4.Helicopter.lua     — entry point, calls heli.lua
  └─ 5.Multirotor.lua     — entry point, calls multi-rotor.lua
       │
       └─ lib/fixed-wing.lua   ─┐
       └─ lib/heli.lua         ─┤─ model wizard logic (platform-neutral)
       └─ lib/multi-rotor.lua  ─┘
              │
              └─ lib/wizard-ui.lua        — loaded at runtime
                    ├── Colour radio:  uses native LVGL directly
                    └── BW radio:      replaced at runtime by a shim
                          ├── wiz-bw128-ui.lua   (128×64, 1-bit mono)
                          └── wiz-bw212-ui.lua   (212×64, 4-bit grey)
```

The model scripts **never** call `lvgl.*` directly.  All display calls go
through the `wizard` object returned by `loadScript(wizard-ui.lua)`.  On
colour radios that object uses native LVGL.  On BW radios the entry-point
script (e.g. `4.Helicopter.lua`) loads the appropriate BW shim instead, which
replaces `wizard.clear()`, `wizard.build()`, `wizard.handleEvent()`,
`wizard.needsRefresh()`, and `wizard.refresh()` with BW-specific
implementations.

---

## Image Files

Always supply `.png` paths in model scripts.  BW UI modules substitute `.bmp`
automatically at draw time using the same base filename.

| Radio type   | Format            | Max size (approx.) | Location                              |
|--------------|-------------------|--------------------|---------------------------------------|
| Colour       | PNG, any depth    | full screen        | `IMG_DIR/<subdir>/<name>.png`         |
| BW 128×64    | BMP, 1-bit mono   | ~62 × 52 px        | `IMG_DIR/<subdir>/<name>.bmp`         |
| BW 212×64    | BMP, 4-bit grey   | ~110 × 52 px       | `IMG_DIR/<subdir>/<name>.bmp`         |

`IMG_DIR` = `/TEMPLATES/1.Wizard/img`

Each wizard script defines `IMG_SUBDIR` near the top.  This must match the
actual directory name on the SD card:

| Script           | IMG_SUBDIR    | SD card directory               |
|------------------|---------------|---------------------------------|
| `fixed-wing.lua` | `wizardType`  | `plane/`, `glider/`, or `wing/` |
| `heli.lua`       | `helicopter`  | `helicopter/`                   |
| `multi-rotor.lua`| `multirotor`  | `multirotor/`                   |

---

## Page Structure

Each wizard screen is built with three calls:

```lua
wizard.clear()

local p = wizard.page({
    title        = string,    -- wizard name at top (colour) / not shown (BW)
    subtitle     = string,    -- page title (colour) / first line (BW)
    bw_subtitle  = string,    -- (optional) shorter subtitle for BW radios
    hasPrevious  = bool,      -- enable/show Previous button
    hasNext      = bool,      -- enable/show Next button
    nextFunc     = function,  -- called when Next is pressed
    previousFunc = function,  -- called when Previous is pressed
    children1    = table,     -- left / top column: settings rows
    children2    = table,     -- right / bottom column: images and labels
                              --   pass nil if no image is needed
})

wizard.build(p)
```

---

## Settings Rows (`children1`)

### Horizontal layout — label on left, control(s) on right

Use for short labels.  This is the default and preferred layout.

```lua
wizard.settings({
    title    = string,    -- label shown on colour radios
    bw_title = string,    -- (optional) shorter label for BW radios
    visible  = function,  -- (optional) function() return bool end
    children = { <controls> },
})
```

### Vertical layout — label above, controls below

Use only when the label is too long for the BW horizontal layout even with
`bw_title` set, or when the control list is multi-line.  In `fixed-wing.lua`
this is used for the tail-type selector where the option strings are long.

```lua
wizard.settingsVertical({
    title    = string,
    bw_title = string,    -- (optional)
    visible  = function,  -- (optional)
    children = { <controls> },
})
```

---

## Controls (inside `settings.children`)

### Toggle (Yes / No switch)

```lua
{ type = "toggle",
  get  = function() return 0 or 1 end,
  set  = function(val) ... end }
```

### Choice (drop-down / scrolling list)

```lua
{ type    = "choice",
  values  = { "Option1", "Option2", ... },
  get     = function() return 1_based_index end,
  set     = function(val) ... end,   -- val is 1-based
  visible = function() return bool end }  -- (optional)
```

Note: the `get` function must return a **1-based** index.  The internal stored
value is always 0-based; the pattern `get = function() return field.value + 1 end`
/ `set = function(val) field.value = val - 1 end` is used throughout.

### Number edit

```lua
{ type = "numberEdit",
  min  = number,
  max  = number,
  get  = function() return value end,
  set  = function(val) ... end }
```

---

## Images (`children2`)

```lua
wizard.image({
    file        = string,              -- full path ending in .png
    visibleFunc = function() bool end, -- (optional) show conditionally
})
```

Multiple images can be placed in `children2`; use `visibleFunc` on each so
only the relevant one is shown at a time (e.g. different diagrams for
different tail configurations).

---

## Summary Rows

On the summary page, `children1` is populated with `wizard.summaryLine()` calls
instead of `wizard.settings()` calls.

```lua
wizard.summaryLine(label, channelIndex, textValue)
```

| Argument       | When to use                                 |
|----------------|---------------------------------------------|
| `channelIndex` | non-nil → shown as `"CH<n+1>"`              |
| `textValue`    | used when `channelIndex` is `nil`           |

---

## The `run()` Function

Every model wizard script's `run()` is a one-liner that delegates to the
shared implementation in `wizard-ui.lua`:

```lua
local function run(event, touchState)
    return wizard.run(event, touchState, page, pages, selectPage)
end
```

`wizard.run()` handles:
1. BW field navigation events (routed to `wizard.handleEvent`)
2. Continuous refresh in edit mode (via `wizard.needsRefresh` / `wizard.refresh`)
3. Hardware next/previous page button events
4. Exit detection via `wizard.exitWizard()`

To change any of this behaviour — for example to add a new BW radio type —
only `wizard-ui.lua` (or the BW shim) needs to change.

---

## How to Add a New Model Type

1. Create a lib script, e.g. `/TEMPLATES/1.Wizard/lib/boat.lua`, following
   the same structure as `fixed-wing.lua`, `heli.lua`, or `multi-rotor.lua`.

2. Create an entry-point script, e.g. `/TEMPLATES/1.Wizard/6.Boat.lua`:

   ```lua
   local RUN_DIR = "/TEMPLATES/1.Wizard/lib"
   local wizard  = loadScript(RUN_DIR .. "/boat.lua")()
   return { init = wizard.init, run = wizard.run, useLvgl = true }
   ```

3. Create image directories:
   - `/TEMPLATES/1.Wizard/img/boat/<name>.png`  (colour)
   - `/TEMPLATES/1.Wizard/img/boat/<name>.bmp`  (BW)

4. Add one entry to the `wizardList` table in `WizardLoader.lua`:

   ```lua
   { name = "Boat", script = RUN_DIR .. "/6.Boat.lua", image = "boat/boat" }
   ```
   The `image` field is `"subdir/basename"` relative to `IMG_DIR`, without
   extension.

5. That's it.  The loader handles display and navigation automatically.

---

## How to Add a Page to an Existing Wizard

1. Declare a `Fields` table for the new page's data.
2. Write a `runXxxConfig()` function following the pattern of the other pages.
3. Add `runXxxConfig` to the `pages` table in `init()`.
4. If the new page sets model properties, add logic to `createModel()`.
5. Add summary row(s) in `runConfigSummary()`.

---

## BW Label Length Guide

BW radios have limited horizontal space.  Use `bw_title` and `bw_subtitle` to
supply shorter alternatives without changing the colour radio display.

| Radio       | Approx. max chars (SMLSIZE) |
|-------------|----------------------------|
| 128×64      | ~12 chars per label column  |
| 212×64      | ~18 chars per label column  |

If even `bw_title` is too long, switch to `wizard.settingsVertical()` which
stacks the label above the control instead of beside it.

---

## Change Comment Convention

All changes made for BW radio support are marked with `-- [BW]`.  Bug fixes
are marked `-- [BUGFIX]`.  Typo corrections are marked `-- [TYPO FIX]`.
This makes it easy to identify every deviation from the original OpenTX source
when reviewing diffs or merging upstream changes.
