local PWB = PizzaWorldBuffs
PWB.utils = {}

-- Convert a time (duration) table to a number of minutes.
function PWB.utils.toMinutes (h, m)
  return h * 60 + m
end

-- Convert a number of minutes to a time table representing the same duration.
function PWB.utils.toTime (minutes)
  local m = math.mod(minutes, 60)
  local h = (minutes - m) / 60
  return h, m
end

-- Convert a time table to string in Hh Mm format, e.g. 1h 52m.
function PWB.utils.toString (h, m)
  if not h and not m then return 'N/A' end
  return (h > 0 and h .. 'h ' or '') .. m .. 'm'
end

-- Get a time table representing a certain number of hours from now (server time).
function PWB.utils.hoursFromNow (hours)
  local h, m = PWB.utils.getServerTime()
  h = math.mod(h + hours, 24)
  return h, m
end

-- Get current server time, normalized by accounting for TurtleWoW's in-game timezones.
function PWB.utils.getServerTime ()
  local h, m = GetGameTime()
  local isOnKalimdor = GetCurrentMapContinent() == 1

  -- TurtleWoW has continent timezones, so we need to normalize the server time if player is on Kalimdor
  if isOnKalimdor then
    h = math.mod(h + 12, 24)
  end

  return h, m
end

-- Get local PizzaWorldBuffs version as a semantic versioning string
function PWB.utils.getVersion()
  return tostring(GetAddOnMetadata(PWB:GetName(), "Version"))
end

-- Get local PizzaWorldBuffs version as a single number
function PWB.utils.getVersionNumber ()
  local major, minor, patch = PWB.utils.strSplit(PWB.utils.getVersion(), '.')
  major = tonumber(major) or 0
  minor = tonumber(minor) or 0
  patch = tonumber(patch) or 0

  return major*10000 + minor*100 + patch
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

-- Check if we have any timers stored in a deprecated format (pre-v0.0.15)
function PWB.utils.hasDeprecatedTimerFormat ()
  local x = PWB.utils.someTimer(function (timer)
    return timer.deadline ~= nil
  end)

  if x then
    PWB:Print('Found timers in a deprecated format!')
  else
    PWB:Print('No timers in deprecated format found! \\o/')
  end

  return x
end

-- Check if I'm the direct witness for any of my timers.
function PWB.utils.isWitness ()
  return PWB.utils.someTimer(function (timer)
    return timer.witness == PWB.me
  end)
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
function PWB.utils.getTimerColor (witness, receivedFrom)
  if witness == PWB.me then return PWB.Colors.green end
  if receivedFrom == witness then return PWB.Colors.orange end
  return PWB.Colors.red
end