-- scripts/THEMEwerk.lua
-- Main script for THEMEwerk-reaper, a local theme browser.
-- @description THEMEwerk: A local theme browser
-- @version 0.1
-- @author Gemini
-- @about
--   A local REAPER theme browser for fast, searchable, and keyboard-friendly theme switching.
--   Requires the S&M extension (https://www.sws-extension.org/)
--   and the js_ReaScriptAPI extension.

-- Set up paths for required modules
local info = debug.getinfo(1,'S')
local script_path = info.source:match[[^@?(.*[\/])[^\\/]*$]]
package.path = package.path .. ';' .. script_path .. '../lib/?.lua'

-- Defer function to run when the script ends
function reaper.defer(func)
  local success, err = pcall(func)
  if not success then
    reaper.ShowConsoleMsg('THEMEwerk defer error: ' .. tostring(err) .. '\\n')
  end
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
  -- Check for dependencies
  if not reaper.JS_File_Exists then
    reaper.ShowMessageBox('This script requires the js_ReaScriptAPI extension.\\nPlease install it via ReaPack.', 'Dependency Not Found', 0)
    return
  end
  local sm_cmd = reaper.NamedCommandLookup('_S&M_LOAD_THEME_CLIP')
  if not (sm_cmd and sm_cmd > 0) then
      reaper.ShowMessageBox(
        'This script requires the S&M extension (v2.8 or later) to apply themes.\\n' ..
        'Please install or update it from https://www.sws-extension.org/',
        'S&M Extension Not Found or Outdated', 0
      )
      return
  end

  local theme_dir = data.get_theme_dir()
  if not theme_dir or not reaper.JS_File_Exists(theme_dir) then
    reaper.ShowMessageBox('Could not find the REAPER ColorThemes directory.', 'Error', 0)
    return
  end

  local themes = data.scan_for_themes(theme_dir)
  state.init(themes)
  
  ui.run()
  
  reaper.defer(function()
    ui.quit()
    reaper.ShowConsoleMsg('THEMEwerk exited.\\n')
  end)
end

main()
