-- @description THEMEwerk: A local theme browser
-- @version 0.1.3
-- @author flarkAUDIO
-- @category Theme Browser
-- @about
--   A local REAPER theme browser for fast, searchable, and keyboard-friendly theme switching.
--   Turns theme browsing into a live workflow.
-- @provides
--   lib/*.lua
--   assets/toolbar_icons/THEMEwerk_toolbar.png
--   assets/toolbar_icons/masters/themewerk_main.png
--   assets/toolbar_icons/single/*.png
--   assets/toolbar_icons/strips_90x30/*.png
--   assets/toolbar_icons/strips_135x45/*.png
--   assets/toolbar_icons/strips_180x60/*.png

-- Set up paths for required modules
local info = debug.getinfo(1,'S')
local script_dir = info.source:match([[^@?(.*[\/])[^\\/]*$]])
if script_dir then
  -- Add script_dir/lib to package.path
  package.path = package.path .. ';' .. script_dir .. 'lib' .. package.config:sub(1,1) .. '?.lua'
end

-- Load libraries
local data, state, ui
local ok
ok, data = pcall(require, 'theme_data')
if not ok then reaper.ShowMessageBox('Failed to load theme_data.lua.\n' .. tostring(data), 'Error', 0) return end
ok, state = pcall(require, 'theme_state')
if not ok then reaper.ShowMessageBox('Failed to load theme_state.lua.\n' .. tostring(state), 'Error', 0) return end
ok, ui = pcall(require, 'theme_ui')
if not ok then reaper.ShowMessageBox('Failed to load theme_ui.lua.\n' .. tostring(ui), 'Error', 0) return end


-- Main function
function main()
  local theme_dir = data.get_theme_dir()
  if not theme_dir then
    reaper.ShowMessageBox('Could not determine the REAPER resource path.', 'Error', 0)
    return
  end

  local themes = data.scan_for_themes(theme_dir)
  if not themes or #themes == 0 then
    reaper.ShowMessageBox('No themes found in ColorThemes directory.', 'Information', 0)
  end
  
  state.init(themes)
  
  -- Start UI
  ui.run()
end

reaper.atexit(function()
  state.save_state()
end)

main()
