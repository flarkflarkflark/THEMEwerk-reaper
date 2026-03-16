-- lib/theme_data.lua
-- Handles discovery and management of REAPER themes.

local M = {}

-- Returns the path to the REAPER ColorThemes directory.
-- @return (string) Path to ColorThemes directory, or nil if not found.
function M.get_theme_dir()
  -- reaper.GetResourcePath() is the reliable way to find the REAPER resource directory.
  local res_path = reaper.GetResourcePath()
  if res_path and #res_path > 0 then
    return res_path .. '/ColorThemes'
  end
  return nil
end

-- Scans the ColorThemes directory for theme files.
-- REAPER themes can be .ReaperTheme files or unpacked directories.
-- This version will focus on .ReaperTheme files for simplicity.
-- @param theme_dir (string) The path to the ColorThemes directory.
-- @return (table) A sorted list of theme names, or nil on error.
function M.scan_for_themes(theme_dir)
  if not theme_dir then
    reaper.ShowConsoleMsg('THEMEwerk: Theme directory not provided.\\n')
    return nil
  end

  local themes = {}
  local theme_exists = {} -- Used as a set to track uniqueness

  -- Scan for .ReaperTheme files
  local file = reaper.JS_File_FindFirst(theme_dir .. '/*.ReaperTheme')
  while file and #file > 0 do
    local theme_name = file:match('([^/\\\\]+)%.ReaperTheme$')
    if theme_name and not theme_exists[theme_name] then
      table.insert(themes, theme_name)
      theme_exists[theme_name] = true
    end
    file = reaper.JS_File_FindNext()
  end
  reaper.JS_File_FindClose()

  -- Scan for .ReaperThemeZip files
  file = reaper.JS_File_FindFirst(theme_dir .. '/*.ReaperThemeZip')
  while file and #file > 0 do
    local theme_name = file:match('([^/\\\\]+)%.ReaperThemeZip$')
    if theme_name and not theme_exists[theme_name] then
      table.insert(themes, theme_name)
      theme_exists[theme_name] = true
    end
    file = reaper.JS_File_FindNext()
  end
  reaper.JS_File_FindClose()

  -- TODO: Add scanning for unpacked theme directories.

  if #themes == 0 then
    reaper.ShowConsoleMsg('THEMEwerk: No theme files found in ' .. theme_dir .. '\\n')
    return {} -- Return an empty table, not nil
  end

  table.sort(themes)
  return themes
end

return M
