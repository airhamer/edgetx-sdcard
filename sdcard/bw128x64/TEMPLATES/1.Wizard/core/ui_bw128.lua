local ui = {}

function ui.renderPage(page, text, state, radio)
    lcd.clear()

    lcd.drawText(2, 2, page.title, SMLSIZE)

    local y = 14
    for _, line in ipairs(text) do
        lcd.drawText(2, y, line, SMLSIZE)
        y = y + 10
    end

    if page.options then
        local oy = y + 4
        for i, opt in ipairs(page.options) do
            local flags = SMLSIZE
            if i == state.selection then flags = flags + INVERS end
            lcd.drawText(4, oy, opt, flags)
            oy = oy + 10
        end
    end

    if page.image then
        local img = Bitmap.open(radio.imagePath .. page.image .. ".bmp")
        if img then
            local w, h = img:getSize()
            lcd.drawBitmap(img, LCD_W - w, LCD_H - h)
        end
    end
end

return ui

