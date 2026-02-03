---- #########################################################################
---- #                                                                       #
---- # Copyright (C) OpenTX                                                  #
---- #                                                                       #
---- # License GPLv2: http://www.gnu.org/licenses/gpl-2.0.html               #
---- #                                                                       #
---- # This program is free software; you can redistribute it and/or modify  #
---- # it under the terms of the GNU General Public License version 2 as     #
---- # published by the Free Software Foundation.                            #
---- #                                                                       #
---- # This program is distributed in the hope that it will be useful        #
---- # but WITHOUT ANY WARRANTY; without even the implied warranty of        #
---- # MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         #
---- # GNU General Public License for more details.                          #
---- #                                                                       #
---- #########################################################################

-- Author: Airhamer / ErnestWorrel (2026)
-- core_engine.lua
-- Place in: <global>/TEMPLATES/1.Wizard/core/
-- Universal wizard for all radio types - uses core_engine and ui modules
-- Thin page manager - delegates event handling to each radio's UI module
-- Each UI module handles its own navigation style (field select, edit, page nav)

local function core_engine()
    
    local state = {
        currentIndex = 1,
        pages = nil,
        radio = nil,
        ui = nil
    }
    
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
    
    -- Page navigation helpers exposed to UI modules
    local nav = {}
    function nav.goNext()
        local page = state.pages[state.currentIndex]
        if page and page.next then
            for i, p in ipairs(state.pages) do
                if p.id == page.next then
                    state.currentIndex = i
                    if state.ui.resetPage then state.ui.resetPage() end
                    return true
                end
            end
        elseif state.currentIndex < #state.pages then
            state.currentIndex = state.currentIndex + 1
            if state.ui.resetPage then state.ui.resetPage() end
            return true
        end
        return false
    end
    
    function nav.goPrev()
        if state.currentIndex > 1 then
            state.currentIndex = state.currentIndex - 1
            if state.ui.resetPage then state.ui.resetPage() end
            return true
        end
        return false  -- Signal: we're at page 1, exit
    end
    
    function nav.currentPage()
        return state.pages[state.currentIndex]
    end
    
    local function run(event)
        local page = state.pages[state.currentIndex]
        if not page then return 0 end
        
        local text = chooseTextVariant(page)
        
        -- Let the UI module handle the event and rendering
        -- UI returns "exit" if user wants to leave the wizard entirely
        local result = state.ui.handlePage(page, text, state.radio, nav, event)
        if result == "exit" then
            return "exit"
        end
        
        return 0
    end
    
    local function runWizard(radio, ui, pages)
        state.radio = radio
        state.ui = ui
        state.pages = pages
        state.currentIndex = 1
        
        if ui.init then ui.init() end
        
        return { run = run }
    end
    
    return {
        runWizard = runWizard
    }
end

return core_engine
