PWB.utils = {}

function PWB.utils.toMinutes (time)
  return time.h * 60 + time.m
end

function PWB.utils.toTime (minutes)
  local time = {}
  time.m = math.mod(minutes, 60)
  time.h = (minutes - time.m) / 60
  return time
end

function PWB.utils.toString (time, format)
  if not time then return 'N/A' end
  if format == 'hm' then
    return (time.h > 0 and time.h .. 'h ' or '') .. time.m .. 'm'
  end
  return string.format('%.2d:%.2d', time.h, time.m)
end

function PWB.utils.hoursFromNow (hours)
  local serverTime = PWB.utils.getServerTime()
  return {
    h = math.mod(serverTime.h + hours, 24),
    m = serverTime.m,
  }
end

function PWB.utils.getServerTime ()
  local h, m = GetGameTime()
  local isOnKalimdor = GetCurrentMapContinent() == 1
  return {
    -- TurtleWoW has continent timezones, so we need to normalize the server time if player is on Kalimdor
    h = (isOnKalimdor and math.mod(h + 12, 24)) or h,
    m = m,
  }
end

function PWB.utils.strSplit (str, delimiter)
  if not str then return nil end
  local delimiter, fields = delimiter or ':', {}
  local pattern = string.format('([^%s]+)', delimiter)
  string.gsub(str, pattern, function(c) fields[table.getn(fields)+1] = c end)
  return unpack(fields)
end

function PWB.utils.getTimerColor (timer)
  if timer.witnessedMyself then return PWB.Colors.green end
  if timer.fromWitness then return PWB.Colors.orange end
  return PWB.Colors.red
end