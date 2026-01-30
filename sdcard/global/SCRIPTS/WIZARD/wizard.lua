-- Dynamic Unified Wizard Entry Point for BW Radios
-- Scans available templates and lets the user choose one.

local radio = loadScript("/TEMPLATES/1.Wizard/core/radio_detect.lua")()
local ui = loadScript(radio.uiModule)()

local TEMPLATE_DIR = "/TEMPLATES/1.Wizard/"

local templates = {}
local selection = 1
local loadedWizard = nil

----------------------------------------------------------------------
-- Scan template directory for N.Name.lua files
----------------------------------------------------------------------
local function scanTemplates()
    local dir = TEMPLATE_DIR
    local f = dir and dir .. "."

    local d = dir and dir .. ""
    local file = nil

    local idx = 0
    while true do
        file = dir and dir .. string.format("%d.", idx)
        idx = idx + 1
        if not file then break end
        -- This is a placeholder; EdgeTX Lua doesn't support full directory scanning.
        -- Instead, we manually check known template numbers.
        -- You can expand this list as you add templates.
	local candidates = {
	    "1.Plane.lua",
	    "2.Glider.lua",
	    "3.Wing.lua",
	    "4.Helicopter.lua",
	    "5.Multirotor.lua"
	}
        for _, name in ipairs(candidates) do
            local path = TEMPLATE_DIR .. name
            local f = io.open(path, "r")
            if f then
                f:close()
                local base = name:gsub("^%d+%.", ""):gsub("%.lua$", "")
                table.insert(templates, { file = name, name = base })
            end
        end
        break
    end
end

scanTemplates()

----------------------------------------------------------------------
-- Render template selection screen
----------------------------------------------------------------------
local function renderChooser()
    lcd.clear()

    lcd.drawText(2, 2, "Select Template", SMLSIZE)

    local y = 16
    for i, t in ipairs(templates) do
        local flags = SMLSIZE
        if i == selection then flags = flags + INVERS end
        lcd.drawText(4, y, t.name, flags)
        y = y + 12
    end
end

----------------------------------------------------------------------
-- Handle input for template chooser
----------------------------------------------------------------------
local function chooserRun(event)
    if event == EVT_VIRTUAL_NEXT or event == EVT_PLUS_FIRST then
        selection = math.min(#templates, selection + 1)
    elseif event == EVT_VIRTUAL_PREV or event == EVT_MINUS_FIRST then
        selection = math.max(1, selection - 1)
    elseif event == EVT_VIRTUAL_ENTER then
        local chosen = templates[selection]
        if chosen then
            local path = TEMPLATE_DIR .. chosen.file
            local wizard = loadScript(path)
            if wizard then
                loadedWizard = wizard()
            end
        end
    end

    if loadedWizard then
        loadedWizard.run(event)
    else
        renderChooser()
    end
end

return { run = chooserRun }
