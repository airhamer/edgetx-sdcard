-- ui_bw128.lua
-- Simple BW128 UI module - works with both simple calls and core_engine
local ui = {}

function ui.renderPage(pageOrTitle, textOrLines, state, radio)
  lcd.clear()
  
  -- Handle two calling patterns:
  -- 1. Old simple: renderPage(title, lines, state)
  -- 2. New core_engine: renderPage(page, text, state, radio)
  
  local title, lines
  
  if type(pageOrTitle) == "table" and pageOrTitle.title then
    -- New core_engine format: pageOrTitle is a page object
    local page = pageOrTitle
    title = page.title or "Wizard"
    
    -- textOrLines is actually the text string for this page
    local text = textOrLines or ""
    
    -- Build lines from page data
    lines = {}
    
    if page.options then
      -- Selection page - show options with scrolling
      local currentVal = page.getValue and page.getValue() or 0
      local visibleLines = 4  -- Max visible options on BW128
      local scroll = 0
      
      -- Calculate scroll offset to keep selection visible
      if currentVal >= visibleLines then
        scroll = currentVal - visibleLines + 1
      end
      
      -- Show text header if not too many options
      if #page.options <= 5 then
        lines[1] = text
      end
      
      -- Show visible options
      for i = scroll + 1, math.min(#page.options, scroll + visibleLines) do
        local selected = (i - 1 == currentVal)
        lines[#lines + 1] = (selected and "> " or "  ") .. page.options[i]
      end
      
      -- Show scroll indicator if needed
      if #page.options > visibleLines then
        lines[#lines + 1] = string.format("(%d/%d)", currentVal + 1, #page.options)
      end
      
    elseif page.summary then
      -- Summary page - show key-value pairs with scrolling
      local maxLines = 4  -- Max visible lines on BW128
      local scroll = state.summaryScroll or 0
      
      -- Build all summary lines first
      local allLines = {}
      for i, item in ipairs(page.summary) do
        local value = item.getValue()
        allLines[#allLines + 1] = item.label .. ": " .. value
      end
      allLines[#allLines + 1] = ""
      allLines[#allLines + 1] = text
      
      -- Calculate scroll limits
      local maxScroll = math.max(0, #allLines - maxLines)
      if scroll > maxScroll then scroll = maxScroll end
      if scroll < 0 then scroll = 0 end
      state.summaryScroll = scroll
      
      -- Show visible lines
      for i = scroll + 1, math.min(#allLines, scroll + maxLines) do
        lines[#lines + 1] = allLines[i]
      end
      
      -- Show scroll indicator if needed
      if #allLines > maxLines then
        lines[#lines + 1] = string.format("(%d/%d)", scroll + 1, #allLines)
      end
      
    else
      -- Simple text page
      lines[1] = text
    end
  else
    -- Old simple format: renderPage(title, lines, state)
    title = pageOrTitle
    lines = textOrLines
  end
  
  -- Draw title
  lcd.drawText(2, 2, title, SMLSIZE)
  
  -- Draw lines
  local y = 14
  for i, line in ipairs(lines) do
    local flags = SMLSIZE
    -- Only apply highlight if using old format with state.highlight
    if state and state.highlight and state.highlight == i then
      flags = flags + INVERS
    end
    lcd.drawText(4, y, line, flags)
    y = y + 10
    if y > LCD_H - 10 then break end  -- Stop if we run out of room
  end
end

return ui
