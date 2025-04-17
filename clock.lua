-- clock.lua
-- Real‑Time EST Clock for CC:Tweaked on a 4×4 Advanced Monitor (HTTPS version)

if not http then
  error("HTTP API unavailable; enable http in CC:Tweaked config")
end

local mon = peripheral.find("monitor")
if not mon then
  error("No monitor attached")
end

-- ── CONFIG ───────────────────────────────────────────────────────────────────
-- Use HTTPS so we actually reach the API :contentReference[oaicite:0]{index=0}
local TIME_API    = "https://worldtimeapi.org/api/timezone/America/New_York.txt"
local SCALE       = 2                -- text size multiplier
local BORDER_COL  = colors.gray
local BG_COL      = colors.black
local TIME_COL    = colors.lime
local DATE_COL    = colors.white
local ERROR_COL   = colors.red
-- ──────────────────────────────────────────────────────────────────────────────

local monthNames = {
  ["01"]="January",  ["02"]="February", ["03"]="March",    ["04"]="April",
  ["05"]="May",      ["06"]="June",     ["07"]="July",     ["08"]="August",
  ["09"]="September",["10"]="October",  ["11"]="November", ["12"]="December"
}

-- initialize monitor
mon.setTextScale(SCALE)
mon.setBackgroundColor(BG_COL)
mon.clear()
local w, h = mon.getSize()

-- draw static border
local function drawBorder()
  mon.setBackgroundColor(BG_COL)
  mon.setTextColor(BORDER_COL)
  mon.setCursorPos(1,1);    mon.write(string.rep("-", w))
  mon.setCursorPos(1,h);    mon.write(string.rep("-", w))
  for y=2, h-1 do
    mon.setCursorPos(1, y); mon.write("|")
    mon.setCursorPos(w, y); mon.write("|")
  end
end
drawBorder()

-- clear the inside area
local function clearInterior()
  mon.setBackgroundColor(BG_COL)
  mon.setTextColor(DATE_COL)
  for y=2, h-1 do
    mon.setCursorPos(2, y)
    mon.write(string.rep(" ", w-2))
  end
end

-- center “text” on row “r”
local function centerPos(text, r)
  local x = math.floor((w - #text) / 2) + 1
  local y = math.max(2, math.min(h-1, r))
  return x, y
end

-- fetch, following one level of redirect if necessary
local function fetchUrl(url)
  local ok, res = pcall(http.get, url)
  if not ok then
    return nil, tostring(res)
  end
  if not res then
    return nil, "nil response"
  end

  local code = res.getResponseCode()
  if code >= 300 and code < 400 then
    local hdr = res.getResponseHeaders()["Location"] or ""
    res.close()
    if hdr ~= "" then
      -- follow redirect
      return fetchUrl(hdr)
    else
      return nil, "redirect without Location"
    end
  end

  return res, nil
end

-- main loop
while true do
  clearInterior()

  -- try to fetch over HTTPS (no more HTTP failure)
  local res, err = fetchUrl(TIME_API)
  if not res then
    -- show truncated error on the monitor
    local title = "HTTP Err!"
    local x,y = centerPos(title, math.floor(h/2)-1)
    mon.setTextColor(ERROR_COL)
    mon.setCursorPos(x,y); mon.write(title)

    local msg = err:gsub("\n"," "):sub(1, w-4)
    local x2,y2 = centerPos(msg, math.floor(h/2)+1)
    mon.setCursorPos(x2,y2); mon.write(msg)

    -- log full error to shell
    print("clock.lua HTTP failure:", err)
    sleep(2)
  else
    -- got a handle, read the text
    local raw = res.readAll()
    res.close()

    -- parse out the ISO‐timestamp
    local iso = raw:match("datetime:%s*([%d%-]+T[%d:]+)")
    if not iso then
      local pErr = "Parse Err!"
      local x,y = centerPos(pErr, math.floor(h/2))
      mon.setTextColor(ERROR_COL)
      mon.setCursorPos(x,y); mon.write(pErr)
      sleep(1)
    else
      -- split into date & time
      local datePart, timePart = iso:match("([^T]+)T(.+)")
      timePart = timePart:sub(1,8)  -- HH:MM:SS

      -- pretty‑print the date
      local Y,M,D = datePart:match("(%d+)%-(%d+)%-(%d+)")
      M = string.format("%02d", tonumber(M))
      local mName = monthNames[M] or M
      local day   = tostring(tonumber(D))
      local prettyDate = mName .. " " .. day .. ", " .. Y

      -- draw time
      local tx,ty = centerPos(timePart, math.floor(h/2)-1)
      mon.setTextColor(TIME_COL)
      mon.setCursorPos(tx,ty); mon.write(timePart)

      -- draw date
      local dx,dy = centerPos(prettyDate, math.floor(h/2)+1)
      mon.setTextColor(DATE_COL)
      mon.setCursorPos(dx,dy); mon.write(prettyDate)

      sleep(1)
    end
  end
end
