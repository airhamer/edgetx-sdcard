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
-- Colour-radio UI module for the EdgeTX model wizard.
-- Loaded by wizard-ui.lua (the dispatcher) when LVGL is available.
-- Uses native LVGL calls throughout; never called on BW radios.
-- See DEVELOPER.md for the full page/settings API.

local IMG_DIR = "/TEMPLATES/1.Wizard/img"

local wizard = {}

-- useful to show lines for layout debugging
local THICKNESS = 0
local LANDSCAPE = 0
local PORTRAIT  = 1

local ORIENTATION = (LCD_W > LCD_H) and LANDSCAPE or PORTRAIT

local exit = false

function wizard.exitWizard()
	return exit
end

local function closeDialog()
	lvgl.confirm({
		title   = "Exit",
		message = "Do you really want to exit the model wizard?",
		confirm = function()
			exit = true
		end,
	})
end

function wizard.page(settings)
	if ORIENTATION == LANDSCAPE then
		return {
			{
				type       = "page",
				title      = settings.title,
				subtitle   = settings.subtitle,
				flexPad    = 0,
				flexFlow   = lvgl.FLOW_ROW,
				align      = CENTER | VTOP,
				backButton = true,
				nextButton = {
					press  = settings.nextFunc,
					active = function() return settings.hasNext end,
				},
				prevButton = {
					press  = settings.previousFunc,
					active = function() return settings.hasPrevious end,
				},
				back     = closeDialog,
				children = {
					{
						type      = "rectangle",
						w         = lvgl.PERCENT_SIZE + 60,
						h         = lvgl.PERCENT_SIZE + 100,
						thickness = THICKNESS,
						flexFlow  = lvgl.FLOW_COLUMN,
						align     = LEFT | VTOP,
						children  = settings.children1,
					},
					{
						type      = "rectangle",
						scrollBar = false,
						w         = lvgl.PERCENT_SIZE + 40,
						h         = lvgl.PERCENT_SIZE + 100,
						thickness = THICKNESS,
						flexFlow  = lvgl.FLOW_COLUMN,
						children  = settings.children2,
					},
				},
			},
		}
	else
		return {
			{
				type       = "page",
				title      = settings.title,
				subtitle   = settings.subtitle,
				flexPad    = 0,
				flexFlow   = lvgl.FLOW_COLUMN,
				align      = CENTER | VTOP,
				backButton = true,
				nextButton = {
					press  = settings.nextFunc,
					active = function() return settings.hasNext end,
				},
				prevButton = {
					press  = settings.previousFunc,
					active = function() return settings.hasPrevious end,
				},
				back     = closeDialog,
				children = {
					{
						type      = "rectangle",
						w         = lvgl.PERCENT_SIZE + 100,
						h         = lvgl.PERCENT_SIZE + 60,
						thickness = THICKNESS,
						flexFlow  = lvgl.FLOW_COLUMN,
						align     = LEFT | VTOP,
						children  = settings.children1,
					},
					{
						type      = "rectangle",
						scrollBar = false,
						w         = lvgl.PERCENT_SIZE + 100,
						h         = lvgl.PERCENT_SIZE + 40,
						thickness = THICKNESS,
						flexFlow  = lvgl.FLOW_COLUMN,
						children  = settings.children2,
					},
				},
			},
		}
	end
end

function wizard.settings(settings)
	return {
		type      = "rectangle",
		flexPad   = 0,
		flexFlow  = lvgl.FLOW_ROW,
		thickness = THICKNESS,
		w         = lvgl.PERCENT_SIZE + 100,
		visible   = settings.visible,
		children  = {
			{
				type      = "rectangle",
				thickness = THICKNESS,
				w         = lvgl.PERCENT_SIZE + 60,
				children  = {
					{
						type  = "label",
						w     = lvgl.PERCENT_SIZE + 100,
						color = COLOR_THEME_PRIMARY1,
						text  = settings.title,
					},
				},
			},
			{
				type      = "rectangle",
				thickness = THICKNESS,
				w         = lvgl.PERCENT_SIZE + 40,
				flexFlow  = lvgl.FLOW_ROW,
				align     = LEFT | VCENTER,
				children  = settings.children,
			},
		},
	}
end

function wizard.settingsVertical(settings)
	return {
		type      = "rectangle",
		flexPad   = 0,
		thickness = THICKNESS,
		w         = lvgl.PERCENT_SIZE + 100,
		flexFlow  = lvgl.FLOW_COLUMN,
		align     = LEFT | VTOP,
		visible   = settings.visible,
		children  = {
			{
				type      = "rectangle",
				thickness = THICKNESS,
				w         = lvgl.PERCENT_SIZE + 100,
				children  = {
					{
						type  = "label",
						w     = lvgl.PERCENT_SIZE + 100,
						color = COLOR_THEME_PRIMARY1,
						text  = settings.title,
					},
				},
			},
			{
				type      = "rectangle",
				thickness = THICKNESS,
				flexFlow  = lvgl.FLOW_ROW,
				align     = LEFT | VCENTER,
				children  = settings.children,
			},
		},
	}
end

function wizard.summaryLine(title, chNum, text2)
	local txt
	if chNum ~= nil then
		txt = "CH" .. (chNum + 1)
	else
		txt = text2
	end

	return wizard.settings({
		title    = title,
		children = {
			{
				type = "label",
				w    = lvgl.PERCENT_SIZE + 100,
				text = txt,
			},
		},
	})
end

function wizard.image(settings)
	local BORDER_PADDING = lvgl.PAD_LARGE * 4

	if ORIENTATION == LANDSCAPE then
		return {
			type    = "image",
			x       = 0,
			y       = 0,
			w       = LCD_W * 40 / 100 - BORDER_PADDING,
			h       = lvgl.PAGE_BODY_HEIGHT - BORDER_PADDING,
			file    = settings.file,
			visible = settings.visibleFunc,
		}
	else
		return {
			type    = "image",
			x       = 0,
			y       = 0,
			w       = LCD_W - BORDER_PADDING,
			h       = lvgl.PAGE_BODY_HEIGHT * 40 / 100 - BORDER_PADDING,
			file    = settings.file,
			visible = settings.visibleFunc,
		}
	end
end

function wizard.finishedPage(settings)
	return wizard.page({
		title       = settings.title,
		subtitle    = "Finished",
		hasPrevious = false,
		hasNext     = false,
		children1   = {
			{ type = "label", text = "Model successfully created !" },
			{ type = "label", text = "Hold [RTN] to exit." },
		},
		children2 = {
			wizard.image({
				file    = IMG_DIR .. "/summary.png",
				visible = function() return true end,
			}),
		},
	})
end

function wizard.clear()
	lvgl.clear()
end

function wizard.build(pageDefinition)
	lvgl.build(pageDefinition)
end

function wizard.handleEvent(event, touchState)
	return false  -- LVGL handles all events on colour radios
end

function wizard.needsRefresh()
	return false  -- LVGL handles refreshing
end

function wizard.refresh()
	-- LVGL handles display updates automatically
end

-- [BW] wizard.run() is defined here (in the colour implementation) so it is
-- available regardless of which UI module is loaded.  BW shims also define
-- it identically.  Centralising the run() body here means all model scripts
-- share one implementation and only this file needs changing if the
-- navigation logic changes.
function wizard.run(event, touchState, page, pages, selectPage)
	-- Route field-navigation events to the UI module (active on BW;
	-- handleEvent returns false immediately on colour so LVGL takes over).
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

	-- Continuous refresh when a field is in edit mode (needed for BLINK).
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
