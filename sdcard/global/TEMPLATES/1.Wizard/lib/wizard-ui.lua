---- #########################################################################
---- #                                                                       #
---- # Wizard UI - Loads appropriate UI module based on radio type          #
---- #                                                                       #
---- #########################################################################

-- Detect radio type BEFORE loading any UI modules
-- Check for native lvgl support (color radios have this built-in)
-- We must check this before any module creates a fake lvgl global

local isColorRadio = (lvgl ~= nil) and (type(lvgl.Page) == "function" or type(lvgl.clear) == "function")

if isColorRadio then
    -- Color radio - load LVGL wrapper
    return loadScript("/TEMPLATES/1.Wizard/lib/wiz-color-ui.lua")()
elseif LCD_W == 212 then
    -- BW 212x64 radio
    return loadScript("/TEMPLATES/1.Wizard/lib/wiz-bw212-ui.lua")()
else
    -- BW 128x64 radio (or fallback)
    return loadScript("/TEMPLATES/1.Wizard/lib/wiz-bw128-ui.lua")()
end
