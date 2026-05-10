-- lib/theme_ui.lua
-- @noindex
-- Handles the user interface for the theme browser.

local M = {}

local state = require('theme_state')
local actions = require('theme_actions')

local function detect_script_version()
  local src = debug.getinfo(1, 'S').source or ''
  local this_file = src:match('^@(.+)$')
  if not this_file then return nil end

  local sep = package.config:sub(1, 1)
  local lib_dir = this_file:match('^(.*' .. sep .. ')')
  if not lib_dir then return nil end
  local script_path = lib_dir .. '..' .. sep .. 'THEMEwerk.lua'

  local f = io.open(script_path, 'r')
  if not f then return nil end
  local chunk = f:read('*a') or ''
  f:close()

  return chunk:match('%-%-%s*@version%s+([%w%._%-]+)')
end

local app_title = 'THEMEwerk-reaper'
local detected_version = detect_script_version()
if detected_version then
  app_title = app_title .. ' v' .. detected_version
end

-- Base metrics (unscaled)
local BASE_FONT_SIZE = 14
local BASE_LINE_HEIGHT = 22
local BASE_PADDING = 10
local BASE_MARGIN = 5
local BASE_SEARCH_HEIGHT = 28
local BASE_FOOTER_HEIGHT = 24
local MIN_WIN_W = 300
local MIN_WIN_H = 250

-- Current session state
local win_w, win_h = 400, 600
local scroll_pos = 0
local scroll_center_pending = false
local selected_idx = 1
local search_text = ''
local filtered_themes = {}
local search_active = false
local last_mouse_state = 0
local last_click_time = 0
local last_refresh_time = 0
local selected_theme_path = ""

-- UI Colors
local COLOR_THEME_ACCENT = {0.9, 0.6, 0, 1}     -- Gold-yellow
local COLOR_INITIAL_THEME = {0.2, 0.9, 0.2, 1} -- REAPER Initial Green
local COLOR_NEW_ORANGE = {1, 0.5, 0, 1}        -- New theme orange
local COLOR_ACTIVE_BLUE = {0.4, 0.7, 1, 1}     -- Active theme blue
local COLOR_TEXT_DIM = {0.6, 0.6, 0.6, 1}
local COLOR_TEXT_META = {0.7, 0.7, 0.7, 1}
local COLOR_WHITE = {1, 1, 1, 1}
local COLOR_BG = {0.12, 0.12, 0.12, 1}
local COLOR_SELECTED_BG = {0.3, 0.3, 0.3, 1}
local COLOR_SEARCH_BG = {0.25, 0.25, 0.25, 1}
local COLOR_PANEL_BG = {0.1, 0.1, 0.1, 1}

local function read_gfx_window_geometry()
  local x, y, w, h, docked
  local ok, d, gx, gy, gw, gh = pcall(gfx.dock, -1, 0, 0, 0, 0)
  if ok and type(gw) == 'number' and type(gh) == 'number' and gw > 0 and gh > 0 then
    docked = d or 0
    x, y, w, h = gx, gy, gw, gh
  else
    local s = state.get_state()
    docked = s.win_docked or 0
    x, y, w, h = s.win_x, s.win_y, gfx.w, gfx.h
  end
  return x, y, w, h, docked
end

local function persist_window_geometry()
  local x, y, w, h, docked = read_gfx_window_geometry()
  state.set_window_geometry(x, y, w, h, docked)
  state.save_state()
end

-- Helper to apply selected theme immediately
local function apply_selected()
  local theme = filtered_themes[selected_idx]
  if theme then
    selected_theme_path = theme.full_path
    if actions.apply_theme(theme.full_path) then
      state.set_current_theme(theme.display_name, theme.full_path)
    end
  end
end

-- Helper to scale values based on current global UI scale
local function scaled(v)
  local s = state.get_state()
  return math.floor(v * (s.ui_scale or 1.0))
end

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
      if theme.display_name:lower():find(search_lower, 1, true) then
        table.insert(filtered_themes, theme)
      end
    end
  end
  
  -- Restore selection by full_path first, then base_name fallback
  if selected_theme_path ~= "" then
    local found = false
    -- Pass 1: exact path
    for i, t in ipairs(filtered_themes) do
      if t.full_path == selected_theme_path then
        selected_idx = i
        found = true
        break
      end
    end
    -- Pass 2: base_name fallback if path moved/renamed but still in filter
    if not found then
      local base = selected_theme_path:match("([^/]+)%.[Rr][Ee][Aa][Pp][Ee][Rr][Tt][Hh][Ee][Mm][Ee][Zz][Ii][Pp]$") or
                   selected_theme_path:match("([^/]+)%.[Rr][Ee][Aa][Pp][Ee][Rr][Tt][Hh][Ee][Mm][Ee]$") or
                   selected_theme_path:match("([^/]+)$")
      for i, t in ipairs(filtered_themes) do
        if t.base_name == base then
          selected_idx = i
          found = true
          break
        end
      end
    end
    if not found then selected_idx = 1 end
  end

  if #filtered_themes > 0 then
    if selected_idx > #filtered_themes then selected_idx = #filtered_themes end
    if selected_idx < 1 then selected_idx = 1 end
    selected_theme_path = filtered_themes[selected_idx].full_path
  else
    selected_idx = 0
    selected_theme_path = ""
  end
end

local function update_fonts()
  local s = state.get_state()
  local font_size = scaled(BASE_FONT_SIZE)
  gfx.setfont(1, 'Arial', font_size)
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
  local initial_theme = s.initial_theme
  local ui_scale = s.ui_scale or 1.0
  
  -- 0. Window Safety & Live Refresh
  if gfx.w < MIN_WIN_W or gfx.h < MIN_WIN_H then end
  
  local now = reaper.time_precise()
  if now - last_refresh_time > 2.0 then
    last_refresh_time = now
    local data = require('theme_data')
    local themes = data.scan_for_themes(data.get_theme_dir())
    state.sync_themes(themes)
    M.filter_themes()
    
    -- Re-clamp selection
    if #filtered_themes > 0 then
      if selected_idx > #filtered_themes then selected_idx = #filtered_themes end
      if selected_idx < 1 then selected_idx = 1 end
      selected_theme_path = filtered_themes[selected_idx].full_path
    else
      selected_idx = 0
      selected_theme_path = ""
    end
  end
  
  -- Responsive metrics
  local line_h = scaled(BASE_LINE_HEIGHT)
  local pad = scaled(BASE_PADDING)
  local margin = scaled(BASE_MARGIN)
  local search_h = scaled(BASE_SEARCH_HEIGHT)
  local footer_h = scaled(BASE_FOOTER_HEIGHT)
  local font_sz = scaled(BASE_FONT_SIZE)
  
  -- Clear background
  gfx.set(COLOR_BG[1], COLOR_BG[2], COLOR_BG[3], 1)
  gfx.rect(0, 0, gfx.w, gfx.h, 1)
  
  -- 1. Draw Header (Search only)
  update_fonts()
  local search_y = pad
  gfx.set(COLOR_SEARCH_BG[1], COLOR_SEARCH_BG[2], COLOR_SEARCH_BG[3], 1)
  gfx.rect(pad, search_y, gfx.w - pad * 2, search_h, 1)
  
  if search_active then
    gfx.set(COLOR_THEME_ACCENT[1], COLOR_THEME_ACCENT[2], COLOR_THEME_ACCENT[3], 1)
    gfx.rect(pad - 1, search_y - 1, gfx.w - pad * 2 + 2, search_h + 2, 0)
  end
  
  local display_search = 'Search: ' .. search_text
  if search_active and (math.floor(os.clock() * 2) % 2 == 0) then
    display_search = display_search .. '|'
  end
  draw_text(pad + margin, search_y + (search_h - font_sz) / 2, display_search)
  
  if gfx.mouse_cap & 1 == 1 and last_mouse_state & 1 == 0 then
    if gfx.mouse_y >= search_y and gfx.mouse_y <= search_y + search_h then
      search_active = true
    else
      search_active = false
    end
  end

  -- 2. Layout Calculations
  local footer_y = gfx.h - footer_h
  local info_bar_h = line_h + margin * 2
  local list_y_start = search_y + search_h + margin
  local list_h = footer_y - list_y_start - info_bar_h - margin
  local sb_w = scaled(6)
  local list_w = gfx.w - pad * 2 - sb_w - margin
  local max_items = math.floor(list_h / line_h)

  if scroll_center_pending and max_items > 0 and selected_idx > 0 then
    scroll_center_pending = false
    scroll_pos = math.max(0, selected_idx - math.floor(max_items / 2) - 1)
    local max_scroll = math.max(0, #filtered_themes - max_items)
    if scroll_pos > max_scroll then scroll_pos = max_scroll end
  end

  -- 3. Draw Theme List
  for i = 1, max_items do
    local idx = i + scroll_pos
    if idx > #filtered_themes then break end
    
    local theme = filtered_themes[idx]
    local item_y = list_y_start + (i-1) * line_h
    
    if idx == selected_idx then
      gfx.set(COLOR_SELECTED_BG[1], COLOR_SELECTED_BG[2], COLOR_SELECTED_BG[3], 1)
      gfx.rect(pad, item_y, list_w, line_h, 1)
    end
    
    local color = COLOR_WHITE
    local prefix = '  '
    if theme.is_active then
      prefix = '> '
    end
    
    if theme.is_missing then
      color = {0.8, 0.2, 0.2, 1} -- Missing is Red
    elseif theme.is_start then
      color = COLOR_INITIAL_THEME
    elseif theme.is_new then
      color = COLOR_NEW_ORANGE
    elseif theme.is_active then
      color = COLOR_ACTIVE_BLUE
    elseif idx == selected_idx then
      color = {1, 1, 0, 1}
    end
    
    draw_text(pad + margin, item_y + (line_h - font_sz) / 2, prefix .. theme.display_name, color)
    
    -- Markers & Status (Right-aligned)
    local status_markers = {}
    if theme.is_missing then table.insert(status_markers, "[MISSING]") end
    if theme.is_start then table.insert(status_markers, "START") end
    if theme.is_active then table.insert(status_markers, "ACTIVE") end
    if theme.is_new then table.insert(status_markers, "NEW") end
    
    local type_marker = theme.type == "themezip" and "[ZIP]" or (theme.has_resource_dir and "[FILE+RES]" or "[FILE]")
    table.insert(status_markers, type_marker)
    
    local combined_marker = table.concat(status_markers, " ")
    local marker_w, _ = gfx.measurestr(combined_marker)
    local marker_x = pad + list_w - marker_w - margin
    if marker_x > pad + margin + scaled(80) then
      local m_color = theme.is_new and COLOR_NEW_ORANGE or COLOR_TEXT_DIM
      if theme.is_active then m_color = COLOR_ACTIVE_BLUE end
      if theme.is_start then m_color = COLOR_INITIAL_THEME end
      if theme.is_missing then m_color = {0.8, 0.2, 0.2, 1} end
      draw_text(marker_x, item_y + (line_h - font_sz) / 2, combined_marker, m_color)
    end
    
    -- Mouse interaction
    if gfx.mouse_cap & 1 == 1 and last_mouse_state & 1 == 0 then
      if gfx.mouse_x >= pad and gfx.mouse_x < pad + list_w and
         gfx.mouse_y >= item_y and gfx.mouse_y < item_y + line_h then
        selected_idx = idx
        selected_theme_path = theme.full_path
        state.touch_theme(theme.full_path)
        apply_selected()
      end
    end
  end

  -- Draw Scrollbar
  if #filtered_themes > max_items then
    local sb_x = gfx.w - pad - sb_w
    local sb_h = list_h
    local handle_h = math.max(scaled(20), sb_h * (max_items / #filtered_themes))
    local handle_y = list_y_start + (sb_h - handle_h) * (scroll_pos / (#filtered_themes - max_items))
    
    gfx.set(0.2, 0.2, 0.2, 1)
    gfx.rect(sb_x, list_y_start, sb_w, sb_h, 1)
    gfx.set(0.4, 0.4, 0.4, 1)
    gfx.rect(sb_x, handle_y, sb_w, handle_h, 1)
  end

  -- 4. Compact Info Bar (Always visible)
  local selected_theme = filtered_themes[selected_idx]
  if selected_theme then
    selected_theme_path = selected_theme.full_path
    state.touch_theme(selected_theme.full_path)
    local info_y = footer_y - info_bar_h
    gfx.set(0.1, 0.1, 0.1, 1)
    gfx.rect(pad, info_y, gfx.w - pad * 2, info_bar_h, 1)
    
    local meta_status = {}
    if selected_theme.is_start then table.insert(meta_status, "[START]") end
    if selected_theme.is_active then table.insert(meta_status, "[ACTIVE]") end
    if selected_theme.is_new then table.insert(meta_status, "[NEW]") end
    if selected_theme.is_missing then table.insert(meta_status, "[MISSING]") end
    
    local info_text = string.format("%s %s (%s)", table.concat(meta_status, ""), selected_theme.display_name, selected_theme.file_name)
    local it_w, _ = gfx.measurestr(info_text)
    draw_text(gfx.w/2 - it_w/2, info_y + (info_bar_h - font_sz)/2, info_text, COLOR_TEXT_META)
  end

  -- 5. Footer
  gfx.set(0.15, 0.15, 0.15, 1)
  gfx.rect(0, footer_y, gfx.w, footer_h, 1)
  gfx.set(0.3, 0.3, 0.3, 1)
  gfx.line(0, footer_y, gfx.w, footer_y)
  
  local footer_font_sz = (gfx.w < 400) and math.max(10, font_sz - 2) or font_sz
  
  -- Left: Branding
  local brand_text = "flarkAUDIO"
  local bw, _ = gfx.measurestr(brand_text)
  draw_text(pad, footer_y + (footer_h - footer_font_sz)/2, brand_text, COLOR_THEME_ACCENT)
  
  -- Tooltip: Branding
  if gfx.mouse_x >= pad and gfx.mouse_x <= pad + bw and
     gfx.mouse_y >= footer_y and gfx.mouse_y <= footer_y + footer_h then
    local tt_text = "for REAPER by flarkAUDIO"
    local ttw, tth = gfx.measurestr(tt_text)
    local ttx, tty = gfx.mouse_x, footer_y - tth - pad
    gfx.set(0, 0, 0, 0.9)
    gfx.rect(ttx, tty, ttw + pad, tth + pad, 1)
    draw_text(ttx + pad/2, tty + pad/2, tt_text, COLOR_WHITE)
  end
  
  local revert_text = "[R] Revert"
  local rw, _ = gfx.measurestr(revert_text)
  local rx = gfx.w - rw - pad
  draw_text(rx, footer_y + (footer_h - footer_font_sz)/2, revert_text, COLOR_INITIAL_THEME)
  
  -- Tooltip: Revert
  if gfx.mouse_x >= rx and gfx.mouse_x <= rx + rw and
     gfx.mouse_y >= footer_y and gfx.mouse_y <= footer_y + footer_h then
    local tt_text = "Revert to the theme active when THEMEwerk opened.\nMay fail if file is missing."
    local ttw, tth = gfx.measurestr(tt_text)
    local ttx, tty = gfx.w - ttw - pad, footer_y - tth - pad
    gfx.set(0, 0, 0, 0.9)
    gfx.rect(ttx, tty, ttw + pad, tth + pad, 1)
    draw_text(ttx + pad/2, tty + pad/2, tt_text, COLOR_WHITE)
  end

  -- Center status
  local status_text = string.format("%d themes shown • UI %d%%", #filtered_themes, math.floor(ui_scale * 100))
  local sw, _ = gfx.measurestr(status_text)
  local sx = gfx.w/2 - sw/2
  if pad + bw + pad < sx and sx + sw + pad < rx then
     draw_text(sx, footer_y + (footer_h - footer_font_sz)/2, status_text, COLOR_TEXT_DIM)
     
     -- Tooltip: Info / Shortcuts
     if gfx.mouse_x >= sx and gfx.mouse_x <= sx + sw and
        gfx.mouse_y >= footer_y and gfx.mouse_y <= footer_y + footer_h then
       local tt_text = "Actions:\n" ..
                       "• Click / Arrows: Apply theme\n" ..
                       "• PageUp / Down: Jump list\n" ..
                       "• Home / End: First / Last\n" ..
                       "• Mouse wheel: Scroll list\n" ..
                       "• + / - / 0: UI Scale"
       local ttw, tth = gfx.measurestr(tt_text)
       local ttx, tty = gfx.w/2 - ttw/2, footer_y - tth - pad
       gfx.set(0, 0, 0, 0.9)
       gfx.rect(ttx, tty, ttw + pad, tth + pad, 1)
       draw_text(ttx + pad/2, tty + pad/2, tt_text, COLOR_WHITE)
     end
  end

  -- Mouse Wheel
  if gfx.mouse_wheel ~= 0 then
    local dir = gfx.mouse_wheel > 0 and -1 or 1
    scroll_pos = scroll_pos + (dir * 3)
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
      if char == 30064 or char == 6579540 then -- up arrow
        selected_idx = selected_idx - 1
        if selected_idx < 1 then selected_idx = 1 end
        if selected_idx <= scroll_pos then scroll_pos = selected_idx - 1 end
        local theme = filtered_themes[selected_idx]
        if theme then state.touch_theme(theme.full_path) end
        apply_selected()
      elseif char == 1685026670 or char == 6619130 then -- down arrow
        selected_idx = selected_idx + 1
        if selected_idx > #filtered_themes then selected_idx = #filtered_themes end
        if selected_idx > scroll_pos + max_items then scroll_pos = selected_idx - max_items end
        local theme = filtered_themes[selected_idx]
        if theme then state.touch_theme(theme.full_path) end
        apply_selected()
      elseif char == 1885828464 or char == 1768842866 then -- page up
        selected_idx = math.max(1, selected_idx - max_items)
        scroll_pos = math.max(0, scroll_pos - max_items)
        local theme = filtered_themes[selected_idx]
        if theme then state.touch_theme(theme.full_path) end
        apply_selected()
      elseif char == 1885824110 or char == 1718584692 then -- page down
        selected_idx = math.min(#filtered_themes, selected_idx + max_items)
        scroll_pos = math.min(math.max(0, #filtered_themes - max_items), scroll_pos + max_items)
        local theme = filtered_themes[selected_idx]
        if theme then state.touch_theme(theme.full_path) end
        apply_selected()
      elseif char == 1752132965 or char == 1752132965 then -- home
        selected_idx = 1
        scroll_pos = 0
        local theme = filtered_themes[selected_idx]
        if theme then state.touch_theme(theme.full_path) end
        apply_selected()
      elseif char == 6647396 or char == 6647396 then -- end
        selected_idx = #filtered_themes
        scroll_pos = math.max(0, #filtered_themes - max_items)
        local theme = filtered_themes[selected_idx]
        if theme then state.touch_theme(theme.full_path) end
        apply_selected()
      elseif char == 13 then -- enter
        local theme = filtered_themes[selected_idx]
        if theme then state.touch_theme(theme.full_path) end
        apply_selected()
      elseif char == 26161 then -- '/' key
        search_active = true
        search_text = ''
        M.filter_themes()
      elseif char == 114 or char == 82 then -- 'r' or 'R' key
        local init_theme_path = state.revert_to_initial()
        if init_theme_path then
          actions.apply_theme(init_theme_path)
          -- Note: state.revert_to_initial already updated state.current_theme
        end
      elseif char == 61 or char == 43 then -- '=' or '+' key
        state.set_ui_scale(ui_scale + 0.1)
        update_fonts()
      elseif char == 45 then -- '-' key
        state.set_ui_scale(ui_scale - 0.1)
        update_fonts()
      elseif char == 48 then -- '0' key
        state.set_ui_scale(1.0)
        update_fonts()
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
  state.load_state()
  local s0 = state.get_state()
  if s0.start_theme_obj and s0.start_theme_obj.full_path then
    selected_theme_path = s0.start_theme_obj.full_path
  end
  M.filter_themes()
  
  local x, y, w, h, docked = state.get_window_geometry()
  w, h = math.max(MIN_WIN_W, w), math.max(MIN_WIN_H, h)
  if x < 0 or y < 0 then x, y = -1, -1 end
  gfx.init(app_title, w, h, docked or 0, x, y)
  update_fonts()
  scroll_center_pending = true
  local last_geom_sync_time = 0
  
  local function loop()
    local now = reaper.time_precise()
    if now - last_geom_sync_time > 0.5 then
      local gx, gy, gw, gh, gd = read_gfx_window_geometry()
      if gx ~= x or gy ~= y or gw ~= w or gh ~= h or gd ~= docked then
        state.set_window_geometry(gx, gy, gw, gh, gd)
        x, y, w, h, docked = gx, gy, gw, gh, gd
      end
      last_geom_sync_time = now
    end

    if M.draw() then
      reaper.defer(loop)
    else
      persist_window_geometry()
      gfx.quit()
    end
  end
  
  reaper.defer(loop)
end

function M.quit()
  persist_window_geometry()
  gfx.quit()
end

return M



