-- lib/theme_data.lua
-- Handles discovery and management of REAPER themes using native APIs.

local M = {}

-- Returns the path to the REAPER ColorThemes directory.
-- @return (string) Path to ColorThemes directory, or nil if not found.
function M.get_theme_dir()
  local res_path = reaper.GetResourcePath()
  if res_path and #res_path > 0 then
    res_path = res_path:gsub('\\\\', '/')
    return res_path .. '/ColorThemes'
  end
  return nil
end

-- Checks if a file exists using native Lua API (efficient O(1) check).
function M.file_exists(path)
  local f = io.open(path, 'r')
  if f then
    f:close()
    return true
  end
  return false
end

-- Scans the ColorThemes directory for theme files natively.
-- @param theme_dir (string) The path to the ColorThemes directory.
-- @return (table) A sorted list of theme names.
function M.scan_for_themes(theme_dir)
  if not theme_dir then return {} end

  local themes = {}
  local theme_exists = {}

  local i = 0
  while true do
    local file = reaper.EnumerateFiles(theme_dir, i)
    if not file then break end
    
    local theme_name = file:match('(.+)%.ReaperTheme$') or 
                       file:match('(.+)%.ReaperThemeZip$')
    
    if theme_name and not theme_exists[theme_name] then
      table.insert(themes, theme_name)
      theme_exists[theme_name] = true
    end
    i = i + 1
  end

  table.sort(themes)
  return themes
end

return M



