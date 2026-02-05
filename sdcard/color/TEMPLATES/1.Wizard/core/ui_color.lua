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
-- ui_color.lua
-- Color screen UI (e.g. RadioMaster TX16S MKII, FrSky X12)
-- Owns: drawing.  Events handled by ui_common.
--
-- Key differences:
--   - LCD_W / LCD_H are large (480x320 typical, but we use LCD_W/LCD_H so it adapts)
--   - Images: lcd.drawBitmap(path, x, y)   — PNG
--   - MIDSIZE flag available for larger text
--   - BLINK flag works
--   - lcd.drawFilledRect for colored title bar
--   - Richer layout: bigger margins, taller lines, image can be large

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

    -- Title bar: filled rect + white text
    local titleH = 30
    lcd.drawFilledRectangle(0, 0, LCD_W, titleH, GREY)
    lcd.drawText(12, 6, text, MIDSIZE)

    -- Layout: image on right if present
    local hasImage  = (page.image ~= nil)
    -- Reserve roughly 40 % of width for image zone on large screens
    local imgZoneW  = math.floor(LCD_W * 0.40)
    local divX      = hasImage and (LCD_W - imgZoneW - 2) or LCD_W
    if hasImage then
        lcd.drawLine(divX, titleH, divX, LCD_H - 1, SOLID, GREY)
    end

    -- ---- page content ----
    if page.options or page.fields then
        local single  = (#fields == 1)
        local lineH   = 28
        local textOff = 6   -- vertical offset within a line for baseline

        if single then
            -- Single field: value in middle of content area
            local valText = common.resolveValue(fields[1])
            local flags   = uiState.edit
                            and (MIDSIZE + BLINK + INVERS)
                            or  (MIDSIZE + INVERS)
            local y = titleH + math.floor((LCD_H - titleH - lineH) / 2)
            lcd.drawText(16, y,            ">>>", MIDSIZE)
            lcd.drawText(56, y,            valText, flags)
        else
            -- Multi-field: stacked in content area
            local totalH = #fields * lineH
            local startY = titleH + math.floor((LCD_H - titleH - totalH) / 2)
            for i, field in ipairs(fields) do
                local flags = 0
                if i - 1 == uiState.field then
                    flags = uiState.edit
                            and (INVERS + BLINK)
                            or  INVERS
                end
                local y = startY + (i - 1) * lineH
                lcd.drawText(16, y,  field.label, SMLSIZE)
                lcd.drawText(16, y + 13, ">>>", SMLSIZE)
                lcd.drawText(52, y + 13, common.resolveValue(field), flags)
            end
        end

    elseif page.summary then
        local lineH      = 20
        local maxVisible = math.floor((LCD_H - titleH - 24) / lineH)
        local scroll     = (uiState.field >= maxVisible)
                           and (uiState.field - maxVisible + 1) or 0
        local y = titleH + 8
        for i = scroll + 1, math.min(#fields, scroll + maxVisible) do
            local flags = (i - 1 == uiState.field)
                          and (INVERS)
                          or  
            lcd.drawText(16, y, fields[i].label .. ": " .. (fields[i].value or "?"), flags)
            y = y + lineH
        end
        lcd.drawText(16, LCD_H - 22, "ENTER = apply", SMLSIZE)

    elseif page.isFinish then
        lcd.drawText(16, LCD_H / 2 - 20, "Setup Complete!", MIDSIZE)
        lcd.drawText(16, LCD_H / 2 + 10, "Press EXIT to finish", SMLSIZE)

    else
        lcd.drawText(16, titleH + 20, text, SMLSIZE)
    end

    -- Image (right zone, vertically centred in content area)
    if hasImage then
        pcall(function()
            -- Approximate image as 96x96; centre vertically in content area
            local imgH = 96
            local imgY = titleH + math.floor((LCD_H - titleH - imgH) / 2)
            local bmp = Bitmap.open(page.image)
            if bmp then
                lcd.drawBitmap(bmp, divX + 8, imgY)
            end
        end)
    end

    return 0
end

return ui
