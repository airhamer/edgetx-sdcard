local ui_common = {}

function ui_common.selectTextVariant(page, radio)
    if radio.isColor and page.text.color then
        return page.text.color
    elseif radio.isBW212 and page.text.bw212 then
        return page.text.bw212
    else
        return page.text.default
    end
end

return ui_common
