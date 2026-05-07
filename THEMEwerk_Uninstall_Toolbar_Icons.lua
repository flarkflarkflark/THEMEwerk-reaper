-- @description THEMEwerk: Uninstall Toolbar Icons
-- @version 0.1.7
-- @author flarkAUDIO
-- @category Theme Browser
-- @about
--   Removes THEMEwerk toolbar icon files from REAPER Data/toolbar_icons.

local sep = package.config:sub(1, 1)
local dst_root = reaper.GetResourcePath() .. sep .. "Data" .. sep .. "toolbar_icons" .. sep
local app_title = "THEMEwerk"

local function detect_script_version()
  local src = debug.getinfo(1, "S").source or ""
  local this_file = src:match("^@(.+)$")
  if not this_file then return nil end
  local f = io.open(this_file, "r")
  if not f then return nil end
  local chunk = f:read("*a") or ""
  f:close()
  return chunk:match("%-%-%s*@version%s+([%w%._%-]+)")
end

local v = detect_script_version()
if v then app_title = app_title .. " v" .. v end

local files = {
  "themewerk_main_90x30.png",
  "themewerk_main_135x45.png",
  "themewerk_main_180x60.png",
  "THEMEwerk_toolbar.png"
}

local removed, missing = 0, {}
for _, name in ipairs(files) do
  local path = dst_root .. name
  local ok = os.remove(path)
  if ok then
    removed = removed + 1
  else
    missing[#missing + 1] = name
  end
end

local msg = "Removed " .. tostring(removed) .. " THEMEwerk toolbar icon files from:\n" .. dst_root
if #missing > 0 then
  msg = msg .. "\n\nNot found:\n" .. table.concat(missing, "\n")
end

reaper.ShowMessageBox(msg, app_title, 0)
