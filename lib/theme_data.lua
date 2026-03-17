-- lib/theme_data.lua
-- @noindex
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
-- @return (table) A list of structured theme objects.
function M.scan_for_themes(theme_dir)
  if not theme_dir then return {} end
  theme_dir = theme_dir:gsub('\\\\', '/'):gsub('/$', '')

  local themes = {}
  local directories = {}

  -- 1. Map all directories first
  local i = 0
  while true do
    local subdir = reaper.EnumerateSubdirectories(theme_dir, i)
    if not subdir then break end
    directories[subdir:lower()] = theme_dir .. '/' .. subdir
    i = i + 1
  end

  -- 2. Scan for valid theme entry files
  i = 0
  while true do
    local file = reaper.EnumerateFiles(theme_dir, i)
    if not file then break end
    
    local base_name, ext = file:match('^(.+)%.([Rr][Ee][Aa][Pp][Ee][Rr][Tt][Hh][Ee][Mm][Ee])$')
    local is_zip = false
    
    if not base_name then
      base_name, ext = file:match('^(.+)%.([Rr][Ee][Aa][Pp][Ee][Rr][Tt][Hh][Ee][Mm][Ee][Zz][Ii][Pp])$')
      is_zip = true
    end
    
    if base_name then
      local res_dir = directories[base_name:lower()]
      local theme_obj = {
        full_path = theme_dir .. '/' .. file,
        file_name = file,
        display_name = base_name,
        base_name = base_name,
        type = is_zip and "themezip" or "theme",
        resource_dir = res_dir,
        has_resource_dir = res_dir ~= nil
      }
      
      table.insert(themes, theme_obj)
    end
    i = i + 1
  end

  table.sort(themes, function(a, b) 
    return a.display_name:lower() < b.display_name:lower() 
  end)
  
  return themes
end

-- Returns the currently active theme path in REAPER.
function M.get_active_theme_path()
  return reaper.GetLastColorThemeFile():gsub('\\\\', '/')
end

return M



