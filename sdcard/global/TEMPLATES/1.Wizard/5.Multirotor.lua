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

-- Author: 3djc (2017)
-- Update by: Offer Shmuely (2023)
-- Update by: Alexander Gnauck (2025)
-- Update by: Airhamer / ErnestWorrel (2026)

-- 5.Multirotor.lua
-- Place in: /TEMPLATES/1.Wizard/lib/
-- Universal wizard for all radio types - uses core_engine and ui modules

return function(radio, ui)
    
    local CORE_DIR = "/TEMPLATES/1.Wizard/core"
    
    -- Load core engine
    local engine = assert(loadScript(CORE_DIR .. "/core_engine.lua"))()()
    
    -- Stick defaults
    local STICK_NUMBER_AIL = 3
    local STICK_NUMBER_ELE = 1
    local STICK_NUMBER_THR = 2
    local STICK_NUMBER_RUD = 0
    
    local channels = { "CH1", "CH2", "CH3", "CH4", "CH5", "CH6", "CH7", "CH8" }
    
    -- Get image extension based on radio type
    local IMG_DIR = "/TEMPLATES/1.Wizard/img/multirotor"
    local imgExt = radio.isColor and ".png" or ".bmp"
    
    -- Get switch names dynamically from the radio
    local function getSwitchNames()
        local switches = {}
        for i = 0, #radio.validSwitch - 1 do
            local switchIdx = radio.validSwitch[i + 1]
            -- Get switch name from radio (MIXSRC_SA is the base)
            local name = getSourceName(MIXSRC_SA + switchIdx - 1)
            switches[i + 1] = name or ("SW" .. i)
        end
        return switches
    end
    
    local switchNames = getSwitchNames()
    
    -- Model configuration data
    -- For channels: 0-based index (0 = CH1)
    -- For switches: 0-based index into validSwitch array
    local modelData = {
        throttleCh = radio.defaultChannel(STICK_NUMBER_THR),
        rollCh = radio.defaultChannel(STICK_NUMBER_AIL),
        pitchCh = radio.defaultChannel(STICK_NUMBER_ELE),
        yawCh = radio.defaultChannel(STICK_NUMBER_RUD),
        armSwitch = 0,      -- Index 0 in validSwitch array
        beeperSwitch = 0,
        modeSwitch = 0,
    }
    
    -- Define pages with text variants for different screen types
    local pages = {
        {
            id = "throttle",
            title = "Throttle Channel",
            text = {
                default = "Select throttle channel",
                bw212 = "Select throttle",
                bw128 = "Throttle",
                color = "Select the channel for throttle control"
            },
            image = IMG_DIR .. "/throttle" .. imgExt,
            options = channels,
            getValue = function() return modelData.throttleCh end,
            setValue = function(val) modelData.throttleCh = val end,
            next = "roll"
        },
        {
            id = "roll",
            title = "Roll Channel",
            text = {
                default = "Select roll channel",
                bw212 = "Select roll",
                bw128 = "Roll",
                color = "Select the channel for roll control"
            },
            image = IMG_DIR .. "/roll" .. imgExt,
            options = channels,
            getValue = function() return modelData.rollCh end,
            setValue = function(val) modelData.rollCh = val end,
            next = "pitch"
        },
        {
            id = "pitch",
            title = "Pitch Channel",
            text = {
                default = "Select pitch channel",
                bw212 = "Select pitch",
                bw128 = "Pitch",
                color = "Select the channel for pitch control"
            },
            image = IMG_DIR .. "/pitch" .. imgExt,
            options = channels,
            getValue = function() return modelData.pitchCh end,
            setValue = function(val) modelData.pitchCh = val end,
            next = "yaw"
        },
        {
            id = "yaw",
            title = "Yaw Channel",
            text = {
                default = "Select yaw channel",
                bw212 = "Select yaw",
                bw128 = "Yaw",
                color = "Select the channel for yaw control"
            },
            image = IMG_DIR .. "/yaw" .. imgExt,
            options = channels,
            getValue = function() return modelData.yawCh end,
            setValue = function(val) modelData.yawCh = val end,
            next = "arm"
        },
        {
            id = "arm",
            title = "Arm Switch",
            text = {
                default = "Select arm switch",
                bw212 = "Arm switch",
                bw128 = "Arm",
                color = "Select the switch to arm/disarm"
            },
            image = IMG_DIR .. "/arm" .. imgExt,
            options = switchNames,
            getValue = function() return modelData.armSwitch end,
            setValue = function(val) modelData.armSwitch = val end,
            next = "beeper"
        },
        {
            id = "beeper",
            title = "Beeper Switch",
            text = {
                default = "Select beeper switch",
                bw212 = "Beeper switch",
                bw128 = "Beeper",
                color = "Select the beeper switch"
            },
            image = IMG_DIR .. "/beeper" .. imgExt,
            options = switchNames,
            getValue = function() return modelData.beeperSwitch end,
            setValue = function(val) modelData.beeperSwitch = val end,
            next = "mode"
        },
        {
            id = "mode",
            title = "Mode Switch",
            text = {
                default = "Select mode switch",
                bw212 = "Mode switch",
                bw128 = "Mode",
                color = "Select the flight mode switch"
            },
            image = IMG_DIR .. "/mode" .. imgExt,
            options = switchNames,
            getValue = function() return modelData.modeSwitch end,
            setValue = function(val) modelData.modeSwitch = val end,
            next = "summary"
        },
        {
            id = "summary",
            title = "Summary",
            text = {
                default = "Review configuration",
                bw212 = "Review config",
                bw128 = "Review",
                color = "Review your configuration"
            },
            summary = {
                { label = "Throttle", getValue = function() return channels[modelData.throttleCh + 1] end },
                { label = "Roll", getValue = function() return channels[modelData.rollCh + 1] end },
                { label = "Pitch", getValue = function() return channels[modelData.pitchCh + 1] end },
                { label = "Yaw", getValue = function() return channels[modelData.yawCh + 1] end },
                { label = "Arm", getValue = function() return switchNames[modelData.armSwitch + 1] end },
                { label = "Beeper", getValue = function() return switchNames[modelData.beeperSwitch + 1] end },
                { label = "Mode", getValue = function() return switchNames[modelData.modeSwitch + 1] end },
            },
            onEnter = function()
                -- Create the model when user confirms
                model.defaultInputs()
                model.deleteMixes()
                
                local function addMix(channel, source, name)
                    local mix = { source = source, name = name }
                    model.insertMix(channel, 0, mix)
                end
                
                -- Add channel mixes
                addMix(modelData.throttleCh, MIXSRC_FIRST_INPUT + radio.defaultChannel(STICK_NUMBER_THR), "Thr")
                addMix(modelData.rollCh, MIXSRC_FIRST_INPUT + radio.defaultChannel(STICK_NUMBER_AIL), "Roll")
                addMix(modelData.pitchCh, MIXSRC_FIRST_INPUT + radio.defaultChannel(STICK_NUMBER_ELE), "Pitch")
                addMix(modelData.yawCh, MIXSRC_FIRST_INPUT + radio.defaultChannel(STICK_NUMBER_RUD), "Yaw")
                
                -- Add switch mixes (convert from array index to actual switch index)
                addMix(4, MIXSRC_SA + radio.validSwitch[modelData.armSwitch + 1] - 1, "Arm")
                addMix(5, MIXSRC_SA + radio.validSwitch[modelData.beeperSwitch + 1] - 1, "Beeper")
                addMix(6, MIXSRC_SA + radio.validSwitch[modelData.modeSwitch + 1] - 1, "Mode")
            end,
            next = "finish"
        },
        {
            id = "finish",
            title = "Complete",
            text = {
                default = "Setup complete! Press EXIT",
                bw212 = "Done! Press EXIT",
                bw128 = "Done!",
                color = "Model configured successfully! Press EXIT to finish"
            },
            isFinish = true
        }
    }
    
    -- Use the core engine to run the wizard
    return engine.runWizard(radio, ui, pages)
end
