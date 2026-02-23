---- #########################################################################
---- #                                                                       #
---- # Copyright (C) EdgeTX                                                  #
-----#                                                                       #
-----# Credits: graphics by https://github.com/jrwieland                     #
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

-- Original author: Alexander Gnauck (2025)
-- UI module for 212x64 BW radios (4-bit grayscale, e.g. Taranis X9D).
-- Loaded by wizard-ui.lua (the dispatcher) when LVGL is nil and LCD_W >= 212.
-- Uses lcd.* calls only.  No lvgl dependency.
-- Layout: inverted title bar, vertical divider at x=100, fields left,
-- image right — matching the style of original OpenTX 212x64 wizards.
-- See DEVELOPER.md for the full page/settings API.

local IMG_DIR = "/TEMPLATES/1.Wizard/img"

local wizard = {}

-- [BW] Use the real LCD_W / LCD_H globals set by the firmware.
-- (Do NOT shadow them with local constants — the globals are already correct.)
local SCREEN_W = LCD_W  -- expected 212
local SCREEN_H = LCD_H  -- expected 64

-- Layout constants (match original 212x64 wizard style)
local DIVIDER_X      = 100   -- vertical divider between fields and image
local IMAGE_X        = DIVIDER_X + 6
local MAX_FIELD_LINES = 5    -- approximately 5 lines fit below the title bar

-- Current page state
local currentPage = nil
local itemList    = {}

-- Field navigation and editing state
local currentItem  = 0
local editMode     = false
local editingItem  = nil
local editValue    = nil

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
-- Text Abbreviation
-- bw_title / bw_subtitle are preferred; abbreviate() is a fallback.
-- Less aggressive than 128-wide version — more horizontal room available.
---------------------------------------------------------------------------

local abbreviations = {
	["Channel"]  = "Ch",
	["channel"]  = "Ch",
	["Switch"]   = "Sw",
	["switch"]   = "Sw",
	["Aileron"]  = "Ail",
	["aileron"]  = "Ail",
	["Elevator"] = "Ele",
	["elevator"] = "Ele",
	["Rudder"]   = "Rud",
	["rudder"]   = "Rud",
	["Flaps"]    = "Flp",
	["flaps"]    = "Flp",
	["Landing"]  = "Lnd",
	["Retracts"] = "Retr",
	["Safety"]   = "Saf",
	["Right"]    = "R",
	["right"]    = "R",
	["Left"]     = "L",
	["left"]     = "L",
	[" (right)"] = " (R)",
	[" (left)"]  = " (L)",
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
-- These return plain Lua tables (no lvgl calls).
-- wizard.build() interprets the tables and draws to lcd.*.
---------------------------------------------------------------------------

function wizard.page(settings)
	return {
		type         = "page",
		title        = settings.title        or "",
		subtitle     = settings.subtitle     or "",
		bw_title     = settings.bw_title,
		bw_subtitle  = settings.bw_subtitle,
		hasPrevious  = settings.hasPrevious  or false,
		hasNext      = settings.hasNext      or false,
		previousFunc = settings.previousFunc,
		nextFunc     = settings.nextFunc,
		children1    = settings.children1    or {},
		children2    = settings.children2    or {},
	}
end

function wizard.finishedPage(settings)
	return {
		type  = "finishedPage",
		title = settings.title or "Complete",
	}
end

function wizard.settings(settings)
	return {
		type     = "settings",
		title    = settings.title    or "",
		bw_title = settings.bw_title,
		children = settings.children or {},
		visible  = settings.visible,
	}
end

function wizard.settingsVertical(settings)
	return {
		type     = "settingsVertical",
		title    = settings.title    or "",
		bw_title = settings.bw_title,
		children = settings.children or {},
		visible  = settings.visible,
	}
end

function wizard.image(settings)
	return {
		type        = "image",
		file        = settings.file or "",
		visibleFunc = settings.visibleFunc,
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
		type  = "summaryLine",
		label = title,
		value = txt,
	}
end

---------------------------------------------------------------------------
-- Clear and Build
---------------------------------------------------------------------------

function wizard.clear()
	lcd.clear()
	currentPage = nil
	itemList    = {}
	currentItem = 0
	editMode    = false
	editingItem = nil
	editValue   = nil
end

function wizard.build(pageDefinition)
	currentPage = pageDefinition
	currentItem = 0
	editMode    = false
	editingItem = nil
	editValue   = nil

	if currentPage then
		buildItemList(currentPage)
		drawPage(currentPage)
	end
end

---------------------------------------------------------------------------
-- Build Item List (flatten children1 into a navigable list)
---------------------------------------------------------------------------

buildItemList = function(page)
	itemList = {}

	if not page or not page.children1 then return end

	for _, child in ipairs(page.children1) do
		if child.visible == nil or child.visible() then

			if child.type == "settings" then
				local visibleControls = {}
				if child.children then
					for _, control in ipairs(child.children) do
						if (control.visible == nil or control.visible()) and
						   (control.type == "toggle" or control.type == "choice" or
						    control.type == "numberEdit") then
							visibleControls[#visibleControls + 1] = control
						end
					end
				end

				if #visibleControls == 1 then
					itemList[#itemList + 1] = {
						type     = "setting",
						label    = child.bw_title or abbreviate(child.title),
						control  = visibleControls[1],
						editable = true,
					}
				elseif #visibleControls > 1 then
					itemList[#itemList + 1] = {
						type     = "setting",
						label    = child.bw_title or abbreviate(child.title),
						control  = visibleControls[1],
						editable = true,
					}
					for i = 2, #visibleControls do
						itemList[#itemList + 1] = {
							type     = "settingValue",
							control  = visibleControls[i],
							editable = true,
						}
					end
				end

			elseif child.type == "settingsVertical" then
				itemList[#itemList + 1] = {
					type     = "settingLabel",
					label    = child.bw_title or abbreviate(child.title),
					editable = false,
				}
				if child.children then
					for _, control in ipairs(child.children) do
						if control.visible == nil or control.visible() then
							local isEditable = (control.type == "toggle" or
							                    control.type == "choice" or
							                    control.type == "numberEdit")
							itemList[#itemList + 1] = {
								type     = "settingValue",
								control  = control,
								editable = isEditable,
							}
						end
					end
				end

			elseif child.type == "summaryLine" then
				itemList[#itemList + 1] = {
					type     = "summary",
					label    = abbreviate(child.label),
					value    = child.value,
					editable = false,
				}

			elseif child.type == "label" then
				itemList[#itemList + 1] = {
					type     = "label",
					text     = abbreviate(child.text or ""),
					editable = false,
				}
			end
		end
	end
end

---------------------------------------------------------------------------
-- Helper: format a control's current value for display
---------------------------------------------------------------------------

getControlValueText = function(control)
	if control.type == "toggle" then
		return control.get() == 1 and "Y" or "N"
	elseif control.type == "choice" then
		local idx = control.get()
		if control.values and idx >= 1 and idx <= #control.values then
			local value = abbreviate(control.values[idx])
			if #value > 12 then value = string.sub(value, 1, 10) .. ".." end
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

formatEditValue = function(control, value)
	if control.type == "toggle" then
		return value == 1 and "Y" or "N"
	elseif control.type == "choice" then
		if control.values and value >= 1 and value <= #control.values then
			local val = abbreviate(control.values[value])
			if #val > 12 then val = string.sub(val, 1, 10) .. ".." end
			return val
		end
		return "?"
	elseif control.type == "numberEdit" then
		return tostring(value)
	end
	return ""
end

---------------------------------------------------------------------------
-- Draw Page (212x64 style: inverted title bar, divider, fields + image)
---------------------------------------------------------------------------

drawPage = function(page)
	if not page then return end

	lcd.clear()

	if page.type == "finishedPage" then
		lcd.drawScreenTitle("Complete!", 0, 0)
		lcd.drawText(10, 20, "Model created successfully", SMLSIZE)
		lcd.drawText(10, 35, "Press [EXIT] to finish",    SMLSIZE)
		return
	end

	-- Inverted title bar
	local titleText    = page.bw_title    or abbreviate(page.title)
	local subtitleText = page.bw_subtitle or abbreviate(page.subtitle)
	local fullTitle

	if titleText ~= "" and subtitleText ~= "" then
		fullTitle = titleText .. " - " .. subtitleText
		if #fullTitle > 40 then fullTitle = subtitleText end
	elseif subtitleText ~= "" then
		fullTitle = subtitleText
	else
		fullTitle = titleText
	end

	lcd.drawScreenTitle(fullTitle, 0, 0)

	-- Vertical divider (matching original 212x64 wizard layout)
	lcd.drawLine(DIVIDER_X, 9, DIVIDER_X, SCREEN_H - 1, DOTTED, 0)

	-- Fields on left side (field-by-field navigation, no scrolling)
	local y          = 12
	local lineHeight = 10
	local totalItems = #itemList

	for i = 1, math.min(MAX_FIELD_LINES, totalItems) do
		local item      = itemList[i]
		local itemIndex = i - 1

		local flags = SMLSIZE
		if itemIndex == currentItem then
			flags = INVERS
			if editMode then flags = INVERS + BLINK end
		end

		if item.type == "setting" then
			local valueText
			if editMode and itemIndex == editingItem then
				valueText = formatEditValue(item.control, editValue)
			else
				valueText = getControlValueText(item.control)
			end
			lcd.drawText(2,            y, item.label, SMLSIZE)
			lcd.drawText(DIVIDER_X-2,  y, valueText,  flags + RIGHT)

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
			lcd.drawText(2,           y, item.label, SMLSIZE)
			lcd.drawText(DIVIDER_X-2, y, item.value, SMLSIZE + RIGHT)

		elseif item.type == "label" then
			local text = item.text
			if #text > 16 then text = string.sub(text, 1, 14) .. ".." end
			lcd.drawText(2, y, text, SMLSIZE)
		end

		y = y + lineHeight
	end

	-- Image on right side (first visible image wins)
	if page.children2 then
		for _, child in ipairs(page.children2) do
			if child.type == "image" then
				if child.visibleFunc == nil or child.visibleFunc() then
					if child.file and child.file ~= "" then
						-- [BW] Convert .png path to .bmp for BW radios
						local bmpFile = string.gsub(child.file, "%.png$", ".bmp")
						pcall(function()
							lcd.drawPixmap(IMAGE_X, 12, bmpFile)
						end)
					end
					break
				end
			end
		end
	end
end

---------------------------------------------------------------------------
-- Event Handling: field-by-field navigation and editing
-- (Matches the feel of original 212x64 OpenTX wizards.)
---------------------------------------------------------------------------

function wizard.handleEvent(event, touchState)
	if not currentPage or currentPage.type == "finishedPage" then
		return false
	end

	local totalItems = #itemList

	-- EDIT MODE: change the value of the selected field
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
				if editValue < (item.control.max or 100) then
					editValue = editValue + 1
				end
			end
			return true

		elseif event == EVT_VIRTUAL_DEC or event == EVT_VIRTUAL_DEC_REPT then
			if item.control.type == "toggle" then
				editValue = 1 - editValue
			elseif item.control.type == "choice" then
				if editValue > 1 then editValue = editValue - 1 end
			elseif item.control.type == "numberEdit" then
				if editValue > (item.control.min or 0) then
					editValue = editValue - 1
				end
			end
			return true

		elseif event == EVT_VIRTUAL_ENTER then
			item.control.set(editValue)
			editMode    = false
			editingItem = nil
			editValue   = nil

			-- Rebuild to update visibility after value change
			buildItemList(currentPage)

			if currentItem >= #itemList then
				currentItem = math.max(0, #itemList - 1)
			end
			return true

		elseif event == EVT_VIRTUAL_EXIT then
			editMode    = false
			editingItem = nil
			editValue   = nil
			return true
		end

		return false
	end

	-- BROWSE MODE: field-by-field navigation (rotary encoder moves between fields)

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

	if event == EVT_VIRTUAL_ENTER then
		local item = itemList[currentItem + 1]
		if item and item.editable and item.control then
			editMode    = true
			editingItem = currentItem
			editValue   = item.control.get()
			return true
		end
	end

	return false
end

function wizard.needsRefresh()
	return editMode  -- BLINK requires continuous redraws while editing
end

function wizard.refresh()
	if currentPage then drawPage(currentPage) end
end

---------------------------------------------------------------------------
-- wizard.run() — shared page-navigation body called by model scripts.
-- Identical across all three UI modules so model scripts don't need to
-- contain navigation logic.
---------------------------------------------------------------------------

function wizard.run(event, touchState, page, pages, selectPage)
	-- Route field-level events to the UI module first.
	if event and (
		event == EVT_VIRTUAL_INC      or event == EVT_VIRTUAL_INC_REPT or
		event == EVT_VIRTUAL_DEC      or event == EVT_VIRTUAL_DEC_REPT or
		event == EVT_VIRTUAL_NEXT     or event == EVT_VIRTUAL_PREV     or
		event == EVT_VIRTUAL_ENTER    or event == EVT_VIRTUAL_EXIT)
	then
		if wizard.handleEvent(event, touchState) then
			if wizard.needsRefresh() then wizard.refresh() end
			return 0
		end
	end

	-- Continuous refresh in edit mode (needed for BLINK flag).
	if wizard.needsRefresh() then wizard.refresh() end

	-- Page-level navigation (hardware Next Page / Prev Page buttons).
	if event == EVT_VIRTUAL_PREV_PAGE and page > 1 and page < #pages then
		killEvents(event)
		selectPage(-1)
	elseif event == EVT_VIRTUAL_NEXT_PAGE and page < #pages then
		killEvents(event)
		selectPage(1)
	end

	if wizard.exitWizard() then return 2 end
	return 0
end

return wizard
