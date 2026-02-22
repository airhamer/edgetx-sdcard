---- #########################################################################
---- #                                                                       #
---- # Multirotor Wizard                                                     #
---- #                                                                       #
---- # License GPLv2: http://www.gnu.org/licenses/gpl-2.0.html               #
---- #                                                                       #
---- #########################################################################
-- Author: 3djc (2017)
-- Update by: Offer Shmuely (2023)
-- Update by: Alexander Gnauck (2025)

---- =========================================================================
---- PAGE / SETTINGS API REFERENCE  (same as fixed-wing.lua -- see that file
---- for the full reference.  Summary below.)
----
---- IMAGES
----   Always supply the .png path.  The BW UI converts to .bmp automatically.
----   Files must exist at:
----     Color : IMG_DIR/<IMG_SUBDIR>/<n>.png
----     BW128 : IMG_DIR/<IMG_SUBDIR>/<n>.bmp  (1-bit mono, max ~62x52 px)
----     BW212 : IMG_DIR/<IMG_SUBDIR>/<n>.bmp  (4-bit grey, max ~110x52 px)
----   IMG_SUBDIR is defined near the top of this file.
----
---- PAGE STRUCTURE
----   wizard.clear()
----   local p = wizard.page({
----     title, subtitle, bw_subtitle,
----     hasPrevious, hasNext, nextFunc, previousFunc,
----     children1 = { <settings rows> },
----     children2 = { <wizard.image() entries> },
----   })
----   wizard.build(p)
----
---- SETTINGS ROWS  (children1)
----   wizard.settings({ title, bw_title, visible, children = { <controls> } })
----   wizard.settingsVertical({ title, bw_title, visible, children = { <controls> } })
----
---- CONTROLS
----   { type="toggle",     get=fn, set=fn }
----   { type="choice",     values={}, get=fn, set=fn, visible=fn }
----   { type="numberEdit", min=n, max=n, get=fn, set=fn }
----
---- IMAGES  (children2)
----   wizard.image({ file=path, visibleFunc=fn })
----
---- SUMMARY ROWS  (children1 of summary page)
----   wizard.summaryLine(label, channelIndex, textValue)
----
---- HOW TO ADD A NEW PAGE
----   1. Declare a Fields table for the page data.
----   2. Write a runXxxConfig() function.
----   3. Add it to the pages table in init().
----   4. Add model configuration logic in createModel().
----   5. Add summary row(s) in runConfigSummary().
---- =========================================================================

local page  = 1
local pages = {}

local STICK_NUMBER_AIL = 3
local STICK_NUMBER_ELE = 1
local STICK_NUMBER_THR = 2
local STICK_NUMBER_RUD = 0

local channels = { "CH1","CH2","CH3","CH4","CH5","CH6","CH7","CH8" }
local switches = { "SA","SB","SC","SD","SE","SF" }

local RUN_DIR    = "/TEMPLATES/1.Wizard/lib"
local IMG_DIR    = "/TEMPLATES/1.Wizard/img"
---- IMG_SUBDIR: subdirectory under IMG_DIR that holds this wizard's images.
---- Must match the actual folder name on the SD card.
local IMG_SUBDIR = "multirotor"

local WIZARD_TITLE = "Multirotor Wizard"

local modelConfig = loadScript(RUN_DIR .. "/model-config.lua")()
local wizard      = loadScript(RUN_DIR .. "/wizard-ui.lua")()

---- Returns the full image path.  Always pass a .png filename;
---- BW UI modules substitute .bmp automatically.
local function getImagePath(filename)
    return IMG_DIR .. "/" .. IMG_SUBDIR .. "/" .. filename
end

local function selectPage(step)
    page = page + step
    pages[page]()
end

---- =========================================================================
---- PAGE 1: Throttle
---- =========================================================================
local ThrottleFields = {
    value       = defaultChannel(STICK_NUMBER_THR),
    avail_values = channels,
}

local function runThrottleConfig()
    wizard.clear()

    local p = wizard.page({
        title       = WIZARD_TITLE,
        subtitle    = "Throttle Settings",
        bw_subtitle = "Thr Set",
        hasPrevious = false,
        hasNext     = true,
        nextFunc    = function() selectPage(1) end,
        children1   = {
            wizard.settings({
                title    = "Assign Throttle channel",
                bw_title = "Thr Ch",
                children = {
                    { type   = "choice",
                      values = ThrottleFields.avail_values,
                      get    = function() return ThrottleFields.value + 1 end,
                      set    = function(val) ThrottleFields.value = val - 1 end },
                },
            }),
        },
        children2 = { wizard.image({ file = getImagePath("throttle.png") }) },
    })
    wizard.build(p)
end

---- =========================================================================
---- PAGE 2: Roll
---- =========================================================================
local RollFields = {
    value        = defaultChannel(STICK_NUMBER_AIL),
    avail_values = channels,
}

local function runRollConfig()
    wizard.clear()

    local p = wizard.page({
        title        = WIZARD_TITLE,
        subtitle     = "Roll Settings",
        bw_subtitle  = "Roll Set",
        hasPrevious  = true,
        hasNext      = true,
        nextFunc     = function() selectPage(1) end,
        previousFunc = function() selectPage(-1) end,
        children1    = {
            wizard.settings({
                title    = "Assign Roll channel",
                bw_title = "Roll Ch",
                children = {
                    { type   = "choice",
                      values = RollFields.avail_values,
                      get    = function() return RollFields.value + 1 end,
                      set    = function(val) RollFields.value = val - 1 end },
                },
            }),
        },
        children2 = { wizard.image({ file = getImagePath("roll.png") }) },
    })
    wizard.build(p)
end

---- =========================================================================
---- PAGE 3: Pitch
---- =========================================================================
local PitchFields = {
    value        = defaultChannel(STICK_NUMBER_ELE),
    avail_values = channels,
}

local function runPitchConfig()
    wizard.clear()

    local p = wizard.page({
        title        = WIZARD_TITLE,
        subtitle     = "Pitch Settings",
        bw_subtitle  = "Pitch Set",
        hasPrevious  = true,
        hasNext      = true,
        nextFunc     = function() selectPage(1) end,
        previousFunc = function() selectPage(-1) end,
        children1    = {
            wizard.settings({
                title    = "Assign Pitch channel",
                bw_title = "Pitch Ch",
                children = {
                    { type   = "choice",
                      values = PitchFields.avail_values,
                      get    = function() return PitchFields.value + 1 end,
                      set    = function(val) PitchFields.value = val - 1 end },
                },
            }),
        },
        children2 = { wizard.image({ file = getImagePath("pitch.png") }) },
    })
    wizard.build(p)
end

---- =========================================================================
---- PAGE 4: Yaw
---- =========================================================================
local YawFields = {
    value        = defaultChannel(STICK_NUMBER_RUD),
    avail_values = channels,
}

local function runYawConfig()
    wizard.clear()

    local p = wizard.page({
        title        = WIZARD_TITLE,
        subtitle     = "Yaw Settings",
        bw_subtitle  = "Yaw Set",
        hasPrevious  = true,
        hasNext      = true,
        nextFunc     = function() selectPage(1) end,
        previousFunc = function() selectPage(-1) end,
        children1    = {
            wizard.settings({
                title    = "Assign Yaw channel",
                bw_title = "Yaw Ch",
                children = {
                    { type   = "choice",
                      values = YawFields.avail_values,
                      get    = function() return YawFields.value + 1 end,
                      set    = function(val) YawFields.value = val - 1 end },
                },
            }),
        },
        children2 = { wizard.image({ file = getImagePath("yaw.png") }) },
    })
    wizard.build(p)
end

---- =========================================================================
---- PAGE 5: Arm Switch
---- =========================================================================
local ArmFields = {
    value        = 5,
    avail_values = switches,
}

local function runArmConfig()
    wizard.clear()

    local p = wizard.page({
        title        = WIZARD_TITLE,
        subtitle     = "Arm switch",
        bw_subtitle  = "Arm Sw",
        hasPrevious  = true,
        hasNext      = true,
        nextFunc     = function() selectPage(1) end,
        previousFunc = function() selectPage(-1) end,
        children1    = {
            wizard.settings({
                title    = "Assign Arm switch",
                bw_title = "Arm Sw",
                children = {
                    { type   = "choice",
                      values = ArmFields.avail_values,
                      get    = function() return ArmFields.value + 1 end,
                      set    = function(val) ArmFields.value = val - 1 end },
                },
            }),
        },
        children2 = { wizard.image({ file = getImagePath("arm.png") }) },
    })
    wizard.build(p)
end

---- =========================================================================
---- PAGE 6: Beeper Switch
---- =========================================================================
local BeeperFields = {
    value        = 3,
    avail_values = switches,
}

local function runBeeperConfig()
    wizard.clear()

    local p = wizard.page({
        title        = WIZARD_TITLE,
        subtitle     = "Beeper switch",
        bw_subtitle  = "Beeper Sw",
        hasPrevious  = true,
        hasNext      = true,
        nextFunc     = function() selectPage(1) end,
        previousFunc = function() selectPage(-1) end,
        children1    = {
            wizard.settings({
                title    = "Assign Beeper switch",
                bw_title = "Beeper Sw",
                children = {
                    { type   = "choice",
                      values = BeeperFields.avail_values,
                      get    = function() return BeeperFields.value + 1 end,
                      set    = function(val) BeeperFields.value = val - 1 end },
                },
            }),
        },
        children2 = { wizard.image({ file = getImagePath("beeper.png") }) },
    })
    wizard.build(p)
end

---- =========================================================================
---- PAGE 7: Mode Switch
---- =========================================================================
local ModeFields = {
    value        = 0,
    avail_values = switches,
}

local function runModeConfig()
    wizard.clear()

    local p = wizard.page({
        title        = WIZARD_TITLE,
        subtitle     = "Mode switch",
        bw_subtitle  = "Mode Sw",
        hasPrevious  = true,
        hasNext      = true,
        nextFunc     = function() selectPage(1) end,
        previousFunc = function() selectPage(-1) end,
        children1    = {
            wizard.settings({
                title    = "Assign Mode switch",
                bw_title = "Mode Sw",
                children = {
                    { type   = "choice",
                      values = ModeFields.avail_values,
                      get    = function() return ModeFields.value + 1 end,
                      set    = function(val) ModeFields.value = val - 1 end },
                },
            }),
        },
        children2 = { wizard.image({ file = getImagePath("mode.png") }) },
    })
    wizard.build(p)
end

---- =========================================================================
---- PAGE 8: Summary
---- =========================================================================
local function runConfigSummary()
    local rows = {}
    local function addRows(...) for _, v in ipairs({...}) do rows[#rows+1] = v end end

    addRows(wizard.summaryLine("Throttle Ch", ThrottleFields.value))
    addRows(wizard.summaryLine("Roll Ch",     RollFields.value))
    addRows(wizard.summaryLine("Pitch Ch",    PitchFields.value))
    addRows(wizard.summaryLine("Yaw Ch",      YawFields.value))
    addRows(wizard.summaryLine("Arm Sw",   nil, ArmFields.avail_values[ArmFields.value + 1]))
    addRows(wizard.summaryLine("Beeper Sw", nil, BeeperFields.avail_values[BeeperFields.value + 1]))
    addRows(wizard.summaryLine("Mode Sw",   nil, ModeFields.avail_values[ModeFields.value + 1]))

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
        children2    = nil,
    })
    wizard.build(p)
end

---- =========================================================================
---- PAGE 9: Apply configuration
---- =========================================================================
local function createModel()
    model.defaultInputs()
    model.deleteMixes()

    modelConfig.addMix(ThrottleFields.value, MIXSRC_FIRST_INPUT + defaultChannel(STICK_NUMBER_THR), "Thr")
    modelConfig.addMix(RollFields.value,     MIXSRC_FIRST_INPUT + defaultChannel(STICK_NUMBER_AIL), "Roll")
    modelConfig.addMix(PitchFields.value,    MIXSRC_FIRST_INPUT + defaultChannel(STICK_NUMBER_ELE), "Pitch")
    modelConfig.addMix(YawFields.value,      MIXSRC_FIRST_INPUT + defaultChannel(STICK_NUMBER_RUD), "Yaw")
    modelConfig.addMix(4, MIXSRC_SA + ArmFields.value,    "Arm")
    modelConfig.addMix(5, MIXSRC_SA + BeeperFields.value, "Beeper")
    modelConfig.addMix(6, MIXSRC_SA + ModeFields.value,   "Mode")
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
    pages = {
        runThrottleConfig,
        runRollConfig,
        runPitchConfig,
        runYawConfig,
        runArmConfig,
        runBeeperConfig,
        runModeConfig,
        runConfigSummary,
        runFinished,
    }
    pages[page]()
end

local function run(event, touchState)
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

    if wizard.needsRefresh and wizard.needsRefresh() then
        if wizard.refresh then wizard.refresh() end
    end

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
