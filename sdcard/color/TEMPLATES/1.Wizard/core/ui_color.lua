local ui = {}
local ui_common = loadScript("/TEMPLATES/1.Wizard/core/ui_common.lua")()

function ui.renderPage(page, text, state, radio)
    lcd.clear()

    -- Title
    lcd.drawText(10, 5, page.title, MIDSIZE + COLOR_THEME_PRIMARY1)

    -- Text
    local y = 40
    for _, line in ipairs(text) do
        lcd.drawText(10, y, line, SMLSIZE)
        y = y + 20
    end

    -- Options
    if page.options then
        local oy = y + 10
        for i, opt in ipairs(page.options) do
            local flags = MIDSIZE
            if i == state.selection then flags = flags + INVERS end
            lcd.drawText(20, oy, opt, flags)
            oy = oy + 26
        end
    end

    -- Image
    if page.image then
        local img = Bitmap.open(radio.imagePath .. page.image .. ".png")
        if img then
            local w, h = img:getSize()
            lcd.drawBitmap(img, LCD_W - w - 10, LCD_H - h - 10)
        end
    end
end

return ui

