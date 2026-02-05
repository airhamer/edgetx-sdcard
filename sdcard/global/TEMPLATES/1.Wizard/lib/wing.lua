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
-- wing.lua
-- Place in: /TEMPLATES/1.Wizard/lib/
-- Flying wing: Elevon L, Elevon R, optional Throttle, optional Flap/Camber switches

return function(radio, ui)

    local CORE_DIR = "/TEMPLATES/1.Wizard/core"
    local engine   = assert(loadScript(CORE_DIR .. "/core_engine.lua"))()()

    local STICK_NUMBER_AIL = 3
    local STICK_NUMBER_ELE = 1
    local STICK_NUMBER_THR = 2

    local channels = { "CH1", "CH2", "CH3", "CH4", "CH5", "CH6", "CH7", "CH8" }

    local IMG_DIR = "/TEMPLATES/1.Wizard/img/wing"
    local imgExt  = radio.isColor and ".png" or ".bmp"

    local switchNames = {}
    for i = 0, #radio.validSwitch - 1 do
        local idx  = radio.validSwitch[i + 1]
        local name = getSourceName(MIXSRC_SA + idx - 1)
        switchNames[i + 1] = name or ("SW" .. i)
    end

    local modelData = {
        elevonLCh    = radio.defaultChannel(STICK_NUMBER_AIL),
        elevonRCh    = radio.defaultChannel(STICK_NUMBER_ELE),
        throttleCh   = -1,
        flapSwitch   = -1,
        camberSwitch = -1,
    }

    local pages = {
        {
            id = "elevonL",
            title = "Elevon Left",
            text = {
                default = "Select left elevon channel",
                bw212   = "Left elevon",
                bw128   = "Elevon L",
                color   = "Select the channel for the left elevon"
            },
            image   = IMG_DIR .. "/plane" .. imgExt,
            options = channels,
            getValue = function() return modelData.elevonLCh end,
            setValue = function(v) modelData.elevonLCh = v end,
            next = "elevonR"
        },
        {
            id = "elevonR",
            title = "Elevon Right",
            text = {
                default = "Select right elevon channel",
                bw212   = "Right elevon",
                bw128   = "Elevon R",
                color   = "Select the channel for the right elevon"
            },
            image   = IMG_DIR .. "/plane" .. imgExt,
            options = channels,
            getValue = function() return modelData.elevonRCh end,
            setValue = function(v) modelData.elevonRCh = v end,
            next = "throttle"
        },
        {
            id = "throttle",
            title = "Throttle Channel",
            text = {
                default = "Throttle (powered wing)",
                bw212   = "Throttle",
                bw128   = "Throttle",
                color   = "Throttle channel — set None if unpowered"
            },
            image    = IMG_DIR .. "/prop" .. imgExt,
            options  = channels,
            optional = true,
            getValue = function() return modelData.throttleCh end,
            setValue = function(v) modelData.throttleCh = v end,
            next = "flap"
        },
        {
            id = "flap",
            title = "Flap Switch",
            text = {
                default = "Select flap switch",
                bw212   = "Flap switch",
                bw128   = "Flap",
                color   = "Select the switch for flaps (or None)"
            },
            image    = IMG_DIR .. "/plane-2a" .. imgExt,
            options  = switchNames,
            optional = true,
            getValue = function() return modelData.flapSwitch end,
            setValue = function(v) modelData.flapSwitch = v end,
            next = "camber"
        },
        {
            id = "camber",
            title = "Camber Switch",
            text = {
                default = "Select camber switch",
                bw212   = "Camber switch",
                bw128   = "Camber",
                color   = "Select the switch for camber (or None)"
            },
            image    = IMG_DIR .. "/drudder-1" .. imgExt,
            options  = switchNames,
            optional = true,
            getValue = function() return modelData.camberSwitch end,
            setValue = function(v) modelData.camberSwitch = v end,
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
                { label = "Elevon L",  getValue = function() return channels[modelData.elevonLCh  + 1] end },
                { label = "Elevon R",  getValue = function() return channels[modelData.elevonRCh  + 1] end },
                { label = "Throttle",  getValue = function() return modelData.throttleCh   == -1 and "None" or channels[modelData.throttleCh   + 1] end },
                { label = "Flap",      getValue = function() return modelData.flapSwitch   == -1 and "None" or switchNames[modelData.flapSwitch   + 1] end },
                { label = "Camber",    getValue = function() return modelData.camberSwitch == -1 and "None" or switchNames[modelData.camberSwitch + 1] end },
            },
            onEnter = function()
                model.defaultInputs()
                model.deleteMixes()

                local function addMix(ch, src, name)
                    model.insertMix(ch, 0, { source = src, name = name })
                end

                addMix(modelData.elevonLCh, MIXSRC_FIRST_INPUT + radio.defaultChannel(STICK_NUMBER_AIL), "ElevL")
                addMix(modelData.elevonRCh, MIXSRC_FIRST_INPUT + radio.defaultChannel(STICK_NUMBER_ELE), "ElevR")

                if modelData.throttleCh >= 0 then
                    addMix(modelData.throttleCh, MIXSRC_FIRST_INPUT + radio.defaultChannel(STICK_NUMBER_THR), "Thr")
                end

                if modelData.flapSwitch >= 0 then
                    addMix(4, MIXSRC_SA + radio.validSwitch[modelData.flapSwitch + 1] - 1, "Flap")
                end
                if modelData.camberSwitch >= 0 then
                    addMix(5, MIXSRC_SA + radio.validSwitch[modelData.camberSwitch + 1] - 1, "Camber")
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
                color   = "Wing model configured! Press EXIT"
            },
            isFinish = true
        }
    }

    return engine.runWizard(radio, ui, pages)
end
