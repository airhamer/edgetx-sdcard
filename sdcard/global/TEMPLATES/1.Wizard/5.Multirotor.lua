-- 5.Multirotor.lua
-- Place in: /TEMPLATES/1.Wizard/
-- Works both standalone (color radios) and via wizard.lua (BW radios)

return function(radio, ui)
    local BASE_DIR = "/TEMPLATES/1.Wizard"
    local LIB_DIR = BASE_DIR .. "/lib"
    local CORE_DIR = BASE_DIR .. "/core"
    
    -- If radio/ui not provided, detect them now (color radio direct call)
    if not radio then
        local radioDetect = assert(loadScript(CORE_DIR .. "/radio_detect.lua"))()()
        radio = radioDetect
    end
    
    if not ui then
        local uiLoader = assert(loadScript(CORE_DIR .. "/" .. radio.uiModule))()
        ui = uiLoader
    end
    
    -- Load the actual wizard logic and call it
    local wizardBuilder = assert(loadScript(LIB_DIR .. "/multi-rotor.lua"))()
    
    -- Call the builder with radio and ui to get wizard instance
    return wizardBuilder(radio, ui)
end
