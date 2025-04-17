-- clock.lua
-- Eastern Standard Time clock using os.date (UTC→EST conversion)
-- Assumes your server’s OS clock is set to UTC

-- find the 4×4 advanced monitor
local mon = peripheral.find("monitor")
if not mon then error("No monitor attached") end

-- month names for formatting
local monthNames = {
  "January","February","March","April","May","June",
  "July","August","September","October","November","December"
}

-- styling constants
local SCALE      = 2
local COL_BG     = colors.black
local COL_BORDER = colors.gray
local COL_TIME   = colors.lime
local COL_DATE   = colors.white

-- initialize monitor
mon.setTextScale(SCALE)
mon.setBackgroundColor(COL_BG)
mon.clear()
local w, h = mon.getSize()

-- draw a simple border
local function drawBorder()
  mon.setTextColor(COL_BORDER)
  -- top and bottom
  mon.setCursorPos(1,1);   mon.write(string.rep("-", w))
  mon.setCursorPos(1,h);   mon.write(string.rep("-", w))
  -- sides
  for y=2, h-1 do
    mon.setCursorPos(1, y);  mon.write("|")
    mon.setCursorPos(w, y);  mon.write("|")
  end
end
drawBorder()

-- clear the inside area (between the borders)
local function clearInterior()
  mon.setBackgroundColor(COL_BG)
  mon.setTextColor(COL_DATE)
  for y=2, h-1 do
    mon.setCursorPos(2, y)
    mon.write(string.rep(" ", w-2))
  end
end

-- helper to center text on a given row
local function centerPos(text, row)
  local x = math.floor((w - #text) / 2) + 1
  local y = math.max(2, math.min(h-1, row))
  return x, y
end

-- main loop: update every second
while true do
  clearInterior()
  drawBorder()

  -- 1) get current UTC timestamp
  local nowUtc = os.time(os.date("!*t"))
  -- 2) convert to EST by subtracting 5 hours
  local estTs  = nowUtc - (5 * 3600)
  -- 3) break it back into components
  local t      = os.date("*t", estTs)

  -- format HH:MM:SS
  local timeStr = string.format("%02d:%02d:%02d", t.hour, t.min, t.sec)
  -- format Month D, YYYY
  local dateStr = monthNames[t.month].." "..t.day..", "..t.year

  -- draw time (one line above center)
  local tx, ty = centerPos(timeStr, math.floor(h/2) - 1)
  mon.setTextColor(COL_TIME)
  mon.setCursorPos(tx, ty)
  mon.write(timeStr)

  -- draw date (one line below center)
  local dx, dy = centerPos(dateStr, math.floor(h/2) + 1)
  mon.setTextColor(COL_DATE)
  mon.setCursorPos(dx, dy)
  mon.write(dateStr)

  sleep(1)
end
