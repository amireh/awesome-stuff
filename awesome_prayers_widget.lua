local http = require 'socket.http'
local json = require 'json'
local ptw = widget({ type = "textbox" })

local pulses = {
  -- the widget update frequency (in seconds)
  refresh = 30,

  -- the prayer timetable synchronization frequency (in seconds)
  sync    = 21600 -- 6 hours
}

local colors = {
  "green",
  "orange",
  "red"
}

local locales = {
  -- en = {
  --   ["seconds"],
  --   ["hours"],
  --   ["Al Fajr"],
  --   ["Al Duhr"],
  --   ["Al Asr"],
  --   ["Al Maghrib"],
  --   ["Al Ishaa"],
  --   ["Unable to fetch prayer times"],
  --   ["Refreshing prayer times every"],
  --   ["and synchronizing prayer timetable every"]
  -- },

  ar = {
    ["seconds"] = "ثواني",
    ["hours"] = "ساعات",
    ["in"] = "بعد",
    ["Al Fajr"] = "الفَجْر",
    ["Al Duhr"] = "الظُّهر",
    ["Al Asr"] = "العَصر",
    ["Al Maghrib"] = "المَغرِب",
    ["Al Ishaa"] = "العِشاء",
    ["Unable to fetch prayer times"] = "فَشِلت عملية الحصول على توقيت الصلاوات",
    ["Refreshing prayer times every"] = "سيتم تحديث التوقيت المُقَرَّر كل",
    ["and synchronizing the timetable every"] = "و تحديث جدول الأوقات كل"
  }
}

local locale = locales.ar

local function l(str)
  return locale[str] or str
end

local function convert_time(secs)
  -- Round "up" to absolute value, so we treat negative differently;
  -- that is, round (-1.5) will return -2
  local function round (x)
    if x >= 0 then return math.floor(x) end
    return math.ceil(x - 0.5)
  end -- function round

  return round(secs / (3600)), round(secs / 60) % 60
end -- function convert_time 

-- Helper for converting a time string of HH:MM to seconds
local function prayer_time_to_seconds(str)
  local hours_parsed = false
  local seconds = 0
  for part in str:gmatch("%d+") do 
    seconds = seconds + (hours_parsed and part * 60 or part * 3600)
    hours_parsed = true
  end
  return seconds
end

-- Reports an error in a Naughty notification
local function on_error(msg)
  naughty.notify({
    preset = naughty.config.presets.critical,
    title = "awesome Prayers",
    text = msg
  })

  return nil, msg
end

local function on_notice(msg)
  print(msg)
  naughty.notify({
    text = tostring(msg)
  })
end

-- fetch()
-- @brief 
--  Locates the past and upcoming prayers relative to a given date and time.
--
-- @param year        The year for which the prayer timings should be calculated
-- @param month       The month for which the prayer timings should be calculated
-- @param day         The day for which the prayer timings should be calculated
-- @param day_seconds The seconds that have passed during the day (hours * 3600 + minutes * 60)
--
-- On success:
--  @return prayer_names [table] the names of the 5 prayers
--  @return prayer_times [table] the times of each of the 5 prayers in HH:MM format
--  @return next_prayer  [number] the index (1..5) of the upcoming prayer
--  @return past_prayer  [number] the index (1..5) of the past prayer
--  @return offset       [number] the amount of seconds left for the upcoming prayer
--
-- On failure: returns nil, error_msg
local prayer_times = nil
local prayer_names = { "Al Fajr", "Al Duhr", "Al Asr", "Al Maghrib", "Al Ishaa" }
local function fetch(year, month, day, day_seconds)
  
  -- Fetch the synchronized prayer times
  if not prayer_times then
    -- Latitude, Longtitude & GMT of Amman, Jordan
    local latitude    = 31
    local langtitude  = 36
    local gmt         = month >= 4 and month < 10 and 3 or 2

    -- Retrieve prayer times for the given date
    local uri = "http://xhanch.com/api/islamic-get-prayer-time.php" ..
                "?lng=" .. langtitude ..
                "&lat=" .. latitude ..
                "&yy=" .. year .. "&mm=" .. month ..
                "&gmt=" .. gmt ..
                "&m=json"

    local resp, msg = http.request(uri)

    if not resp then
      return nil, l("Unable to fetch prayer times") .. ": " .. msg
    end

    local raw_times = json.decode(resp)[tostring(day)]
    
    prayer_times = {
      raw_times["fajr"],
      raw_times["zuhr"],
      raw_times["asr"],
      raw_times["maghrib"],
      raw_times["isha"]
    }
  end

  -- Locate the upcoming & past prayers
  local past_prayer, next_prayer = nil, nil
  local offset = 0
  
  for i = 1, 5 do
    local prayer_time_seconds = prayer_time_to_seconds(prayer_times[i])

    if day_seconds < prayer_time_seconds then
      next_prayer = i
      offset = prayer_time_seconds - day_seconds
      if i == 1 then past_prayer = 5 else past_prayer = i - 1 end
      break
    elseif i == 5 then
      next_prayer = 1
      past_prayer = 5

      offset = 24 * 3600 - day_seconds + prayer_time_to_seconds(prayer_times[1])
    end

    -- print(prayer_names[i] .. " => seconds: " .. prayer_time_seconds)
  end

  return
    prayer_names,
    prayer_times,
    next_prayer,
    past_prayer,
    offset
end -- function fetch()

local function refresh()
  local today = os.date("*t")
  local today_seconds = tonumber(today["hour"]) * 3600 + tonumber(today["min"]) * 60

  local prayer_names, 
        prayer_times, 
        next_prayer, 
        past_prayer,
        offset = fetch(today["year"], today["month"], today["day"], today_seconds)

  if not prayer_names then
    local errmsg = prayer_times
    return on_error(errmsg)
  end

  local offset_h, offset_m = convert_time(offset)

  -- colorize the countdown based on how long is left for the upcoming prayer
  local color = "white"
  
  if      offset_h >= 2 then color = colors[1] -- "green"
  elseif  offset_h > 1  then color = colors[2] -- "orange"
  else                       color = colors[3] -- "red"
  end

  ptw.text = 
    "<span color='" .. color .. "'>" .. 
    l(prayer_names[next_prayer]) .. " " .. l("in") .. " " ..
    offset_h .. ":" .. offset_m .. "</span>"

  return true
end

if refresh() then
  local timers = {
    refresh = nil,
    sync    = nil
  }

  timers.refresh = timer({ timeout = pulses.refresh })
  timers.refresh:add_signal("timeout", refresh)
  timers.refresh:start()

  timers.sync = timer({ timeout = pulses.sync })
  timers.sync:add_signal("timeout", function() prayer_times = nil end)
  timers.sync:start()

  on_notice(
    l("Refreshing prayer times every") .. ' ' .. pulses.refresh .. ' ' ..
    l("seconds") .. ' ' ..
    l("and synchronizing the timetable every") .. ' ' ..
    tostring(tonumber(pulses.sync / 60 / 60)) .. ' ' .. l("hours") .. "." )
end

return ptw