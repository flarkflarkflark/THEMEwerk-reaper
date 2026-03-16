-- lib/theme_actions.lua
-- Contains functions that perform actions using native REAPER APIs.

local M = {}
local data = require('theme_data')

-- Applies a REAPER theme using native API.
-- @param theme_name (string) The name of the theme to apply.
-- @return (boolean) true on success, false on failure.
function M.apply_theme(theme_name)
  if not theme_name or #theme_name == 0 then return false end

  local theme_dir = reaper.GetResourcePath():gsub('\\\\', '/') .. '/ColorThemes/'
  
  -- Extensions to try
  local exts = { '.ReaperTheme', '.ReaperThemeZip' }
  local final_path = nil

  for _, ext in ipairs(exts) do
    local path = theme_dir .. theme_name .. ext
    if data.file_exists(path) then
      final_path = path
      break
    end
  end

  if not final_path then
    -- Check if it's an unpacked directory
    local dir_path = theme_dir .. theme_name
    if data.file_exists(dir_path) then
       final_path = dir_path
    end
  end

  if final_path then
    -- Native REAPER API to load a theme
    reaper.OpenColorThemeFile(final_path)
    return true
  end

  return false
end

return M


