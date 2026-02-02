
-- Author: 3djc (2017)
-- Update by: Offer Shmuely (2023)
-- Update by: Alexander Gnauck (2025)

-- Plane template entry point (official-style)

return function(radio)
    local RUN_DIR  = "/TEMPLATES/1.Wizard"
    local CORE_DIR = RUN_DIR .. "/core"
    local LIB_DIR  = RUN_DIR .. "/lib"

    -- Load UI module based on radio detection
    local ui = loadScript(CORE_DIR .. "/" .. radio.uiModule)()

    -- Load multirotor wizard logic
    local wizardFunc = loadScript(LIB_DIR .. "/plane.lua")
    return wizardFunc(radio, ui)
end


