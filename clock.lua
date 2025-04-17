-- clock.lua
-- Real‐Time EST Clock for CC:Tweaked on a 4×4 Advanced Monitor
-- Now with full HTTP error capture & display

if not http then
    error("HTTP API unavailable; enable http in CC:Tweaked config")
  end
  
  local mon = peripheral.find("monitor")
  if not mon then
    error("No monitor attached")
  end
  
  -- ── CONFIG ───────────────────────────────────────────────────────────────────
  local TIME_API = "http://worldtimeapi.org/api/timezone/America/New_York.txt"
  local SCALE    = 2                -- text size multiplier
  local BORDER   = colors.gray
  local BG       = colors.black
  local TIME_COL = colors.lime
  local DATE_COL = colors.white
  local ERR_COL  = colors.red
  -- ──────────────────────────────────────────────────────────────────────────────
  
  local months = {
    ["01"]="January", ["02"]="February", ["03"]="March",    ["04"]="April",
    ["05"]="May",     ["06"]="June",     ["07"]="July",     ["08"]="August",
    ["09"]="September", ["10"]="October", ["11"]="November", ["12"]="December"
  }
  
  -- initialize monitor
  mon.setTextScale(SCALE)
  mon.setBackgroundColor(BG)
  mon.clear()
  local w, h = mon.getSize()
  
  -- draw border
  local function drawBorder()
    mon.setBackgroundColor(BG)
    mon.setTextColor(BORDER)
    mon.setCursorPos(1,1);    mon.write(string.rep("-", w))
    mon.setCursorPos(1,h);    mon.write(string.rep("-", w))
    for y=2, h-1 do
      mon.setCursorPos(1, y); mon.write("|")
      mon.setCursorPos(w, y); mon.write("|")
    end
  end
  drawBorder()
  
  -- clear interior
  local function clearInterior()
    mon.setBackgroundColor(BG)
    mon.setTextColor(DATE_COL)
    for y=2, h-1 do
      mon.setCursorPos(2, y)
      mon.write(string.rep(" ", w-2))
    end
  end
  
  -- center helper
  local function centerPos(text, row)
    local x = math.floor((w - #text) / 2) + 1
    local y = math.max(2, math.min(h-1, row))
    return x, y
  end
  
  -- main loop
  while true do
    clearInterior()
  
    -- pcall to catch thrown errors (e.g. domain not whitelisted)
    local ok, res, err = pcall(function()
      return http.get(TIME_API)
    end)
  
    if not ok then
      -- http.get threw an error
      local msg = "HTTP Err!"
      local x,y = centerPos(msg, math.floor(h/2)-1)
      mon.setTextColor(ERR_COL)
      mon.setCursorPos(x,y); mon.write(msg)
  
      -- truncate the error for display
      local e = tostring(res)  -- 'res' holds the thrown error message
      e = e:gsub("\n"," "):sub(1, w-4)
      local x2,y2 = centerPos(e, math.floor(h/2)+1)
      mon.setCursorPos(x2,y2); mon.write(e)
  
      -- also log full error to shell
      print("clock.lua HTTP exception:", e)
      sleep(2)
  
    elseif not res then
      -- http.get returned nil + error string
      local msg = "HTTP Err!"
      local x,y = centerPos(msg, math.floor(h/2)-1)
      mon.setTextColor(ERR_COL)
      mon.setCursorPos(x,y); mon.write(msg)
  
      local e = tostring(err):gsub("\n"," "):sub(1, w-4)
      local x2,y2 = centerPos(e, math.floor(h/2)+1)
      mon.setCursorPos(x2,y2); mon.write(e)
  
      print("clock.lua HTTP failure:", err)
      sleep(2)
  
    else
      -- success!
      local raw = res.readAll()
      res.close()
  
      -- grab ISO date/time (YYYY‑MM‑DDThh:mm:ss)
      local datetime = raw:match("datetime:%s*([%d%-]+T[%d:]+)")
      if not datetime then
        local msg = "Parse Err!"
        local x,y = centerPos(msg, math.floor(h/2))
        mon.setTextColor(ERR_COL)
        mon.setCursorPos(x,y); mon.write(msg)
        sleep(1)
      else
        local datePart, timeFull = datetime:match("([^T]+)T(.+)")
        local timePart = timeFull:match("^(%d%d:%d%d:%d%d)")
  
        local y_, m_, d_ = datePart:match("(%d+)%-(%d+)%-(%d+)")
        m_ = string.format("%02d", tonumber(m_))
        local mName = months[m_] or m_
        local dayNum = tostring(tonumber(d_))
        local formattedDate = mName .. " " .. dayNum .. ", " .. y_
  
        -- draw time
        local tx,ty = centerPos(timePart, math.floor(h/2)-1)
        mon.setTextColor(TIME_COL)
        mon.setCursorPos(tx,ty); mon.write(timePart)
  
        -- draw date
        local dx,dy = centerPos(formattedDate, math.floor(h/2)+1)
        mon.setTextColor(DATE_COL)
        mon.setCursorPos(dx,dy); mon.write(formattedDate)
  
        sleep(1)
      end
    end
  end
  