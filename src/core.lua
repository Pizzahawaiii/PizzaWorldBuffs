PWB.core = {}

local BUFF_CD_HOURS = 2

-- Encoded timer format:
--
--   FACTION-BOSS-HH-MM-WITNESS
--
--   FACTION    'A' for Alliance or 'H' for Horde
--   BOSS       'O' for Onyxia or 'N' for Nefarian
--   TIME       The server time at which the head will go down again, in HH-MM format
--   WITNESS    Name of the player who originally witnessed the buff
--
-- Example:
--   A-O-16-37-Pizzahawaii
function PWB.core.encode (timer)
  if not timer or not timer.faction or not timer.boss or not timer.deadline or not timer.witness then return end
  return string.format('%s-%s-%.2d-%.2d-%s', timer.faction, timer.boss, timer.deadline.h, timer.deadline.m, timer.witness)
end

function PWB.core.encodeAll ()
  local timersStr
  for faction, timers in pairs(PWB_timers) do
    for boss, timer in pairs(timers) do
      timersStr = (timersStr and timersStr .. ';' or '') .. PWB.core.encode(timer)
    end
  end
  return timersStr
end

function PWB.core.decode (timerStr, receivedFrom)
  local faction, boss, hStr, mStr, witness = PWB.utils.strSplit(timerStr, '-')
  return {
    faction = faction,
    boss = boss,
    deadline = {
      h = tonumber(hStr),
      m = tonumber(mStr),
    },
    witness = witness,
    receivedFrom = receivedFrom,
  }
end

function PWB.core.getTimeLeft (timer)
  local deadline = { h = timer.deadline.h, m = timer.deadline.m }
  local now = PWB.utils.getServerTime()

  if now.h > deadline.h and deadline.h < BUFF_CD_HOURS then
    -- now is before and deadline is after midnight. Let's just fix the diff
    -- calculation by adding 24 hours to the deadline time.
    deadline.h = deadline.h + 24
  end

  local diff = PWB.utils.toMinutes(deadline) - PWB.utils.toMinutes(now)

  local isExpired = diff < 0
  local isInvalid = diff > BUFF_CD_HOURS * 60
  if isExpired or isInvalid then return end

  return PWB.utils.toTime(diff)
end

function PWB.core.isValid (timer)
  local now = GetTime()
  local twoHours = 2 * 60 * 60

  -- Mark timer as invalid if we accepted/stored it more than 2 hours ago. This prevents an
  -- issue that's due to the timers containing only the time, not the date. Without this, if
  -- you log off at e.g. 7 pm with 1 hour left on Ony buff and then log back in the next day
  -- at 7 pm, the addon will just resume the old timer because it doesn't know it's from
  -- the day before.
  if timer.acceptedAt and now > timer.acceptedAt + twoHours then
    return false
  end

  return PWB.core.getTimeLeft(timer) ~= nil
end

local yellTriggers = {
  A = {
    O = 'The dread lady, Onyxia, hangs from the arches!',
    N = 'Citizens of the Alliance, the Lord of Blackrock is slain! Nefarian has been subdued',
  },
  H = {
    O = 'The brood mother, Onyxia, has been slain!',
    N = 'NEFARIAN IS SLAIN! People of Orgrimmar, bow down before the might of',
  },
}
function PWB.core.parseMonsterYell (yellMsg)
  for faction, bossTriggers in pairs(yellTriggers) do
    for boss, yellTrigger in pairs(bossTriggers) do
      local found = string.find(yellMsg, yellTrigger)
      if found then
        return boss, faction
      end
    end
  end
end

function PWB.core.getTimer (faction, boss)
  return PWB_timers[faction][boss]
end

function PWB.core.setTimer (timer)
  PWB_timers[timer.faction][timer.boss] = timer
  PWB_timers[timer.faction][timer.boss].acceptedAt = GetTime()
end

function PWB.core.clearTimer (faction, boss)
  PWB_timers[faction][boss] = nil
end

function PWB.core.clearExpiredTimers ()
  if not PWB_timers then return end

  for faction, timers in pairs(PWB_timers) do
    for boss, timer in pairs(timers) do
      if not PWB.core.isValid(timer) then
        PWB.core.clearTimer(faction, boss)
      end
    end
  end
end

function PWB.core.clearAllTimers ()
  PWB_timers = {
    A = {
      O = nil,
      N = nil,
    },
    H = {
      O = nil,
      N = nil,
    },
  }
end

function PWB.core.shouldAcceptNewTimer (newTimer)
  local currentTimer = PWB.core.getTimer(newTimer.faction, newTimer.boss)

  -- Never accept invalid or expired timers
  if not PWB.core.isValid(newTimer) then return false end

  -- Always accept if we currently don't have a timer for this buff
  if not currentTimer then return true end

  -- Always accept if current timer is expired or invalid
  if not PWB.core.isValid(currentTimer) then return true end

  -- Always accept new timers that we witnessed ourselves
  if newTimer.witness == PWB.me then return true end

  -- Never accept other peoples' timers if we currently have a timer that we witnessed ourselves
  if currentTimer.witness == PWB.me then return false end

  -- Otherwise, only accept if the new timer came from a direct witness and our current one didn't
  return PWB.utils.receivedFromWitness(newTimer) and not PWB.utils.receivedFromWitness(currentTimer)
end

function PWB.core.hasTimers ()
  if not PWB_timers then return false end

  for _, timers in pairs(PWB_timers) do
    for _, timer in pairs(timers) do
      if timer then return true end
    end
  end

  return false
end

function PWB.core.resetPublishDelay ()
  -- (Re)set our own publishAll delay to a random number of seconds
  -- TODO: Tweak this so we don't spam the channel too much once more people use the addon
  -- TODO: Ideally, think of a better solution
  PWB.nextPublishAt = GetTime() + math.random(5, 30)
end

function PWB.core.shouldPublishTimers ()
  local now = GetTime()

  -- If we've reached the publish interval limit (i.e. we haven't published our timers in X minutes),
  -- we just force publish our timers.
  if PWB.lastPublishedAt and now > PWB.lastPublishedAt + PWB.maxPublishIntervalMinutes * 60 then
    return true
  end

  return PWB.nextPublishAt and now > PWB.nextPublishAt
end

function PWB.core.publishTimers ()
  PWB.core.resetPublishDelay()

  -- Remember the last time we published our timers.
  PWB.lastPublishedAt = GetTime()

  if UnitLevel('player') < 5 or not PWB.core.hasTimers() then
    return
  end

  local pwbChannel = GetChannelName(PWB.name)
  if pwbChannel ~= 0 then
    SendChatMessage(PWB.abbrev .. ':' .. PWB.utils.getVersionNumber() .. ':' .. PWB.core.encodeAll(), 'CHANNEL', nil, pwbChannel)
  end
end