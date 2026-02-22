---- #########################################################################
---- #                                                                       #
---- # Fixed Wing Wizard (Plane / Glider / Wing)                            #
---- #                                                                       #
---- # License GPLv2: http://www.gnu.org/licenses/gpl-2.0.html               #
---- #                                                                       #
---- #########################################################################
-- Author: 3djc (2017)
-- Update by: Offer Shmuely (2023)
-- Update by: Alexander Gnauck (2025)

---- =========================================================================
---- PAGE / SETTINGS API REFERENCE
---- =========================================================================
---- This file builds wizard pages using the wizard-ui abstraction layer.
---- The same calls work on color radios (real LVGL) and BW radios (lcd shim).
----
---- IMAGES
---- ------
---- Always supply the .png path. The BW UI modules automatically substitute
---- .bmp when running on a BW radio, using the same filename.
----   Image files must exist at:
----     Color  : IMG_DIR/<subdir>/<name>.png
----     BW128  : IMG_DIR/<subdir>/<name>.bmp  (1-bit monochrome, max ~62x52 px)
----     BW212  : IMG_DIR/<subdir>/<name>.bmp  (4-bit grayscale,  max ~110x52 px)
----
---- PAGE STRUCTURE
---- --------------
---- Each wizard page is built with:
----
----   wizard.clear()          -- clear previous page state
----
----   wizard.page({
----     title        = string,   -- wizard name shown at top (color) or ignored (BW)
----     subtitle     = string,   -- page title (color) / first line on BW
----     bw_subtitle  = string,   -- (optional) shorter subtitle for BW radios
----     hasPrevious  = bool,     -- show/enable Previous button
----     hasNext      = bool,     -- show/enable Next button
----     nextFunc     = function, -- called when Next is pressed
----     previousFunc = function, -- called when Previous is pressed
----     children1    = table,    -- left-column content (settings list)
----     children2    = table,    -- right-column content (images, labels)
----   })
----
----   wizard.build(page)      -- render the page
----
---- SETTINGS ROWS  (go into children1)
---- ------------------------------------
---- Horizontal layout - label on the left, control(s) on the right:
----   wizard.settings({
----     title       = string,   -- label shown on color radios
----     bw_title    = string,   -- (optional) shorter label for BW radios
----     visible     = function, -- (optional) function() return bool end
----     children    = { <controls> },
----   })
----
---- Vertical layout - label above, control below (use for long labels or
---- multi-line choices):
----   wizard.settingsVertical({
----     title       = string,
----     bw_title    = string,   -- (optional)
----     visible     = function, -- (optional)
----     children    = { <controls> },
----   })
----
---- CONTROLS  (go into the children table inside a settings row)
---- -------------------------------------------------------------
----   Toggle (Yes/No):
----     { type = "toggle",
----       get = function() return 0|1 end,
----       set = function(val) ... end }
----
----   Choice (drop-down list):
----     { type = "choice",
----       values  = { "Option1", "Option2", ... },
----       get     = function() return 1-based-index end,
----       set     = function(val) ... end,   -- val is 1-based
----       visible = function() return bool end }  -- (optional)
----
----   Number (editable integer):
----     { type = "numberEdit",
----       min = number, max = number,
----       get = function() return value end,
----       set = function(val) ... end }
----
---- IMAGES  (go into children2)
---- ----------------------------
----   wizard.image({
----     file        = string,              -- path ending in .png
----     visibleFunc = function() bool end, -- (optional) show conditionally
----   })
----
---- SUMMARY ROWS  (go into children1 of the summary page)
---- -------------------------------------------------------
----   wizard.summaryLine(label, channelIndex, textValue)
----     label        - string label
----     channelIndex - if non-nil, shown as "CH<n+1>"
----     textValue    - if channelIndex is nil, shown as-is
----
---- HOW TO ADD A NEW PAGE
---- ----------------------
---- 1. Declare a Fields table for the new page's data.
---- 2. Write a runXxxConfig() function following the pattern below.
---- 3. Add runXxxConfig to the pages table in init().
---- 4. If the new page sets model properties, add the logic to createModel().
---- 5. Add summary row(s) in runConfigSummary().
---- =========================================================================

local wizardType = ...

local RUN_DIR   = "/TEMPLATES/1.Wizard/lib"
local IMG_DIR   = "/TEMPLATES/1.Wizard/img"
---- IMG_SUBDIR: name of the subdirectory under IMG_DIR that holds this
---- wizard's images.  Must match the actual folder on the SD card.
local IMG_SUBDIR = wizardType   -- "plane", "glider", or "wing"

local RUDDER_NAME_AIL = (wizardType ~= "wing") and "Aileron" or "Elevon"
local WIZARD_TITLE    = string.gsub(string.lower(wizardType), "^%l", string.upper) .. " Wizard"

local modelConfig = loadScript(RUN_DIR .. "/model-config.lua")()
local wizard      = loadScript(RUN_DIR .. "/wizard-ui.lua")()

local page  = 1
local pages = {}

local STICK_NUMBER_AIL = 3
local STICK_NUMBER_ELE = 1
local STICK_NUMBER_THR = 2
local STICK_NUMBER_RUD = 0

local defaultChannel_0_AIL = defaultChannel(STICK_NUMBER_AIL)
local defaultChannel_0_ELE = defaultChannel(STICK_NUMBER_ELE)
local defaultChannel_0_THR = defaultChannel(STICK_NUMBER_THR)
local defaultChannel_0_RUD = defaultChannel(STICK_NUMBER_RUD)

---- Returns the full path for an image file.
---- Always pass the .png filename; BW UI modules convert to .bmp automatically.
local function getImagePath(filename)
    return IMG_DIR .. "/" .. IMG_SUBDIR .. "/" .. filename
end

local function selectPage(step)
    page = page + step
    pages[page]()
end

---- =========================================================================
---- PAGE 1: Motor Settings
---- =========================================================================
local MotorFields = {
    is_motor  = { value = 1, avail_values = { "No", "Yes" } },
    motor_ch  = { value = defaultChannel_0_THR,
                  avail_values = { "CH1","CH2","CH3","CH4","CH5","CH6","CH7","CH8","CH9","CH10" } },
    is_arm    = { value = 1, avail_values = { "No", "Yes" } },
    arm_switch = { value = 5,
                   avail_values = { "SA","SB","SC","SD","SE","SF","SG","SH" } },
}

local function runMotorConfig()
    wizard.clear()

    local children1 = {
        wizard.settings({
            title    = "Have a motor?",
            bw_title = "Motor?",
            children = {
                { type = "toggle",
                  get  = function() return MotorFields.is_motor.value end,
                  set  = function(val) MotorFields.is_motor.value = val end },
            },
        }),

        wizard.settings({
            title    = "Motor channel",
            bw_title = "Motor Ch",
            visible  = function() return MotorFields.is_motor.value == 1 end,
            children = {
                { type   = "choice",
                  values = MotorFields.motor_ch.avail_values,
                  get    = function() return MotorFields.motor_ch.value + 1 end,
                  set    = function(val) MotorFields.motor_ch.value = val - 1 end },
            },
        }),

        wizard.settings({
            title    = "Safety Switch",
            bw_title = "Arm Sw",
            visible  = function() return MotorFields.is_motor.value == 1 end,
            children = {
                { type = "toggle",
                  get  = function() return MotorFields.is_arm.value end,
                  set  = function(val) MotorFields.is_arm.value = val end },
                { type    = "choice",
                  values  = MotorFields.arm_switch.avail_values,
                  visible = function() return MotorFields.is_arm.value == 1 end,
                  get     = function() return MotorFields.arm_switch.value + 1 end,
                  set     = function(val) MotorFields.arm_switch.value = val - 1 end },
            },
        }),
    }

    local children2 = {
        wizard.image({ file = getImagePath("prop.png") }),
    }

    local p = wizard.page({
        title       = WIZARD_TITLE,
        subtitle    = "Motor Settings",
        bw_subtitle = "Motor Set",
        hasPrevious = false,
        hasNext     = true,
        nextFunc    = function() selectPage(1) end,
        children1   = children1,
        children2   = children2,
    })
    wizard.build(p)
end

---- =========================================================================
---- PAGE 2: Aileron / Elevon Settings
---- =========================================================================
local AilFields = {
    ail_type = { value = 2,
                 avail_values = { "None", "One", "Two" } },
    ail_ch_a = { value = defaultChannel_0_AIL,
                 avail_values = { "CH1","CH2","CH3","CH4","CH5","CH6","CH7","CH8","CH9","CH10" } },
    ail_ch_b = { value = defaultChannel_0_AIL + 1,
                 avail_values = { "CH1","CH2","CH3","CH4","CH5","CH6","CH7","CH8","CH9","CH10" } },
}

local function runAilConfig()
    wizard.clear()

    local children1 = {
        wizard.settings({
            title    = "Number of " .. RUDDER_NAME_AIL,
            bw_title = "# " .. RUDDER_NAME_AIL,
            visible  = function() return wizardType ~= "wing" end,
            children = {
                { type   = "choice",
                  values = AilFields.ail_type.avail_values,
                  get    = function() return AilFields.ail_type.value + 1 end,
                  set    = function(val) AilFields.ail_type.value = val - 1 end },
            },
        }),

        wizard.settings({
            title    = "A (right)",
            bw_title = "A (R)",
            visible  = function() return AilFields.ail_type.value > 0 end,
            children = {
                { type   = "choice",
                  values = AilFields.ail_ch_a.avail_values,
                  get    = function() return AilFields.ail_ch_a.value + 1 end,
                  set    = function(val) AilFields.ail_ch_a.value = val - 1 end },
            },
        }),

        wizard.settings({
            title   = "B (left)",
            visible = function() return AilFields.ail_type.value == 2 end,
            children = {
                { type   = "choice",
                  values = AilFields.ail_ch_b.avail_values,
                  get    = function() return AilFields.ail_ch_b.value + 1 end,
                  set    = function(val) AilFields.ail_ch_b.value = val - 1 end },
            },
        }),
    }

    local children2 = {
        wizard.image({ file = getImagePath("plane-2a.png"),
                       visibleFunc = function() return AilFields.ail_type.value == 2 end }),
        wizard.image({ file = getImagePath("plane-1a.png"),
                       visibleFunc = function() return AilFields.ail_type.value == 1 end }),
        wizard.image({ file = getImagePath("plane.png"),
                       visibleFunc = function() return AilFields.ail_type.value == 0 end }),
    }

    local p = wizard.page({
        title        = WIZARD_TITLE,
        subtitle     = RUDDER_NAME_AIL .. " Settings",
        hasPrevious  = true,
        hasNext      = true,
        nextFunc     = function() selectPage(1) end,
        previousFunc = function() selectPage(-1) end,
        children1    = children1,
        children2    = children2,
    })
    wizard.build(p)
end

---- =========================================================================
---- PAGE 3: Flaps Settings
---- =========================================================================
local FlapsFields = {
    flap_type = { value = 0, avail_values = { "No", "Yes (one)", "Yes (two)" } },
    flap_ch_a = { value = 7, avail_values = { "CH1","CH2","CH3","CH4","CH5","CH6","CH7","CH8","CH9","CH10" } },
    flap_ch_b = { value = 8, avail_values = { "CH1","CH2","CH3","CH4","CH5","CH6","CH7","CH8","CH9","CH10" } },
}

local function runFlapsConfig()
    wizard.clear()

    local children1 = {
        wizard.settings({
            title    = "Do you have flaps",
            bw_title = "Flaps?",
            children = {
                { type   = "choice",
                  values = FlapsFields.flap_type.avail_values,
                  get    = function() return FlapsFields.flap_type.value + 1 end,
                  set    = function(val) FlapsFields.flap_type.value = val - 1 end },
            },
        }),

        wizard.settings({
            title   = "A (right)",
            visible = function() return FlapsFields.flap_type.value > 0 end,
            children = {
                { type   = "choice",
                  values = FlapsFields.flap_ch_a.avail_values,
                  get    = function() return FlapsFields.flap_ch_a.value + 1 end,
                  set    = function(val) FlapsFields.flap_ch_a.value = val - 1 end },
            },
        }),

        wizard.settings({
            title   = "B (left)",
            visible = function() return FlapsFields.flap_type.value == 2 end,
            children = {
                { type   = "choice",
                  values = FlapsFields.flap_ch_b.avail_values,
                  get    = function() return FlapsFields.flap_ch_b.value + 1 end,
                  set    = function(val) FlapsFields.flap_ch_b.value = val - 1 end },
            },
        }),
    }

    local children2 = {
        wizard.image({ file = getImagePath("plane-2f.png"),
                       visibleFunc = function() return FlapsFields.flap_type.value == 2 end }),
        wizard.image({ file = getImagePath("plane-1f.png"),
                       visibleFunc = function() return FlapsFields.flap_type.value == 1 end }),
        wizard.image({ file = getImagePath("plane.png"),
                       visibleFunc = function() return FlapsFields.flap_type.value == 0 end }),
    }

    local p = wizard.page({
        title        = WIZARD_TITLE,
        subtitle     = "Flaps Settings",
        bw_subtitle  = "Flaps Set",
        hasPrevious  = true,
        hasNext      = true,
        nextFunc     = function() selectPage(1) end,
        previousFunc = function() selectPage(-1) end,
        children1    = children1,
        children2    = children2,
    })
    wizard.build(p)
end

---- =========================================================================
---- PAGE 4: Tail Settings
---- =========================================================================
local TailFields = {
    tail_type = { value = 1,
                  avail_values = {
                      "1 CH for Elevator, no Rudder",
                      "1 CH for Elevator, 1 for Rudder",
                      "2 CH for Elevator, 1 for Rudder",
                      "V Tail",
                  } },
    ch_a = { value = defaultChannel_0_ELE,
             avail_values = { "CH1","CH2","CH3","CH4","CH5","CH6","CH7","CH8","CH9","CH10" } },
    ch_b = { value = defaultChannel_0_RUD,
             avail_values = { "CH1","CH2","CH3","CH4","CH5","CH6","CH7","CH8","CH9","CH10" } },
    ch_c = { value = 5,
             avail_values = { "CH1","CH2","CH3","CH4","CH5","CH6","CH7","CH8","CH9","CH10" } },
}

local function runTailConfig()
    wizard.clear()

    local children1 = {
        wizard.settingsVertical({
            title    = "Select your tail configuration",
            bw_title = "Tail Type",
            children = {
                { type   = "choice",
                  values = TailFields.tail_type.avail_values,
                  get    = function() return TailFields.tail_type.value + 1 end,
                  set    = function(val) TailFields.tail_type.value = val - 1 end },
            },
        }),

        wizard.settings({
            title = "Channel for A",
            children = {
                { type   = "choice",
                  values = TailFields.ch_a.avail_values,
                  get    = function() return TailFields.ch_a.value + 1 end,
                  set    = function(val) TailFields.ch_a.value = val - 1 end },
            },
        }),

        wizard.settings({
            title   = "Channel for B",
            visible = function() return TailFields.tail_type.value > 0 end,
            children = {
                { type   = "choice",
                  values = TailFields.ch_b.avail_values,
                  get    = function() return TailFields.ch_b.value + 1 end,
                  set    = function(val) TailFields.ch_b.value = val - 1 end },
            },
        }),

        wizard.settings({
            title   = "Channel for C",
            visible = function() return TailFields.tail_type.value == 2 end,
            children = {
                { type   = "choice",
                  values = TailFields.ch_c.avail_values,
                  get    = function() return TailFields.ch_c.value + 1 end,
                  set    = function(val) TailFields.ch_c.value = val - 1 end },
            },
        }),
    }

    local children2 = {
        wizard.image({ file = getImagePath("tail-1.png"),
                       visibleFunc = function() return TailFields.tail_type.value == 0 end }),
        wizard.image({ file = getImagePath("tail-2.png"),
                       visibleFunc = function() return TailFields.tail_type.value == 1 end }),
        wizard.image({ file = getImagePath("tail-3.png"),
                       visibleFunc = function() return TailFields.tail_type.value == 2 end }),
        wizard.image({ file = getImagePath("tail-4.png"),
                       visibleFunc = function() return TailFields.tail_type.value == 3 end }),
    }

    local p = wizard.page({
        title        = WIZARD_TITLE,
        subtitle     = "Tail Settings",
        bw_subtitle  = "Tail Set",
        hasPrevious  = true,
        hasNext      = true,
        nextFunc     = function() selectPage(1) end,
        previousFunc = function() selectPage(-1) end,
        children1    = children1,
        children2    = children2,
    })
    wizard.build(p)
end

---- =========================================================================
---- PAGE 5: Landing Gear
---- =========================================================================
local GearFields = {
    is_gear = { value = 0, avail_values = { "No", "Yes" } },
    switch  = { value = 3, avail_values = { "SA","SB","SC","SD","SE","SF","SG","SH" } },
    channel = { value = 6, avail_values = { "CH1","CH2","CH3","CH4","CH5","CH6","CH7","CH8","CH9","CH10" } },
}

local function runGearConfig()
    wizard.clear()

    local children1 = {
        wizard.settings({
            title    = "Does your model have retract landing gears?",
            bw_title = "Retract gear?",
            children = {
                { type   = "choice",
                  values = GearFields.is_gear.avail_values,
                  get    = function() return GearFields.is_gear.value + 1 end,
                  set    = function(val) GearFields.is_gear.value = val - 1 end },
            },
        }),

        wizard.settings({
            title   = "Retracts switch",
            visible = function() return GearFields.is_gear.value > 0 end,
            children = {
                { type   = "choice",
                  values = GearFields.switch.avail_values,
                  get    = function() return GearFields.switch.value + 1 end,
                  set    = function(val) GearFields.switch.value = val - 1 end },
            },
        }),

        wizard.settings({
            title   = "Retracts channel",
            visible = function() return GearFields.is_gear.value > 0 end,
            children = {
                { type   = "choice",
                  values = GearFields.channel.avail_values,
                  get    = function() return GearFields.channel.value + 1 end,
                  set    = function(val) GearFields.channel.value = val - 1 end },
            },
        }),
    }

    local children2 = {
        wizard.image({ file = getImagePath("plane.png") }),
    }

    local p = wizard.page({
        title        = WIZARD_TITLE,
        subtitle     = "Landing Gear",
        bw_subtitle  = "Lnd Gear",
        hasPrevious  = true,
        hasNext      = true,
        nextFunc     = function() selectPage(1) end,
        previousFunc = function() selectPage(-1) end,
        children1    = children1,
        children2    = children2,
    })
    wizard.build(p)
end

---- =========================================================================
---- PAGE 6: Additional Settings (Expo / Dual Rate)
---- =========================================================================
local AdditionalSettingsFields = {
    expo         = { value = 30, min = 0, max = 100 },
    is_dual_rate = { value = 1, avail_values = { "No", "Yes" } },
    dr_switch    = { value = 2, avail_values = { "SA","SB","SC","SD","SE","SF","SG","SH" } },
}

local function runAdditionalSettings()
    wizard.clear()

    local children1 = {
        wizard.settings({
            title = "Expo",
            children = {
                { type = "numberEdit",
                  w    = lvgl.PERCENT_SIZE + 100,
                  min  = AdditionalSettingsFields.expo.min,
                  max  = AdditionalSettingsFields.expo.max,
                  get  = function() return AdditionalSettingsFields.expo.value end,
                  set  = function(val) AdditionalSettingsFields.expo.value = val end },
            },
        }),

        wizard.settings({
            title = "Dual Rate",
            children = {
                { type = "toggle",
                  get  = function() return AdditionalSettingsFields.is_dual_rate.value end,
                  set  = function(val) AdditionalSettingsFields.is_dual_rate.value = val end },
                { type    = "choice",
                  values  = AdditionalSettingsFields.dr_switch.avail_values,
                  visible = function() return AdditionalSettingsFields.is_dual_rate.value == 1 end,
                  get     = function() return AdditionalSettingsFields.dr_switch.value + 1 end,
                  set     = function(val) AdditionalSettingsFields.dr_switch.value = val - 1 end },
            },
        }),
    }

    local p = wizard.page({
        title        = WIZARD_TITLE,
        subtitle     = "Additional Settings",
        bw_subtitle  = "Extra Set",
        hasPrevious  = true,
        hasNext      = true,
        nextFunc     = function() selectPage(1) end,
        previousFunc = function() selectPage(-1) end,
        children1    = children1,
        children2    = nil,
    })
    wizard.build(p)
end

---- =========================================================================
---- PAGE 7: Summary
---- =========================================================================
local function runConfigSummary()
    local rows = {}
    local function addRows(...) for _, v in ipairs({...}) do rows[#rows+1] = v end end

    if MotorFields.is_motor.value == 1 then
        addRows(wizard.summaryLine("Motor Channel", MotorFields.motor_ch.value))
    end

    if AilFields.ail_type.value == 1 then
        addRows(wizard.summaryLine(RUDDER_NAME_AIL .. " channel", AilFields.ail_ch_a.value))
    elseif AilFields.ail_type.value == 2 then
        addRows(wizard.summaryLine(RUDDER_NAME_AIL .. " R channel", AilFields.ail_ch_a.value),
                wizard.summaryLine(RUDDER_NAME_AIL .. " L channel", AilFields.ail_ch_b.value))
    end

    if FlapsFields.flap_type.value == 1 then
        addRows(wizard.summaryLine("Flaps channel", FlapsFields.flap_ch_a.value))
    elseif FlapsFields.flap_type.value == 2 then
        addRows(wizard.summaryLine("Flaps R channel", FlapsFields.flap_ch_a.value),
                wizard.summaryLine("Flaps L channel", FlapsFields.flap_ch_b.value))
    end

    if wizardType ~= "wing" then
        if TailFields.tail_type.value == 0 then
            addRows(wizard.summaryLine("Elevator channel", TailFields.ch_a.value))
        elseif TailFields.tail_type.value == 1 then
            addRows(wizard.summaryLine("Elevator channel", TailFields.ch_a.value),
                    wizard.summaryLine("Rudder channel",   TailFields.ch_b.value))
        elseif TailFields.tail_type.value == 2 then
            addRows(wizard.summaryLine("Elevator R channel", TailFields.ch_a.value),
                    wizard.summaryLine("Rudder channel",     TailFields.ch_b.value),
                    wizard.summaryLine("Elevator L channel", TailFields.ch_c.value))
        elseif TailFields.tail_type.value == 3 then
            addRows(wizard.summaryLine("V-Tail Right", TailFields.ch_a.value),
                    wizard.summaryLine("V-Tail Left",  TailFields.ch_b.value))
        end

        if GearFields.is_gear.value == 1 then
            local swName = GearFields.switch.avail_values[1 + GearFields.switch.value]
            addRows(wizard.summaryLine("Gear Switch",   nil, swName),
                    wizard.summaryLine("Gear Channel",  GearFields.channel.value))
        else
            addRows(wizard.summaryLine("Gear Switch",   nil, "None"),
                    wizard.summaryLine("Gear Channel",  nil, "None"))
        end
    end

    addRows(wizard.summaryLine("Expo", nil, AdditionalSettingsFields.expo.value))

    local drText = AdditionalSettingsFields.is_dual_rate.avail_values[1 + AdditionalSettingsFields.is_dual_rate.value]
    if AdditionalSettingsFields.is_dual_rate.value == 1 then
        drText = drText .. " (" .. AdditionalSettingsFields.dr_switch.avail_values[1 + AdditionalSettingsFields.dr_switch.value] .. ")"
    end
    addRows(wizard.summaryLine("Dual Rate", nil, drText))

    if MotorFields.is_arm.value == 1 then
        addRows(wizard.summaryLine("Arm switch", nil,
            MotorFields.arm_switch.avail_values[1 + MotorFields.arm_switch.value]))
    end

    wizard.clear()

    local p = wizard.page({
        title        = WIZARD_TITLE,
        subtitle     = "Model Summary",
        bw_subtitle  = "Summary",
        hasPrevious  = true,
        hasNext      = true,
        nextFunc     = function() selectPage(1) end,
        previousFunc = function() selectPage(-1) end,
        children1    = rows,
        children2    = nil,   -- no image on summary page
    })
    wizard.build(p)
end

---- =========================================================================
---- PAGE 8: Apply configuration and show finished screen
---- =========================================================================
local function createModel()
    model.defaultInputs()

    if wizardType == "wing" then
        model.deleteInput(defaultChannel(STICK_NUMBER_RUD), 0)
    end

    model.deleteMixes()

    local expoVal    = AdditionalSettingsFields.expo.value
    local isDualRate = AdditionalSettingsFields.is_dual_rate.value == 1
    local drSwitch   = AdditionalSettingsFields.dr_switch.avail_values[1 + AdditionalSettingsFields.dr_switch.value]

    if isDualRate then
        modelConfig.updateInputLine(defaultChannel_0_AIL, 0, expoVal, 100, drSwitch .. CHAR_UP)
        modelConfig.updateInputLine(defaultChannel_0_AIL, 1, expoVal,  75, drSwitch .. "-")
        modelConfig.updateInputLine(defaultChannel_0_AIL, 2, expoVal,  50, drSwitch .. CHAR_DOWN)
        modelConfig.updateInputLine(defaultChannel_0_ELE, 0, expoVal, 100, drSwitch .. CHAR_UP)
        modelConfig.updateInputLine(defaultChannel_0_ELE, 1, expoVal,  75, drSwitch .. "-")
        modelConfig.updateInputLine(defaultChannel_0_ELE, 2, expoVal,  50, drSwitch .. CHAR_DOWN)
    else
        modelConfig.updateInputLine(defaultChannel_0_AIL, 0, expoVal, 100, nil)
        modelConfig.updateInputLine(defaultChannel_0_ELE, 0, expoVal, 100, nil)
    end

    if wizardType ~= "wing" then
        modelConfig.updateInputLine(defaultChannel_0_RUD, 0, expoVal, 100, nil)
    end

    if MotorFields.is_motor.value == 1 then
        modelConfig.addMix(MotorFields.motor_ch.value, MIXSRC_FIRST_INPUT + defaultChannel_0_THR, "Motor")
    end

    if wizardType ~= "wing" then
        if AilFields.ail_type.value == 1 then
            modelConfig.addMix(AilFields.ail_ch_a.value, MIXSRC_FIRST_INPUT + defaultChannel_0_AIL, "Ail")
        elseif AilFields.ail_type.value == 2 then
            modelConfig.addMix(AilFields.ail_ch_a.value, MIXSRC_FIRST_INPUT + defaultChannel_0_AIL, "Ail-R")
            modelConfig.addMix(AilFields.ail_ch_b.value, MIXSRC_FIRST_INPUT + defaultChannel_0_AIL, "Ail-L", -100)
        end
    else
        modelConfig.addMix(AilFields.ail_ch_a.value, MIXSRC_FIRST_INPUT + defaultChannel(STICK_NUMBER_ELE), "ele-R",  50)
        modelConfig.addMix(AilFields.ail_ch_a.value, MIXSRC_FIRST_INPUT + defaultChannel(STICK_NUMBER_AIL), "ail-R", -50)
        modelConfig.addMix(AilFields.ail_ch_b.value, MIXSRC_FIRST_INPUT + defaultChannel(STICK_NUMBER_ELE), "ele-L",  50)
        modelConfig.addMix(AilFields.ail_ch_b.value, MIXSRC_FIRST_INPUT + defaultChannel(STICK_NUMBER_AIL), "ail-L",  50)
    end

    if wizardType ~= "wing" then
        if FlapsFields.flap_type.value == 1 then
            modelConfig.addMix(FlapsFields.flap_ch_a.value, MIXSRC_SA, "Flaps")
        elseif FlapsFields.flap_type.value == 2 then
            modelConfig.addMix(FlapsFields.flap_ch_a.value, MIXSRC_SA, "FlapsR")
            modelConfig.addMix(FlapsFields.flap_ch_b.value, MIXSRC_SA, "FlapsL")
        end

        if TailFields.tail_type.value == 0 then
            modelConfig.addMix(TailFields.ch_a.value, MIXSRC_FIRST_INPUT + defaultChannel(1), "Elev")
        elseif TailFields.tail_type.value == 1 then
            modelConfig.addMix(TailFields.ch_a.value, MIXSRC_FIRST_INPUT + defaultChannel(1), "Elev")
            modelConfig.addMix(TailFields.ch_b.value, MIXSRC_FIRST_INPUT + defaultChannel(0), "Rudder")
        elseif TailFields.tail_type.value == 2 then
            modelConfig.addMix(TailFields.ch_a.value, MIXSRC_FIRST_INPUT + defaultChannel(1), "Elev-R")
            modelConfig.addMix(TailFields.ch_b.value, MIXSRC_FIRST_INPUT + defaultChannel(0), "Rudder")
            modelConfig.addMix(TailFields.ch_c.value, MIXSRC_FIRST_INPUT + defaultChannel(1), "Elev-L")
        elseif TailFields.tail_type.value == 3 then
            modelConfig.addMix(TailFields.ch_a.value, MIXSRC_FIRST_INPUT + defaultChannel(1), "V-EleR",  50)
            modelConfig.addMix(TailFields.ch_a.value, MIXSRC_FIRST_INPUT + defaultChannel(0), "V-RudR",  50, 1)
            modelConfig.addMix(TailFields.ch_b.value, MIXSRC_FIRST_INPUT + defaultChannel(1), "V-EleL",  50)
            modelConfig.addMix(TailFields.ch_b.value, MIXSRC_FIRST_INPUT + defaultChannel(0), "V-RudL", -50, 1)
        end

        if GearFields.is_gear.value == 1 then
            local switchIndex = MIXSRC_SA + GearFields.switch.value
            modelConfig.addMix(GearFields.channel.value, switchIndex, "Gear", 100, 0)
        end
    end

    if MotorFields.is_arm.value == 1 then
        local switchName  = MotorFields.arm_switch.avail_values[1 + MotorFields.arm_switch.value]
        local switchIndex = getSwitchIndex(switchName .. CHAR_DOWN)
        local channelIndex = MotorFields.motor_ch.value
        model.setCustomFunction(FUNC_OVERRIDE_CHANNEL, {
            switch  = switchIndex,
            func    = 0,
            value   = -100,
            mode    = 0,
            param   = channelIndex,
            active  = 1,
        })
    end
end

local function runFinished()
    createModel()
    wizard.clear()
    wizard.build(wizard.finishedPage({ title = WIZARD_TITLE }))
end

---- =========================================================================
---- Init and run
---- =========================================================================
local function init()
    if wizardType ~= "wing" then
        pages = {
            runMotorConfig,
            runAilConfig,
            runFlapsConfig,
            runTailConfig,
            runGearConfig,
            runAdditionalSettings,
            runConfigSummary,
            runFinished,
        }
    else
        pages = {
            runMotorConfig,
            runAilConfig,
            runAdditionalSettings,
            runConfigSummary,
            runFinished,
        }
    end
    pages[page]()
end

local function run(event, touchState)
    -- Let the UI module handle field navigation and editing (BW radios).
    -- Only intercept the specific events the UI module cares about.
    if event and (
        event == EVT_VIRTUAL_INC      or event == EVT_VIRTUAL_INC_REPT or
        event == EVT_VIRTUAL_DEC      or event == EVT_VIRTUAL_DEC_REPT or
        event == EVT_VIRTUAL_NEXT     or event == EVT_VIRTUAL_PREV     or
        event == EVT_VIRTUAL_ENTER    or event == EVT_VIRTUAL_EXIT)
    then
        if wizard.handleEvent and wizard.handleEvent(event, touchState) then
            if wizard.refresh then wizard.refresh() end
            return 0
        end
    end

    -- Continuous refresh when in edit mode (needed for BLINK flag).
    if wizard.needsRefresh and wizard.needsRefresh() then
        if wizard.refresh then wizard.refresh() end
    end

    -- Page-level navigation (Next Page / Prev Page buttons).
    if event == EVT_VIRTUAL_PREV_PAGE and page > 1 and page < #pages then
        killEvents(event)
        selectPage(-1)
    elseif event == EVT_VIRTUAL_NEXT_PAGE and page < #pages then
        killEvents(event)
        selectPage(1)
    end

    if wizard.exitWizard() == true then return 2 end
    return 0
end

return { run = run, init = init }
