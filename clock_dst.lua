-- clock.lua
-- EST/EDT 12‑Hour Clock on a 4×4 Advanced Monitor, DST auto‑calculated

-- find monitor
local mon = peripheral.find("monitor")
if not mon then error("No monitor attached") end

-- month names
local monthNames = {
  "January","February","March","April","May","June",
  "July","August","September","October","November","December"
}

-- styling
local SCALE      = 2
local COL_BG     = colors.black
local COL_BORDER = colors.gray
local COL_TIME   = colors.lime
local COL_DATE   = colors.white
local COL_ERR    = colors.red

-- init monitor
mon.setTextScale(SCALE)
mon.setBackgroundColor(COL_BG)
mon.clear()
local w,h = mon.getSize()

-- draw border
local function drawBorder()
  mon.setTextColor(COL_BORDER)
  mon.setCursorPos(1,1);    mon.write(string.rep("-", w))
  mon.setCursorPos(1,h);    mon.write(string.rep("-", w))
  for y=2,h-1 do
    mon.setCursorPos(1,y);  mon.write("|")
    mon.setCursorPos(w,y);  mon.write("|")
  end
end
drawBorder()

-- clear interior
local function clearInterior()
  mon.setTextColor(COL_DATE)
  mon.setBackgroundColor(COL_BG)
  for y=2,h-1 do
    mon.setCursorPos(2,y)
    mon.write(string.rep(" ", w-2))
  end
end

-- center helper
local function centerPos(text,row)
  local x = math.floor((w - #text)/2)+1
  row = math.max(2, math.min(h-1, row))
  return x,row
end

-- compute DST bounds in UTC for given year
local function dstBounds(year)
  -- second Sunday in March at 2:00 local → 7:00 UTC
  local m1 = os.date("!*t", os.time{year=year, month=3, day=1, hour=0}).wday
  local firstSunMar = 1 + ((8 - m1) % 7)
  local secondSunMar = firstSunMar + 7
  local startUTC = os.time{year=year, month=3, day=secondSunMar, hour=7}
  -- first Sunday in Nov at 2:00 local (EDT → UTC-4) → 6:00 UTC
  local n1 = os.date("!*t", os.time{year=year, month=11, day=1, hour=0}).wday
  local firstSunNov = 1 + ((8 - n1) % 7)
  local endUTC   = os.time{year=year, month=11, day=firstSunNov, hour=6}
  return startUTC, endUTC
end

-- convert 24h "HH:MM:SS" → "H:MM:SS AM/PM"
local function to12(t24)
  local h24 = tonumber(t24:sub(1,2))
  local rest = t24:sub(3)
  local suffix = (h24<12) and "AM" or "PM"
  local h12 = h24 % 12
  if h12 == 0 then h12 = 12 end
  return tostring(h12)..rest.." "..suffix
end

-- main loop
while true do
  clearInterior()
  local nowUTC = os.time(os.date("!*t"))
  local curYear = os.date("!*t").year
  local sUTC,eUTC = dstBounds(curYear)
  local offset = (nowUTC>=sUTC and nowUTC<eUTC) and 4 or 5
  local estTs = nowUTC - offset*3600
  local t = os.date("*t", estTs)
  -- format
  local time24 = string.format("%02d:%02d:%02d", t.hour, t.min, t.sec)
  local time12 = to12(time24)
  local dateStr = monthNames[t.month].." "..t.day..", "..t.year

  -- draw time
  local tx,ty = centerPos(time12, math.floor(h/2)-1)
  mon.setTextColor(COL_TIME)
  mon.setCursorPos(tx,ty)
  mon.write(time12)
  -- draw date
  local dx,dy = centerPos(dateStr, math.floor(h/2)+1)
  mon.setTextColor(COL_DATE)
  mon.setCursorPos(dx,dy)
  mon.write(dateStr)

  sleep(1)
end
