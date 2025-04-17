-- clock.lua
-- Real‐Time EST Clock for CC:Tweaked on a 4×4 Advanced Monitor
-- Fetches America/New_York time every second and displays HH:MM:SS + Month D, YYYY

-- Make sure http is available
if not http then
  error("HTTP API unavailable; enable http in CC:Tweaked config")
end

-- Find the monitor peripheral
local mon = peripheral.find("monitor")
if not mon then
  error("No monitor attached")
end

-- Configuration
local TIME_API = "http://worldtimeapi.org/api/timezone/America/New_York.txt"
local SCALE    = 2                -- 2× text size
local BORDER   = colors.gray
local BG       = colors.black
local TIME_COL = colors.lime
local DATE_COL = colors.white
local ERR_COL  = colors.red

-- Month lookup
local months = {
  ["01"]="January", ["02"]="February", ["03"]="March",    ["04"]="April",
  ["05"]="May",     ["06"]="June",     ["07"]="July",     ["08"]="August",
  ["09"]="September", ["10"]="October", ["11"]="November", ["12"]="December"
}

-- Init monitor
mon.setTextScale(SCALE)
mon.setBackgroundColor(BG)
mon.clear()
local w, h = mon.getSize()

-- Draw border
local function drawBorder()
  mon.setBackgroundColor(BG)
  mon.setTextColor(BORDER)
  -- top/bottom
  mon.setCursorPos(1, 1);   mon.write(string.rep("-", w))
  mon.setCursorPos(1, h);   mon.write(string.rep("-", w))
  -- sides
  for y=2, h-1 do
    mon.setCursorPos(1, y);   mon.write("|")
    mon.setCursorPos(w, y);   mon.write("|")
  end
end
drawBorder()

-- Clear interior (inside the border)
local function clearInterior()
  mon.setBackgroundColor(BG)
  mon.setTextColor(DATE_COL)
  for y=2, h-1 do
    mon.setCursorPos(2, y)
    mon.write(string.rep(" ", w-2))
  end
end

-- Center helper
local function centerPos(text, row)
  local x = math.floor((w - #text) / 2) + 1
  local y = row
  if y < 2 then y = 2 end
  if y > h-1 then y = h-1 end
  return x, y
end

-- Main loop
while true do
  clearInterior()

  -- Fetch from API
  local res = http.get(TIME_API)
  if not res then
    -- HTTP failed
    local msg = "HTTP Error"
    local x,y = centerPos(msg, math.floor(h/2))
    mon.setTextColor(ERR_COL)
    mon.setCursorPos(x, y)
    mon.write(msg)
    sleep(1)
  else
    local raw = res.readAll()
    res.close()

    -- Parse "datetime: 2025-04-16T23:45:12.123456-04:00"
    local datetime = raw:match("datetime:%s*([%d%-]+T[%d:]+)")
    if not datetime then
      local msg = "Parse Error"
      local x,y = centerPos(msg, math.floor(h/2))
      mon.setTextColor(ERR_COL)
      mon.setCursorPos(x, y)
      mon.write(msg)
      sleep(1)
    else
      -- Split into date/time
      local datePart, timePart = datetime:match("([^T]+)T(.+)")
      timePart = timePart:match("^(%d%d:%d%d:%d%d)") -- strip fractions

      -- Format date
      local y_, m_, d_ = datePart:match("(%d+)%-(%d+)%-(%d+)")
      m_ = string.format("%02d", tonumber(m_))
      local mName = months[m_] or m_
      local dayNum = tostring(tonumber(d_))
      local formattedDate = mName .. " " .. dayNum .. ", " .. y_

      -- Draw time
      local tx, ty = centerPos(timePart, math.floor(h/2)-1)
      mon.setTextColor(TIME_COL)
      mon.setCursorPos(tx, ty)
      mon.write(timePart)

      -- Draw date
      local dx, dy = centerPos(formattedDate, math.floor(h/2)+1)
      mon.setTextColor(DATE_COL)
      mon.setCursorPos(dx, dy)
      mon.write(formattedDate)

      sleep(1)
    end
  end
end
