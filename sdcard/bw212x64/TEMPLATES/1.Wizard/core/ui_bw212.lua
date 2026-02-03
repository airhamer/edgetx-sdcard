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
-- ui_bw212.lua
-- Place in: <bw212x64>/TEMPLATES/1.Wizard/core/
-- Universal wizard for all radio types - uses core_engine and ui modules-- ui_bw212.lua
-- BW 212x64 UI (e.g. FrSky X9D+)
-- Owns: drawing.  Events handled by ui_common.
--
-- Differences from bw128:
--   - LCD_W = 212  →  more horizontal room; image gets 80 px wide zone
--   - BLINK flag works reliably  →  no manual timer needed
--   - GREY_DEFAULT available     →  used for title bar background fill
-- Images: lcd.drawPixmap(x, y, path)   — 4-bit BMP

local ui = {}
local common = loadScript("/TEMPLATES/1.Wizard/core/ui_common.lua")()

----------------------------------------------------------------------
-- State
----------------------------------------------------------------------
local uiState = { field = 0, edit = false, dirty = true }

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

    -- ---- events ----
    local evResult = common.handleEvents(page, fields, fieldMax, uiState, nav, event)
    if evResult == "exit"    then return "exit" end
    if evResult == "handled" then return 0     end

    -- ---- drawing ----
    if not uiState.dirty then return 0 end
    uiState.dirty = false
    lcd.clear()

    -- Title bar: filled grey background, white text
    lcd.drawRect(0, 0, LCD_W, 12, SOLID, GREY_DEFAULT)
    lcd.drawText(4, 1, text, INVERS)

    -- Layout split
    local hasImage = (page.image ~= nil)
    -- Reserve 80 px on the right for the image zone
    local divX = hasImage and (LCD_W - 82) or LCD_W
    if hasImage then
        lcd.drawLine(divX, 12, divX, LCD_H - 1, DOTTED, 0)
    end

    -- ---- page content ----
    if page.options or page.fields then
        local single = (#fields == 1)

        if single then
            -- Single field: label already in title bar, value at bottom
            local valText = common.resolveValue(fields[1])
            local flags   = uiState.edit and INVERS + BLINK or INVERS
            lcd.drawText(6,  LCD_H - 11, ">>>", 0)
            lcd.drawText(30, LCD_H - 11, valText, flags)
        else
            -- Multi-field: label + value stacked, anchored to bottom
            local lineH  = 11
            local startY = LCD_H - (#fields * lineH * 2) - 2
            for i, field in ipairs(fields) do
                local flags = 0
                if i - 1 == uiState.field then
                    flags = uiState.edit and INVERS + BLINK or INVERS
                end
                local y = startY + (i - 1) * (lineH * 2)
                lcd.drawText(6,  y,         field.label, 0)
                lcd.drawText(6,  y + lineH, ">>>", 0)
                lcd.drawText(30, y + lineH, common.resolveValue(field), flags)
            end
        end

    elseif page.summary then
        local lineH      = 10
        local maxVisible = math.floor((LCD_H - 22) / lineH)
        local scroll     = (uiState.field >= maxVisible)
                           and (uiState.field - maxVisible + 1) or 0
        local y = 14
        for i = scroll + 1, math.min(#fields, scroll + maxVisible) do
            local flags = (i - 1 == uiState.field) and INVERS or 0
            lcd.drawText(6, y, fields[i].label .. ": " .. (fields[i].value or "?"), flags)
            y = y + lineH
        end
        lcd.drawText(6, LCD_H - 9, "ENTER=apply", SMLSIZE)

    elseif page.isFinish then
        lcd.drawText(6, 24, "Setup Complete!", 0)
        lcd.drawText(6, 40, "Press EXIT", SMLSIZE)

    else
        lcd.drawText(6, 20, text, SMLSIZE)
    end

    -- Image (right zone, bottom-aligned)
    if hasImage then
        pcall(function()
            lcd.drawPixmap(divX + 2, LCD_H - 48, page.image)
        end)
    end

    return 0
end

return ui
