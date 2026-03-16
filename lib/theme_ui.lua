-- lib/theme_ui.lua
-- Handles the user interface for the theme browser.

local M = {}

local state = require('theme_state')
local actions = require('theme_actions')

local app_title = 'THEMEwerk-reaper v0.1'
local font_size = 14
local line_height = 20
local win_w, win_h = 400, 600
local scroll_pos = 0
local selected_idx = 1
local search_text = ''
local filtered_themes = {}
local search_active = false
local last_mouse_state = 0

function M.filter_themes()
  local s = state.get_state()
  local all_themes = s.themes
  filtered_themes = {}
  if search_text == '' then
    for _, theme in ipairs(all_themes) do
      table.insert(filtered_themes, theme)
    end
  else
    local search_lower = search_text:lower()
    for _, theme in ipairs(all_themes) do
      if theme:lower():find(search_lower, 1, true) then
        table.insert(filtered_themes, theme)
      end
    end
  end
  
  if #filtered_themes > 0 then
    if selected_idx > #filtered_themes then selected_idx = #filtered_themes end
    if selected_idx < 1 then selected_idx = 1 end
  else
    selected_idx = 0
  end
end

local function draw_text(x, y, text, color)
  if color then
    gfx.set(color[1], color[2], color[3], color[4] or 1)
  else
    gfx.set(1, 1, 1, 1)
  end
  gfx.x, gfx.y = x, y
  gfx.drawstr(text)
end

function M.draw()
  local s = state.get_state()
  local current_theme = s.current_theme
  
  -- Clear background
  gfx.set(0.12, 0.12, 0.12, 1) -- #1E1E1E
  gfx.rect(0, 0, gfx.w, gfx.h, 1)
  
  -- Draw Title
  draw_text(10, 10, app_title, {0.9, 0.6, 0, 1})
  draw_text(gfx.w - 100, 10, "[R] Revert", {0.6, 0.6, 0.6, 1})

  -- Draw Search Box
  local search_y = 35
  gfx.set(0.25, 0.25, 0.25, 1)
  gfx.rect(10, search_y, gfx.w - 20, line_height, 1)
  
  if search_active then
    gfx.set(0.9, 0.6, 0, 1)
    gfx.rect(9, search_y - 1, gfx.w - 18, line_height + 2, 0)
  end
  
  local display_search = 'Search: ' .. search_text
  if search_active and (math.floor(os.clock() * 2) % 2 == 0) then
    display_search = display_search .. '|'
  end
  draw_text(15, search_y + 2, display_search)
  
  if gfx.mouse_cap & 1 == 1 and last_mouse_state & 1 == 0 then
    if gfx.mouse_y >= search_y and gfx.mouse_y <= search_y + line_height then
      search_active = true
    else
      search_active = false
    end
  end

  local list_y_start = 65
  local list_h = gfx.h - list_y_start - 10
  local max_items = math.floor(list_h / line_height)
  
  for i = 1, max_items do
    local idx = i + scroll_pos
    if idx > #filtered_themes then break end
    
    local theme_name = filtered_themes[idx]
    local item_y = list_y_start + (i-1) * line_height
    
    if idx == selected_idx then
      gfx.set(0.3, 0.3, 0.3, 1)
      gfx.rect(10, item_y, gfx.w - 20, line_height, 1)
    end
    
    local color = {1, 1, 1, 1}
    local prefix = '  '
    if theme_name == current_theme then
      color = {0.2, 0.9, 0.2, 1}
      prefix = '> '
    end
    
    if idx == selected_idx then
      color = {1, 1, 0, 1}
    end
    
    draw_text(15, item_y + 2, prefix .. theme_name, color)
    
    if gfx.mouse_cap & 1 == 1 and last_mouse_state & 1 == 0 then
      if gfx.mouse_y >= item_y and gfx.mouse_y < item_y + line_height then
        selected_idx = idx
        if actions.apply_theme(theme_name) then
           state.set_current_theme(theme_name)
        end
      end
    end
  end

  if gfx.mouse_wheel ~= 0 then
    local dir = gfx.mouse_wheel > 0 and -3 or 3
    scroll_pos = scroll_pos + dir
    gfx.mouse_wheel = 0
    if scroll_pos < 0 then scroll_pos = 0 end
    local max_scroll = #filtered_themes - max_items
    if max_scroll < 0 then max_scroll = 0 end
    if scroll_pos > max_scroll then scroll_pos = max_scroll end
  end

  local char = gfx.getchar()
  if char > 0 then
    if search_active then
      if char == 8 then -- backspace
        search_text = search_text:sub(1, -2)
        M.filter_themes()
      elseif char == 13 or char == 27 then -- enter or escape
        search_active = false
      elseif char >= 32 and char <= 126 then -- printable ASCII
        search_text = search_text .. string.char(char)
        M.filter_themes()
      end
    else
      if char == 30064 then -- up arrow
        selected_idx = selected_idx - 1
        if selected_idx < 1 then selected_idx = 1 end
        if selected_idx <= scroll_pos then scroll_pos = selected_idx - 1 end
      elseif char == 1685026670 then -- down arrow
        selected_idx = selected_idx + 1
        if selected_idx > #filtered_themes then selected_idx = #filtered_themes end
        if selected_idx > scroll_pos + max_items then scroll_pos = selected_idx - max_items end
      elseif char == 13 then -- enter
        if selected_idx > 0 and filtered_themes[selected_idx] then
          if actions.apply_theme(filtered_themes[selected_idx]) then
            state.set_current_theme(filtered_themes[selected_idx])
          end
        end
      elseif char == 26161 then -- '/' key
        search_active = true
        search_text = ''
        M.filter_themes()
      elseif char == 114 or char == 82 then -- 'r' or 'R' key
        local init_theme = state.revert_to_initial()
        if init_theme then
          actions.apply_theme(init_theme)
        end
      elseif char == 27 then -- escape
        return false
      end
    end
  end
  
  if char == -1 then return false end -- Window closed

  last_mouse_state = gfx.mouse_cap
  gfx.update()
  return true
end

function M.run()
  M.filter_themes()
  gfx.init(app_title, win_w, win_h)
  gfx.setfont(1, 'Arial', font_size)
  
  local function loop()
    if M.draw() then
      reaper.defer(loop)
    else
      gfx.quit()
    end
  end
  
  reaper.defer(loop)
end

function M.quit()
  gfx.quit()
end

return M


