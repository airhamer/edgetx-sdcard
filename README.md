EdgeTX Unified Wizard System — Formal Design Document
1. Introduction
This document proposes and describes a unified, cross‑radio model‑creation wizard system for EdgeTX. The goal is to replace the existing fragmented wizard implementations with a single, maintainable, and extensible architecture that works consistently across all supported radio types, including:
    • Color radios
    • BW 212×64 radios
    • BW 128×64 radios
The new system preserves full compatibility with the existing color‑radio template mechanism while enabling BW radios to use the same templates, model logic, and UI flow.
This design significantly reduces code duplication, simplifies maintenance, and improves the user experience for RC hobbyists.
2. Background and Motivation
2.1 Current State
Historically, EdgeTX has maintained two separate wizard systems:
    1. Color radios
        ◦ Use a template‑based system
        ◦ Each template includes a .lua and .yml pair
        ◦ UI is color‑specific
        ◦ Logic is embedded in each template script
    2. BW radios (128×64 and 212×64)
        ◦ Use a completely different wizard implementation
        ◦ No template chooser
        ◦ No YAML‑based model definitions
        ◦ UI and logic are tightly coupled
        ◦ Limited template availability
This results in:
    • Duplicate logic across radio types
    • Inconsistent user experience
    • Difficulty adding new templates
    • High maintenance burden
    • Limited extensibility
2.2 Goals
The unified wizard system aims to:
    • Consolidate all wizard logic into a single shared engine
    • Provide a consistent experience across all radios
    • Reuse existing YAML templates
    • Support multiple templates on BW radios
    • Simplify future template creation
    • Reduce maintenance overhead
    • Improve clarity and organization of SD‑card structure
3. High‑Level Architecture
The unified wizard system is composed of four major components:
    1. Core Engine
    2. Model Logic Layer
    3. UI Abstraction Layer
    4. Template Entry Points
These components work together to provide a consistent wizard experience across all radios.
4. Core Components
4.1 Core Engine (core_engine.lua)
The core engine is responsible for:
    • Page navigation
    • Event handling
    • Rendering delegation
    • YAML model loading and saving
    • State management
    • Integration with model‑specific logic
It is radio‑agnostic and template‑agnostic.
4.2 Model Logic Layer (lib/<model>.lua)
Each model type (Plane, Glider, Wing, Helicopter, Multirotor) defines:
    • Wizard pages
    • Page transitions
    • Options and text
    • Model‑specific configuration logic
This layer contains no UI code and is shared across all radios.
4.3 UI Abstraction Layer
Three UI modules implement the same renderPage() API:
    • ui_color.lua
    • ui_bw212.lua
    • ui_bw128.lua
Each module handles:
    • Text layout
    • Option highlighting
    • Image placement
    • Screen‑specific constraints
This isolates all display differences from the rest of the system.
4.4 Template Entry Points (N.Name.lua)
Each template includes:
    • A wrapper script that loads the core engine
    • A YAML file defining the model structure
Example:
Code
1.Plane.lua
1.Plane.yml
Color radios require this pairing for template selection.
5. Directory Structure
The unified system introduces a clean, predictable directory layout:
Code
TEMPLATES/1.Wizard/
│
├── 1.Plane.lua
├── 1.Plane.yml
├── 2.Glider.lua
├── 2.Glider.yml
├── 3.Wing.lua
├── 3.Wing.yml
├── 4.Helicopter.lua
├── 4.Helicopter.yml
├── 5.Multirotor.lua
├── 5.Multirotor.yml
│
├── lib/
│   ├── plane.lua
│   ├── glider.lua
│   ├── wing.lua
│   ├── helicopter.lua
│   └── multi-rotor.lua
│
└── core/
    ├── core_engine.lua
    ├── radio_detect.lua
    ├── ui_common.lua
    └── radio_custom.lua (optional)
Display‑specific UI and images live under:
Code
<display>/TEMPLATES/1.Wizard/ui_<display>.lua
<display>/TEMPLATES/1.Wizard/img/<model>/
6. BW Wizard Entry Point
BW radios now use:
Code
scripts/wizard/wizard.lua
This script:
    • Presents a template chooser
    • Loads the selected template
    • Hands control to the unified engine
This brings BW radios in line with the color‑radio experience.
7. Reuse of Existing YAML Templates
The original color‑radio YAML templates are reused without modification. This ensures:
    • Full compatibility
    • No regression in model creation
    • No need to rewrite model definitions
This also means template authors only need to maintain one YAML file per model type.
8. Advantages
8.1 Benefits to EdgeTX Maintainers
    • Eliminates duplicated wizard code One engine, one set of templates, one set of UI modules.
    • Simplifies maintenance Fixes and improvements apply to all radios automatically.
    • Easier to add new templates Only one logic file and one YAML file required.
    • Cleaner SD‑card structure Predictable, organized, and easier for contributors to understand.
    • Future‑proof New radio types or screen sizes can be supported by adding a single UI module.
8.2 Benefits to RC Hobbyists
    • Consistent experience across radios Plane, Glider, Wing, Helicopter, and Multirotor templates behave the same everywhere.
    • More templates available on BW radios BW radios now gain access to the full template library.
    • Faster and clearer model setup Improved UI layout and consistent navigation.
    • More reliable model creation All radios use the same YAML definitions and logic.
    • Easier community support Tutorials and guides apply to all radios.
9. Compatibility and Migration
9.1 Backward Compatibility
    • Color radios continue to use the template system unchanged.
    • YAML templates remain in the same format.
    • Existing models are unaffected.
9.2 Migration Steps
    • Remove old wizard scripts from BW radios
    • Add unified wizard directories to YAML build manifests
    • Add new UI modules and images
    • Add unified engine and model logic
10. Conclusion
This unified wizard system modernizes and streamlines the EdgeTX model‑creation workflow. It replaces fragmented, duplicated code with a clean, modular, and extensible architecture that benefits both maintainers and end users.
By consolidating logic, reusing YAML templates, and abstracting UI differences, the system provides a consistent, reliable, and future‑proof foundation for model creation across all EdgeTX radios.
This design significantly improves maintainability, reduces complexity, and enhances the user experience for RC pilots.

Technical Appendix — Unified Wizard System
This appendix provides detailed technical information for EdgeTX maintainers and contributors implementing or extending the unified wizard system. It documents the internal architecture, APIs, directory structure, and the workflow for adding, removing, or modifying model templates.
A. Directory Structure Specification
The unified wizard system uses a predictable, cross‑radio directory layout:
Code
TEMPLATES/1.Wizard/
│
├── N.Name.lua                ← Template entry points (color radios require this)
├── N.Name.yml                ← YAML model definitions
│
├── lib/                      ← Model‑specific logic (shared across radios)
│   ├── plane.lua
│   ├── glider.lua
│   ├── wing.lua
│   ├── helicopter.lua
│   └── multi-rotor.lua
│
└── core/                     ← Shared wizard engine and utilities
    ├── core_engine.lua
    ├── radio_detect.lua
    ├── ui_common.lua
    └── radio_custom.lua      ← Optional user overrides
Display‑specific UI and images live under:
Code
<display>/TEMPLATES/1.Wizard/ui_<display>.lua
<display>/TEMPLATES/1.Wizard/img/<model>/
Where <display> is one of:
    • color
    • bw212x64
    • bw128x64
B. Core Engine API
The core engine exposes a single public API:
lua
engine.runWizard(pages)
Inputs
    • pages: A Lua table defining the wizard pages for a model template.
Outputs
    • Returns a table with a run(event) function that EdgeTX calls each frame.
Responsibilities
    • Page navigation
    • Event handling
    • State management
    • Delegation to UI modules
    • YAML model loading and saving
Page Definition Format
Each page is a table with:
lua
{
    id = "unique_id",
    title = "Page Title",
    text = {
        default = { "Line 1", "Line 2" },
        color   = { "Optional color text" },
        bw212   = { "Optional 212x64 text" }
    },
    options = { "Option A", "Option B" },  -- optional
    image = "image_name",                  -- optional
    next = "next_page_id"                  -- optional
}
C. UI Module API
Each UI module implements:
lua
ui.renderPage(page, text, state, radio)
Inputs
    • page: The page definition
    • text: The selected text variant
    • state: Wizard state (selection, current page index)
    • radio: Radio capabilities (screen size, image path, etc.)
Responsibilities
    • Draw title
    • Draw text
    • Draw options
    • Draw images
    • Respect screen constraints
UI Modules
    • ui_color.lua
    • ui_bw212.lua
    • ui_bw128.lua
D. Radio Detection API
radio_detect.lua returns a table describing the radio:
lua
{
    isColor = true/false,
    isBW212 = true/false,
    isBW128 = true/false,
    uiModule = "/path/to/ui_module.lua",
    imagePath = "/path/to/images/",
    validSwitch = { ... },
    defaultChannel = function(idx) ... end
}
This allows the core engine and templates to remain radio‑agnostic.
E. Template Entry Point Specification
Each template entry point (N.Name.lua) must:
    1. Load the core engine
    2. Load the model logic file
    3. Pass the model’s page definitions to the engine
Example:
lua
local engine = loadScript("/TEMPLATES/1.Wizard/core/core_engine.lua")()
local model  = loadScript("/TEMPLATES/1.Wizard/lib/plane.lua")()

return engine.runWizard(model.pages)
Color radios require:
Code
N.Name.lua
N.Name.yml
to be in the same directory.
F. YAML Template Requirements
YAML templates define:
    • Inputs
    • Mixers
    • Outputs
    • Curves
    • Logical switches
    • Special functions
    • Model metadata
The unified wizard system reuses the original color‑radio YAML templates without modification.
G. BW Wizard Entry Point
BW radios launch the wizard through:
Code
scripts/wizard/wizard.lua
This script:
    • Displays a template chooser
    • Loads the selected template
    • Hands control to the unified engine
H. Adding, Removing, or Modifying a Model Template
This section explains the workflow for maintainers or contributors who want to extend the wizard system.
H.1 Adding a New Model Template
To add a new template (e.g., “EDF Jet”), follow these steps:
1. Create a YAML model definition
Place it in:
Code
TEMPLATES/1.Wizard/6.EDFJet.yml
2. Create a template entry point
Code
TEMPLATES/1.Wizard/6.EDFJet.lua
Contents:
lua
local engine = loadScript("/TEMPLATES/1.Wizard/core/core_engine.lua")()
local model  = loadScript("/TEMPLATES/1.Wizard/lib/edfjet.lua")()

return engine.runWizard(model.pages)
3. Create the model logic file
Code
TEMPLATES/1.Wizard/lib/edfjet.lua
Define:
    • Pages
    • Options
    • Images
    • Navigation
4. Add images
Code
color/TEMPLATES/1.Wizard/img/edfjet/*.png
bw212x64/TEMPLATES/1.Wizard/img/edfjet/*.bmp
bw128x64/TEMPLATES/1.Wizard/img/edfjet/*.bmp
5. Add template to BW chooser
In scripts/wizard/wizard.lua, add:
lua
"6.EDFJet.lua"
6. Update build YAMLs
Add:
Code
/TEMPLATES/1.Wizard/6.EDFJet.lua
/TEMPLATES/1.Wizard/6.EDFJet.yml
H.2 Removing a Template
To remove a template:
    1. Delete N.Name.lua
    2. Delete N.Name.yml
    3. Delete lib/<model>.lua
    4. Remove its image folders
    5. Remove it from the BW chooser
    6. Remove it from build YAMLs
Color radios will no longer display it in the template list.
H.3 Modifying a Template
To modify a template:
1. Update the YAML file
Modify mixers, inputs, outputs, etc.
2. Update the model logic file
Modify:
    • Pages
    • Options
    • Navigation
    • Images
3. Update images (optional)
4. No changes needed to the core engine or UI modules
Templates are isolated from the engine.
I. Extensibility Considerations
The unified wizard system is designed to support:
    • New radio types
    • New screen sizes
    • New templates
    • New UI themes
    • User‑defined overrides
    • Third‑party template packs
The architecture is modular and stable.
J. Conclusion
This technical appendix documents the internal structure and extension workflow of the unified wizard system. It provides maintainers with a clear understanding of how the system operates and how to safely extend or modify it.
The unified architecture reduces duplication, improves maintainability, and delivers a consistent user experience across all EdgeTX radios.
