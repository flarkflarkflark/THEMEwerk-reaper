-- @description THEMEwerk: Install Toolbar Icons
-- @version 0.1.7
-- @author flarkAUDIO
-- @category Theme Browser
-- @about
--   Copies THEMEwerk toolbar icon strips into REAPER Data/toolbar_icons
--   so they appear in the toolbar icon picker.

local function script_dir()
  local src = debug.getinfo(1, "S").source or ""
  local p = src:match("^@(.+)$")
  if not p then return nil end
  return p:match("^(.*[\\/])")
end

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

local function copy_file(src, dst)
  local in_f = io.open(src, "rb")
  if not in_f then return false, "missing source: " .. src end
  local data = in_f:read("*a")
  in_f:close()
  local out_f = io.open(dst, "wb")
  if not out_f then return false, "cannot write: " .. dst end
  out_f:write(data)
  out_f:close()
  return true
end

local sep = package.config:sub(1, 1)
local base = script_dir()
local app_title = "THEMEwerk"
local v = detect_script_version()
if v then app_title = app_title .. " v" .. v end
if not base then
  reaper.ShowMessageBox("Could not resolve script directory.", app_title, 0)
  return
end

local src_root = base .. "assets" .. sep .. "toolbar_icons" .. sep
local dst_root = reaper.GetResourcePath() .. sep .. "Data" .. sep .. "toolbar_icons" .. sep

reaper.RecursiveCreateDirectory(dst_root, 0)

local files = {
  "strips_90x30" .. sep .. "themewerk_main_90x30.png",
  "strips_135x45" .. sep .. "themewerk_main_135x45.png",
  "strips_180x60" .. sep .. "themewerk_main_180x60.png",
  "THEMEwerk_toolbar.png"
}

local copied, failed = 0, {}
for _, rel in ipairs(files) do
  local ok, err = copy_file(src_root .. rel, dst_root .. rel:match("([^\\/]+)$"))
  if ok then
    copied = copied + 1
  else
    failed[#failed + 1] = err
  end
end

if #failed == 0 then
  reaper.ShowMessageBox(
    "Installed " .. tostring(copied) .. " THEMEwerk toolbar icon files to:\n" .. dst_root,
    app_title,
    0
  )
else
  reaper.ShowMessageBox(
    "Installed " .. tostring(copied) .. " files, but some failed:\n\n" .. table.concat(failed, "\n"),
    app_title,
    0
  )
end
