PWB.core = {}

local BUFF_CD_HOURS = 2

-- Encode the provided timer as a string that can be shared with other addon users.
--
-- Encoded timer format:
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

-- Encode all of our timers as strings, separated by semicolon.
function PWB.core.encodeAll ()
  local timersStr
  for _, timers in pairs(PWB_timers) do
    for _, timer in pairs(timers) do
      timersStr = (timersStr and timersStr .. ';' or '') .. PWB.core.encode(timer)
    end
  end
  return timersStr
end

-- Decode the provided timer string into a timer table.
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

-- Generate a time table representing the duration from now until the provided
-- timer will run out.
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

-- Check if the provided timer is valid. A timer is only valid if all of the following
-- conditions apply:
--
--   1. The timer is less than 2 hours in the future.
--   2. The timer has not expired, i.e. it's not in the past.
--   3. We received/stored the timer no more than 2 hours ago.
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

-- These are the NPC yell triggers we use to detect that one of the buffs has dropped.
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

-- Given an NPC's yell message, check if it's one of the triggers for a buff being dropped.
-- If yes, return the boss and faction. Otherwise, return nil.
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

-- Get our current timer for the provided faction and boss.
function PWB.core.getTimer (faction, boss)
  return PWB_timers[faction][boss]
end

-- Store the provided timer locally.
function PWB.core.setTimer (timer)
  PWB_timers[timer.faction][timer.boss] = timer
  PWB_timers[timer.faction][timer.boss].acceptedAt = GetTime()
end

-- Remove the provided timer from our local timer store.
function PWB.core.clearTimer (timer)
  PWB_timers[timer.faction][timer.boss] = nil
end

-- Clear all invalid timers from our local timer store.
function PWB.core.clearExpiredTimers ()
  -- Initialize timers if they somehow haven't been initialized yet
  if not PWB_timers then PWB.core.clearAllTimers() end

  PWB.utils.forEachTimer(function (timer)
    if not PWB.core.isValid(timer) then
      PWB.core.clearTimer(timer)
    end
  end)
end

-- Clear all local timers, even valid ones.
function PWB.core.clearAllTimers ()
  PWB.utils.forEachTimer(function (timer)
    PWB.core.clearTimer(timer)
  end)
end

-- Check if the provided timer should be accepted and stored locally.
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

-- Reset the publish delay that we will count down from before we publish our local timers.
function PWB.core.resetPublishDelay ()
  local min, max = 5, 30
  local witnessPriority = .3

  -- (Re)set our own publish delay to a random number of seconds. If we have witnessed one of our
  -- timers ourselves, we get publish priority, i.e. we're more likely to publish our timers.
  local delay = PWB.utils.isWitness() and math.random((1 - witnessPriority) * min, (1 - witnessPriority) * max) or math.random(min, max)
  PWB.nextPublishAt = GetTime() + delay
end

-- Check if we should publish our local timers.
function PWB.core.shouldPublishTimers ()
  local now = GetTime()

  -- If we've reached the publish interval limit (i.e. we haven't published our timers in X minutes),
  -- we just force publish our timers.
  if PWB.lastPublishedAt and now > PWB.lastPublishedAt + PWB.maxPublishIntervalMinutes * 60 then
    return true
  end

  return PWB.nextPublishAt and now > PWB.nextPublishAt
end

-- Publish our local timers by sending them to the hidden PWB chat channel.
--
-- Message format:
--   PizzaWorldBuffs:VERSION:TIMER;TIMER;TIMER;...
-- 
--   VERSION    Our own version of the addon as a single number
--   TIMER      A single encoded timer; see PWB.core.encode() for details
--
-- Example:
--   PizzaWorldBuffs:1337:A-O-13-37-Pizzahawaii;H-N-14-44-Someotherdude
function PWB.core.publishTimers ()
  PWB.core.resetPublishDelay()

  -- Remember the last time we published our timers.
  PWB.lastPublishedAt = GetTime()

  if UnitLevel('player') < 5 or not PWB.utils.hasTimers() then
    return
  end

  local pwbChannel = GetChannelName(PWB.name)
  if pwbChannel ~= 0 then
    SendChatMessage(PWB.abbrev .. ':' .. PWB.utils.getVersionNumber() .. ':' .. PWB.core.encodeAll(), 'CHANNEL', nil, pwbChannel)
  end
end