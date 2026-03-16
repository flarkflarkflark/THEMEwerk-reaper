-- lib/theme_ui.lua
-- Handles the user interface for the theme browser.

local M = {}

local state = require('lib.theme_state')
local actions = require('lib.theme_actions')

local app_title = 'THEMEwerk-reaper v0.1'
local font_size = 14
local line_height = 18
local win_w, win_h = 400, 600
local scroll_pos = 0
local selected_idx = 1
local search_text = ''
local filtered_themes = {}
local search_active = false

function M.filter_themes()
  local all_themes = state.get_state().themes
  filtered_themes = {}
  if search_text == '' then
    for _, theme in ipairs(all_themes) do
      table.insert(filtered_themes, theme)
    end
    return
  end
  
  for _, theme in ipairs(all_themes) do
    if theme:lower():find(search_text:lower(), 1, true) then
      table.insert(filtered_themes, theme)
    end
  end
  selected_idx = 1
  scroll_pos = 0
end

function M.update()
  local current_theme = state.get_state().current_theme
  
  gfx.clear = 0x1E1E1E -- Dark gray background
  
  -- Draw Title
  gfx.x, gfx.y = 10, 10
  gfx.printf(app_title)

  -- Draw Search Box
  gfx.y = 30
  gfx.x = 10
  gfx.set(0.5, 0.5, 0.5, 1) -- Gray box
  gfx.rect(10, gfx.y, win_w - 20, line_height)
  if search_active then
    gfx.set(1, 1, 0, 1) -- Yellow outline when active
    gfx.rect(9, gfx.y - 1, win_w - 18, line_height + 2, 0)
  end
  gfx.set(1, 1, 1, 1)
  gfx.x = 15
  gfx.y = gfx.y + 2
  local display_search = 'Search: ' .. search_text
  if search_active then
    display_search = display_search .. '_'
  end
  gfx.printf(display_search)
  
  -- Detect click in search box
  if gfx.mouse_evt == 1 and gfx.mouse_y > 30 and gfx.mouse_y < 30 + line_height then
    search_active = true
  elseif gfx.mouse_evt == 1 then
    search_active = false
  end

  -- Draw Themes
  gfx.y = 60
  for i, theme_name in ipairs(filtered_themes) do
    if i > scroll_pos and gfx.y < win_h - 20 then
      gfx.x = 10
      
      local display_str = theme_name
      if theme_name == current_theme then
        gfx.set(0.2, 1.0, 0.2, 1) -- Green for current theme
        display_str = '> ' .. display_str
      else
        gfx.set(1,1,1,1) -- White
      end
      
      if i == selected_idx then
        gfx.set(1,1,0,1) -- Yellow for selected
      end
      
      gfx.printf(display_str)
      
      -- Click detection
      if gfx.mouse_y > gfx.y and gfx.mouse_y < gfx.y + line_height and gfx.mouse_x > 10 and gfx.mouse_x < win_w - 10 then
        if gfx.mouse_evt == 1 then -- Left click
          selected_idx = i
          actions.apply_theme(theme_name)
          state.set_current_theme(theme_name)
          search_active = false
        end
      end
      
      gfx.y = gfx.y + line_height
    end
  end

  -- Scroll handling
  if gfx.mouse_wheel ~= 0 then
    scroll_pos = scroll_pos - (gfx.mouse_wheel * 3) -- scroll 3 items at a time
    if scroll_pos < 0 then scroll_pos = 0 end
    local max_scroll = #filtered_themes - math.floor((win_h - 80) / line_height)
    if max_scroll < 0 then max_scroll = 0 end
    if scroll_pos > max_scroll then scroll_pos = max_scroll end
  end

  local char = gfx.getchar()
  if char > 0 then
    if search_active then
      if char == 8 then -- backspace
        search_text = search_text:sub(1, -2)
        M.filter_themes()
      elseif char >= 32 and char <= 126 then -- printable ASCII
        search_text = search_text .. string.char(char)
        M.filter_themes()
      elseif char == 13 or char == 27 then -- enter or escape
        search_active = false
      end
    else -- not search active
      if char == 65362 then -- up arrow
        selected_idx = selected_idx - 1
        if selected_idx < 1 then selected_idx = 1 end
      elseif char == 65364 then -- down arrow
        selected_idx = selected_idx + 1
        if selected_idx > #filtered_themes then selected_idx = #filtered_themes end
      elseif char == 13 then -- enter
        if selected_idx > 0 and filtered_themes[selected_idx] then
          actions.apply_theme(filtered_themes[selected_idx])
          state.set_current_theme(filtered_themes[selected_idx])
        end
      elseif char == 47 then -- '/' key to activate search
        search_active = true
        search_text = ''
        M.filter_themes()
      end
    end
  end
  
  gfx.update()
end

function M.run()
  M.filter_themes() -- Initial population
  gfx.init(app_title, win_w, win_h, 0, function() M.update() end)
end

function M.quit()
  gfx.quit()
end

return M
