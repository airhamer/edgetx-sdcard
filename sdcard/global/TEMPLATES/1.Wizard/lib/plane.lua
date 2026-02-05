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
-- plane.lua
-- Place in: /TEMPLATES/1.Wizard/lib/
-- Powered airplane: Aileron, Elevator, Throttle, Rudder
-- Optional: Flap switch, Retract switch

return function(radio, ui)

    local CORE_DIR = "/TEMPLATES/1.Wizard/core"
    local engine   = assert(loadScript(CORE_DIR .. "/core_engine.lua"))()()

    -- Stick mapping (EdgeTX standard)
    local STICK_NUMBER_AIL = 3
    local STICK_NUMBER_ELE = 1
    local STICK_NUMBER_THR = 2
    local STICK_NUMBER_RUD = 0

    local channels = { "CH1", "CH2", "CH3", "CH4", "CH5", "CH6", "CH7", "CH8" }

    local IMG_DIR = "/TEMPLATES/1.Wizard/img/plane"
    local imgExt  = radio.isColor and ".png" or ".bmp"

    -- Switch names (dynamic)
    local switchNames = {}
    for i = 0, #radio.validSwitch - 1 do
        local idx  = radio.validSwitch[i + 1]
        local name = getSourceName(MIXSRC_SA + idx - 1)
        switchNames[i + 1] = name or ("SW" .. i)
    end

    local modelData = {
        aileronCh  = radio.defaultChannel(STICK_NUMBER_AIL),
        elevatorCh = radio.defaultChannel(STICK_NUMBER_ELE),
        throttleCh = radio.defaultChannel(STICK_NUMBER_THR),
        rudderCh   = radio.defaultChannel(STICK_NUMBER_RUD),
        flapSwitch    = -1,
        retractSwitch = -1,
    }

    local pages = {
        {
            id = "aileron",
            title = "Aileron Channel",
            text = {
                default = "Select aileron channel",
                bw212   = "Select aileron",
                bw128   = "Aileron",
                color   = "Select the channel for aileron control"
            },
            image   = IMG_DIR .. "/ailerons-0" .. imgExt,
            options = channels,
            getValue = function() return modelData.aileronCh end,
            setValue = function(v) modelData.aileronCh = v end,
            next = "elevator"
        },
        {
            id = "elevator",
            title = "Elevator Channel",
            text = {
                default = "Select elevator channel",
                bw212   = "Select elevator",
                bw128   = "Elevator",
                color   = "Select the channel for elevator control"
            },
            image   = IMG_DIR .. "/tail-1" .. imgExt,
            options = channels,
            getValue = function() return modelData.elevatorCh end,
            setValue = function(v) modelData.elevatorCh = v end,
            next = "throttle"
        },
        {
            id = "throttle",
            title = "Throttle Channel",
            text = {
                default = "Select throttle channel",
                bw212   = "Select throttle",
                bw128   = "Throttle",
                color   = "Select the channel for throttle"
            },
            image   = IMG_DIR .. "/prop" .. imgExt,
            options = channels,
            getValue = function() return modelData.throttleCh end,
            setValue = function(v) modelData.throttleCh = v end,
            next = "rudder"
        },
        {
            id = "rudder",
            title = "Rudder Channel",
            text = {
                default = "Select rudder channel",
                bw212   = "Select rudder",
                bw128   = "Rudder",
                color   = "Select the channel for rudder control"
            },
            image   = IMG_DIR .. "/tail-2" .. imgExt,
            options = channels,
            getValue = function() return modelData.rudderCh end,
            setValue = function(v) modelData.rudderCh = v end,
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
            image    = IMG_DIR .. "/brakes-1" .. imgExt,
            options  = switchNames,
            optional = true,
            getValue = function() return modelData.flapSwitch end,
            setValue = function(v) modelData.flapSwitch = v end,
            next = "retract"
        },
        {
            id = "retract",
            title = "Retract Switch",
            text = {
                default = "Select retract switch",
                bw212   = "Retract switch",
                bw128   = "Retract",
                color   = "Select the switch for retractable gear (or None)"
            },
            image    = IMG_DIR .. "/servo" .. imgExt,
            options  = switchNames,
            optional = true,
            getValue = function() return modelData.retractSwitch end,
            setValue = function(v) modelData.retractSwitch = v end,
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
                { label = "Aileron",  getValue = function() return channels[modelData.aileronCh  + 1] end },
                { label = "Elevator", getValue = function() return channels[modelData.elevatorCh + 1] end },
                { label = "Throttle", getValue = function() return channels[modelData.throttleCh + 1] end },
                { label = "Rudder",   getValue = function() return channels[modelData.rudderCh   + 1] end },
                { label = "Flap",     getValue = function() return modelData.flapSwitch    == -1 and "None" or switchNames[modelData.flapSwitch    + 1] end },
                { label = "Retract",  getValue = function() return modelData.retractSwitch == -1 and "None" or switchNames[modelData.retractSwitch + 1] end },
            },
            onEnter = function()
                model.defaultInputs()
                model.deleteMixes()

                local function addMix(ch, src, name)
                    model.insertMix(ch, 0, { source = src, name = name })
                end

                addMix(modelData.aileronCh,  MIXSRC_FIRST_INPUT + radio.defaultChannel(STICK_NUMBER_AIL), "Ail")
                addMix(modelData.elevatorCh, MIXSRC_FIRST_INPUT + radio.defaultChannel(STICK_NUMBER_ELE), "Ele")
                addMix(modelData.throttleCh, MIXSRC_FIRST_INPUT + radio.defaultChannel(STICK_NUMBER_THR), "Thr")
                addMix(modelData.rudderCh,   MIXSRC_FIRST_INPUT + radio.defaultChannel(STICK_NUMBER_RUD), "Rud")

                if modelData.flapSwitch >= 0 then
                    addMix(4, MIXSRC_SA + radio.validSwitch[modelData.flapSwitch + 1] - 1, "Flap")
                end
                if modelData.retractSwitch >= 0 then
                    addMix(5, MIXSRC_SA + radio.validSwitch[modelData.retractSwitch + 1] - 1, "Retract")
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
                color   = "Plane model configured! Press EXIT"
            },
            isFinish = true
        }
    }

    return engine.runWizard(radio, ui, pages)
end
