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
-- radio_detect.lua
-- Place in: <global>/TEMPLATES/1.Wizard/core/
-- Minimal, safe radio specific settings for EdgeTX model templates.
local function safeGetVersion()
  local ver, name = getVersion()
  return ver or "0.0.0", name or ""
end

local function detectScreen()
  if LCD_H > 64 then
    return "color"
  elseif LCD_W > 128 then
    return "bw212"
  else
    return "bw128"
  end
end

local function detectSwitches(radioName)
  radioName = string.lower(radioName or "")
  
  -- Try to detect number of switches dynamically
  local switches = {}
  
  -- Test each switch to see if it exists
  -- EdgeTX supports up to 32 switches, but most radios have 6-12
  for i = 0, 31 do
    local name = getSourceName(MIXSRC_SA + i)
    if name and name ~= "" and not string.find(name, "---") then
      switches[#switches + 1] = i + 1  -- Store 1-based index
    end
  end
  
  -- If we found switches, use them
  if #switches > 0 then
    return switches
  end
  
  -- Fallback: known radio types
  if string.find(radioName, "x7") then
    return {1,2,3,4,5,6,7,8,9,10,11,12,13,15}
  elseif string.find(radioName, "xlite") then
    return {1,2,3,4,5,6,7,9,10,12}
  else
    -- Default assumption: 8 switches (SA-SH)
    return {1,2,3,4,5,6,7,8}
  end
end

local function radio_detect()
  local radio = {}
  local ver, name = safeGetVersion()
  radio.version = ver
  radio.name    = name
  
  local screen = detectScreen()
  radio.screenType = screen
  radio.isColor = (screen == "color")
  radio.isBW212 = (screen == "bw212")
  radio.isBW128 = (screen == "bw128")
  
  if radio.isColor then
    radio.uiModule = "ui_color.lua"
  elseif radio.isBW212 then
    radio.uiModule = "ui_bw212.lua"
  else
    radio.uiModule = "ui_bw128.lua"
  end
  
  radio.validSwitch = detectSwitches(name)
  
  radio.defaultChannel = function(idx)
    if defaultChannel then
      return defaultChannel(idx)
    end
    return idx
  end
  
  return radio
end

return radio_detect
