---- #########################################################################
---- #                                                                       #
---- # UI Module for 128x64 Black & White Radios                            #
---- # Compact display with scrolling and abbreviations                     #
---- #                                                                       #
---- # License GPLv2: http://www.gnu.org/licenses/gpl-2.0.html               #
---- #                                                                       #
---- #########################################################################

local IMG_DIR = "/TEMPLATES/1.Wizard/img"

local wizard = {}

-- Screen dimensions for 128x64
local LCD_W = 128
local LCD_H = 64

-- Create a minimal lvgl compatibility layer for BW radios
if not lvgl then
    _G.lvgl = {
        PERCENT_SIZE = 100,  -- Dummy value
    }
end

-- Current page state
local currentPage = nil
local scrollOffset = 0  -- For scrolling through items
local itemList = {}

-- Phase 2: Field navigation and editing state
local currentItem = 0   -- Which item is selected (for navigation)
local editMode = false  -- Are we in edit mode?
local editingItem = nil -- Which item we're editing
local editValue = nil   -- Temporary value while editing

-- Forward declarations
local drawPage
local getControlValueText
local buildItemList
local ensureVisible
local formatEditValue

local exit = false

function wizard.exitWizard()
    return exit
end

---------------------------------------------------------------------------
-- Text Abbreviation
---------------------------------------------------------------------------

local abbreviations = {
    ["Channel"] = "Ch",
    ["channel"] = "Ch",
    ["Switch"] = "Sw",
    ["switch"] = "Sw",
    ["Aileron"] = "Ail",
    ["aileron"] = "Ail",
    ["Elevator"] = "Ele",
    ["elevator"] = "Ele",
    ["Rudder"] = "Rud",
    ["rudder"] = "Rud",
    -- ["Elevon"] = "Elvn",  -- Don't abbreviate
    -- ["elevon"] = "Elvn",
    ["Flaps"] = "Flp",
    ["flaps"] = "Flp",
    ["Landing"] = "Lnd",
    ["Retracts"] = "Retr",
    ["Number of"] = "#",
    ["Do you have"] = "Have",
    ["Does your model have"] = "Have",
    ["Safety"] = "Saf",
    ["Additional"] = "Add'l",
    ["Settings"] = "Set",
    ["configuration"] = "config",
    ["Configuration"] = "Config",
    ["Right"] = "R",
    ["right"] = "R",
    ["Left"] = "L",
    ["left"] = "L",
    [" (right)"] = " (R)",
    [" (left)"] = " (L)",
    ["Throttle"] = "Thr",
    ["throttle"] = "Thr",
}

local function abbreviate(text)
    if not text then return "" end
    
    local result = text
    for long, short in pairs(abbreviations) do
        result = string.gsub(result, long, short)
    end
    
    return result
end

---------------------------------------------------------------------------
-- Page Builder Functions
---------------------------------------------------------------------------

function wizard.page(settings)
    return {
        type = "page",
        title = settings.title or "",
        subtitle = settings.subtitle or "",
        bw_title = settings.bw_title,
        bw_subtitle = settings.bw_subtitle,
        hasPrevious = settings.hasPrevious or false,
        hasNext = settings.hasNext or false,
        previousFunc = settings.previousFunc,
        nextFunc = settings.nextFunc,
        children1 = settings.children1 or {},
        children2 = settings.children2 or {}
    }
end

function wizard.finishedPage(settings)
    return {
        type = "finishedPage",
        title = settings.title or "Complete"
    }
end

function wizard.settings(settings)
    return {
        type = "settings",
        title = settings.title or "",
        bw_title = settings.bw_title,
        children = settings.children or {},
        visible = settings.visible
    }
end

function wizard.settingsVertical(settings)
    return {
        type = "settingsVertical",
        title = settings.title or "",
        bw_title = settings.bw_title,
        children = settings.children or {},
        visible = settings.visible
    }
end

function wizard.image(settings)
    return {
        type = "image",
        file = settings.file or "",
        visibleFunc = settings.visibleFunc
    }
end

function wizard.summaryLine(title, chNum, text2)
    local txt
    if chNum ~= nil then
        txt = "CH" .. (chNum + 1)
    else
        txt = text2 or ""
    end
    
    return {
        type = "summaryLine",
        label = title,
        value = txt
    }
end

---------------------------------------------------------------------------
-- Clear and Build
---------------------------------------------------------------------------

function wizard.clear()
    lcd.clear()
    currentPage = nil
    scrollOffset = 0
    itemList = {}
    -- Phase 2: Reset navigation/edit state
    currentItem = 0
    editMode = false
    editingItem = nil
    editValue = nil
end

function wizard.build(pageDefinition)
    currentPage = pageDefinition
    scrollOffset = 0
    -- Phase 2: Reset navigation/edit state when building new page
    currentItem = 0
    editMode = false
    editingItem = nil
    editValue = nil
    
    if currentPage then
        buildItemList(currentPage)
        drawPage(currentPage)
    end
end

---------------------------------------------------------------------------
-- Build Item List (flatten for scrolling)
---------------------------------------------------------------------------

buildItemList = function(page)
    itemList = {}
    
    if not page or not page.children1 then
        return
    end
    
    for _, child in ipairs(page.children1) do
        if child.visible == nil or child.visible() then
            if child.type == "settings" then
                -- Analyze the controls
                local visibleControls = {}
                if child.children then
                    for _, control in ipairs(child.children) do
                        if (control.visible == nil or control.visible()) and
                           (control.type == "toggle" or control.type == "choice" or control.type == "numberEdit") then
                            visibleControls[#visibleControls + 1] = control
                        end
                    end
                end
                
                if #visibleControls == 0 then
                    -- No controls, just skip
                elseif #visibleControls == 1 then
                    -- Single control: label + value on same line
                    itemList[#itemList + 1] = {
                        type = "setting",
                        label = child.bw_title or abbreviate(child.title),
                        child = child,
                        control = visibleControls[1],
                        editable = true
                    }
                else
                    -- Multiple controls: special handling
                    -- First control (usually toggle) on same line as label
                    itemList[#itemList + 1] = {
                        type = "setting",
                        label = child.bw_title or abbreviate(child.title),
                        child = child,
                        control = visibleControls[1],
                        editable = true
                    }
                    
                    -- Additional controls on separate lines (indented, no label)
                    for i = 2, #visibleControls do
                        itemList[#itemList + 1] = {
                            type = "settingValue",
                            control = visibleControls[i],
                            editable = true
                        }
                    end
                end
            elseif child.type == "settingsVertical" then
                -- Vertical: label on one line, value below
                itemList[#itemList + 1] = {
                    type = "settingLabel",
                    label = child.bw_title or abbreviate(child.title),
                    editable = false
                }
                if child.children then
                    for _, control in ipairs(child.children) do
                        if control.visible == nil or control.visible() then
                            local isEditable = (control.type == "toggle" or 
                                              control.type == "choice" or 
                                              control.type == "numberEdit")
                            itemList[#itemList + 1] = {
                                type = "settingValue",
                                control = control,
                                editable = isEditable
                            }
                        end
                    end
                end
            elseif child.type == "summaryLine" then
                itemList[#itemList + 1] = {
                    type = "summary",
                    label = abbreviate(child.label),
                    value = child.value,
                    editable = false  -- Summary lines are read-only
                }
            elseif child.type == "label" then
                itemList[#itemList + 1] = {
                    type = "label",
                    text = abbreviate(child.text or ""),
                    editable = false  -- Labels are read-only
                }
            end
        end
    end
end

---------------------------------------------------------------------------
-- Helper Functions
---------------------------------------------------------------------------

-- Ensure selected item is visible on screen
ensureVisible = function(itemIndex)
    local maxVisibleLines = 4
    
    -- If selected item is below visible area, scroll down
    if itemIndex >= scrollOffset + maxVisibleLines then
        scrollOffset = itemIndex - maxVisibleLines + 1
    end
    
    -- If selected item is above visible area, scroll up
    if itemIndex < scrollOffset then
        scrollOffset = itemIndex
    end
end

-- Format a value for display during editing
formatEditValue = function(control, value)
    if control.type == "toggle" then
        return value == 1 and "Y" or "N"
    elseif control.type == "choice" then
        if control.values and value >= 1 and value <= #control.values then
            local val = control.values[value]
            val = abbreviate(val)
            if #val > 8 then
                val = string.sub(val, 1, 6) .. ".."
            end
            return val
        end
        return "?"
    elseif control.type == "numberEdit" then
        return tostring(value)
    end
    return ""
end

---------------------------------------------------------------------------
-- Draw Page Function (with scrolling and selection highlight)
---------------------------------------------------------------------------

drawPage = function(page)
    if not page then
        return
    end
    
    lcd.clear()
    
    if page.type == "finishedPage" then
        lcd.drawText(1, 1, "Done!", 0)
        lcd.drawText(1, 12, "Model created", SMLSIZE)
        lcd.drawText(1, 22, "Press RTN", SMLSIZE)
        return
    end
    
    -- Line 1: Title bar
    local titleText = page.bw_title or abbreviate(page.title)
    local subtitleText = page.bw_subtitle or abbreviate(page.subtitle)
    local fullTitle = ""
    
    if titleText ~= "" and subtitleText ~= "" then
        fullTitle = titleText .. " - " .. subtitleText
        if #fullTitle > 20 then
            fullTitle = subtitleText
        end
    elseif subtitleText ~= "" then
        fullTitle = subtitleText
    else
        fullTitle = titleText
    end
    
    lcd.drawText(1, 1, fullTitle, 0)
    
    -- Lines 2-5: Display items (left 60px, right 68px for image)
    local y = 12
    local lineHeight = 10
    local maxVisibleLines = 4
    local leftWidth = 60
    local totalItems = #itemList
    
    -- Draw visible items
    for i = scrollOffset + 1, math.min(scrollOffset + maxVisibleLines, totalItems) do
        local item = itemList[i]
        local itemIndex = i - 1
        
        -- Determine display flags for label and value separately
        local labelFlags = SMLSIZE
        local valueFlags = SMLSIZE + RIGHT
        
        -- Highlight selected item (browse mode) - whole line
        if itemIndex == currentItem and not editMode then
            labelFlags = labelFlags + INVERS
            valueFlags = valueFlags + INVERS
        end
        
        -- Blink editing item (edit mode) - ONLY the value blinks
        -- Use BLINK flag which automatically blinks without needing refresh events
        if editMode and itemIndex == editingItem then
            valueFlags = valueFlags + BLINK + INVERS
        end
        
        if item.type == "setting" then
            -- Label and value on same line
            local valueText = ""
            
            -- Show edit value or actual value
            if editMode and itemIndex == editingItem then
                valueText = formatEditValue(item.control, editValue)
            elseif item.control then
                valueText = getControlValueText(item.control)
            end
            
            -- Label: normal (no blink)
            lcd.drawText(1, y, item.label, labelFlags)
            -- Value: blinks if editing (using valueFlags which has BLINK)
            lcd.drawText(leftWidth - 1, y, valueText, valueFlags)
            
        elseif item.type == "settingLabel" then
            -- Label only (value on next line)
            lcd.drawText(1, y, item.label, labelFlags)
            
        elseif item.type == "settingValue" then
            -- Value only (indented)
            local valueText
            
            -- Show edit value or actual value
            if editMode and itemIndex == editingItem then
                valueText = formatEditValue(item.control, editValue)
            else
                valueText = getControlValueText(item.control)
            end
            
            -- Apply BLINK if editing this item
            local valueOnlyFlags = SMLSIZE
            if editMode and itemIndex == editingItem then
                valueOnlyFlags = valueOnlyFlags + BLINK + INVERS
            end
            
            lcd.drawText(5, y, valueText, valueOnlyFlags)
            
        elseif item.type == "summary" then
            lcd.drawText(1, y, item.label, labelFlags)
            lcd.drawText(leftWidth - 1, y, item.value, valueFlags)
            
        elseif item.type == "label" then
            local text = item.text
            if #text > 10 then
                text = string.sub(text, 1, 8) .. ".."
            end
            lcd.drawText(1, y, text, labelFlags)
        end
        
        y = y + lineHeight
    end
    
    -- Scroll indicators
    if totalItems > maxVisibleLines then
        if scrollOffset > 0 then
            lcd.drawText(leftWidth - 1, 12, "^", SMLSIZE + RIGHT)
        end
        if scrollOffset + maxVisibleLines < totalItems then
            lcd.drawText(leftWidth - 1, LCD_H - 10, "v", SMLSIZE + RIGHT)
        end
    end
    
    -- Draw image on right half (66-128)
    if page.children2 then
        for _, child in ipairs(page.children2) do
            if child.type == "image" then
                if child.visibleFunc == nil or child.visibleFunc() then
                    if child.file and child.file ~= "" then
                        -- Convert .png to .bmp for BW radios
                        local bmpFile = string.gsub(child.file, "%.png$", ".bmp")
                        
                        -- For BW radios, use lcd.drawPixmap with pcall to catch errors
                        -- Position at right half, centered vertically
                        pcall(function()
                            lcd.drawPixmap(LCD_W / 2 + 2, 12, bmpFile)
                        end)
                    end
                    break
                end
            end
        end
    end
end

---------------------------------------------------------------------------
-- Get Control Value as Display Text
---------------------------------------------------------------------------

getControlValueText = function(control)
    if control.type == "toggle" then
        local val = control.get()
        return val == 1 and "Y" or "N"
        
    elseif control.type == "choice" then
        local idx = control.get()
        if control.values and idx >= 1 and idx <= #control.values then
            local value = control.values[idx]
            value = abbreviate(value)
            if #value > 8 then
                value = string.sub(value, 1, 6) .. ".."
            end
            return value
        end
        return "?"
        
    elseif control.type == "numberEdit" then
        return tostring(control.get())
        
    elseif control.type == "label" then
        return abbreviate(control.text or "")
    end
    
    return ""
end

---------------------------------------------------------------------------
-- Navigation and Event Handling (Phase 2: Navigation + Editing)
---------------------------------------------------------------------------

function wizard.handleEvent(event, touchState)
    if not currentPage or currentPage.type == "finishedPage" then
        return false
    end
    
    local totalItems = #itemList
    local maxVisibleLines = 4
    
    -- EDIT MODE: Change value
    if editMode then
        local item = itemList[editingItem + 1]
        
        -- Change value with rotary encoder
        if event == EVT_VIRTUAL_INC or event == EVT_VIRTUAL_INC_REPT then
            if item.control.type == "toggle" then
                editValue = 1 - editValue  -- Toggle between 0 and 1
            elseif item.control.type == "choice" then
                if editValue < #item.control.values then
                    editValue = editValue + 1
                end
            elseif item.control.type == "numberEdit" then
                local max = item.control.max or 100
                if editValue < max then
                    editValue = editValue + 1
                end
            end
            return true
            
        elseif event == EVT_VIRTUAL_DEC or event == EVT_VIRTUAL_DEC_REPT then
            if item.control.type == "toggle" then
                editValue = 1 - editValue  -- Toggle between 0 and 1
            elseif item.control.type == "choice" then
                if editValue > 1 then
                    editValue = editValue - 1
                end
            elseif item.control.type == "numberEdit" then
                local min = item.control.min or 0
                if editValue > min then
                    editValue = editValue - 1
                end
            end
            return true
            
        -- Save and exit edit mode
        elseif event == EVT_VIRTUAL_ENTER then
            item.control.set(editValue)
            editMode = false
            
            local oldEditingItem = editingItem
            editingItem = nil
            editValue = nil
            
            -- Rebuild item list to update visibility based on new value
            buildItemList(currentPage)
            
            -- Try to keep selection on same item, or move to nearest valid item
            if currentItem >= #itemList then
                currentItem = math.max(0, #itemList - 1)
            end
            
            -- If we're now on a non-editable item, find next editable one
            if currentItem < #itemList then
                local item = itemList[currentItem + 1]
                if item and not item.editable then
                    -- Search forward for editable item
                    local found = false
                    for i = currentItem + 1, #itemList - 1 do
                        if itemList[i + 1] and itemList[i + 1].editable then
                            currentItem = i
                            found = true
                            break
                        end
                    end
                    -- If not found forward, search backward
                    if not found then
                        for i = currentItem - 1, 0, -1 do
                            if itemList[i + 1] and itemList[i + 1].editable then
                                currentItem = i
                                break
                            end
                        end
                    end
                end
            end
            
            ensureVisible(currentItem)
            return true
            
        -- Cancel and exit edit mode
        elseif event == EVT_VIRTUAL_EXIT then
            editMode = false
            editingItem = nil
            editValue = nil
            return true
        end
        
        return false
    end
    
    -- BROWSE MODE: Navigate or enter edit
    
    -- Field navigation (up/down through items)
    if event == EVT_VIRTUAL_NEXT then
        if currentItem < totalItems - 1 then
            currentItem = currentItem + 1
            ensureVisible(currentItem)
            return true
        end
        
    elseif event == EVT_VIRTUAL_PREV then
        if currentItem > 0 then
            currentItem = currentItem - 1
            ensureVisible(currentItem)
            return true
        end
    end
    
    -- Scroll through items (when many items, alternative to field nav)
    if event == EVT_VIRTUAL_INC or event == EVT_VIRTUAL_INC_REPT then
        if scrollOffset + maxVisibleLines < totalItems then
            scrollOffset = scrollOffset + 1
            -- Move selection with scroll to keep it visible
            if currentItem < scrollOffset then
                currentItem = scrollOffset
            end
            return true
        end
    
    elseif event == EVT_VIRTUAL_DEC or event == EVT_VIRTUAL_DEC_REPT then
        if scrollOffset > 0 then
            scrollOffset = scrollOffset - 1
            -- Move selection with scroll to keep it visible
            if currentItem >= scrollOffset + maxVisibleLines then
                currentItem = scrollOffset + maxVisibleLines - 1
            end
            return true
        end
    end
    
    -- Enter edit mode (if field is editable)
    if event == EVT_VIRTUAL_ENTER then
        local item = itemList[currentItem + 1]
        if item and item.editable and item.control then
            editMode = true
            editingItem = currentItem
            editValue = item.control.get()
            return true
        end
    end
    
    return false  -- Event not handled
end

function wizard.needsRefresh()
    -- Return true if we're in edit mode (for BLINK to work)
    return editMode
end

function wizard.refresh()
    -- Redraw the current page
    if currentPage then
        drawPage(currentPage)
    end
end

return wizard
