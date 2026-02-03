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
-- BW 128x64 UI module (e.g. Radiomaster GX12, pocket, frsky x7 etc
--
-- Navigation (matches original EdgeTX bw128 wizard style):
--   INC / DEC        : move between fields (not editing) / scroll value (editing)
--   ENTER            : toggle edit mode on selected field (field blinks)
--   NEXT_PAGE        : advance to next page
--   PREV_PAGE        : go back one page
--   EXIT             : exit wizard

local ui = {}

----------------------------------------------------------------------
-- Internal state
----------------------------------------------------------------------
local uiState = {
    field = 0,       -- Currently highlighted field index (0-based)
    edit  = false,   -- Is the current field in edit mode?
    dirty = true     -- Do we need to redraw?
}

----------------------------------------------------------------------
-- Blink: toggle INVERS on/off manually every ~500ms
----------------------------------------------------------------------
local blinkOn = true
local lastBlinkTick = 0
local function updateBlink()
    local t = getTime()
    if t - lastBlinkTick >= 50 then   -- ~500ms at 100Hz tick
        lastBlinkTick = t
        blinkOn = not blinkOn
        uiState.dirty = true
    end
end

----------------------------------------------------------------------
-- Called by core_engine when page changes
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
-- Build field list from page definition.
-- A page with page.options has one field.
-- A page with page.fields has multiple fields (future multi-field pages).
-- A summary page has read-only display fields.
----------------------------------------------------------------------
local function getFields(page)
    if page.fields then
        -- Future: multi-field pages (like plane tail config)
        return page.fields
    elseif page.options then
        -- Single selectable field - carry optional flag through
        return { { label = page.title, options = page.options,
                   getValue = page.getValue, setValue = page.setValue,
                   optional = page.optional } }
    elseif page.summary then
        -- Read-only summary lines
        local fields = {}
        for _, item in ipairs(page.summary) do
            fields[#fields + 1] = { label = item.label, value = item.getValue() }
        end
        return fields
    end
    return {}
end

----------------------------------------------------------------------
-- Main handler: events + draw
----------------------------------------------------------------------
function ui.handlePage(page, text, radio, nav, event)

    local fields   = getFields(page)
    local fieldMax = math.max(0, #fields - 1)

    -- Clamp field to valid range
    if uiState.field > fieldMax then uiState.field = fieldMax end

    --------------------------------------------------------------
    -- EVENT HANDLING
    --------------------------------------------------------------

    -- NEXT_PAGE: advance to next page
    if event == EVT_VIRTUAL_NEXT_PAGE then
        uiState.edit = false
        if page.isFinish then return "exit" end
        -- Summary page: apply before advancing
        if page.summary and page.onEnter then page.onEnter() end
        nav.goNext()
        uiState.dirty = true
        return 0
    end

    -- PREV_PAGE: go back
    if event == EVT_VIRTUAL_PREV_PAGE then
        uiState.edit = false
        if not nav.goPrev() then return "exit" end
        uiState.dirty = true
        return 0
    end

    -- EXIT: leave wizard
    if event == EVT_VIRTUAL_EXIT then
        return "exit"
    end

    -- ENTER: toggle edit mode on the current field
    if event == EVT_VIRTUAL_ENTER then
        local field = fields[uiState.field + 1]
        if field and field.options then
            uiState.edit  = not uiState.edit
            blinkOn       = true
            uiState.dirty = true
        elseif page.isFinish then
            return "exit"
        elseif page.summary then
            -- ENTER on summary = apply
            if page.onEnter then page.onEnter() end
            nav.goNext()
            uiState.dirty = true
        end
        return 0
    end

    -- INC / DEC: scroll value (editing) or move between fields (not editing)
    if event == EVT_VIRTUAL_INC or event == EVT_VIRTUAL_DEC then
        local isInc = (event == EVT_VIRTUAL_INC)

        if uiState.edit then
            -- Scroll the value of the current field
            local field = fields[uiState.field + 1]
            if field and field.options and field.getValue and field.setValue then
                local val    = field.getValue()
                local maxVal = #field.options - 1
                local minVal = field.optional and -1 or 0   -- -1 = "None" slot
                if isInc and val < maxVal then
                    field.setValue(val + 1)
                    uiState.dirty = true
                elseif not isInc and val > minVal then
                    field.setValue(val - 1)
                    uiState.dirty = true
                end
            end
        else
            -- Move between fields
            if isInc and uiState.field < fieldMax then
                uiState.field = uiState.field + 1
                uiState.dirty = true
            elseif not isInc and uiState.field > 0 then
                uiState.field = uiState.field - 1
                uiState.dirty = true
            end
        end
        return 0
    end

    -- Keep blink running while in edit mode
    if uiState.edit then updateBlink() end

    --------------------------------------------------------------
    -- DRAWING
    --------------------------------------------------------------
    if not uiState.dirty then return 0 end
    uiState.dirty = false

    lcd.clear()

    -- Title bar: text inverted across top
    lcd.drawText(2, 0, text, INVERS)

    -- Layout: if image exists, left half = fields, right half = image
    local hasImage = (page.image ~= nil)
    local divX     = hasImage and (LCD_W / 2 - 1) or LCD_W

    if hasImage then
        lcd.drawLine(divX, 8, divX, LCD_H - 1, DOTTED, 0)
    end

    --------------------------------------------------------------
    -- Page content
    --------------------------------------------------------------
    if page.options or page.fields then
        -- Single-field pages: title bar is the label, just show >>> value at bottom
        -- Multi-field pages: each field gets its own short label + >>> + value
        local lineH  = 10
        local single = (#fields == 1)
        local startY = single and (LCD_H - lineH) or (LCD_H - (lineH * #fields * 2) - 2)

        for i, field in ipairs(fields) do
            local isSelected = (i - 1 == uiState.field)
            local val        = field.getValue and field.getValue() or 0
            local valText
            if val == -1 and field.optional then
                valText = "None"
            else
                valText = (field.options and field.options[val + 1]) or (field.value or "?")
            end

            local flags = 0
            if isSelected then
                flags = uiState.edit and (blinkOn and INVERS or 0) or INVERS
            end

            if single then
                -- Just >>> value on one line at the bottom
                lcd.drawText(4, LCD_H - 10, ">>>", 0)
                lcd.drawText(28, LCD_H - 10, valText, flags)
            else
                -- Multi-field: label on one line, >>> value on next
                local y = startY + (i - 1) * (lineH * 2)
                lcd.drawText(4, y, field.label, 0)
                lcd.drawText(4, y + lineH, ">>>", 0)
                lcd.drawText(28, y + lineH, valText, flags)
            end
        end

    elseif page.summary then
        -- Summary: scrollable list of label: value
        local lineH      = 9
        local maxVisible = math.floor((LCD_H - 18) / lineH)
        local scroll     = 0
        if uiState.field >= maxVisible then
            scroll = uiState.field - maxVisible + 1
        end

        local y = 10
        for i = scroll + 1, math.min(#fields, scroll + maxVisible) do
            local f     = fields[i]
            local flags = (i - 1 == uiState.field) and INVERS or 0
            lcd.drawText(4, y, f.label .. ": " .. (f.value or "?"), flags)
            y = y + lineH
        end

        -- Bottom hint
        lcd.drawText(4, LCD_H - 8, "ENTER=apply", SMLSIZE)

    elseif page.isFinish then
        lcd.drawText(4, 24, "Setup Complete!", 0)
        lcd.drawText(4, 38, "Press EXIT", SMLSIZE)

    else
        -- Plain text page
        lcd.drawText(4, 20, text, SMLSIZE)
    end

    --------------------------------------------------------------
    -- Image (right half)
    --------------------------------------------------------------
    if hasImage then
        pcall(function()
            lcd.drawPixmap(LCD_W / 2 + 2, LCD_H - 48, page.image)
        end)
    end

    return 0
end

return ui
