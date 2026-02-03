---- #########################################################################
---- #                                                                       #
---- # Copyright (C) OpenTX                                                  #
---- #                                                                       #
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

-- Author: Airhamer / ErnestWorrel (2026)
-- ui_bw128.lua
-- Place in: <bw128x64>/TEMPLATES/1.Wizard/core/
-- Universal wizard for all radio types - uses core_engine and ui modules
-- BW 128x64 UI (e.g. Radiomaster GX12, FrSky X9D, FrSky QX7, Pocket ...)
-- Owns: drawing, blink timer.  Events handled by ui_common.
--
-- Blink: manual timer toggle (BLINK flag unreliable on 128x64 hardware)
-- Images: lcd.drawPixmap(x, y, path)   — 1-bit BMP

local ui = {}
local common = loadScript("/TEMPLATES/1.Wizard/core/ui_common.lua")()

----------------------------------------------------------------------
-- State
----------------------------------------------------------------------
local uiState = { field = 0, edit = false, dirty = true }

-- Blink: ~500 ms period via getTime() ticks (100 Hz)
local blinkOn        = true
local lastBlinkTick  = 0

local function updateBlink()
    local t = getTime()
    if t - lastBlinkTick >= 50 then
        lastBlinkTick = t
        blinkOn       = not blinkOn
        uiState.dirty = true
    end
end

----------------------------------------------------------------------
function ui.resetPage()
    uiState.field = 0
    uiState.edit  = false
    uiState.dirty = true
end

function ui.init()
    uiState.field = 0
    uiState.edit  = false
    uiState.dirty = true
end

----------------------------------------------------------------------
-- Main handler
----------------------------------------------------------------------
function ui.handlePage(page, text, radio, nav, event)
    local fields   = common.getFields(page)
    local fieldMax = math.max(0, #fields - 1)
    if uiState.field > fieldMax then uiState.field = fieldMax end

    -- ---- events (all logic in common) ----
    local evResult = common.handleEvents(page, fields, fieldMax, uiState, nav, event)
    if evResult == "exit"    then return "exit" end
    if evResult == "handled" then
        -- ENTER toggles edit; reset blink phase so it starts visible
        if uiState.edit then blinkOn = true end
        return 0
    end

    -- No event this tick — keep blink running if editing
    if uiState.edit then updateBlink() end

    -- ---- drawing ----
    if not uiState.dirty then return 0 end
    uiState.dirty = false
    lcd.clear()

    -- Title bar (inverted)
    lcd.drawText(2, 0, text, INVERS)

    -- Layout split when image present
    local hasImage = (page.image ~= nil)
    local divX     = hasImage and (LCD_W / 2 - 1) or LCD_W
    if hasImage then
        lcd.drawLine(divX, 8, divX, LCD_H - 1, DOTTED, 0)
    end

    -- ---- page content ----
    if page.options or page.fields then
        local single = (#fields == 1)

        if single then
            local valText = common.resolveValue(fields[1])
            local flags   = uiState.edit and (blinkOn and INVERS or 0) or INVERS
            lcd.drawText(4,  LCD_H - 10, ">>>", 0)
            lcd.drawText(28, LCD_H - 10, valText, flags)
        else
            local lineH  = 10
            local startY = LCD_H - (#fields * lineH * 2) - 2
            for i, field in ipairs(fields) do
                local flags = 0
                if i - 1 == uiState.field then
                    flags = uiState.edit and (blinkOn and INVERS or 0) or INVERS
                end
                local y = startY + (i - 1) * (lineH * 2)
                lcd.drawText(4,  y,         field.label, 0)
                lcd.drawText(4,  y + lineH, ">>>", 0)
                lcd.drawText(28, y + lineH, common.resolveValue(field), flags)
            end
        end

    elseif page.summary then
        local lineH      = 9
        local maxVisible = math.floor((LCD_H - 18) / lineH)
        local scroll     = (uiState.field >= maxVisible)
                           and (uiState.field - maxVisible + 1) or 0
        local y = 10
        for i = scroll + 1, math.min(#fields, scroll + maxVisible) do
            local flags = (i - 1 == uiState.field) and INVERS or 0
            lcd.drawText(4, y, fields[i].label .. ": " .. (fields[i].value or "?"), flags)
            y = y + lineH
        end
        lcd.drawText(4, LCD_H - 8, "ENTER=apply", SMLSIZE)

    elseif page.isFinish then
        lcd.drawText(4, 24, "Setup Complete!", 0)
        lcd.drawText(4, 38, "Press EXIT", SMLSIZE)

    else
        lcd.drawText(4, 20, text, SMLSIZE)
    end

    -- Image (right half, bottom-aligned, 48 px tall assumed)
    if hasImage then
        pcall(function()
            lcd.drawPixmap(LCD_W / 2 + 2, LCD_H - 48, page.image)
        end)
    end

    return 0
end

return ui
