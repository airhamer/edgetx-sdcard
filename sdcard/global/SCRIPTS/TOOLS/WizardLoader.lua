---- #########################################################################
---- #                                                                       #
---- # Wizard Loader - Model Type Selection                                  #
---- # Standalone tool that presents a list of available wizard types and   #
---- # launches the selected wizard script.                                 #
---- #                                                                       #
---- # License GPLv2: http://www.gnu.org/licenses/gpl-2.0.html               #
---- #                                                                       #
---- #########################################################################

---- HOW TO ADD A NEW MODEL TYPE TO THE WIZARD LOADER
---- =====================================================
---- 1. Create the wizard entry-point script, e.g.:
----       /TEMPLATES/1.Wizard/6.Boat.lua
----    That file should call the appropriate lib script, for example:
----       local wizard = loadScript(RUN_DIR .. "/lib/boat.lua")("boat")
----       return { init = wizard.init, run = wizard.run, useLvgl = true }
----
---- 2. Create the lib script (e.g. /TEMPLATES/1.Wizard/lib/boat.lua)
----    following the same pattern as fixed-wing.lua, heli.lua, or
----    multi-rotor.lua. See the comments at the top of those files for
----    the full page/settings API reference.
----
---- 3. Create an image directory and a representative image for the
----    selection screen:
----       /TEMPLATES/1.Wizard/img/boat/boat.png   (color radios)
----       /TEMPLATES/1.Wizard/img/boat/boat.bmp   (BW radios)
----    BW image format requirements:
----       128x64 radios: 1-bit monochrome BMP, max ~62x52 px
----       212x64 radios: 4-bit grayscale BMP,  max ~110x52 px
----
---- 4. Add one entry to the wizardList table below, following the
----    pattern of the existing entries:
----       { name = "Boat", script = RUN_DIR .. "/6.Boat.lua", image = "boat" }
----    The 'image' field is "subdir/basename" relative to IMG_DIR, without
----    extension. e.g. "helicopter/heli" -> IMG_DIR/helicopter/heli.bmp
----
---- 5. That's it. The loader handles display and navigation automatically.

local toolName = "TNS|Wizard Loader|TNE"

local RUN_DIR = "/TEMPLATES/1.Wizard"
local IMG_DIR = RUN_DIR .. "/img"

local selectedWizard = 0
local dirty = true  -- Start dirty so first frame draws

---- Wizard list
---- Each entry: { name, script, image }
----   name   - display name shown in the selection list
----   script - full path to the entry-point .lua for that wizard
----   image  - "subdir/basename" relative to IMG_DIR, without extension.
----             e.g. "helicopter/heli" -> IMG_DIR/helicopter/heli.bmp
local wizardList = {
    { name = "Plane",  script = RUN_DIR .. "/1.Plane.lua",      image = "plane/plane"           },
    { name = "Glider", script = RUN_DIR .. "/2.Glider.lua",     image = "glider/plane"          },
    { name = "Wing",   script = RUN_DIR .. "/3.Wing.lua",       image = "wing/wing"             },
    { name = "Heli",   script = RUN_DIR .. "/4.Helicopter.lua", image = "helicopter/heli"       },
    { name = "Multi",  script = RUN_DIR .. "/5.Multirotor.lua", image = "multirotor/multi"      },
}

local function init()
    selectedWizard = 0
    dirty = true  -- Force redraw on (re)init
end

---- Detect whether this is a real color radio (native LVGL) vs a BW radio.
---- We check for an actual LVGL function rather than just lvgl ~= nil,
---- because the BW UI modules install a fake lvgl shim that would otherwise
---- make a second run misidentify the radio as color.
local function isColorRadio()
    return lvgl ~= nil and (type(lvgl.Page) == "function" or type(lvgl.clear) == "function")
end

local function getImagePath()
    local imgExt = isColorRadio() and ".png" or ".bmp"
    local entry  = wizardList[selectedWizard + 1]
    return IMG_DIR .. "/" .. entry.image .. imgExt
end

local function drawSelection()
    lcd.clear()

    local lcdW = LCD_W or 128
    local lcdH = LCD_H or 64
    local currentImage = getImagePath()

    if lcdW >= 212 then
        ---- 212x64 BW radio layout
        ---- Title bar across full width, vertical divider at x=100,
        ---- list on the left, image on the right.
        lcd.drawScreenTitle("Select Model Type", 0, 0)
        lcd.drawLine(100, 9, 100, lcdH - 1, DOTTED, 0)

        local y = 12
        for i, wiz in ipairs(wizardList) do
            local flags = SMLSIZE
            if i - 1 == selectedWizard then flags = SMLSIZE + INVERS end
            lcd.drawText(10, y, wiz.name, flags)
            y = y + 10
        end

        pcall(function() lcd.drawPixmap(106, 12, currentImage) end)

    elseif lcdW == 128 then
        ---- 128x64 BW radio layout
        ---- Title on line 1, scrolling list on left (4 visible items),
        ---- scroll indicators at x=58, image on right half.
        lcd.drawText(1, 1, "Select Type", 0)

        local maxVisible  = 4
        local scrollOffset = 0
        if selectedWizard >= maxVisible then
            scrollOffset = selectedWizard - maxVisible + 1
        end

        local y = 12
        for i = scrollOffset + 1, math.min(scrollOffset + maxVisible, #wizardList) do
            local flags = SMLSIZE
            if i - 1 == selectedWizard then flags = SMLSIZE + INVERS end
            lcd.drawText(2, y, wizardList[i].name, flags)
            y = y + 10
        end

        if scrollOffset > 0 then
            lcd.drawText(58, 12, "^", SMLSIZE)
        end
        if scrollOffset + maxVisible < #wizardList then
            lcd.drawText(58, lcdH - 10, "v", SMLSIZE)
        end

        pcall(function() lcd.drawPixmap(62, 12, currentImage) end)

    else
        ---- Color radio layout
        ---- Simple full-screen list with large image on the right.
        lcd.drawText(10, 10, "Select Model Type", DBLSIZE)

        local y = 50
        for i, wiz in ipairs(wizardList) do
            local flags = 0
            if i - 1 == selectedWizard then flags = INVERS end
            lcd.drawText(10, y, wiz.name, flags)
            y = y + 30
        end

        if lcdW > 200 then
            pcall(function() lcd.drawPixmap(lcdW - 150, 50, currentImage) end)
        end
    end
end

local function run(event, touchState)
    ---- Handle input events first, then redraw only when something changed.

    if event == EVT_VIRTUAL_EXIT then
        return 2  -- Exit tool

    elseif event == EVT_VIRTUAL_INC or event == EVT_VIRTUAL_INC_REPT then
        if selectedWizard < #wizardList - 1 then
            selectedWizard = selectedWizard + 1
            dirty = true
        end

    elseif event == EVT_VIRTUAL_DEC or event == EVT_VIRTUAL_DEC_REPT then
        if selectedWizard > 0 then
            selectedWizard = selectedWizard - 1
            dirty = true
        end

    elseif event == EVT_VIRTUAL_ENTER then
        return wizardList[selectedWizard + 1].script
    end

    if dirty then
        drawSelection()
        dirty = false
    end

    return 0
end

return { init = init, run = run }
