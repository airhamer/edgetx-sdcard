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
-- [BW] Converted to a dispatcher: detects radio type at load time and
--      returns the correct UI implementation (colour LVGL or BW lcd shim).
--      Model wizard scripts load only this file; they never reference lvgl
--      directly.  See DEVELOPER.md for the full page/settings API.

local RUN_DIR = "/TEMPLATES/1.Wizard/lib"

-- Detect whether LVGL is available (colour radio).
-- We check for the clear() function specifically; the global lvgl table may
-- exist on some BW builds as a stub, so checking a known function is safer.
local isColor = lvgl ~= nil and type(lvgl.clear) == "function"

if isColor then
	-- Colour radio: load the full LVGL implementation.
	return loadScript(RUN_DIR .. "/wiz-color-ui.lua")()
elseif LCD_W >= 212 then
	-- BW 212x64 radio (e.g. Taranis X9D, Horus in BW mode).
	return loadScript(RUN_DIR .. "/wiz-bw212-ui.lua")()
else
	-- BW 128x64 radio (e.g. Taranis X-Lite, QX7).
	return loadScript(RUN_DIR .. "/wiz-bw128-ui.lua")()
end
