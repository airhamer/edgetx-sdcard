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
-- helicopter.lua
-- Place in: /TEMPLATES/1.Wizard/lib/
-- Helicopter (simplified collective-pitch or fixed-pitch)

return function(radio, ui)

    local CORE_DIR = "/TEMPLATES/1.Wizard/core"
    local engine   = assert(loadScript(CORE_DIR .. "/core_engine.lua"))()()

    local STICK_NUMBER_AIL = 3
    local STICK_NUMBER_ELE = 1
    local STICK_NUMBER_THR = 2
    local STICK_NUMBER_RUD = 0

    local channels = { "CH1", "CH2", "CH3", "CH4", "CH5", "CH6", "CH7", "CH8" }

    local IMG_DIR = "/TEMPLATES/1.Wizard/img/helicopter"
    local imgExt  = radio.isColor and ".png" or ".bmp"

    local switchNames = {}
    for i = 0, #radio.validSwitch - 1 do
        local idx  = radio.validSwitch[i + 1]
        local name = getSourceName(MIXSRC_SA + idx - 1)
        switchNames[i + 1] = name or ("SW" .. i)
    end

    local modelData = {
        throttleCh      = radio.defaultChannel(STICK_NUMBER_THR),
        collectiveCh    = radio.defaultChannel(STICK_NUMBER_ELE),
        cyclicPitchCh   = radio.defaultChannel(STICK_NUMBER_AIL),
        yawCh           = radio.defaultChannel(STICK_NUMBER_RUD),
        governorSwitch  = -1,
        modeSwitch      = -1,
    }

    local pages = {
        {
            id = "throttle",
            title = "Throttle Channel",
            text = {
                default = "Select throttle channel",
                bw212   = "Select throttle",
                bw128   = "Throttle",
                color   = "Select the channel for throttle (motor)"
            },
            image   = IMG_DIR .. "/heli-throttle" .. imgExt,
            options = channels,
            getValue = function() return modelData.throttleCh end,
            setValue = function(v) modelData.throttleCh = v end,
            next = "collective"
        },
        {
            id = "collective",
            title = "Collective Channel",
            text = {
                default = "Select collective channel",
                bw212   = "Collective",
                bw128   = "Collective",
                color   = "Select the channel for collective pitch"
            },
            image   = IMG_DIR .. "/heli-elev" .. imgExt,
            options = channels,
            getValue = function() return modelData.collectiveCh end,
            setValue = function(v) modelData.collectiveCh = v end,
            next = "cyclicPitch"
        },
        {
            id = "cyclicPitch",
            title = "Cyclic Pitch",
            text = {
                default = "Select cyclic pitch channel",
                bw212   = "Cyclic pitch",
                bw128   = "Cyclic P",
                color   = "Select the channel for cyclic pitch (fore/aft)"
            },
            image   = IMG_DIR .. "/heli-ailer" .. imgExt,
            options = channels,
            getValue = function() return modelData.cyclicPitchCh end,
            setValue = function(v) modelData.cyclicPitchCh = v end,
            next = "yaw"
        },
        {
            id = "yaw",
            title = "Yaw Channel",
            text = {
                default = "Select yaw channel",
                bw212   = "Select yaw",
                bw128   = "Yaw",
                color   = "Select the channel for yaw (tail rotor)"
            },
            image   = IMG_DIR .. "/heli-rud" .. imgExt,
            options = channels,
            getValue = function() return modelData.yawCh end,
            setValue = function(v) modelData.yawCh = v end,
            next = "governor"
        },
        {
            id = "governor",
            title = "Governor Switch",
            text = {
                default = "Select governor switch",
                bw212   = "Governor switch",
                bw128   = "Governor",
                color   = "Select the switch for governor on/off (or None)"
            },
            image    = IMG_DIR .. "/heli-switch" .. imgExt,
            options  = switchNames,
            optional = true,
            getValue = function() return modelData.governorSwitch end,
            setValue = function(v) modelData.governorSwitch = v end,
            next = "mode"
        },
        {
            id = "mode",
            title = "Mode Switch",
            text = {
                default = "Select flight mode switch",
                bw212   = "Mode switch",
                bw128   = "Mode",
                color   = "Select the switch for idle-up / flight mode (or None)"
            },
            image    = IMG_DIR .. "/heli-switch" .. imgExt,
            options  = switchNames,
            optional = true,
            getValue = function() return modelData.modeSwitch end,
            setValue = function(v) modelData.modeSwitch = v end,
            next = "summary"
        },
        {
            id = "summary",
            title = "Summary",
            text = {
                default = "Review configuration",
                bw212   = "Review config",
                bw128   = "Review",
                color   = "Review your configuration"
            },
            summary = {
                { label = "Throttle",  getValue = function() return channels[modelData.throttleCh    + 1] end },
                { label = "Collective",getValue = function() return channels[modelData.collectiveCh  + 1] end },
                { label = "Cyclic P",  getValue = function() return channels[modelData.cyclicPitchCh + 1] end },
                { label = "Yaw",       getValue = function() return channels[modelData.yawCh         + 1] end },
                { label = "Governor",  getValue = function() return modelData.governorSwitch == -1 and "None" or switchNames[modelData.governorSwitch + 1] end },
                { label = "Mode",      getValue = function() return modelData.modeSwitch     == -1 and "None" or switchNames[modelData.modeSwitch     + 1] end },
            },
            onEnter = function()
                model.defaultInputs()
                model.deleteMixes()

                local function addMix(ch, src, name)
                    model.insertMix(ch, 0, { source = src, name = name })
                end

                addMix(modelData.throttleCh,    MIXSRC_FIRST_INPUT + radio.defaultChannel(STICK_NUMBER_THR), "Thr")
                addMix(modelData.collectiveCh,  MIXSRC_FIRST_INPUT + radio.defaultChannel(STICK_NUMBER_ELE), "Coll")
                addMix(modelData.cyclicPitchCh, MIXSRC_FIRST_INPUT + radio.defaultChannel(STICK_NUMBER_AIL), "CycP")
                addMix(modelData.yawCh,         MIXSRC_FIRST_INPUT + radio.defaultChannel(STICK_NUMBER_RUD), "Yaw")

                if modelData.governorSwitch >= 0 then
                    addMix(4, MIXSRC_SA + radio.validSwitch[modelData.governorSwitch + 1] - 1, "Gov")
                end
                if modelData.modeSwitch >= 0 then
                    addMix(5, MIXSRC_SA + radio.validSwitch[modelData.modeSwitch + 1] - 1, "Mode")
                end
            end,
            next = "finish"
        },
        {
            id = "finish",
            title = "Complete",
            text = {
                default = "Setup complete! Press EXIT",
                bw212   = "Done! Press EXIT",
                bw128   = "Done!",
                color   = "Helicopter model configured! Press EXIT"
            },
            isFinish = true
        }
    }

    return engine.runWizard(radio, ui, pages)
end
