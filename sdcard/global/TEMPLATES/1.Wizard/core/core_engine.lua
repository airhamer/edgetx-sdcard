-- core_engine.lua
-- Universal wizard engine for all radio types
local function core_engine()
    
    local state = {
        currentIndex = 1,
        pages = nil,
        radio = nil,
        ui = nil
    }
    
    local function findPage(id)
        for i, p in ipairs(state.pages) do
            if p.id == id then return p, i end
        end
        return nil
    end
    
    local function chooseTextVariant(page)
        local radio = state.radio
        if not page.text then return "" end
        
        if radio.isColor and page.text.color then
            return page.text.color
        elseif radio.isBW212 and page.text.bw212 then
            return page.text.bw212
        elseif radio.isBW128 and page.text.bw128 then
            return page.text.bw128
        else
            return page.text.default or page.text
        end
    end
    
    local function handleEvent(event)
        local page = state.pages[state.currentIndex]
        if not page then return end
        
        -- Handle navigation based on page type
        if page.options and page.getValue and page.setValue then
            -- Page with selectable options
            local maxVal = #page.options - 1  -- Options are 0-indexed
            
            if event == EVT_VIRTUAL_NEXT or event == EVT_PLUS_FIRST then
                local currentVal = page.getValue()
                if currentVal < maxVal then
                    page.setValue(currentVal + 1)
                end
            elseif event == EVT_VIRTUAL_PREV or event == EVT_MINUS_FIRST then
                local currentVal = page.getValue()
                if currentVal > 0 then
                    page.setValue(currentVal - 1)
                end
            elseif event == EVT_VIRTUAL_ENTER then
                -- Move to next page
                if page.next then
                    local nextPage, idx = findPage(page.next)
                    if nextPage then
                        state.currentIndex = idx
                    end
                elseif state.currentIndex < #state.pages then
                    state.currentIndex = state.currentIndex + 1
                end
            end
        elseif page.summary then
            -- Summary page - handle scrolling and ENTER
            if event == EVT_VIRTUAL_NEXT or event == EVT_PLUS_FIRST then
                state.summaryScroll = (state.summaryScroll or 0) + 1
            elseif event == EVT_VIRTUAL_PREV or event == EVT_MINUS_FIRST then
                state.summaryScroll = math.max(0, (state.summaryScroll or 0) - 1)
            elseif event == EVT_VIRTUAL_ENTER then
                -- Call onEnter callback if it exists
                if page.onEnter then
                    page.onEnter()
                end
                -- Move to next page
                if page.next then
                    local nextPage, idx = findPage(page.next)
                    if nextPage then
                        state.currentIndex = idx
                        state.summaryScroll = 0  -- Reset scroll for next time
                    end
                elseif state.currentIndex < #state.pages then
                    state.currentIndex = state.currentIndex + 1
                    state.summaryScroll = 0
                end
            end
        elseif page.isFinish then
            -- Finish page - EXIT exits the wizard
            if event == EVT_VIRTUAL_EXIT then
                return "exit"
            end
        else
            -- Simple page - ENTER advances
            if event == EVT_VIRTUAL_ENTER then
                if page.next then
                    local nextPage, idx = findPage(page.next)
                    if nextPage then
                        state.currentIndex = idx
                    end
                elseif state.currentIndex < #state.pages then
                    state.currentIndex = state.currentIndex + 1
                end
            end
        end
        
        -- Handle EXIT (go back)
        if event == EVT_VIRTUAL_EXIT then
            if state.currentIndex > 1 then
                state.currentIndex = state.currentIndex - 1
            else
                return "exit"
            end
        end
    end
    
    local function run(event)
        local result = handleEvent(event)
        if result == "exit" then
            return "exit"
        end
        
        local page = state.pages[state.currentIndex]
        if not page then return 0 end
        
        local text = chooseTextVariant(page)
        
        -- Call the UI render function
        state.ui.renderPage(page, text, state, state.radio)
        
        return 0
    end
    
    local function runWizard(radio, ui, pages)
        state.radio = radio
        state.ui = ui
        state.pages = pages
        state.currentIndex = 1
        
        return { run = run }
    end
    
    return {
        runWizard = runWizard
    }
end

return core_engine
