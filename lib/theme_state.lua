-- lib/theme_state.lua
-- Manages the state of the theme browser.

local M = {}

-- Holds the current state of the application
-- For v0.1, this is simple. It will grow as features are added.
local state = {
  themes = {},          -- Full list of available theme names
  current_theme = nil,  -- The name of the currently applied theme
  previous_theme = nil, -- The name of the theme active before the script was run
  favorites = {},       -- List of favorite theme names
  recents = {},         -- List of recently used theme names
}

-- Initializes the state.
-- @param themes (table) A list of theme names from theme_data.
function M.init(themes)
  state.themes = themes or {}
  -- Try to get the current theme.
  -- NOTE: There is no direct API to get the current theme file name.
  -- We can get the full path to the theme file, then extract the name.
  local current_theme_path = reaper.GetLastLoadedThemeFile()
  if current_theme_path and #current_theme_path > 0 then
    local theme_name = current_theme_path:match('([^/\\\\]+)%.ReaperTheme$')
    if not theme_name then
      -- It might be an unpacked theme, try to get the directory name
      theme_name = current_theme_path:match('([^/\\\\]+)[/\\\\]?$')
    end
    state.current_theme = theme_name
    state.previous_theme = theme_name -- Store the initial theme
  else
    -- Fallback if we can't determine the theme
    reaper.ShowConsoleMsg('THEMEwerk: Could not determine the currently active theme.\\n')
  end
end

-- Returns the full state table.
-- @return (table) The current state.
function M.get_state()
  return state
end

-- Sets the current theme.
-- @param theme_name (string) The name of the theme to set as current.
function M.set_current_theme(theme_name)
  if state.current_theme ~= theme_name then
    state.previous_theme = state.current_theme
    state.current_theme = theme_name
  end
end

-- Reverts to the previous theme.
function M.revert_to_previous()
  if state.previous_theme then
    state.current_theme = state.previous_theme
  end
end

return M
