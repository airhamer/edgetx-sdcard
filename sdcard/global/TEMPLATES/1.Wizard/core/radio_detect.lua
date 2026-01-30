local function fileExists(path)
    local f = io.open(path, "r")
    if f then f:close() return true end
    return false
end

local function radio_detect()

    local radio = {}

    local ver, radioName, maj, minor, rev = getVersion()

    -- Screen type detection
    if LCD_W > 200 then
        radio.isColor = true
        radio.isBW212 = false
        radio.isBW128 = false
        radio.uiModule = "/color/TEMPLATES/1.Wizard/ui_color.lua"
        radio.imagePath = "/color/TEMPLATES/1.Wizard/img/multirotor/"
    elseif LCD_W > 150 then
        radio.isColor = false
        radio.isBW212 = true
        radio.isBW128 = false
        radio.uiModule = "/bw212x64/TEMPLATES/1.Wizard/ui_bw212.lua"
        radio.imagePath = "/bw212x64/TEMPLATES/1.Wizard/img/multirotor/"
    else
        radio.isColor = false
        radio.isBW212 = false
        radio.isBW128 = true
        radio.uiModule = "/bw128x64/TEMPLATES/1.Wizard/ui_bw128.lua"
        radio.imagePath = "/bw128x64/TEMPLATES/1.Wizard/img/multirotor/"
    end

    -- Default channel mapping
    radio.defaultChannel = function(idx)
        return defaultChannel(idx)
    end

    -- Switch detection
    if string.match(radioName, "x7") then
        radio.validSwitch = {1,2,3,4,5,6,7,8,9,10,11,12,13,15}
    elseif string.match(radioName, "xlite") then
        radio.validSwitch = {1,2,3,4,5,6,7,9,10,12}
    else
        radio.validSwitch = {1,2,3,4,5,6,7}
    end

    -- Optional user override
    if fileExists("/TEMPLATES/1.Wizard/core/radio_custom.lua") then
        local custom = loadScript("/TEMPLATES/1.Wizard/core/radio_custom.lua")()
        for k, v in pairs(custom) do
            radio[k] = v
        end
    end

    return radio
end

return radio_detect

