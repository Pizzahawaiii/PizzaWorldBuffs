PWB.utils = {}

-- Convert a time (duration) table to a number of minutes.
function PWB.utils.toMinutes (time)
  return time.h * 60 + time.m
end

-- Convert a number of minutes to a time table representing the same duration.
function PWB.utils.toTime (minutes)
  local time = {}
  time.m = math.mod(minutes, 60)
  time.h = (minutes - time.m) / 60
  return time
end

-- Convert a time table to string in Hh Mm format, e.g. 1h 52m.
function PWB.utils.toString (time)
  if not time then return 'N/A' end
  return (time.h > 0 and time.h .. 'h ' or '') .. time.m .. 'm'
end

-- Get a time table representing a certain number of hours from now (server time).
function PWB.utils.hoursFromNow (hours)
  local serverTime = PWB.utils.getServerTime()
  return {
    h = math.mod(serverTime.h + hours, 24),
    m = serverTime.m,
  }
end

-- Get current server time, normalized by accounting for TurtleWoW's in-game timezones.
function PWB.utils.getServerTime ()
  local h, m = GetGameTime()
  local isOnKalimdor = GetCurrentMapContinent() == 1
  return {
    -- TurtleWoW has continent timezones, so we need to normalize the server time if player is on Kalimdor
    h = (isOnKalimdor and math.mod(h + 12, 24)) or h,
    m = m,
  }
end

-- Get local PizzaWorldBuffs version as a semantic versioning string
function PWB.utils.getVersion()
  return tostring(GetAddOnMetadata(PWB.name, "Version"))
end

-- Get local PizzaWorldBuffs version as a single number
function PWB.utils.getVersionNumber ()
  local major, minor, patch = PWB.utils.strSplit(PWB.utils.getVersion(), '.')
  major = tonumber(major) or 0
  minor = tonumber(minor) or 0
  patch = tonumber(patch) or 0

  return major*10000 + minor*100 + patch
end

-- Check if we directly witnessed the provided timer ourselves.
function PWB.utils.witnessedByMe (timer)
  return timer.witness and timer.witness == PWB.me
end

-- Check if we received the provided timer from a direct witness.
function PWB.utils.receivedFromWitness (timer)
  return timer.receivedFrom and timer.witness and timer.receivedFrom == timer.witness
end

-- Identity function
function PWB.utils.identity (x)
  return x
end

-- Check if condition applies to any of our timers.
function PWB.utils.someTimer (fn)
  if not PWB_timers then return false end
  for _, timers in pairs(PWB_timers) do
    for _, timer in pairs(timers) do
      if fn(timer) then return true end
    end
  end
  return false
end

-- Invoke fn for each timer we have stored currently.
function PWB.utils.forEachTimer (fn)
  if not PWB_timers then return end
  for _, timers in pairs(PWB_timers) do
    for _, timer in pairs(timers) do
      fn(timer)
    end
  end
end

-- Check if we currently have any timers stored.
function PWB.utils.hasTimers ()
  return PWB.utils.someTimer(PWB.utils.identity)
end

-- Check if I'm the direct witness for any of my timers.
function PWB.utils.isWitness ()
  return PWB.utils.someTimer(PWB.utils.witnessedByMe)
end

-- Split the provided string by the specified delimiter.
function PWB.utils.strSplit (str, delimiter)
  if not str then return nil end
  local delimiter, fields = delimiter or ':', {}
  local pattern = string.format('([^%s]+)', delimiter)
  string.gsub(str, pattern, function(c) fields[table.getn(fields)+1] = c end)
  return unpack(fields)
end

-- Get the color that should be used for a timer, based on how confident we are in it.
function PWB.utils.getTimerColor (timer)
  if PWB.utils.witnessedByMe(timer) then return PWB.Colors.green end
  if PWB.utils.receivedFromWitness(timer) then return PWB.Colors.orange end
  return PWB.Colors.red
end