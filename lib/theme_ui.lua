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
local selected_idx = -1

function M.update()
  local themes = state.get_state().themes
  local current_theme = state.get_state().current_theme
  
  gfx.clear = 0x1E1E1E -- Dark gray background
  
  -- Draw Title
  gfx.x, gfx.y = 10, 10
  gfx.printf(app_title)

  -- Draw Themes
  gfx.y = 40
  for i, theme_name in ipairs(themes) do
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
        selected_idx = i
        if gfx.mouse_evt == 1 then -- Left click
          actions.apply_theme(theme_name)
          state.set_current_theme(theme_name)
        end
      end
      
      gfx.y = gfx.y + line_height
    end
  end

  -- Scroll handling
  if gfx.mouse_wheel ~= 0 then
    scroll_pos = scroll_pos - gfx.mouse_wheel
    if scroll_pos < 0 then scroll_pos = 0 end
    local max_scroll = #themes - math.floor((win_h - 60) / line_height)
    if scroll_pos > max_scroll then scroll_pos = max_scroll end
  end

  local char = gfx.getchar()
  if char > 0 then
    if char == 65362 then -- up arrow
      selected_idx = selected_idx - 1
      if selected_idx < 1 then selected_idx = 1 end
    elseif char == 65364 then -- down arrow
      selected_idx = selected_idx + 1
      if selected_idx > #themes then selected_idx = #themes end
    elseif char == 13 then -- enter
      if selected_idx > 0 then
        actions.apply_theme(themes[selected_idx])
        state.set_current_theme(themes[selected_idx])
      end
    end
  end
  
  gfx.update()
end

function M.run()
  gfx.init(app_title, win_w, win_h, 0, function() M.update() end)
end

function M.quit()
  gfx.quit()
end

return M
