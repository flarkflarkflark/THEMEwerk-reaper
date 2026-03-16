-- scripts/THEMEwerk.lua
-- Main script for THEMEwerk-reaper, a local theme browser.
-- @description THEMEwerk: A local theme browser
-- @version 0.1.0-alpha
-- @author flarkflarkflark
-- @about
--   A local REAPER theme browser for fast, searchable, and keyboard-friendly theme switching.
--   Turns theme browsing into a live workflow.
-- @provides
--   [main] .
--   ../lib/theme_actions.lua
--   ../lib/theme_data.lua
--   ../lib/theme_state.lua
--   ../lib/theme_ui.lua

-- Set up paths for required modules
local info = debug.getinfo(1,'S')
local script_path = info.source:match[[^@?(.*[\/])[^\\/]*$]]
if script_path then
  package.path = package.path .. ';' .. script_path .. '../lib/?.lua'
end

-- Load libraries
local data, state, ui
local ok
ok, data = pcall(require, 'theme_data')
if not ok then reaper.ShowMessageBox('Failed to load theme_data.lua.\\n' .. tostring(data), 'Error', 0) return end
ok, state = pcall(require, 'theme_state')
if not ok then reaper.ShowMessageBox('Failed to load theme_state.lua.\\n' .. tostring(state), 'Error', 0) return end
ok, ui = pcall(require, 'theme_ui')
if not ok then reaper.ShowMessageBox('Failed to load theme_ui.lua.\\n' .. tostring(ui), 'Error', 0) return end


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


