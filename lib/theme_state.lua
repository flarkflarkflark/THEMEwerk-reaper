-- lib/theme_state.lua
-- Manages the state of the theme browser, including persistence.

local M = {}

local EXT_STATE_SECTION = 'THEMEwerk-reaper'
local RECENTS_KEY = 'recents'
local FAVORITES_KEY = 'favorites'
local MAX_RECENTS = 10

-- Holds the current state of the application
local state = {
  themes = {},          -- Full list of available theme names
  current_theme = nil,  -- The name of the currently applied theme
  initial_theme = nil,  -- The name of the theme active before the script was run
  previous_theme = nil, -- The name of the theme active before the last switch
  favorites = {},       -- List of favorite theme names
  recents = {},         -- List of recently used theme names
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
end

function M.load_state()
  local recents_str = reaper.GetExtState(EXT_STATE_SECTION, RECENTS_KEY)
  local favorites_str = reaper.GetExtState(EXT_STATE_SECTION, FAVORITES_KEY)
  state.recents = string_to_table(recents_str)
  state.favorites = string_to_table(favorites_str)
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
    local name = last_theme:match('([^/]+)%.[Rr][Ee][Aa][Pp][Ee][Rr][Tt][Hh][Ee][Mm][Ee]') or 
                 last_theme:match('([^/]+)%.[Rr][Ee][Aa][Pp][Ee][Rr][Tt][Hh][Ee][Mm][Ee][Zz][Ii][Pp]') or
                 last_theme:match('([^/]+)$')
    return name
  end
  return nil
end

-- Initializes the state.
-- @param themes (table) A list of theme names from theme_data.
function M.init(themes)
  M.load_state()
  state.themes = themes or {}
  
  local theme_name = get_current_theme_from_ini()
  if theme_name then
    state.current_theme = theme_name
    state.initial_theme = theme_name
  else
    reaper.ShowConsoleMsg('THEMEwerk: Could not determine the currently active theme from reaper.ini\\n')
  end
end

-- Returns the full state table.
function M.get_state()
  return state
end

-- Sets the current theme.
-- @param theme_name (string) The name of the theme to set as current.
function M.set_current_theme(theme_name)
  if not theme_name then return end
  if state.current_theme ~= theme_name then
    state.previous_theme = state.current_theme
    state.current_theme = theme_name
    M.add_to_recents(theme_name)
  end
end

-- Reverts to the initial theme (active when script started).
function M.revert_to_initial()
  if state.initial_theme then
    state.previous_theme = state.current_theme
    state.current_theme = state.initial_theme
    return state.initial_theme
  end
  return nil
end

return M


