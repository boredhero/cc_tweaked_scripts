-- clock.lua
-- EST clock using os.date (no HTTP needed)

-- find the monitor
local mon = peripheral.find("monitor")
if not mon then error("No monitor attached") end

-- test that os.date is available
if not os.date then
  error("Your CC:Tweaked version may not support os.date; please update")
end

-- styling
local SCALE     = 2
local COL_BG    = colors.black
local COL_BORDER= colors.gray
local COL_TIME  = colors.lime
local COL_DATE  = colors.white

-- init
mon.setTextScale(SCALE)
mon.setBackgroundColor(COL_BG)
mon.clear()
local w,h = mon.getSize()

-- draw a simple border
local function drawBorder()
  mon.setTextColor(COL_BORDER)
  mon.setCursorPos(1,1);    mon.write(string.rep("-", w))
  mon.setCursorPos(1,h);    mon.write(string.rep("-", w))
  for y=2, h-1 do
    mon.setCursorPos(1, y); mon.write("|")
    mon.setCursorPos(w, y); mon.write("|")
  end
end

-- clear inside area
local function clearInterior()
  mon.setBackgroundColor(COL_BG)
  mon.setTextColor(COL_DATE)
  for y=2, h-1 do
    mon.setCursorPos(2, y)
    mon.write(string.rep(" ", w-2))
  end
end

-- center helper
local function centerPos(txt, row)
  local x = math.floor((w - #txt) / 2) + 1
  local y = math.max(2, math.min(h-1, row))
  return x,y
end

-- main loop
while true do
  clearInterior()
  drawBorder()

  -- fetch local time
  local t = os.date("*t")                -- local timezone
  local timeStr = string.format(
    "%02d:%02d:%02d", t.hour, t.min, t.sec
  )
  local dateStr = os.date("%B %d, %Y")   -- e.g. April 16, 2025

  -- draw time
  local tx,ty = centerPos(timeStr, math.floor(h/2)-1)
  mon.setTextColor(COL_TIME)
  mon.setCursorPos(tx,ty)
  mon.write(timeStr)

  -- draw date
  local dx,dy = centerPos(dateStr, math.floor(h/2)+1)
  mon.setTextColor(COL_DATE)
  mon.setCursorPos(dx,dy)
  mon.write(dateStr)

  sleep(1)
end
