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
  previous_theme = nil, -- The name of the theme active before the script was run
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
  -- Remove if already exists
  for i, v in ipairs(state.recents) do
    if v == theme_name then
      table.remove(state.recents, i)
      break
    end
  end
  -- Add to the front
  table.insert(state.recents, 1, theme_name)
  -- Trim the list
  if #state.recents > MAX_RECENTS then
    state.recents[MAX_RECENTS + 1] = nil
  end
end

function M.toggle_favorite(theme_name)
  local found_idx = -1
  for i, v in ipairs(state.favorites) do
    if v == theme_name then
      found_idx = i
      break
    end
  end

  if found_idx > 0 then
    table.remove(state.favorites, found_idx)
  else
    table.insert(state.favorites, theme_name)
  end
end

-- Initializes the state.
-- @param themes (table) A list of theme names from theme_data.
function M.init(themes)
  M.load_state()
  state.themes = themes or {}
  -- Try to get the current theme.
  local current_theme_path = reaper.GetLastLoadedThemeFile()
  if current_theme_path and #current_theme_path > 0 then
    local theme_name = current_theme_path:match('([^/\\\\]+)%.ReaperTheme[^Zip]?$')
    if not theme_name then
       theme_name = current_theme_path:match('([^/\\\\]+)%.ReaperThemeZip$')
    end
    if not theme_name then
      -- It might be an unpacked theme, try to get the directory name
      theme_name = current_theme_path:match('([^/\\\\]+)[/\\\\]?$')
    end
    state.current_theme = theme_name
    state.previous_theme = theme_name -- Store the initial theme
  else
    reaper.ShowConsoleMsg('THEMEwerk: Could not determine the currently active theme.\\n')
  end
end

-- Returns the full state table.
function M.get_state()
  return state
end

-- Sets the current theme.
-- @param theme_name (string) The name of the theme to set as current.
function M.set_current_theme(theme_name)
  if state.current_theme ~= theme_name then
    state.previous_theme = state.current_theme
    state.current_theme = theme_name
    M.add_to_recents(theme_name)
  end
end

-- Reverts to the previous theme.
function M.revert_to_previous()
  if state.previous_theme then
    state.current_theme = state.previous_theme
  end
end

return M
