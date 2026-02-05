---- #########################################################################
---- #                                                                       #
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

-- Author: 3djc (2017)
-- Update by: Offer Shmuely (2023)
-- Update by: Alexander Gnauck (2025)
-- Update by: Airhamer / ErnestWorrel (2026)
-- 4.Helicopter.lua
-- Place in: /TEMPLATES/1.Wizard/
-- Works standalone (color radios call directly) or via wizard.lua (BW radios)

local BASE_DIR = "/TEMPLATES/1.Wizard"
local LIB_DIR  = BASE_DIR .. "/lib"
local CORE_DIR = BASE_DIR .. "/core"

local function loader(radio, ui)
    if not radio then
        radio = assert(loadScript(CORE_DIR .. "/radio_detect.lua"))()()
    end
    if not ui then
        ui = assert(loadScript(CORE_DIR .. "/" .. radio.uiModule))()
    end
    
    local builder = assert(loadScript(LIB_DIR .. "/helicopter.lua"))()
    return builder(radio, ui)
end

if ... then
    return loader
else
    return loader(nil, nil)
end
