---- #########################################################################
---- #                                                                       #
---- # UI Module for 212x64 Black & White Radios                            #
---- # 4-bit grayscale, field-by-field navigation like original wizards     #
---- #                                                                       #
---- # License GPLv2: http://www.gnu.org/licenses/gpl-2.0.html               #
---- #                                                                       #
---- #########################################################################

local IMG_DIR = "/TEMPLATES/1.Wizard/img"

local wizard = {}

-- Screen dimensions for 212x64
local LCD_W = 212
local LCD_H = 64

-- Create a minimal lvgl compatibility layer for BW radios
if not lvgl then
    _G.lvgl = {
        PERCENT_SIZE = 100,
    }
end

-- Current page state
local currentPage = nil
local itemList = {}

-- Phase 2: Field navigation (field-by-field like original 212x64 wizards)
local currentItem = 0
local editMode = false
local editingItem = nil
local editValue = nil

-- Forward declarations
local drawPage
local getControlValueText
local buildItemList
local formatEditValue

local exit = false

function wizard.exitWizard()
    return exit
end

---------------------------------------------------------------------------
-- Text Abbreviation (less aggressive - we have more width)
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
    ["Flaps"] = "Flp",
    ["flaps"] = "Flp",
    ["Landing"] = "Lnd",
    ["Retracts"] = "Retr",
    ["Safety"] = "Saf",
    ["Right"] = "R",
    ["right"] = "R",
    ["Left"] = "L",
    ["left"] = "L",
    [" (right)"] = " (R)",
    [" (left)"] = " (L)",
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
    itemList = {}
    currentItem = 0
    editMode = false
    editingItem = nil
    editValue = nil
end

function wizard.build(pageDefinition)
    currentPage = pageDefinition
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
-- Build Item List
---------------------------------------------------------------------------

buildItemList = function(page)
    itemList = {}
    
    if not page or not page.children1 then
        return
    end
    
    for _, child in ipairs(page.children1) do
        if child.visible == nil or child.visible() then
            if child.type == "settings" then
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
                    -- No controls, skip
                elseif #visibleControls == 1 then
                    itemList[#itemList + 1] = {
                        type = "setting",
                        label = child.bw_title or abbreviate(child.title),
                        control = visibleControls[1],
                        editable = true
                    }
                else
                    -- Multiple controls: first on same line, rest below
                    itemList[#itemList + 1] = {
                        type = "setting",
                        label = child.bw_title or abbreviate(child.title),
                        control = visibleControls[1],
                        editable = true
                    }
                    
                    for i = 2, #visibleControls do
                        itemList[#itemList + 1] = {
                            type = "settingValue",
                            control = visibleControls[i],
                            editable = true
                        }
                    end
                end
            elseif child.type == "settingsVertical" then
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
                    editable = false
                }
            elseif child.type == "label" then
                itemList[#itemList + 1] = {
                    type = "label",
                    text = abbreviate(child.text or ""),
                    editable = false
                }
            end
        end
    end
end

---------------------------------------------------------------------------
-- Helper Functions
---------------------------------------------------------------------------

formatEditValue = function(control, value)
    if control.type == "toggle" then
        return value == 1 and "Y" or "N"
    elseif control.type == "choice" then
        if control.values and value >= 1 and value <= #control.values then
            local val = control.values[value]
            val = abbreviate(val)
            if #val > 12 then
                val = string.sub(val, 1, 10) .. ".."
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
-- Draw Page Function (212x64 style: title bar + ~5 lines, large image)
---------------------------------------------------------------------------

drawPage = function(page)
    if not page then
        return
    end
    
    lcd.clear()
    
    if page.type == "finishedPage" then
        lcd.drawScreenTitle("Complete!", 0, 0)
        lcd.drawText(10, 20, "Model created successfully", SMLSIZE)
        lcd.drawText(10, 35, "Press [EXIT] to finish", SMLSIZE)
        return
    end
    
    -- Title bar (inverted, full width)
    local titleText = page.bw_title or abbreviate(page.title)
    local subtitleText = page.bw_subtitle or abbreviate(page.subtitle)
    local fullTitle = ""
    
    if titleText ~= "" and subtitleText ~= "" then
        fullTitle = titleText .. " - " .. subtitleText
        if #fullTitle > 40 then
            fullTitle = subtitleText
        end
    elseif subtitleText ~= "" then
        fullTitle = subtitleText
    else
        fullTitle = titleText
    end
    
    lcd.drawScreenTitle(fullTitle, 0, 0)
    
    -- Draw vertical divider line (like original 212x64 wizards)
    local dividerX = 100  -- Left side gets ~100px, right side gets ~112px
    lcd.drawLine(dividerX, 9, dividerX, LCD_H-1, DOTTED, 0)
    
    -- Draw items on LEFT SIDE ONLY (field-by-field, no scrolling)
    local y = 12
    local lineHeight = 10
    local maxVisibleLines = 5  -- 64px height = ~5 lines
    local totalItems = #itemList
    
    -- Display all items (no scrolling - field-by-field navigation)
    for i = 1, math.min(maxVisibleLines, totalItems) do
        local item = itemList[i]
        local itemIndex = i - 1
        
        -- Get field flags (like original wizards)
        local flags = SMLSIZE
        if itemIndex == currentItem then
            flags = INVERS
            if editMode then
                flags = INVERS + BLINK
            end
        end
        
        if item.type == "setting" then
            local valueText = ""
            
            if editMode and itemIndex == editingItem then
                valueText = formatEditValue(item.control, editValue)
            elseif item.control then
                valueText = getControlValueText(item.control)
            end
            
            lcd.drawText(2, y, item.label, SMLSIZE)
            lcd.drawText(dividerX - 2, y, valueText, flags + RIGHT)
            
        elseif item.type == "settingLabel" then
            lcd.drawText(2, y, item.label, SMLSIZE)
            
        elseif item.type == "settingValue" then
            local valueText
            
            if editMode and itemIndex == editingItem then
                valueText = formatEditValue(item.control, editValue)
            else
                valueText = getControlValueText(item.control)
            end
            
            lcd.drawText(8, y, valueText, flags)
            
        elseif item.type == "summary" then
            lcd.drawText(2, y, item.label, SMLSIZE)
            lcd.drawText(dividerX - 2, y, item.value, SMLSIZE + RIGHT)
            
        elseif item.type == "label" then
            local text = item.text
            if #text > 16 then
                text = string.sub(text, 1, 14) .. ".."
            end
            lcd.drawText(2, y, text, SMLSIZE)
        end
        
        y = y + lineHeight
    end
    
    -- Draw large image on RIGHT SIDE
    if page.children2 then
        for _, child in ipairs(page.children2) do
            if child.type == "image" then
                if child.visibleFunc == nil or child.visibleFunc() then
                    if child.file and child.file ~= "" then
                        -- Convert .png to .bmp (4-bit grayscale for 212x64)
                        local bmpFile = string.gsub(child.file, "%.png$", ".bmp")
                        
                        -- Draw large image on right side
                        -- Position at divider + margin, images can be ~100x50
                        pcall(function()
                            lcd.drawPixmap(dividerX + 6, 12, bmpFile)
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
            if #value > 12 then
                value = string.sub(value, 1, 10) .. ".."
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
-- Navigation (field-by-field like original 212x64 wizards)
---------------------------------------------------------------------------

function wizard.handleEvent(event, touchState)
    if not currentPage or currentPage.type == "finishedPage" then
        return false
    end
    
    local totalItems = #itemList
    
    -- EDIT MODE: Change value
    if editMode then
        local item = itemList[editingItem + 1]
        
        if event == EVT_VIRTUAL_INC or event == EVT_VIRTUAL_INC_REPT then
            if item.control.type == "toggle" then
                editValue = 1 - editValue
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
                editValue = 1 - editValue
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
            
        elseif event == EVT_VIRTUAL_ENTER then
            item.control.set(editValue)
            editMode = false
            editingItem = nil
            editValue = nil
            
            -- Rebuild to update visibility
            buildItemList(currentPage)
            
            -- Adjust selection if needed
            if currentItem >= #itemList then
                currentItem = math.max(0, #itemList - 1)
            end
            
            return true
            
        elseif event == EVT_VIRTUAL_EXIT then
            editMode = false
            editingItem = nil
            editValue = nil
            return true
        end
        
        return false
    end
    
    -- BROWSE MODE: Field-by-field navigation (no scrolling)
    
    -- Navigate between fields
    if event == EVT_VIRTUAL_INC or event == EVT_VIRTUAL_INC_REPT then
        if currentItem < totalItems - 1 then
            currentItem = currentItem + 1
            return true
        end
        
    elseif event == EVT_VIRTUAL_DEC or event == EVT_VIRTUAL_DEC_REPT then
        if currentItem > 0 then
            currentItem = currentItem - 1
            return true
        end
    end
    
    -- Enter edit mode
    if event == EVT_VIRTUAL_ENTER then
        local item = itemList[currentItem + 1]
        if item and item.editable and item.control then
            editMode = true
            editingItem = currentItem
            editValue = item.control.get()
            return true
        end
    end
    
    return false
end

function wizard.needsRefresh()
    return editMode
end

function wizard.refresh()
    if currentPage then
        drawPage(currentPage)
    end
end

return wizard
