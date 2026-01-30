local function core_engine()

    local radio = loadScript("/TEMPLATES/1.Wizard/core/radio_detect.lua")()
    local ui = loadScript(radio.uiModule)()

    local state = {
        currentIndex = 1,
        selection = 1,
        pages = nil,
        model = nil
    }

    local function findPage(id)
        for i, p in ipairs(state.pages) do
            if p.id == id then return p, i end
        end
        return nil
    end

    local function chooseTextVariant(page)
        if radio.isColor and page.text.color then
            return page.text.color
        elseif radio.isBW212 and page.text.bw212 then
            return page.text.bw212
        else
            return page.text.default
        end
    end

    local function handleEvent(event)
        local page = state.pages[state.currentIndex]

        if event == EVT_VIRTUAL_NEXT or event == EVT_PLUS_FIRST then
            if page.options then
                state.selection = math.min(#page.options, state.selection + 1)
            end
        elseif event == EVT_VIRTUAL_PREV or event == EVT_MINUS_FIRST then
            if page.options then
                state.selection = math.max(1, state.selection - 1)
            end
        elseif event == EVT_VIRTUAL_ENTER then
            if page.next then
                local nextPage, idx = findPage(page.next)
                if nextPage then
                    state.currentIndex = idx
                    state.selection = 1
                end
            end
        end
    end

    local function run(event)
        handleEvent(event)
        local page = state.pages[state.currentIndex]
        if not page then return end

        local text = chooseTextVariant(page)
        ui.renderPage(page, text, state, radio)
    end

    local function runWizard(pages)
        state.pages = pages
        return { run = run }
    end

    return {
        runWizard = runWizard
    }
end

return core_engine

