---- #########################################################################
---- #                                                                       #
---- # Copyright (C) EdgeTX                                                  #
-----#                                                                       #
---- # License GPLv2: http://www.gnu.org/licenses/gpl-2.0.html               #
---- #                                                                       #
---- # This program is free software; you can redistribute it and/or modify  #
---- # it under the terms of the GNU General Public License version 2 as     #
---- # published by the Free Software Foundation.                            #
---- #                                                                       #
---- # This program is distributed in the hope that it will be useful        #
---- # but WITHOUT ANY WARRANTY; without even the implied warranty of        #
---- # MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         #
---- # GNU General Public License for more details.                          #
---- #                                                                       #
---- #########################################################################
-- Update by: Airhamer / ErnestWorrel (2026)
-- wizard.lua
-- Place in: global/SCRIPTS/WIZARD/  should work with all radios.
-- Possibly remove completely later and have all radios run the templates from
--   the add model screen like color radios do.

local BASE_DIR = "/TEMPLATES/1.Wizard"
local CORE_DIR = BASE_DIR .. "/core"

----------------------------------------------------------------------
-- 1. Detect radio FIRST (before anything else)
----------------------------------------------------------------------
-- loadScript returns a function that returns radio_detect function
-- So we need to call it twice: ()() 
local radio = assert(loadScript(CORE_DIR .. "/radio_detect.lua"))()()

----------------------------------------------------------------------
-- 2. Load UI module based on radio type
----------------------------------------------------------------------
local ui = assert(loadScript(CORE_DIR .. "/" .. radio.uiModule))()

----------------------------------------------------------------------
-- Template list
----------------------------------------------------------------------
local IMG_DIR = "/TEMPLATES/1.Wizard/img"
local imgExt = radio.isColor and ".png" or ".bmp"

local TEMPLATES = {
    { file = "1.Plane.lua",       name = "Plane",      image = IMG_DIR .. "/plane/plane" .. imgExt },
    { file = "2.Glider.lua",      name = "Glider",     image = IMG_DIR .. "/glider/plane" .. imgExt },
    { file = "3.Wing.lua",        name = "Wing",       image = IMG_DIR .. "/wing/wing" .. imgExt },
    { file = "4.Helicopter.lua",  name = "Helicopter", image = IMG_DIR .. "/helicopter/heli" .. imgExt },
    { file = "5.Multirotor.lua",  name = "Multirotor", image = IMG_DIR .. "/multirotor/quadri" .. imgExt }
}

----------------------------------------------------------------------
-- State
----------------------------------------------------------------------
local state = {
    mode = "chooser",     -- "chooser" or "running"
    selection = 1,
    scroll = 0,           -- For scrolling on small screens
    activeWizard = nil
}

----------------------------------------------------------------------
-- Draw template chooser
----------------------------------------------------------------------
local function drawChooser()
    lcd.clear()
    
    -- Title
    local title = "Select Template"
    if radio.isColor then
        lcd.drawText(10, 10, title, MIDSIZE)
    else
        lcd.drawText(2, 2, title, SMLSIZE)
    end
    
    -- Calculate visible range for small screens
    local startY = radio.isColor and 40 or 16
    local lineHeight = radio.isColor and 20 or 10
    local maxVisible = math.floor((LCD_H - startY) / lineHeight)
    
    -- Auto-scroll to keep selection visible
    if state.selection > state.scroll + maxVisible then
        state.scroll = state.selection - maxVisible
    elseif state.selection <= state.scroll then
        state.scroll = math.max(0, state.selection - 1)
    end
    
    -- Draw visible items (left half of screen)
    local y = startY
    local leftWidth = LCD_W / 2
    for i = state.scroll + 1, math.min(#TEMPLATES, state.scroll + maxVisible) do
        local flags = SMLSIZE
        if i == state.selection then 
            flags = flags + INVERS 
        end
        lcd.drawText(radio.isColor and 10 or 4, y, TEMPLATES[i].name, flags)
        y = y + lineHeight
    end
    
    -- Show scroll indicator if needed
    if not radio.isColor and #TEMPLATES > maxVisible then
        local indicator = string.format("%d/%d", state.selection, #TEMPLATES)
        lcd.drawText(4, LCD_H - 8, indicator, SMLSIZE)
    end
    
    -- Draw image on right side (if exists)
    local selectedTemplate = TEMPLATES[state.selection]
    if selectedTemplate and selectedTemplate.image then
        -- Draw vertical divider line
        lcd.drawLine(LCD_W / 2 - 1, startY, LCD_W / 2 - 1, LCD_H - 1, DOTTED, 0)
        
        -- Try to draw the image in bottom right corner
        local imgX = LCD_W / 2 + 2
        local imgY = LCD_H - 48  -- Assume 48px tall images, adjust to bottom
        
        -- Attempt to load and draw bitmap
        pcall(function()
            if radio.isColor then
                lcd.drawBitmap(selectedTemplate.image, imgX, imgY)
            else
                lcd.drawPixmap(imgX, imgY, selectedTemplate.image)
            end
        end)
    end
end

----------------------------------------------------------------------
-- Main run function
----------------------------------------------------------------------
local function run(event)
    
    -- If template is running, delegate to it
    if state.mode == "running" and state.activeWizard then
        local result = state.activeWizard.run(event)
        -- If wizard returns "exit", go back to chooser
        if result == "exit" then
            state.mode = "chooser"
            state.activeWizard = nil
        end
        return 0
    end
    
    -- Otherwise, we're in chooser mode
    if event == EVT_VIRTUAL_NEXT or event == EVT_PLUS_FIRST then
        state.selection = math.min(#TEMPLATES, state.selection + 1)
    elseif event == EVT_VIRTUAL_PREV or event == EVT_MINUS_FIRST then
        state.selection = math.max(1, state.selection - 1)
    elseif event == EVT_VIRTUAL_ENTER then
        -- Load selected template
        local template = TEMPLATES[state.selection]
        local path = BASE_DIR .. "/" .. template.file
        
        -- Load and execute template (call it to get the loader function)
        local templateFunc = assert(loadScript(path))()
        -- Call the loader function with radio and ui to get wizard instance
        state.activeWizard = templateFunc(radio, ui)
        if state.activeWizard then
            state.mode = "running"
        end
    elseif event == EVT_VIRTUAL_EXIT then
        -- Exit wizard
        return 2
    end
    
    drawChooser()
    return 0
end

return { run = run }
