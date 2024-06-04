local PWB = PizzaWorldBuffs
PWB.core = {}

setfenv(1, PWB:GetEnv())

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
function PWB.core.encode(faction, boss, h, m, witness)
  if not faction or not boss or not h or not m or not witness then return end
  return string.format('%s-%s-%.2d-%.2d-%s', faction, boss, h, m, witness)
end

-- Encode all of our timers as strings, separated by semicolon.
function PWB.core.encodeAll()
  local timersStr
  for _, timers in pairs(PWB_timers) do
    for _, timer in pairs(timers) do
      local faction, boss, h, m, witness = timer.faction, timer.boss, timer.h, timer.m, timer.witness
      timersStr = (timersStr and timersStr .. ';' or '') .. PWB.core.encode(faction, boss, h, m, witness)
    end
  end
  return timersStr
end

-- Decode the provided timer string into a timer table.
function PWB.core.decode(timerStr)
  local faction, boss, hStr, mStr, witness = PWB.utils.strSplit(timerStr, '-')
  return faction, boss, tonumber(hStr), tonumber(mStr), witness
end

-- Generate a time table representing the duration from now until the provided
-- timer will run out.
function PWB.core.getTimeLeft(h, m)
  local sh, sm = PWB.utils.getServerTime()

  if sh > h and h < BUFF_CD_HOURS then
    -- now is before and deadline is after midnight. Let's just fix the diff
    -- calculation by adding 24 hours to the deadline time.
    h = h + 24
  end

  local diff = PWB.utils.toMinutes(h, m) - PWB.utils.toMinutes(sh, sm)

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
function PWB.core.isValid(h, m, acceptedAt)
  local now = time()
  local twoHours = 2 * 60 * 60

  -- Mark timer as invalid if we accepted/stored it more than 2 hours ago. This prevents an
  -- issue that's due to the timers containing only the time, not the date. Without this, if
  -- you log off at e.g. 7 pm with 1 hour left on Ony buff and then log back in the next day
  -- at 7 pm, the addon will just resume the old timer because it doesn't know it's from
  -- the day before.
  if not acceptedAt or acceptedAt > now or acceptedAt < now - twoHours then
    return false
  end

  return PWB.core.getTimeLeft(h, m) ~= nil
end

-- These are the NPC yell triggers we use to detect that one of the buffs has dropped.
local yellTriggers = {
  A = {
    O = T['YELL_TRIGGER_ALLIANCE_ONYXIA'],
    N = T['YELL_TRIGGER_ALLIANCE_NEFARIAN'],
  },
  H = {
    O = T['YELL_TRIGGER_HORDE_ONYXIA'],
    N = T['YELL_TRIGGER_HORDE_NEFARIAN'],
  },
}

-- Given an NPC's yell message, check if it's one of the triggers for a buff being dropped.
-- If yes, return the boss and faction. Otherwise, return nil.
function PWB.core.parseMonsterYell(yellMsg)
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
function PWB.core.getTimer(faction, boss)
  return PWB_timers[faction][boss]
end

-- Store the provided timer locally.
function PWB.core.setTimer(faction, boss, h, m, witness, receivedFrom)
  PWB_timers[faction][boss] = {
    faction = faction,
    boss = boss,
    h = h,
    m = m,
    witness = witness,
    receivedFrom = receivedFrom,
    acceptedAt = time(),
  }
end

-- Remove the provided timer from our local timer store.
function PWB.core.clearTimer(timer)
  PWB_timers[timer.faction][timer.boss] = nil
end

-- Clear all invalid timers from our local timer store.
function PWB.core.clearExpiredTimers()
  -- Initialize timers if they somehow haven't been initialized yet
  if not PWB_timers then PWB.core.clearAllTimers() end

  PWB.utils.forEachTimer(function (timer)
    if not PWB.core.isValid(timer.h, timer.m, timer.acceptedAt) then
      PWB.core.clearTimer(timer)
    end
  end)
end

-- Clear all local timers, even valid ones.
function PWB.core.clearAllTimers()
  PWB_timers = {
    A = {},
    H = {},
  }
end

-- Check if the provided timer should be accepted and stored locally.
function PWB.core.shouldAcceptNewTimer(faction, boss, h, m, witness, receivedFrom)
  if not PWB_config.sharingEnabled then return false end

  local currentTimer = PWB.core.getTimer(faction, boss)

  -- Never accept invalid or expired timers
  if not PWB.core.isValid(h, m, time()) then return false end

  -- Always accept if we currently don't have a timer for this buff
  if not currentTimer then return true end

  -- Always accept if current timer is expired or invalid
  if not PWB.core.isValid(currentTimer.h, currentTimer.m, currentTimer.acceptedAt) then return true end

  -- Always accept new timers that we witnessed ourselves
  if witness == PWB.me then return true end

  -- Never accept other peoples' timers if we currently have a timer that we witnessed ourselves
  if currentTimer.witness == PWB.me then return false end

  -- Otherwise, only accept if the new timer came from a direct witness and our current one didn't
  return receivedFrom == witness and currentTimer.receivedFrom ~= currentTimer.witness
end

-- Reset the publish delay that we will count down from before we publish our local timers.
function PWB.core.resetPublishDelay()
  local min, max = 5, 30
  local witnessPriority = .3

  -- (Re)set our own publish delay to a random number of seconds. If we have witnessed one of our
  -- timers ourselves, we get publish priority, i.e. we're more likely to publish our timers.
  local delay = PWB.utils.isWitness() and math.random((1 - witnessPriority) * min, (1 - witnessPriority) * max) or math.random(min, max)
  PWB.nextPublishAt = time() + delay
end

-- Check if we should publish our local timers.
function PWB.core.shouldPublishTimers()
  if not PWB_config.sharingEnabled then return false end

  local now = time()

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
function PWB.core.publishTimers()
  PWB.core.resetPublishDelay()

  -- Always clear all expired timers (again) right before publishing to make sure we never share
  -- outdated timers.
  PWB.core.clearExpiredTimers()

  if not PWB_config.sharingEnabled then return end

  -- Remember the last time we published our timers.
  PWB.lastPublishedAt = time()

  if UnitLevel('player') < 5 or not PWB.utils.hasTimers() then
    return
  end

  local pwbChannel = GetChannelName(PWB.channelName)
  if pwbChannel ~= 0 then
    SendChatMessage(PWB.abbrev .. ':' .. PWB.utils.getVersionNumber() .. ':' .. PWB.core.encodeAll(), 'CHANNEL', nil, pwbChannel)
  end
end
