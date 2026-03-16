-- lib/theme_state.lua
-- Manages the state of the theme browser, including persistence.

local M = {}

local EXT_STATE_SECTION = 'THEMEwerk-reaper'
local RECENTS_KEY = 'recents'
local FAVORITES_KEY = 'favorites'
local UI_SCALE_KEY = 'ui_scale'
local WIN_X_KEY = 'win_x'
local WIN_Y_KEY = 'win_y'
local WIN_W_KEY = 'win_w'
local WIN_H_KEY = 'win_h'
local MAX_RECENTS = 10

-- Holds the current state of the application
local state = {
  themes = {},          -- Full list of available theme objects
  current_theme = nil,  -- The name of the currently applied theme
  initial_theme = nil,  -- The name of the theme active before the script was run
  initial_paths = {},   -- Set of full_paths present at launch
  touched_paths = {},   -- Set of full_paths touched by user
  start_theme_obj = nil,-- The theme object that was START at launch
  previous_theme = nil, -- The name of the theme active before the last switch
  favorites = {},       -- List of favorite theme names
  recents = {},         -- List of recently used theme names
  ui_scale = 1.0,       -- Global UI scale factor
  win_x = -1,           -- Window X position (-1 for centered)
  win_y = -1,           -- Window Y position
  win_w = 400,          -- Window width
  win_h = 600,          -- Window height
}

local function table_to_string(tbl)
  local str = ''
  for i, v in ipairs(tbl) do
    str = str .. v
    if i < #tbl then
      str = str .. ','
    end
  end
  return str
end

local function string_to_table(str)
  local tbl = {}
  if not str or str == '' then return tbl end
  for match in (str .. ','):gmatch('(.-),') do
    table.insert(tbl, match)
  end
  return tbl
end

function M.save_state()
  local recents_str = table_to_string(state.recents)
  local favorites_str = table_to_string(state.favorites)
  reaper.SetExtState(EXT_STATE_SECTION, RECENTS_KEY, recents_str, true)
  reaper.SetExtState(EXT_STATE_SECTION, FAVORITES_KEY, favorites_str, true)
  reaper.SetExtState(EXT_STATE_SECTION, UI_SCALE_KEY, tostring(state.ui_scale), true)
  reaper.SetExtState(EXT_STATE_SECTION, WIN_X_KEY, tostring(state.win_x), true)
  reaper.SetExtState(EXT_STATE_SECTION, WIN_Y_KEY, tostring(state.win_y), true)
  reaper.SetExtState(EXT_STATE_SECTION, WIN_W_KEY, tostring(state.win_w), true)
  reaper.SetExtState(EXT_STATE_SECTION, WIN_H_KEY, tostring(state.win_h), true)
end

function M.load_state()
  local recents_str = reaper.GetExtState(EXT_STATE_SECTION, RECENTS_KEY)
  local favorites_str = reaper.GetExtState(EXT_STATE_SECTION, FAVORITES_KEY)
  local ui_scale_str = reaper.GetExtState(EXT_STATE_SECTION, UI_SCALE_KEY)
  local win_x_str = reaper.GetExtState(EXT_STATE_SECTION, WIN_X_KEY)
  local win_y_str = reaper.GetExtState(EXT_STATE_SECTION, WIN_Y_KEY)
  local win_w_str = reaper.GetExtState(EXT_STATE_SECTION, WIN_W_KEY)
  local win_h_str = reaper.GetExtState(EXT_STATE_SECTION, WIN_H_KEY)
  
  state.recents = string_to_table(recents_str)
  state.favorites = string_to_table(favorites_str)
  state.ui_scale = tonumber(ui_scale_str) or 1.0
  state.win_x = tonumber(win_x_str) or -1
  state.win_y = tonumber(win_y_str) or -1
  state.win_w = tonumber(win_w_str) or 400
  state.win_h = tonumber(win_h_str) or 600
end

function M.set_ui_scale(scale)
  state.ui_scale = math.max(0.5, math.min(4.0, scale))
end

function M.touch_theme(full_path)
  if not full_path then return end
  state.touched_paths[full_path] = true
end

function M.sync_themes(new_themes)
  local active_path = reaper.GetLastColorThemeFile():gsub('\\\\', '/')
  
  -- 1. Check if START theme still exists on disk
  local start_exists = false
  if state.start_theme_obj then
    for _, t in ipairs(new_themes) do
      if t.full_path == state.start_theme_obj.full_path then
        start_exists = true
        break
      end
    end
  end
  
  -- 2. Annotate all themes with status
  for _, t in ipairs(new_themes) do
    t.is_start = state.start_theme_obj and (t.full_path == state.start_theme_obj.full_path)
    t.is_active = (t.full_path == active_path)
    t.is_new = not state.initial_paths[t.full_path] and not state.touched_paths[t.full_path]
    t.is_missing = false
  end
  
  -- 3. If START theme is missing, inject it with is_missing = true
  if not start_exists and state.start_theme_obj then
    local missing_start = {}
    for k,v in pairs(state.start_theme_obj) do missing_start[k] = v end
    missing_start.is_missing = true
    missing_start.is_start = true
    missing_start.is_active = (missing_start.full_path == active_path)
    missing_start.is_new = false
    table.insert(new_themes, missing_start)
    table.sort(new_themes, function(a, b) 
      return a.display_name:lower() < b.display_name:lower() 
    end)
  end
  
  state.themes = new_themes
end

function M.set_window_geometry(x, y, w, h)
  state.win_x = x or -1
  state.win_y = y or -1
  state.win_w = math.max(300, w or 400)
  state.win_h = math.max(200, h or 600)
end

function M.add_to_recents(theme_name)
  if not theme_name then return end
  for i, v in ipairs(state.recents) do
    if v == theme_name then
      table.remove(state.recents, i)
      break
    end
  end
  table.insert(state.recents, 1, theme_name)
  if #state.recents > MAX_RECENTS then
    state.recents[MAX_RECENTS + 1] = nil
  end
end

-- Safely detects the current theme by reading reaper.ini
local function get_current_theme_from_ini()
  local ini_path = reaper.get_ini_file()
  local f = io.open(ini_path, 'r')
  if not f then return nil end
  
  local last_theme = nil
  for line in f:lines() do
    -- Trim whitespace and check for various theme keys
    local clean_line = line:gsub('^%s*(.-)%s*$', '%1')
    
    -- Matches: lasttheme=..., lasttheme_v6=..., etc. (case insensitive)
    local val = clean_line:match('^[Ll][Aa][Ss][Tt][Tt][Hh][Ee][Mm][Ee][^=]*=(.*)')
    if val then
      last_theme = val:gsub('^%s*(.-)%s*$', '%1') -- trim value
    end
  end
  f:close()
  
  if last_theme and last_theme ~= '' then
    -- Extract name from path
    last_theme = last_theme:gsub('\\\\', '/')
    local name = last_theme:match('([^/\\%?%*%\"]+)%.[Rr][Ee][Aa][Pp][Ee][Rr][Tt][Hh][Ee][Mm][Ee][Zz][Ii][Pp]$') or
                 last_theme:match('([^/\\%?%*%\"]+)%.[Rr][Ee][Aa][Pp][Ee][Rr][Tt][Hh][Ee][Mm][Ee]$') or
                 last_theme:match('([^/\\%?%*%\"]+)$')
    return name
  end
  return nil
end

-- Initializes the state.
-- @param themes (table) A list of theme objects from theme_data.
function M.init(themes)
  M.load_state()
  state.themes = themes or {}
  state.initial_paths = {}
  state.touched_paths = {}
  
  -- Track what was there at start
  for _, t in ipairs(state.themes) do
    state.initial_paths[t.full_path] = true
  end
  
  local active_path = reaper.GetLastColorThemeFile():gsub('\\\\', '/')
  for _, t in ipairs(state.themes) do
    if t.full_path == active_path then
       state.start_theme_obj = t
       state.initial_theme = t.base_name
       break
    end
  end
  
  -- Fallback if current theme not in ColorThemes (rare)
  if not state.start_theme_obj then
    local name = get_current_theme_from_ini()
    if name then
      state.initial_theme = name
      state.start_theme_obj = { base_name = name, display_name = name, full_path = active_path, is_missing = true }
    end
  end
  
  -- Initial sync to set status flags
  M.sync_themes(state.themes)
end

-- Returns the full state table.
function M.get_state()
  return state
end

-- Sets the current theme.
-- @param theme_name (string) The name of the theme to set as current.
-- @param full_path (string) The path of the theme to set as current.
function M.set_current_theme(theme_name, full_path)
  if not theme_name then return end
  if full_path then M.touch_theme(full_path) end
  if state.current_theme ~= theme_name then
    state.previous_theme = state.current_theme
    state.current_theme = theme_name
    M.add_to_recents(theme_name)
  end
end

-- Reverts to the initial theme (active when script started).
function M.revert_to_initial()
  if state.start_theme_obj then
    state.previous_theme = state.current_theme
    state.current_theme = state.start_theme_obj.base_name
    return state.start_theme_obj.full_path
  end
  return nil
end

return M


