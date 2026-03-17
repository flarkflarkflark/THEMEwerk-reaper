-- lib/theme_actions.lua
-- @noindex
-- Contains functions that perform actions using native REAPER APIs.

local M = {}
local data = require('theme_data')

-- Applies a REAPER theme.
-- @param theme_path_or_name (string) Full path to theme file or its name.
-- @return (boolean) true on success, false on failure.
function M.apply_theme(theme_path_or_name)
  if not theme_path_or_name or #theme_path_or_name == 0 then return false end

  -- If it's already a full path to an existing file, apply it
  if data.file_exists(theme_path_or_name) then
    reaper.OpenColorThemeFile(theme_path_or_name)
    return true
  end

  local theme_dir = reaper.GetResourcePath():gsub('\\\\', '/') .. '/ColorThemes/'
  
  -- Fallback for name-only calls (Recents/Favorites)
  local exts = { '.ReaperTheme', '.ReaperThemeZip' }
  for _, ext in ipairs(exts) do
    local path = theme_dir .. theme_path_or_name .. ext
    if data.file_exists(path) then
      reaper.OpenColorThemeFile(path)
      return true
    end
  end

  return false
end

return M


