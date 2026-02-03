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
-- Place in: global/TEMPLATES/1.Wizard/core/  should work with all radios.
-- Possibly remove completely later and have all radios run the templates from
--   the add model screen like color radios do.
-- ui_common.lua
-- Shared logic for all radio UI modules.
-- Owns: field construction, value resolution, and ALL event handling.
-- Each ui_*.lua owns only: drawing (layout, flags, image calls) and blink style.

local common = {}

----------------------------------------------------------------------
-- getFields: build field list from a page definition
--   page.fields   → multi-field (returned as-is)
--   page.options  → single field (wrapped, carries optional flag)
--   page.summary  → read-only label:value pairs
----------------------------------------------------------------------
function common.getFields(page)
    if page.fields then
        return page.fields
    elseif page.options then
        return { {
            label    = page.title,
            options  = page.options,
            getValue = page.getValue,
            setValue = page.setValue,
            optional = page.optional
        } }
    elseif page.summary then
        local fields = {}
        for _, item in ipairs(page.summary) do
            fields[#fields + 1] = { label = item.label, value = item.getValue() }
        end
        return fields
    end
    return {}
end

----------------------------------------------------------------------
-- resolveValue: display string for a field's current value
--   -1 + optional  →  "None"
--   otherwise      →  options[val+1]
----------------------------------------------------------------------
function common.resolveValue(field)
    local val = field.getValue and field.getValue() or 0
    if val == -1 and field.optional then
        return "None"
    end
    return (field.options and field.options[val + 1]) or (field.value or "?")
end

----------------------------------------------------------------------
-- clampValue: returns new value after applying delta, respects optional -1 min
----------------------------------------------------------------------
function common.clampValue(field, delta)
    local val    = field.getValue()
    local maxVal = #field.options - 1
    local minVal = field.optional and -1 or 0
    local newVal = val + delta
    if newVal < minVal then newVal = minVal end
    if newVal > maxVal then newVal = maxVal end
    return newVal
end

----------------------------------------------------------------------
-- optionalGet: factory for summary getValue closures on optional fields
--   Usage:  getValue = common.optionalGet(function() return data.x end, names)
----------------------------------------------------------------------
function common.optionalGet(getter, nameTable)
    return function()
        local v = getter()
        if v == -1 then return "None" end
        return nameTable[v + 1] or "?"
    end
end

----------------------------------------------------------------------
-- handleEvents: process all wizard events.  Identical across all radios.
--
--   uiState = { field, edit, dirty }   (owned by each ui_*.lua, passed by ref)
--   Returns:
--     "exit"      → caller must return "exit" to core_engine
--     "handled"   → event consumed, no draw needed (but dirty may be set)
--     nil         → no event fired this tick; caller should check dirty & draw
----------------------------------------------------------------------
function common.handleEvents(page, fields, fieldMax, uiState, nav, event)

    if event == EVT_VIRTUAL_NEXT_PAGE then
        uiState.edit = false
        if page.isFinish then return "exit" end
        if page.summary and page.onEnter then page.onEnter() end
        nav.goNext()
        uiState.dirty = true
        return "handled"
    end

    if event == EVT_VIRTUAL_PREV_PAGE then
        uiState.edit = false
        if not nav.goPrev() then return "exit" end
        uiState.dirty = true
        return "handled"
    end

    if event == EVT_VIRTUAL_EXIT then
        return "exit"
    end

    if event == EVT_VIRTUAL_ENTER then
        local field = fields[uiState.field + 1]
        if field and field.options then
            uiState.edit  = not uiState.edit
            uiState.dirty = true
            return "handled"
        elseif page.isFinish then
            return "exit"
        elseif page.summary then
            if page.onEnter then page.onEnter() end
            nav.goNext()
            uiState.dirty = true
            return "handled"
        end
        return "handled"
    end

    if event == EVT_VIRTUAL_INC or event == EVT_VIRTUAL_DEC then
        local delta = (event == EVT_VIRTUAL_INC) and 1 or -1

        if uiState.edit then
            local field = fields[uiState.field + 1]
            if field and field.options and field.setValue then
                local newVal = common.clampValue(field, delta)
                if newVal ~= field.getValue() then
                    field.setValue(newVal)
                    uiState.dirty = true
                end
            end
        else
            local newField = uiState.field + delta
            if newField >= 0 and newField <= fieldMax then
                uiState.field = newField
                uiState.dirty = true
            end
        end
        return "handled"
    end

    return nil   -- no event this tick
end

return common
